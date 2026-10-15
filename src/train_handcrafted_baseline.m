function [models,tuning] = train_handcrafted_baseline(X,labels,trainRows,validationRows,boxConstraints)
%TRAIN_HANDCRAFTED_BASELINE Independent linear SVMs, validation-only C choice.
% Standardisation is fitted by fitcsvm using training rows only. No random
% segment-level CV or test data enter training or hyperparameter selection.
if nargin < 5
    boxConstraints = [0.01 0.1 1 10];
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
tuning = table;
for target = 1:2
    assert(numel(unique(labels(trainRows,target))) == 2, ...
        "Each training target needs positive and negative examples.");
    bestF1 = -Inf;
    bestIndex = 0;
    for c = 1:numel(boxConstraints)
        model = fitcsvm(X(trainRows,:),logical(labels(trainRows,target)), ...
            "KernelFunction","linear","KernelScale",1,"Standardize",true, ...
            "ClassNames",[false; true],"BoxConstraint",boxConstraints(c));
        prediction = predict(model,X(validationRows,:));
        m = presence_metrics(labels(validationRows,target),prediction);
        candidate = table(targets(target),boxConstraints(c),m.F1,false, ...
            'VariableNames',{'Target','BoxConstraint','ValidationF1','Selected'});
        tuning = [tuning; candidate]; %#ok<AGROW>
        % Strict comparison breaks ties in favour of the smallest C.
        if m.F1 > bestF1
            bestF1 = m.F1;
            models.(targets(target)) = compact(model);
            bestIndex = height(tuning);
        end
    end
    tuning.Selected(bestIndex) = true;
end
end
