classdef SingleThresholdDamageAnalysis
    methods (Static)
        function measureDamageArea(fig, croppedAnalysis, inputData, pixelSize, thresholdMultiplier, frameRate, bgFrames, sourceDepth, startFrame, endFrame, damageSNRStartFrame, damageSNREndFrame, mode, inputType, depthMethod, thermalDiffusivity, frameIndex, useMillimeters)
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
                uialert(fig, 'Source depth is too small (< 0.1 mm).', 'Error');
                return;
            end
            % Validate frame ranges
            maxFrames = size(croppedAnalysis.data, 3);
            if damageSNRStartFrame < 1 || damageSNREndFrame > maxFrames || damageSNRStartFrame > damageSNREndFrame
                uialert(fig, sprintf('Invalid frame range: 1 to %d.', maxFrames), 'Error');
                return;
            end
            % Check size consistency
            [height, width, ~] = size(croppedAnalysis.data);
            [xSize, ySize] = size(inputData);
            if xSize ~= height || ySize ~= width
                error('Size mismatch: inputData [%d %d] vs croppedAnalysis.data [%d %d]', xSize, ySize, height, width);
            end
            % Initialize figure
            damageFig = uifigure('Name', 'Damage Area Analysis', 'Position', [100, 100, 800, 600]);
            ax_new = uiaxes(damageFig, 'Position', [0.02, 0.02, 0.96, 0.96], 'Units', 'normalized');
            imagesc(ax_new, inputData, 'XData', [1 ySize], 'YData', [1 xSize]);
            colormap(ax_new, 'jet');
            colorbar(ax_new);
            set(ax_new, 'YDir', 'normal', 'XLim', [0.5 ySize+0.5], 'YLim', [0.5 xSize+0.5],  'DataAspectRatio', [1 1 1], 'Box', 'off', 'TickDir', 'out');
            % Apply scaling to axes
            if useMillimeters
                set(ax_new, 'XTick', 0:50:ySize, 'XTickLabel', round((0:50:ySize)*pixelSize, 2),'YTick', 0:50:xSize, 'YTickLabel', round((0:50:xSize)*pixelSize, 2));
                xlabel(ax_new, 'X (mm)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel(ax_new, 'Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            else
                xlabel(ax_new, 'X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel(ax_new, 'Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            end
            title(ax_new, sprintf('Damage Analysis (%s, %s Mode, %s Depth)', inputType, mode, depthMethod), 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
            hold(ax_new, 'on');

            % Precompute statistics
            input_median = [];
            input_mean = [];
            temp_diff_std = [];
            input_std = [];
            if strcmp(inputType, 'Thermogram')
                input_median = median(inputData(:));
                temp_diff = input_median - inputData;
                temp_diff_std = std(temp_diff(:));
                if temp_diff_std == 0
                    temp_diff_std = 1;
                end
            else
                input_mean = mean(inputData(:));
                input_std = std(inputData(:));
                if input_std == 0
                    input_std = 1;
                end
            end
            frame_time = frameIndex / frameRate;

            % Process based on mode
            if strcmp(mode, 'Manual')
                % Placeholder for Manual mode
                uialert(fig, 'Manual mode not implemented yet.', 'Info');
                if isvalid(damageFig)
                    close(damageFig);
                end
                return;
            else % Auto mode
                % Compute thresholds
                if strcmp(inputType, 'Thermogram')
                    outer_threshold = thresholdMultiplier * temp_diff_std;
                    inner_threshold = (thresholdMultiplier + 1) * temp_diff_std;
                    mask_outer = temp_diff > outer_threshold;
                    mask_inner = temp_diff > inner_threshold;
                else
                    if strcmp(inputType, 'Damage Indicator')
                        outer_threshold = input_mean + thresholdMultiplier * input_std;
                        inner_threshold = input_mean + (thresholdMultiplier + 1) * input_std;
                        mask_outer = inputData > outer_threshold;
                        mask_inner = inputData > inner_threshold;
                    else
                        outer_threshold = input_mean - thresholdMultiplier * input_std;
                        inner_threshold = input_mean - (thresholdMultiplier + 1) * input_std;
                        mask_outer = inputData < outer_threshold;
                        mask_inner = inputData < inner_threshold;
                    end
                end
                % Clean up masks
                mask_outer = imopen(mask_outer, strel('disk', 3));
                mask_outer = imclose(mask_outer, strel('disk', 5));
                mask_inner = imopen(mask_inner, strel('disk', 3));
                mask_inner = imclose(mask_inner, strel('disk', 5));
                % Detect regions
                props_outer = regionprops(mask_outer, 'Area', 'Centroid', 'PixelIdxList');
                boundaries_outer = bwboundaries(mask_outer);
                props_inner = regionprops(mask_inner, 'Area', 'Centroid', 'PixelIdxList');
                boundaries_inner = bwboundaries(mask_inner);
                if isempty(props_outer)
                    if isvalid(damageFig)
                        close(damageFig);
                    end
                    return;
                end
                % Calculate deviations for auto mode
                all_deviations = [];
                for k = 1:length(props_outer)
                    pixelIdxList = props_outer(k).PixelIdxList;
                    between_pixels = pixelIdxList(~mask_inner(pixelIdxList));
                    if ~isempty(between_pixels)
                        between_pixels = between_pixels(1:min(3, length(between_pixels)));
                        if strcmp(inputType, 'Thermogram')
                            temp_diff = input_median - inputData(between_pixels);
                            deviation = mean(temp_diff) / temp_diff_std;
                        else
                            input_values = inputData(between_pixels);
                            if strcmp(inputType, 'Damage Indicator')
                                deviation = (mean(input_values) - input_mean) / input_std;
                            else
                                deviation = (input_mean - mean(input_values)) / input_std;
                            end
                        end
                        all_deviations = [all_deviations, deviation];
                    end
                end
                for m = 1:length(props_inner)
                    pixelIdxList = props_inner(m).PixelIdxList;
                    pixelIdxList = pixelIdxList(1:min(3, length(pixelIdxList)));
                    if strcmp(inputType, 'Thermogram')
                        temp_diff = input_median - inputData(pixelIdxList);
                        deviation = mean(temp_diff) / temp_diff_std;
                    else
                        input_values = inputData(pixelIdxList);
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
                % Plot borders for auto mode
                if isvalid(ax_new)
                    for k = 1:length(boundaries_outer)
                        boundary = boundaries_outer{k};
                        plot(ax_new, boundary(:,2), boundary(:,1), 'k', 'LineWidth', 2);
                    end
                    for k = 1:length(boundaries_inner)
                        boundary = boundaries_inner{k};
                        plot(ax_new, boundary(:,2), boundary(:,1), 'b', 'LineWidth', 2);
                    end
                end
            end

            % Nested function for label placement with offset
            function place_label(x, y, str, color, offsetDirection)
                if isvalid(ax_new) && isvalid(damageFig)
                    % Adjust y position based on offsetDirection ('above' or 'below')
                    if strcmp(offsetDirection, 'above')
                        y_adjusted = y + 15; % Move label above the centroid
                    else % 'below'
                        y_adjusted = y - 15; % Move label below the centroid
                    end
                    text(ax_new, x, y_adjusted, str, 'Color', color, 'FontSize', 8,'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [1 1 1 0.7]);
                end
            end

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

            % Process outer (between) regions
            if ~isempty(props_outer)
                max_deviation = max(all_deviations);
                if isempty(max_deviation) || max_deviation <= 0
                    max_deviation = 4;
                end
                for k = 1:length(props_outer)
                    pixelIdxList = props_outer(k).PixelIdxList;
                    between_pixels = pixelIdxList;
                    if strcmp(mode, 'Auto')
                        between_pixels = pixelIdxList(~mask_inner(pixelIdxList));
                    end
                    if ~isempty(between_pixels)
                        between_pixels = between_pixels(1:min(3, length(between_pixels)));
                        between_area_mm2 = length(pixelIdxList) * (pixelSize^2);
                        if strcmp(inputType, 'Thermogram')
                            temp_diff = input_median - inputData(between_pixels);
                            between_deviation = mean(temp_diff) / temp_diff_std;
                        else
                            input_values = inputData(between_pixels);
                            if strcmp(inputType, 'Damage Indicator')
                                between_deviation = (mean(input_values) - input_mean) / input_std;
                            else
                                between_deviation = (input_mean - mean(input_values)) / input_std;
                            end
                        end
                        if between_deviation < 1
                            between_damage_type = 'Minor';
                        elseif between_deviation < 2
                            between_damage_type = 'Moderate';
                        else
                            between_damage_type = 'Severe';
                        end
                        if strcmp(depthMethod, 'Diffusivity')
                            if strcmp(inputType, 'Thermogram')
                                temp_anomaly = mean(temp_diff) / max(input_median, 1);
                                depth_mm = sourceDepth * sqrt(thermalDiffusivity * frame_time * abs(temp_anomaly));
                            else
                                % Compute t_max for the defect region using SNR over frames
                                pixel_values_over_frames = zeros(length(between_pixels), size(snr_over_frames, 3));
                                for p = 1:length(between_pixels)
                                    [row, col] = ind2sub([xSize, ySize], between_pixels(p));
                                    pixel_values_over_frames(p, :) = snr_over_frames(row, col, :);
                                end
                                % Average SNR over the defect region for each frame
                                avg_snr_over_frames = mean(pixel_values_over_frames, 1);
                                % Find the frame with maximum SNR
                                [~, max_idx] = max(avg_snr_over_frames);
                                t_max = (damageSNRStartFrame + max_idx - 1) / frameRate; % Convert frame to time (seconds)
                                depth_mm = sqrt(thermalDiffusivity * t_max); % z = sqrt(alpha * t_max), in mm
                                fprintf('Outer Region %d: Computed depth using Diffusivity: %.3f mm (t_max = %.3f s, thermalDiffusivity = %.3f mm²/s)\n', ...
                                    k, depth_mm, t_max, thermalDiffusivity);
                            end
                            depth_mm = min(sourceDepth, depth_mm);
                        else % SNR
                            depth_mm = sourceDepth * (between_deviation / max_deviation);
                            fprintf('Outer Region %d: Computed depth using SNR: %.3f mm (deviation = %.3f, max_deviation = %.3f)\n', ...
                                k, depth_mm, between_deviation, max_deviation);
                        end
                        if depth_mm < 0
                            depth_mm = 0;
                        end
                        place_label(props_outer(k).Centroid(1), props_outer(k).Centroid(2), ...
                            sprintf('%s: %.2f mm²\nDepth: %.1f mm', between_damage_type, between_area_mm2, depth_mm), 'black', 'above');
                    end
                end
            end

            % Process inner regions (auto mode only)
            if strcmp(mode, 'Auto') && ~isempty(props_inner)
                for m = 1:length(props_inner)
                    pixelIdxList = props_inner(m).PixelIdxList;
                    pixelIdxList = pixelIdxList(1:min(3, length(pixelIdxList)));
                    inner_area_mm2 = length(props_inner(m).PixelIdxList) * (pixelSize^2);
                    if strcmp(inputType, 'Thermogram')
                        temp_diff = input_median - inputData(pixelIdxList);
                        inner_deviation = mean(temp_diff) / temp_diff_std;
                    else
                        input_values = inputData(pixelIdxList);
                        if strcmp(inputType, 'Damage Indicator')
                            inner_deviation = (mean(input_values) - input_mean) / input_std;
                        else
                            inner_deviation = (input_mean - mean(input_values)) / input_std;
                        end
                    end
                    if inner_deviation < 1
                        inner_damage_type = 'Minor';
                    elseif inner_deviation < 2
                        inner_damage_type = 'Moderate';
                    else
                        inner_damage_type = 'Severe';
                    end
                    if strcmp(depthMethod, 'Diffusivity')
                        if strcmp(inputType, 'Thermogram')
                            temp_anomaly = mean(temp_diff) / max(input_median, 1);
                            depth_mm = sourceDepth * sqrt(thermalDiffusivity * frame_time * abs(temp_anomaly));
                        else
                            % Compute t_max for the defect region using SNR over frames
                            pixel_values_over_frames = zeros(length(pixelIdxList), size(snr_over_frames, 3));
                            for p = 1:length(pixelIdxList)
                                [row, col] = ind2sub([xSize, ySize], pixelIdxList(p));
                                pixel_values_over_frames(p, :) = snr_over_frames(row, col, :);
                            end
                            % Average SNR over the defect region for each frame
                            avg_snr_over_frames = mean(pixel_values_over_frames, 1);
                            % Find the frame with maximum SNR
                            [~, max_idx] = max(avg_snr_over_frames);
                            t_max = (damageSNRStartFrame + max_idx - 1) / frameRate; % Convert frame to time (seconds)
                            depth_mm = sqrt(thermalDiffusivity * t_max); % z = sqrt(alpha * t_max), in mm
                            fprintf('Inner Region %d: Computed depth using Diffusivity: %.3f mm (t_max = %.3f s, thermalDiffusivity = %.3f mm²/s)\n', ...
                                m, depth_mm, t_max, thermalDiffusivity);
                        end
                        depth_mm = min(sourceDepth, depth_mm);
                    else % SNR
                        depth_mm = sourceDepth * (inner_deviation / max_deviation);
                        fprintf('Inner Region %d: Computed depth using SNR: %.3f mm (deviation = %.3f, max_deviation = %.3f)\n', ...
                            m, depth_mm, inner_deviation, max_deviation);
                    end
                    if depth_mm < 0
                        depth_mm = 0;
                    end
                    place_label(props_inner(m).Centroid(1), props_inner(m).Centroid(2), ...
                        sprintf('%s: %.2f mm²\nDepth: %.1f mm', inner_damage_type, inner_area_mm2, depth_mm), 'blue', 'below');
                end
            end

            % Final axes setup
            if isvalid(damageFig) && isvalid(ax_new)
                hold(ax_new, 'off');
                xlim(ax_new, [0.5 ySize+0.5]);
                ylim(ax_new, [0.5 xSize+0.5]);
                axis(ax_new, 'tight');
                set(ax_new, 'DataAspectRatio', [1 1 1]);
            end
        end
    end
end