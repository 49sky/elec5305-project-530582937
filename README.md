# ELEC5305 Project – Speech and Music Presence Detection in Overlapping Audio

## Overview

This project investigates how reliably speech and music can be detected when both are present in the same audio recording.

The main research question is:

> How does the relative level of speech and music affect the ability to detect both sources in an overlapping mixture, and how do interpretable audio features compare with a pretrained audio classifier as one source becomes progressively weaker?

The project is implemented primarily in MATLAB.

The original preliminary run is preserved in [results/archive/preliminary-2026-10-27](results/archive/preliminary-2026-10-27/). The current experiment adds class-balanced evaluation, a controlled SVM weighting comparison, and validation-selected YAMNet thresholds. New development results are written to `results/development/`; the reserved final test set is separate.

[Method notes and references](docs/methods.md) describe the design. The [development analysis](docs/development_results.md) explains the measured changes and remaining errors. The [experiment log](docs/experiments.md) records what has been tested and what remains to do.

## Speech-to-Music Ratio

Controlled mixtures are generated using

```text
x[n] = s[n] + a m[n]
```

where `s[n]` is speech, `m[n]` is music, and `a` controls the relative level of the music signal.

The speech-to-music ratio is

```text
SMR = 10 log10(Pspeech / Pmusic)
```

The planned experiment uses:

- -20 dB
- -10 dB
- -5 dB
- 0 dB
- +5 dB
- +10 dB
- +20 dB

Positive SMR means speech is stronger than music. Negative SMR means music is stronger.

## Dataset

The project uses speech and music recordings from the MUSAN corpus.

Source recordings are divided into training, validation and test sets before segmentation or mixture generation. This keeps segments from the same original recording in a single partition.

MUSAN: https://www.openslr.org/17/

The dataset itself is not stored in this repository.

