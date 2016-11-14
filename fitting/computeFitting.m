%% generate fitting structure (called after all generations)
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
% pre-defined variables
if ~exist('glm_sps_dt','var')
   error('please define "glm_sps_dt" first');
end
if ~exist('glm_stim_xlen','var')
   error('please define "glm_stim_xlen" first');
end
if ~exist('stim','var')
   error('please run "genStim" first');
end
if ~exist('sps','var')
   error('please run "genSps" first');
end
if ~exist('glm_nkt','var')
   error('please define "glm_nkt" first');
end
if ~exist('glm_nkx','var')
   error('please define "glm_nkx" first');
end
if ~exist('glm_k_nbasis','var')
   error('please define "k_nbasis" first');
end
if ~exist('glm_k_rank','var')
   error('please define "k_rank" first');
end
if ~exist('glm_h_nbasis','var')
   error('please define "h_nbasis" first');
end
if ~exist('glm_h_ftpeak','var')
   error('please define "h_ftpeak" first');
end
% start recording diary
diary(['out-',date_stamp,'.txt']);
%% [1] compute STA as the initial guess for K kernel
m_sta = simpleSTC(stim.mat,sps.mat_coarse,glm_nkt); 
m_sta = reshape(m_sta,glm_nkt,[]); % reshape to match dimensions of true filter
m_exptmask= [];  % Not currently supported!

%% [2] traditional method
% common options
m_options = {'display', 'iter', ...
             'maxiter', 10000,...
             'TolFun' , 1e-6,...
             'TolX'   , 1e-6};

% setup initial guess          
m_k0 = m_sta;
% struct for storing fitting results
fits = struct([]);
for m_tid = 1:length(glm_models)
   m_type = glm_models{m_tid};
   m_done = false;
   fprintf(['Fitting method:',m_type,'\n']);
   while ~m_done
      % check cases for special arguments
      if strcmp(m_type, 'bilinear')
         m_ggi = GLMmakeFitStruct('bilinear',...
            stim.dt,sps.dt,...
            glm_nkt,glm_k_nbasis,m_k0,... % here use results of linear 
            glm_h_nbasis,glm_h_ftpeak,...    % fitting to improve
            glm_k_rank);
      else
         m_ggi = GLMmakeFitStruct(m_type,...
            stim.dt,sps.dt,...
            glm_nkt,glm_k_nbasis,m_k0,...
            glm_h_nbasis,glm_h_ftpeak);
      end
      
      % Insert binned spike train into fitting struct
      m_ggi.sps  = sps.mat;  
      % insert mask (optional)
      m_ggi.mask = m_exptmask; 
      % init spike-history weights randomly
      m_ggi.ihw  = randn(size(m_ggi.ihw))*0.5; 
      
      % compute conditional intensity at initial parameters
      [m_neglogli0, ~] = neglogli_GLM(m_ggi,stim.mat);      
      fprintf('Initial negative log-likelihood: %.5e\n', m_neglogli0);
      
      % check if objective function value is valid      
      if (m_neglogli0 > 1e180)
         % restore initial guess back to STA if f(x) is too large
         m_k0 = m_sta;
         fprintf('f is too large, change init guess\n');
         continue;
      end
      
      % do ML estimation of model params
      [m_ggf, m_negloglif] = GLMfitML(m_ggi,stim.mat,m_options);
      
      % save initial guess
      fprintf('Fitting succeed! Updating initial guess\n');
      m_k0 = m_ggf.k;
      m_done = true;
      
      % build stucture
      fits(m_tid).type = m_type;
      fits(m_tid).ggi = m_ggi;
      fits(m_tid).negloglii = m_neglogli0;
      fits(m_tid).ggf = m_ggf;
      fits(m_tid).negloglif = m_negloglif;
   end
end

% %% [3] bilinear stimli filter method
% m_ggi = GLMmakeFitStruct('bilinear',...
%    stim.dt,sps.dt,...
%    glm_nkt,glm_k_nbasis,m_ggf.k,...  % here use results of linear fitting 
%    glm_h_nbasis,glm_h_ftpeak,...   % to improve
%    glm_k_rank);
% m_ggi.sps  = sps.mat;
% m_ggi.mask = m_exptmask;
% %
% % compute conditional intensity at initial parameters 
% [m_neglogli0, m_rr] = neglogli_GLM(m_ggi,stim.mat);
% fprintf('Initial value of negative log-li (GLMbi): %.5e\n', m_neglogli0);
% if (m_neglogli0 > 1e180)
%    m_ggi = GLMmakeFitStruct('bilinear',...
%       stim.dt,sps.dt,...
%       glm_nkt,glm_k_nbasis,m_sta,...% here use results of linear fitting
%       glm_h_nbasis,glm_h_ftpeak,...   % to improve
%       glm_k_rank);
%    m_ggi.sps  = sps.mat;
%    m_ggi.mask = m_exptmask;
%    [m_neglogli0, m_rr] = neglogli_GLM(m_ggi,stim.mat);
%    fprintf('recalculate Initial value (GLMbi): %.5e\n', m_neglogli0);
% end
% %
% % do ML estimation of model params
% [m_ggf, m_negloglif] = GLMfitML(m_ggi,stim.mat,m_options);
% %
% % build stucture
% fitB = struct('ggi',m_ggi, 'neglogli0',m_neglogli0, 'rr',m_rr,...
%               'ggf',m_ggf, 'negloglif',m_negloglif);

%% clean up
clear m_*;
diary off;