function plot_presence_comparison(metrics,recallBySMR,figureDir)
%PLOT_PRESENCE_COMPARISON Hard-decision metrics on the same test examples.
systems = unique(metrics.System,"stable");
fig = figure("Color","w","Visible","off");
layout = tiledlayout(1,2,"TileSpacing","compact");
for k = 1:2
    targets = ["Speech","Music"];
    rows = metrics.Target == targets(k);
    nexttile;
    bar([metrics.Precision(rows),metrics.Recall(rows),metrics.F1(rows)]');
    xticks(1:3);
    xticklabels(["Precision","Recall","F1"]);
    ylim([0 1]); grid on;
    title(targets(k)+" presence");
    legend(systems,"Location","best");
end
title(layout,"Held-out test performance (pure sources and mixtures)");
exportgraphics(fig,fullfile(figureDir,"presence_metrics_comparison.png"),"Resolution",180);
close(fig);
fig = figure("Color","w","Visible","off");
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
