function artifacts = preliminary_mixture_demo(options)
%PRELIMINARY_MIXTURE_DEMO Reproducible handcrafted SVM / pretrained comparison.
% Run from the repository root. Name-value options permit smaller smoke runs.
arguments
    options.SplitFile (1,1) string = fullfile("data","splits","source_split.mat")
    options.ResultsDir (1,1) string = fullfile("results","development")
    options.Phase (1,1) string {mustBeMember(options.Phase,["development","final"])} = "development"
    options.TrainPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.ValidationPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.TestPairs (1,1) double {mustBeInteger,mustBePositive} = 10
    options.TestStartIndex (1,1) double {mustBeInteger,mustBePositive} = 1
    options.SampleRate (1,1) double {mustBeInteger,mustBePositive} = 16000
    options.DurationSec (1,1) double {mustBePositive,mustBeFinite} = 2
    options.SMRValues (1,:) double {mustBeFinite} = [-10 0 10]
    options.BoxConstraints (1,:) double {mustBePositive,mustBeFinite} = [0.01 0.1 1 10]
    options.YAMNetThresholds (1,:) double {mustBeFinite,mustBeNonnegative} = 0:0.05:1
    options.UseYAMNet (1,1) logical = true
    options.MakePlots (1,1) logical = true
    options.SourceCredit (1,1) string = "MUSAN: Snyder, Chen and Povey (2015); https://www.openslr.org/17/ ; CC BY 4.0: https://creativecommons.org/licenses/by/4.0/"
end
previousRng = rng;
cleanupRng = onCleanup(@() rng(previousRng));
rng(530582937,"twister");
assert(~isempty(options.SMRValues) && ~isempty(options.BoxConstraints), ...
    "SMR values and box constraints must be nonempty.");
assert(numel(unique(options.SMRValues)) == numel(options.SMRValues),"SMR values must be unique.");
if options.Phase=="development"
    assert(options.TestStartIndex+options.TestPairs-1<=10, ...
        "presence:ReservedTestSources", ...
        "Development runs are restricted to test sources 1-10. Use run_final_experiment for the reserved sources.");
else
    assert(options.TestStartIndex>=11,"Final runs must exclude the first ten test sources.");
end
assert(~isempty(options.YAMNetThresholds) && all(options.YAMNetThresholds<=1), ...
    "YAMNet threshold candidates must be nonempty and between zero and one.");
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
    first = 1;
    if k==3, first = options.TestStartIndex; end
    [partitionX,partitionMetadata,featureNames,audio] = build_presence_dataset( ...
        split,partitions(k),pairCounts(k),options.SampleRate,options.DurationSec,options.SMRValues,first);
    if k==2, validationAudio = audio; end
    X = [X; partitionX]; %#ok<AGROW>
    metadata = [metadata; partitionMetadata]; %#ok<AGROW>
end
% audio now contains only held-out test examples; discard training audio.
labels = [metadata.SpeechPresent,metadata.MusicPresent];
trainRows = metadata.Partition == "train";
validationRows = metadata.Partition == "validation";
testRows = metadata.Partition == "test";
[models,tuning] = train_handcrafted_baseline(X,labels,trainRows,validationRows,options.BoxConstraints);
[balancedModels,balancedTuning] = train_handcrafted_baseline( ...
    X,labels,trainRows,validationRows,options.BoxConstraints,true);
tuning = [tuning;balancedTuning];
[svmPredictions,svmMargins] = predict_handcrafted_baseline(models,X(testRows,:));
[balancedPredictions,balancedMargins] = predict_handcrafted_baseline(balancedModels,X(testRows,:));
predictions = metadata(testRows,:);
predictions.SVMSpeechMargin = svmMargins(:,1);
predictions.SVMMusicMargin = svmMargins(:,2);
predictions.SVMSpeechPresent = svmPredictions(:,1);
predictions.SVMMusicPresent = svmPredictions(:,2);
predictions.BalancedSpeechMargin = balancedMargins(:,1);
predictions.BalancedMusicMargin = balancedMargins(:,2);
predictions.BalancedSpeechPresent = balancedPredictions(:,1);
predictions.BalancedMusicPresent = balancedPredictions(:,2);
systemNames = ["Always present","SVM unweighted","SVM balanced"];
allPredictions = cat(3,true(size(svmPredictions)),svmPredictions,balancedPredictions);
yamnetThresholds = []; thresholdTuning = table;
validationScores = table;
if options.UseYAMNet
    [net,classNames] = load_yamnet;
    validationYAMNet = zeros(numel(validationAudio),2);
    for row = 1:numel(validationAudio)
        [validationYAMNet(row,1),validationYAMNet(row,2)] = ...
            yamnet_scores(validationAudio{row},options.SampleRate,net,classNames);
    end
    [yamnetThresholds,thresholdTuning] = select_presence_thresholds( ...
        validationYAMNet,labels(validationRows,:),options.YAMNetThresholds);
    validationScores = metadata(validationRows,:);
    validationScores.YAMNetSpeechScore = validationYAMNet(:,1);
    validationScores.YAMNetMusicScore = validationYAMNet(:,2);
    yamnetScores = zeros(height(predictions),2);
    for row = 1:height(predictions)
        [yamnetScores(row,1),yamnetScores(row,2)] = yamnet_scores(audio{row},options.SampleRate,net,classNames);
    end
    % Network weights stay frozen for both decision rules.
    predictions.YAMNetSpeechScore = yamnetScores(:,1);
    predictions.YAMNetMusicScore = yamnetScores(:,2);
    predictions.YAMNetSpeechPresent = yamnetScores(:,1) >= 0.5;
    predictions.YAMNetMusicPresent = yamnetScores(:,2) >= 0.5;
    predictions.YAMNetTunedSpeechPresent = yamnetScores(:,1) >= yamnetThresholds(1);
    predictions.YAMNetTunedMusicPresent = yamnetScores(:,2) >= yamnetThresholds(2);
    systemNames = [systemNames,"YAMNet fixed","YAMNet validation"];
    allPredictions = cat(3,allPredictions,yamnetScores>=0.5,yamnetScores>=yamnetThresholds);
