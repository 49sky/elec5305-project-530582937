function result = run_final_experiment(options)
arguments
    options.DryRun (1,1) logical = true
    options.ResultsDir (1,1) string = ""
end
root = fileparts(fileparts(mfilename('fullpath')));
previous = pwd; restore = onCleanup(@()cd(previous)); cd(root);
p = jsondecode(fileread(fullfile('config','final_protocol.json')));
if strlength(options.ResultsDir)>0, p.ResultsDir = options.ResultsDir; end
archive = fullfile('results','archive','preliminary-2026-10-27');
original = read_split(fullfile(archive,'source_split.csv'));
current = read_split(fullfile('data','splits','source_split.csv'));
assert(isequal(current,original),"The source split differs from the frozen protocol.");
used = readtable(fullfile(archive,'preliminary_presence_predictions.csv'), ...
    'TextType','string','Delimiter',',','ReadVariableNames',true,'VariableNamingRule','preserve');
usedPaths = unique([used.SpeechFile;used.MusicFile]);
usedPaths = usedPaths(~ismissing(usedPaths) & strlength(usedPaths)>0);
selected = table; split = struct;
partitions = ["train","validation","test"];
counts = [p.TrainPairs,p.ValidationPairs,p.TestPairs];
for k = 1:3
    first = 1;
    if k==3, first = p.TestStartIndex; end
    for type = ["speech","music"]
        rows = current.Type==type & current.Partition==partitions(k);
        paths = current.Path(rows);
        split.(type).(partitions(k)) = paths;
        indices = first+(0:counts(k)-1);
        assert(max(indices)<=numel(paths),"The frozen protocol needs more %s sources.",type);
        if k==3
            assert(~any(ismember(paths(indices),usedPaths)),"A reserved test source was used in the preliminary run.");
        end
        selected = [selected;table(repmat(partitions(k),numel(indices),1), ...
            repmat(type,numel(indices),1),indices',paths(indices), ...
            'VariableNames',{'Partition','Type','Index','Path'})];
    end
end
if options.DryRun
    result = selected;
    disp(groupsummary(selected,["Partition","Type"]));
    return
end
assert(~isfile(fullfile(p.ResultsDir,'preliminary_presence_predictions.csv')), ...
    "presence:FinalResultsExist","Final predictions already exist. Review the saved run rather than rerunning the test set.");
validate_source_split(split);
if ~isfolder(p.ResultsDir), mkdir(p.ResultsDir); end
splitFile = fullfile(p.ResultsDir,'source_split.mat');
save(splitFile,'split');
result = preliminary_mixture_demo(Phase="final",SplitFile=splitFile, ...
    ResultsDir=string(p.ResultsDir),TrainPairs=p.TrainPairs, ...
    ValidationPairs=p.ValidationPairs,TestPairs=p.TestPairs, ...
    TestStartIndex=p.TestStartIndex,SampleRate=p.SampleRate,DurationSec=p.DurationSec, ...
    SMRValues=p.SMRValues(:)',BoxConstraints=p.BoxConstraints(:)', ...
    YAMNetThresholds=p.YAMNetThresholds(:)', ...
    BootstrapResamples=p.BootstrapResamples,BootstrapSeed=p.BootstrapSeed);
end

function t = read_split(file)
t = readtable(file,'TextType','string','Delimiter',',','ReadVariableNames',true, ...
    'VariableNamingRule','preserve');
assert(width(t)==3,"The source manifest must have three columns.");
t.Properties.VariableNames = {'Type','Partition','Path'};
end
