# Method notes

## Question and scope

The question is how relative speech/music level changes the ability to detect
both sources, and how a simple feature model compares with a pretrained audio
classifier. The experiment uses controlled mixtures with known source tracks.
It does not separate the tracks or train a new neural network.

## Why these methods

Scheirer and Slaney [1] studied speech/music discrimination using multiple
acoustic descriptors and temporal summaries. That provides a useful starting
point for an interpretable baseline. Our 40-value feature vector follows this
general approach, but its definitions and linear SVMs are not an exact
reproduction of their system. The complete feature definitions are in the
README and `handcrafted_features.m`.

MUSAN [2] supplies diverse speech and music with source information and licences.
Its published discrimination experiment excluded overlapping segments. Our
controlled SMR sweep asks how performance changes when both source tracks are
present. This is a difference in the evaluation question; it is not evidence
that our project introduces overlap detection to the literature.

YAMNet [3] provides a representation learned from AudioSet using log-mel
inputs and MobileNet. This project uses MathWorks' `audioPretrainedNetwork`
implementation [5], whose documented output is softmax. TensorFlow's reference
uses independent sigmoid outputs. The results here describe the MATLAB model.

Speech and Music scores are averaged over each excerpt. Softmax makes classes
compete and constrains simultaneous detection at a 0.5 threshold: the two mean
scores sum to at most one. Lower validation-selected thresholds allow both
outputs to be accepted. This motivates the threshold comparison, while other
factors, including masking and domain differences, can also affect scores.
Weights and output layers stay fixed. New runs record and check the output-layer
type. The model is a reference classifier; no current state-of-the-art claim is
made.

## Controlled weighting comparison

The preliminary SVM labelled every test example as speech-present. Because
mixtures provide positives for both outputs, positive-class F1 can reward that
behaviour. Adding more mixture ratios increases the imbalance further.

The new comparison uses empirical priors versus equal class priors in `fitcsvm`
[4]. Both versions use the same training-derived mean/std transform, features,
source selections and C candidates. Scaling is done before fitting because
MATLAB otherwise uses prior-weighted scaling when standardisation is enabled.
Each output selects C by validation balanced accuracy, with the smallest C
breaking ties. Both use the zero-margin boundary. There is no additional
threshold search for the weighted SVM.

The historic F1-selected model is retained as a record of the first iteration.
For the new weighting comparison, the unweighted model is rerun under the same
selection rule as the weighted model. Differences from the historic run cannot
be attributed solely to weighting.

## Evaluation and limits

Balanced accuracy is the primary per-output measure, alongside positive-class
F1, specificity, macro-F1, confusion counts and mixture recall versus SMR. An
always-present reference is included. Confusion plots normalise within actual
classes and show the counts, so rare negatives remain visible.

Source files are split before extracting central excerpts. All settings are
chosen using training/validation data. Development is restricted to the ten
test pairs already inspected; the final protocol reserves indices 11-60.
Each pair contributes related observations across SMRs. Confidence intervals
therefore resample complete pairs, including their pure-source controls. For
each of 2,000 draws, the same sampled pair indices are used for every system.
The 2.5th and 97.5th percentiles give the reported 95% intervals for balanced
accuracy, positive-class F1 and paired balanced-accuracy differences. This is
the percentile bootstrap [6], applied to pair-level confusion counts.

These intervals describe variation across the selected test pairs with models
and thresholds held fixed. They do not include retraining or validation-selection
uncertainty. Ten development pairs provide limited evidence; the final protocol
uses 50 unused pairs. Repeated speakers or artists may create dependence beyond
the file pairs.

File-level separation does not guarantee new speakers, artists or recording
conditions. Labels describe the source tracks included, rather than an exhaustive
annotation of audible events. In particular, MUSAN includes vocal music, so
music-only errors need careful listening and metadata inspection before they
are interpreted as failures to reject speech. Silence/noise-only rejection and
natural, uncontrolled mixtures are outside the current evaluation.

## References

1. E. Scheirer and M. Slaney, "Construction and evaluation of a robust
   multifeature speech/music discriminator," ICASSP, vol. 2, pp. 1331-1334, 1997.
   [DOI](https://doi.org/10.1109/ICASSP.1997.596192).
2. D. Snyder, G. Chen and D. Povey, "MUSAN: A music, speech, and noise corpus,"
   2015. [Paper](https://arxiv.org/abs/1510.08484),
   [corpus and licence](https://www.openslr.org/17/).
3. TensorFlow Models, "YAMNet," model documentation and source code.
   [Official repository](https://github.com/tensorflow/models/tree/master/research/audioset/yamnet).
4. MathWorks, "fitcsvm," MATLAB documentation.
   [Class priors, weighting and standardisation](https://www.mathworks.com/help/stats/fitcsvm.html).
5. MathWorks, "audioPretrainedNetwork," MATLAB documentation.
   [MATLAB YAMNet architecture](https://www.mathworks.com/help/audio/ref/audiopretrainednetwork.html).
   TensorFlow's [activation setting](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/params.py)
   defines the reference sigmoid output.
6. MathWorks, "bootci," MATLAB documentation.
   [Bootstrap sampling and percentile intervals](https://www.mathworks.com/help/stats/bootci.html).
   The implementation here samples source-pair counts directly.
