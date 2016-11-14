classdef Monkey < handle
   properties(SetAccess = public)
      files % file system
      fpath % file path
      number % Number of Neurons
      idList % Index List
      gpList % Grouping List
      msizes % Minimum Size List
      tpoint
      neurons % Neuron List
      cPeriod % Current Time Period
      corrMat % Cache for Current Correlation Matrix
      rateMat % Cache for Firing Rate Matrix of Current Period
   end
   methods
      %
      % Constructor
      %
      function obj = Monkey(path)
         import process.*;
         import helper.*;
         % [0] load data
         obj.files = dir(['data/',path]);
         obj.fpath = path;
         % [1] initialize array
         obj.number = length(obj.files) - 2;
         obj.idList = 1:1:obj.number;
         obj.gpList = ones(1,obj.number);
         obj.msizes = zeros(1,5);
         obj.tpoint = zeros(5,obj.number);
         % [2] build neurons
         obj.neurons = Neuron(1:obj.number);
         idx = 0;
         % loop over each neuron
         for file = obj.files';
            if (strcmp(file.name,'.')==0 && strcmp(file.name,'..')==0)
               idx = idx + 1; disp(file.name);
               % get information of each neuron
               [~,obj.neurons(idx).fname,~] = fileparts(file.name);
               obj.neurons(idx).index = idx;
               % [2] each period
               pathstr = [path,'/',obj.neurons(idx).fname];
               for i = 1:1:5
                  [ obj.neurons(idx).rate{i},...
                    obj.neurons(idx).time{i},...
                    obj.neurons(idx).tcut{i} ...
                  ] = averagePeriodFiringRate('loc',pathstr ,...
                     'per',i       ,...
                     'dis',false   ,...
                     'cut',true    );
               end
               % [3] all period (using period 4: align on saccade onset)
               [ obj.neurons(idx).rate{6},...
                 obj.neurons(idx).time{6},...
                 ~ , obj.tpoint(:,idx) ...
               ] = averagePeriodFiringRate('loc',pathstr ,...
                  'per',4       ,...
                  'dis',false   ,...
                  'cut',false   );
               obj.neurons(idx).tcut{6} = [...
                  obj.neurons(idx).time{6}(1)  ,...
                  obj.neurons(idx).time{6}(end)];
            end
         end
         obj.cPeriod = 0; % empty cache
         % adjust all sizes
         for i = 1:1:6
            obj.adjustSize(i);
         end
      end
      %
      % shrink data size according to time cuts
      %
      function adjustSize(obj,k)
         import process.*;
         import helper.*;
         % make all data the same size
         % --- [1] time cut
         for i = 1:1:obj.number;
            if i == 1; mtcut = obj.neurons(1).tcut{k}; end;
            mtcut(1) = min(mtcut(1), obj.neurons(i).tcut{k}(1));
            mtcut(2) = min(mtcut(2), obj.neurons(i).tcut{k}(2));
         end
         % --- [2] index list
         idx = cell(obj.number);
         % --- [3] get minimum size
         for i = 1:1:obj.number;
            idx{i} = find(obj.neurons(i).time{k} > mtcut(1) & ...
               obj.neurons(i).time{k} < mtcut(2));
            if i == 1; msize = length(idx{1}); end;
            msize = min(length(idx{i}), msize);
         end
         % --- [4] shrink data
         for i = 1:1:obj.number;
            obj.neurons(i).rate{k} = ...
               obj.neurons(i).rate{k}(idx{i}(1:msize));
            obj.neurons(i).time{k} = ...
               obj.neurons(i).time{k}(idx{i}(1:msize));
            obj.neurons(i).tcut{k} = mtcut;
         end
         obj.msizes(k) = msize;
      end
      %
      % Calculate Correlatiom Matrix
      %
      function computeCorrMat(obj, k)
         import process.*;
         import helper.*;
         obj.corrMat = zeros(obj.number, obj.number);
         for i = 1:1:obj.number;
            for j = 1:1:obj.number;
               id_i = obj.idList(i);
               id_j = obj.idList(j);
               % [1] get data
               ri = obj.neurons(id_i).rate{k};
               rj = obj.neurons(id_j).rate{k};
               % [2] calculate correlation coefficient
               tmp = corrcoef(ri',rj');
               obj.corrMat(i,j) = tmp(1,2);
            end
         end
      end
      %
      % Display Correlation Matrix
      %
      function showCorrMat(obj,k)
         import process.*;
         import helper.*;
         if obj.cPeriod ~= k;
            obj.computeCorrMat(k);
         end
         obj.cPeriod = k;
         imagesc(obj.corrMat);
         axis equal tight;
         colorbar;
         title(Neuron.getPeriodTitle(k));
      end
      %
      % Swap Neuronal Indices
      %
      function swap(obj,i,j)
         import process.*;
         import helper.*;
         tmp = obj.idList(i);
         obj.idList(i) = obj.idList(j);
         obj.idList(j) = tmp;
         if obj.cPeriod ~= 0;
            obj.computeCorrMat(obj.cPeriod);
            obj.showCorrMat(obj.cPeriod);
         end
      end
      %
      % Calculate Firing Rate Matrix
      %
      function computeRateMat(obj,k)
         import process.*;
         import helper.*;
         obj.rateMat = zeros(obj.number,obj.msizes(k));
         for i = 1:1:obj.number
            id = obj.idList(i);
            obj.rateMat(id,:) = obj.neurons(id).rate{k};
         end
      end
      %
      % Clustering Neurons
      %
      function cluster(obj, cutoff, k, showLines)
         import process.*;
         import helper.*;
         % [0] default variables
         if ~exist('showLines','var')
            showLines = false;
         end
         % [1] clustering
         obj.computeRateMat(k);
         T = clusterdata(obj.rateMat,...
            'distance', 'correlation',...
            'linkage' , 'average',...
            'maxclust', cutoff);
         % [2] sort clustering
         [S,I] = sort(T);
         obj.idList = I';
         obj.gpList = S';
         obj.computeCorrMat(k);
         % [3] show figure
         obj.showCorrMat(k);
         % [4] draw cluster boundaries
         if showLines
            hold on;
            sline = find(diff(S) ~= 0) + 0.5;
            for i = 1:1:length(sline)
               plot([sline(i) sline(i)],[0.5 obj.number + 0.5],'--k');
               plot([0.5 obj.number + 0.5],[sline(i) sline(i)],'--k');
            end
            hold off;
         end
      end      
   end
end