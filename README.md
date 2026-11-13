# Speech and Music Presence Detection

[Code](https://github.com/49sky/elec5305-project-530582937) · [Download ZIP](https://github.com/49sky/elec5305-project-530582937/archive/refs/heads/main.zip) · [Project site](https://49sky.github.io/elec5305-project-530582937/)

How does the relative level of speech and music affect detection when both are present?

This MATLAB project compares 40 handcrafted audio features with linear SVMs against pretrained YAMNet. It creates controlled mixtures from MUSAN recordings and measures speech and music presence separately.

## Results

The final experiment used 100 training pairs, 30 validation pairs and 50 previously unused test pairs. Seven speech-to-music ratios (SMRs), from -20 to +20 dB, produced 450 test examples.

| System | Speech balanced accuracy | Speech F1 | Music balanced accuracy | Music F1 |
| --- | ---: | ---: | ---: | ---: |
| Always present | 0.5000 | 0.9412 | 0.5000 | 0.9412 |
| SVM unweighted | 0.5000 | 0.9412 | 0.8838 | 0.9711 |
| SVM balanced | 0.7988 | 0.8523 | 0.9325 | 0.9573 |
| MATLAB YAMNet, fixed 0.5 | 0.6813 | 0.5321 | 0.8613 | 0.8389 |
| MATLAB YAMNet, validation thresholds | 0.7800 | 0.7179 | 0.9313 | 0.9262 |

Balanced accuracy averages recall and specificity. F1 describes the present class. The unweighted speech SVM accepted every clip, giving high F1 but zero specificity. Weighting and threshold selection improved balanced accuracy, although both approaches still missed very weak sources.

See the [final analysis](docs/final_results.md), [CSV results and plots](https://github.com/49sky/elec5305-project-530582937/tree/main/results/final), [methods and references](docs/methods.md), and [experiment history](docs/experiments.md).

## Requirements

- MATLAB R2024a or later; GitHub Actions uses R2026b.
- Signal Processing Toolbox and Statistics and Machine Learning Toolbox.
- Audio Toolbox and Deep Learning Toolbox for YAMNet.

The tests use synthetic audio and saved predictions. They need no MUSAN or model download.

## Run the tests

From the repository root in MATLAB:

```matlab
addpath("src")
results = runtests("tests");
assertSuccess(results)
```

The tests cover known feature values, source separation between partitions, training-only scaling, model reloads, validation selection, bootstrap grouping, invalid inputs and plot generation.

## Run an experiment locally

Extract the official MUSAN speech and music folders under `data/musan/`; see [data setup](https://github.com/49sky/elec5305-project-530582937/blob/main/data/README.md). The corpus is excluded from Git. A local experiment needs disk space for the audio, while the GitHub workflow downloads it onto a temporary runner.

For the small experiment, with ten pairs per partition and SMRs of -10, 0 and +10 dB:

```matlab
addpath("src")
create_source_split
preliminary_mixture_demo(ResultsDir="results/run");
```

The first YAMNet run may download its weights from MathWorks. To use only the handcrafted system:

```matlab
preliminary_mixture_demo(UseYAMNet=false, ResultsDir="results/svm_only");
```

Use a new output directory when changing settings, so results from different configurations are kept apart.

The [final protocol](config/final_protocol.json) fixes source selections, SMRs and selection rules. Preview its source list without loading audio:

```matlab
selected = run_final_experiment;
```

Reproduce it in a new directory:

```matlab
run_final_experiment(DryRun=false, ResultsDir="results/reproduction");
addpath("tests/helpers")
check_reproduction("results/reproduction")
```

The comparison checks the features, decisions, selected settings and metrics against the recorded final run. Output paths may differ; numerical values use a tolerance of `1e-6`. The experiment refuses to overwrite an existing final prediction table.

The [full reproduction](https://github.com/49sky/elec5305-project-530582937/actions/runs/43366250478) on 13 November 2026 passed all 16 MATLAB tests and matched all eight recorded result tables.

## Run on GitHub

Open **Actions → MATLAB → Run workflow** and select:

- `checks`: run the MATLAB tests, with no audio download. Code pushes run this automatically.
- `development`: run the small experiment.
- `reproduce-final`: repeat the fixed final protocol and compare it with the recorded results.

Experiments write to `results/run/` on the runner and upload one `presence-<run>` artifact containing CSVs, plots, models and short demo clips with source credits. They do not commit generated files back to the repository. The recorded results remain in Git.

## Outputs and demo

An experiment saves named features, validation tuning, test predictions, confusion counts, F1 and balanced accuracy, recall versus SMR, and source-pair confidence intervals. `run_manifest.json` records the settings, sources and software versions. The model MAT file contains the four SVMs, scaling and feature names; new YAMNet runs also save the frozen network and class names.

Download and extract an experiment artifact. Supply the actual paths to a clip and its model file:

```matlab
addpath("src")
presence_demo("path/to/pair_11_smr_+0.wav", ...
    "path/to/preliminary_handcrafted_models.mat", PlayAudio=true);
```

This displays SVM decisions and margins, a waveform and a spectrogram. Playback is off by default. Keep the source credits with the clips. The demo needs no full corpus download.

Saved predictions can be reviewed without retraining:

```matlab
review_presence_results("results/final");
```

## Files

- `src/`: feature extraction, mixture generation, training, evaluation and demo.
- `tests/`: MATLAB tests and the reproduction comparison.
- `config/final_protocol.json`: fixed final settings.
- `results/final/`: recorded final experiment.
- `results/development/`: small controlled comparison.
- `results/archive/`: original preliminary experiment.
- `docs/`: methods, results interpretation and experiment history.

The [revised proposal](Revised_Project_Proposal.pdf) describes the current scope. The [original proposal](ProjectProposal.pdf) records the earlier isolated speech/music classification plan.
