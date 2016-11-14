%% Pre-process data
run ../setpaths.m;
import helper.*;
import process.*;
% --- delete false data
% --- combine data according to different conditions
% [0] predefined variables
if (~exist('data_path_original', 'var'))
   error('please define "data_path_original" first');
end
fprintf('\nreading data from\n  ---> %s\n', data_path_original);

% [1] process output file name
[m_pathstr, m_name, m_ext] = fileparts(data_path_original);
data_path_processed = [pwd,'/', m_name, '_processed', m_ext];
fprintf('saving data to\n  ---> %s\n\n', data_path_processed);

% [2] load data
m_data   = load(data_path_original);

% [3] generate structs
m_nTrial = round(length(m_data.c_data));
m_data.c_data = m_data.c_data(1:m_nTrial); % shrunk data
fprintf('\ntotal number of trials %i\n', length(m_data.c_data));
fprintf('\nnumber of learning trials %i\n\n', m_nTrial);

% calculate valid trials
m_nValid = sum(arrayfun(@(x) (x.trialcancel==0), m_data.c_data));

% struct array attributions
data=struct([]);

% obtain data sttributes
m_v = 0;
for m_i = 1:m_nTrial
   if m_data.c_data(m_i).trialcancel ~=0; continue; end;
   m_v = m_v + 1;
   % assign attribute
   data(m_v).origin_idx = m_i;
   % ---------------------------------------------------------------------
   % >> spike times
   data(m_v).sps = ...
      m_data.c_data(m_i).spike.Time - m_data.c_data(m_i).time.BeginTime;
   % ----
   % >> other times
   % --> fixation target
   data(m_v).fixBeg = m_data.c_data(m_i).reltime.FpOn;   % fixation onset
   data(m_v).fixEnd = m_data.c_data(m_i).reltime.Gap1On; % fixation offset
   % --> visual target
   data(m_v).tarBeg = m_data.c_data(m_i).reltime.Rf1On;  % v-target onset
   data(m_v).tarEnd = m_data.c_data(m_i).reltime.Rf1Off; % v-target offset
   % --> saccade times
   data(m_v).sacBeg = ...
      m_data.c_data(m_i).saccade.lat + m_data.c_data(m_i).saccade.beg;
   data(m_v).sacEnd = ...
      data(m_v).sacBeg + m_data.c_data(m_i).saccade.dur + 500;   
   % ----
   % here we want to remove early points and late points
   % --> trial timing (unshifted times)
   % data(m_v).triBeg = m_data.c_data(m_i).reltime.BeginTime;
   % data(m_v).triEnd = m_data.c_data(m_i).reltime.EndTime;
   data(m_v).triBeg = data(m_v).fixBeg;
   data(m_v).triEnd = data(m_v).sacEnd;
   % ---- 
   % shift all times   
   data(m_v).tmin = 0;
   data(m_v).tmax = data(m_v).triEnd - data(m_v).triBeg;
   data(m_v).fixBeg = data(m_v).fixBeg - data(m_v).triBeg;
   data(m_v).fixEnd = data(m_v).fixEnd - data(m_v).triBeg;
   data(m_v).tarBeg = data(m_v).tarBeg - data(m_v).triBeg;
   data(m_v).tarEnd = data(m_v).tarEnd - data(m_v).triBeg;
   data(m_v).sacBeg = data(m_v).sacBeg - data(m_v).triBeg;
   data(m_v).sacEnd = data(m_v).sacEnd - data(m_v).triBeg;
   data(m_v).sps = data(m_v).sps - data(m_v).triBeg;
   % shunk spike train
   data(m_v).sps = data(m_v).sps(data(m_v).sps <=  data(m_v).tmax);
   if isempty(data(m_v).sps)
      data(m_v).sps = -1; % assign a dummy value instead of empty array
   end
   
   % ---------------------------------------------------------------------
   % >> target-position
   m_tarLoc = m_data.c_data(m_i).Jump1Loc; % target location
   data(m_v).tarLoc = m_tarLoc;
   data(m_v).tarDir = ang2dir(cart2pol(m_tarLoc(1), m_tarLoc(2)));   
   % ----
   % >> eye-position
   m_eyet = floor(data(m_v).triBeg)+1:floor(data(m_v).triEnd)+1;
   m_eyei = m_data.c_data(m_i).saccade.ei;
   m_eyex = m_data.c_data(m_i).EyePos.x - m_eyei(1);
   m_eyey = m_data.c_data(m_i).EyePos.y - m_eyei(2);
   data(m_v).eyeamp = sqrt(max(m_eyex(m_eyet) .^2 + m_eyey(m_eyet) .^2));
   data(m_v).eyepos = [m_eyex(m_eyet),m_eyey(m_eyet)];
end

% filter data according to different requirements
data_sort = struct();
data_sort.dirIdx = cell(8,1);
for m_i =1:8
   data_sort.dirIdx{m_i} = arrayfun(@(x) x.tarDir == (m_i-1), data);
end

switch glm_fit_type  
   case 'seperate_direction'
      % delete useless data
      data = data(data_sort.dirIdx{glm_seperate_direction});
      % compute permutation
      data_perm = randperm(sum(data_sort.dirIdx{glm_seperate_direction}));
   otherwise
      % data permutation
      data_perm = randperm(m_nValid);
end

glm_empty_flag = false;
if isempty(data_perm)
   glm_empty_flag = true;
end

% [4] save data
save(data_path_processed,...
   'data','data_sort','data_perm','data_path_original');

% [5] clean up
clear m_*;