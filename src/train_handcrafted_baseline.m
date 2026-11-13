function [models,tuning] = train_handcrafted_baseline(X,labels,trainRows,validationRows,boxConstraints,balanceClasses)
if nargin < 5, boxConstraints = [0.01 0.1 1 10]; end
if nargin < 6, balanceClasses = false; end
if balanceClasses
    prior = "uniform"; variant = "SVM balanced";
else
    prior = "empirical"; variant = "SVM unweighted";
end
validateattributes(X,{'numeric'},{'2d','real','finite','nonempty'});
validateattributes(labels,{'numeric','logical'},{'size',[size(X,1),2],'binary'});
validateattributes(trainRows,{'logical'},{'column','numel',size(X,1)});
validateattributes(validationRows,{'logical'},{'column','numel',size(X,1)});
validateattributes(boxConstraints,{'numeric'},{'vector','positive','finite','nonempty'});
assert(any(trainRows) && any(validationRows) && ~any(trainRows & validationRows), ...
    "Training and validation rows must be nonempty and disjoint.");
boxConstraints = sort(unique(boxConstraints));
targets = ["Speech","Music"];
models = struct;
models.Mean = mean(X(trainRows,:),1);
models.Scale = std(X(trainRows,:),0,1);
models.Scale(models.Scale==0) = 1;
models.BalanceClasses = balanceClasses;
% Use the same training-derived scaling for both prior settings.
scaled = (X-models.Mean)./models.Scale;
tuning = table;
for target = 1:2
    assert(numel(unique(labels(trainRows,target))) == 2, ...
        "Each training target needs positive and negative examples.");
    assert(numel(unique(labels(validationRows,target))) == 2, ...
        "Each validation target needs positive and negative examples.");
    bestScore = -Inf;
    bestIndex = 0;
    for c = 1:numel(boxConstraints)
        model = fitcsvm(scaled(trainRows,:),logical(labels(trainRows,target)), ...
            "KernelFunction","linear","KernelScale",1,"Standardize",false, ...
            "Prior",prior,"ClassNames",[false; true],"BoxConstraint",boxConstraints(c));
        prediction = predict(model,scaled(validationRows,:));
        m = presence_metrics(labels(validationRows,target),prediction);
        candidate = table(variant,targets(target),boxConstraints(c), ...
            m.BalancedAccuracy,m.F1,m.Specificity,false, ...
            'VariableNames',{'Variant','Target','BoxConstraint', ...
            'ValidationBalancedAccuracy','ValidationF1','ValidationSpecificity','Selected'});
        tuning = [tuning; candidate];
        if m.BalancedAccuracy > bestScore
            bestScore = m.BalancedAccuracy;
            models.(targets(target)) = compact(model);
            bestIndex = height(tuning);
        end
    end
    tuning.Selected(bestIndex) = true;
end
end
