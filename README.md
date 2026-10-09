# elec5305-project-530582937

# ELEC5305 Project – Speech and Music Presence Detection in Overlapping Audio

## Project Overview

This project investigates the detection of speech and music when both sources occur simultaneously in an audio recording.

Instead of classifying an audio sample as either speech or music, the system will independently determine:

- whether speech is present;
- whether music is present.

The main research question is:

> **How does the relative level of speech and music affect the ability to detect both sources in an overlapping mixture, and how do interpretable audio features compare with a pretrained audio classifier as one source becomes progressively weaker?**

The project will be implemented primarily in MATLAB and will compare a handcrafted signal-processing approach with pretrained YAMNet.

## Speech-to-Music Ratio

Controlled speech/music mixtures will be generated using:

\[
x[n] = s[n] + a\,m[n]
\]

where:

- `s[n]` is the speech signal;
- `m[n]` is the music signal;
- `a` controls the relative level of music.

The speech-to-music ratio (SMR) is defined as:

\[
SMR = 10\log_{10}\left(\frac{P_{speech}}{P_{music}}\right)
\]

The main experiment will use:

- -20 dB
- -10 dB
- -5 dB
- 0 dB
- +5 dB
- +10 dB
- +20 dB

Positive SMR means speech is stronger than music, while negative SMR means music is stronger.

## Dataset

The main dataset will be the **MUSAN speech and music corpus**.

Speech and music source recordings will first be divided into separate:

- training;
- validation;
- test

partitions.

The source split will be completed **before segmentation and mixture generation** so that segments from the same original recording cannot appear in multiple partitions.

This avoids data leakage between training and testing.

## Output Labels

The project uses a multi-label formulation with two independent binary outputs:

| Audio condition | Speech present | Music present |
|---|---:|---:|
| Speech only | 1 | 0 |
| Music only | 0 | 1 |
| Speech + music | 1 | 1 |

The system therefore answers:

1. **Is speech present?**
2. **Is music present?**

## System A – Handcrafted Audio Features

The first detection system will use interpretable audio features calculated in MATLAB.

Initial features include:

- RMS energy;
- zero-crossing rate;
- spectral centroid;
- spectral flux;
- spectral rolloff;
- spectral bandwidth;
- spectral flatness;
- MFCCs.

Features will be calculated on short audio frames and then aggregated over each analysis segment using statistics such as mean and standard deviation.

Two linear support vector machines will then be trained:

- speech-presence SVM;
- music-presence SVM.

The purpose is not to compare many machine-learning algorithms, but to investigate how interpretable signal-processing features behave when speech and music overlap.

## System B – YAMNet

The second system will use pretrained **YAMNet** through MATLAB Audio Toolbox.

YAMNet will be used only as a pretrained reference system and will not be retrained or fine-tuned.

Speech- and music-related output scores will be examined for each audio mixture and compared with the handcrafted SVM system.

## Proposed Experimental Method

The project will follow these main steps:

1. Obtain speech and music recordings from MUSAN.
2. Create source-disjoint training, validation and test partitions.
3. Convert audio to a consistent format and sampling rate.
4. Segment selected source recordings.
5. Generate controlled speech/music mixtures at specified SMRs.
6. Verify the measured SMR of each generated mixture.
7. Generate STFT spectrograms for representative examples.
8. Extract frame-based audio features.
9. Aggregate features over each audio segment.
10. Train separate linear SVM speech and music detectors.
11. Run pretrained YAMNet on the same mixtures.
12. Select detection thresholds using validation data.
13. Evaluate both systems using unseen test sources.
14. Analyse detection performance as a function of SMR.
15. Examine representative success and failure cases.

## Evaluation

Performance will be reported separately for speech and music using:

- precision;
- recall;
- F1-score.

The main analysis will examine:

- speech recall versus SMR;
- music recall versus SMR;
- weaker-source recall versus relative source level.

The project will investigate how detection performance changes as either speech or music becomes progressively weaker in the mixture.

Representative failure cases will also be analysed using waveforms, spectrograms, audio features and YAMNet scores.

## Initial Milestone

The first proof-of-concept experiment will use:

- 10 speech recordings;
- 10 music recordings;
- SMR = -10 dB, 0 dB and +10 dB.

For selected mixtures, the initial implementation will produce:

- waveform;
- spectrogram;
- measured SMR;
- YAMNet speech score;
- YAMNet music score.

Once this pipeline is verified, the experiment will be expanded to a larger dataset and the full set of SMR values.

## Expected Outcome

The expected outcome is a reproducible MATLAB-based system that demonstrates how speech and music detection performance changes under controlled overlapping conditions.

The final project will compare:

**Handcrafted audio features + two linear SVM detectors**

with:

**Pretrained YAMNet speech/music scores**

The main result will not simply be an overall classification accuracy. Instead, the project will determine how reliably each system detects speech and music as the relative acoustic level between the two sources changes.

## Tools

- MATLAB
- Signal Processing Toolbox
- Audio Toolbox
- Statistics and Machine Learning Toolbox
- Pretrained YAMNet
- MUSAN dataset

## Repository Structure

The repository is expected to contain:

```text
elec5305-project-530582937/
│
├── README.md
├── proposal/
│   └── revised_project_proposal.pdf
│
├── src/
│   ├── dataset/
│   ├── mixture_generation/
│   ├── features/
│   ├── svm/
│   ├── yamnet/
│   └── evaluation/
│
├── results/
│   ├── figures/
│   └── tables/
│
├── docs/
│   └── literature_review/
│
└── final_report/
