%% Kernel Verification (bilinear method)
%
% set all paths
run ../setpaths.m;
import helper.*;
import process.*;
if ~exist('GLMspiketools_path','var') || ...
      sum(~cellfun(@haspath, GLMspiketools_path)) == 0;
   cd ../GLMspiketools;
   setpaths;
   cd ../fitting;
end
% set all variables
if ~exist('date_stamp','var')
   date_stamp = datestr(datetime('now'),'mmmm-ddHHMM');
end
if ~exist('stim','var')
   error('please run "genStim" first');
end
if ~exist('sps','var')
   error('please run "genSps" first');
end
if ~exist('fits','var')
   error('please run "computFitting" first');
end

%% simulations
%
% --- histogram for original data
m_wfun = 'Gaussian_200';
m_t_hist = sps.tbin;
m_o_hist = windowing(sps.mat, m_wfun);

% --- record windowing func
diary(['out-',date_stamp,'.txt']);
fprintf('\nUsing windowing function %s\n', m_wfun);
diary off;

% --- Insert into glm structure (created with default history filter)
% --- Create GLM structure with default params
ggsim = makeSimStruct_GLM(glm_nkt,stim.dt,sps.dt);

% --- new figure
m_h = figure;
m_w = length(fits);
setFigureSize([800 700]);
% draw stimuli
subplot(4 + m_w * 4, 1, 1 : 3);
imagesc(stim.mat');
if ~ispc   
   m_tick = get(gca,'XTick');   
   set(gca,'XTick', m_tick(2:2:end));
   m_label = arrayfun(@(x) num2str(x, '%1.1e'),...
      get(gca,'XTick') .* glm_stim_dt,'UniformOutput', false);
   set(gca,'XTickLabel', m_label);   
end
ylabel('spatial');
xlabel('time (ms)');
title('stimuli + hist plot');

% comaprison
m_dsample_rate = round(length(m_t_hist)/1000);
m_t_hist_draw  = downsample(m_t_hist,m_dsample_rate);
m_o_hist_draw  = downsample(m_o_hist,m_dsample_rate);
sims.t_hist = m_t_hist_draw;
sims.o_hist = m_o_hist_draw;

% --- Generate some data for Traditional method
sims.gen = struct([]);
m_subplot_mark = 5;
for m_t = 1:length(glm_models)
   % simulation
   ggsim.k  = fits(m_t).ggf.k;
   ggsim.dc = fits(m_t).ggf.dc;
   for m_i = 1:10
      [~,m_sps,~,~] = simGLM(ggsim,stim.mat);
      if m_i == 1
         sims.gen(m_t).gen_hist = windowing(m_sps, m_wfun);
      else
         sims.gen(m_t).gen_hist = sims.gen(m_t).gen_hist + ...
            (windowing(m_sps, m_wfun) - sims.gen(m_t).gen_hist) ./ m_i;
      end
   end   
   sims.gen(m_t).coef = corrcoef(sims.gen(m_t).gen_hist,m_o_hist);
   
   % print
   diary(['out-',date_stamp,'.txt']);   
   fprintf('r with traditional %f\n',sims.gen(m_t).coef(1,2)); 
   diary off;
   
   % downsample
   m_g_hist_draw = downsample(sims.gen(m_t).gen_hist,m_dsample_rate);
   sims.gen(m_t).g_hist = m_g_hist_draw;   
   
   % plot   
   subplot(4 + m_w * 4, 1, m_subplot_mark : m_subplot_mark+2);   
   m_subplot_mark = m_subplot_mark + 4;
   plot(m_t_hist_draw, m_o_hist_draw, m_t_hist_draw, m_g_hist_draw);
   ylabel('number of spikes');
   xlim([m_t_hist_draw(1), m_t_hist_draw(end)]);
end
% setup common x label
xlabel('time (ms)');

% setup legend
legend({'observed spike count',glm_models{:}});

% save figures
savefig(m_h, ['figver-',date_stamp]);

% m_gt_hist_draw = downsample(simT.gen_hist,m_downsample_rate);
% m_gb_hist_draw = downsample(simB.gen_hist,m_downsample_rate);
%
% subplot(9,1,4:6);
% subplot(9,1,4:9);
%
% plot results
%
% plot generated data
%
% [simT.tsp,simT.sps,simT.Itot,simT.Istm] = simGLM(ggsim,stim.mat);
% simT.gen_hist = histc(simT.tsp,m_t_hist); % generated data
%
% Generate some data for Bilinear method
% ggsim.k  = fitB.ggf.k;
% ggsim.dc = fitB.ggf.dc;
% for m_i = 1:10
%    [~,m_sps,~,~] = simGLM(ggsim,stim.mat);
%    if m_i == 1
%       simB.gen_hist = windowing(m_sps, m_window_fun);
%    else
%       simB.gen_hist = simB.gen_hist + ...
%          (windowing(m_sps, m_window_fun) - simB.gen_hist) ./ m_i;
%    end
% end
% [simB.tsp,simB.sps,simB.Itot,simB.Istm] = simGLM(ggsim,stim.mat);
% simB.gen_hist = histc(simB.tsp,m_t_hist); % generated data
%
% correlation coefficient of traditional % bilinear
% simT.coef = corrcoef(fits(m_t).gen_hist,m_o_hist);
% simB.coef = corrcoef(simB.gen_hist,m_o_hist);
% simT.coef = corrcoef(simT.sps,sps.mat);
% simB.coef = corrcoef(simB.sps,sps.mat);
%
% print
% diary(['out-',date_stamp,'.txt']);
% fprintf('\nUsing windowing function %s\n', m_window_fun);
% fprintf('r with traditional %f\n',simT.coef(1,2));
% fprintf('r with bilinear    %f\n',simB.coef(1,2));
% diary off;

%% clean up
clear m_*;