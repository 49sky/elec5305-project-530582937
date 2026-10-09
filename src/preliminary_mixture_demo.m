clear; close all; clc;

addpath("src");

splitFile = fullfile("data","splits","source_split.mat");

if ~isfile(splitFile)
    create_source_split;
end

load(splitFile,"split");

speechFiles = split.speech.validation;
musicFiles = split.music.validation;

nPairs = 10;

if numel(speechFiles) < nPairs || numel(musicFiles) < nPairs
    error("At least 10 validation speech and music sources are required.");
end

speechFiles = speechFiles(1:nPairs);
musicFiles = musicFiles(1:nPairs);

SMRValues = [-10 0 10];
targetFs = 16000;
durationSec = 2.0;

audioDir = fullfile("results","preliminary_audio");
figureDir = fullfile("results","preliminary_figures");

if ~isfolder(audioDir)
    mkdir(audioDir);
end

if ~isfolder(figureDir)
    mkdir(figureDir);
end

try
    [net,classNames] = audioPretrainedNetwork("yamnet");
catch
    modelName = "yamnet";
    downloadFolder = fullfile(tempdir,"pretrainedNetDownload");
    if ~isfolder(downloadFolder)
        mkdir(downloadFolder);
    end
    downloadURL = sprintf("https://ssd.mathworks.com/supportfiles/audio/%s.zip",modelName);
    zipFile = websave(fullfile(downloadFolder,modelName + ".zip"),downloadURL);
    modelFolder = fullfile(tempdir,"pretrainedAudioModels");
    if ~isfolder(modelFolder)
        mkdir(modelFolder);
    end
    unzip(zipFile,modelFolder);
    addpath(fullfile(modelFolder,modelName));
    [net,classNames] = audioPretrainedNetwork("yamnet");
end

pairColumn = [];
speechFileColumn = strings(0);
musicFileColumn = strings(0);
targetSMRColumn = [];
measuredSMRColumn = [];
speechScoreColumn = [];
musicScoreColumn = [];
audioFileColumn = strings(0);

for pair = 1:nPairs

    [speech,fs] = read_audio_segment(speechFiles(pair),targetFs,durationSec);
    [music,~] = read_audio_segment(musicFiles(pair),targetFs,durationSec);

    fig = figure("Color","w","Visible","off");
    tl = tiledlayout(2,numel(SMRValues),"TileSpacing","compact","Padding","compact");

    for k = 1:numel(SMRValues)

        targetSMR = SMRValues(k);
        [mix,measuredSMR] = make_smr_mixture(speech,music,targetSMR);

        audioName = sprintf("pair_%02d_smr_%+d.wav",pair,targetSMR);
        audioPath = fullfile(audioDir,audioName);
        audiowrite(audioPath,mix,fs);

        [speechScore,musicScore] = yamnet_scores(mix,fs,net,classNames);

        pairColumn(end+1,1) = pair;
        speechFileColumn(end+1,1) = speechFiles(pair);
        musicFileColumn(end+1,1) = musicFiles(pair);
        targetSMRColumn(end+1,1) = targetSMR;
        measuredSMRColumn(end+1,1) = measuredSMR;
        speechScoreColumn(end+1,1) = speechScore;
        musicScoreColumn(end+1,1) = musicScore;
        audioFileColumn(end+1,1) = string(audioPath);

        t = (0:numel(mix)-1)/fs;

        nexttile(k);
        plot(t,mix);
        grid on;
        xlabel("Time (s)");
        ylabel("Amplitude");
        title(sprintf("SMR = %+d dB",targetSMR));

        nexttile(k+numel(SMRValues));
        spectrogram(mix,hann(512,"periodic"),384,1024,fs,"yaxis");
        title(sprintf("SMR = %+d dB",targetSMR));

        fprintf("Pair %02d | target %+d dB | measured %.2f dB | speech %.3f | music %.3f\n", ...
            pair,targetSMR,measuredSMR,speechScore,musicScore);

    end

    title(tl,sprintf("Speech/Music Pair %02d",pair));

    figurePath = fullfile(figureDir,sprintf("pair_%02d_smr_comparison.png",pair));
    exportgraphics(fig,figurePath,"Resolution",150);
    close(fig);

end

results = table( ...
    pairColumn, ...
    speechFileColumn, ...
    musicFileColumn, ...
    targetSMRColumn, ...
    measuredSMRColumn, ...
    speechScoreColumn, ...
    musicScoreColumn, ...
    audioFileColumn, ...
    "VariableNames",{ ...
    "Pair","SpeechFile","MusicFile","TargetSMR_dB","MeasuredSMR_dB", ...
    "YAMNetSpeechScore","YAMNetMusicScore","MixtureFile"});

writetable(results,fullfile("results","preliminary_results.csv"));

meanSpeech = zeros(numel(SMRValues),1);
meanMusic = zeros(numel(SMRValues),1);
stdSpeech = zeros(numel(SMRValues),1);
stdMusic = zeros(numel(SMRValues),1);

for k = 1:numel(SMRValues)
    rows = results.TargetSMR_dB == SMRValues(k);
    meanSpeech(k) = mean(results.YAMNetSpeechScore(rows));
    meanMusic(k) = mean(results.YAMNetMusicScore(rows));
    stdSpeech(k) = std(results.YAMNetSpeechScore(rows));
    stdMusic(k) = std(results.YAMNetMusicScore(rows));
end

summary = table(SMRValues',meanSpeech,stdSpeech,meanMusic,stdMusic, ...
    "VariableNames",{"SMR_dB","MeanSpeechScore","StdSpeechScore","MeanMusicScore","StdMusicScore"});

writetable(summary,fullfile("results","preliminary_yamnet_summary.csv"));

fig = figure("Color","w");
errorbar(SMRValues,meanSpeech,stdSpeech,"-o","LineWidth",1.2);
hold on;
errorbar(SMRValues,meanMusic,stdMusic,"-o","LineWidth",1.2);
grid on;
xlabel("Speech-to-Music Ratio (dB)");
ylabel("Mean YAMNet score");
title("Preliminary YAMNet scores versus SMR");
legend("Speech","Music","Location","best");

exportgraphics(fig,fullfile(figureDir,"yamnet_scores_vs_smr.png"),"Resolution",180);
close(fig);

disp(results(:,["Pair","TargetSMR_dB","MeasuredSMR_dB","YAMNetSpeechScore","YAMNetMusicScore"]));
disp(summary);
