function tests = test_presence_intervals
tests = functiontests(localfunctions);
end

function testWholePairsAndPairedDifferences(testCase)
t = table(repmat("test",6,1),[11;11;11;12;12;12], ...
    logical([1;0;1;1;0;1]),logical([0;1;1;0;1;1]), ...
    'VariableNames',{'Partition','Pair','SpeechPresent','MusicPresent'});
p = [t.SpeechPresent,t.MusicPresent];
p(4:6,:) = ~p(4:6,:);
p = cat(3,p,p);
state = rng;
[a,d] = bootstrap_presence_metrics(t,p,["A","B"],Resamples=1000,Contrasts=[2 1]);
verifyEqual(testCase,rng,state);
verifyEqual(testCase,a.Estimate(a.Metric=="BalancedAccuracy"),0.5*ones(4,1));
verifyEqual(testCase,a.Estimate(a.Metric=="F1"),(4/7)*ones(4,1),'AbsTol',1e-12);
verifyEqual(testCase,a.Lower95,zeros(8,1));
verifyEqual(testCase,a.Upper95,ones(8,1));
verifyEqual(testCase,d{:,{'Difference','Lower95','Upper95'}},zeros(2,3));
verifyEqual(testCase,a.SourcePairs,2*ones(8,1));
rows = repelem((1:6)',3);
[repeated,~] = bootstrap_presence_metrics(t(rows,:),p(rows,:,:),["A","B"], ...
    Resamples=1000,Contrasts=[2 1]);
verifyEqual(testCase,repeated,a);
end

function testPartitionAndPairChecks(testCase)
t = table(["train";"test"],[1;2],logical([1;0]),logical([0;1]), ...
    'VariableNames',{'Partition','Pair','SpeechPresent','MusicPresent'});
p = logical([1 0;0 1]);
verifyError(testCase,@()bootstrap_presence_metrics(t,p,"A"),'presence:BootstrapPartition');
t.Partition(:) = "test";
verifyError(testCase,@()bootstrap_presence_metrics(t,p,"A"),'presence:BootstrapPairClasses');
t.Pair(:) = 1;
verifyError(testCase,@()bootstrap_presence_metrics(t,p,"A"),'presence:BootstrapPairs');
end

function testSavedDevelopmentReview(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
source = fullfile(root,'results','development');
dest = string(tempname); mkdir(dest);
cleanup = onCleanup(@()rmdir(dest,'s'));
copyfile(fullfile(source,'preliminary_presence_predictions.csv'),dest);
copyfile(fullfile(source,'run_manifest.json'),dest);
[a,d] = review_presence_results(dest,Resamples=100,MakePlot=false);
m = readtable(fullfile(source,'preliminary_presence_metrics.csv'),'TextType','string');
for k = 1:height(m)
    row = a.System==m.System(k) & a.Target==m.Target(k) & a.Metric=="BalancedAccuracy";
    verifyEqual(testCase,a.Estimate(row),m.BalancedAccuracy(k),'AbsTol',1e-12);
end
verifyEqual(testCase,height(a),20);
verifyEqual(testCase,height(d),4);
verifyTrue(testCase,isfile(fullfile(dest,'evaluation_manifest.json')));
verifyTrue(testCase,isfile(fullfile(dest,'preliminary_error_cases.csv')));
verifyTrue(testCase,all(a.Lower95<=a.Upper95));
end

function testFinalRunPreservesExistingPredictions(testCase)
folder = string(tempname); mkdir(folder);
cleanup = onCleanup(@()rmdir(folder,'s'));
file = fullfile(folder,'preliminary_presence_predictions.csv');
writelines("Existing final predictions",file);
verifyError(testCase,@()run_final_experiment(DryRun=false,ResultsDir=folder), ...
    'presence:FinalResultsExist');
verifyEqual(testCase,strtrim(string(fileread(file))),"Existing final predictions");
end
