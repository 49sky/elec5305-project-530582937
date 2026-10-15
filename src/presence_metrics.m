function metrics = presence_metrics(truth,predicted)
%PRESENCE_METRICS Per-output counts and metrics; undefined ratios are zero.
validateattributes(truth,{'numeric','logical'},{'2d','binary','nonempty'});
validateattributes(predicted,{'numeric','logical'},{'size',size(truth),'binary'});
truth = logical(truth);
predicted = logical(predicted);
tp = sum(truth & predicted,1)';
fp = sum(~truth & predicted,1)';
fn = sum(truth & ~predicted,1)';
tn = sum(~truth & ~predicted,1)';
precision = tp./max(tp+fp,1);
recall = tp./max(tp+fn,1);
f1 = 2*tp./max(2*tp+fp+fn,1);
metrics = table(tp,fp,fn,tn,precision,recall,f1, ...
    'VariableNames',{'TP','FP','FN','TN','Precision','Recall','F1'});
end
