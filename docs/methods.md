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

YAMNet [3] provides a contrasting representation learned from AudioSet. It uses
log-mel inputs and a MobileNet architecture to score 521 event classes. We use
the Speech and Music outputs averaged over each excerpt. Its broad training
coverage is useful, but its output scores are not calibrated specifically for
our mixtures. Comparing fixed and validation-selected thresholds helps separate
score quality from the chosen decision boundary. YAMNet is a reference model;
we do not claim it represents the current best audio classifier.

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
Each pair contributes related observations across SMRs. Future confidence
intervals should therefore resample whole pairs. They are not implemented yet.

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
