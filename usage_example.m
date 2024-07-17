clc; clear; close all;
addpath(genpath(fileparts(matlab.desktop.editor.getActiveFilename)));

%  ------------
%  | SETTINGS |
%  ------------

% Data path
data_path = 'data';
if ~exist(data_path,'dir'), mkdir(data_path), end
% Download example data from figshare:
[lfp, sf, gt, areas] = download_lfp_figshare('download_folder',data_path);

% What channels do you want to display?
% Write down what channels you like to be displayed. Channels annotated in
% different cells will be displayed with some separation, useful to display
% different shanks.
% Eg. Probe with 4 shanks of 8 channels each: channels = {1:8, 9:16, 17:24, 25:32}
% Eg. Probe with 2 shanks of 10 and 20 each, but only want to see the first 
%       5 of each shank: channels = {1:5, 11:16}
dorsal_pyr = find(strcmp(areas,'pyr'));
ventral_pyr = find(strcmp(areas,'Vpyr'));
channels = { dorsal_pyr(1:3:end) , ventral_pyr(1:3:end) };

% Recording will be divided into different chunks. 
% How long would you like them to be? (in minutes)
chunk_dur = 5; % minutes

% Load events
[events, file_names] = load_events_from_all_txts(fullfile(data_path,'events'));


%  -----------------
%  | SELECT EVENTS |
%  -----------------

% Name of file to write
file_name = 'events_selected_manually.txt';
file_path = fullfile(data_path, 'events', file_name);

% Run app for selecting events
tagtool(lfp, file_path, 'sf', sf, ...
                        'events', events, ...
                        'event_names', file_names,...
                        'channels', channels, ...
                        'chunk_min', chunk_dur);

