%% Calculate Average Firing Rate 
% Input Arguments
% * File: Data File Name
% * Window: Windowing Function File Name
% * Alignment:
%   1) FlashOnset
%   2) FlashOff
%   3) FixOff 
%   4) SaccadeOn 
%   5) SaccadeOff
% * Dir: Display Selected Directions Only
% Ourput Arguments (All Row Vectors)
% * aMesh: Average Firing Rate
% * tMesh: Time Axis of the Average Firing Rate
% * tPnt: Selected Time Points (Averaged value)
%   1) Flash Onset
%   2) Flash Offset
%   3) Fixtation Offset
%   4) Saccade Onset
%   5) Saccade Offset
% Function Definition
function [aMesh, tMesh, tPnt] = averageFiringRate(varargin)
import helper.*;
import process.*;
% Default variables
fNam = 'example.mat';  % data file name
wFun = 'Gaussian_50';  % windowing function
aPnt = 'SaccadeOnset'; % alignment point
eDir = [0 1 2 3 4 5 6 7]; % eye direction
% Only want 3 optional inputs at most
nargs = length(varargin);
% Place optional args in memorable variable names
iarg = 1;
while (iarg <= nargs);
    switch varargin{iarg}
        case { 'File','file' }
            fNam = varargin{iarg + 1}; 
            iarg = iarg + 2;
        case { 'Window','window','Win','win' }
            wFun = varargin{iarg + 1}; 
            iarg = iarg + 2;
        case { 'Alignment','alignment','Align','align' }
            aPnt = varargin{iarg + 1}; 
            iarg = iarg + 2;
        case { 'Direction','direction','dir','Dir' }
            eDir = mod(varargin{iarg + 1}, 8);
            iarg = iarg + 2;
        otherwise
            warning('Invalid Field Name');
    end
end
% [1] load data
load(['window/',wFun,'.mat']);
load(['data/'  ,fNam]);
TNum = length(c_data);
% [3] calculate time range and alignment
alignment = zeros(TNum, 1);
timeStep = 0.1;
maxT = 0; 
minT = 0;
for i = 1:TNum
    % check whether trial is valid
    if c_data(i).trialcancel; continue; end;
    % [3.1] alignment
    bTrial = c_data(i).time.BeginTime; % trial begin time
    eTrial = c_data(i).time.EndTime;   % trial end time
    if strcmp(aPnt, 'FixOff') % Fixtation off
        alignment(i) = c_data(i).saccade.beg;    
    elseif strcmp(aPnt, 'SaccadeOnset')
        alignment(i) = c_data(i).saccade.lat + c_data(i).saccade.beg;
    elseif strcmp(aPnt, 'SaccadeOffset')
        alignment(i) = c_data(i).saccade.lat + ...
                       c_data(i).saccade.beg + ...
                       c_data(i).saccade.dur;
    elseif strcmp(aPnt, 'FlashOnset')  % saccade target on time
        alignment(i) = c_data(i).time.Rf1On  - bTrial;
    elseif strcmp(aPnt, 'FlashOffset') % saccade target off time
        alignment(i) = c_data(i).time.Rf1Off - bTrial;
    else
        warning('Undefined Alignment');
    end
    % [3.2] store time points
    maxT = max(eTrial - bTrial - alignment(i), maxT);
    minT = min(-alignment(i), minT);
