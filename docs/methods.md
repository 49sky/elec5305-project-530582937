# Methods

## Task and data

Each excerpt has two outputs: speech present and music present. Speech-only clips have labels `[1,0]`, music-only clips `[0,1]`, and mixtures `[1,1]`.

MUSAN [2] supplies the source recordings. Files are split before extracting one central two-second excerpt per source. Audio is converted to mono, resampled to 16 kHz and DC-removed. Source files are never shared across partitions. The saved source order determines the speech/music pairs.

Mixtures use `x = speech + a*music`, with `a` chosen so that `SMR = 10*log10(Pspeech/Pmusic)`. Positive SMR means speech is stronger. Pure controls and mixtures are peak-normalised to 0.99. The measured source-power ratio is checked before mixing.

The final protocol uses 100 training pairs, 30 validation pairs and 50 test pairs at indices 11-60 of the archived split. Each pair supplies two controls and seven mixtures at `[-20 -10 -5 0 5 10 20]` dB. Short or silent source excerpts raise an error rather than silently changing the source selection.

## Handcrafted features

Frames use a 25 ms periodic Hann window and 10 ms hop. The FFT uses the next power of two: 512 points at 16 kHz. The seven scalar features are:

| Feature | Definition |
| --- | --- |
| RMS | Square root of mean squared samples, before windowing |
| Zero-crossing rate | Fraction of adjacent unwindowed samples with different signs |
| Spectral centroid | Mean frequency weighted by spectral power |
| Spectral flux | L2 change between successive unit-sum power spectra; first frame is zero |
| Rolloff | Frequency containing 85% of spectral power |
| Bandwidth | Power-weighted frequency standard deviation |
| Flatness | Geometric/arithmetic mean ratio of spectral power |

MFCCs use 40 triangular HTK-mel bands from 20 Hz to Nyquist, natural-log energies floored at `1e-12`, and an orthonormal DCT retaining c0-c12. There are no deltas, liftering or pre-emphasis. The same floor stabilises flatness. Silent frames have zero centroid, bandwidth, rolloff and flatness; flux still reflects the change from the preceding frame.

The 20 frame measurements are summarised as all means followed by all sample standard deviations, giving 40 features. Incomplete trailing frames are dropped. Excerpts shorter than one window are padded to one frame. Feature names are saved with the data and models.

## Linear SVMs

Separate linear SVMs detect speech and music. Both versions use the same training-only mean and sample-standard-deviation transform, with scale one for constant features. MATLAB receives scaled features with `Standardize=false`, since class priors would otherwise affect internal scaling [4].

The unweighted version uses empirical priors; the balanced version uses equal priors. Each target selects C from `[0.01 0.1 1 10]` using validation balanced accuracy, with ties choosing the smallest C. Training sources alone fit the models. Decisions use the zero-margin boundary; margins are scores rather than probabilities.

The archived October model used validation F1 and internal scaling. Its results record the original iteration. The controlled weighting comparison reruns both SVM versions with the same scaling and selection rule.

## MATLAB YAMNet

The reference is the frozen `audioPretrainedNetwork("yamnet")` model [5]. Mean Speech and Music scores are calculated over each excerpt. The MATLAB version has a softmax head; TensorFlow's reference [3] uses independent sigmoid outputs. The recorded head is checked before inference.

Softmax makes classes compete for a total score of one, also bounding the sum of their clip means. Two classes cannot both exceed 0.5. The experiment compares fixed 0.5 decisions with independently selected thresholds from `0:0.05:1`. Validation balanced accuracy selects each threshold. Ties favour the value nearest 0.5, then the smaller value. Weights and output layers stay fixed.

New model artifacts also contain the frozen network and class names for reuse.

## Evaluation

Overall metrics include pure-source controls and mixtures. Precision, recall, positive-class F1, specificity, balanced accuracy, macro-F1 and confusion counts are reported separately for each target. Macro-F1 averages the present- and absent-class F1. An always-present reference shows the effect of class prevalence.

Recall-versus-SMR curves use mixtures only. The weaker source is speech below 0 dB and music above 0 dB. At 0 dB, weaker-source recall is `NaN`, with count zero. An unobserved SMR also has `NaN` recall. Undefined precision/recall/F1 ratios are zero; specificity is `NaN` without negatives, and balanced accuracy and macro-F1 are `NaN` if either class is absent.

Confidence intervals use 2,000 resamples of whole source pairs, including their controls. Shared sampled indices preserve the pairing between systems. The 2.5th and 97.5th percentiles give 95% intervals for balanced accuracy, F1 and paired balanced-accuracy differences [6]. Models and validation-selected thresholds stay fixed, so the intervals cover test-pair variation rather than retraining uncertainty.

## Research context and limits

Scheirer and Slaney [1] motivate combining acoustic descriptors and temporal summaries. The feature definitions and linear models here form a simple baseline. Bhattacharjee et al. [7] study overlap using harmonic-percussive features and multi-task learning on synthetic and real audio. Their work gives context for weak-source errors; this project keeps a smaller model comparison and a controlled SMR sweep.

Labels describe included source tracks. Vocal music and pauses within speech can make these labels differ from audible events. File-level splits do not guarantee new speakers or artists. Short controlled mixtures also leave natural mixtures and silence/noise-only rejection outside the evaluation. Repeated artists or speakers may introduce dependence beyond the source pairs.

## References

1. E. Scheirer and M. Slaney, "Construction and evaluation of a robust multifeature speech/music discriminator," ICASSP, vol. 2, pp. 1331-1334, 1997. [DOI](https://doi.org/10.1109/ICASSP.1997.596192).
2. D. Snyder, G. Chen and D. Povey, "MUSAN: A music, speech, and noise corpus," 2015. [Paper](https://arxiv.org/abs/1510.08484), [corpus and licence](https://www.openslr.org/17/).
3. TensorFlow Models, "YAMNet." [Source and documentation](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet), [output activation](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/params.py).
4. MathWorks, "fitcsvm." [Priors and standardisation](https://www.mathworks.com/help/stats/fitcsvm.html).
5. MathWorks, "audioPretrainedNetwork." [MATLAB YAMNet architecture](https://www.mathworks.com/help/audio/ref/audiopretrainednetwork.html).
6. MathWorks, "bootci." [Bootstrap and percentile intervals](https://www.mathworks.com/help/stats/bootci.html). This implementation resamples source-pair confusion counts directly.
7. M. Bhattacharjee, S. R. M. Prasanna and P. Guha, "Clean vs. Overlapped Speech-Music Detection Using Harmonic-Percussive Features and Multi-Task Learning," IEEE/ACM TASLP, vol. 31, pp. 1-10, 2023. [DOI](https://doi.org/10.1109/TASLP.2022.3164199), [publisher summary](https://signalprocessingsociety.org/publications-resources/ieee-transactions-audio-speech-and-language-processing/2023/01/clean-vs-overlapped-speech-music-detection-using-harmonic-percussive-features-and-multi-task).
