# MUSAN Dataset Setup

The MUSAN dataset is not stored in this repository.

Download MUSAN from:

https://www.openslr.org/17/

After extraction, the preliminary MATLAB code expects:

```text
data/
└── musan/
    ├── speech/
    │   └── ... WAV files
    └── music/
        └── ... WAV files
```

The scripts recursively search the speech and music directories.

The source recordings are split before segmentation or mixture generation so that one original source file cannot appear in more than one of the training, validation or test partitions.