end
tMesh = minT:timeStep:maxT; % time mesh
% [4] compute plots
numValid = 0;
aMesh = zeros(1,length(tMesh)); % average mesh
FlashB = zeros(TNum, 1);
FlashE = zeros(TNum, 1);
SacBeg = zeros(TNum, 1);
SacEnd = zeros(TNum, 1);
FixOff = zeros(TNum, 1);
rho = zeros(2, 8);
for i = 1:TNum
    % check whether trial is valid
    if c_data(i).trialcancel; continue; end;
    bTrial = c_data(i).time.BeginTime;
    % [4.1] eye direction
    %{
    eyeTime = c_data(i).EyePos.reltime; % time
    eyeXpos = c_data(i).EyePos.x; % x coordinate
    eyeYpos = c_data(i).EyePos.y; % y coordinate
    ind = eyeTime > 40 + alignment(i) & eyeTime < 60 + alignment(i);
    ang = cart2pol(mean(eyeXpos(ind)), mean(eyeYpos(ind)));
    %}
    eLoc = c_data(i).saccade.ef - c_data(i).saccade.ei;
    ang  = cart2pol(eLoc(1), eLoc(2));
    % [4.2] test eye direction
    if (sum(ismember(ang2dir(ang), eDir)) == 0); continue; end;
    % plot firing rate
    % [4.3] windowing
    numValid = numValid + 1;
    sTime = c_data(i).spike.Time - bTrial;      % spike list
    sMesh = histc(sTime' - alignment(i), tMesh); % spike mesh
    wMesh = conv(sMesh, wf, 'same'); % windowing mesh
    % [4.4] process method
    aMesh = aMesh + wMesh;
    % plot raster point
    % [4.5] plot flash points
    FlashB(numValid) = c_data(i).time.Rf1On  - bTrial - alignment(i);
    FlashE(numValid) = c_data(i).time.Rf1Off - bTrial - alignment(i);
    FixOff(numValid) = c_data(i).saccade.beg - alignment(i);
    SacBeg(numValid) = c_data(i).saccade.lat + ...
                       c_data(i).saccade.beg - ...
                       alignment(i);
    SacEnd(numValid) = c_data(i).saccade.lat + ...
                       c_data(i).saccade.beg + ...
                       c_data(i).saccade.dur - ...
                       alignment(i);
    % polar plot
    rho(1,ang2dir(ang)+1) = rho(1,ang2dir(ang)+1) + mean(wMesh);
    rho(2,ang2dir(ang)+1) = rho(2,ang2dir(ang)+1) + 1;
end
% a hack: make numValid >= 1
% numValid = max(1, numValid);
% shrink data
FlashB = FlashB(1:numValid);
FlashE = FlashE(1:numValid);
FixOff = FixOff(1:numValid);
SacBeg = SacBeg(1:numValid);
SacEnd = SacEnd(1:numValid);
% normalize polar plot
for i = 1:8
    if rho(2,i) ~=0; rho(1,i) = rho(1,i) ./ rho(2,i); end
end
% [5] control plot
tPnt = zeros(1,5);
tPnt(1) = mean(FlashB); % black
tPnt(2) = mean(FlashE); % black
tPnt(3) = mean(FixOff); % red
tPnt(4) = mean(SacBeg); % magenta
tPnt(5) = mean(SacEnd); % magenta
if nargout == 0
    pno = 10; % subplot vertical number
    bor = 10; % border
    % set figure size
    setFigureSize([900 400]);
    % [5.1] firing rate plot
    subplot(pno, 2, 3:2:2 * pno);
    plot(tMesh, aMesh/numValid); hold on;
    xlim = get(gca, 'XLim');
    ylim = get(gca, 'YLim');
    axis manual;
    plot([tPnt(1);tPnt(1)], ylim, '--k','LineWidth',0.7); hold on;
    plot([tPnt(2);tPnt(2)], ylim, '--k','LineWidth',0.7); hold on;
    plot([tPnt(3);tPnt(3)], ylim, '--g','LineWidth',0.7); hold on;
    plot([tPnt(4);tPnt(4)], ylim, '--m','LineWidth',0.7); hold on;
    plot([tPnt(5);tPnt(5)], ylim, '--m','LineWidth',0.7); hold on;
    hold off;
    % [5.2] raster plot
    subplot(pno, 2, 1);
    plot(FlashB, 1:numValid, '.k','markersize',3); hold on;
    plot(FixOff, 1:numValid, '.g','markersize',3); hold on;
    plot(SacBeg, 1:numValid, '.m','markersize',3); hold on;
    hold off;
    axis manual;
    set(gca,'XLim',xlim,...
            'YLim',[1-bor;numValid+bor],...
            'XTick',[],...
            'YTick',[]);
    % set title
    if isequal(eDir, [0 1 2 3 4 5 6 7])
        title('All Direction');
    else
        title(['Direction ',num2str(eDir)]);
    end
    % [5.3] polar plot
    subplot(pno, 2, 2:2:2*pno);
    % setPolarLim(0.05);
    polar(0:pi/4:2*pi, rho(1,[1:end 1]));
    title('Global Average');
end
end