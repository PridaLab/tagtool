# tagtool

Tagtool is a MATLAB tool to manually tag LFP events. It prompts a GUI that shows the LFP profile in windows of 2 seconds, and is prepared to mark the beginning and end of events by clicking on the screen. Events are saved even if the program is killed or closed, so if it is run again, it will go to the last tagged event. Every time that an event is tagged, their beginning and ending times are written in a .txt file.

The steps to mark the events are:

- Every time you want to tag an event, you have to:
  - **Select new event**: press `d` on the keyboard, or click “New event” button
  - **End selecting new event**: press `f` on the keyboard, or click “Done” button
  
- If you want to remove the last tagged event:
  - **Remove last event**: press `b` on the keyboard, or click “Remove last” button
  
- In order to slide the window to display the next 2 seconds:
  - **Forward**: press `t` on the keyboard, or click anywhere forward in the bottom slider
  - **Backward**: press `q` on the keyboard, or click anywhere backwards in the bottom slider. If you prefer to just move 1 second, please click the arrows at the beginning and end tops of the slider.

The GUI is presented calling the function tagtool. Its inputs are:
  - `LFP`: LFP signal to plot (timestamps x channels)
  - `file_name`: Full path and name of the file that will save tagged events (in seconds, if sf provided, timestamps if not)
  - `sf` (optional): Sampling frequency. By default is 30 kHz, but downsampling is recommended for speed purposes.
  - `chunk_min` (optional): To keep the spirits up in long recordings, it is good to divide the full recording in shorter chunks, to see the process of the tagging. By default, the LFP will be divided in chunks of 5 minutes, but it is modifiable. If the program is closed, and then re-run, all chunks will be re-shown on the window of the last tagged event of that chunk. When a chunk is finished, just click “END AND CLOSE”.
  - `events` (optional): Previously detected events (such events detected by a filter or a CNN) can be plotted in the GUI. This optional input has to be a cell array, in which each cell needs to contain a matrix (# events x 2) with two columns indicating beginning and end (in seconds) of each detection.
  - `event_names` (optional): Names characterizing each group of events of the variable `events`.
  - `channels` (optional): Cell array, indicating what channels you like to be displayed. Channels annotated in different cells will be displayed with some separation, useful to display different shanks.
    - Eg1. Probe with 4 shanks of 8 channels each: channels = {1:8, 9:16, 17:24, 25:32}.
    - Eg2. Probe with 2 shanks of 10 and 20 each, but only want to see the first 5 of each shank: channels = {1:5, 11:16}.
    If it's not provided, all channels will be plotted.

There is a main script called `usage_example.m` that shows how to use the tool. 

Before running, please remind that some variables, some of which are the just descrived above, need to be specified. 
