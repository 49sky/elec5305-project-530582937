function [X,metadata,featureNames,audio] = build_presence_dataset(split,partition,nPairs,fs,durationSec,smrValues)
%BUILD_PRESENCE_DATASET One central segment per source, with pure negatives.
% Pairing is deterministic; all derivatives retain their source partition.
validateattributes(nPairs,{"numeric"},{"scalar","integer","positive"});
validateattributes(smrValues,{"numeric"},{"vector","real","finite","nonempty"});
speechFiles = string(split.speech.(partition)(:));
musicFiles = string(split.music.(partition)(:));
if numel(speechFiles) < nPairs || numel(musicFiles) < nPairs
    error("presence:InsufficientSources", ...
        "%s needs %d speech and music sources; found %d and %d.", ...
        partition,nPairs,numel(speechFiles),numel(musicFiles));
end
nRows = nPairs*(2+numel(smrValues));
X = zeros(nRows,40);
audio = cell(nRows,1);
metadata = table(repmat(string(partition),nRows,1),zeros(nRows,1), ...
    strings(nRows,1),strings(nRows,1),strings(nRows,1),nan(nRows,1), ...
    nan(nRows,1),false(nRows,1),false(nRows,1), ...
    "VariableNames",{"Partition","Pair","AudioType","SpeechFile","MusicFile", ...
    "TargetSMR_dB","MeasuredSMR_dB","SpeechPresent","MusicPresent"});
row = 0;
for pair = 1:nPairs
    speech = read_audio_segment(speechFiles(pair),fs,durationSec);
    music = read_audio_segment(musicFiles(pair),fs,durationSec);
    for kind = 1:(2+numel(smrValues))
        row = row+1;
        metadata.Pair(row) = pair;
        if kind == 1
            x = normalise_peak(speech);
            metadata.AudioType(row) = "speech_only";
            metadata.SpeechPresent(row) = true;
        elseif kind == 2
            x = normalise_peak(music);
            metadata.AudioType(row) = "music_only";
            metadata.MusicPresent(row) = true;
        else
            targetSMR = smrValues(kind-2);
            [x,measuredSMR] = make_smr_mixture(speech,music,targetSMR);
            metadata.AudioType(row) = "mixture";
            metadata.TargetSMR_dB(row) = targetSMR;
            metadata.MeasuredSMR_dB(row) = measuredSMR;
            metadata.SpeechPresent(row) = true;
            metadata.MusicPresent(row) = true;
        end
        if metadata.SpeechPresent(row)
            metadata.SpeechFile(row) = speechFiles(pair);
        end
        if metadata.MusicPresent(row)
            metadata.MusicFile(row) = musicFiles(pair);
        end
        [X(row,:),featureNames] = handcrafted_features(x,fs);
        audio{row} = x;
    end
end
end

function x = normalise_peak(x)
peak = max(abs(x));
if peak <= eps
    error("presence:SilentSource","A selected central source segment is silent.");
end
x = 0.99*x/peak;
end
