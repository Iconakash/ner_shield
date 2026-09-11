"""XGBoost training pipeline for disruption prediction (Phase 9 §9.1-§9.6).

Two prediction tasks:
  regression  (default) — disruption *score* 0..100 per horizon (existing)
  classification        — P(disruption) per horizon; the operationally meaningful
                          "will a disruption occur" prediction where a missed event
                          (false negative) is the dangerous error (§9.3).

Dataset sources (pluggable):
  synthetic (default)   — rule-labeled, born DEMO. The registry forbids promoting
                          synthetic-trained models above DEMO (see ml/registry.py).
  --dataset <path>      — REAL authorized data (CSV: 11 features + 'label' column,
                          label in {0,1} for classification, 0..100 for regression).
                          This is the ONLY path that can reach PRODUCTION, and it
                          requires authorized historical data we do not have here.

Usage:
  python -m backend.ml.train_disruption --version v1
  python -m backend.ml.train_disruption --version v1 --mode classification
  python -m backend.ml.train_disruption --version v1 --dataset data/real.csv

Requires: pip install xgboost scikit-learn joblib numpy   (optional extras)
"""
import argparse
import csv
import json
import random
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REGISTRY = REPO / "ml_models" / "disruption_xgb"

sys.path.insert(0, str(REPO))
sys.path.insert(0, str(REPO / "backend"))

from backend.ml.feature_spec import FEATURE_ORDER  # noqa: E402
from backend.ml.heuristic import HORIZON_MULTIPLIERS, HORIZONS  # noqa: E402


# ----------------------------------------------------------- synthetic datasets
def synthetic_regression_dataset(n: int = 4000, seed: int = 42):
    """Rule-labeled regression samples (existing behavior, DEMO-only)."""
    rng = random.Random(seed)
    rows, labels = [], {h: [] for h in HORIZONS}
    for _ in range(n):
        forecast = rng.uniform(0, 180)
        rain = min(forecast * rng.uniform(0.4, 1.1), 200)
        elev = rng.uniform(50, 3800)
        slope = rng.uniform(1, 55)
        flood = rng.uniform(0, 100) if elev < 800 else rng.uniform(0, 45)
        slide = min(100, (slope / 55.0) * 80 + rng.uniform(0, 25))
        cond = rng.uniform(20, 95)
        disr12 = rng.choice([0, 0, 1, 2, 3, 5])
        clos12 = rng.choice([0, 0, 0, 1, 2, 4])
        traffic = rng.uniform(10, 95)
        fieldrep = rng.uniform(0, 100) if forecast > 60 else rng.uniform(0, 35)

        feats = [rain, forecast, elev, slope, flood, slide, cond,
                 disr12, clos12, traffic, fieldrep]
        base = (min(forecast / 4.0, 45) + min(rain / 6.0, 18)
                + flood * 0.16 + slide * 0.18
                + max(0, (55 - cond)) * 0.25
                + min(slope, 30) * 0.22
                + (elev if elev > 1500 else 0) / 120.0
                + disr12 * 3 + clos12 * 4 + fieldrep * 0.06)
        rows.append(feats)
        for h in HORIZONS:
            labels[h].append(max(0.0, min(100.0,
                base * HORIZON_MULTIPLIERS[h] + rng.gauss(0, 3))))
    return rows, labels


def synthetic_classification_dataset(n: int = 4000, seed: int = 42,
                                    threshold: float = 50.0):
    """Binary disruption labels derived from the regression score: disruption
    occurs when the (deterministic) score exceeds `threshold`. Self-consistent
    with synthetic_regression_dataset so the two modes train on the same world.
    DEMO-only."""
    rows, reg = synthetic_regression_dataset(n, seed)
    labels = {h: [1 if reg[h][i] >= threshold else 0 for i in range(n)]
              for h in HORIZONS}
    return rows, labels


