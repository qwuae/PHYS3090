function plotEach(Monkey)
import helper.*;
import process.*;
% monkey
files = dir(['data/',Monkey]);
close all;
for file = files'
   if (strcmp(file.name,'.')==0 && strcmp(file.name,'..')==0)
      [~,name,~] = fileparts(file.name);
      disp(file.name);
      %
      % [1] plot average firing rate
      figure('name',file.name,'Visible','off');
      [~,filename,~] = fileparts(file.name);
      averagePeriodFiringRate('loc',[Monkey,'/',filename],...
         'append',true, 'per', 4);
      setFigurePaperSize();
      print(['output/',Monkey,'_average',name],'-djpeg','-r300');
      close;
      %
      % [2] plot average polar
      figure('name',file.name,'Visible','off');
      setFigureSize([1200,800]);
      setFigurePaperSize();
      [~,filename,~] = fileparts(file.name);
      for i = 1:5
         subplot(2,3,i);
         averagePeriodFiringRate...
            ('loc',[Monkey,'/',filename],...
            'plotContent','polar',...
            'per',i,...
            'cut',true,...            
            'append',true);
      end
      subplot(2,3,6);
      axis off;
      text(0.1,0.1,'period 1 = before visual target');
      text(0.1,0.3,'period 2 = during visual target');
      text(0.1,0.5,'period 3 = memory period');
      text(0.1,0.7,'period 4 = during saccade');
      text(0.1,0.9,'period 5 = after saccade');
      print(['output/',Monkey,'_aPolar',name],'-djpeg','-r300');
      close;
   end
end
close all;
end