# Experiment log

## 27 October 2026: original comparison

The small experiment completed with ten training, validation and test pairs and
three SMRs. Its files and configuration are preserved in
[`results/archive/preliminary-2026-10-27`](../results/archive/preliminary-2026-10-27/).

| System | Speech F1 | Speech balanced accuracy | Music F1 | Music balanced accuracy |
| --- | ---: | ---: | ---: | ---: |
| Handcrafted SVM | 0.889 | 0.500 | 0.941 | 0.750 |
| YAMNet, fixed 0.5 | 0.545 | 0.688 | 0.919 | 0.925 |

Balanced accuracies above were calculated later from the original confusion
counts. No model was rerun to obtain them. The different rankings show why the
initial F1 comparison alone cannot establish which representation is better.

## 3 November 2026: evaluation and controlled modification

The development comparison adds:

- an always-present reference and class-balanced metrics;
- unweighted versus equal-prior SVMs with shared training-only scaling;
- balanced-accuracy C selection for both SVM versions;
- YAMNet validation scores and a separate validation-selected threshold for
  each target, alongside its fixed 0.5 rule;
- source manifests, confusion plots and a small audio demonstration.

The hypothesis is that equal priors can reduce the tendency to accept every
example as positive. That could improve balanced accuracy while reducing recall
for a very weak source. The comparison must report both effects. An improvement
is not assumed in advance.

The [3 November run](https://github.com/49sky/elec5305-project-530582937/actions/runs/41575559205)
passed the MATLAB checks, experiment and publication. Its outputs are in
`results/development/`. The ten test pairs produced 50 examples.

| System | Speech balanced accuracy | Speech F1 | Music balanced accuracy | Music F1 |
| --- | ---: | ---: | ---: | ---: |
| Always present | 0.500 | 0.889 | 0.500 | 0.889 |
| SVM unweighted | 0.725 | 0.822 | 0.638 | 0.864 |
| SVM balanced | 0.675 | 0.811 | 0.775 | 0.883 |
| MATLAB YAMNet, fixed 0.5 | 0.688 | 0.545 | 0.925 | 0.919 |
| MATLAB YAMNet, validation thresholds | 0.713 | 0.596 | 0.975 | 0.974 |

Equal priors helped music specificity but reduced speech specificity. The
weighting hypothesis was therefore only partly supported on this small set.
The validation-selected YAMNet thresholds were 0.05 for speech and 0.15 for
music. [Development analysis](development_results.md) separates the pure-source
errors from mixture misses.

## 12 November 2026: evaluation review

The evaluation now includes 95% percentile intervals from 2,000 resamples of
whole source pairs, with the same draws used for paired system comparisons.
Saved prediction CSVs can be reviewed without loading audio or rerunning models.
The original decisions remain unchanged. An error-case table identifies clips
for later listening; its labels are source-track labels.

The model description now identifies the MATLAB YAMNet softmax head explicitly.
This differs from the independent sigmoid head in the TensorFlow reference.
The experiment keeps the MATLAB model and records its output layer in new runs.
The final source selection, SMRs and model-selection rules remain fixed.

## Reserved final experiment

[`config/final_protocol.json`](../config/final_protocol.json) records the planned
seven-SMR experiment: 100 training pairs, 30 validation pairs and 50 test pairs
at indices 11-60 of the existing split. The preview checks these against the
archived source lists without reading the audio. Push checks do not use those
reserved test sources; the final audio experiment is a separate manual run.

After the development checks, run the fixed protocol once for the final
comparison. Use its results to answer the question and describe limitations,
without retuning on that test set. The final report, GitHub Site and video are
still to be prepared. The video should demonstrate a few representative clips,
including a false alarm or missed weak source, and explain the processing.
