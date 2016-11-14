function setPolarFontSize(sz)
for tHandle = findall(gcf,'Type','Text');
 	set(tHandle,'FontSize',sz);
end
end