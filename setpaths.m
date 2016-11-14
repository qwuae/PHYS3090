%% setup environmental paths for path-independent programming
% [1]
% define searching paths
global neuro_path;
neuro_path = pwd;
% [2]
% add searching paths
addpath(neuro_path);
% [3]
% useful directories
global neuro_dir_window;
neuro_dir_window = [neuro_path,'/window'];