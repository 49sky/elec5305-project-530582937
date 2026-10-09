function [x,fs] = read_audio_segment(filePath,targetFs,durationSec)

[x,fs0] = audioread(filePath);

if size(x,2) > 1
    x = mean(x,2);
end

if fs0 ~= targetFs
    x = resample(x,targetFs,fs0);
end

fs = targetFs;
L = round(durationSec*fs);

if numel(x) < L
    error("Audio file is shorter than %.1f seconds: %s",durationSec,filePath);
end

startIndex = floor((numel(x)-L)/2) + 1;
x = x(startIndex:startIndex+L-1);

x = x - mean(x);

end
