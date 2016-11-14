% assemble all neurons for one monkey
classdef MonkeyCell < handle
   properties (Access = public)      
      % pre-computed variables
      dataDir  % (dir object) directory of the data
      dPathStr % (str) path to the storage directory
      wPathStr % (str) path to the windowing function      
      
      num % (int) total number of neurons      
      idx % (row int)    index list 
      tno % (row int)    number of valid trials for each neuron
      raw % (row struct) neuron raw data      
      
      % -- Processed variables      
      % computed at processing time
      
      alignTime % (col float) alignment time
      eventTime % (col float) event time points
      eventName % (col str)   event name cell
      rangeName % (str)       time range name
      
      pcaResult % PCA results (pc, score, latent, condition, result)

      % -- Processed variables   
      data % (col struct) each variable occupies one column
      time % (col struct) time mesh
   end
   methods
      %
      % ------------------------------------------------------------------
      % Initialization
      % ------------------------------------------------------------------
      % load actual data 
      function loadData(obj)
         import helper.*;
         import process.*;              
         index = 0;         
         for file = obj.dataDir'
            if (file.isdir); continue; end;
            % displaying file names
            disp(file.name); index = index + 1;
            % load data
            pathstr = [obj.dPathStr,'/',file.name];
            obj.raw(index).init(pathstr,obj.wPathStr);
            obj.tno(index) = obj.raw(index).valid_number;
         end
      end
      % Initialization
      function init(obj, fpath, wpath)         
         import helper.*;
         import process.*;  
         obj.wPathStr = ['window/', wpath];
         obj.dPathStr = ['data/'  , fpath];         
         obj.dataDir  = dir(obj.dPathStr);          
         obj.num = length(obj.dataDir)-2;  % exclude '.' and '..' dir         
         obj.idx = 1:obj.num;              % id list for quick ordering         
         obj.tno = zeros(1, obj.num);      % number of trials for each
         obj.raw = NeuronCell(obj.num);    % load data for each neuron
      end
      % Constructor
      function obj = MonkeyCell(fpath, wpath)
         import helper.*;
         import process.*;
         obj.init(fpath, wpath);
         obj.loadData();
      end
      %
      % ------------------------------------------------------------------
      % Setter
      % ------------------------------------------------------------------
      %
      function setTime(obj, series)         
         obj.time = series;
      end
      %
      function setAlignTime(obj, align)         
         k = 0;
         obj.alignTime = zeros(sum(obj.tno), 1);         
         for i = 1:obj.num
            obj.raw(i).setAlign(align);
            obj.alignTime(k+1:k+obj.tno(i)) = obj.raw(i).align;            
            k = k + obj.tno(i);
         end
      end
      %
      % ------------------------------------------------------------------
      % Getter
      % ------------------------------------------------------------------      
      % 
      function [r] = getEventRaster(obj, attr)
         k = 0;
         r = zeros(sum(obj.tno), 1);
         for i = 1:obj.num
            r(k+1:k+obj.tno(i),1) = obj.raw(i).getDataAttr(attr);
            k = k + obj.tno(i);
         end
         r = r - obj.alignTime;
      end
      %
      % ------------------------------------------------------------------
      % Data pre-processing
      % ------------------------------------------------------------------
      %
      function [m, w] = computeRateMethod(obj, method, align, range)
         import helper.*;
         import process.*;
         % [0] set alignment and compute data
         obj.setAlignTime(align);
         arrayfun(@(x) x.setRate(method, align), obj.raw);
         % [1] set event time points & cutting time
         switch range  
            case 'all'
               % --- get events points in raster form
               pTmp = zeros(sum(obj.tno), 5);
               pTmp(:,1) = obj.getEventRaster('begTar');
               pTmp(:,2) = obj.getEventRaster('endTar');
               pTmp(:,3) = obj.getEventRaster('endFix');
               pTmp(:,4) = obj.getEventRaster('begSac');
               pTmp(:,5) = obj.getEventRaster('endSac');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Target Onset';...
                                'Target Offset';...
                                'Fixation Offset';...
                                'Saccade Onset';...
                                'saccade Offset'};
               obj.rangeName = ['All Time',' @ align ', align];
               % --- get smallest time range
               [Tmins, Tmaxs] = arrayfun(@(x) x.getTimeCut, obj.raw);
               c = [ max(Tmins), min(Tmaxs) ];               
            case 'preTar' 
               % 500ms before target onset to target onset               
               % --- get events points and time cuts in raster form
               pTmp = zeros(sum(obj.tno), 1);
               pTmp(:,1) = obj.getEventRaster('begTar');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Target Onset'};
               obj.rangeName = ['Before Visual Target Onset',...
                                ' @ align ', align];
               % --- get smallest time range               
               cTmp = zeros(sum(obj.tno), 2);
               cTmp(:,1) = pTmp(:,1) - 500;
               cTmp(:,2) = pTmp(:,1);
               c = [ max(cTmp(:,1)), min(cTmp(:,2)) ];
            case 'durTar' 
               % after target onset to target offset
               % --- get events points and time cuts in raster form
               pTmp = zeros(sum(obj.tno), 2);
               pTmp(:,1) = obj.getEventRaster('begTar');
               pTmp(:,2) = obj.getEventRaster('endTar');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Target Onset'; 'Target Offset'};
               obj.rangeName = ['Visual Target Appears',...
                                ' @ align ', align];
               % --- get smallest time range
               cTmp = zeros(sum(obj.tno), 2);
               cTmp(:,1) = pTmp(:,1);
               cTmp(:,2) = pTmp(:,2);       
               c = [ max(cTmp(:,1)), min(cTmp(:,2)) ];
            case 'durMem' 
               % target offset to fixation offset
               % --- get events points and time cuts in raster form
               pTmp = zeros(sum(obj.tno), 2);
               pTmp(:,1) = obj.getEventRaster('endTar');
               pTmp(:,2) = obj.getEventRaster('endFix');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Target Offset'; 'Fixation Offset'};
               obj.rangeName = ['Memory Period',...
                                ' @ align ', align];
               % --- get smallest time range
               cTmp = zeros(sum(obj.tno), 2);
               cTmp(:,1) = pTmp(:,1);
               cTmp(:,2) = pTmp(:,2);
               c = [ max(cTmp(:,1)), min(cTmp(:,2)) ];
            case 'durSac' 
               % 250ms before to 250 after saccade onset
               % --- get events points and time cuts in raster form
               pTmp = zeros(sum(obj.tno), 3);
               pTmp(:,1) = obj.getEventRaster('endFix');
               pTmp(:,2) = obj.getEventRaster('begSac');
               pTmp(:,3) = obj.getEventRaster('endSac');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Fixation Offset';...
                                'Saccade Onset';...
                                'Saccade Offset'};
               obj.rangeName = ['During Saccade',...
                                ' @ align ', align];
               % --- get smallest time range
               cTmp = zeros(sum(obj.tno), 2);
               cTmp(:,1) = max(pTmp(:,1), pTmp(:,2) - 250);
               cTmp(:,2) = pTmp(:,3) + 250;
               c = [ max(cTmp(:,1)), min(cTmp(:,2)) ];              
            case 'aftSac' 
               % 250ms to 750ms after saccade offset
               % --- get events points and time cuts in raster form
               pTmp = zeros(sum(obj.tno), 1);
               pTmp(:,1) = obj.getEventRaster('endSac');
               obj.eventTime = mean(pTmp, 1);
               obj.eventName = {'Saccade Offset'};
               obj.rangeName = ['After Saccade',...
                                ' @ align ', align];
               % --- get smallest time range
               cTmp = zeros(sum(obj.tno), 2);
               cTmp(:,1) = pTmp(:,1) + 250;
               cTmp(:,2) = pTmp(:,1) + 750;
               c = [ max(cTmp(:,1)), min(cTmp(:,2)) ];               
            otherwise
               error('undefined time range');
         end
         % [2] shrink data
         w = arrayfun(@(x) x.getRateWidth(), obj.raw);
         s = arrayfun(@(x) x.shrinkDataCuts(c), obj.raw);
         m = min(s);
         % bad alignment checking
         if m == 0
            error(['bad alignment ', align, ' for period ', range]);
         end
         arrayfun(@(x) x.shrinkDataSize(m, 'left'), obj.raw);   
      end
      %
      function computeRateAverage(obj, align, range)
         import helper.*;
         import process.*;
         % calculate raw data
         obj.setPcaCondition(1);
         [T, ~] = obj.computeRateMethod('rateAverage', align, range);
         % load data into matrix
         obj.data = zeros(T, obj.num);
         for i = 1 : obj.num
         	obj.data(:, i) = obj.raw(i).rate(:);         
         end
         %  set time series
         obj.setTime(obj.raw(1).time);         
      end
      %
      % Process data into CT x N matrix
      % --> C : number of saccade directions (8 directions)
      % --> T : Length of time series
      % --> N : number of neurons
      function computeRateDir(obj, align, range)
         import helper.*;
         import process.*;
         % calculate raw data
         C = 8;
         obj.setPcaCondition(C);
         [T, ~] = obj.computeRateMethod('rateDir', align, range);
         % load data into matrix
         obj.data = zeros(T * C, obj.num);
         for i = 1 : obj.num
         	obj.data(:, i) = obj.raw(i).rate(:);         
         end
         %  set time series
         obj.setTime(obj.raw(1).time);
      end
      % Process all data into one T x M matrix
      % --> T : Length of time series
      % --> M : the total number of trials of all neurons
      function computeRateRaw(obj, align, range)
         import helper.*;
         import process.*;
         % calculate raw data
         obj.setPcaCondition(1);
         [l, w] = obj.computeRateMethod('rateRaw', align, range);
         % --- load data into matrix
         obj.data = zeros(l, sum(w));
         k = 0;
         for i = 1:obj.num
            obj.data(:, k + 1:k + w(i)) = obj.raw(i).rate;
            k = k + w(i);
         end
         % load time (for simplicity, use the time of the first neuron)
         obj.setTime(obj.raw(1).time);
      end
      %
      % ------------------------------------------------------------------
      % PCA analysis
      % ------------------------------------------------------------------
      %
      function setPcaCondition(obj, C)
         import helper.*;
         import process.*;
         obj.pcaResult.condition = C;
      end
      %
      function pcaCut(obj)
         import helper.*;
         import process.*;
         C = obj.pcaResult.condition;
         N = length(obj.time);
         obj.pcaResult.result = cell(C,1);
         for i = 1:C
            i_id = i * N - N + 1;
            f_id = i * N;
            obj.pcaResult.result{i} = obj.pcaResult.score(i_id:f_id, :);
         end
      end
      %
      function pca(obj)
         import helper.*;
         import process.*;
         [pc, score, latent] = pca(obj.data);
         obj.pcaResult.pc = pc;
         obj.pcaResult.score = score;
         obj.pcaResult.latent = latent;         
         obj.pcaCut();
      end
      %
      function [p] = pcaLatentPercentage(obj, i)
         import helper.*;
         import process.*;
         n = sum(obj.pcaResult.latent(i));
         d = sum(obj.pcaResult.latent);
         p = 100 *  n / d;
         fprintf('\ncontaining %f percentage\n\n',p);
      end
      %
      function pcaDirectPlot(obj, period)
         import helper.*;
         import process.*;
         C = obj.pcaResult.condition;
         plot(obj.pcaResult.score(:,period));         
         % draw boundary lines
         tnum = length(obj.time);
         rlim = get(gca, 'ylim');
         hold on;
         for i = 1:C-1
            plot([tnum * i, tnum * i], rlim, '--k');
         end
         hold off;
         % restore axis limits
         xlim([0,tnum * C]);
         ylim(rlim);
         set(gca,'xtick',[]);
         % print percentage
         obj.pcaLatentPercentage(period);
      end
      %
      function pcaPlotCond(obj,c,i)
         import helper.*;
         import process.*;
         if obj.pcaResult.condition > 1
            title = [obj.rangeName, ' @ condition ', num2str(c)];
         else
            title = obj.rangeName;
         end
         neuronRatePlot(obj.time, obj.pcaResult.result{c}(:,i), ...
            'stages', obj.eventTime, ...
            'legend', obj.eventName, ...
            'title',  title);
         % print percentage
         obj.pcaLatentPercentage(i);
      end
      %
      function pcaPlotPolarSub(obj, pos, c, i)
         import helper.*;
         import process.*;
         subplot(3,3,pos);
         neuronRatePlot(obj.time, obj.pcaResult.result{c}(:,i), ...
            obj.eventTime);
      end
      %
      function pcaPlotPolar(obj, i)
         import helper.*;
         import process.*;
         setFigureSize([1000, 1000]);
         if obj.pcaResult.condition ~= 8
            error('can only plot polar for directional analysis');
         end
         % plot data in 8 direction
         obj.pcaPlotPolarSub(6,1,i);
         obj.pcaPlotPolarSub(3,2,i);
         obj.pcaPlotPolarSub(2,3,i);
         obj.pcaPlotPolarSub(1,4,i);
         obj.pcaPlotPolarSub(4,5,i);
         obj.pcaPlotPolarSub(7,6,i);
         obj.pcaPlotPolarSub(8,7,i);
         obj.pcaPlotPolarSub(9,8,i);
      end
      %
      function pcaCrossPlot(obj, i, j)
         import helper.*;
         import process.*;
         C = obj.pcaResult.condition;
         % constants
         c = hsv(C) * 0.7;
         n = length(obj.time);
         % set figure         
         setFigureSize([1600 800]);
         subplot(1,2,1); cla('reset');
         subplot(1,2,2); cla('reset');
         % drawing
         for t = 1 : 100 : C * n
            % plot sub-1
            subplot(1,2,1);
            cla('reset');
            plot(obj.pcaResult.score(:,[i,j])); 
            ypos = get(gca, 'ylim');            
            hold on; plot([t,t], ypos,'--k'); hold off;
            ylim(ypos);
            xlim([1,C * n]);
            % plot sub-2
            subplot(1,2,2);
            % vertical line
            cn = ceil(t/n);
            it = 1 + cn * n - n;
            hold on;
            plot(obj.pcaResult.score(it:t,i),...
                 obj.pcaResult.score(it:t,j),'color', c(cn,:));   
            xlim([-240 240]);
            ylim([-240 240]);
            hold off;
            % pause and draw
            pause(0.005);
            drawnow;
         end
      end
      %
      function pcaPlotBasis(obj, i)
         import helper.*;
         import process.*;
         plot(obj.pcaResult.pc(:,i));
      end
   end
end