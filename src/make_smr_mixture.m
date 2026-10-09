function [mix,measuredSMR,scale] = make_smr_mixture(speech,music,targetSMR)

speech = speech(:);
music = music(:);

L = min(numel(speech),numel(music));
speech = speech(1:L);
music = music(1:L);

speech = speech - mean(speech);
music = music - mean(music);

Ps = mean(speech.^2);
Pm = mean(music.^2);

if Ps <= eps || Pm <= eps
    error("Speech or music segment has near-zero power.");
end

scale = sqrt(Ps/(Pm*10^(targetSMR/10)));
musicScaled = scale*music;

measuredSMR = 10*log10(mean(speech.^2)/mean(musicScaled.^2));

mix = speech + musicScaled;
peak = max(abs(mix));

if peak > 0
    mix = 0.99*mix/peak;
end

end
