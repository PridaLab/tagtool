function events = read_events_from_file(file_name, varargin)

%%% read_all_events takes as only input the name of the
%%% output file from select_events_manually.m. It reads and appends all the
%%% selected event times from files with same name (plus the _1.txt,
%%% _2.txt, etc...)
%%%
%%% Input:
%%%     file_name         path to .txt file. This file has to have two
%%%                       columns containing the beginning and end of
%%%                       events (in seconds)
%%%     remove_duplicates (optional) if duplicates events are detected, 
%%%                       it removes them if true, keeps them if false.
%%% 
%%% Output:
%%%     selected_events:  Nx2 array with start and end of each event (in
%%%                       seconds)
%%%
%%% A. Navas-Olive 2023 LCN
    
    % Get optional values
    p = inputParser;
    addParameter(p,'remove_duplicates', true, @islogical);
    parse(p,varargin{:});
    remove_duplicates = p.Results.remove_duplicates;

    % Take name of folder without _X
    [folder, just_file_name] = fileparts(file_name);
    file_name_basic = just_file_name;
    
    % Check all files starting with that name
    datFile = dir(fullfile(folder,sprintf('%s*',file_name_basic)));

    % Retreive event times
    events = [];
    for ifile = 1:length(datFile)
        % Read events
        events = [events; importdata(fullfile(folder, datFile(ifile).name));];
    end
    
    % Sort
    events = unique(events,'rows');
    
    % Remove duplicates
    if remove_duplicates && ~isempty(events)
        events(events(2:end,1) < events(1:end-1,2),:) = [];
    end
    
    
end