# ----------------------------------------------------------- real-data loader
def load_real_dataset(path: str):
    """Load authorized historical data. Expected CSV columns: the 11 features in
    FEATURE_ORDER order (by name) plus a 'label' column. For classification the
    label is in {0,1}; for regression it is 0..100. Returns (rows, {horizon:
    labels}) — real data has a single horizon (the observed outcome), so every
    horizon key maps to the same label vector. Raises ValueError if the file is
    missing or malformed."""
    p = Path(path)
    if not p.is_file():
        raise ValueError(f"dataset not found: {path}")
    rows: list[list[float]] = []
    labels: list[float] = []
    with p.open() as f:
        reader = csv.DictReader(f)
        for r in reader:
            row = [float(r[c]) for c in FEATURE_ORDER]
            rows.append(row)
            labels.append(float(r["label"]))
    if not rows:
        raise ValueError(f"dataset is empty: {path}")
    by_horizon = {h: labels for h in HORIZONS}
    return rows, by_horizon


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default="v1")
    ap.add_argument("--mode", choices=["regression", "classification"],
                    default="regression")
    ap.add_argument("--dataset", default=None,
                    help="path to REAL authorized CSV (default: synthetic)")
    ap.add_argument("--threshold", type=float, default=0.5,
                    help="classification threshold (default 0.5)")
    args = ap.parse_args()

    try:
        import joblib
        import xgboost as xgb
        import numpy as np
    except ImportError as exc:  # pragma: no cover
        print(f"missing optional dependency: {exc}\n"
              "install with: pip install xgboost scikit-learn joblib numpy")
        return 2

    # --- resolve dataset --------------------------------------------------
    training_source = "synthetic-rule-labels"
    if args.dataset:
        try:
            X, y_by_h = load_real_dataset(args.dataset)
        except ValueError as exc:
            print(f"ERROR: {exc}")
            return 2
        training_source = f"real:{Path(args.dataset).name}"
    elif args.mode == "classification":
        X, y_by_h = synthetic_classification_dataset()
    else:
        X, y_by_h = synthetic_regression_dataset()
    X_np = np.array(X)
    out_dir = REGISTRY / args.version
    out_dir.mkdir(parents=True, exist_ok=True)

    metrics = {"horizons": {}, "mode": args.mode, "threshold": args.threshold}
    models = {}
    is_classification = args.mode == "classification"

    for h in HORIZONS:
        y = np.array(y_by_h[h])
        split = int(len(X_np) * 0.8)
        if is_classification:
            model = xgb.XGBClassifier(
                n_estimators=250, max_depth=4, learning_rate=0.08,
                subsample=0.9, colsample_bytree=0.9, eval_metric="logloss",
                reg_lambda=1.0, n_jobs=2)
        else:
            model = xgb.XGBRegressor(
                n_estimators=250, max_depth=4, learning_rate=0.08,
                subsample=0.9, colsample_bytree=0.9,
                objective="reg:squarederror", reg_lambda=1.0, n_jobs=2)
        model.fit(X_np[:split], y[:split],
                  eval_set=[(X_np[split:], y[split:])], verbose=False)

        preds = model.predict(X_np[split:])
        if is_classification:
            probs = (model.predict_proba(X_np[split:])[:, 1]
                     if hasattr(model, "predict_proba") else preds.astype(float))
            from backend.ml.evaluate import classification_metrics
            m = classification_metrics(y[split:], probs, args.threshold)
            metrics["horizons"][h] = m
        else:
            mae = float(np.mean(np.abs(preds - y[split:])))
            metrics["horizons"][h] = {"mae_pct": round(mae, 2)}
        models[h] = model

    bundle = {"models": models, "feature_order": FEATURE_ORDER,
              "mode": args.mode}
    joblib.dump(bundle, out_dir / "model.joblib")

    (out_dir / "feature_spec.json").write_text(json.dumps(
        {"feature_order": FEATURE_ORDER}, indent=2))
    (out_dir / "metrics.json").write_text(json.dumps(
        {**metrics, "trained_on": training_source,
         "note": ("DEMO synthetic — replace labels with authorized data "
                  "for PRODUCTION")}, indent=2))
    print(f"registered disruption_xgb/{args.version} mode={args.mode} "
          f"trained_on={training_source}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
