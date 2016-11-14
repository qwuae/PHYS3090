function setPolarLim(lim)
    h_fake = polar([0 lim 0 -lim], [lim 0 -lim 0]); hold on;
    set(h_fake,'Visible','off');
end