end
[metrics,recallBySMR] = evaluate_presence_systems(predictions,allPredictions,systemNames,options.SMRValues);
audioDir = fullfile(options.ResultsDir,"preliminary_audio");
figureDir = fullfile(options.ResultsDir,"preliminary_figures");
if ~isfolder(audioDir), mkdir(audioDir); end
if ~isfolder(figureDir), mkdir(figureDir); end
predictions.MixtureFile = strings(height(predictions),1);
predictions.AudioFile = strings(height(predictions),1);
for row = 1:height(predictions)
    if predictions.AudioType(row)=="mixture"
        name = sprintf("pair_%02d_smr_%+g.wav",predictions.Pair(row),predictions.TargetSMR_dB(row));
        predictions.MixtureFile(row) = fullfile(audioDir,name);
    elseif predictions.Pair(row)==options.TestStartIndex
        name = sprintf("pair_%02d_%s.wav",predictions.Pair(row),predictions.AudioType(row));
    else
        continue
    end
    predictions.AudioFile(row) = fullfile(audioDir,name);
    audiowrite(predictions.AudioFile(row),audio{row},options.SampleRate);
end
features = [metadata,array2table(X,'VariableNames',cellstr(featureNames))];
writetable(features,fullfile(options.ResultsDir,"preliminary_handcrafted_features.csv"));
writetable(predictions,fullfile(options.ResultsDir,"preliminary_presence_predictions.csv"));
writetable(tuning,fullfile(options.ResultsDir,"preliminary_svm_tuning.csv"));
writetable(metrics,fullfile(options.ResultsDir,"preliminary_presence_metrics.csv"));
writetable(recallBySMR,fullfile(options.ResultsDir,"preliminary_recall_vs_smr.csv"));
if options.UseYAMNet
    writetable(validationScores,fullfile(options.ResultsDir,"preliminary_yamnet_validation_scores.csv"));
    writetable(thresholdTuning,fullfile(options.ResultsDir,"preliminary_yamnet_thresholds.csv"));
end
write_confusions(metrics,options.ResultsDir);
write_audio_credit(predictions,audioDir,options);
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
configuration.SelectionMetric = "BalancedAccuracy";
configuration.SelectedYAMNetThresholds = yamnetThresholds;
configuration.SystemNames = systemNames;
matlabVersion = version;
toolboxes = ver;
save(fullfile(options.ResultsDir,"preliminary_handcrafted_models.mat"), ...
    "models","balancedModels","tuning","yamnetThresholds","thresholdTuning", ...
    "configuration","split","metadata","featureNames","matlabVersion","toolboxes");
manifest = struct('Configuration',configuration,'MATLABVersion',matlabVersion, ...
    'Toolboxes',toolboxes,'CodeRevision',string(getenv('GITHUB_SHA')), ...
    'CreatedUTC',string(datetime('now','TimeZone','UTC')), ...
    'Sources',table2struct(metadata(:,1:5)));
fid = fopen(fullfile(options.ResultsDir,"run_manifest.json"),'w');
assert(fid~=-1,"Could not write the run manifest.");
fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true)); fclose(fid);
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
    "Tuning",tuning,"Models",models,"BalancedModels",balancedModels, ...
    "YAMNetThresholds",yamnetThresholds,"ThresholdTuning",thresholdTuning,"FeatureNames",featureNames);
end

function write_confusions(metrics,folder)
counts = table;
for k = 1:height(metrics)
    m = metrics(k,:);
    values = [m.TN;m.FP;m.FN;m.TP];
    fractions = values./[m.NegativeCount;m.NegativeCount;m.PositiveCount;m.PositiveCount];
    rows = table(repmat(m.System,4,1),repmat(m.Target,4,1), ...
        ["Absent";"Absent";"Present";"Present"],["Absent";"Present";"Absent";"Present"], ...
        values,fractions,'VariableNames',{'System','Target','Actual','Predicted','Count','Fraction'});
    counts = [counts;rows]; %#ok<AGROW>
end
writetable(counts,fullfile(folder,"preliminary_confusion_counts.csv"));
end

function write_audio_credit(predictions,folder,options)
example = predictions(predictions.Pair==min(predictions.Pair) & predictions.AudioType=="mixture",:);
fid = fopen(fullfile(folder,"SOURCES.txt"),'w');
assert(fid~=-1,"Could not write the audio source credits.");
fprintf(fid,'%s\n',options.SourceCredit);
fprintf(fid,'Speech: %s\nMusic: %s\n',example.SpeechFile(1),example.MusicFile(1));
fprintf(fid,'Central %.3g s excerpts converted to mono at %g Hz, DC-removed, level-adjusted and mixed.\n', ...
    options.DurationSec,options.SampleRate);
fclose(fid);
sources = [example.SpeechFile(1),example.MusicFile(1)];
for k = 1:2
    files = dir(fileparts(sources(k)));
    for j = 1:numel(files)
        name = string(files(j).name);
        if ~files(j).isdir && (endsWith(lower(name),'.txt') || ...
                any(startsWith(upper(name),["INFO","README","LICENSE","ANNOTATIONS"])))
            dest = fullfile(folder,"attribution");
            if ~isfolder(dest), mkdir(dest); end
            copyfile(fullfile(files(j).folder,files(j).name),fullfile(dest,sprintf('%d_%s',k,name)));
        end
    end
end
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
