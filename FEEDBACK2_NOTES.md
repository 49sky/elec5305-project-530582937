# Feedback 2 – Preliminary Implementation

This repository now contains the preliminary implementation for the revised ELEC5305 project.

## Implemented

- source-level MUSAN speech/music indexing
- reproducible 70/15/15 train/validation/test split
- controlled speech/music mixture generation at a target SMR
- measured SMR verification
- fixed-length 16 kHz audio preparation
- preliminary mixtures at -10, 0 and +10 dB
- STFT spectrogram generation
- pretrained YAMNet inference
- Speech and Music YAMNet score extraction
- preliminary score-versus-SMR summary

## Main preliminary script

Run:

```matlab
addpath("src")
preliminary_mixture_demo
```

The preliminary experiment uses 10 validation speech sources and 10 validation music sources. For each pair it generates mixtures at -10, 0 and +10 dB SMR.

## Expected outputs

```text
results/
├── preliminary_results.csv
├── preliminary_yamnet_summary.csv
├── preliminary_audio/
└── preliminary_figures/
```

The handcrafted feature/SVM system is intentionally the next milestone. The current code first verifies the controlled-mixture and YAMNet reference pipeline.
