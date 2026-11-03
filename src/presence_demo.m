function result = presence_demo(audioFile,modelFile,options)
%PRESENCE_DEMO Inspect the two SVM versions on one audio excerpt.
arguments
    audioFile (1,1) string
    modelFile (1,1) string = fullfile('results','development','preliminary_handcrafted_models.mat')
    options.PlayAudio (1,1) logical = false
    options.MakePlot (1,1) logical = true
end
saved = load(modelFile);
c = saved.configuration;
x = read_audio_segment(audioFile,c.SampleRate,c.DurationSec);
peak = max(abs(x)); assert(peak>eps,"The excerpt is silent.");
x = 0.99*x/peak;
[features,names] = handcrafted_features(x,c.SampleRate);
assert(isequal(names,saved.featureNames),"Feature schema differs from the saved model.");
[a,ma] = predict_handcrafted_baseline(saved.models,features);
[b,mb] = predict_handcrafted_baseline(saved.balancedModels,features);
result = table(["SVM unweighted";"SVM balanced"],[a(1);b(1)],[a(2);b(2)], ...
    [ma(1);mb(1)],[ma(2);mb(2)],'VariableNames', ...
    {'System','SpeechPresent','MusicPresent','SpeechMargin','MusicMargin'});
disp(result);
if options.MakePlot
    figure('Color','w','Position',[100 100 900 550]);
    tiledlayout(2,1,'TileSpacing','compact');
    nexttile; plot((0:numel(x)-1)/c.SampleRate,x); grid on;
    xlabel('Time (s)'); ylabel('Amplitude'); title('Audio excerpt');
    nexttile; spectrogram(x,hann(512,'periodic'),384,1024,c.SampleRate,'yaxis');
    title('Spectrum over time');
end
if options.PlayAudio, sound(x,c.SampleRate); end
end
