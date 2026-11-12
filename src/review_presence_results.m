function [intervals,comparisons] = review_presence_results(resultsDir,options)
%REVIEW_PRESENCE_RESULTS Evaluate saved decisions without reloading audio or models.
arguments
    resultsDir (1,1) string = fullfile('results','development')
    options.Resamples (1,1) double {mustBeInteger,mustBePositive} = 2000
    options.Seed (1,1) double {mustBeInteger,mustBeNonnegative} = 530582937
    options.MakePlot (1,1) logical = true
end
file = fullfile(resultsDir,'preliminary_presence_predictions.csv');
t = readtable(file,'TextType','string','Delimiter',',','ReadVariableNames',true);
systems = ["Always present","SVM unweighted","SVM balanced"];
p = cat(3,true(height(t),2),logical(t{:,{'SVMSpeechPresent','SVMMusicPresent'}}), ...
    logical(t{:,{'BalancedSpeechPresent','BalancedMusicPresent'}}));
contrasts = [3 2];
if ismember('YAMNetSpeechPresent',t.Properties.VariableNames)
    p = cat(3,p,logical(t{:,{'YAMNetSpeechPresent','YAMNetMusicPresent'}}), ...
        logical(t{:,{'YAMNetTunedSpeechPresent','YAMNetTunedMusicPresent'}}));
    systems = [systems,"YAMNet fixed","YAMNet validation"];
    contrasts = [contrasts;5 4];
end
[intervals,comparisons] = bootstrap_presence_metrics(t,p,systems, ...
    Resamples=options.Resamples,Seed=options.Seed,Contrasts=contrasts);
writetable(intervals,fullfile(resultsDir,'preliminary_metric_intervals.csv'));
writetable(comparisons,fullfile(resultsDir,'preliminary_paired_comparisons.csv'));
errors = table;
targets = ["Speech","Music"];
truth = logical([t.SpeechPresent,t.MusicPresent]);
for target = 1:2
    decisions = reshape(p(:,target,2:end),height(t),[]);
    rows = any(decisions~=truth(:,target),2);
    cases = t(rows,{'Pair','AudioType','TargetSMR_dB','SpeechFile','MusicFile','AudioFile'});
    cases.Target = repmat(targets(target),height(cases),1);
    cases.Present = truth(rows,target);
    for system = 2:numel(systems)
        name = matlab.lang.makeValidName(systems(system));
        cases.(name) = p(rows,target,system);
    end
    errors = [errors;cases]; %#ok<AGROW>
end
writetable(errors,fullfile(resultsDir,'preliminary_error_cases.csv'));
sourceRevision = "";
sourceManifest = fullfile(resultsDir,'run_manifest.json');
if isfile(sourceManifest)
    original = jsondecode(fileread(sourceManifest));
    sourceRevision = string(original.CodeRevision);
end
manifest = struct('PredictionFile',file,'SourceCodeRevision',sourceRevision, ...
    'EvaluationCodeRevision',string(getenv('GITHUB_SHA')), ...
    'Resamples',options.Resamples,'Seed',options.Seed,'ConfidenceLevel',0.95, ...
    'Unit','source pair','Method','percentile','SourcePairs',numel(unique(t.Pair)), ...
    'CreatedUTC',string(datetime('now','TimeZone','UTC')));
fid = fopen(fullfile(resultsDir,'evaluation_manifest.json'),'w');
assert(fid~=-1,"Could not write the evaluation manifest.");
fprintf(fid,'%s\n',jsonencode(manifest,PrettyPrint=true)); fclose(fid);
if options.MakePlot
    folder = fullfile(resultsDir,'preliminary_figures');
    if ~isfolder(folder), mkdir(folder); end
    fig = figure('Color','w','Visible','off','Position',[100 100 1100 430]);
    tiledlayout(1,2,'TileSpacing','compact');
    for target = targets
        m = intervals(intervals.Target==target & intervals.Metric=="BalancedAccuracy",:);
        nexttile; hold on;
        for k = 1:height(m)
            plot([m.Lower95(k),m.Upper95(k)],[k k],'-','Color',[.2 .4 .7],'LineWidth',1.5);
        end
        plot(m.Estimate,1:height(m),'o','Color',[.2 .4 .7],'MarkerFaceColor',[.2 .4 .7]);
        xline(0.5,':','Always present','LabelOrientation','horizontal');
        yticks(1:height(m)); yticklabels(m.System); ylim([0.5 height(m)+0.5]);
        xlim([0 1]); grid on; xlabel('Balanced accuracy');
        title(target+": 95% source-pair intervals");
    end
    exportgraphics(fig,fullfile(folder,'balanced_accuracy_intervals.png'),'Resolution',180);
    close(fig);
end
end
