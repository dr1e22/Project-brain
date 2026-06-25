classdef DualThresholdDamageAnalysis
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

            if strcmp(inputType, 'SNR')
                uialert(fig, ...
                    'Dual thresholding is not recommended for SNR. Use single thresholding for low-SNR material damage.', ...
                    'Thresholding warning');
                return;
            end

            if strcmp(inputType, 'Thermogram')
                uialert(fig, ...
                    'Dual thresholding is not recommended for raw thermograms. Use Variance or Damage Indicator maps.', ...
                    'Thresholding warning');
                return;
            end

            [xSize, ySize] = size(inputData);

            validData = inputData(~isnan(inputData));
            dataMean = mean(validData);
            dataStd  = std(validData);

            if dataStd == 0 || isnan(dataStd)
                uialert(fig, 'Input data has zero or invalid standard deviation.', 'Error'); return;
            end

            % -------------------------------------------------------------
            % Low-side threshold
            % -------------------------------------------------------------
            outerLow = dataMean - thresholdMultiplier * dataStd;
            innerLow = dataMean - (thresholdMultiplier + 1) * dataStd;

            maskOuterLow = inputData < outerLow;
            maskInnerLow = inputData < innerLow;

            % -------------------------------------------------------------
            % High-side threshold
            % -------------------------------------------------------------
            outerHigh = dataMean + thresholdMultiplier * dataStd;
            innerHigh = dataMean + (thresholdMultiplier + 1) * dataStd;

            maskOuterHigh = inputData > outerHigh;
            maskInnerHigh = inputData > innerHigh;

            % -------------------------------------------------------------
            % Weighted and Multiplicative damage indicators invert the
            % physical meaning of the high/low response:
            %
            %   Weighted / Multiplicative:
            %       high-side = material damage field
            %       low-side  = actuator/heating interaction
            %
            %   Log Add / Log Hybrid / Log Hybrid v2:
            %       low-side  = material damage field
            %       high-side = actuator/heating interaction
            % -------------------------------------------------------------
            damageMethodDropdown = findobj(fig, 'Tag', 'damageMethodDropdown');

            if strcmp(inputType, 'Damage Indicator') && ...
                    ~isempty(damageMethodDropdown) && ...
                    isprop(damageMethodDropdown, 'Value') && ...
                    ismember(damageMethodDropdown.Value, {'Weighted', 'Multiplicative'})

                tempOuter = maskOuterLow;
                tempInner = maskInnerLow;

                maskOuterLow = maskOuterHigh;
                maskInnerLow = maskInnerHigh;

                maskOuterHigh = tempOuter;
                maskInnerHigh = tempInner;
            end

            % -------------------------------------------------------------
            % Clean masks
            % -------------------------------------------------------------
            maskOuterLow  = imclose(imopen(maskOuterLow,  strel('disk', 3)), strel('disk', 5));
            maskInnerLow  = imclose(imopen(maskInnerLow,  strel('disk', 3)), strel('disk', 5));
            maskOuterHigh = imclose(imopen(maskOuterHigh, strel('disk', 3)), strel('disk', 5));
            maskInnerHigh = imclose(imopen(maskInnerHigh, strel('disk', 3)), strel('disk', 5));

            propsOuterLow  = regionprops(maskOuterLow,  'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            propsInnerLow  = regionprops(maskInnerLow,  'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            propsOuterHigh = regionprops(maskOuterHigh, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');
            propsInnerHigh = regionprops(maskInnerHigh, 'Area', 'Centroid', 'PixelIdxList', 'BoundingBox');

            boundariesOuterLow  = bwboundaries(maskOuterLow);
            boundariesInnerLow  = bwboundaries(maskInnerLow);
            boundariesOuterHigh = bwboundaries(maskOuterHigh);
            boundariesInnerHigh = bwboundaries(maskInnerHigh);

            if isempty(propsOuterLow) && isempty(propsOuterHigh)
                uialert(fig, 'No dual-threshold regions detected.', 'Result'); return;
            end

            % Remove very small regions
            minAreaPixels = 100;

            propsOuterLow  = DualThresholdDamageAnalysis.filterSmallRegions(propsOuterLow,  minAreaPixels);
            propsInnerLow  = DualThresholdDamageAnalysis.filterSmallRegions(propsInnerLow,  minAreaPixels);
            propsOuterHigh = DualThresholdDamageAnalysis.filterSmallRegions(propsOuterHigh, minAreaPixels);
            propsInnerHigh = DualThresholdDamageAnalysis.filterSmallRegions(propsInnerHigh, minAreaPixels);

            % -------------------------------------------------------------
            % Figure
            % -------------------------------------------------------------
            damageFig = uifigure('Name', 'Dual-Threshold Damage Analysis', ...
                'Position', [100, 100, 950, 700]);

            ax = uiaxes(damageFig, ...
                'Position', [0.04, 0.04, 0.92, 0.92], ...
                'Units', 'normalized');

            imagesc(ax, inputData, 'XData', [1 ySize], 'YData', [1 xSize]);
            colormap(ax, 'jet');
            colorbar(ax);
            hold(ax, 'on');

            set(ax, ...
                'YDir', 'normal', ...
                'DataAspectRatio', [1 1 1], ...
                'Box', 'off', ...
                'TickDir', 'out');

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

            title(ax, sprintf('Dual Threshold: %s | %.1fσ', inputType, thresholdMultiplier), ...
                'FontWeight', 'bold');

            % -------------------------------------------------------------
            % Plot boundaries
            % -------------------------------------------------------------
            DualThresholdDamageAnalysis.plotBoundaries(ax, boundariesOuterLow,  'k', 2);
            DualThresholdDamageAnalysis.plotBoundaries(ax, boundariesInnerLow,  'b', 2);
            DualThresholdDamageAnalysis.plotBoundaries(ax, boundariesOuterHigh, 'w', 2);
            DualThresholdDamageAnalysis.plotBoundaries(ax, boundariesInnerHigh, [0.5 0.5 0.5], 2);

            % -------------------------------------------------------------
            % Main labels
            % -------------------------------------------------------------
            mainMaterialIdx = DualThresholdDamageAnalysis.labelMainMaterialRegion( ...
                ax, propsOuterLow, propsInnerLow, maskOuterLow, maskInnerLow, ...
                inputData, dataMean, dataStd, pixelSize, sourceDepth, ...
                thresholdMultiplier, ySize, xSize);

            mainHeatingIdx = DualThresholdDamageAnalysis.labelMainHeatingRegions( ...
                ax, propsOuterHigh, propsInnerHigh, maskOuterHigh, maskInnerHigh, ...
                inputData, dataMean, dataStd, pixelSize, sourceDepth, ySize, xSize);

            % -------------------------------------------------------------
            % Number secondary regions only
            % -------------------------------------------------------------
            nextRegionNumber = 1;

            nextRegionNumber = DualThresholdDamageAnalysis.numberSecondaryRegions( ...
                ax, propsOuterLow, mainMaterialIdx, nextRegionNumber, 'k');

            DualThresholdDamageAnalysis.numberSecondaryRegions( ...
                ax, propsOuterHigh, mainHeatingIdx, nextRegionNumber, 'w');

            % -------------------------------------------------------------
            % Legend
            % -------------------------------------------------------------
            legendText = sprintf(['Black = material damage boundary\n', ...
                                  'Blue = higher-severity material damage\n', ...
                                  'White = actuator-interaction / heating boundary\n', ...
                                  'Grey = higher-severity heating response\n', ...
                                  'Numbers = secondary detected regions\n', ...
                                  'Text boxes can be dragged']);

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
        % Remove small regions
        % -------------------------------------------------------------
        function propsOut = filterSmallRegions(propsIn, minAreaPixels)

            if isempty(propsIn)
                propsOut = propsIn;
                return;
            end

            propsOut = propsIn([propsIn.Area] >= minAreaPixels);
        end

        % -------------------------------------------------------------
        % Plot region boundaries
        % -------------------------------------------------------------
        function plotBoundaries(ax, boundaries, colour, lineWidth)

            for k = 1:numel(boundaries)

                b = boundaries{k};

                if size(b,1) > 10
                    plot(ax, b(:,2), b(:,1), ...
                        'Color', colour, ...
                        'LineWidth', lineWidth);
                end
            end
        end

        % -------------------------------------------------------------
        % Main material-damage label
        % -------------------------------------------------------------
        function mainIdx = labelMainMaterialRegion(ax, propsOuter, propsInner, maskOuter, maskInner, inputData, dataMean, dataStd, pixelSize, sourceDepth, thresholdMultiplier, ySize, xSize)

            mainIdx = [];

            if isempty(propsOuter)
                return;
            end

            [~, mainIdx] = max([propsOuter.Area]);

            outerArea_mm2 = propsOuter(mainIdx).Area * pixelSize^2;

            innerArea_mm2 = DualThresholdDamageAnalysis.getNestedInnerArea( ...
                propsOuter(mainIdx), propsInner, maskOuter, maskInner, pixelSize);

            values = inputData(propsOuter(mainIdx).PixelIdxList);
            values = values(~isnan(values));

            if isempty(values)
                return;
            end

            deviation = abs(mean(values) - dataMean) / dataStd;
            severity = DualThresholdDamageAnalysis.getSeverity(deviation);

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

            centroid = propsOuter(mainIdx).Centroid;

            % Initial placement only. The label can be dragged afterwards.
            labelX = centroid(1) - 20;
            labelY = centroid(2) + 95;

            labelX = min(max(labelX, 15), ySize - 120);
            labelY = min(max(labelY, 25), xSize - 55);

            labelString = sprintf(['%s\n%s\n', ...
                                   '%s: %.2f mm²\n', ...
                                   '%s: %.2f mm²\n', ...
                                   '%s'], ...
                                   labelTitle, severity, ...
                                   outerZoneName, outerArea_mm2, ...
                                   innerZoneName, innerArea_mm2, ...
                                   depthLine);

            DualThresholdDamageAnalysis.drawLabel(ax, centroid, labelX, labelY, labelString, 'k');
        end

        % -------------------------------------------------------------
        % Two main actuator/heating labels
        % -------------------------------------------------------------
        function mainIdx = labelMainHeatingRegions(ax, propsOuter, propsInner, maskOuter, maskInner, inputData, dataMean, dataStd, pixelSize, sourceDepth, ySize, xSize)

            mainIdx = [];

            if isempty(propsOuter)
                return;
            end

            centroids = reshape([propsOuter.Centroid], 2, []).';

            imageCentre = [ySize/2, xSize/2];

            distToCentre = sqrt((centroids(:,1) - imageCentre(1)).^2 + ...
                                (centroids(:,2) - imageCentre(2)).^2);

            [~, order] = sort(distToCentre, 'ascend');

            nLabels = min(2, numel(order));

            mainIdx = order(1:nLabels);

            for n = 1:nLabels

                idx = mainIdx(n);

                outerArea_mm2 = propsOuter(idx).Area * pixelSize^2;

                innerArea_mm2 = DualThresholdDamageAnalysis.getNestedInnerArea( ...
                    propsOuter(idx), propsInner, maskOuter, maskInner, pixelSize);

                values = inputData(propsOuter(idx).PixelIdxList);
                values = values(~isnan(values));

                if isempty(values)
                    continue;
                end

                deviation = abs(mean(values) - dataMean) / dataStd;
                severity = DualThresholdDamageAnalysis.getSeverity(deviation);

                centroid = propsOuter(idx).Centroid;

                % Initial placements only. Labels can be dragged afterwards.
                if centroid(1) < imageCentre(1)
                    % Left heating feature
                    labelX = centroid(1) - 120;
                    labelY = centroid(2) - 55;
                else
                    % Right heating feature
                    labelX = centroid(1) + 35;
                    labelY = centroid(2) + 10;
                end

                labelX = min(max(labelX, 15), ySize - 120);
                labelY = min(max(labelY, 25), xSize - 55);

                labelString = sprintf(['Actuator interaction field\n%s\n', ...
                                       'Resistive-heating zone: %.2f mm²\n', ...
                                       'Severe heating subset: %.2f mm²\n', ...
                                       'Actuator depth: %.1f mm'], ...
                                       severity, outerArea_mm2, innerArea_mm2, sourceDepth);

                DualThresholdDamageAnalysis.drawLabel(ax, centroid, labelX, labelY, labelString, 'k');
            end
        end

        % -------------------------------------------------------------
        % Number secondary regions only
        % -------------------------------------------------------------
        function nextNumber = numberSecondaryRegions(ax, propsOuter, mainIdx, startNumber, markerColour)

            nextNumber = startNumber;

            if isempty(propsOuter)
                return;
            end

            maxNumberedRegions = 8;

            [~, order] = sort([propsOuter.Area], 'descend');

            count = 0;

            for n = 1:numel(order)

                idx = order(n);

                if ~isempty(mainIdx) && any(idx == mainIdx)
                    continue;
                end

                centroid = propsOuter(idx).Centroid;

                plot(ax, centroid(1), centroid(2), 'o', ...
                    'Color', markerColour, ...
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
        % Calculate nested inner-region area
        % -------------------------------------------------------------
        function innerArea_mm2 = getNestedInnerArea(outerProp, propsInner, maskOuter, maskInner, pixelSize)

            innerArea_mm2 = 0;

            if isempty(propsInner)
                return;
            end

            outerMaskThis = false(size(maskOuter));
            outerMaskThis(outerProp.PixelIdxList) = true;

            for j = 1:numel(propsInner)

                innerMaskThis = false(size(maskInner));
                innerMaskThis(propsInner(j).PixelIdxList) = true;

                if any(outerMaskThis(:) & innerMaskThis(:))
                    innerArea_mm2 = innerArea_mm2 + propsInner(j).Area * pixelSize^2;
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
                'ButtonDownFcn', @DualThresholdDamageAnalysis.startDragLabel, ...
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

            fig.WindowButtonMotionFcn = @DualThresholdDamageAnalysis.dragLabel;
            fig.WindowButtonUpFcn = @DualThresholdDamageAnalysis.stopDragLabel;
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
    end
end