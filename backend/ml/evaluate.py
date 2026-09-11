"""XGBoost disruption-model EVALUATION suite (Phase 9 §9.3).

Pure functions — no infra, no model — so they unit-test with hand-known inputs.
Every metric the master prompt asks for:

    precision, recall, F1, ROC-AUC, calibration (ECE), false-negative rate

The false-negative rate gets first-class treatment because in disruption
prediction a missed event (false negative) is the dangerous kind: the system
says "all clear" while a road washes out. Downstream promotion gates weight it.
"""
from __future__ import annotations

import math
from collections import Counter


def _tp_fp_fn_tn(y_true, y_pred):
    tp = fp = fn = tn = 0
    for yt, yp in zip(y_true, y_pred):
        if yt == 1 and yp == 1:
            tp += 1
        elif yt == 0 and yp == 1:
            fp += 1
        elif yt == 1 and yp == 0:
            fn += 1
        else:
            tn += 1
    return tp, fp, fn, tn


def precision(y_true, y_pred) -> float:
    tp, fp, *_ = _tp_fp_fn_tn(y_true, y_pred)
    return tp / (tp + fp) if (tp + fp) else 0.0


def recall(y_true, y_pred) -> float:
    tp, _, fn, _ = _tp_fp_fn_tn(y_true, y_pred)
    return tp / (tp + fn) if (tp + fn) else 0.0


def false_negative_rate(y_true, y_pred) -> float:
    """Fraction of real disruptions missed (the dangerous error)."""
    tp, _, fn, _ = _tp_fp_fn_tn(y_true, y_pred)
    return fn / (tp + fn) if (tp + fn) else 0.0


def false_positive_rate(y_true, y_pred) -> float:
    _, fp, _, tn = _tp_fp_fn_tn(y_true, y_pred)
    return fp / (fp + tn) if (fp + tn) else 0.0


def f1_score(y_true, y_pred) -> float:
    p = precision(y_true, y_pred)
    r = recall(y_true, y_pred)
    return 2 * p * r / (p + r) if (p + r) else 0.0


def roc_auc(y_true, y_prob) -> float:
    """Area under the ROC curve via the probabilistic (Wilcoxon-Mann-Whitney)
    formulation. Returns 0.5 (random) when one class is absent — there is no
    ranking signal to measure, so we report chance rather than invent one."""
    if not y_prob or len(set(y_true)) < 2:
        return 0.5
    pos = [p for y, p in zip(y_true, y_prob) if y == 1]
    neg = [p for y, p in zip(y_true, y_prob) if y == 0]
    if not pos or not neg:
        return 0.5
    wins = 0
    for p in pos:
        for n in neg:
            if p > n:
                wins += 1
            elif p == n:
                wins += 0.5
    return wins / (len(pos) * len(neg))


def expected_calibration_error(y_true, y_prob, n_bins: int = 10) -> float:
    """ECE: average |accuracy − confidence| across probability bins. Lower is
    better; 0 means the model's probabilities match observed frequencies."""
    if not y_prob:
        return 0.0
    bins = [[] for _ in range(n_bins)]  # each entry: (y, prob)
    for y, p in zip(y_true, y_prob):
        idx = min(int(p * n_bins), n_bins - 1)
        bins[idx].append((y, p))
    ece = 0.0
    n = len(y_true)
    for b in bins:
        if not b:
            continue
        acc = sum(y for y, _ in b) / len(b)
        conf = sum(p for _, p in b) / len(b)
        ece += len(b) / n * abs(acc - conf)
    return round(ece, 4)


def classification_metrics(y_true, y_prob, threshold: float = 0.5) -> dict:
    """Full §9.3 metric card for one horizon. `y_prob` is the model's disruption
    probability; `threshold` binarises it for the count-based metrics."""
    y_pred = [1 if p >= threshold else 0 for p in y_prob]
    return {
        "threshold": threshold,
        "precision": round(precision(y_true, y_pred), 4),
        "recall": round(recall(y_true, y_pred), 4),
        "f1": round(f1_score(y_true, y_pred), 4),
        "roc_auc": round(roc_auc(y_true, y_prob), 4),
        "false_negative_rate": round(false_negative_rate(y_true, y_pred), 4),
        "false_positive_rate": round(false_positive_rate(y_true, y_pred), 4),
        "calibration_ece": expected_calibration_error(y_true, y_prob),
        "n_samples": len(y_true),
        "n_positive": sum(y_true),
    }


def passes_promotion_bar(metrics: dict, *, min_f1: float = 0.6,
                         max_fnr: float = 0.25) -> tuple[bool, str]:
    """Is this metric card good enough to consider for VALIDATION→PRODUCTION?
    Conservative by default — a high false-negative rate fails even with decent
    F1, because missed disruptions are the dangerous error. Returns (ok, reason).
    """
    if metrics.get("f1", 0.0) < min_f1:
        return False, f"F1 {metrics.get('f1')} below floor {min_f1}"
    if metrics.get("false_negative_rate", 1.0) > max_fnr:
        return False, (f"false-negative rate {metrics.get('false_negative_rate')} "
                       f"above ceiling {max_fnr}")
    return True, "ok"