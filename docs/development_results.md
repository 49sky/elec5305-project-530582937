# Development results

The 3 November experiment used ten source pairs in each partition, two-second
excerpts and SMRs of -10, 0 and +10 dB. Each test pair supplied three mixtures
and two pure-source controls. The 50 test examples therefore contain 40
positives and ten negatives for each target.

## Weighting comparison

The unweighted and balanced SVMs use identical features, training-derived
scaling and validation balanced-accuracy selection. For music, balancing
reduced false positives on speech-only clips from six to three. It also added
one missed music-positive example. Balanced accuracy rose from 0.6375 to
0.7750. The specificity gain, rather than better mixture recall, explains the
improvement: both versions detected music in 26 of the 30 mixtures.

Speech showed a different pattern. Both SVM versions detected 30 of 40 positive
examples, but false positives on music-only clips increased from three to four.
Balanced accuracy fell from 0.7250 to 0.6750. Balancing recovered two pure-speech
examples while losing two mixture detections. At -10 dB, speech mixture recall
fell from 0.7 to 0.5; at +10 dB it rose from 0.8 to 0.9. There is no consistent
improvement across targets or mixture conditions.

## MATLAB YAMNet and thresholds

Validation selected thresholds of 0.05 for speech and 0.15 for music. Relative
to the fixed 0.5 rule, these recovered two speech-positive and four
music-positive test examples, with no additional false positives among the ten
negatives. Speech balanced accuracy rose from 0.6875 to 0.7125; music rose from
0.9250 to 0.9750. Ten negative clips give limited evidence about the wider false
alarm rate.

| SMR | Fixed speech recall | Selected speech recall | Fixed music recall | Selected music recall |
| --- | ---: | ---: | ---: | ---: |
| -10 dB | 0.0 | 0.0 | 1.0 | 1.0 |
| 0 dB | 0.0 | 0.0 | 1.0 | 1.0 |
| +10 dB | 0.6 | 0.8 | 0.4 | 0.8 |

The strong overall music result does not establish reliable detection of both
sources. Even with selected thresholds, speech was missed in all ten mixtures
at both -10 and 0 dB. Mean Speech scores can be low when the dominant content is
assigned to Music or another class.

The [MathWorks model](https://www.mathworks.com/help/audio/ref/audiopretrainednetwork.html)
uses a softmax head. Its classes share a total score of one, which also bounds
the sum of their clip means. Two classes cannot both exceed 0.5. This constrains
the fixed-threshold reference. The
[TensorFlow reference](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/params.py)
uses sigmoid outputs, so these findings should be described as results for the
MATLAB implementation. Thresholds, masking, source content and model training
all affect the comparison; the experiment does not isolate the output head's
effect.

## Uncertainty and error inspection

`preliminary_metric_intervals.csv` reports source-pair bootstrap intervals for
balanced accuracy and F1. `preliminary_paired_comparisons.csv` reports the
balanced-minus-unweighted and selected-minus-fixed differences using shared
resamples. They keep all observations from a source pair together and hold
the fitted models fixed. The intervals cover test-pair variation, with no
claim about variation from retraining or selecting thresholds again.

`preliminary_error_cases.csv` lists labelled errors, source paths and saved
audio paths. Pair 1 is available in the small audio artifact: the unweighted
SVM marks its music-only clip as speech, while the balanced SVM rejects speech
in its -10 dB mixture. These are useful candidates for listening. No listening
judgement is inferred from the labels. Vocal music and pauses within a central
speech excerpt can make source-track labels differ from audible events.

The final comparison keeps the same task and selection rules, expands to seven
SMRs and uses 50 unused test pairs. It will assess whether these development
patterns persist across a broader source selection.
