%% Function windowing
% ==> windowing the spike matrix (0/1 matrix)
% Input
% -- sps
% -- win
function [mesh] = windowing(sps, win, edges, format)
import helper.*;
import process.*;
% search object from path
global neuro_dir_window;
load([neuro_dir_window,'/',win,'.mat']);
% do calculations
if ~exist('format','var')
   format = 'histogram';
end
switch format
   case 'histogram'
      mesh = conv(sps, wf, 'same');
   case 'timeSeries'
      if ~exist('edges','var')
         error('missing time series input for "timeSeries" format');
      end
      mesh = conv(histc(sps, edges), wf, 'same');
   otherwise
      error('unknown format %s', format);
end
end