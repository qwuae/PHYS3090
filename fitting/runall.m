%% run GLM fitting (the whole chain)
%
% get some descriotions for this running process
clear;
glm_comment_str = input('Describe changes you made please:\n','s');

%% define parameters
% ** flags
flag_debug = false;
% ** parameters
% --> time_gap : empty time distance between adjacent trials
% --> stim_dt  : temproal bin size for stimuli matrix
% --> stim_xlen: spatial  bin size for stimuli matrix
% --> stim_dt  : temproal bin size for spike matrix
% --> nkt      : temporal size for K kernel
% --> nkx      : spatial  size for K kernel
% --> k_nbasis : number of basis for K kernel
% --> k_rank   : number of column/row vector pairs to use for K kernel
% --> h_nbasis : number of basis for H kernel
% --> h_ftpeak : last basis time peak for H kernel
%
% the case that we want to seperate data accroding to saccade direction

glm_fit_type = 'seperate_direction';
glm_models = {'nobasis'};
switch glm_fit_type
   case 'seperate_direction'      
      glm_stim_xlen = 4;
   case 'conbine_fixation'      
      glm_stim_xlen = 10;
   case 'no_eye_angle'
      glm_stim_xlen = 10;
   otherwise
      glm_stim_xlen = 11;
end

glm_time_gap  = 15;
glm_stim_dt   = 4.0;
glm_sps_dt    = 0.05;
glm_nkt = glm_time_gap / glm_sps_dt;
glm_nkx = glm_stim_xlen;
glm_k_nbasis = 75;
glm_k_rank   = 1;
glm_h_nbasis = 50;
glm_h_ftpeak = 2;

%% run calculations

% data location
% --- selections
% /P/
% 20110210_memory003G.mat  20110920_memory002.mat  20110923_memory004.mat
% 20110929_memory003G.mat  20110929_memory013G.mat 20111005_memory005G.mat
% 20111007_memory003.mat   20111007_memory011G.mat 20111011_memory005.mat
% 20111012_memory008G.mat  20111014_memory003.mat  20111018_memory001G.mat
% 20111018_memory005G.mat  20111024_memory003.mat  20120128_memory005G.mat
% 20120131_memory005G.mat  20120206_memory012G.mat 20120208_memory020.mat
% 20120214_memory006.mat   20120311_memory009.mat  20120315_memory005G.mat
% 20120315_memory009.mat   20120328_memory009.mat  20120329_memory002G.mat

%    '20110210_memory003G.mat', '20110920_memory002.mat',...
%    '20110923_memory004.mat',  '20110929_memory003G.mat',...
%    '20110929_memory013G.mat', '20111005_memory005G.mat',...
%    '20111007_memory003.mat',  '20111007_memory011G.mat',...
%    '20111011_memory005.mat',  '20111012_memory008G.mat',...
%    '20111014_memory003.mat',  '20111018_memory001G.mat',...
%    '20111018_memory005G.mat', '20111024_memory003.mat',...
%    '20120128_memory005G.mat', '20120131_memory005G.mat',...
%    '20120206_memory012G.mat', '20120208_memory020.mat',...
%    '20120214_memory006.mat',  '20120311_memory009.mat',...
%    '20120315_memory005G.mat', '20120315_memory009.mat',...
%    '20120328_memory009.mat',  '20120329_memory002G.mat' 

warning('off','all');
data_p = { ...   
   '20111014_memory003.mat',  '20111018_memory001G.mat',...
   '20111018_memory005G.mat', '20111024_memory003.mat',...
   '20120128_memory005G.mat', '20120131_memory005G.mat',...
   };
%   ...
%   '20110210_memory003G.mat', '20110920_memory002.mat',...
%   '20110923_memory004.mat',  '20110929_memory003G.mat',...
%   '20110929_memory013G.mat', '20111005_memory005G.mat',...
%   '20111007_memory003.mat',  '20111007_memory011G.mat',...
%   '20111011_memory005.mat',  '20111012_memory008G.mat',...
% ...
%   '20120206_memory012G.mat', '20120208_memory020.mat',...
%   '20120214_memory006.mat',  '20120311_memory009.mat',...
%   '20120315_memory005G.mat', '20120315_memory009.mat',...
%   '20120328_memory009.mat',  '20120329_memory002G.mat' };

% -- good example
% m_data_name  = '20120206_memory012G.mat';
% -- bad example
% m_data_name  = '20120329_memory002G.mat';

switch glm_fit_type
   case 'seperate_direction'
      mm_d = 0;   
end

% get data path
mm_i = 0;
while true
   
   % get data name
   switch glm_fit_type
      case 'seperate_direction'
         if mod(mm_d,8) == 0
            % run script
            if mm_i ~= 0; system(['bash sep-dir.sh ', mm_data_name]); end;
            mm_i = mm_i + 1;
         end
         mm_d = mod(mm_d,8) + 1;
         glm_seperate_direction = mm_d;         
      otherwise
         mm_i = mm_i + 1;
   end

   % break loop
   if mm_i > length(data_p); break; end;
   mm_data_name = data_p{mm_i};
   
   % if strcmp(m_data_name, '20120206_memory012G.mat'); continue; end;   
   % if ~strcmp(m_data_name, '20120328_memory009.mat'); continue; end;
   
   % get data full path
   data_path_original = ['/home/qiwu/work/neuro/data/P/', mm_data_name];
   % get current time
   date_stamp = datestr(datetime('now'),'mmmm-ddHHMM');
   % print parameters
   diary(['out-',date_stamp,'.txt']);   
   switch glm_fit_type
      case 'seperate_direction'
         fprintf(['working on data ',mm_data_name]);
         fprintf(['on direction ',num2str(glm_seperate_direction),'\n']);
      otherwise         
         fprintf(['working on data ',mm_data_name,'\n']);
   end
   fprintf(['\nComment: ',glm_comment_str,'\n\n']);
   fprintf('original data path: %s\n',data_path_original);
   fprintf('stimuli dt    : %f\n',glm_stim_dt);
   fprintf('stimuli x-size: %i\n',glm_stim_xlen);
   fprintf('spike   dt    : %f\n',glm_sps_dt);
   fprintf('kernel kx-size: %i\n',glm_nkx);
   fprintf('kernel kt-size: %i\n',glm_nkt);
   fprintf('k basis number: %i\n',glm_k_nbasis);
   fprintf('k rank        : %f\n',glm_k_rank);
   fprintf('h basis number: %i\n',glm_h_nbasis);
   fprintf('h final t-peak: %f\n',glm_h_ftpeak);
   fprintf('\n');
   diary off;
   
   % run processes
   glm_empty_flag = false;
   run ../setpaths.m;
   genData;
   save(['var-',date_stamp]);
   if glm_empty_flag
      fprintf('r with traditional N/A\n');
   else
      genStim;
      save(['var-',date_stamp]);
      genSps;
      save(['var-',date_stamp]);
      computeFitting;
      save(['var-',date_stamp]);
      plotFitting;
      save(['var-',date_stamp]);
      verifyFitting;
      save(['var-',date_stamp]);
   end
   close all;
end
