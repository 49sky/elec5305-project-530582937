function [intervals,comparisons] = bootstrap_presence_metrics(metadata,predictions,systemNames,options)
arguments
    metadata table
    predictions {mustBeNumericOrLogical}
    systemNames (1,:) string
    options.Resamples (1,1) double {mustBeInteger,mustBePositive} = 2000
    options.Seed (1,1) double {mustBeInteger,mustBeNonnegative} = 530582937
    options.Contrasts (:,2) double {mustBeInteger,mustBePositive} = zeros(0,2)
end
assert(all(metadata.Partition=="test"),"presence:BootstrapPartition","Use test predictions only.");
validateattributes(predictions,{'numeric','logical'}, ...
    {'binary','size',[height(metadata),2,numel(systemNames)]});
validateattributes(metadata.Pair,{'numeric'},{'column','finite','numel',height(metadata)});
assert(numel(unique(systemNames))==numel(systemNames),"System names must be unique.");
assert(all(options.Contrasts<=numel(systemNames),'all'),"Unknown contrast system.");
[pairs,~,group] = unique(metadata.Pair);
n = numel(pairs);
assert(n>=2,"presence:BootstrapPairs","At least two source pairs are needed.");
previous = rng; restore = onCleanup(@()rng(previous));
rng(options.Seed,'twister');
% Keep each pair's controls and mixtures together in every resample.
draws = randi(n,n,options.Resamples);
truth = [metadata.SpeechPresent,metadata.MusicPresent];
assert(all(ismember(truth,[0 1]),'all'),'presence:InvalidLabels','Presence labels must be zero or one.');
truth = logical(truth);
targets = ["Speech","Music"];
intervals = table; comparisons = table;
sampleBA = zeros(options.Resamples,numel(systemNames),2);
pointBA = zeros(numel(systemNames),2);
for target = 1:2
    y = truth(:,target);
    positives = accumarray(group,double(y),[n 1]);
    negatives = accumarray(group,double(~y),[n 1]);
    assert(all(positives>0 & negatives>0),"presence:BootstrapPairClasses", ...
        "Each pair must contain positive and negative examples for each target.");
    for system = 1:numel(systemNames)
        p = logical(predictions(:,target,system));
        counts = [accumarray(group,double(y&p),[n 1]), ...
            accumarray(group,double(~y&p),[n 1]), ...
            accumarray(group,double(y&~p),[n 1]), ...
            accumarray(group,double(~y&~p),[n 1])];
        totals = zeros(options.Resamples,4);
        for k = 1:4
            values = counts(:,k);
            totals(:,k) = sum(reshape(values(draws),size(draws)),1)';
        end
        tp = totals(:,1); fp = totals(:,2); fn = totals(:,3); tn = totals(:,4);
        samples = [(tp./(tp+fn)+tn./(tn+fp))/2,2*tp./(2*tp+fp+fn)];
        sampleBA(:,system,target) = samples(:,1);
        m = presence_metrics(y,p);
        pointBA(system,target) = m.BalancedAccuracy;
        bounds = prctile(samples,[2.5 97.5],1);
        rows = table(repmat(systemNames(system),2,1),repmat(targets(target),2,1), ...
            ["BalancedAccuracy";"F1"],[m.BalancedAccuracy;m.F1], ...
            bounds(1,:)',bounds(2,:)',repmat(n,2,1),repmat(options.Resamples,2,1), ...
            'VariableNames',{'System','Target','Metric','Estimate','Lower95','Upper95', ...
            'SourcePairs','Resamples'});
        intervals = [intervals;rows];
    end
    for contrast = options.Contrasts'
        a = contrast(1); b = contrast(2);
        bounds = prctile(sampleBA(:,a,target)-sampleBA(:,b,target),[2.5 97.5]);
        row = table(systemNames(a),systemNames(b),targets(target), ...
            pointBA(a,target)-pointBA(b,target),bounds(1),bounds(2),n,options.Resamples, ...
            'VariableNames',{'System','Reference','Target','Difference','Lower95', ...
            'Upper95','SourcePairs','Resamples'});
        comparisons = [comparisons;row];
    end
end
end
