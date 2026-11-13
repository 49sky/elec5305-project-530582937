function metrics = presence_metrics(truth,predicted)
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
positiveCount = tp+fn;
negativeCount = tn+fp;
specificity = tn./negativeCount;
balancedAccuracy = (recall+specificity)/2;
negativeF1 = 2*tn./max(2*tn+fp+fn,1);
macroF1 = (f1+negativeF1)/2;
missingClass = positiveCount==0 | negativeCount==0;
balancedAccuracy(missingClass) = NaN;
macroF1(missingClass) = NaN;
metrics = table(tp,fp,fn,tn,precision,recall,f1,specificity, ...
    balancedAccuracy,macroF1,positiveCount,negativeCount, ...
    'VariableNames',{'TP','FP','FN','TN','Precision','Recall','F1', ...
    'Specificity','BalancedAccuracy','MacroF1','PositiveCount','NegativeCount'});
end
