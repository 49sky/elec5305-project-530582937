function [metrics,recallBySMR] = evaluate_presence_systems(metadata,predictions,systemNames,smrValues)
%EVALUATE_PRESENCE_SYSTEMS Shared held-out evaluation for both systems.
% predictions: observations x [speech,music] x systems, hard decisions.
assert(all(metadata.Partition == "test"),"Evaluation requires held-out test rows.");
assert(size(predictions,1) == height(metadata) && size(predictions,2) == 2 ...
    && size(predictions,3) == numel(systemNames),"Prediction dimensions do not match.");
truth = [metadata.SpeechPresent,metadata.MusicPresent];
metrics = table;
recallBySMR = table;
for system = 1:numel(systemNames)
    m = presence_metrics(truth,predictions(:,:,system));
    m = addvars(m,repmat(string(systemNames(system)),2,1),["Speech";"Music"], ...
        'Before',1,'NewVariableNames',{'System','Target'});
    metrics = [metrics; m]; %#ok<AGROW>
    for smr = smrValues(:)'
        rows = metadata.AudioType == "mixture" & metadata.TargetSMR_dB == smr;
        n = sum(rows);
        speechRecall = sum(predictions(rows,1,system))/max(n,1);
        musicRecall = sum(predictions(rows,2,system))/max(n,1);
        if smr < 0
            weaker = "Speech";
            weakerRecall = speechRecall;
            weakerCount = n;
        elseif smr > 0
            weaker = "Music";
            weakerRecall = musicRecall;
            weakerCount = n;
        else
            % Equal-power mixtures have no weaker source.
            weaker = "None";
            weakerRecall = NaN;
            weakerCount = 0;
        end
        row = table(string(systemNames(system)),smr,n,speechRecall,musicRecall, ...
            weaker,weakerCount,weakerRecall,'VariableNames',{'System','SMR_dB', ...
            'Mixtures','SpeechRecall','MusicRecall','WeakerSource', ...
            'WeakerSourceCount','WeakerSourceRecall'});
        recallBySMR = [recallBySMR; row]; %#ok<AGROW>
    end
end
end
