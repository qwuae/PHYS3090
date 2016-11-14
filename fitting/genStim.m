%% Generate Stimuli matrix (call after genData.m)
%
%  @param: data_path_processed
%  @param: stim_dt
%  @param: stim_xlen
%
%  @return: stim
%
%  fields
%     dt    [1 x 1] time bin size
%     tmin  [1 x 1] temporal starting point
%     tmax  [1 x 1] temporal ending point
%     tlen  [1 x 1] temporal mesh length, which equals to T
%     xlen  [1 x 1] spatial mesh length
%     tbin  [1 x T] temporal mesh
%        ---> T length of time mesh
%     mat   [T x CM] stimuli matrix
%        ---> T length of time mesh
%        ---> C: number of different conditions
%        ---> M: number of stimuli type
%
% [0] predefined data (set here for debugging)
run ../setpaths.m;
import helper.*;
import process.*;
if (~exist('glm_time_gap', 'var'))
   error('please define "glm_time_gap" first');
end
if (~exist('data_path_processed', 'var'))
   error('please run "genData" first');
end
fprintf('\nreading processed data from\n  ---> %s\n',data_path_processed);
if (~exist('glm_stim_dt', 'var'))
   error('please define "glm_stim_dt" first');
end
fprintf('using stimuli sampling rate %fHz\n',1/glm_stim_dt);
if (~exist('glm_stim_xlen', 'var'))
   error('please define "glm_stim_xlen" first');
end
fprintf('using default stimuli spacial length %f\n\n',glm_stim_xlen);
%
% [1] load all data
m_raw = load(data_path_processed);
% generate struct
stim = struct();
stim.dt   = glm_stim_dt;
stim.tmin = stim.dt; % -> start from sps.dt for obtain correst up sampling
stim.tmax = sum(arrayfun(@(x) x.tmax, m_raw.data))+ glm_time_gap;
stim.tbin = stim.tmin:stim.dt:(stim.tmax+stim.dt); % -> here adding one
stim.tlen = length(stim.tbin);                     % additional bin in
stim.xlen = glm_stim_xlen;                         % order to contain all
% generate matrix                                  % data points
stim.mat  = zeros(stim.tlen, stim.xlen);
% initial values for looping
m_c = 1;
m_v = data_perm(1);
m_t = 0;
m_offset = 0;
for m_i = 1:stim.tlen
   % shift current time
   m_t = stim.tbin(m_i) - m_offset;
   % check current trial index
   if m_t >= m_raw.data(m_v).tmax
      % disp(m_v);
      m_offset = m_offset + m_raw.data(m_v).tmax;
      m_c = m_c + 1;
      % -> since the time mesh is larger than real data, boundary check is
      % important here
      if m_c > numel(m_raw.data)
         break;
      end
      m_v = data_perm(m_c);
      m_t = stim.tbin(m_i) - m_offset;
   end
   % assign matrix value
   m_eyepos = m_raw.data(m_v).eyepos(1+floor(m_t),:);
   [m_theta,m_rho] = cart2pol(m_eyepos(1),m_eyepos(2));
   % different stim matrix
   
   switch glm_fit_type
      case 'seperate_direction'                  
         if m_t >= m_raw.data(m_v).fixBeg && m_t <= m_raw.data(m_v).fixEnd
            stim.mat(m_i,2) = 1;
         end
         if m_t >= m_raw.data(m_v).tarBeg && m_t <= m_raw.data(m_v).tarEnd
            m_dir = m_raw.data(m_v).tarDir;
            stim.mat(m_i,1) = 1;
         end
         stim.mat(m_i,3:4) = [m_theta/2/pi, m_rho/m_raw.data(m_v).eyeamp];
      case 'conbine_fixation' 
         % case to combine fixation singal         
         if m_t >= m_raw.data(m_v).tarBeg && m_t <= m_raw.data(m_v).fixEnd
            m_dir = m_raw.data(m_v).tarDir;
            stim.mat(m_i,m_dir+1) = 1;
         end
         stim.mat(m_i,9:10) = [m_theta/2/pi, m_rho/m_raw.data(m_v).eyeamp];
      case 'no_eye_angle'         
         if m_t >= m_raw.data(m_v).fixBeg && m_t <= m_raw.data(m_v).fixEnd
            stim.mat(m_i,9) = 1;
         end
         if m_t >= m_raw.data(m_v).tarBeg && m_t <= m_raw.data(m_v).tarEnd
            m_dir = m_raw.data(m_v).tarDir;
            stim.mat(m_i,m_dir+1) = 1;
         end
         stim.mat(m_i,10) = m_rho/m_raw.data(m_v).eyeamp;
      otherwise         
         if m_t >= m_raw.data(m_v).fixBeg && m_t <= m_raw.data(m_v).fixEnd
            stim.mat(m_i,9) = 1;
         end
         if m_t >= m_raw.data(m_v).tarBeg && m_t <= m_raw.data(m_v).tarEnd
            m_dir = m_raw.data(m_v).tarDir;
            stim.mat(m_i,m_dir+1) = 1;
         end
         stim.mat(m_i,10:11) = ...
            [m_theta/2/pi, m_rho/m_raw.data(m_v).eyeamp];
   end
end
%
% [2] save data
save(data_path_processed, 'stim', '-append');
clear m_*;
%
% [3] debug plot
if flag_debug
   figure;
   imagesc(stim.mat);
end