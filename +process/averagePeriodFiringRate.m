%% Calculate get firing rate in period
% Input Arguments
% * Loc: Data File Name / Location
% * Win: Windowing Function File Name
% * Per: Selected Period
% * Dir: Display Selected Directions Only
% * Flags:
% *   dis (display): draw graphs if true
% *   cut: cut output rate according to cutting points if true
% Ourput Arguments (All Row Vectors)
% * rate: Average Firing Rate
% * time: Time Axis of the Average Firing Rate
% * tcut: Cutting time points for selected region
% Function Definition
function [rate, time, tcut, tpnt] = averagePeriodFiringRate(varargin)
import helper.*;
import process.*;
% Parse Arguments
% [1] Default Variables
defaultLoc = 'example';      % data file name
defaultWin = 'Gaussian_50';  % windowing function
defaultPer = 1;              % alignment point
defaultDir = 0;              %
defaultFlagDis = true;
defaultFlagCut = false;
defaultFlagAppend = false;
defaultPlotContent = 'all';
% [2] Validation functions
validLoc = @(x) ischar(x);
validWin = @(x) ischar(x);
validPer = @(x) sum(x == [1,2,3,4,5]) == 1;
validDir = @(x) sum(x == [0,1,2,3,4,5,6,7,8]) == 1;
% [3] Parse Inputs
parser = inputParser;
% [3.1]
addParameter(parser,'loc',defaultLoc,validLoc);
addParameter(parser,'win',defaultWin,validWin);
addParameter(parser,'per',defaultPer,validPer);
addParameter(parser,'dir',defaultDir,validDir);
addParameter(parser,'dis',defaultFlagDis,@islogical);
addParameter(parser,'cut',defaultFlagCut,@islogical);
addParameter(parser,'append',defaultFlagAppend,@islogical);
addParameter(parser,'plotContent',defaultPlotContent,@ischar);
% [3.2] parse arguments
parse(parser,varargin{:});
% [3.3] set arguments
loc = parser.Results.loc;
win = parser.Results.win;
per = parser.Results.per;
dir = parser.Results.dir;
disFlag = parser.Results.dis;
cutFlag = parser.Results.cut;
appendFlag = parser.Results.append;
plotContent = parser.Results.plotContent;

% Pre-Process data
% [1] load data
load(['window/',win,'.mat']);
load(['data/'  ,loc,'.mat']);
tnum = length(c_data); % number of trials
% [2] define alignment
switch per
   case {1,2}
      align = 'TargetOnset';
   case {3}
      align = 'FixationOff';
   case {4}
      align = 'SaccadeOnset';
   case {5}
      align = 'SaccadeOffset';
   otherwise
      error('Undefined Period');
end
% [3] calculate time range and alignment
alignPoints = zeros(tnum, 1);
timeStep = 0.1;
maxT = 0;
minT = 0;
for i = 1:tnum
   % check whether trial is valid
   if c_data(i).trialcancel; continue; end;
   % [3.1] alignment
   bTrial = c_data(i).time.BeginTime; % trial begin time
   eTrial = c_data(i).time.EndTime;   % trial end time
   switch align
      case 'FixationOff'
         alignPoints(i) = c_data(i).saccade.beg;
      case 'SaccadeOnset'
         alignPoints(i) = c_data(i).saccade.lat + c_data(i).saccade.beg;
      case 'SaccadeOffset'
         alignPoints(i) = c_data(i).saccade.lat + ...
            c_data(i).saccade.beg + ...
            c_data(i).saccade.dur;
      case 'TargetOnset'
         alignPoints(i) = c_data(i).time.Rf1On  - bTrial;
      case 'TargetOffset'
         alignPoints(i) = c_data(i).time.Rf1Off - bTrial;
      otherwise
         error('Undefined Alignment Method');
   end
   % [3.2] store time points
   maxT = max(eTrial - bTrial - alignPoints(i), maxT);
   minT = min(-alignPoints(i), minT);
end

% Default Outputs
time  = minT:timeStep:maxT;    % time mesh
rate  = zeros(1,length(time)); % average firing rate mesh

