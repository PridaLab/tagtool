function merge_events_in_file(file_name, varargin)

%%% merge_events_in_file takes as only input the name of the
%%% output file from select_events_manually.m. It reads and appends all the
%%% selected event times from files with same name (plus the _1.txt,
%%% _2.txt, etc...), merges them into a single file. If 'keep_old_txts' is
%%% not set as 'true', they are removed. If 'keep_old_txts' is kept as
%%% 'true' then the new file will be called 'XXX_merged.txt'
%%%
%%% Input:
%%%     file_name         path to .txt file. This file has to have two
%%%                       columns containing the beginning and end of
%%%                       events (in seconds)
%%%     keep_old_txts     (optional) False by default
%%%
%%% A. Navas-Olive 2023 LCN
    
    % Get optional values
    p = inputParser;
    addParameter(p,'keep_old_txts', false, @islogical);
    parse(p,varargin{:});
    keep_old_txts = p.Results.keep_old_txts;

    % Read events
    events = read_events_from_file(file_name);
    
    % Make a new merged script    
    new_file_name = file_name;
    new_file_name (strfind(new_file_name ,'.txt'):end) = [];
    new_file_name  = [new_file_name  '_merged.txt'];
    fileID = fopen(new_file_name, 'w');
    fprintf(fileID, '%.8f %.8f\n', events');
    fclose(fileID);
    
    % Remove old txts
    if ~keep_old_txts
        [folder, just_file_name] = fileparts(file_name);
        files_to_remove = dir(fullfile(folder,sprintf('%s*',just_file_name)));
        for ifile = 1:length(files_to_remove)
            full_file_name = fullfile(folder, files_to_remove(ifile).name);
            if ~strcmp(full_file_name, new_file_name)
                delete(full_file_name);
            end
        end
        % Rename merged to original name
        movefile(new_file_name, [file_name '.txt'])
    end
    
end