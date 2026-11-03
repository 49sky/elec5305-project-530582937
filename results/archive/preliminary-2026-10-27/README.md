# Original preliminary experiment

This snapshot preserves the successful run of 27 October 2026, before the
evaluation and weighting changes.

- Code/results revision: `5fc45bf4b1e2bfe2eec68b9f743d41e8f6c280ed`.
- [MATLAB run](https://github.com/49sky/elec5305-project-530582937/actions/runs/40511456636).
- Ten source pairs per partition, 2 s excerpts and SMRs -10, 0 and +10 dB.
- Separate linear SVMs, validation positive-class F1 for C selection, zero-margin
  decisions. YAMNet used a fixed 0.5 threshold.

The original CSVs, source split and figures are retained unchanged.
`configuration.json` records the settings from that revision.
`recomputed_metrics.csv` adds specificity and balanced accuracy calculated from
the original confusion counts; it is not a new experiment.

The speech SVM labelled all 50 test examples positive: 40 true positives and ten
false positives. Its positive-class F1 was 0.889 and balanced accuracy was 0.5.
This observation motivated the later comparison. It does not establish whether
class imbalance, limited training diversity or the features themselves caused
the behaviour.

Models and audio were workflow artifacts rather than Git files. They can be
regenerated using the code at the recorded revision and the official corpus.
The larger final test set was not used in this run.
