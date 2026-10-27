# MUSAN Dataset

The MUSAN dataset is used for the speech and music source recordings.

Download: https://www.openslr.org/17/

Use the complete official MUSAN archive. Some third-party mirrors contain only noise WAVs and cannot run this speech/music experiment. CI extracts the official speech and music folders and verifies that each contains WAV files before starting MATLAB.

Expected local structure:

```text
data/
└── musan/
    ├── speech/
    └── music/
```

The dataset is excluded from Git because of its size.

Source recordings are split into training, validation and test partitions before any segmentation or mixture generation.