% Process Data
% [1]
id = 0;
cData = zeros(2, tnum);
pData = zeros(2, 8);
rData = zeros(5, tnum);
for i = 1:tnum
   % [2] check whether trial is valid
   if c_data(i).trialcancel; continue; end;
   
   % [3] eye direction
   eye = c_data(i).saccade.ef - c_data(i).saccade.ei;
   ang = ang2dir(cart2pol(eye(1), eye(2)));
   
   % [4] test eye direction
   if (dir ~= 0 && ang ~= dir);
      continue;
   else
      id = id + 1;
      % [5] plot raster point
      % --- Target Onset
      rData(1,id) = c_data(i).reltime.Rf1On  - alignPoints(i);
      % --- Target Offset
      rData(2,id) = c_data(i).reltime.Rf1Off - alignPoints(i);
      % --- Fixation Offset
      rData(3,id) = c_data(i).saccade.beg - alignPoints(i);
      % --- Saccade Onset
      rData(4,id) = c_data(i).saccade.lat + ...
         c_data(i).saccade.beg - ...
         alignPoints(i);
      % --- Saccade Offset
      rData(5,id) = c_data(i).saccade.lat + ...
         c_data(i).saccade.beg + ...
         c_data(i).saccade.dur - ...
         alignPoints(i);
      
      % [6] plot firing rate
      % [6.1] windowing
      % --- Spike List
      sTime = c_data(i).spike.Time - c_data(i).time.BeginTime;
      % --- Spike Mesh
      sMesh = histc(sTime' - alignPoints(i), time);
      % --- Mesh after Windowing
      wMesh = conv(sMesh, wf, 'same');
      % --- Total Sum
      rate = rate + wMesh;
      switch per
         case 1 % 500m before target onset
            cData(1, id) = max(rData(1,id) - 500 , minT);
            cData(2, id) = rData(1,id);
         case 2 % 500ms after target onset, but before target offset
            cData(1, id) = rData(1,id);
            cData(2, id) = min(rData(1,id) + 500, rData(2,id));
         case 3 % before fixation offset but after target offset
            cData(1, id) = rData(2,id);
            cData(2, id) = rData(3,id);
         case 4 % 250 before saccade onset but after fixation offset
            cData(1, id) = max(rData(3,id), rData(4,id) - 250);
            cData(2, id) = min(rData(4,id) + 250, maxT);
         case 5
            cData(1, id) = min(rData(5,id) + 250, maxT);
            cData(2, id) = min(rData(5,id) + 750, maxT);
      end
      
      % [7] polar plot
      if cutFlag
         polarMesh = wMesh(time > cData(1, id) & time < cData(2, id));
      else
         polarMesh = wMesh;
      end
      pData(1,ang+1) = ...
         pData(1,ang+1) + mean(polarMesh);
      pData(2,ang+1) = pData(2,ang+1) + 1;
   end;
end

% Cutting points
tcut(1) = max(cData(1,1:id));
tcut(2) = min(cData(2,1:id));
cutIdx = find(time > tcut(1) & time < tcut(2));

% Plot
if disFlag
   if ~appendFlag
      figure;
   end
   % shrink data
   rData = rData(1:5,1:id);
   % normalize polar plot
   for i = 1:8
      if pData(2,i) ~=0; pData(1,i) = pData(1,i) ./ pData(2,i); end
   end
   tPnt = mean(rData,2);
   
   % set figure size
   setFigureSize([900 400]);
   
   if strcmp(plotContent, 'all') || strcmp(plotContent, 'rate')
      % [5.1] firing rate plot
      if strcmp(plotContent, 'all')
         subplot(10, 2, 3:2:20);
      elseif strcmp(plotContent, 'rate')
         subplot(10, 1, 2:1:10);
      end
      neuronRatePlot(time, rate/id, 'stages', tPnt, 'shadow', tcut);

      % [5.2] raster plot
      xlim = get(gca, 'XLim');
      if strcmp(plotContent, 'all')
         subplot(10, 2, 1);
      elseif strcmp(plotContent, 'rate')
         subplot(10, 1, 1);
      end
      hold on;
      plot(rData(1,:), 1:id, '.k','markersize',3);
      plot(rData(3,:), 1:id, '.g','markersize',3);
      plot(rData(4,:), 1:id, '.m','markersize',3);
      hold off; axis manual;
      set(gca,'XLim',xlim,'YLim',[1-10;id+10],'XTick',[],'YTick',[]);
      % set title
      if dir == 0
         title(['All direction',' at period ',num2str(per)]);
      else
         title(['Only direction ',num2str(dir),' at period ',num2str(per)]);
      end;   
   end
   
   % [5.3] polar plot
   if strcmp(plotContent, 'all') || strcmp(plotContent, 'polar')
      if strcmp(plotContent, 'all')
         subplot(10, 2, 2:2:20);
      end
      % setPolarLim(0.05);
      polar(0:pi/4:2 * pi, pData(1,[1:end 1]));
      if cutFlag
         title(['Average over only period ',num2str(per)]);
      else
         title( 'Average over all periods' );
      end
   end
   
end

tpnt = mean(rData,2);
% Cut Output Rate
if cutFlag
   time = time(cutIdx);
   rate = rate(cutIdx);
end
end