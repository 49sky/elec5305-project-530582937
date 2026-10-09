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

The first system will use frame-based audio features including:

- RMS energy
- zero-crossing rate
- spectral centroid
- spectral flux
- spectral rolloff
- spectral bandwidth
- spectral flatness
- MFCCs

Frame-level measurements will be summarised over each audio segment using statistics such as mean and standard deviation.

Two linear SVMs will then be used:

- speech presence detector
- music presence detector

## System B – YAMNet

The second system uses pretrained YAMNet through MATLAB Audio Toolbox.

YAMNet is used as a reference model only and is not retrained or fine-tuned. Speech and Music output scores are extracted for each mixture.

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

The preliminary experiment uses 10 speech sources, 10 music sources and three SMR values:

```text
-10 dB, 0 dB, +10 dB
```

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
│   └── preliminary_mixture_demo.m
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

The scripts save generated mixtures, figures and CSV results under `results/`.

## Planned Evaluation

The final evaluation will report:

- speech precision, recall and F1-score
- music precision, recall and F1-score
- speech recall versus SMR
- music recall versus SMR
- weaker-source recall

## MATLAB Requirements

- MATLAB
- Signal Processing Toolbox
- Audio Toolbox
- Deep Learning Toolbox
- Statistics and Machine Learning Toolbox

## Course

ELEC5305 – Acoustics, Speech and Signal Processing  
The University of Sydney
