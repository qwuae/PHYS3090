function setFigureSize(fDim)
    fPos = get(gcf, 'Position'); % figure center
    fCen = fPos(1:2) + fPos(3:4) * 0.5;
    figX = fCen(1) - fDim(1)/2; % center the figure on X
    figY = fCen(2) - fDim(2)/2; % center the figure on Y
    set(gcf, 'Position', [figX, figY, fDim(1), fDim(2)]);
end