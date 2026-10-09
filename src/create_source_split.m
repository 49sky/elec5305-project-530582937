function split = create_source_split(datasetRoot,outDir)

if nargin < 1
    datasetRoot = fullfile("data","musan");
end

if nargin < 2
    outDir = fullfile("data","splits");
end

rng(530582937);

allFiles = dir(fullfile(datasetRoot,"**","*"));
allFiles = allFiles(~[allFiles.isdir]);

if isempty(allFiles)
    error("No files found under %s.",datasetRoot);
end

names = string({allFiles.name})';
paths = string(fullfile({allFiles.folder},{allFiles.name}))';

isWav = endsWith(lower(names),".wav");
paths = paths(isWav);

if isempty(paths)
    error("No WAV files found under %s.",datasetRoot);
end

normalised = replace(paths,"\","/");
speechMask = contains(lower(normalised),"/speech/");
musicMask = contains(lower(normalised),"/music/");

speechPaths = paths(speechMask);
musicPaths = paths(musicMask);

if isempty(speechPaths) || isempty(musicPaths)
    error("Could not identify both speech and music WAV files in the MUSAN folder.");
end

repoPrefix = string(pwd) + filesep;
speechPaths = erase(speechPaths,repoPrefix);
musicPaths = erase(musicPaths,repoPrefix);

speechPaths = speechPaths(randperm(numel(speechPaths)));
musicPaths = musicPaths(randperm(numel(musicPaths)));

split.speech = partition_files(speechPaths);
split.music = partition_files(musicPaths);

if ~isfolder(outDir)
    mkdir(outDir);
end

save(fullfile(outDir,"source_split.mat"),"split");

type = [repmat("speech",numel(speechPaths),1); repmat("music",numel(musicPaths),1)];

partition = [ ...
    repmat("train",numel(split.speech.train),1); ...
    repmat("validation",numel(split.speech.validation),1); ...
    repmat("test",numel(split.speech.test),1); ...
    repmat("train",numel(split.music.train),1); ...
    repmat("validation",numel(split.music.validation),1); ...
    repmat("test",numel(split.music.test),1)];

path = [ ...
    split.speech.train; ...
    split.speech.validation; ...
    split.speech.test; ...
    split.music.train; ...
    split.music.validation; ...
    split.music.test];

T = table(type,partition,path);
writetable(T,fullfile(outDir,"source_split.csv"));

fprintf("Speech: %d train, %d validation, %d test\n", ...
    numel(split.speech.train),numel(split.speech.validation),numel(split.speech.test));

fprintf("Music:  %d train, %d validation, %d test\n", ...
    numel(split.music.train),numel(split.music.validation),numel(split.music.test));

end

function p = partition_files(files)

n = numel(files);
nTrain = floor(0.70*n);
nValidation = floor(0.15*n);

p.train = files(1:nTrain);
p.validation = files(nTrain+1:nTrain+nValidation);
p.test = files(nTrain+nValidation+1:end);

end
