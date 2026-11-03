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

Keep the corpus's LICENSE, README and ANNOTATIONS files. MUSIC recordings may
contain vocals; the experiment's labels refer to the source tracks mixed in.
The split is by file, not necessarily by speaker or artist. See
[method notes](../docs/methods.md) for the implications.

Development uses test source indices 1-10 only. The final protocol reserves
indices 11-60 and checks the committed split against the original manifest.
Do not recreate or reshuffle the split to replace difficult final examples.
