function [ s ] = TelopsRead( filename, filepath )
% Author: Geir Olafsson 
% Affiliation: Univesity of Bristol

%TelopsRead - reads in thermal data (in degrees Celcius from a .hcc file
%from Telops infrared detector. Filename should include path for best
%results. Output is y pixels, x pixels, time 3D array. 

%Ensure that telops toolbox is installed prior to use. 

% Headers is optional output if required. 


fprintf('\n-------------------------------------------------------\n')
fprintf(['Reading in ',filename,' Telops data...\n'])

%% Check to make sure the toolbox has been installed 
fprintf('Validating toolbox install...\n')

InstallCheck = exist('readIRCam','file');

if InstallCheck == 6
    fprintf('Toolbox found\n')  
else
    fprintf('Error - IRRead Function not found.\n')
    fprintf('Please check Telops Toolbox is installed. Please contact Telops for latest version\n')
end    

id = 'Telops:XmlMinorVersionMismatch';
warning('off',id);
id = 'MATLAB:nargchk:deprecated';
warning('off',id);
clearvars id 


%% Read in data 
fprintf('Reading data...\n')

if ~strcmp(filename(end-3:end),'.hcc')
    filename = [filename,'.hcc'];
    fprintf('Assumed .hcc file extention has been added to filename\n')
end

% Store filename 
s.filename = filename;

% Build full file path 
fold = fullfile(filepath,filename);

% Read IR data 
[data2D,s.headers,s.frames] = readIRCam(fold);

if isnan(data2D) 
    fprintf('NaN data found')
end

disp(size(s.headers));
% Reshape to expected 3D array (256,320,time)
s.data = formImage(s.headers(1,:), data2D)-s.headers(1).DataOffset;

%% Correct for bad pixels by averaging 3x3 neighbours
fprintf('Replacing bad pixel data with 3x3 neighbour average...\n')

% Set bad pixel coordinates
x = [57,106,133,133,304];
y = [46,162,166,168,127];

% Replace each bad pixel 
for i = 1:length(x)
    
    % Set bad pixels to nan so their value does not affect the average
    s.data(y(i),x(i),:) = nan;
    
    % Calculate mean over 3x3 neighbours 
    replacement = squeeze(nanmean(nanmean(s.data(y(i)-1:y(i)+1,x(i)-1:x(i)+1,:))));
    
    % Replace mean 
    s.data(y(i),x(i),:) = replacement;

end

%% Build time vector 
fprintf('Building time vector...\n')

tStamp = double([s.headers.POSIXTime]);

t = zeros(length(tStamp),6);

for i = 1: length(s.data)
%     tm = cellfun(@(c) str2double(c),strsplit(tStamp,':'));
%     time(i,:) = datevec(tm(1)+datenum(2016,0,0,tm(2),tm(3),tm(4)));
    t(i,:) = datevec(datetime(s.headers(i).POSIXTime, 'ConvertFrom', 'posixtime'));
    
    t(i,6) = str2double(strcat(num2str(t(i,6)),'.',num2str(s.headers(i).SubSecondTime,'%07.f')));
end 

timeDiff = diff(t);

ind = find(timeDiff(:,5)>0);

% Add 60 seconds where time goes over a minute
timeDiff(ind,6) = timeDiff(ind,6)+60;

% Add up difference to find total time 
s.totalTime = sum(timeDiff(:,6));

% Cumulatively sum the time intervals and add a zero to build time vector
s.time = [0;cumsum(timeDiff(:,6))]';


%% Extract Load Data 
fprintf('Extracting ADC Data...\n')
s.load.data = double([s.headers.ADCReadout]);

%% Extract Frame Rate 
s.fps = s.headers(1).AcquisitionFrameRate;

fprintf('Read Complete')
fprintf('\n-------------------------------------------------------\n')

end

