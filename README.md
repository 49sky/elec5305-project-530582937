# Speech and Music Presence Detection

[Code](https://github.com/49sky/elec5305-project-530582937) · [Download ZIP](https://github.com/49sky/elec5305-project-530582937/archive/refs/heads/main.zip) · [Project site](https://49sky.github.io/elec5305-project-530582937/)

Speech and music often occur together in recordings. Detecting the stronger source can be straightforward, while the quieter source may be missed. This MATLAB project studies that problem through controlled mixtures of MUSAN speech and music recordings.

## Research question

**How does speech-to-music ratio affect the detection of speech and music separately, and how does a linear SVM using handcrafted audio features compare with frozen MATLAB YAMNet on controlled mixtures?**

Each clip receives two decisions: speech present and music present. A mixture should receive both labels. Speech-only and music-only clips provide controls for checking false alarms. Speech-to-music ratio (SMR) sets the relative source power: negative values mean music is stronger, and positive values mean speech is stronger.

The comparison also examines two practical modifications: equal rather than empirical class priors for the SVM, and validation-selected rather than fixed 0.5 thresholds for YAMNet. The aim is to measure how these choices affect detection and false alarms as the relative source level changes. Model settings are chosen using validation data before evaluating the reserved test sources.

## Approach

- **Audio:** source files are separated into training, validation and test partitions before extracting central two-second, mono, 16 kHz excerpts. Each speech/music pair produces two pure-source controls and mixtures at specified SMRs.
- **Features:** RMS, zero-crossing rate, five spectral descriptors and 13 MFCCs are measured in 25 ms frames with a 10 ms hop. Their means and standard deviations give 40 features per clip.
- **Systems:** separate linear SVMs detect speech and music, using scaling fitted on training data. Frozen YAMNet supplies a pretrained comparison. The MATLAB model uses softmax outputs; its weights and output layer are kept fixed.
- **Evaluation:** balanced accuracy is the primary measure, supported by F1, confusion counts, recall versus SMR and paired source-pair confidence intervals. The same test clips are used for every system.

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

## Conclusion

Relative source level strongly affected detection. When speech was 20 dB below music, speech recall was 0.20 for the balanced SVM and 0.00 for validation-threshold YAMNet. When music was 20 dB below speech, music recall was 0.52 and 0.26 respectively.

Class balancing and validation-selected thresholds improved balanced accuracy on the final test set. The balanced SVM had the highest point estimates for both targets, with its music result very close to YAMNet's. Balancing reduced false alarms at the cost of more missed positives; threshold selection recovered YAMNet detections but did not solve the weak-source problem.

These findings apply to short, controlled MUSAN mixtures and source-track labels. File-level separation does not guarantee unseen speakers or artists, and the experiment does not establish performance on natural mixtures or silence/noise-only recordings. The [final analysis](docs/final_results.md) discusses these limits and the conditional confidence intervals.

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
