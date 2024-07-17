function [lfp, sf, ground_truth, areas] = download_lfp_figshare(varargin)

    % Get optional values
    p = inputParser;
    addParameter(p,'download_folder', '', @isstr);
    parse(p,varargin{:});
    download_folder = p.Results.download_folder;   
    
    % URL for Thy1_01Jul_neuropixels, in fighsare
    url_lfp = 'https://figshare.com/ndownloader/files/35141068';
    path_lfp = fullfile(download_folder, 'lfp.dat');
    url_info = 'https://figshare.com/ndownloader/files/35141062';
    path_info = fullfile(download_folder, 'info.mat');
    % Save in folder
    if ~exist(path_lfp,'file')
        disp('Downloading lfp...')
        websave(path_lfp, url_lfp);
        websave(path_info, url_info);
    end
    load(path_info);
    % Number of LFP channels
    n_channels = length(areas);
    % Sampling frequency
    sf = fs; % Hz

    % Read it
    lfp = perpl_LoadBinary(path_lfp,...
                'frequency', sf,...
                'samples', inf,...
                'nChannels', 1);
    lfp = reshape(lfp, n_channels, [])';

end