function check_reproduction(folder)
reportFile = fullfile(folder,'reproduction_check.json');
if isfile(reportFile), delete(reportFile); end
reference = fullfile('results','final');
files = ["preliminary_handcrafted_features.csv","preliminary_presence_predictions.csv","preliminary_presence_metrics.csv", ...
    "preliminary_recall_vs_smr.csv","preliminary_svm_tuning.csv", ...
    "preliminary_yamnet_thresholds.csv","preliminary_metric_intervals.csv", ...
    "preliminary_paired_comparisons.csv"];
for file = files
    expected = readtable(fullfile(reference,file),'TextType','string','Delimiter',',','ReadVariableNames',true);
    actual = readtable(fullfile(folder,file),'TextType','string','Delimiter',',','ReadVariableNames',true);
    if file=="preliminary_yamnet_thresholds.csv"
        expected = sortrows(expected,{'Target','Threshold'});
        actual = sortrows(actual,{'Target','Threshold'});
    end
    assert(isequal(size(expected),size(actual)),"presence:ReproductionMismatch","Reproduction size differs: %s",file);
    assert(isequal(expected.Properties.VariableNames,actual.Properties.VariableNames), ...
        "presence:ReproductionMismatch","Reproduction columns differ: %s",file);
    for column = string(expected.Properties.VariableNames)
        if ismember(column,["AudioFile","MixtureFile"]), continue; end
        a = expected.(column); b = actual.(column);
        if isnumeric(a)
            same = (isnan(a)&isnan(b)) | abs(a-b)<=1e-6*max(1,abs(a));
        else
            same = (ismissing(a)&ismissing(b)) | a==b;
        end
        assert(all(same,'all'),"presence:ReproductionMismatch","Reproduction differs: %s, %s",file,column);
    end
end
report = struct('Reference',reference,'ComparedFiles',files,'Status','passed', ...
    'NumericTolerance',1e-6,'CodeRevision',string(getenv('GITHUB_SHA')));
fid = fopen(reportFile,'w');
assert(fid~=-1,"Could not write the reproduction check.");
fprintf(fid,'%s\n',jsonencode(report,PrettyPrint=true)); fclose(fid);
disp('Final predictions, selected settings and metrics match the recorded run.');
end
