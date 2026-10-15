function artifacts = preliminary_mixture_demo(options)
%PRELIMINARY_MIXTURE_DEMO Reproducible handcrafted SVM / pretrained comparison.
% Run from the repository root. Name-value options permit smaller smoke runs.
arguments
    options.SplitFile (1,1) string = fullfile("data","splits","source_split.mat")
    options.ResultsDir (1,1) string = "results"
    options.TrainPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.ValidationPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.TestPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.SampleRate (1,1) double {mustBeInteger,mustBePositive} = 16000
    options.DurationSec (1,1) double {mustBePositive,mustBeFinite} = 2
    options.SMRValues (1,:) double {mustBeFinite} = [-10 0 10]
    options.BoxConstraints (1,:) double {mustBePositive,mustBeFinite} = [0.01 0.1 1 10]
    options.UseYAMNet (1,1) logical = true
    options.MakePlots (1,1) logical = true
end
previousRng = rng;
cleanupRng = onCleanup(@() rng(previousRng));
rng(530582937,"twister");
assert(~isempty(options.SMRValues) && ~isempty(options.BoxConstraints), ...
    "SMR values and box constraints must be nonempty.");
assert(numel(unique(options.SMRValues)) == numel(options.SMRValues),"SMR values must be unique.");
if ~isfile(options.SplitFile)
    if options.SplitFile ~= fullfile("data","splits","source_split.mat")
        error("presence:MissingSplit","Split file does not exist: %s",options.SplitFile);
    end
    create_source_split;
end
loaded = load(options.SplitFile,"split");
split = loaded.split;
validate_source_split(split);
partitions = ["train","validation","test"];
pairCounts = [options.TrainPairs,options.ValidationPairs,options.TestPairs];
X = zeros(0,40);
metadata = table;
for k = 1:3
    [partitionX,partitionMetadata,featureNames,audio] = build_presence_dataset( ...
        split,partitions(k),pairCounts(k),options.SampleRate,options.DurationSec,options.SMRValues);
    X = [X; partitionX]; %#ok<AGROW>
    metadata = [metadata; partitionMetadata]; %#ok<AGROW>
end
% audio now contains only held-out test examples; discard training audio.
labels = [metadata.SpeechPresent,metadata.MusicPresent];
trainRows = metadata.Partition == "train";
validationRows = metadata.Partition == "validation";
testRows = metadata.Partition == "test";
[models,tuning] = train_handcrafted_baseline(X,labels,trainRows,validationRows,options.BoxConstraints);
[svmPredictions,svmMargins] = predict_handcrafted_baseline(models,X(testRows,:));
predictions = metadata(testRows,:);
predictions.SVMSpeechMargin = svmMargins(:,1);
predictions.SVMMusicMargin = svmMargins(:,2);
predictions.SVMSpeechPresent = svmPredictions(:,1);
predictions.SVMMusicPresent = svmPredictions(:,2);
systemNames = "Handcrafted SVM";
allPredictions = svmPredictions;
if options.UseYAMNet
    [net,classNames] = load_yamnet;
    yamnetScores = zeros(height(predictions),2);
    for row = 1:height(predictions)
        [yamnetScores(row,1),yamnetScores(row,2)] = yamnet_scores(audio{row},options.SampleRate,net,classNames);
    end
    % Fixed a priori threshold; YAMNet remains frozen and is never fitted.
    predictions.YAMNetSpeechScore = yamnetScores(:,1);
    predictions.YAMNetMusicScore = yamnetScores(:,2);
    predictions.YAMNetSpeechPresent = yamnetScores(:,1) >= 0.5;
    predictions.YAMNetMusicPresent = yamnetScores(:,2) >= 0.5;
    systemNames(2) = "YAMNet";
    allPredictions(:,:,2) = yamnetScores >= 0.5;
