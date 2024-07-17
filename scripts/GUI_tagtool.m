function GUI_tagtool(x, y, file_name, varargin)

%%%  GUI_tagtool(x, y, file_name) plots (x,y) signal, and
%%%  displays a GUI to mark events clicking on the screen, than then saves
%%%  in the file_name file. There are shortcuts to substitute the buttons:
%%%     d -> select new event
%%%     f -> end selecting new event
%%%     b -> remove last event
%%%     t -> slide forward
%%%     a -> slide backwards
%%%
%%%
%%% Inputs:
%%%    x              Times of signal to plot (eg seconds)
%%%    y              Signal to plot (eg one shank of a LFP recording)
%%%    file_name      Full path to file in which to save marked events.
%%%                   Those saved events will be in the same units as the
%%%                   provided time signal x.
%%%    events         (optional) cell array of ini and end of events of
%%%                   interest (eg, predicted events). By default it will
%%%                   be empty.
%%%    file_name_base (optional) Base of the file_name, in case file_name
%%%                   has suffixes like _1... By default is file_name
%%%                
%%% 
%%% A. Navas-Olive, LCN 2020 



    % -----------------------
    %   Get variables
    % -----------------------    
    
    % Get optional values
    p = inputParser;
    addParameter(p,'separate_channels', {}, @isnumeric);
    addParameter(p,'events', {}, @iscell);
    addParameter(p,'event_names', {}, @iscell);
    addParameter(p,'file_name_base', file_name, @isstr);
    parse(p,varargin{:});
    separate_channels = p.Results.separate_channels;
    events = p.Results.events;
    event_names = p.Results.event_names;
    file_name_base = p.Results.file_name_base;
    [dirData, ~, ~] = fileparts(file_name);
    [~, file_name_base, ~] = fileparts(file_name_base);
    file_name_base = fullfile(dirData, file_name_base);
    
    % By default, make amplitude an option
    do_amplitude = true;
    amplitude = 1;
    icmap = 1;
    
    % If there are events but not event_names, then make event names
    if ~isempty(events) && isempty(event_names)
        for group = 1:length(events)
            event_names = [event_names, fprintf('events #%d', group)];
        end
    end
    
    % Define variables
    if ~exist('cmap','var'), cmap = colormap('lines'); close; end
    
    % Previously selected events
    selected_events = read_events_from_file(file_name_base);
    % Find last selected
    if ~isempty(selected_events)
        n = max( floor(max(selected_events(:,1)))-x(1) , 0);
        if n > (max(x)-min(x)-1)
            n = floor(max(x)-min(x)-2);
        end
    else
        n = 0;
    end
    
    % Generate Plot Variables
    idxs_win = find(x>=(min(x)+n) & x<=(min(x)+n+2));
    if isempty(separate_channels)
        separate_channels = -[1:size(y,2)];
    end
    y_min = min(min(amplitude*y(idxs_win,:) + separate_channels));
    y_max = max(max(amplitude*y(idxs_win,:) + separate_channels));
    y_min = y_min - (y_max-y_min)/20;
    y_max = y_max + (y_max-y_min)/20;

    

    % -----------------------
    %   Plot
    % -----------------------
    
    % Make Figure
    hf = figure('units','normalized','pos',[0.05 0.15 0.9 0.6], ...
                    'KeyPressFcn', @keyPress);
    ha = axes('position',[0.1 0.3 0.8 0.6]);
    
    % Make legend
    if ~isempty(events)
        hold on
        for idetection = 1:size(events, 2)
            hlegend{idetection} = fill([-100 -99], [-100,-99], 1, 'facecolor', cmap(idetection+icmap,:), 'edgecolor', 'none' );
        end
    end
    
    % Plot LFP
    hplot = plot(x(idxs_win), amplitude*y(idxs_win,:) + separate_channels, 'k');
    
    % Plot Previously selected events
    hold on
    if ~isempty(selected_events)
        ievents = find(((n+min(x)) < selected_events(:,2)) & (selected_events(:,1) < (n+min(x)+2)));
        if ~isempty(ievents)
            kevent = 1;
            for ievent = ievents
                hdetct{kevent} = fill(selected_events(ievent,[1 2 2 1]), [y_min y_min y_max y_max], 1, 'facecolor', [0.1 0.5 0.7], 'facealpha', 0.3, 'edgecolor', 'none');
                kevent = kevent+1;
            end
        end
    end
    
    % Plot Detected Events
    hevents = cell(0);
    if ~isempty(events)
        hold on
        k = 1;
        x_events = {};
        y_events = {};
        for idetection = 1:size(events, 2)
            events_to_plot = find((events{1,idetection}(:,1)>=x(1)) & (events{1,idetection}(:,2)<=x(end)));
            x_events{idetection} = cell(1,length(events_to_plot));
            y_events{idetection} = cell(1,length(events_to_plot));
            for ievent = events_to_plot'
                xini = events{1,idetection}(ievent,1);
                xend = events{1,idetection}(ievent,2);
                xs = [x(x>=xini & x<=xend)];
                ys = [(1.05-0.09*idetection)+zeros(size(xs)), y(x>=xini & x<=xend,:)];
                x_events{idetection}{ievent} = xs;
                y_events{idetection}{ievent} = ys;
                % Plot in this window
                if (xs(1)>=x(idxs_win(1))) && (xs(end)<=x(idxs_win(end)))
                    ys_hight = [0 -separate_channels];
                    hevents{k} = plot(xs, amplitude*ys - ys_hight, 'color', cmap(idetection+icmap,:));
                    k = k+1;
                end
            end
        end
    end
    
    
    % Axis
    xlabel('Time (seg)')
    ylabel('LFP')
    xlim([n+min(x) n+min(x)+2])
    ylim([y_min y_max])
    set(gca, 'ytick', [])
    if ~isempty(events)
        legend(event_names, 'orientation', 'horizontal', 'location', 'northoutside')
    end
    
    
    
    
    % -----------------------
    %   Buttons
    % -----------------------
    
    set(hplot,'hittest','off')
    
    hstart = uicontrol('style','pushbutton','string','New ripple',...
        'units','normalized','position',[0.775 0.125 0.05 0.075],...
        'callback',@startgin);
    
    hstop = uicontrol('style','pushbutton','string','Done',...
        'units','normalized','position',[0.83 0.125 0.05 0.075],...
        'callback',@stopgin,'enable','off');
    
    hdelete = uicontrol('style','pushbutton','string','Remove last',...
        'units','normalized','position',[0.885 0.125 0.05 0.075],...
        'callback',@deletelast);
    
    hscroll = uicontrol('style','slider','units','normalized',...
        'position',[0.0 0.05 0.75 0.05],'min',0,'max',max(x)-min(x)-1,...
        'SliderStep',[1 2]/(max(x)-min(x)+1),'callback',@fct,...
        'value', n);
        
    hend = uicontrol('style','pushbutton','string','END AND CLOSE',...
        'units','normalized','position',[0.775 0.05 0.16 0.075],...
        'Callback', 'uiresume(gcbf)');
    
    if do_amplitude
        uicontrol('style','text','string','LFP amplitude ', 'unit','normalized','position',[.92 .34 .1 .1]);
        hamplitude = uicontrol('style','edit','string', amplitude,'unit','normalized','position',[.925 .25 .05 .1]);
    end
    
    % Instructions
    htop = .95;
    %%%     d -> select new event
    uicontrol('style','text','string','d: start new event', 'unit','normalized','position',[.90  htop .1 .03]);
    %%%     f -> end selecting new event
    uicontrol('style','text','string','f: end new event', 'unit','normalized','position',[.90  htop-0.03 .1 .03]);
    %%%     b -> remove last event
    uicontrol('style','text','string','b: remove last event', 'unit','normalized','position',[.90  htop-0.03*2 .1 .03]);
    %%%     t -> slide forward
    uicontrol('style','text','string','space: slide forward', 'unit','normalized','position',[.90  htop-0.03*3 .1 .03]);
    %%%     q -> slide backwards   
    uicontrol('style','text','string','a: slide backwards', 'unit','normalized','position',[.90  htop-0.03*4 .1 .03]);
    

    % -----------------------
    %   Wait
    % -----------------------
    
    uiwait(gcf)
    close
    

    
    
    % -----------------------
    %   Functions
    % -----------------------

    % Keyboard shortcuts
    
    function keyPress(hObj, e)
        switch e.Key
            % d: new event
            case 'd'
                startgin(hstart)
            % f: end new event
            case 'f'
                stopgin(hstop)
            % b: remove last event
            case 'b'
                deletelast(hdelete)
            % t: slide forward
            case 'space'
                hscroll.Value = n+2;
                fct(hscroll)
            % q: slide backwards
            case 'a'
                hscroll.Value = n-2;
                fct(hscroll)
        end
    end
    
    % Start / End event selection
    
    function startgin(hObj,~,~)
        set(hObj,'Enable','off')
        set(hstop,'enable','on')
        set(hf,'WindowButtonMotionFcn',@changepointer)
        set(ha,'ButtonDownFcn',@getpoints)
    end

    function stopgin(hObj,~)
        set(hObj,'Enable','off')
        set(hstart,'enable','on')
        set(hf,'Pointer','arrow')
        set(hf,'WindowButtonMotionFcn',[])
        set(ha,'ButtonDownFcn',[])
        xy = getappdata(hf,'xypoints');
        hold on
        if ~isempty(xy)
            if exist('hdetct','var')
                hdetct{length(hdetct)+1} = fill( [xy(end-1:end,1)' flip(xy(end-1:end,1)')], [y_min y_min y_max y_max], 1, 'facecolor', [0.1 0.5 0.7], 'facealpha', 0.3, 'edgecolor', 'none');
            else
                hdetct{1} = fill( [xy(end-1:end,1)' flip(xy(end-1:end,1)')], [y_min y_min y_max y_max], 1, 'facecolor', [0.1 0.5 0.7], 'facealpha', 0.3, 'edgecolor', 'none');
            end
        
            % Write data
            fileID = fopen(file_name,'a');
            fgetl(fileID);
            fprintf(fileID, '%.8f %.8f\n', min(xy(end-1:end,1)), max(xy(end-1:end,1)));
            fclose(fileID);
        end
    end

    function changepointer(~,~)
        axlim = get(ha,'Position');
        fglim = get(hf,'Position');
        x1 = axlim(1)*fglim(3) + fglim(1);
        x2 = (axlim(1)+axlim(3))*fglim(3) + fglim(1);
        y1 = axlim(2)*fglim(4) + fglim(2);
        y2 = (axlim(2)+axlim(4))*fglim(4) + fglim(2);
        pntr = get(0,'PointerLocation');
        if pntr(1)>x1 && pntr(1)<x2 && pntr(2)>y1 && pntr(2)<y2
            set(hf,'Pointer','crosshair')
        else
            set(hf,'Pointer','arrow')
        end
    end

    function getpoints(hObj,~,~)
        cp = get(hObj,'CurrentPoint');
        line(cp(1,1),cp(1,2),'linestyle','none','marker','o','color',[0.1 0.5 0.7])
        xy = getappdata(hf,'xypoints');
        xy = [xy;cp(1,1:2)];
        setappdata(hf,'xypoints',xy);
    end
    
    % Delete last event

    function deletelast(~,~)        
        % Count events
        selected_events = read_events_from_file(file_name);
        num_total_events = length(selected_events);
        % If there are events
        if num_total_events>0
            % Copy text from file
            fileID = fopen(file_name,'r');
            text = fileread(file_name);
            fclose(fileID);
            % Erase last line
            text_erased = strsplit(text,'\n');
            fileID = fopen(file_name,'w');
            fgetl(fileID);
            for ii = 1:length(text_erased)-2
                fprintf(fileID, '%s\n', text_erased{ii});
            end
            fclose(fileID);
        else
            warning('No events found to delete')
        end
        % Erase from plot
        delete(hdetct{end})
    end


    % Scroll

    function fct(~,~)
        
        % Update horizontal scroll
        n = get(hscroll,'value');
        n = round(n);
        
        % Update Amplitude        
        idxs_win = find(x>=(min(x)+n) & x<=(min(x)+n+2));
        if do_amplitude
            amp_y = str2double(hamplitude.get.String);
        end
        
        % Plot LFP
        delete(hplot)
        hplot = plot(x(idxs_win), amp_y*y(idxs_win,:) + separate_channels, 'k');
        
        % Detected events        
        if ~isempty(selected_events)
            ievents = find(((n+min(x)) < selected_events(:,2)) & (selected_events(:,1) < (n+min(x)+2)));
            if ~isempty(ievents)
                if exist('hdetct', 'var') && ~isempty(hdetct)
                    delete(hdetct{1})
                end
                kevent = 1;
                for ievent = ievents'
                    hdetct{kevent} = fill(selected_events(ievent,[1 2 2 1]), [y_min y_min y_max y_max], 1, 'facecolor', [0.1 0.5 0.7], 'facealpha', 0.3, 'edgecolor', 'none');
                    kevent = kevent + 1;
                end
            end
        end
    
        % Detected Events
        if ~isempty(events)
            if exist('hevents','var')
                for ii = 1:length(hevents)
                    delete(hevents{ii})
                end
            end
            hevents = cell(0);
            hold on
            k = 1;
            for idetection = 1:size(events,2)
                events_to_plot = find((events{1,idetection}(:,1)>=x(idxs_win(1))) & (events{1,idetection}(:,2)<=x(idxs_win(end))));
                for ievent = events_to_plot'
                    xs = x_events{idetection}{ievent};
                    ys = y_events{idetection}{ievent};
                    % Plot in this window
                    ys_hight = [0 -separate_channels];
                    hevents{k} = plot(xs, amp_y*ys - ys_hight, 'color', cmap(idetection+icmap,:));
                    k = k+1;
                end
            end
        end
        
        % Axis
        xlabel('Time (seg)')
        ylabel('LFP')
        set(gca, 'ytick', [])
        xlim(min(x)+[n, n+2])
        ylim([y_min y_max])
        if ~isempty(events)
            legend(event_names, 'orientation', 'horizontal', 'location', 'northoutside')
        end
        
    end

end