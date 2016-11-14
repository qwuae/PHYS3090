% To plot firing rate nicely
% ------------------------------------------------------------------------
% time
% rate
% stages
% shadow
% ------------------------------------------------------------------------
function neuronRatePlot(varargin)
import helper.*;
import process.*;
% Parse Arguments
parser = inputParser;
% ------------------------------------------------------------------------
% [0] required variables
addRequired(parser, 'time');
addRequired(parser, 'rate');
% [1] optional variables
addOptional(parser, 'stages', []);
addOptional(parser, 'shadow', []);
addOptional(parser, 'legend', {});
addOptional(parser, 'shadowcolor', 'Y', @(x) ischar(x));
addOptional(parser, 'ymin', 0.0001, @(x) isnumeric(x));
addOptional(parser, 'title', {});
% ------------------------------------------------------------------------
% [2] parse arguments
parse(parser,varargin{:});
% ------------------------------------------------------------------------
% [3.1] set required arguments
times = parser.Results.time;
rates = parser.Results.rate;
% ------------------------------------------------------------------------
% [3.2] set optional arguments
YMIN  = parser.Results.ymin;
line_stage = parser.Results.stages;
time_range = parser.Results.shadow;
fill_color = parser.Results.shadowcolor;
% --- additional information
info_legend = parser.Results.legend;
info_title  = parser.Results.title;
% ------------------------------------------------------------------------
num = length(line_stage);
color = hsv(num) * 0.7; % vertical line colors
% ------------------------------------------------------------------------
cla('reset');
hold on;
% [4.1] fill selected region
if ~isempty(time_range)
   idx = find(times > time_range(1) & times < time_range(2));
   fX = [times(fliplr(idx)), times(idx)];
   fY = [YMIN * ones(1,length(idx)), rates(idx)];
   fh = fill(fX,fY,fill_color,'EdgeColor',fill_color);
   set(get(get(fh,'Annotation'),'LegendInformation'),...
      'IconDisplayStyle','off');
end
% [4.2] plot-rate
ph = plot(times, rates);
for h = ph'
   set(get(get(h,'Annotation'),'LegendInformation'),...
         'IconDisplayStyle','off');
end
% adjust y-axis limit
ylim = get(gca, 'YLim');
ylim(1) = ylim(1) + YMIN;
% [4.3] plot vertical lines
if ~isempty(line_stage)
   for i = 1:num
      xlim = [line_stage(i);line_stage(i)];
      plot(xlim,ylim,'--','LineWidth',0.7,'color',color(i,:));
   end
end
% ------------------------------------------------------------------------
% additional information
% [4.4] legend
if ~isempty(info_legend)
   legend(info_legend);
end
% [4.5] title
if ~isempty(info_title)
   title(info_title);
end
hold off;
end