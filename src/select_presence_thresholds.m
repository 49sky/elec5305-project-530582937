function [thresholds,tuning] = select_presence_thresholds(scores,labels,candidates)
if nargin < 3, candidates = 0:0.05:1; end
validateattributes(scores,{'numeric'},{'2d','ncols',2,'finite','>=',0,'<=',1});
validateattributes(labels,{'numeric','logical'},{'size',size(scores),'binary'});
validateattributes(candidates,{'numeric'},{'vector','finite','>=',0,'<=',1,'nonempty'});
candidates = unique(candidates(:));
[~,order] = sortrows([round(abs(candidates-0.5),12),candidates],[1 2]);
candidates = candidates(order);
targets = ["Speech","Music"];
thresholds = zeros(1,2); tuning = table;
for k = 1:2
    assert(numel(unique(labels(:,k)))==2,"Validation needs both classes for each output.");
    best = -Inf; selected = 0;
    for threshold = candidates'
        m = presence_metrics(labels(:,k),scores(:,k)>=threshold);
        row = table(targets(k),threshold,m.BalancedAccuracy,m.F1,m.Specificity,false, ...
            'VariableNames',{'Target','Threshold','ValidationBalancedAccuracy', ...
            'ValidationF1','ValidationSpecificity','Selected'});
        tuning = [tuning;row];
        if m.BalancedAccuracy > best
            best = m.BalancedAccuracy;
            thresholds(k) = threshold;
            selected = height(tuning);
        end
    end
    tuning.Selected(selected) = true;
end
end
