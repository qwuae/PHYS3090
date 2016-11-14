classdef Neuron
properties
    index  % File Index
    fname  % File Name
    rate = cell(6,1);  % Time Mesh
    time = cell(6,1);  % Average Firing Rate of all direction
    tcut = cell(6,1);
end
% Normal Functions
methods
    %
    % (Array) Constructor
    %
    function obj = Neuron(num)
       import helper.*;
       import process.*;       
       if nargin ~= 0 % to prevent infinite loops
           obj(num) = Neuron;
       end
    end 
end
% Static Functions
methods(Static)
    %
    % Get Time Interval Name
    %
    function r = getPeriodName(p)
        Names = { 'PreTatget'    ,...
                  'PostTarget'   ,...
                  'MemoryPeriod' ,...
                  'PreSaccade'   ,...
                  'PostSaccade' };
        r = Names{p};
    end
    %
    % Get Time Interval Title
    %
    function r = getPeriodTitle(p)
        Names = {   '1) Before Visual Target Onset',...
                    '2) After Visual Target Onset',...
                    '3) Memory Period',...
                    '4) During Saccade',...
                    '5) After Saccade' ...
                };
        r = Names{p};
    end
end
end