% to fit example data with glm
%% set pathes and import modules
clear;
cd ../GLMspiketools;
setpaths;
cd ../fitting;
addpath('../');
import helper.*;

%% produce data inputs
load ../data/example.mat;
%
% set trial index
tidx = 5;
%
% @var: dtStim 
% --- Bin size for stimulus (in seconds).
% --- smaller than 1.0 usually
dtStim = 10.0;
%
% @var: dtSp
% --- Bin size for simulating model & computing likelihood 
% --- must evenly divide dtStim
dtSps = dtStim / 10;  
%
% @var: nkt --- size of temporal filter
nkt = 500 / dtStim;
% @var: nkx 
% --- size of spatial filter
% --- 1) visual target positions x8
% --- 2) fixation light          x1
nkx = 9; 
%
% @var: Stim [T x M]  
% --- stimuli matrix [time, space]
% --- [1] get event times
tmax = c_data(tidx).reltime.EndTime;
tmin = c_data(tidx).reltime.BeginTime;
fixBeg = c_data(tidx).reltime.FpOn;   % fixation onset
fixEnd = c_data(tidx).reltime.Gap1On;  % fixation offset
tarBeg = c_data(tidx).reltime.Rf1On;  % visual target onset
tarEnd = c_data(tidx).reltime.Rf1Off; % visual target offset

% --- [2] allocate empty stimuli matrix
tlenStim = length(tmin:dtStim:tmax);
xlenStim = nkx;
Stim = zeros(tlenStim, xlenStim);
% --- assign data
loc = c_data(tidx).Jump1Loc;
dir = ang2dir(cart2pol(loc(1), loc(2)));
for t = tmin:dtStim:tmax
   i_hist = t / dtStim + 1;
   if t >= fixBeg && t <= fixEnd
      Stim(i_hist,9) = 1;
   end
   if t >= tarBeg && t <= tarEnd
      Stim(i_hist,dir+1) = 1;
   end
end
% --- since p(x) must be symmetry, probably we need to shift the matrix
% --- by a constant offset b = N1/(N1+N0) where N1 is the number of ones
% --- in the stimuli matrix, N0 is the number of zeros in the matrix
% N1 = sum(sum(Stim));
% N0 = size(Stim, 1) * size(Stim, 2);
% Stim = Stim - N1 / (N1 + N0);
% debug draw
figure;
imagesc(Stim');
xlabel('time');
ylabel('space');

%% prepare spike vector
% @var: spikes [T, 1]
% --- spikes bin size / size of stimulus matrix = up sampling rate
tlenSps = tlenStim * (dtStim / dtSps);
tbinSps = tmin:(tmax-tmin)/(tlenSps-1):tmax;
sps_data = c_data(tidx).spike.Time - c_data(tidx).time.BeginTime;
sps_ori  = histc(sps_data, tbinSps);
% debug draw
% plot(tmin:dtStim:tmax, spikes);

%% Fitting according to demo2
% --- bin spikes in bins the size of stimulus
sps_coarse = sum(reshape(sps_ori,[],tlenStim),1)';
% --- [1] compute STA
sta = simpleSTC(Stim,sps_coarse,nkt); % Compute STA
sta = reshape(sta,nkt,[]); % reshape it to match dimensions of true filter
exptmask= [];  % Not currently supported!

% --- [2] Initialize params for fitting, including bases 
nkbasis = 8; % number of basis vectors for representing k
nhbasis = 8; % number of basis vectors for representing h
hpeakFinal = 500; % time of peak of last basis vector for h
k_rank = 1; % Number of column/row vector pairs to use

% --- [3] Fit data
% --- a) Traditional method
gg0f = makeFittingStruct_GLM(dtStim,dtSps,nkt,nkbasis, ...
   sta,nhbasis,hpeakFinal);
gg0f.sps  = sps_ori;   % Insert binned spike train into fitting struct
gg0f.mask = exptmask; % insert mask (optional)
gg0f.ihw  = randn(size(gg0f.ihw))*1; % initialize spike-history weights randomly
% --- Compute conditional intensity at initial parameters 
[negloglival0,rr] = neglogli_GLM(gg0f,Stim);
fprintf('Initial negative log-likelihood: %.5f\n', negloglival0);
% --- Do ML estimation of model params (requires optimization toolbox)
opts = {'display', 'iter', 'maxiter', 100};
[gg1, negloglival1a] = MLfit_GLM(gg0f,Stim,opts);

% --- b) Bilinear stim filter method
gg0b = makeFittingStruct_GLMbi(k_rank,dtStim,dtSps,nkt,nkbasis, ...
   sta,nhbasis,hpeakFinal);
gg0b.sps  = sps_ori;
gg0b.mask = exptmask;
% --- Compute conditional intensity at initial parameters 
logli0b = neglogli_GLM(gg0b,Stim); % Compute logli of initial params
fprintf('Initial value of negative log-li (GLMbi): %.3f\n', logli0b);
% --- Do ML estimation of model params
opts = {'display', 'iter'};
[gg2, negloglival2] = MLfit_GLMbi(gg0b,Stim,opts); % do ML (requires optimization toolbox)

%% Plot results
figure;
% estimated filter
subplot(121); 
imagesc(gg1.k); title('ML estimate: full filter'); 
xlabel('space'); 
ylabel('time');
colorbar;
% estimated filter
subplot(122); 
imagesc(gg2.k); title('ML estimate: bilinear filter');
xlabel('space'); 
colorbar;

figure;
subplot(211);
plot(gg1.ih); title('H-kernel: full filter'); 
subplot(212);
plot(gg2.ih); title('H-kernel: full filter'); 
%% varify kernel
% --- Insert into glm structure (created with default history filter)
% --- Create GLM structure with default params
ggsim = makeSimStruct_GLM(nkt,dtStim,dtSps);
ggsim.k  = gg2.k; % Insert into simulation struct
ggsim.dc = gg2.dc;

%% Generate some data
[tsp,sps_gen,Itot,Istm] = simGLM(ggsim,Stim);  % run model
nsp = length(tsp);
% --- Make plot of first 0.5 seconds of data
ttstim = tmin:dtStim:tmax;
iistim = 1:length(ttstim);
ttspk  = tmin:dtSps:tmax; 
iispk  = 1:length(ttspk);
% --- plot generated data
figure;
subplot(411);
imagesc([tmin tmax], [1 nkx], Stim(iistim,:)'); 
title('stimulus'); ylabel('pixel');
subplot(412);
semilogy(ttspk,exp(sps_ori(iispk)),ttspk, exp(sps_gen(iispk)));
ylabel('spike rate (sp/s)');
title('conditional intensity (and spikes)');
subplot(413);
plot(ttspk,exp(Itot(iispk)));
%--- comaprison
subplot(414);
up_rate_hist = 50;
t_hist = 1:50:tbinSps(end);
o_hist = histc(find(sps_ori>=1),t_hist); % original data
g_hist = histc(find(sps_gen>=1),t_hist); % generated data
plot(t_hist, o_hist, t_hist, g_hist);