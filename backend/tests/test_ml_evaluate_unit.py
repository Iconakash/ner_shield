"""Phase 9 §9.3 — evaluation metric unit tests. Pure functions, known inputs."""
import sys as _sys
from pathlib import Path

BACKEND = Path(__file__).resolve().parents[1]
if str(BACKEND) not in _sys.path:
    _sys.path.insert(0, str(BACKEND))

from ml.evaluate import (  # noqa: E402
    classification_metrics, expected_calibration_error, f1_score,
    false_negative_rate, false_positive_rate, passes_promotion_bar,
    precision, recall, roc_auc)


# ---------------------------------------------------- count-based metrics
def test_perfect_predictions_score_one():
    y = [1, 0, 1, 1, 0]
    assert precision(y, y) == 1.0
    assert recall(y, y) == 1.0
    assert f1_score(y, y) == 1.0
    assert false_negative_rate(y, y) == 0.0
    assert false_positive_rate(y, y) == 0.0


def test_all_missed_is_worst_case_fnr():
    y_true = [1, 1, 1]
    y_pred = [0, 0, 0]
    assert false_negative_rate(y_true, y_pred) == 1.0   # dangerous: all missed
    assert recall(y_true, y_pred) == 0.0
    assert precision(y_true, y_pred) == 0.0            # no positive predictions


def test_hand_computed_precision_recall_f1():
    # tp=2, fp=1, fn=1, tn=1  ->  P=2/3, R=2/3, F1=2/3
    y_true = [1, 0, 1, 1, 0]
    y_pred = [1, 1, 1, 0, 0]
    assert precision(y_true, y_pred) == 2 / 3
    assert recall(y_true, y_pred) == 2 / 3
    assert abs(f1_score(y_true, y_pred) - 2 / 3) < 1e-9
    assert false_negative_rate(y_true, y_pred) == 1 / 3


def test_f1_harmonic_mean_property():
    # When P != R, F1 is strictly below the arithmetic mean.
    y_true = [1, 1, 1, 0, 0, 0, 0, 0]
    y_pred = [1, 0, 0, 0, 0, 0, 0, 0]   # P=1, R=1/3
    p, r = precision(y_true, y_pred), recall(y_true, y_pred)
    assert f1_score(y_true, y_pred) == 2 * p * r / (p + r)


# --------------------------------------------------------------- ROC-AUC
def test_roc_auc_perfect_separation():
    y_true = [1, 1, 0, 0]
    y_prob = [0.9, 0.8, 0.2, 0.1]
    assert roc_auc(y_true, y_prob) == 1.0


def test_roc_auc_random_is_half():
    y_true = [1, 0, 1, 0]
    y_prob = [0.5, 0.5, 0.5, 0.5]
    assert roc_auc(y_true, y_prob) == 0.5


def test_roc_auc_worse_than_random():
    # model ranks negatives above positives
    y_true = [1, 1, 0, 0]
    y_prob = [0.1, 0.2, 0.8, 0.9]
    assert roc_auc(y_true, y_prob) == 0.0


def test_roc_auc_single_class_returns_chance():
    assert roc_auc([1, 1, 1], [0.9, 0.8, 0.7]) == 0.5
    assert roc_auc([], []) == 0.5


# ----------------------------------------------------------- calibration ECE
def test_ece_perfect_calibration():
    # 10 samples, all correct at the stated confidence → ECE 0
    y_true = [1, 0]
    y_prob = [1.0, 0.0]
    assert expected_calibration_error(y_true, y_prob) == 0.0


def test_ece_miscalibrated_is_positive():
    y_true =  [1, 0, 1, 0]
    y_prob =  [0.1, 0.9, 0.1, 0.9]   # confident and wrong
    assert expected_calibration_error(y_true, y_prob) > 0.0


def test_ece_empty_is_zero():
    assert expected_calibration_error([], []) == 0.0


# ---------------------------------------------------- full metric card
def test_classification_metrics_card_shape_and_fnr_flag():
    y_true = [1, 0, 1, 1, 0, 0, 1, 0]
    y_prob = [0.9, 0.1, 0.8, 0.7, 0.3, 0.2, 0.4, 0.6]
    m = classification_metrics(y_true, y_prob, threshold=0.5)
    assert set(m.keys()) == {"threshold", "precision", "recall", "f1",
                             "roc_auc", "false_negative_rate",
                             "false_positive_rate", "calibration_ece",
                             "n_samples", "n_positive"}
    assert m["n_samples"] == 8 and m["n_positive"] == 4
    # fn=1 (the 0.4 sample), so fnr = 1/4
    assert m["false_negative_rate"] == 0.25


# ------------------------------------------------- promotion gate (§9.3/§9.5)
def test_passes_promotion_bar_good_model():
    ok, _ = passes_promotion_bar({"f1": 0.85, "false_negative_rate": 0.1})
    assert ok


def test_promotion_bar_blocks_high_fnr():
    # Decent F1 but misses too many real disruptions → blocked
    ok, reason = passes_promotion_bar({"f1": 0.8, "false_negative_rate": 0.5})
    assert not ok and "false-negative" in reason


def test_promotion_bar_blocks_low_f1():
    ok, reason = passes_promotion_bar({"f1": 0.3, "false_negative_rate": 0.1})
    assert not ok and "F1" in reason