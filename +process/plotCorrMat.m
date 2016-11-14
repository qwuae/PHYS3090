function plotCorrMat(Monkey)
import process.*;
import helper.*;
% monkey
files = dir(['data/',Monkey]);
sz = length(files) - 2;

% initialize Array
n = Neuron(sz);
idx = 0;
% loop over each neuron
for file = files';
    if (strcmp(file.name,'.')==0 && strcmp(file.name,'..')==0)
        idx = idx + 1; if idx > sz; break; end; disp(file.name);
        % get information of each neuron 
        [~,n(idx).fname,~] = fileparts(file.name);
        n(idx).index = idx;
        pathstr = [Monkey,'/',n(idx).fname];
        % [1] overall average aligned on saccade
        [ n(idx).rate{6},...
          n(idx).time{6},...
          ~ ...
        ] = averageFiringRate('file',pathstr);
        % [2] each period
        for i = 1:1:5
            [ n(idx).rate{i},...
              n(idx).time{i},...
              n(idx).tcut{i} ...
            ] = averagePeriodFiringRate('loc',pathstr ,...
                                        'per',i       ,...
                                        'dis',false   ,...
                                        'cut',true    );
        end
    end
end
% correlation plot
corrMat = zeros(sz,sz,5);
for k = 1:5;
figure;
for i = 1:sz;
for j = 1:sz;
    ri = n(i).rate{k};
    rj = n(j).rate{k};
    ti = n(i).time{k};
    tj = n(j).time{k};
    ci = n(i).tcut{k};
    cj = n(j).tcut{k};
    % compare lengths
    [ri, rj] = alignShrink(ri,rj,ti,tj,ci,cj);
    % calculate correlation coefficient
    tmp = corrcoef(ri', rj');
    corrMat(i,j,k) = tmp(1,2);
end
end
imagesc(corrMat(:,:,k));
axis equal tight;
colorbar;
title(Neuron.getPeriodName(k));
print(['output/',Monkey,'_corrMat_',Neuron.getPeriodName(k)],...
       '-djpeg',...
       '-r300');
end
close all;
end