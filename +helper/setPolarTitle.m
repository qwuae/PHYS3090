function setPolarTitle(text)
	% setup original axis
    axis on; 
    title(text);
    set(gca,...
        'XTick',[],'YTick',[],...
        'Color',[0.8 0.8 0.8],...
        'XColor',[0.8 0.8 0.8],...
        'YColor',[0.8 0.8 0.8]);
end