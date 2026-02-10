classdef QuantifyDamage
    methods(Static)
        function quantifyDamage(fig, croppedAnalysis, inputData, pixelSize, thresholdMultiplier, thermalDiffusivity, frameRate, bgFrames, sourceDepth, damageSNRStartFrame, damageSNREndFrame, inputType, depthMethod)
            % Input validation
            if isempty(croppedAnalysis)
                uialert(fig, 'Crop data first.', 'Error');
                return;
            end
            if isempty(inputData)
                uialert(fig, 'Generate input data first.', 'Error');
                return;
            end
            if frameRate <= 0 || pixelSize <= 0 || thresholdMultiplier < 0
                uialert(fig, 'Frame rate, pixel size, and threshold multiplier must be positive.', 'Error');
                return;
            end
            if sourceDepth < 0.1
                uialert(fig, 'Source depth is too small (< 0.1 mm). Please set a larger value in the GUI.', 'Error');
                return;
            end
            
            % Validate frame ranges
            maxFrames = size(croppedAnalysis.data, 3);
            if damageSNRStartFrame < 1 || damageSNREndFrame > maxFrames || damageSNRStartFrame > damageSNREndFrame
                uialert(fig, sprintf('Invalid frame range for damage analysis: Must be between 1 and %d.', maxFrames), 'Error');
                return;
            end
            
            % Check size consistency
            [height, width, ~] = size(croppedAnalysis.data);
            [xSize, ySize] = size(inputData);
            if xSize ~= height || ySize ~= width
                error('Size mismatch: inputData [%d %d] vs croppedAnalysis.data [%d %d]', xSize, ySize, height, width);
            end
            
            % Compute thresholds
            if strcmp(inputType, 'Thermogram')
                input_median = median(inputData(:));
                temp_diff = input_median - inputData;
                temp_diff_std = std(temp_diff(:));
                if temp_diff_std == 0
                    temp_diff_std = 1;
                end
                disp(['QuantifyDamage: temp_diff size = ', num2str(size(temp_diff))]);
            else
                input_mean = mean(inputData(:));
                input_std = std(inputData(:));
                if input_std == 0
                    input_std = 1;
                end
            end
            
            % Initialize parameters
            numFrames = size(croppedAnalysis.data, 3);
            pulseStartTime = (bgFrames / frameRate) + 0.080;
            time = (0:numFrames-1) / frameRate;
            used_pixels = false(xSize, ySize);
            disp(['QuantifyDamage: used_pixels size = ', num2str(size(used_pixels))]);
            table_data = {};
            region_counter = 0;
            
            % Compute SNR over frame range for non-Thermogram inputs
            snr_over_frames = [];
            if ~strcmp(inputType, 'Thermogram')
                % Compute per-pixel SNR for each frame in the range
                snr_over_frames = zeros(xSize, ySize, damageSNREndFrame - damageSNRStartFrame + 1);
                for frame = damageSNRStartFrame:damageSNREndFrame
                    idx = frame - damageSNRStartFrame + 1;
                    frameData = croppedAnalysis.data(:,:,frame);
                    % Apply filters if necessary (simplified for this example)
                    % In your script, you use applyFilters, but for simplicity, we'll skip filtering here
                    % Compute SNR for the frame (simplified version of generateHeatmaps logic)
                    signal_power = mean(frameData, 'all')^2;
                    noise_power = var(frameData, 0, 'all');
                    snr_over_frames(:,:,idx) = 10 * log10(signal_power ./ (noise_power + eps));
                end
            end
            
            % Hierarchical detection from 6 SD to 1 SD
            all_deviations = [];
            for sd = 6:-1:1
                if strcmp(inputType, 'Thermogram')
                    threshold = sd * temp_diff_std;
                    mask = temp_diff > threshold & ~used_pixels;
                else
                    if strcmp(inputType, 'Damage Indicator')
                        threshold = input_mean + sd * input_std;
                        mask = inputData > threshold & ~used_pixels;
                    else
                        threshold = input_mean - sd * input_std;
                        mask = inputData < threshold & ~used_pixels;
                    end
                end
                mask = imopen(mask, strel('disk', 3));
                mask = imclose(mask, strel('disk', 5));
                
                props = regionprops(mask, 'Area', 'PixelIdxList');
                
                if isempty(props)
                    continue;
                end
                
                % Calculate deviations
                for k = 1:length(props)
                    if strcmp(inputType, 'Thermogram')
                        temp_diff_values = temp_diff(props(k).PixelIdxList);
                        deviation = mean(temp_diff_values) / temp_diff_std;
                    else
                        input_values = inputData(props(k).PixelIdxList);
                        if strcmp(inputType, 'Damage Indicator')
                            deviation = (mean(input_values) - input_mean) / input_std;
                        else
                            deviation = (input_mean - mean(input_values)) / input_std;
                        end
                    end
                    all_deviations = [all_deviations, deviation];
                end
                
                max_deviation = max(all_deviations);
                if max_deviation <= 0
                    max_deviation = 4;
                end
                
                for k = 1:length(props)
                    region_counter = region_counter + 1;
                    used_pixels(props(k).PixelIdxList) = true;
                    
                    area_mm2 = props(k).Area * (pixelSize^2);
                    if strcmp(inputType, 'Thermogram')
                        temp_diff_values = temp_diff(props(k).PixelIdxList);
                        deviation = mean(temp_diff_values) / temp_diff_std;
                    else
                        input_values = inputData(props(k).PixelIdxList);
                        if strcmp(inputType, 'Damage Indicator')
                            deviation = (mean(input_values) - input_mean) / input_std;
                        else
                            deviation = (input_mean - mean(input_values)) / input_std;
                        end
                    end
                    
                    if deviation < 1
                        damage_type = 'Minor';
                        damage_description = 'Porosity';
                    elseif deviation < 2
                        damage_type = 'Moderate';
                        damage_description = 'Delamination';
                    else
                        damage_type = 'Severe';
                        damage_description = 'Void';
                    end
                    
                    if strcmp(depthMethod, 'Diffusivity')
                        if strcmp(inputType, 'Thermogram')
                            temp_anomaly = mean(temp_diff_values) / max(input_median, 1);
                            depth_mm = sourceDepth * sqrt(thermalDiffusivity * abs(temp_anomaly));
                        else
                            % Compute t_max for the defect region using SNR over frames
                            pixel_values_over_frames = zeros(length(props(k).PixelIdxList), size(snr_over_frames, 3));
                            for p = 1:length(props(k).PixelIdxList)
                                [row, col] = ind2sub([xSize, ySize], props(k).PixelIdxList(p));
                                pixel_values_over_frames(p, :) = snr_over_frames(row, col, :);
                            end
                            % Average SNR over the defect region for each frame
                            avg_snr_over_frames = mean(pixel_values_over_frames, 1);
                            % Find the frame with maximum SNR
                            [~, max_idx] = max(avg_snr_over_frames);
                            t_max = (damageSNRStartFrame + max_idx - 1) / frameRate; % Convert frame to time (seconds)
                            depth_mm = sqrt(thermalDiffusivity * t_max); % z = sqrt(alpha * t_max), in mm
                            fprintf('Region %d: Computed depth using Diffusivity: %.3f mm (t_max = %.3f s, thermalDiffusivity = %.3f mm²/s)\n', ...
                                region_counter, depth_mm, t_max, thermalDiffusivity);
                        end
                        depth_mm = min(sourceDepth, depth_mm);
                    else % SNR
                        depth_mm = sourceDepth * (deviation / max_deviation);
                        fprintf('Region %d: Computed depth using SNR: %.3f mm (deviation = %.3f, max_deviation = %.3f)\n', ...
                            region_counter, depth_mm, deviation, max_deviation);
                    end
                    if depth_mm < 0
                        depth_mm = 0;
                    end
                    
                    table_data = [table_data; {region_counter, sd, area_mm2, depth_mm, deviation, damage_type, damage_description}];
                end
            end
            
            if isempty(table_data)
                uialert(fig, 'No damage regions detected across 1 to 6 SD.', 'Warning');
                return;
            end
            
            quantFig = uifigure('Name', sprintf('Damage Quantification Results (%s, 1 to 6 SD)', inputType), 'Position', [200, 200, 700, 400]);
            uilabel(quantFig, 'Position', [10, 360, 680, 30], ...
                    'Text', 'Damage Quantification', ...
                    'FontName', 'Arial', 'FontSize', 16, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
            
            uitable(quantFig, 'Data', table_data, ...
                    'ColumnName', {'Region #', 'SD Threshold', 'Area (mm²)', 'Depth (mm)', 'Deviation', 'Damage Type', 'Description'}, ...
                    'Position', [20, 50, 660, 300]);
            
            uibutton(quantFig, 'Position', [20, 10, 100, 30], 'Text', 'Export Data', 'ButtonPushedFcn', @exportData);
            
            function exportData(~, ~)
                [file, path] = uiputfile('*.csv', 'Save Damage Quantification Data', sprintf('damage_quantification_%s.csv', lower(inputType)));
                if isequal(file, 0)
                    return;
                end
                fullpath = fullfile(path, file);
                columnNames = {'Region_Number', 'SD_Threshold', 'Area_mm2', 'Depth_mm', 'Deviation', 'Damage_Type', 'Damage_Description'};
                export_table = cell2table(table_data, 'VariableNames', columnNames);
                writetable(export_table, fullpath);
                uialert(fig, sprintf('Data exported to %s', fullpath), 'Success');
            end
        end
    end
end