end
[metrics,recallBySMR] = evaluate_presence_systems(predictions,allPredictions,systemNames,options.SMRValues);
audioDir = fullfile(options.ResultsDir,"preliminary_audio");
figureDir = fullfile(options.ResultsDir,"preliminary_figures");
if ~isfolder(audioDir), mkdir(audioDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
predictions.MixtureFile = strings(height(predictions),1);
for row = find(predictions.AudioType == "mixture")'
    name = sprintf("pair_%02d_smr_%+g.wav",predictions.Pair(row),predictions.TargetSMR_dB(row));
    predictions.MixtureFile(row) = fullfile(audioDir,name);
    audiowrite(predictions.MixtureFile(row),audio{row},options.SampleRate);
end
features = [metadata,array2table(X,'VariableNames',cellstr(featureNames))];
writetable(features,fullfile(options.ResultsDir,"preliminary_handcrafted_features.csv"));
writetable(predictions,fullfile(options.ResultsDir,"preliminary_presence_predictions.csv"));
writetable(tuning,fullfile(options.ResultsDir,"preliminary_svm_tuning.csv"));
writetable(metrics,fullfile(options.ResultsDir,"preliminary_presence_metrics.csv"));
writetable(recallBySMR,fullfile(options.ResultsDir,"preliminary_recall_vs_smr.csv"));
% Preserve the original mixture-only CSV and YAMNet score summary.
mixtures = predictions(predictions.AudioType == "mixture",:);
writetable(mixtures,fullfile(options.ResultsDir,"preliminary_results.csv"));
if options.UseYAMNet
    summary = yamnet_summary(mixtures,options.SMRValues);
    writetable(summary,fullfile(options.ResultsDir,"preliminary_yamnet_summary.csv"));
end
configuration = options;
configuration.Seed = 530582937;
configuration.YAMNetThreshold = 0.5;
configuration.SVMDecisionThreshold = 0;
matlabVersion = version;
toolboxes = ver;
save(fullfile(options.ResultsDir,"preliminary_handcrafted_models.mat"), ...
    "models","tuning","configuration","split","metadata","featureNames","matlabVersion","toolboxes");
if options.MakePlots
    plot_presence_comparison(metrics,recallBySMR,figureDir);
    plot_mixtures(predictions,audio,options.SampleRate,options.SMRValues,figureDir);
    if options.UseYAMNet
        fig = figure("Color","w","Visible","off");
        errorbar(summary.SMR_dB,summary.MeanSpeechScore,summary.StdSpeechScore,"-o"); hold on;
        errorbar(summary.SMR_dB,summary.MeanMusicScore,summary.StdMusicScore,"-o");
        grid on; xlabel("Speech-to-Music Ratio (dB)"); ylabel("Mean YAMNet score");
        title("Preliminary YAMNet scores versus SMR (test mixtures)");
        legend("Speech","Music","Location","best");
        exportgraphics(fig,fullfile(figureDir,"yamnet_scores_vs_smr.png"),"Resolution",180);
        close(fig);
    end
end
disp(metrics); disp(recallBySMR);
artifacts = struct("Predictions",predictions,"Metrics",metrics,"RecallBySMR",recallBySMR, ...
    "Tuning",tuning,"Models",models,"FeatureNames",featureNames);
end

function [net,classNames] = load_yamnet
try
    [net,classNames] = audioPretrainedNetwork("yamnet");
catch
    downloadFolder = fullfile(tempdir,"pretrainedNetDownload");
    if ~isfolder(downloadFolder), mkdir(downloadFolder); end
    zipFile = websave(fullfile(downloadFolder,"yamnet.zip"), ...
        "https://ssd.mathworks.com/supportfiles/audio/yamnet.zip");
    modelFolder = fullfile(tempdir,"pretrainedAudioModels");
    if ~isfolder(modelFolder), mkdir(modelFolder); end
    unzip(zipFile,modelFolder); addpath(fullfile(modelFolder,"yamnet"));
    [net,classNames] = audioPretrainedNetwork("yamnet");
end
end

function summary = yamnet_summary(mixtures,smrValues)
values = zeros(numel(smrValues),4);
for k = 1:numel(smrValues)
    rows = mixtures.TargetSMR_dB == smrValues(k);
    values(k,:) = [mean(mixtures.YAMNetSpeechScore(rows)),std(mixtures.YAMNetSpeechScore(rows)), ...
        mean(mixtures.YAMNetMusicScore(rows)),std(mixtures.YAMNetMusicScore(rows))];
end
summary = array2table([smrValues(:),values],'VariableNames', ...
    {'SMR_dB','MeanSpeechScore','StdSpeechScore','MeanMusicScore','StdMusicScore'});
end

function plot_mixtures(metadata,audio,fs,smrValues,figureDir)
for pair = unique(metadata.Pair)'
    fig = figure("Color","w","Visible","off", ...
        "Position",[100 100 max(900,300*numel(smrValues)) 560]);
    layout = tiledlayout(2,numel(smrValues),"TileSpacing","compact","Padding","compact");
    for k = 1:numel(smrValues)
        row = find(metadata.Pair == pair & metadata.TargetSMR_dB == smrValues(k),1);
        x = audio{row};
        nexttile(k); plot((0:numel(x)-1)/fs,x); grid on;
        xlabel("Time (s)"); ylabel("Amplitude"); title(sprintf("SMR = %+g dB",smrValues(k)));
        nexttile(k+numel(smrValues));
        spectrogram(x,hann(512,"periodic"),384,1024,fs,"yaxis");
        title(sprintf("SMR = %+g dB",smrValues(k)));
    end
    title(layout,sprintf("Test speech/music pair %02d",pair));
    exportgraphics(fig,fullfile(figureDir,sprintf("pair_%02d_smr_comparison.png",pair)),"Resolution",150);
    close(fig);
end
end
