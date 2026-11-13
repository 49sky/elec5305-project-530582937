# MUSAN setup

Download the complete corpus from [OpenSLR](https://www.openslr.org/17/) and extract its speech and music folders as:

```text
data/musan/speech/
data/musan/music/
```

The official compressed archive is about 11 GB. The GitHub audio workflow streams it to a temporary runner, extracts speech/music and checks that both contain WAV files. Routine test runs download no audio.

Keep MUSAN's licence, README and annotation files with the recordings. The corpus uses CC BY 4.0; individual source credits accompany the generated demo clips. The audio itself is excluded from Git.

`create_source_split` sorts and shuffles files using seed `530582937`, then assigns 70% to training, 15% to validation and the remainder to testing. Derived segments and mixtures stay in their source partition. The committed CSV fixes the source order used by the final protocol.

Development uses test indices 1-10. The recorded final experiment uses indices 11-60. Reproductions keep that same selection.

Labels describe which source tracks were included. Music may contain vocals, and file-level splits do not guarantee different speakers or artists. See the [methods](../docs/methods.md).
