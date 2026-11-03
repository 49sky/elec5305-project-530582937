function [predictions,margins] = predict_handcrafted_baseline(models,X)
%PREDICT_HANDCRAFTED_BASELINE Positive-class SVM margins are not probabilities.
targets = ["Speech","Music"];
if isfield(models,'Mean')
    X = (X-models.Mean)./models.Scale;
end
predictions = false(size(X,1),2);
margins = zeros(size(X,1),2);
for k = 1:2
    model = models.(targets(k));
    [predictions(:,k),scores] = predict(model,X);
    positiveColumn = find(model.ClassNames == true,1);
    margins(:,k) = scores(:,positiveColumn);
end
end
