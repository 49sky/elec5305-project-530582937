function plot_presence_comparison(metrics,recallBySMR,figureDir)
systems = unique(metrics.System,"stable");
fig = figure("Color","w","Visible","off","Position",[100 100 1100 430]);
layout = tiledlayout(1,2,"TileSpacing","compact");
for k = 1:2
    targets = ["Speech","Music"];
    rows = metrics.Target == targets(k);
    nexttile;
    bar([metrics.Precision(rows),metrics.Recall(rows),metrics.F1(rows), ...
        metrics.Specificity(rows),metrics.BalancedAccuracy(rows)]');
    xticks(1:5);
    xticklabels(["Precision","Recall","F1","Specificity","Balanced accuracy"]);
    xtickangle(20);
    ylim([0 1]); grid on;
    title(targets(k)+" presence");
    if k==1, legend(systems,"Location","southoutside"); end
end
title(layout,"Held-out test performance (pure sources and mixtures)");
exportgraphics(fig,fullfile(figureDir,"presence_metrics_comparison.png"),"Resolution",180);
close(fig);
targets = ["Speech","Music"];
for target = targets
    fig = figure("Color","w","Visible","off", ...
        "Position",[100 100 260*numel(systems) 300]);
    tiledlayout(1,numel(systems),"TileSpacing","compact","Padding","compact");
    for system = systems'
        m = metrics(metrics.System==system & metrics.Target==target,:);
        counts = [m.TN m.FP;m.FN m.TP];
        fractions = counts./sum(counts,2);
        nexttile; imagesc(fractions,[0 1]); axis square;
        xticks(1:2); yticks(1:2);
        xticklabels(["Absent","Present"]); yticklabels(["Absent","Present"]);
        xlabel("Predicted"); ylabel("Actual"); title(system);
        for actual = 1:2
            for predicted = 1:2
                text(predicted,actual,sprintf('%d\n%.0f%%', ...
                    counts(actual,predicted),100*fractions(actual,predicted)), ...
                    'HorizontalAlignment','center','Color','k','BackgroundColor','w');
            end
        end
    end
    exportgraphics(fig,fullfile(figureDir,lower(target)+"_confusion.png"),"Resolution",180);
    close(fig);
end
fig = figure("Color","w","Visible","off","Position",[100 100 1200 380]);
layout = tiledlayout(1,3,"TileSpacing","compact");
variables = ["SpeechRecall","MusicRecall","WeakerSourceRecall"];
titles = ["Speech","Music","Weaker source (0 dB excluded)"];
for k = 1:3
    nexttile; hold on;
    for system = systems'
        rows = recallBySMR.System == system;
        plot(recallBySMR.SMR_dB(rows),recallBySMR.(variables(k))(rows),"-o","LineWidth",1.2);
    end
    xlabel("Speech-to-Music Ratio (dB)"); ylabel("Recall");
    ylim([0 1]); grid on; title(titles(k));
    legend(systems,"Location","best");
end
title(layout,"Held-out mixture recall versus SMR");
exportgraphics(fig,fullfile(figureDir,"presence_recall_vs_smr.png"),"Resolution",180);
close(fig);
end
