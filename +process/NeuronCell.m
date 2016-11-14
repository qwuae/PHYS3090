% class for handling single neuron
classdef NeuronCell < handle
   properties(Constant)
      step = 0.1 % time step
   end
   properties
      pathstr % (str) relative path to the data file
      namestr % (str) data file name
      winfunc % (obj) windowing function
      % (int) processing parameters
      total_number
      valid_number
      % (col struct) alignment points
      align
      alignStr
      % (col struct) time mesh
      time
      % (col struct) parsed raw data
      data 
      % (col matrix) cache for rate
      rate
      % spike matrix
      spikeMat
   end
   methods
      % Array Constructor
      function obj = NeuronCell(num)
         import helper.*;
         import process.*;
        if nargin ~= 0 % to prevent infinite loops
            obj(num) = NeuronCell;
        end
      end 
      % Initialization
      function init(obj, datapath, window)
         import helper.*;
         import process.*;
         % --- load data
         load(datapath);
         obj.setWindowfunc(window);
         obj.setPathstr(datapath);
         obj.setData(c_data);
      end
      %
      % ------------------------------------------------------------------
      % Setter
      % ------------------------------------------------------------------
      %
      function setWindowfunc(obj, window)
         obj.winfunc = load(window);
      end
      %
      function setPathstr(obj, datapath)
         [obj.pathstr,obj.namestr,~] = fileparts(datapath);
      end
      %
      function setData(obj, raw)
         import helper.*;
         import process.*;
         % --- data: structs
         obj.total_number = length(raw);
         obj.data = cell(obj.total_number,1);
         % --- load data
         id = 0;
         for i = 1:obj.total_number;
            % --- check whether trial is valid
            if raw(i).trialcancel~=0; continue; end;
            id = id + 1;
            % 
            % --- trial begin time
            obj.data{id}.begTri = raw(i).time.BeginTime;
            % --- trial end time
            obj.data{id}.endTri = raw(i).time.EndTime;
            % --- fixation onset
            obj.data{id}.begFix = raw(i).reltime.FpOn; 
            % --- fixation offset
            obj.data{id}.endFix = raw(i).reltime.Gap1On;            
            % --- saccade onset
            obj.data{id}.begSac = raw(i).saccade.lat +...
                                  raw(i).saccade.beg;
            % --- saccade offset
            obj.data{id}.endSac = raw(i).saccade.lat + ...
                                  raw(i).saccade.beg + ...
                                  raw(i).saccade.dur;
            % --- target onset
            obj.data{id}.begTar = raw(i).reltime.Rf1On;
            % --- target offset
            obj.data{id}.endTar = raw(i).reltime.Rf1Off;
            %
            % --- eye movements
            obj.data{id}.eyei = raw(i).saccade.ei;
            obj.data{id}.eyef = raw(i).saccade.ef;
            obj.data{id}.eye  = raw(i).saccade.ef - raw(i).saccade.ei;
            obj.data{id}.ang  = cart2pol(obj.data{id}.eye(1),...
                                         obj.data{id}.eye(2));
            obj.data{id}.dir  = ang2dir(obj.data{id}.ang);
            %
            % --- spike information
            obj.data{id}.spikes = raw(i).spike.Time -...
                                  raw(i).time.BeginTime;
         end
         % --- shrink data
         obj.valid_number = id;
         obj.data(id+1:end) = [];
      end
      %
      function setAlign(obj,str)
         obj.alignStr = str;
         obj.align = obj.getDataAttr(str);
      end
      %
      function setRate(obj, method, alignstr)
         if strcmp(alignstr, obj.alignStr) == 0;
            obj.setAlign(alignstr);
         end
         obj.rate = obj.(method)();
      end
      %
      % ------------------------------------------------------------------
      % Getter
      % ------------------------------------------------------------------
      %
      function [t] = getTimeMin(obj)
         t = obj.time(1);
      end
      %
      function [t] = getTimeMax(obj)
         t = obj.time(end);
      end
      %
      function [Tmin, Tmax] = getTimeCut(obj)
         Tmin = obj.getTimeMin;
         Tmax = obj.getTimeMax;
      end
      %
      function [w] = getRateWidth(obj)
         w = size(obj.rate,2);
      end
      %
      function [a] = getDataAttr(obj, attr)         
         a = cellfun(@(x) x.(attr), obj.data);
      end
      %
      % ------------------------------------------------------------------
      % Utilities
      % ------------------------------------------------------------------
      %
      function [r] = computeTime(obj)
         import helper.*;
         import process.*;
         % --- get relative trial time (loop is faster than cellfun)
         t = zeros(obj.valid_number, 1);
         for i = 1:obj.valid_number
            t(i) = obj.data{i}.endTri - obj.data{i}.begTri;
         end
         % --- calculate time
         maxT = max(t-obj.align);
         minT = min( -obj.align);
         obj.time = (minT:obj.step:maxT)';
         % --- set return value
         r = obj.time;
      end
      %
      function [wMesh] = computeWindowing(obj, i)
         import helper.*;
         import process.*;
         % --- Spike Mesh         
         sMesh = histc(obj.data{i}.spikes - obj.align(i), obj.time);
         % --- check vector shape
         if isrow(sMesh); sMesh = sMesh'; end;
         % --- Mesh after Windowing
         wMesh = conv(sMesh, obj.winfunc.wf, 'same'); 
      end
      %
      function [l] = shrinkDataCuts(obj, cuts)
         import helper.*;
         import process.*;
         idx = obj.time > cuts(1) & obj.time < cuts(2);       
         obj.time = obj.time(idx);
         obj.rate = obj.rate(idx,:);
         l = length(obj.time);
      end
      %
      function [l] = shrinkDataSize(obj, len, method)
         import helper.*;
         import process.*;
         switch method
            case {'l','left'}
               obj.time = obj.time(1:len);
               obj.rate = obj.rate(1:len,:);
            case {'r','right'}
               obj.time = obj.time(end-len+1:end);
               obj.rate = obj.rate(end-len+1:end,:);
            otherwise
               error('undefined shrink method');
         end
         l = len;
      end
      %
      function [r] = rateAverage(obj,dir)         
         import helper.*;
         import process.*;
         obj.computeTime();
         % --- calculate rate
         normFactor = 0;
         r = zeros(length(obj.time),1);
         for i = 1:obj.valid_number
            if exist('dir','var')
               if dir ~= obj.data{i}.dir; continue; end;
            end
            normFactor = normFactor + 1;
            r = r + obj.computeWindowing(i);            
         end
         % --- aviod zero division
         if normFactor ~= 0; r = r / normFactor; end;
      end
      %
      function [r] = rateRaw(obj)         
         import helper.*;
         import process.*;
         obj.computeTime();
         % --- calculate rate
         r = zeros(length(obj.time),obj.valid_number);
         for i = 1:obj.valid_number
            r(:,i) = obj.computeWindowing(i);
         end
      end
      %
      function [r] = rateDir(obj)
         import helper.*;
         import process.*;
         obj.computeTime();
         % --- calculate rate
         r = zeros(length(obj.time),8);
         for i = 0:7
            r(:,i+1) = obj.rateAverage(i);
         end
      end
      %
      % ------------------------------------------------------------------
      % Spike analysis
      % ------------------------------------------------------------------
      %
      function isi(obj, period)
         import helper.*;
         import process.*;
         % get time period
         switch period
            case 'preTar'
               t1 = obj.getDataAttr('begFix');
               t2 = obj.getDataAttr('begTar');
            case 'durTar'
               t1 = obj.getDataAttr('begTar');
               t2 = obj.getDataAttr('endTar');
            case 'durMem'
               t1 = obj.getDataAttr('endTar');
               t2 = obj.getDataAttr('endFix');
            case 'preSac'
               t1 = obj.getDataAttr('endFix') - 250;
               t2 = obj.getDataAttr('begSac') + 250;
            case 'durSac'
               t1 = obj.getDataAttr('begSac') - 250;
               t2 = obj.getDataAttr('endSac') + 250;
            otherwise
               error('undefined period');
         end         
         % calculate ISI
         sCut = cell(1, obj.valid_number);
         for i = 1:obj.valid_number
            sRaw = obj.data{i}.spikes;
            sCut{i} = sRaw(sRaw > t1(1) & sRaw < t2(2))';
         end
         spike = [sCut{:}];         
         % make a histogram
         histogram(diff(spike), 1:0.5:40, 'Normalization', 'probability');
      end
   end
end