function [features,names,frames] = handcrafted_features(x,fs)
%HANDCRAFTED_FEATURES Fixed 40-value segment descriptor (mean then std).
% 25 ms periodic Hann frames, 10 ms hop, power spectrum, 85% rolloff,
% 40 triangular HTK-mel bands (20 Hz to Nyquist), 13 orthonormal MFCCs
% including c0. No deltas, pre-emphasis, liftering or segment-level fitting.

validateattributes(x,{"numeric"},{"vector","real","finite","nonempty"});
validateattributes(fs,{"numeric"},{"scalar","real","finite",">=",1000});
x = double(x(:));
windowLength = round(0.025*fs);
hopLength = round(0.010*fs);
fftLength = 2^nextpow2(windowLength);
if numel(x) < windowLength
    x(end+1:windowLength) = 0;
end
starts = 1:hopLength:(numel(x)-windowLength+1);
samples = x((0:windowLength-1)' + starts);
rmsEnergy = sqrt(mean(samples.^2,1));
zcr = mean(diff(samples >= 0,1,1) ~= 0,1);
window = 0.5 - 0.5*cos(2*pi*(0:windowLength-1)'/windowLength);
spectrum = abs(fft(samples.*window,fftLength,1)).^2;
spectrum = spectrum(1:fftLength/2+1,:);
frequency = (0:fftLength/2)'*fs/fftLength;
power = sum(spectrum,1);
normalised = spectrum./max(power,realmin);
centroid = sum(frequency.*normalised,1);
bandwidth = sqrt(sum((frequency-centroid).^2.*normalised,1));
flux = [0 sqrt(sum(diff(normalised,1,2).^2,1))];
[~,rolloffIndex] = max(cumsum(normalised,1) >= 0.85,[],1);
rolloff = frequency(rolloffIndex)';
flatness = exp(mean(log(max(spectrum,1e-12)),1))./max(mean(spectrum,1),1e-12);
silent = power == 0;
rolloff(silent) = 0;
flatness(silent) = 0;

melEdges = linspace(2595*log10(1+20/700),2595*log10(1+(fs/2)/700),42);
hzEdges = 700*(10.^(melEdges/2595)-1);
filterBank = zeros(40,numel(frequency));
for k = 1:40
    rising = (frequency-hzEdges(k))/(hzEdges(k+1)-hzEdges(k));
    falling = (hzEdges(k+2)-frequency)/(hzEdges(k+2)-hzEdges(k+1));
    filterBank(k,:) = max(0,min(rising,falling))';
end
cosine = sqrt(2/40)*cos(pi/40*(0:12)'*((0:39)+0.5));
cosine(1,:) = cosine(1,:)/sqrt(2);
coefficients = cosine*log(max(filterBank*spectrum,1e-12));
frames = [rmsEnergy; zcr; centroid; flux; rolloff; bandwidth; flatness; coefficients]';
baseNames = ["RMS","ZCR","SpectralCentroid","SpectralFlux", ...
    "SpectralRolloff","SpectralBandwidth","SpectralFlatness","MFCC"+string(0:12)];
features = [mean(frames,1),std(frames,0,1)];
names = [baseNames+"_Mean",baseNames+"_Std"];
assert(all(isfinite(features)),"Feature extraction produced non-finite values.");
end
