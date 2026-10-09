function [speechScore,musicScore,scores] = yamnet_scores(x,fs,net,classNames)

spectrograms = yamnetPreprocess(x,fs);
scores = predict(net,spectrograms);

if isa(scores,"dlarray")
    scores = extractdata(scores);
end

if isa(scores,"gpuArray")
    scores = gather(scores);
end

names = string(classNames);
speechIndex = find(strcmpi(names,"Speech"),1);
musicIndex = find(strcmpi(names,"Music"),1);

if isempty(speechIndex) || isempty(musicIndex)
    error("Speech or Music class was not found in the YAMNet class list.");
end

if size(scores,2) == numel(names)
    speechScore = mean(scores(:,speechIndex));
    musicScore = mean(scores(:,musicIndex));
elseif size(scores,1) == numel(names)
    speechScore = mean(scores(speechIndex,:));
    musicScore = mean(scores(musicIndex,:));
else
    error("Unexpected YAMNet score dimensions.");
end

end
