# MUSAN Dataset

The MUSAN dataset is used for the speech and music source recordings.

Download: https://www.openslr.org/17/

Expected local structure:

```text
data/
└── musan/
    ├── speech/
    └── music/
```

The dataset is excluded from Git because of its size.

Source recordings are split into training, validation and test partitions before any segmentation or mixture generation.
