function tests = test_handcrafted_baseline
tests = functiontests(localfunctions);
end

function testFeatureDefinitions(testCase)
fs = 16000;
x = sin(2*pi*1000*(0:2*fs-1)'/fs);
[features,names,frames] = handcrafted_features(x,fs);
verifySize(testCase,features,[1 40]);
verifySize(testCase,frames,[198 20]);
verifyEqual(testCase,numel(unique(names)),40);
verifyEqual(testCase,features(1),1/sqrt(2),"AbsTol",1e-10);
verifyEqual(testCase,features(3),1000,"AbsTol",5);
verifyLessThan(testCase,features(6),100);
verifyLessThan(testCase,features(7),0.01);
verifyEqual(testCase,features,[mean(frames,1),std(frames,0,1)],"AbsTol",1e-12);
verifyEqual(testCase,features,handcrafted_features(x,fs));
end

function testSilenceAndShortSegments(testCase)
[features,~,frames] = handcrafted_features(zeros(20,1),16000);
verifySize(testCase,frames,[1 20]);
verifyTrue(testCase,all(isfinite(features)));
verifyEqual(testCase,features(1:7),zeros(1,7));
verifyEqual(testCase,features(21:40),zeros(1,20));
end

function testMetricCounts(testCase)
truth = logical([1 0;0 1;1 1;0 0]);
predicted = logical([1 1;1 0;0 1;0 0]);
m = presence_metrics(truth,predicted);
verifyEqual(testCase,m{:,1:4},ones(2,4));
verifyEqual(testCase,m{:,5:7},0.5*ones(2,3));
m = presence_metrics(false(3,2),false(3,2));
verifyEqual(testCase,m{:,5:7},zeros(2,3));
end

function testSourceSplitAndEndToEnd(testCase)
root = string(tempname);
mkdir(root);
cleanup = onCleanup(@() rmdir(root,"s"));
datasetRoot = fullfile(root,"musan");
fs = 16000;
t = (0:2*fs-1)'/fs;
for source = ["speech","music"]
    folder = fullfile(datasetRoot,source);
    mkdir(folder);
    for k = 1:14
        if source == "speech"
            x = sin(2*pi*(180+7*k)*t).*(0.5+0.4*sin(2*pi*4*t));
        else
            x = 0.5*sin(2*pi*(700+11*k)*t)+0.3*sin(2*pi*(1400+13*k)*t);
        end
        if k == 1
            audiowrite(fullfile(folder,sprintf("%02d.wav",k)),[x(1:2:end),0.5*x(1:2:end)],fs/2);
        else
            audiowrite(fullfile(folder,sprintf("%02d.wav",k)),x,fs);
        end
    end
end
splitDir = fullfile(root,"splits");
rngBefore = rng;
split = create_source_split(datasetRoot,splitDir);
verifyEqual(testCase,rng,rngBefore);
second = create_source_split(datasetRoot,fullfile(root,"splits_again"));
verifyEqual(testCase,split,second);
validate_source_split(split);
leaking = split;
leaking.speech.test(1) = leaking.speech.train(1);
verifyError(testCase,@() validate_source_split(leaking),"presence:SourceLeakage");
[X,metadata,names] = build_presence_dataset(split,"train",2,fs,2,[-10 0 10]);
verifySize(testCase,X,[10 40]);
verifyEqual(testCase,sum(metadata.SpeechPresent),8);
verifyEqual(testCase,sum(metadata.MusicPresent),8);
mixtures = metadata.AudioType == "mixture";
verifyEqual(testCase,metadata.MeasuredSMR_dB(mixtures),metadata.TargetSMR_dB(mixtures),"AbsTol",1e-10);
verifyTrue(testCase,all(isnan(metadata.TargetSMR_dB(~mixtures))));
verifyError(testCase,@() build_presence_dataset(split,"validation",99,fs,2,[-10 0 10]), ...
    "presence:InsufficientSources");

outDir = fullfile(root,"results");
a = preliminary_mixture_demo(SplitFile=fullfile(splitDir,"source_split.mat"), ...
    ResultsDir=outDir,TrainPairs=2,ValidationPairs=2,TestPairs=2, ...
    BoxConstraints=[0.1 1],UseYAMNet=false,MakePlots=true);
verifyEqual(testCase,rng,rngBefore);
verifySize(testCase,a.Predictions,[10 14]);
verifyEqual(testCase,a.FeatureNames,names);
verifyEqual(testCase,height(a.Metrics),2);
verifyEqual(testCase,sum(a.Tuning.Selected),2);
verifyTrue(testCase,all(a.Predictions.Partition == "test"));
verifyTrue(testCase,isfile(fullfile(outDir,"preliminary_handcrafted_models.mat")));
verifyTrue(testCase,isfile(fullfile(outDir,"preliminary_figures","presence_metrics_comparison.png")));
verifyTrue(testCase,isfile(fullfile(outDir,"preliminary_figures","presence_recall_vs_smr.png")));
verifyTrue(testCase,isfile(fullfile(outDir,"preliminary_figures","pair_01_smr_comparison.png")));
features = readtable(fullfile(outDir,"preliminary_handcrafted_features.csv"));
verifyEqual(testCase,height(features),30);

% Saved scaling comes from the training rows, and saved models reproduce margins.
saved = load(fullfile(outDir,"preliminary_handcrafted_models.mat"));
training = string(features.Partition) == "train";
verifyEqual(testCase,saved.models.Speech.Mu,mean(features{training,10:end},1),"AbsTol",1e-9);
test = string(features.Partition) == "test";
[decisions,margins] = predict_handcrafted_baseline(saved.models,features{test,10:end});
verifyEqual(testCase,decisions,[a.Predictions.SVMSpeechPresent,a.Predictions.SVMMusicPresent]);
verifyEqual(testCase,margins,[a.Predictions.SVMSpeechMargin,a.Predictions.SVMMusicMargin],"AbsTol",1e-8);
end

function testHeldOutRowsCannotChangeTraining(testCase)
state = rng;
cleanup = onCleanup(@() rng(state));
X = [(1:12)',sin((1:12)')];
labels = repmat(logical([0 1;1 0]),6,1);
train = [true(6,1);false(6,1)];
validation = [false(6,1);true(4,1);false(2,1)];
[models,tuning] = train_handcrafted_baseline(X,labels,train,validation,[0.1 1]);
changedX = X;
changedX(11:12,:) = 1e6;
changedLabels = labels;
changedLabels(11:12,:) = ~changedLabels(11:12,:);
rng(state);
[other,otherTuning] = train_handcrafted_baseline(changedX,changedLabels,train,validation,[0.1 1]);
verifyEqual(testCase,models.Speech.Mu,other.Speech.Mu);
verifyEqual(testCase,models.Music.Beta,other.Music.Beta,"AbsTol",1e-10);
verifyEqual(testCase,tuning,otherTuning);
end

function testWeakerSourceAndSharedEvaluation(testCase)
metadata = table(repmat("test",5,1),["mixture";"mixture";"mixture";"speech_only";"music_only"], ...
    [-10;0;10;NaN;NaN],logical([1;1;1;1;0]),logical([1;1;1;0;1]), ...
    "VariableNames",{"Partition","AudioType","TargetSMR_dB","SpeechPresent","MusicPresent"});
predictions = false(5,2,2);
predictions(:,:,1) = [0 1;1 1;1 0;1 0;0 1];
predictions(:,:,2) = [1 0;1 1;0 1;1 1;1 1];
[metrics,recall] = evaluate_presence_systems(metadata,predictions,["SVM","YAMNet"],[-10 0 10]);
verifyEqual(testCase,height(metrics),4);
verifyEqual(testCase,recall.WeakerSource,["Speech";"None";"Music";"Speech";"None";"Music"]);
verifyEqual(testCase,recall.WeakerSourceRecall([1 3 4 6]),[0;0;1;1]);
verifyTrue(testCase,all(isnan(recall.WeakerSourceRecall([2 5]))));
verifyEqual(testCase,recall.WeakerSourceCount([2 5]),[0;0]);
end
