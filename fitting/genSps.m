%% Generate Spike matrix (call after genStim.m)
%
%  @param: data_path_processed
%
%  @return: sps
%  
%  fields
%     dt    [1 x 1]
%     tmin
%     tmax
%     mat   [1 x CM] original spikes matrix
%
% [0] predefined data (set here for debugging)
run ../setpaths.m;
import helper.*;
import process.*;
if (~exist('data_path_processed', 'var'))   
   error('please run "genData" first');
end
fprintf('\nreading processed data from\n  ---> %s\n', data_path_processed);
if (~exist('stim', 'var'))
   error('please run "genStim" first');
end
if (~exist('glm_sps_dt', 'var'))
   error('please define "glm_sps_dt" first');
end
fprintf('using spike sampling rate %fHz\n\n',1/glm_sps_dt);
%
% [1] load all data
m_raw = load(data_path_processed);
% generate structure
sps = struct();
sps.dt   = glm_sps_dt; 
sps.tmin = sps.dt; % -> start from sps.dt for obtain correst up sampling
sps.tmax = stim.tmax + glm_time_gap;
sps.tbin = sps.tmin:sps.dt:stim.tbin(end);
sps.tlen = length(sps.tbin);
% generate matrix
sps.tsp  = [];
sps.mat  = zeros(sps.tlen,1);
sps.mat_coarse = zeros(stim.tlen,1);
m_offset = 0;
for m_v = data_perm
   % disp(m_v);
   % compute spike hist count
   sps.tsp = [sps.tsp; m_raw.data(m_v).sps + m_offset];
   m_histc = histc(m_raw.data(m_v).sps + m_offset, sps.tbin);
   if iscolumn(m_histc)
      sps.mat = sps.mat + m_histc;
   else
      sps.mat = sps.mat + m_histc';
   end
   % compute time offset
   m_offset = m_offset + m_raw.data(m_v).tmax;   
   % debug
   % plot(sps.mat);
   % pause;   
end
sps.mat_coarse = sum(reshape(sps.mat,[],stim.tlen),1)';
%
% [2] save data
save(data_path_processed, 'sps', '-append');
clear m_*;
%
% [3] debug plot
if flag_debug
   figure;
   plot(sps.tbin, sps.mat);
end