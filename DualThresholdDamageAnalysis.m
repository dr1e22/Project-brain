classdef DualThresholdDamageAnalysis
    methods (Static)
        function measureDamageArea(fig, croppedAnalysis, inputData, pixelSize, thresholdMultiplier, frameRate, bgFrames, sourceDepth, startFrame, endFrame, damageSNRStartFrame, damageSNREndFrame, mode, inputType, depthMethod, thermalDiffusivity, frameIndex, useMillimeters)
            % -------------------------------------------------------------
            % INPUT VALIDATION
            % -------------------------------------------------------------
            if isempty(croppedAnalysis)
                uialert(fig, 'Crop data first.', 'Error'); return;
            end
            if isempty(inputData)
                uialert(fig, 'Generate input data first.', 'Error'); return;
            end
            if frameRate <= 0 || pixelSize <= 0 || thresholdMultiplier < 0
                uialert(fig, 'Frame rate, pixel size, and threshold multiplier must be positive.', 'Error'); return;
            end
            if sourceDepth < 0.1
                uialert(fig, 'Source depth is too small (< 0.1 mm).', 'Error'); return;
            end
            maxFrames = size(croppedAnalysis.data, 3);
            if damageSNRStartFrame < 1 || damageSNREndFrame > maxFrames || damageSNRStartFrame > damageSNREndFrame
                uialert(fig, sprintf('Invalid frame range: 1 to %d.', maxFrames), 'Error'); return;
            end
            [height, width, ~] = size(croppedAnalysis.data);
            [xSize, ySize] = size(inputData);
            if xSize ~= height || ySize ~= width
                error('Size mismatch: inputData [%d %d] vs croppedAnalysis.data [%d %d]', xSize, ySize, height, width);
            end
            % -------------------------------------------------------------
            % CREATE FIGURE
            % -------------------------------------------------------------
            damageFig = uifigure('Name', 'Damage Area Analysis', 'Position', [100 100 800 600]);
            ax_new = uiaxes(damageFig, 'Position', [0.02 0.02 0.96 0.96], 'Units', 'normalized');
            imagesc(ax_new, inputData, 'XData', [1 ySize], 'YData', [1 xSize]);
            colormap(ax_new, 'jet'); colorbar(ax_new);
            set(ax_new, 'YDir', 'normal', 'XLim', [0.5 ySize+0.5], 'YLim', [0.5 xSize+0.5], ...
                'DataAspectRatio', [1 1 1], 'Box', 'off', 'TickDir', 'out');
            if useMillimeters
                set(ax_new, 'XTick', 0:50:ySize, 'XTickLabel', round((0:50:ySize)*pixelSize, 2), ...
                    'YTick', 0:50:xSize, 'YTickLabel', round((0:50:xSize)*pixelSize, 2));
                xlabel(ax_new, 'X (mm)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel(ax_new, 'Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            else
                xlabel(ax_new, 'X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel(ax_new, 'Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            end
            title(ax_new, sprintf('Damage Analysis (%s, %s Mode, %s Depth)', inputType, mode, depthMethod), ...
                'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
            hold(ax_new, 'on');
            % -------------------------------------------------------------
            % STATISTICS
            % -------------------------------------------------------------
            if strcmp(inputType, 'Thermogram')
                input_median = median(inputData(:));
                temp_diff = input_median - inputData;
                input_std = std(temp_diff(:)); if input_std == 0, input_std = 1; end
            else
                input_mean = mean(inputData(:));
                input_std = std(inputData(:)); if input_std == 0, input_std = 1; end
            end
            % -------------------------------------------------------------
            % MANUAL MODE
            % -------------------------------------------------------------
            if strcmp(mode, 'Manual')
                uialert(fig, 'Manual mode not implemented yet.', 'Info');
                if isvalid(damageFig), close(damageFig); end
                return;
            end
            % -------------------------------------------------------------
            % AUTO MODE – THRESHOLDING
            % -------------------------------------------------------------
            outer_threshold_low = input_mean - thresholdMultiplier * input_std;
            inner_threshold_low = input_mean - (thresholdMultiplier + 1) * input_std;
            outer_threshold_high = input_mean + thresholdMultiplier * input_std;
            inner_threshold_high = input_mean + (thresholdMultiplier + 1) * input_std;
            mask_outer_low = inputData < outer_threshold_low;
            mask_inner_low = inputData < inner_threshold_low;
            mask_outer_high = inputData > outer_threshold_high;
            mask_inner_high = inputData > inner_threshold_high;
            mask_outer_low = imclose(imopen(mask_outer_low , strel('disk',3)), strel('disk',5));
            mask_inner_low = imclose(imopen(mask_inner_low , strel('disk',3)), strel('disk',5));
            mask_outer_high = imclose(imopen(mask_outer_high, strel('disk',3)), strel('disk',5));
            mask_inner_high = imclose(imopen(mask_inner_high, strel('disk',3)), strel('disk',5));
            props_outer_low = regionprops(mask_outer_low , 'Area','Centroid','PixelIdxList');
            props_inner_low = regionprops(mask_inner_low , 'Area','Centroid','PixelIdxList');
            props_outer_high = regionprops(mask_outer_high, 'Area','Centroid','PixelIdxList');
            props_inner_high = regionprops(mask_inner_high, 'Area','Centroid','PixelIdxList');
            boundaries_outer_low = bwboundaries(mask_outer_low);
            boundaries_inner_low = bwboundaries(mask_inner_low);
            boundaries_outer_high = bwboundaries(mask_outer_high);
            boundaries_inner_high = bwboundaries(mask_inner_high);
            if isempty(props_outer_low) && isempty(props_outer_high)
                if isvalid(damageFig), close(damageFig); end
                return;
            end
            % DEVIATIONS & MAX DEVIATION
            all_dev_low = []; all_dev_high = [];
            for k = 1:numel(props_outer_low)
                idx = props_outer_low(k).PixelIdxList(~mask_inner_low(props_outer_low(k).PixelIdxList));
                if ~isempty(idx), idx = idx(1:min(3,end)); end
                vals = inputData(idx); dev = (input_mean - mean(vals))/input_std;
                all_dev_low = [all_dev_low, dev];
            end
            for m = 1:numel(props_inner_low)
                idx = props_inner_low(m).PixelIdxList(1:min(3,end));
                vals = inputData(idx); dev = (input_mean - mean(vals))/input_std;
                all_dev_low = [all_dev_low, dev];
            end
            for k = 1:numel(props_outer_high)
                idx = props_outer_high(k).PixelIdxList(~mask_inner_high(props_outer_high(k).PixelIdxList));
                if ~isempty(idx), idx = idx(1:min(3,end)); end
                vals = inputData(idx); dev = (mean(vals) - input_mean)/input_std;
                all_dev_high = [all_dev_high, dev];
            end
            for m = 1:numel(props_inner_high)
                idx = props_inner_high(m).PixelIdxList(1:min(3,end));
                vals = inputData(idx); dev = (mean(vals) - input_mean)/input_std;
                all_dev_high = [all_dev_high, dev];
            end
            max_dev = max([all_dev_low, all_dev_high]); if max_dev <= 0, max_dev = 4; end
            if isvalid(ax_new)
                cellfun(@(b) plot(ax_new, b(:,2), b(:,1), 'Color','k', 'LineWidth',2), boundaries_outer_low);
                cellfun(@(b) plot(ax_new, b(:,2), b(:,1), 'Color','b', 'LineWidth',2), boundaries_inner_low);
                cellfun(@(b) plot(ax_new, b(:,2), b(:,1), 'Color','w', 'LineWidth',2), boundaries_outer_high);
                cellfun(@(b) plot(ax_new, b(:,2), b(:,1), 'Color',[0.5 0.5 0.5], 'LineWidth',2), boundaries_inner_high);
            end
            % PULSE START TIME & DIFFUSIVITY
            startTimeField = findobj(fig, 'Tag', 'startTimeField');
            pulseStartTime = 0.1;
            if ~isempty(startTimeField) && isprop(startTimeField, 'Value')
                pulseStartTime = startTimeField.Value;
            end
            if strcmp(depthMethod, 'Diffusivity') && thermalDiffusivity <= 0
                uialert(fig, 'Thermal diffusivity must be > 0. Run "Calculate Diffusion" first.', 'Error');
                return;
            end
            % -------------------------------------------------------------
            % PROCESS EACH REGION
            % -------------------------------------------------------------
            function processRegion(props, isHigh, isOuter)  % Added isOuter parameter
                for i = 1:numel(props)
                    pix = props(i).PixelIdxList;
                    if isHigh
                        between = pix(~mask_inner_high(pix));
                    else
                        between = pix(~mask_inner_low(pix));
                    end
                    if ~isempty(between), between = between(1:min(3,end)); end
                    if isempty(between) && numel(pix) >= 3
                        between = pix(1:3);
                    end
                    if isempty(between), continue; end
                    [rows, cols] = ind2sub([xSize, ySize], between);
                    nFrames = damageSNREndFrame - damageSNRStartFrame + 1;
                    sig = zeros(numel(between), nFrames);
                    for f = 1:nFrames
                        frmIdx = damageSNRStartFrame + f - 1;
                        if frmIdx > maxFrames, break; end
                        slice = croppedAnalysis.data(:,:,frmIdx);
                        sig(:,f) = slice(sub2ind(size(slice), rows, cols));
                    end
                    avgSig = mean(sig,1);
                    [~, peakIdx] = max(avgSig);
                    t_max = (damageSNRStartFrame + peakIdx - 1)/frameRate - pulseStartTime;
                    t_max = max(t_max, eps);
                    if strcmp(depthMethod, 'Diffusivity')
                        depth_mm = sqrt(thermalDiffusivity * t_max); % from actuator
                    else
                        dev = (mean(inputData(between)) - input_mean)/input_std;
                        if ~isHigh, dev = -dev; end
                        depth_mm = sourceDepth - (sourceDepth * (dev / max_dev)); % from surface, max = 1.8 mm
                    end
                    depth_mm = max(0, depth_mm);
                    area_mm2 = numel(pix) * pixelSize^2;
                    type = getDamageType(dev);
                    % Set col and pos unconditionally based on isHigh and isOuter (removed faulty i-based conditional)
                    if isHigh
                        if isOuter
                            col = 'w'; % White for outer high
                            pos = 'above';
                        else
                            col = [0.5 0.5 0.5]; % Grey for inner high
                            pos = 'below';
                        end
                    else
                        if isOuter
                            col = 'k'; % Black for outer low
                            pos = 'above';
                        else
                            col = 'b'; % Blue for inner low
                            pos = 'below';
                        end
                    end
                    place_label(props(i).Centroid(1), props(i).Centroid(2), ...
                        sprintf('%s: %.2f mm²\nDepth: %.1f mm', type, area_mm2, depth_mm), col, pos);
                end
            end
            processRegion(props_outer_low , false, true);  % Outer low: black, above
            processRegion(props_inner_low , false, false); % Inner low: blue, below
            processRegion(props_outer_high, true, true);   % Outer high: white, above
            processRegion(props_inner_high, true, false);  % Inner high: gray, below
            if isvalid(damageFig) && isvalid(ax_new)
                hold(ax_new, 'off');
                xlim(ax_new, [0.5 ySize+0.5]); ylim(ax_new, [0.5 xSize+0.5]);
                axis(ax_new, 'tight'); set(ax_new, 'DataAspectRatio', [1 1 1]);
            end
            function type = getDamageType(dev)
                if dev < 1, type = 'Minor';
                elseif dev < 2, type = 'Moderate';
                else, type = 'Severe'; end
            end
            function place_label(x, y, str, color, labelPos)
                if ~isvalid(ax_new) || ~isvalid(damageFig), return; end
                if strcmp(labelPos,'above')
                    base = 25;
                else
                    base = -25;
                end
                jitter = rand * 12 - 6;
                y = y + base + jitter;
                hText = text(ax_new, x, y, str, 'Color', color, 'FontSize',8, 'FontWeight','bold', 'HorizontalAlignment','center', 'BackgroundColor',[1 1 1 0.7], 'PickableParts','all', 'HitTest','on');
                set(hText, 'ButtonDownFcn', @(~,~) startDrag(hText));
            end
            function startDrag(hObj)
                set(damageFig, 'WindowButtonMotionFcn', @(src,evt) dragging(src,evt,hObj));
                set(damageFig, 'WindowButtonUpFcn', @(~,~) stopDrag());
            end
            function dragging(~, ~, hObj)
                cp = get(ax_new, 'CurrentPoint');
                set(hObj, 'Position', [cp(1,1) cp(1,2) 0]);
            end
            function stopDrag()
                set(damageFig, 'WindowButtonMotionFcn', '');
                set(damageFig, 'WindowButtonUpFcn', '');
            end
        end
    end
end