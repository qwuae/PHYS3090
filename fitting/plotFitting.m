%% plot fitting results
% pre-defined variables
run ../setpaths.m;
import helper.*;
import process.*;
if ~exist('date_stamp','var')
   date_stamp = datestr(datetime('now'),'mmmm-ddHHMM');
end
if ~exist('fits','var')
   error('please run "computeFitting" first');
end
% if ~exist('fitB','var')
%    error('please run "computeFitting" first');
% end
%
% make figure
m_h = figure;
m_w = length(glm_models);
setFigureSize([800,600]);
%
% estimated filter
for m_t = 1:length(glm_models)   
   m_type = glm_models{m_t};
   % stimuli kernel
   subplot(12, m_w, m_t : m_w : 7 * m_w + m_t);
   imagesc(fits(m_t).ggf.k);
   if ~ispc
      m_label = ...
         cellfun(@(x)str2double(x),get(gca,'YTickLabel')) .* glm_sps_dt;
      m_label = arrayfun(@(x)num2str(x),m_label,'UniformOutput',false);
      set(gca,'YTickLabel', m_label);
   end
   title('ML estimate: full filter');
   xlabel('space');
   ylabel('time(ms)');
   colorbar;
   % post-spike kernel
   subplot(12, m_w, 10 * m_w + m_t : m_w : 11 * m_w + m_t);
   plot(fits(m_t).ggf.iht,fits(m_t).ggf.ih);
   xlabel('time(ms)');
end
%
% estimated filter
% subplot(12,2,2:2:18);
% imagesc(fitB.ggf.k);
% if ~ispc
%    m_label = ...
%       cellfun(@(x)str2double(x),get(gca,'YTickLabel')) .* glm_sps_dt;
%    m_label = arrayfun(@(x)num2str(x),m_label,'UniformOutput',false);
%    set(gca,'YTickLabel', m_label);
% end
% title('ML estimate: bilinear filter');
% xlabel('space'); 
% colorbar;
% %
% subplot(12,2,22:2:24);
% plot(fitB.ggf.iht,fitB.ggf.ih);
% xlabel('time(ms)');
%
% save figures
savefig(m_h,['figfit-',date_stamp]);
%
% clean up
clear m_*;