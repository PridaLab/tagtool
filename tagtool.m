function tagtool(LFP, file_name, varargin)
    
%%%  tagtool(LFP, file_name) plots LFP signal by chunks,
%%%  displays a GUI to mark events clicking on the screen, than then saves
%%%  in the file_name file. There are shortcuts to substitute the buttons:
%%%     d -> select new event
%%%     f -> end selecting new event
%%%     b -> remove last event
%%%     t -> slide forward
%%%     q -> slide backwards
%%%
%%%
%%% Inputs:
%%%    LFP            Signal to plot.
%%%    file_name      Full path to file in which to save marked events.
%%%                   Those saved events will be in the same units as the
%%%                   provided time signal x.
%%%    sf             (optional) Sampling frequency. By default, 30 kHz
%%%    chunk_min      (optional) Time length (in minutes) in which to
%%%                   divide the signal to shorten it. By default, 2min.
%%%    events         (optional) Cell array of ini and end of events of
%%%                   interest (eg, predicted events). By default it will
%%%                   be empty. If not is empty, each group of events will
%%%                   be plotted in a different color
%%%    event_names    (optional) Names characterizing each group of events
%%%                   of the variable "events"
%%%    channels       (optional) Cell array, containing what channels to
%%%                   plot for each channel. For example, if you has two
%%%                   probes of 8 channels, and want to plot the first 2 of
%%%                   the first probe, and then the 8 of the second probe,
%%%                   channels = {[1,2], [9:16]};
%%%                   If it's not provided, all channels will be plotted.
%%%                
%%% 
%%% A. Navas-Olive, LCN 2023

    % Get optional values
    p = inputParser;
    addParameter(p,'sf', 30000, @isnumeric);
    addParameter(p,'chunk_min', 5, @isnumeric);
    addParameter(p,'events', {}, @iscell);
    addParameter(p,'event_names', {}, @iscell);
    addParameter(p,'channels', {1:size(LFP,2)}, @iscell);
    parse(p,varargin{:});
    sf = p.Results.sf;
    chunk_min = p.Results.chunk_min;
    events = p.Results.events;
    event_names = p.Results.event_names;
    channels = p.Results.channels;
    
    % Erase termination
    [dirData, file_name_base, ~] = fileparts(file_name);
    
    % Exclude manually detected events
    ikeep = find(strcmp(event_names, [file_name_base '.txt'])==0);
    event_names = event_names(ikeep);
    events = events(ikeep);
    
    % Change file names to display them nicely
    event_names = strrep(event_names','_',' ');
    
    % Make folder
    if ~exist(dirData, 'dir')
        mkdir(dirData)
    end
    
    tmp = 1;
    while exist(file_name,'file')        
        [~, just_file_name] = fileparts(file_name);
        file_name_split = strsplit(just_file_name,'_');
        file_name_1 = strjoin(file_name_split(1:3),'_');
        file_name_2 = '_1';
        if length(file_name_split)>3
            file_name_2 = ['_' num2str(1+str2num(file_name_split{4}))];
        end
        file_name = fullfile(dirData, sprintf('%s%s.txt', file_name_1, file_name_2));
    end
    
    % Downsample LFP properties
    sf_low = 1250;
    idxs = 1:size(LFP,1);
    idxs_downsampled = linspace( 1, size(LFP,1), size(LFP,1)*sf_low/sf);
    
    % Make new downsampled LFP with the selected channels
    lfp = LFP(:, cell2mat(channels));
    lfp = interp1( idxs, double(lfp), idxs_downsampled );
    
    % Select y positions to space shanks
    y_channel = [];
    k = 0;
    for shank = 1:length(channels)
        y_channel = [y_channel, k + [1:length(channels{shank})]];
        k = length(y_channel)+shank;
    end

    % chunk_min - min chunk
    chunks = [0:chunk_min*60:size(lfp,1)/sf_low];

    for ichunk = 1:length(chunks)

        fprintf('You are in %d-min-chunk %d/%d...',chunk_min,ichunk,length(chunks)); tic
        chunk = chunks(ichunk);

        idxs = max(1, chunk*sf_low) : min((chunk+chunk_min*60)*sf_low, size(lfp,1));
        x = idxs'/sf_low;
        y = lfp(idxs,:); 
        y = ( y - mean(y) ) ./ (2.5*std(y));

        % Plot
        GUI_tagtool(x, y, file_name, 'separate_channels', -y_channel,...
                            'events', events, 'event_names', event_names, ...
                            'file_name_base', file_name_base)

        % Total number of ripples
        selected_events = read_events_from_file(fullfile(dirData, [file_name_base '.txt'])); 
        num_total_events = size(selected_events,1);
        fprintf(' - %d total ripples (%.2f sec)\n',num_total_events,toc);
    end

end