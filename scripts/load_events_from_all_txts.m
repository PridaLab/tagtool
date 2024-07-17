function [events, file_names] = load_events_from_all_txts(data_path)

%%% It returns a cell array 'events' that contains the ini and end times of
%%% of all the txt event files found in 'data_path'
%%%
%%% Inputs:
%%%    data_path  directory of data
%%%
%%%    events   1xM cell array. Each M cell corresponds to timings of the
%%%             different M types of events, and contains a N(m)x2 vector
%%%             with inis and ends of events
%%%    ids      (optional) Open Ephys output IDs of the different events
%%% 
%%% A. Navas-Olive, LCN 2023
    
    % Read all events in 'data_path'
    all_file_names = dir(data_path);
    all_file_names = {all_file_names.name};
    n_files = length(all_file_names);
    file_names = {};
    
    % Remove all names that contain "_n.txt", and folders
    for ifile = 3:n_files
        if isempty(regexp(all_file_names{ifile},'([a-z]|[_])+_(\d)+.txt','match')) &&...
                isfile(fullfile(data_path,all_file_names{ifile}))
            file_names = [file_names all_file_names{ifile}];
        end
    end
    
    % Load events from the remaining files
    n_files = length(file_names);
    events = cell(1,n_files);
    for ifile = 1:n_files
        events{ifile} = read_events_from_file(fullfile(data_path, file_names{ifile}));
    end
    
end