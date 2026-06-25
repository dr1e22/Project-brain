classdef SingleThresholdDamageAnalysis
    methods (Static)

        function measureDamageArea(fig, croppedAnalysis, inputData, pixelSize, thresholdMultiplier, frameRate, bgFrames, sourceDepth, startFrame, endFrame, damageSNRStartFrame, damageSNREndFrame, mode, inputType, depthMethod, thermalDiffusivity, frameIndex, useMillimeters)

            if isempty(croppedAnalysis)
                uialert(fig, 'Crop data first.', 'Error'); return;
            end
            if isempty(inputData)
                uialert(fig, 'Generate input data first.', 'Error'); return;
            end
            if pixelSize <= 0 || thresholdMultiplier < 0
                uialert(fig, 'Pixel size and threshold multiplier must be positive.', 'Error'); return;
            end

            % Read actuator/source depth directly from GUI
            sourceDepthField = findobj(fig, 'Tag', 'sourceDepthField');
            if ~isempty(sourceDepthField) && isprop(sourceDepthField, 'Value')
                sourceDepth = sourceDepthField.Value;
            end

            if strcmp(mode, 'Manual')
                uialert(fig, 'Manual mode not implemented yet.', 'Info'); return;
            end

            [xSize, ySize] = size(inputData);

            validData = inputData(~isnan(inputData));
            dataMean = mean(validData);
            dataStd  = std(validData);

            if dataStd == 0 || isnan(dataStd)
                uialert(fig, 'Input data has zero or invalid standard deviation.', 'Error'); return;
            end

            damageMethodDropdown = findobj(fig, 'Tag', 'damageMethodDropdown');
            if ~isempty(damageMethodDropdown) && isprop(damageMethodDropdown, 'Value')
                damageMethod = damageMethodDropdown.Value;
            else
                damageMethod = 'Unknown';
            end

            switch inputType

                case 'SNR'
                    maskOuter = inputData < dataMean - thresholdMultiplier * dataStd;
                    maskInner = inputData < dataMean - (thresholdMultiplier + 1) * dataStd;
                    thresholdRole = 'MaterialLow';

                case 'Variance'
                    maskOuter = inputData > dataMean + thresholdMultiplier * dataStd;
                    maskInner = inputData > dataMean + (thresholdMultiplier + 1) * dataStd;
                    thresholdRole = 'VarianceHeating';

                case 'Damage Indicator'

                    if ismember(damageMethod, {'Logarithmic Add', 'Log Hybrid', 'Log Hybrid v2'})
                        maskOuter = inputData < dataMean - thresholdMultiplier * dataStd;
                        maskInner = inputData < dataMean - (thresholdMultiplier + 1) * dataStd;
                        thresholdRole = 'MaterialLow';

                    elseif ismember(damageMethod, {'Weighted', 'Multiplicative'})
                        maskOuter = inputData > dataMean + thresholdMultiplier * dataStd;
                        maskInner = inputData > dataMean + (thresholdMultiplier + 1) * dataStd;
                        thresholdRole = 'MaterialHigh';

                    elseif strcmp(damageMethod, 'Logarithmic Mult')
                        uialert(fig, ...
                            'Logarithmic Mult did not indicate damage with single thresholding.', ...
                            'Damage Indicator Result');
                        return;

                    else
                        uialert(fig, sprintf('Unknown Damage Indicator method: %s', damageMethod), ...
                            'Unsupported DI Method');
                        return;
                    end

                otherwise
                    uialert(fig, ...
                        'Single thresholding is recommended for SNR, Variance, or Damage Indicator maps only.', ...
                        'Unsupported input');
                    return;
            end

            % Clean masks
            maskOuter = imopen(maskOuter, strel('disk', 3));
            maskOuter = imclose(maskOuter, strel('disk', 5));

            maskInner = imopen(maskInner, strel('disk', 3));
            maskInner = imclose(maskInner, strel('disk', 5));

            propsOuter = regionprops(maskOuter, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            propsInner = regionprops(maskInner, 'Area', 'Centroid', 'PixelIdxList');

            boundariesOuter = bwboundaries(maskOuter);
            boundariesInner = bwboundaries(maskInner);

            if isempty(propsOuter)
                uialert(fig, 'No regions detected at this threshold.', 'Result'); return;
            end

            minAreaPixels = 100;
            propsOuter = propsOuter([propsOuter.Area] >= minAreaPixels);

            if isempty(propsOuter)
                uialert(fig, 'Only small isolated regions detected.', 'Result'); return;
            end

            damageFig = uifigure('Name', 'Single-Threshold Damage Analysis', ...
                'Position', [100, 100, 900, 680]);

            ax = uiaxes(damageFig, 'Position', [0.04, 0.04, 0.92, 0.92], ...
                'Units', 'normalized');

            imagesc(ax, inputData, 'XData', [1 ySize], 'YData', [1 xSize]);
            colormap(ax, 'jet');
            colorbar(ax);
            hold(ax, 'on');

            set(ax, 'YDir', 'normal', 'DataAspectRatio', [1 1 1], ...
                'Box', 'off', 'TickDir', 'out');

            if useMillimeters
                set(ax, ...
                    'XTick', 0:50:ySize, ...
                    'XTickLabel', round((0:50:ySize) * pixelSize, 2), ...
                    'YTick', 0:50:xSize, ...
                    'YTickLabel', round((0:50:xSize) * pixelSize, 2));
                xlabel(ax, 'X (mm)');
                ylabel(ax, 'Y (mm)');
            else
                xlabel(ax, 'X (Pixels)');
                ylabel(ax, 'Y (Pixels)');
            end

            if strcmp(inputType, 'Damage Indicator')
                title(ax, sprintf('Single Threshold: %s | %s | %.1fσ', ...
                    inputType, damageMethod, thresholdMultiplier), 'FontWeight', 'bold');
            else
                title(ax, sprintf('Single Threshold: %s | %.1fσ', ...
                    inputType, thresholdMultiplier), 'FontWeight', 'bold');
            end

            % Plot boundaries
            for k = 1:numel(boundariesOuter)
                b = boundariesOuter{k};
                if size(b,1) > 10
                    plot(ax, b(:,2), b(:,1), 'k', 'LineWidth', 2);
                end
            end

            for k = 1:numel(boundariesInner)
                b = boundariesInner{k};
                if size(b,1) > 10
                    plot(ax, b(:,2), b(:,1), 'b', 'LineWidth', 2);
                end
            end

            % Sort detected regions by size
            [~, order] = sort([propsOuter.Area], 'descend');

            % Full labels for largest regions only
            maxFullLabels = 3;
            nLabels = min(maxFullLabels, numel(order));
            fullLabelIdx = order(1:nLabels);

            usedLabelPositions = [];

            for idx = 1:nLabels

                k = fullLabelIdx(idx);

                outerArea_mm2 = propsOuter(k).Area * pixelSize^2;

                outerMaskThis = false(size(maskOuter));
                outerMaskThis(propsOuter(k).PixelIdxList) = true;

                innerArea_mm2 = 0;
                for j = 1:numel(propsInner)
                    innerMaskThis = false(size(maskInner));
                    innerMaskThis(propsInner(j).PixelIdxList) = true;

                    if any(outerMaskThis(:) & innerMaskThis(:))
                        innerArea_mm2 = innerArea_mm2 + propsInner(j).Area * pixelSize^2;
                    end
                end

                values = inputData(propsOuter(k).PixelIdxList);
                values = values(~isnan(values));

                if isempty(values)
                    continue;
                end

                if strcmp(thresholdRole, 'MaterialHigh') || strcmp(thresholdRole, 'VarianceHeating')
                    deviation = (mean(values) - dataMean) / dataStd;
                else
                    deviation = (dataMean - mean(values)) / dataStd;
                end

                severity = SingleThresholdDamageAnalysis.getSeverity(deviation);

                if strcmp(thresholdRole, 'VarianceHeating')

                    if thresholdMultiplier <= 1
                        labelTitle = 'Thermal variability field';
                        outerZoneName = 'High-variance zone';
                        innerZoneName = 'Elevated heating zone';
                        depthLine = 'Actuator-layer interaction';

                    elseif thresholdMultiplier < 3
                        labelTitle = 'Resistive-heating field';
                        outerZoneName = 'Current-crowding zone';
                        innerZoneName = 'Severe heating zone';
                        depthLine = sprintf('Actuator depth: %.1f mm', sourceDepth);

                    else
                        labelTitle = 'Severe actuator-heating field';
                        outerZoneName = 'Severe current-crowding zone';
                        innerZoneName = 'Critical heating core';
                        depthLine = sprintf('Actuator depth: %.1f mm', sourceDepth);
                    end

                else

                    if thresholdMultiplier <= 1
                        labelTitle = 'Thermal disturbance field';
                        outerZoneName = 'Thermal disturbance zone';
                        innerZoneName = 'Elevated damage zone';
                        depthLine = 'Core: elevated damage severity';

                    elseif thresholdMultiplier < 3
                        labelTitle = 'Elevated damage field';
                        outerZoneName = 'Elevated damage zone';
                        innerZoneName = 'Severe damage zone';
                        depthLine = 'Core: damage approaching actuator layer';

                    else
                        labelTitle = 'Severe damage field';
                        outerZoneName = 'Severe damage zone';
                        innerZoneName = 'Critical damage core';
                        depthLine = sprintf('Core depth: >= %.1f mm', sourceDepth);
                    end
                end

                labelString = sprintf(['%s\n%s\n', ...
                    '%s: %.2f mm²\n', ...
                    '%s: %.2f mm²\n', ...
                    '%s'], ...
                    labelTitle, severity, ...
                    outerZoneName, outerArea_mm2, ...
                    innerZoneName, innerArea_mm2, ...
                    depthLine);

                centroid = propsOuter(k).Centroid;
                bbox = propsOuter(k).BoundingBox;

                [labelX, labelY, usedLabelPositions] = ...
                    SingleThresholdDamageAnalysis.findLabelPosition( ...
                    centroid, bbox, ySize, xSize, usedLabelPositions);

                SingleThresholdDamageAnalysis.drawLabel(ax, centroid, labelX, labelY, labelString, 'k');
            end

            % Number all additional detected regions
            SingleThresholdDamageAnalysis.numberSecondaryRegions(ax, propsOuter, fullLabelIdx, 1);

            if strcmp(thresholdRole, 'VarianceHeating')
                thresholdMeaning = 'High variance = resistive heating / current crowding';
            elseif thresholdMultiplier <= 1
                thresholdMeaning = 'Low k = thermal disturbance screen';
            elseif thresholdMultiplier < 3
                thresholdMeaning = 'Intermediate k = elevated damage field';
            else
                thresholdMeaning = 'High k = severe / critical core';
            end

            legendText = sprintf(['Black = lower-severity boundary\n', ...
                                  'Blue = higher-severity boundary\n', ...
                                  '%s\n', ...
                                  'Numbers = secondary detected regions\n', ...
                                  'Text boxes can be dragged'], thresholdMeaning);

            text(ax, 10, xSize - 10, legendText, ...
                'Color', 'k', ...
                'FontSize', 9, ...
                'FontWeight', 'bold', ...
                'BackgroundColor', [1 1 1 0.78], ...
                'VerticalAlignment', 'top', ...
                'Margin', 3);

            hold(ax, 'off');
            axis(ax, 'image');
        end

        % -------------------------------------------------------------
        % Severity classification
        % -------------------------------------------------------------
        function severity = getSeverity(deviation)
            if deviation < 1
                severity = 'Minor';
            elseif deviation < 2
                severity = 'Moderate';
            else
                severity = 'Severe';
            end
        end

        % -------------------------------------------------------------
        % Initial automatic label placement
        % -------------------------------------------------------------
        function [labelX, labelY, usedLabelPositions] = findLabelPosition(centroid, bbox, ySize, xSize, usedLabelPositions)

            candidatePositions = [
                bbox(1) + bbox(3) + 25, centroid(2) + 20;
                bbox(1) - 80,           centroid(2) + 20;
                centroid(1) + 25,       bbox(2) + bbox(4) + 25;
                centroid(1) + 25,       bbox(2) - 25;
                bbox(1) + bbox(3) + 25, centroid(2) - 30;
                bbox(1) - 80,           centroid(2) - 30
            ];

            bestScore = inf;
            labelX = centroid(1) + 25;
            labelY = centroid(2) + 20;

            for i = 1:size(candidatePositions, 1)

                cx = candidatePositions(i,1);
                cy = candidatePositions(i,2);

                cx = min(max(cx, 10), ySize - 120);
                cy = min(max(cy, 10), xSize - 45);

                distanceToDamage = sqrt((cx - centroid(1))^2 + (cy - centroid(2))^2);

                overlapPenalty = 0;
                for j = 1:size(usedLabelPositions, 1)
                    d = sqrt((cx - usedLabelPositions(j,1))^2 + ...
                             (cy - usedLabelPositions(j,2))^2);

                    if d < 35
                        overlapPenalty = overlapPenalty + 1000;
                    end
                end

                score = overlapPenalty + distanceToDamage;

                if score < bestScore
                    bestScore = score;
                    labelX = cx;
                    labelY = cy;
                end
            end

            usedLabelPositions = [usedLabelPositions; labelX, labelY];
        end

        % -------------------------------------------------------------
        % Number secondary regions only
        % -------------------------------------------------------------
        function nextNumber = numberSecondaryRegions(ax, propsOuter, labelledIdx, startNumber)

            nextNumber = startNumber;

            if isempty(propsOuter)
                return;
            end

            maxNumberedRegions = 12;

            [~, order] = sort([propsOuter.Area], 'descend');

            count = 0;

            for n = 1:numel(order)

                idx = order(n);

                if ~isempty(labelledIdx) && any(idx == labelledIdx)
                    continue;
                end

                centroid = propsOuter(idx).Centroid;

                plot(ax, centroid(1), centroid(2), 'ko', ...
                    'MarkerFaceColor', 'w', ...
                    'MarkerSize', 8, ...
                    'LineWidth', 1.2);

                text(ax, centroid(1), centroid(2), sprintf('%d', nextNumber), ...
                    'Color', 'k', ...
                    'FontSize', 7, ...
                    'FontWeight', 'bold', ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'BackgroundColor', 'none', ...
                    'Margin', 1);

                nextNumber = nextNumber + 1;
                count = count + 1;

                if count >= maxNumberedRegions
                    break;
                end
            end
        end

        % -------------------------------------------------------------
        % Draw draggable label and leader line
        % -------------------------------------------------------------
        function drawLabel(ax, centroid, labelX, labelY, labelString, lineColour)

            hLine = plot(ax, [centroid(1), labelX], [centroid(2), labelY], ...
                '-', ...
                'Color', lineColour, ...
                'LineWidth', 1);

            plot(ax, centroid(1), centroid(2), 'ko', ...
                'MarkerSize', 4, ...
                'MarkerFaceColor', 'k');

            hText = text(ax, labelX, labelY, labelString, ...
                'Color', 'k', ...
                'FontSize', 8, ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle', ...
                'BackgroundColor', [1 1 1 0.78], ...
                'Margin', 3, ...
                'ButtonDownFcn', @SingleThresholdDamageAnalysis.startDragLabel, ...
                'PickableParts', 'all', ...
                'HitTest', 'on');

            hText.UserData.Centroid = centroid;
            hText.UserData.LineHandle = hLine;
            hText.UserData.AxisHandle = ax;
        end

        % -------------------------------------------------------------
        % Start dragging a label
        % -------------------------------------------------------------
        function startDragLabel(src, ~)

            ax = src.UserData.AxisHandle;
            fig = ancestor(ax, 'figure');

            if ~isstruct(fig.UserData)
                fig.UserData = struct();
            end

            fig.UserData.DraggedLabel = src;

            fig.WindowButtonMotionFcn = @SingleThresholdDamageAnalysis.dragLabel;
            fig.WindowButtonUpFcn = @SingleThresholdDamageAnalysis.stopDragLabel;
        end

        % -------------------------------------------------------------
        % Drag label and update leader line
        % -------------------------------------------------------------
        function dragLabel(fig, ~)

            if ~isstruct(fig.UserData)
                return;
            end

            if ~isfield(fig.UserData, 'DraggedLabel')
                return;
            end

            hText = fig.UserData.DraggedLabel;

            if ~isvalid(hText)
                return;
            end

            ax = hText.UserData.AxisHandle;
            cp = ax.CurrentPoint;

            newX = cp(1,1);
            newY = cp(1,2);

            hText.Position = [newX, newY, 0];

            centroid = hText.UserData.Centroid;
            hLine = hText.UserData.LineHandle;

            if isvalid(hLine)
                hLine.XData = [centroid(1), newX];
                hLine.YData = [centroid(2), newY];
            end
        end

        % -------------------------------------------------------------
        % Stop dragging label
        % -------------------------------------------------------------
        function stopDragLabel(fig, ~)

            fig.WindowButtonMotionFcn = '';
            fig.WindowButtonUpFcn = '';

            if isstruct(fig.UserData) && isfield(fig.UserData, 'DraggedLabel')
                fig.UserData = rmfield(fig.UserData, 'DraggedLabel');
            end
        end
    end
end