function data = perpl_LoadBinary(filename,varargin)

%bz_LoadBinary - Load data from a multiplexed binary file.
%
%  Reading a subset of the data can be done in two different manners: either
%  by specifying start time and duration (more intuitive), or by indicating
%  the position and size of the subset in terms of number of samples per
%  channel (more accurate).
%
%  USAGE
%
%    data = bz_LoadBinary(filename,<options>)
%
%    filename       file to read
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%    -------------------------------------------------------------------------
%     'frequency'   sampling rate (in Hz, default = 20kHz)
%     'start'       position to start reading (in s, default = 0)
%     'duration'    duration to read (in s, default = Inf)
%     'offset'      position to start reading (in samples per channel,
%                   default = 0)
%     'samples'     number of samples (per channel) to read (default = Inf)
%     'nChannels'   number of data channels in the file (default = 1)
%     'channels'    channels to read, base 1 (default = all)
%     'precision'   sample precision (default = 'int16')
%     'skip'        number of bytes to skip after each value is read
%                   (default = 0)
%     'downsample'  factor by which to downample by (default = 1)
%     'bitVolts'    if provided LFP will be converted to double precision
%     with this factor
%    =========================================================================

% Copyright (C) 2004-2011 by Michaël Zugaro
% Modified by Saman Abbaspoor
%Modified by DLevenstein 2016 to include downsampling
% bz_ added to function name by Luke Sjulson 2017 to fix namespace issues
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.

p = inputParser;
addParameter(p,'frequency',30000,@isdscalar)           
addParameter(p,'start',0,@isdscalar)           
addParameter(p,'duration',0,@isnumeric)
addParameter(p,'offset',0,@isiscalar)
addParameter(p,'samples',0,@isnumeric)
addParameter(p,'nChannels',1,@isiscalar)
addParameter(p,'channels',[1],@isivector)
addParameter(p,'precision','int16',@isa)
addParameter(p,'skip',0,@isiscalar)
addParameter(p,'downsample',1,@isiscalar)
addParameter(p,'filter_freq_range',[],@isivector)
addParameter(p,'bitVolts',0,@isnumeric) % for our data it is: 0.195
parse(p,varargin{:})

frequency       = p.Results.frequency;
start           = p.Results.start;
duration        = p.Results.duration;
offset          = p.Results.offset;
nSamplesPerChannel   = p.Results.samples;
nChannels       = p.Results.nChannels;
channels        = p.Results.channels;
precision       = p.Results.precision;
skip            = p.Results.skip;
downsamplefactor      = p.Results.downsample;
bitVolts        = p.Results.bitVolts;


time = false; samples = false;
if duration>0; time = true; end
if nSamplesPerChannel>0; samples = true; end

% Either start+duration, or offset+size
if time && samples,
	error(['Data subset can be specified either in time or in samples, but not both (type ''help <a href="matlab:help bz_LoadBinary">bz_LoadBinary</a>'' for details).']);
end

% By default, load all channels
if isempty(channels),
	channels = 1:nChannels;
end

% Check consistency between channel IDs and number of channels
if any(channels>nChannels),
	error('Cannot load specified channels (listed channel IDs inconsistent with total number of channels).');
end

% Open file
if ~exist(filename),
	error(['File ''' filename ''' not found.']);
end
f = fopen(filename,'r');
if f == -1,
	error(['Cannot read ' filename ' (insufficient access rights?).']);
end

% Size of one data point (in bytes)
sampleSize = 0;
switch precision,
	case {'uchar','unsigned char','schar','signed char','int8','integer*1','uint8','integer*1'},
		sampleSize = 1;
	case {'int16','integer*2','uint16','integer*2'},
		sampleSize = 2;
	case {'int32','integer*4','uint32','integer*4','single','real*4','float32','real*4'},
		sampleSize = 4;
	case {'int64','integer*8','uint64','integer*8','double','real*8','float64','real*8'},
		sampleSize = 8;
end

% Position and number of samples (per channel) of the data subset
if time,
	dataOffset = floor(start*frequency)*nChannels*sampleSize;
	nSamplesPerChannel = round((duration*frequency));
else
	dataOffset = offset*nChannels*sampleSize;
end

% Position file index for reading
status = fseek(f,dataOffset,'bof');
if status ~= 0,
	fclose(f);
	error('Could not start reading (possible reasons include trying to read past the end of the file).');
end

% Determine total number of samples in file
fileStart = ftell(f);
status = fseek(f,0,'eof');
if status ~= 0,
	fclose(f);
	error('Error reading the data file (possible reasons include trying to read past the end of the file).');
end
fileStop = ftell(f);
% (floor in case all channels do not have the same number of samples)
maxNSamplesPerChannel = floor(((fileStop-fileStart)/nChannels/sampleSize));
frewind(f);
status = fseek(f,dataOffset,'bof');
if status ~= 0,
	fclose(f);
	error('Could not start reading (possible reasons include trying to read past the end of the file).');
end

if isinf(nSamplesPerChannel) || nSamplesPerChannel > maxNSamplesPerChannel,
	nSamplesPerChannel = maxNSamplesPerChannel;
end

if downsamplefactor>1
%     precision = [num2str(nChannels),'*',precision]; % this line is
%     incorrect, the precision variable is a string that does not depend on
%     the number of channels
    skip = nChannels*(downsamplefactor-1)*sampleSize;
    nSamplesPerChannel = floor(nSamplesPerChannel./downsamplefactor);
end


% For large amounts of data, read chunk by chunk
maxSamplesPerChunk = 10000;
nSamples = nSamplesPerChannel*nChannels;
if nSamples <= maxSamplesPerChunk,
	data = LoadChunk(f,nChannels,channels,nSamples/nChannels,precision,skip);
    if bitVolts > 0; data = double(data)*bitVolts; end
else
	% Determine chunk duration and number of chunks
	nSamplesPerChunk = floor(maxSamplesPerChunk/nChannels)*nChannels;
	nChunks = floor(nSamples/nSamplesPerChunk);
	% Preallocate memory
    if bitVolts == 0
        data = zeros(nSamplesPerChannel,length(channels),precision);
    elseif bitVolts > 0
        data = zeros(nSamplesPerChannel,length(channels));
    end
	% Read all chunks
	i = 1;
	for j = 1:nChunks,
		d = LoadChunk(f,nChannels,channels,nSamplesPerChunk/nChannels,precision,skip);
        if bitVolts > 0; d = double(d)*bitVolts; end
		[m,n] = size(d);
		if m == 0, break; end
		data(i:i+m-1,:) = d;
		i = i+m;
	end
	% If the data size is not a multiple of the chunk size, read the remainder
	remainder = nSamples - nChunks*nSamplesPerChunk;
	if remainder ~= 0,
		d = LoadChunk(f,nChannels,channels,remainder/nChannels,precision,skip);
        if bitVolts > 0; d = double(d)*bitVolts; end
		[m,n] = size(d);
		if m ~= 0,
			data(i:i+m-1,:) = d;
		end
	end
end

fclose(f);

% ---------------------------------------------------------------------------------------------------------

function data = LoadChunk(fid,nChannels,channels,nSamples,precision,skip)

if skip ~= 0,
	data = fread(fid,[nChannels nSamples],[num2str(nChannels),'*',precision '=>' precision],skip);
    %data = fread(fid,[nChannels nSamples],[num2str(nChannels),'*',precision],nChannels*skip);
else
	data = fread(fid,[nChannels nSamples],[precision '=>' precision]);
end
data=data';

if isempty(data),
	warning('No data read (trying to read past file end?)');
elseif ~isempty(channels),
	data = data(:,channels);
end
