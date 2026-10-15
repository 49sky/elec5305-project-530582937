# ELEC5305 Project – Speech and Music Presence Detection in Overlapping Audio

## Overview

This project investigates how reliably speech and music can be detected when both are present in the same audio recording.

The main research question is:

> How does the relative level of speech and music affect the ability to detect both sources in an overlapping mixture, and how do interpretable audio features compare with a pretrained audio classifier as one source becomes progressively weaker?

The project is implemented primarily in MATLAB.

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

## Detection Task

Two independent binary outputs are used:

| Audio | Speech present | Music present |
|---|---:|---:|
| Speech only | 1 | 0 |
| Music only | 0 | 1 |
| Speech + music | 1 | 1 |

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

SVM feature scaling is fitted on training rows only. Each detector selects its own `BoxConstraint` from `[0.01 0.1 1 10]` using validation F1; ties select the smallest value. The selected model remains fitted only on training sources. Predictions use the SVM's zero-margin boundary. Exported SVM margins are decision scores, not probabilities.

## System B – YAMNet

The second system uses pretrained YAMNet through MATLAB Audio Toolbox.

YAMNet is used as a reference model only and is not retrained or fine-tuned. Mean Speech and Music scores are extracted for every held-out segment. Each output uses a fixed, a priori threshold of 0.5 for presence evaluation.

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

By default, the preliminary experiment uses 10 speech/music source pairs **in each** of the train, validation and test partitions, with three SMR values:

```text
-10 dB, 0 dB, +10 dB
```

Each pair contributes one speech-only segment, one music-only segment and three mixtures: 50 examples per partition (150 total). Sources are paired in their saved split order; one central 2 s segment per source is converted to mono/16 kHz and DC-removed. Pure segments and mixtures are all peak-normalized to 0.99. No source is reused across partitions; duplicate source paths fail before feature extraction. The small defaults are a smoke experiment, not a final performance estimate. Only test examples contribute to reported evaluation; the original demo used validation mixtures, so its old results are not directly comparable.

## Repository Structure

```text
.
├── README.md
├── data/
│   └── README.md
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
│   └── preliminary_mixture_demo.m
├── tests/
│   └── test_handcrafted_baseline.m
└── results/
    ├── preliminary_audio/
    └── preliminary_figures/
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

Each requested partition must contain at least the specified number of sources of both types. A short or silent central segment raises an error identifying the issue rather than silently changing the selected corpus. The first YAMNet run may download its pretrained model from MathWorks and requires internet access.

To run the baseline without downloading or loading YAMNet:

```matlab
run = preliminary_mixture_demo(UseYAMNet=false, ResultsDir="results/svm_only");
```

Use a separate `ResultsDir` for each configuration so earlier YAMNet outputs cannot be mistaken for outputs from a baseline-only run. `MakePlots=false` skips PNG generation. Equivalent batch execution from a terminal in the repository root is:

```sh
matlab -batch 'addpath("src"); create_source_split; preliminary_mixture_demo'
```

The run saves the following under `ResultsDir` (default `results/`):

| Output | Contents |
|---|---|
| `preliminary_handcrafted_features.csv` | All partitions, source paths, binary labels, SMRs and 40 named features |
| `preliminary_svm_tuning.csv` | Validation F1 for each target/C candidate and the selected candidate |
| `preliminary_handcrafted_models.mat` | Both compact SVMs with training scaling, split, selected-source metadata, feature names, configuration, seed and MATLAB/toolbox versions |
| `preliminary_presence_predictions.csv` | All test examples, labels, SVM margins/decisions and YAMNet scores/decisions when enabled |
| `preliminary_presence_metrics.csv` | Test TP/FP/FN/TN, precision, recall and F1 per system and target |
| `preliminary_recall_vs_smr.csv` | Test mixture speech/music/weak-source recall and sample counts at each SMR |
| `preliminary_results.csv` | Original mixture-only result table, extended with test labels and baseline predictions |
| `preliminary_yamnet_summary.csv` | Original mean/std YAMNet score summary for test mixtures (when enabled) |
| `preliminary_audio/*.wav` | Test mixtures |
| `preliminary_figures/*.png` | Pair waveforms/spectrograms, metric comparison, recall-versus-SMR comparison and original YAMNet score plot |

To reproduce predictions from a saved baseline:

```matlab
saved = load("results/preliminary_handcrafted_models.mat");
x = read_audio_segment("path/to/audio.wav", saved.configuration.SampleRate, ...
    saved.configuration.DurationSec);
x = 0.99*x/max(abs(x)); % same peak normalization as the experiment
[features, names] = handcrafted_features(x, saved.configuration.SampleRate);
assert(isequal(names, saved.featureNames));
[present, margins] = predict_handcrafted_baseline(saved.models, features);
% Columns are [speech, music].
```

Run regression tests without MUSAN, Audio Toolbox or a YAMNet download:

```matlab
addpath("src")
tests = runtests("tests");
assertSuccess(tests)
```

The tests generate temporary synthetic audio, check known feature values and source separation, verify training-only scaling and held-out isolation, reload saved models, and run baseline extraction/training/evaluation/plot export end to end. They require Signal Processing Toolbox and Statistics and Machine Learning Toolbox. GitHub Actions runs the same checks before downloading MUSAN, then runs the full comparison and commits the generated CSVs/PNGs. It uploads the model MAT-file as the `preliminary-handcrafted-models` workflow artifact; model files and generated WAVs are excluded from Git.

## Evaluation

Both systems report on the same test set:

- speech precision, recall and F1-score
- music precision, recall and F1-score
- speech recall versus SMR
- music recall versus SMR
- weaker-source recall

Overall precision/recall/F1 includes pure-source negatives and mixtures. SMR curves use mixtures only. Speech is weaker at negative SMR and music at positive SMR. At 0 dB neither source is weaker, so weaker-source recall is `NaN` with count zero and is omitted from that curve. Undefined precision/recall/F1 ratios are reported as zero. The corpus has no neither-source class; the preliminary evaluation does not measure silence/noise rejection.

## MATLAB Requirements

- MATLAB R2024a or later (CI uses R2026b)
- Signal Processing Toolbox
- Audio Toolbox
- Deep Learning Toolbox
- Statistics and Machine Learning Toolbox

## Course

ELEC5305 – Acoustics, Speech and Signal Processing  
The University of Sydney
