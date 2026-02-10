% plotTwoRegionsTemp.m
% Script to plot absolute temperature over time for two cropped regions from a thermal data file
% Requirements: Telops Toolbox (TelopsRead function)
% Usage: Run the script, select a .hcc file, and crop two regions to compare their absolute temperature profiles

% Clear workspace and close figures
clear;
close all;

% Default parameters
defaultFrameRate = 383; % Hz
windowSize = 50; % Smoothing window size for moving average

% Load thermal data file
[filename, filepath] = uigetfile('*.hcc', 'Select Thermal Data File');
if isequal(filename, 0)
    error('No file selected.');
end
fpath = fullfile(filepath, filename);
try
    readData = TelopsRead(filename, filepath);
    thermaldata = readData.data; % [height, width, frames]
    timeVector = readData.time;
    frameRate = readData.fps;
    if frameRate <= 0 || isnan(frameRate)
        frameRate = defaultFrameRate;
        warning('Invalid frame rate in file. Using default (%.1f Hz).', defaultFrameRate);
    end
catch ME
    error('Error loading file: %s', ME.message);
end

% Get data dimensions
[height, width, numFrames] = size(thermaldata);
if numFrames < 1
    error('No frames available in data.');
end

% Compute time vector if not provided
if isempty(timeVector) || length(timeVector) ~= numFrames
    timeVector = (0:numFrames-1) / frameRate;
end

% Select first region
figure('Name', 'Select First Region');
imshow(thermaldata(:,:,1), []);
title('Select First Cropping Region');
h1 = imrect;
position1 = wait(h1);
close(gcf);

% Extract first region
x1 = max(1, round(position1(1)));
y1 = max(1, round(position1(2)));
width1 = round(position1(3));
height1 = round(position1(4));
if width1 <= 0 || height1 <= 0
    error('Invalid first cropping region: Width and height must be positive.');
end
x1_end = min(x1 + width1 - 1, width);
y1_end = min(y1 + height1 - 1, height);
region1 = thermaldata(y1:y1_end, x1:x1_end, :);

% Select second region
figure('Name', 'Select Second Region');
imshow(thermaldata(:,:,1), []);
title('Select Second Cropping Region');
h2 = imrect;
position2 = wait(h2);
close(gcf);

% Extract second region
x2 = max(1, round(position2(1)));
y2 = max(1, round(position2(2)));
width2 = round(position2(3));
height2 = round(position2(4));
if width2 <= 0 || height2 <= 0
    error('Invalid second cropping region: Width and height must be positive.');
end
x2_end = min(x2 + width2 - 1, width);
y2_end = min(y2 + height2 - 1, height);
region2 = thermaldata(y2:y2_end, x2:x2_end, :);

% Compute average temperature for each region
tempProfile1 = squeeze(mean(region1, [1 2], 'double')); % Mean over height and width
tempProfile2 = squeeze(mean(region2, [1 2], 'double'));

% Apply smoothing
tempProfile1Smoothed = movmean(tempProfile1, windowSize);
tempProfile2Smoothed = movmean(tempProfile2, windowSize);

% Plot
figure('Name', 'Absolute Temperature Over Time for Two Regions');
plot(timeVector, tempProfile1Smoothed, 'b-', 'DisplayName', 'Region 1 (Smoothed)', 'LineWidth', 1.5);
hold on;
plot(timeVector, tempProfile2Smoothed, 'r-', 'DisplayName', 'Region 2 (Smoothed)', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Absolute Temperature (°C)');
title('Average Absolute Temperature in Two Cropped Regions');
legend('Location', 'best');
grid on;
hold off;

% Optional: Save the plot
% saveas(gcf, 'two_regions_absolute_temp_plot.png');