Download the complete corpus from the [official MUSAN page](https://www.openslr.org/17/) and extract `musan/` inside `data/`. CI streams that official archive and extracts the speech/music folders. The archive is about 11 GB; allow enough download time and disk space. The former CI mirror contained noise audio only and is no longer used.

## Detection Task

Two independent binary outputs are used:

| Audio | Speech present | Music present |
|---|---:|---:|
| Speech only | 1 | 0 |
| Music only | 0 | 1 |
| Speech + music | 1 | 1 |

These labels describe which source recordings were included in the mixture. MUSAN music can contain vocals, so a music-only label is not a guarantee that the excerpt contains no human voice. Source-file separation also does not establish speaker- or artist-independent testing. These limits matter when interpreting errors.

## System A – Handcrafted Features

The first system extracts frame-based audio features including:

- RMS energy
- zero-crossing rate
- spectral centroid
- spectral flux
- spectral rolloff
- spectral bandwidth
- spectral flatness
- MFCCs

Frame-level measurements are summarised over each segment using the mean and sample standard deviation. Two separate linear SVMs detect:

- speech presence detector
- music presence detector

`handcrafted_features` uses 25 ms periodic Hann windows with a 10 ms hop and the next power-of-two FFT length (512 at 16 kHz). RMS and zero-crossing rate use the unwindowed frames. Spectral centroid and bandwidth (weighted standard deviation in Hz) use power-spectrum weights; flux is the L2 change between consecutive unit-sum power spectra, with the first frame set to zero. Rolloff contains 85% of spectral power and flatness is the geometric/arithmetic power ratio. MFCCs use 40 triangular HTK-mel bands from 20 Hz to Nyquist, natural log energies floored at `1e-12`, and an orthonormal DCT, retaining c0–c12 without deltas, liftering or pre-emphasis. The same floor stabilizes flatness; silent-frame scalar spectral descriptors are zero.

The seven scalar features and 13 MFCCs produce 20 frame measurements and **40 segment features**, ordered as all means followed by all standard deviations. Incomplete trailing frames are dropped; a segment shorter than one window is zero-padded to one frame. Feature names are exported with the data. These definitions use base MATLAB; extraction does not learn a transform from the dataset.

Two versions use the same 40 features and the same training-only mean/sample-standard-deviation scaling. Constant features use scale one. The unweighted version uses empirical class priors; the balanced version uses equal priors. MATLAB receives already-scaled features with `Standardize=false`, so weighting cannot change the scaling transform.

Each detector selects `BoxConstraint` from `[0.01 0.1 1 10]` using validation balanced accuracy; ties select the smallest value. This rule is the same for both versions. Training sources alone fit the selected model. Predictions use the zero-margin boundary; margins are decision scores, not probabilities. The archived October run used validation F1 and MATLAB's internal scaling, so its numbers document the original iteration rather than an otherwise identical weighting comparison.

## System B – YAMNet

The second system uses pretrained YAMNet through MATLAB Audio Toolbox.

The project uses the MATLAB `audioPretrainedNetwork("yamnet")` model, whose documented output head is softmax. TensorFlow's reference YAMNet instead uses independent sigmoid outputs. Here, classes compete for a total score of one: two mean scores cannot both exceed 0.5. The fixed-threshold reference has this limitation. The output head and weights stay unchanged, and new runs record the layer type. See the [model documentation](https://www.mathworks.com/help/audio/ref/audiopretrainednetwork.html).

YAMNet's pretrained weights are frozen. Mean Speech and Music scores are extracted separately for validation and test excerpts. We retain the fixed 0.5 rule and compare it with thresholds selected independently for speech and music from `0:0.05:1` using validation balanced accuracy. Ties favour the candidate nearest 0.5, then the smaller threshold. Test scores and labels do not enter threshold selection.

## Preliminary Implementation

The current code includes:

- MUSAN speech and music file indexing
- reproducible source-level train/validation/test splitting
- audio conversion to mono and 16 kHz
- fixed-duration segment extraction
- controlled mixture generation at a requested SMR
- measured SMR verification
- STFT spectrogram generation
- pretrained YAMNet inference
- Speech and Music score extraction
- handcrafted feature extraction and separate linear speech/music SVMs
- pure speech and pure music examples providing negatives for each detector
- validation-only SVM selection and held-out comparison metrics and plots
- saved models, feature schema, source provenance and run configuration
- unweighted and class-balanced SVMs with identical feature scaling
- an always-present reference, specificity, balanced accuracy and confusion matrices
- fixed and validation-selected YAMNet decision rules

By default, the preliminary experiment uses 10 speech/music source pairs **in each** of the train, validation and test partitions, with three SMR values:

```text
-10 dB, 0 dB, +10 dB
```

Each pair contributes one speech-only segment, one music-only segment and three mixtures: 50 examples per partition (150 total). Sources are paired in their saved split order; one central 2 s segment per source is converted to mono/16 kHz and DC-removed. Pure segments and mixtures are all peak-normalized to 0.99. No source is reused across partitions; duplicate source paths fail before feature extraction. The small defaults are a smoke experiment, not a final performance estimate. Only test examples contribute to reported evaluation; the original demo used validation mixtures, so its old results are not directly comparable.

Routine development runs are restricted to the first ten test sources of each type, which have already been inspected. They do not use the remaining test sources. The [final protocol](config/final_protocol.json) fixes 100 training pairs, 30 validation pairs and 50 test pairs at indices 11-60, with the full seven-SMR grid. It has a dry-run preview and checks that the split matches the archived manifest and the selected test files were absent from the preliminary run.

## Repository Structure

```text
.
├── README.md
├── data/
│   └── README.md
├── config/final_protocol.json
├── docs/
│   ├── methods.md
│   ├── development_results.md
│   └── experiments.md
├── src/
│   ├── create_source_split.m
│   ├── make_smr_mixture.m
│   ├── read_audio_segment.m
│   ├── yamnet_scores.m
│   ├── handcrafted_features.m
│   ├── build_presence_dataset.m
│   ├── train_handcrafted_baseline.m
│   ├── predict_handcrafted_baseline.m
│   ├── presence_metrics.m
│   ├── evaluate_presence_systems.m
│   ├── plot_presence_comparison.m
│   ├── validate_source_split.m
│   ├── select_presence_thresholds.m
│   ├── bootstrap_presence_metrics.m
│   ├── review_presence_results.m
│   ├── presence_demo.m
│   ├── run_final_experiment.m
│   └── preliminary_mixture_demo.m
├── tests/
│   └── test_handcrafted_baseline.m
└── results/
    ├── archive/preliminary-2026-10-27/
    └── development/
```

## Running the Preliminary Experiment

Place the MUSAN speech and music folders under:

```text
data/musan/speech/
data/musan/music/
```

From the repository root in MATLAB:

```matlab
addpath("src")
create_source_split
preliminary_mixture_demo
```

`preliminary_mixture_demo` reuses `data/splits/source_split.mat` when it exists and creates it only when missing. Recreate the split explicitly after changing the corpus; otherwise keep it fixed between comparisons. Source paths within the repository are relative to its root. File discovery is sorted before seeded shuffling (`530582937`, Twister), and both splitting and the experiment restore the caller's RNG state.

For a larger training set or the full planned SMR grid:

```matlab
run = preliminary_mixture_demo(TrainPairs=100, ValidationPairs=10, TestPairs=10, ...
    SMRValues=[-20 -10 -5 0 5 10 20], ResultsDir="results/full_grid");
```

This command still uses the ten development test pairs. To preview the reserved final source selection, without loading any audio or model:

```matlab
selected = run_final_experiment;
```

The final run is a separate, explicit operation after the development comparison is complete:

```matlab
run = run_final_experiment(DryRun=false);
```

That command needs MUSAN locally and writes to `results/final/`. It refuses to overwrite an existing final prediction table. Routine push checks use synthetic audio and saved development predictions. Audio experiments are separate manual workflow runs; select `development` or `final`.

For a deliberate reproduction, keep the same protocol and use a new output directory:

```matlab
run = run_final_experiment(DryRun=false, ResultsDir="results/final_reproduction");
```

`ResultsDir` changes only the output location; source selections, SMRs and selection rules still come from the frozen protocol.

Each requested partition must contain at least the specified number of sources of both types. A short or silent central segment raises an error identifying the issue rather than silently changing the selected corpus. The first YAMNet run may download its pretrained model from MathWorks and requires internet access.

To run the baseline without downloading or loading YAMNet:

```matlab
run = preliminary_mixture_demo(UseYAMNet=false, ResultsDir="results/svm_only");
```

Use a separate `ResultsDir` for each configuration so earlier YAMNet outputs cannot be mistaken for outputs from a baseline-only run. `MakePlots=false` skips PNG generation. Equivalent batch execution from a terminal in the repository root is:

```sh
matlab -batch 'addpath("src"); create_source_split; preliminary_mixture_demo'
```

The run saves the following under `ResultsDir` (default `results/development/`):

| Output | Contents |
|---|---|
| `preliminary_handcrafted_features.csv` | All partitions, source paths, binary labels, SMRs and 40 named features |
| `preliminary_svm_tuning.csv` | Validation balanced accuracy, F1 and specificity for each variant/target/C candidate |
| `preliminary_handcrafted_models.mat` | Four compact SVMs, shared scaling, selected thresholds, split, feature schema, configuration and MATLAB/toolbox versions |
| `preliminary_presence_predictions.csv` | All test examples, labels, SVM margins/decisions and YAMNet scores/decisions when enabled |
| `preliminary_presence_metrics.csv` | Counts, precision, recall, F1, specificity, balanced accuracy, macro-F1 and class counts |
| `preliminary_confusion_counts.csv` | Confusion counts and fractions within each actual class |
| `preliminary_yamnet_validation_scores.csv` | Validation metadata and raw YAMNet scores |
| `preliminary_yamnet_thresholds.csv` | Validation scores for each candidate threshold and the selected rules |
| `run_manifest.json` | Configuration, source selections, code revision and software versions |
| `preliminary_metric_intervals.csv` | 95% source-pair percentile intervals for balanced accuracy and F1 |
| `preliminary_paired_comparisons.csv` | Paired balanced-accuracy differences for the two controlled modifications |
| `preliminary_error_cases.csv` | Labelled mistakes and source/audio paths for inspection |
| `evaluation_manifest.json` | Evaluation settings, input model-run revision and evaluation code revision |
| `preliminary_recall_vs_smr.csv` | Test mixture speech/music/weak-source recall and sample counts at each SMR |
| `preliminary_results.csv` | Original mixture-only result table, extended with test labels and baseline predictions |
| `preliminary_yamnet_summary.csv` | Original mean/std YAMNet score summary for test mixtures (when enabled) |
| `preliminary_audio/*.wav` | Test mixtures and the first pair's pure-source excerpts; source credits accompany the demo |
| `preliminary_figures/*.png` | First three pairs' waveforms/spectrograms, metric comparisons, confusion matrices, SMR curves and confidence intervals |

To reproduce predictions from a saved baseline:

```matlab
saved = load("results/development/preliminary_handcrafted_models.mat");
x = read_audio_segment("path/to/audio.wav", saved.configuration.SampleRate, ...
    saved.configuration.DurationSec);
x = 0.99*x/max(abs(x)); % same peak normalization as the experiment
[features, names] = handcrafted_features(x, saved.configuration.SampleRate);
assert(isequal(names, saved.featureNames));
[present, margins] = predict_handcrafted_baseline(saved.models, features);
[balancedPresent, balancedMargins] = predict_handcrafted_baseline(saved.balancedModels, features);
% Columns are [speech, music].
```

## Small Audio Demo

Download the `preliminary-handcrafted-models` and `presence-demo` artifacts from the same successful Actions run. The demo contains five short clips from one pair: pure speech, pure music, and mixtures at -10, 0 and +10 dB. Keep the accompanying `SOURCES.txt` and attribution files with the audio. No full MUSAN download is needed for this demonstration.

After extracting the artifacts, supply the actual paths:

```matlab
addpath("src")
presence_demo("path/to/pair_01_smr_+0.wav", "path/to/preliminary_handcrafted_models.mat", ...
    PlayAudio=true);
```

The demo plots the audio and displays the two SVM versions' decisions and margins. It does not load YAMNet; the full comparison's YAMNet results are saved in the CSVs. Audio playback is off unless requested. A demonstration on an arbitrary file is an illustration, not an additional labelled test result.

## Checks and Workflow

Run regression tests without MUSAN, Audio Toolbox or a YAMNet download:

```matlab
addpath("src")
tests = runtests("tests");
assertSuccess(tests)
```

The tests generate temporary synthetic audio, check known feature values and source separation, verify training-only scaling and held-out isolation, reload saved models, and run baseline extraction/training/evaluation/plot export end to end. They require Signal Processing Toolbox and Statistics and Machine Learning Toolbox.

Result-publication regression tests use Python's standard library and temporary local Git repositories. They reproduce a branch update during an experiment, a competing binary result update, an experiment-code update, and unchanged outputs:

```sh
python3 -m unittest discover -s tests -p 'test_publish_results.py' -v
```

Pushes run the Python and MATLAB tests and review the saved development predictions. This path uses synthetic fixtures and CSVs, so it does not download MUSAN or load YAMNet. It publishes the added intervals, paired comparisons, error-case table and confidence plot. Existing model decisions and the source run manifest are preserved.

For an audio experiment, open **Actions → MATLAB Presence Experiment → Run workflow → main**. Select `development` for the small comparison or `final` for the fixed final protocol. The runner downloads MUSAN and the pretrained model, runs the checks and selected experiment, and saves its outputs. Final runs use the archived source split and test pairs 11–60; the workflow refuses to overwrite existing final predictions.

Development artifacts are `preliminary-handcrafted-models`, `preliminary-results` and `presence-demo`. Final runs use `final-handcrafted-models`, `final-results` and `presence-demo`. The final demo contains the first reserved pair at seven SMRs plus its pure-source clips. Preserve the source credits. Models and generated WAVs stay out of Git and can be regenerated; artifacts have a retention period.

A separate publication job updates only the chosen output directory and the source-split CSV. It preserves historical results, rebases onto unrelated branch updates and retries ordinary push races. If experiment code, the protocol or conflicting results changed during the run, the outputs remain in the artifact. Publication can be retried without rerunning the experiment. A historical workflow rerun uses that run's old code.

To repeat only the evaluation of an existing prediction table:

```matlab
addpath("src")
[intervals, comparisons] = review_presence_results("results/development");
```

This writes 95% percentile intervals using 2,000 source-pair resamples and seed `530582937`. Optional `Resamples`, `Seed` and `MakePlot` arguments control the review. Audio experiments use the same defaults through `BootstrapResamples` and `BootstrapSeed`.

## Evaluation

Both systems report on the same test set:

- speech precision, recall and F1-score
- music precision, recall and F1-score
- speech recall versus SMR
- music recall versus SMR
- weaker-source recall
- specificity, balanced accuracy, macro-F1 and per-output confusion matrices

The always-present reference exposes the effect of prevalence: it obtains F1 0.889 with the three-SMR design, despite zero specificity. With seven SMRs, the same rule obtains F1 0.941 because each detector has eight positives for every negative. Balanced accuracy averages sensitivity and specificity, giving this rule 0.5. Macro-F1 here averages the present-class and absent-class F1 for each output; it is not an average over SMRs.

Overall precision/recall/F1 includes pure-source negatives and mixtures. SMR curves use mixtures only. Speech is weaker at negative SMR and music at positive SMR. At 0 dB neither source is weaker, so weaker-source recall is `NaN` with count zero and is omitted from that curve. Undefined precision/recall/F1 ratios are reported as zero. The corpus has no neither-source class; the preliminary evaluation does not measure silence/noise rejection.

Specificity is `NaN` when there are no negatives; balanced accuracy and macro-F1 are `NaN` if either actual class is absent. The normal experiment includes both classes. Repeated mixtures of a source pair are related observations. The bootstrap resamples whole pairs, including their controls, and uses shared draws for every system and paired difference. Its intervals describe test-source variation with fitted models and selected thresholds fixed. They do not include retraining or threshold-selection uncertainty. File-level grouping also leaves possible dependence between recordings by the same speaker or artist.

## MATLAB Requirements

- MATLAB R2024a or later (CI uses R2026b)
- Signal Processing Toolbox
- Audio Toolbox
- Deep Learning Toolbox
- Statistics and Machine Learning Toolbox

## Course

ELEC5305 – Acoustics, Speech and Signal Processing  
The University of Sydney
