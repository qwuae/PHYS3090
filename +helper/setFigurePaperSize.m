function setFigurePaperSize()
set(gcf,'InvertHardcopy','on');
set(gcf,'PaperUnits', 'inches');
fDim = get(gcf, 'Position');
pSize = get(gcf, 'PaperSize');
pW = fDim(3)/100;
pH = fDim(4)/100;
pL = (pSize(1)- pW)/2;
pB = (pSize(2)- pH)/2;
set(gcf,'PaperPosition', [pL, pB, pW, pH]);
end