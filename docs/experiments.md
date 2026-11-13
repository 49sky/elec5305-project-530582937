# Experiment history

## 27 October: original comparison

The [original run](https://github.com/49sky/elec5305-project-530582937/actions/runs/40511456636) used ten pairs per partition, two-second excerpts and three SMRs. Its files are preserved in [the archive](https://github.com/49sky/elec5305-project-530582937/tree/main/results/archive/preliminary-2026-10-27).

The speech SVM accepted all 50 test examples. Positive-class F1 was 0.889, but balanced accuracy was 0.5. This motivated measures that account for negatives and a class-weighting comparison. The original C selection used validation F1.

## 3 November: controlled modifications

The [development run](https://github.com/49sky/elec5305-project-530582937/actions/runs/41575559205) compared empirical and equal-prior SVMs using shared training-derived scaling and validation balanced accuracy. YAMNet retained its fixed 0.5 rule and added validation-selected thresholds.

Balancing increased music balanced accuracy from 0.6375 to 0.7750: false positives on speech-only clips fell from six to three, with one additional missed positive. Speech balanced accuracy fell from 0.7250 to 0.6750. Both speech models detected 30 positives, while false positives rose from three to four.

Selected YAMNet thresholds were 0.05 for speech and 0.15 for music. They recovered two speech-positive and four music-positive examples without additional observed false positives. Speech was still missed in all -10 and 0 dB mixtures.

The [development outputs](https://github.com/49sky/elec5305-project-530582937/tree/main/results/development) contain the decisions, plots and later source-pair intervals. Both paired SVM weighting intervals included zero on these ten pairs.

## 12-13 November: final comparison

The [final run](https://github.com/49sky/elec5305-project-530582937/actions/runs/43222393874) passed its tests, experiment and publication. The fixed protocol used 100 training, 30 validation and 50 previously unused test pairs across seven SMRs: 900, 270 and 450 examples respectively.

The source manifest matched the archive. No final test file overlapped training, validation or the original preliminary test. The recorded MATLAB YAMNet head was softmax. Settings were selected on validation data, with no final-test retuning.

Balanced SVM accuracy was 0.79875 for speech and 0.93250 for music. Validation-threshold YAMNet reached 0.78000 and 0.93125. The paired intervals for both modifications were above zero on this set. Weak-source recall still fell at extreme SMRs. See the [final analysis](final_results.md) for the counts, curves and limitations.

## 13 November: reproduction

The [full reproduction](https://github.com/49sky/elec5305-project-530582937/actions/runs/43366250478) passed all 16 MATLAB tests. All eight CSV tables matched the recorded experiment, including 1,620 feature rows, 450 test predictions, selected settings and metrics, within the stated `1e-6` numerical tolerance. Only output paths were excluded from the comparison. The final protocol, source split and recorded results were unchanged. Fresh outputs, models, plots and short demo clips are available in the run's `presence-reproduce-final` artifact.

The repository keeps the original, development and final results separately. Reproduction runs use a new output directory and compare their features, decisions, selected settings and metrics with the recorded final run. The workflow saves fresh outputs as an artifact rather than changing the recorded results.

The written project report and demonstration video remain separate submission deliverables.
