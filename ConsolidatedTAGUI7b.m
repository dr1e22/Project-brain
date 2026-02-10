function ConsolidatedTAGUI7b()

    %% Create the main UI figure
    fig = uifigure('Position', [100, 100, 600, 800], 'Name', 'Thermal Data Analysis ConsolidatedTAGUI7b');
    %% Banner (Top)
    bannerLabel = uilabel(fig, 'Position', [20, 720, 560, 80], 'Text', 'Consolidated Thermal Data Analysis Tool', ...
'FontSize', 24, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'center', ...
'BackgroundColor', [0.1, 0.3, 0.6], 'FontColor', [1, 1, 1]);
    %% Footer
    ownerLabel = uilabel(fig, 'Position', [20, 10, 560, 20], 'Text', 'Created by Darren Roderick', ...
'FontSize', 12, 'HorizontalAlignment', 'right', 'BackgroundColor', [0.9, 0.9, 0.9]);
    %% Panel 1: File Operations
    panelFile = uipanel(fig, 'Title', 'File Operations', 'Position', [20, 650, 280, 70], 'FontWeight', 'bold', 'FontSize', 12);
    btnLoad = uibutton(panelFile, 'Position', [5, 10, 100, 30], 'Text', 'Load File', 'ButtonPushedFcn', @loadFile);
    btnCropRegion = uibutton(panelFile, 'Position', [120, 10, 100, 30], 'Text', 'Crop Region', 'ButtonPushedFcn', @cropRegion);
    btnClearData = uibutton(panelFile, 'Position', [235, 10, 30, 30], 'Text', 'X', 'ButtonPushedFcn', @clearData, 'Tooltip', 'Clear Loaded Data');
    %% Panel 2: Background Subtraction Settings
    panelBackground = uipanel(fig, 'Title', 'Background Subtraction Settings', 'Position', [300, 650, 280, 70], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelBackground, 'Position', [5, 10, 50, 30], 'Text', 'No of Frames:', 'WordWrap', 'on');
    bgFrameField = uieditfield(panelBackground, 'numeric', 'Position', [60, 10, 50, 30], 'Value', 20, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', ...
'Tooltip', 'Frames for background subtraction', 'Tag','bgFrameField');
    btnSetBgFrames = uibutton(panelBackground, 'Position', [130, 10, 60, 30], 'Text', 'Set', 'ButtonPushedFcn', @setBgFrames);
    btnResetBg = uibutton(panelBackground, 'Position', [210, 10, 50, 30], 'Text', 'Reset', 'ButtonPushedFcn', @resetBackground, 'Tooltip', 'Reset Background Frames');
    %% Panel 3: Filter Settings
    panelFilter = uipanel(fig, 'Title', 'Filter Settings', 'Position', [300, 560, 280, 90], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelFilter, 'Position', [5, 30, 50, 30], 'Text', 'Select Filters:','WordWrap', 'on');
    filterDropdown = uidropdown(panelFilter, 'Position', [50, 30, 100, 30], 'Items', {'Gaussian', 'Average', 'Median'}, 'Value', 'Gaussian', 'Tag', 'filterDropdown');
    btnPreviewFilter = uibutton(panelFilter, 'Position', [175, 30, 100, 30], 'Text', 'Preview Filter', 'ButtonPushedFcn', @previewFilter, 'Tooltip', 'Preview Filtered Frame');
    uilabel(panelFilter, 'Position', [5, 5, 70, 20], 'Text', 'Kernel Size:');
    filterSizeField = uieditfield(panelFilter, 'numeric', 'Position', [80, 5, 20, 20], 'Value', 5, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Kernel size for Gaussian, Average, Median', 'Tag', 'filterSizeField');
    uilabel(panelFilter, 'Position', [120, 5, 100, 20], 'Text', 'Gaussian Sigma:');
    sigmaField = uieditfield(panelFilter, 'numeric', 'Position', [230, 5, 20, 20], 'Value', 1, ...
'RoundFractionalValues', true, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Sigma for Gaussian filter', 'Tag', 'sigmaField');
    %% Panel 4: Frame Analysis
    panelFrame = uipanel(fig, 'Title', 'Frame Analysis', 'Position', [20, 560, 280, 90], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelFrame, 'Position', [5, 40, 35, 30], 'Text', 'Frame Index:', 'WordWrap', 'on');
    frameField = uieditfield(panelFrame, 'numeric', 'Position', [50, 40, 50, 30], 'Value', 1, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tag', 'frameField');
    btnShowFrame = uibutton(panelFrame, 'Position', [100, 5, 80, 30], 'Text', 'Frame', 'ButtonPushedFcn', @showFrame, 'Tooltip', 'Show Filtered Frame Image');
    btnShowSurface = uibutton(panelFrame, 'Position', [5, 5, 80, 30], 'Text', 'Surface Plot', 'ButtonPushedFcn', @showSurfacePlot, 'Tooltip', 'Show 3D Surface Plot');
    btnCreateMP4 = uibutton(panelFrame, 'Position', [190, 5, 80, 30], 'Text', 'MP4', 'ButtonPushedFcn', @createMP4, 'Tooltip', 'Create MP4 Video');
    uilabel(panelFrame, 'Position', [180, 40, 50, 30], 'Text', 'Frame Interval:', 'WordWrap', 'on');
    mp4IntervalField = uieditfield(panelFrame, 'numeric', 'Position', [235, 40, 35, 30], 'Value', 10, 'Limits', [1 Inf], 'Tooltip', 'Frame interval for MP4', 'Tag', 'mp4IntervalField');
    %% Panel 5: SNR & Variance
    panelSNR = uipanel(fig, 'Title', 'SNR & Variance', 'Position', [20, 500, 560, 60], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelSNR, 'Position', [230, 10, 150, 20], 'Text', 'Frame/Pixel:');
    snrVarMethodDropdown = uidropdown(panelSNR, 'Position', [300, 10, 100, 20], 'Items', {'Per Frame', 'Per Pixel'}, 'Value', 'Per Frame', 'Tag', 'snrVarMethodDropdown');
    btnCalcSNRVar = uibutton(panelSNR, 'Position', [450, 5, 100, 30], 'Text', 'SNR/Var Plot', 'ButtonPushedFcn', @calculateSNRandVariance);
    uilabel(panelSNR, 'Position', [5, 10, 100, 20], 'Text', 'Start Frame:');
    startFrameField = uieditfield(panelSNR, 'numeric', 'Position', [80, 10, 50, 20], 'Value', 1500, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tag', 'startFrameField');
    uilabel(panelSNR, 'Position', [140, 10, 50, 20], 'Text', 'to:');
    endFrameField = uieditfield(panelSNR, 'numeric', 'Position', [160, 10, 50, 20], 'Value', 2500, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tag', 'endFrameField');
    %% Panel 6: Heatmaps
    panelHeatmaps = uipanel(fig, 'Title', 'Heatmaps', 'Position', [20, 440, 560, 60], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelHeatmaps, 'Position', [5, 10, 80, 20], 'Text', 'SNR Method:');
    snrMethodDropdown = uidropdown(panelHeatmaps, 'Position', [80, 5, 100, 30], 'Items', {'Mean-Based SNR', 'Variance-Based SNR', 'Hybrid SNR', 'Contrast-Based CNR'}, 'Value', 'Mean-Based SNR', ...
'Tooltip', 'Select SNR computation method', 'Tag', 'snrMethodDropdown', 'ValueChangedFcn', @updateHeatmap);
    btnGenerateHeatmaps = uibutton(panelHeatmaps, 'Position', [450, 5, 100, 30], 'Text', 'Heatmaps', 'ButtonPushedFcn', @generateHeatmaps);
    uilabel(panelHeatmaps, 'Position', [200, 5, 100, 30], 'Text', 'Distance Measurement:', 'WordWrap', 'On');
    distanceMeasurementDropdown = uidropdown(panelHeatmaps, 'Position', [285, 5, 90, 30], ...
'Items', {'Manual Distance: Frame', 'Manual Distance: SNR Heatmap', 'Manual Distance: Variance Heatmap', 'Manual Distance: Damage Indicator Heatmap', ...
'Auto Distance: Frame', 'Auto Distance: SNR Heatmap', 'Auto Distance: Variance Heatmap', 'Auto Distance: Damage Indicator Heatmap'}, ...
'Value', 'Manual Distance: Frame', 'Tag', 'distanceMeasurementDropdown', ...
'Tooltip', 'Select distance measurement type and target', 'ValueChangedFcn', @performDistanceMeasurement);
    scaleUnitsCheckbox = uicheckbox(panelHeatmaps, 'Text', 'mm', 'Position', [395, 5, 90, 30], 'Value', true, ...
'Tooltip', 'Toggle between pixels and millimeters for image scaling', 'Tag', 'scaleUnitsCheckbox');
    %% Panel 7: Damage Detection and Quantification
    panelDamage = uipanel(fig, 'Title', 'Damage Detection and Quantification', 'Position', [20, 250, 560, 190], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelDamage, 'Position', [5, 145, 70, 20], 'Text', 'DI Method:');
    damageMethodDropdown = uidropdown(panelDamage, 'Position', [70, 135, 80, 30], ...
'Items', {'Multiplicative', 'Weighted', 'Logarithmic Add', 'Logarithmic Mult', 'Log Hybrid', 'Log Hybrid v2', 'S-Curve'}, ...
'Value', 'Weighted', 'Tag', 'damageMethodDropdown', 'ValueChangedFcn', @updateDamageMethod, ...
'Tooltip', 'Select damage indicator method');
    useWeightedCheckbox = uicheckbox(panelDamage, 'Text', 'Use Weighted', 'Position', [160, 145, 130, 20], ...
'Value', true, 'ValueChangedFcn', @toggleWeightedMethod, 'Tag', 'useWeightedCheckbox', ...
'Tooltip', 'Toggle between weighted and original Damage Indicator method');
    uilabel(panelDamage, 'Position', [270, 145, 60, 20], 'Text', 'SNR:');
    snrWeightField = uieditfield(panelDamage, 'numeric', 'Position', [300, 145, 30, 20], 'Value', 0.5, ...
'Limits', [0 1], 'LowerLimitInclusive', 'on', 'UpperLimitInclusive', 'on', ...
'ValueChangedFcn', @updateWeights, 'Tag', 'snrWeightField', 'Tooltip', 'SNR weight in Damage Indicator (0 to 1)');
    uilabel(panelDamage, 'Position', [340, 145, 60, 20], 'Text', 'Var:');
    varianceWeightField = uieditfield(panelDamage, 'numeric', 'Position', [362, 145, 30, 20], 'Value', 0.5, ...
'Limits', [0 1], 'LowerLimitInclusive', 'on', 'UpperLimitInclusive', 'on', ...
'ValueChangedFcn', @updateWeights, 'Tag', 'varianceWeightField', 'Tooltip', 'Variance weight in Damage Indicator (0 to 1)');
% S-Curve manual input boxes
    uilabel(panelDamage, 'Position', [5, 110, 80, 20], 'Text', 'S-Curve k:');
    scurveKField = uieditfield(panelDamage, 'numeric', 'Position', [65, 110, 40, 20], 'Value', 20, ...
'Limits', [1 100], 'Tooltip', 'S-curve steepness – higher = sharper', 'Tag', 'scurveKField', 'Enable', 'off');
    uilabel(panelDamage, 'Position', [110, 110, 40, 20], 'Text', 'x0:');
    scurveX0Field = uieditfield(panelDamage, 'numeric', 'Position', [130, 110, 40, 20], 'Value', 0.5, ...
'Limits', [0 1], 'RoundFractionalValues', 'off', 'Tooltip', 'Inflection point (0–1)', 'Tag', 'scurveX0Field', 'Enable', 'off');
% Auto S-Curve button
    btnAutoSCurve = uibutton(panelDamage, 'Position', [190, 105, 140, 30], 'Text', 'S Curve - Diff', ...
'ButtonPushedFcn', @autoSetSCurveFromDiffusivity, 'Tooltip', 'Set k and x0 from Calculate Diffusion curve');
    btnGenerateDamageHeatmap = uibutton(panelDamage, 'Position', [450, 100, 105, 35], 'Text', 'Damage Indicator', 'WordWrap', 'on','ButtonPushedFcn', @generateDamageHeatmap);
    btnCalcDiffusivity = uibutton(panelDamage, 'Position', [5, 70, 145, 30], 'Text', 'Calculate Diffusion', 'ButtonPushedFcn', @calcDiffusivity, 'Tooltip', 'Estimate thermal diffusivity');
    uilabel(panelDamage, 'Position', [5, 45, 105, 20], 'Text', 'Therm Diff (mm²/s):');
    thermalDiffusivityField = uieditfield(panelDamage, 'numeric', 'Position', [110, 45, 40, 20], 'Value', 0.1, ...
'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Material thermal diffusivity (mm²/s)', 'Tag', 'thermalDiffusivityField');
    btnPreviewThermogram = uibutton(panelDamage, 'Position', [5, 5, 145, 30], 'Text', 'Preview Thermogram', 'ButtonPushedFcn', @previewThermogram, 'Tooltip', 'Preview thermogram slice');
    uilabel(panelDamage, 'Position', [160, 40, 90, 20], 'Text', 'SNR Start Frame:');
    damageSNRStartFrameField = uieditfield(panelDamage, 'numeric', 'Position', [250, 40, 50, 20], 'Value', startFrameField.Value, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', ...
'Tooltip', 'Start frame for SNR heatmap in damage analysis', 'Tag', 'damageSNRStartFrameField');
    uilabel(panelDamage, 'Position', [160, 10, 90, 20], 'Text', 'SNR End Frame:');
    damageSNREndFrameField = uieditfield(panelDamage, 'numeric', 'Position', [250, 10, 50, 20], 'Value', endFrameField.Value, ...
'RoundFractionalValues', true, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', ...
'Tooltip', 'End frame for SNR heatmap in damage analysis', 'Tag', 'damageSNREndFrameField');
    uilabel(panelDamage, 'Position', [160, 70, 90, 20], 'Text', 'SNR Threshold:');
    thresholdField = uieditfield(panelDamage, 'numeric', 'Position', [250, 70, 50, 20], 'Value', 2, ...
'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'SNR threshold for damage detection', 'Tag', 'thresholdField');
    uilabel(panelDamage, 'Position', [310, 65, 60, 30], 'Text', 'Analysis Input:', 'WordWrap', 'on');
    analysisInputDropdown = uidropdown(panelDamage, 'Position', [360, 75, 80, 20], ...
'Items', {'Thermogram', 'SNR', 'Variance', 'Damage Indicator'}, 'Value', 'SNR', ...
'Tooltip', 'Select input for damage analysis', 'Tag', 'analysisInputDropdown');
    uilabel(panelDamage, 'Position', [310, 35, 60, 30], 'Text', 'Depth Method:', 'WordWrap', 'on');
    depthMethodDropdown = uidropdown(panelDamage, 'Position', [360, 45, 80, 20], ...
'Items', {'SNR', 'Diffusivity'}, 'Value', 'SNR', 'Tooltip', 'Select method for depth calculation', 'Tag', 'depthMethodDropdown');
    uilabel(panelDamage, 'Position', [310, 10, 60, 30], 'Text', 'Mode:');
    damageModeDropdown = uidropdown(panelDamage, 'Position', [360, 15, 80, 20], ...
'Items', {'Manual', 'Auto'}, 'Value', 'Auto', 'Tooltip', 'Damage detection mode', 'Tag', 'damageModeDropdown');
    btnMeasureDamage = uibutton(panelDamage, 'Position', [450, 55, 105, 35], 'Text', 'Measure Damage', ...
'ButtonPushedFcn', @callMeasureDamage, 'Tooltip', 'Measure damage area');
    btnQuantifyDamage = uibutton(panelDamage, 'Position', [450, 10, 105, 35], 'Text', 'Quantify Damage', ...
'ButtonPushedFcn', @callQuantifyDamage, 'Tooltip', 'Calculate Detailed Damage Stats');
    uilabel(panelDamage, 'Position', [400, 145, 100, 20], 'Text', 'Thresholding:', 'WordWrap','on');
    thresholdModeDropdown = uidropdown(panelDamage,'Position', [480, 145, 70, 20], ...
'Items', {'Single', 'Dual'}, 'Value', 'Single', 'Tooltip', 'Single: one threshold; Dual: low (material) + high (actuator)', ...
'Tag', 'thresholdModeDropdown');
    %% Panel 8: Camera and Actuator Settings
    panelCamera = uipanel(fig, 'Title', 'Camera and internal actuator settings', 'Position', [20, 150, 560, 100], 'FontWeight', 'bold', 'FontSize', 12);
    uilabel(panelCamera, 'Position', [5, 55, 90, 20], 'Text', 'Lens Size (mm):');
    lensSizeField = uieditfield(panelCamera, 'numeric', 'Position', [100, 55, 50, 20], 'Value', 13, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Focal length of lens', 'ValueChangedFcn', @updatePixelSize, 'Tag', 'lensSizeField');
    uilabel(panelCamera, 'Position', [5, 30, 90, 20], 'Text', 'Pixel Size (mm):');
    pixelSizeField = uieditfield(panelCamera, 'numeric', 'Position', [100, 30, 50, 20], 'Value', 0.6, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Calculated pixel size in scene', 'Enable', 'off', 'Tag', 'pixelSizeField');
    uilabel(panelCamera, 'Position', [5, 5, 90, 20], 'Text', 'Total Frames:');
    totalFramesField = uieditfield(panelCamera, 'numeric', 'Position', [100, 7, 50, 20], 'Value', 3832, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Total captured frames', 'Tag', 'totalFramesField');
    uilabel(panelCamera, 'Position', [200, 55, 115, 20], 'Text', 'Frame Rate (Hz):');
    frameRateField = uieditfield(panelCamera, 'numeric', 'Position', [300, 55, 50, 20], 'Value', 383, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Image capture frequency', 'ValueChangedFcn', @updateFrameRate, 'Tag', 'frameRateField');
    uilabel(panelCamera, 'Position', [200, 30, 90, 20], 'Text', 'Distance (mm):');
    distanceField = uieditfield(panelCamera, 'numeric', 'Position', [300, 30, 50, 20], 'Value', 155, 'Limits', [1 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Distance to sample', 'ValueChangedFcn', @updatePixelSize, 'Tag', 'distanceField');
    uilabel(panelCamera, 'Position', [200, 5, 90, 20], 'Text', 'Time Interval (s):');
    timeIntervalField = uieditfield(panelCamera, 'numeric', 'Position', [300, 7, 50, 20], 'Value', 6, 'Limits', [1 20], 'LowerLimitInclusive', 'on', 'Tooltip', 'Time interval for diffusivity calc (seconds)', 'Tag', 'timeIntervalField');
    uilabel(panelCamera, 'Position', [380, 5, 120, 20], 'Text', 'Start Time (s):');
    startTimeField = uieditfield(panelCamera, 'numeric', 'Position', [500, 5, 50, 20], 'Value', 0.1, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Start time for diffusivity calc (seconds)', 'Tag', 'startTimeField');
    uilabel(panelCamera, 'Position', [380, 55, 120, 20], 'Text', 'Source Depth (mm):');
    sourceDepthField = uieditfield(panelCamera, 'numeric', 'Position', [500, 55, 50, 20], 'Value', 1.8, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Depth of heat source', 'Tag', 'sourceDepthField');
    uilabel(panelCamera, 'Position', [380, 30, 90, 20], 'Text', 'Pulse Dur (ms):');
    pulseDurationField = uieditfield(panelCamera, 'numeric', 'Position', [500, 30, 50, 20], 'Value', 3000, 'Limits', [0 Inf], 'LowerLimitInclusive', 'on', 'Tooltip', 'Heat pulse duration', 'Tag', 'pulseDurationField');
    %% Panel 9: Processing Sequence and Settings (External Heat Source)
    panelSequence = uipanel(fig, 'Title', 'Processing Sequence and Settings (External Heat Source)', 'Position', [20, 30, 560, 120], 'FontWeight', 'bold', 'FontSize', 12);
    chkFlash = uicheckbox(panelSequence, 'Text', 'Est. Flash', 'Position', [10, 80, 70, 20], 'Value', true, 'Tooltip', 'Estimate flash frame');
    uilabel(panelSequence, 'Position', [110, 80, 80, 20], 'Text', 'Flash Frame:');
    flashFrameLabel = uilabel(panelSequence, 'Position', [185, 80, 50, 20], 'Text', 'N/A', 'FontWeight', 'bold');
    chkTSR = uicheckbox(panelSequence, 'Text', 'TSR', 'Position', [10, 60, 50, 20], 'Value', true);
    uilabel(panelSequence, 'Position', [110, 60, 70, 20], 'Text', 'TSR Order:');
    tsrOrderField = uieditfield(panelSequence, 'numeric', 'Position', [175, 60, 40, 20], 'Value', 4, 'Limits', [4 8], 'Tooltip', 'Polynomial order for TSR');
    uilabel(panelSequence, 'Position', [250, 80, 80, 20], 'Text', 'Next Step:');
    methodGroup = uibuttongroup(panelSequence, 'Position', [250, 35, 60, 45]);
    radioPCT = uiradiobutton(methodGroup, 'Text', 'PCT', 'Position', [10, 25, 50, 20]);
    radioPPT = uiradiobutton(methodGroup, 'Text', 'PPT', 'Position', [10, 5, 50, 20], 'Value', true);
    btnRunSequence = uibutton(panelSequence, 'Position', [470, 55, 80, 40], 'Text', 'Run', 'ButtonPushedFcn', @runSequence);
    btnShowResults = uibutton(panelSequence, 'Position', [470, 10, 80, 40], 'Text', 'Show', 'ButtonPushedFcn', @showResults, 'Enable', 'off');
    chkUseCropped = uicheckbox(panelSequence, 'Text', 'Cropped Data', 'Position', [10, 40, 130, 20], 'Value', false, 'Tooltip', 'Process cropped data instead of full data');
    uilabel(panelSequence, 'Position', [350, 80, 100, 20], 'Text', 'Select Output:');
    pctPptSelector = uidropdown(panelSequence, 'Position', [350, 40, 90, 40], 'Items', {'N/A'}, 'Value', 'N/A', 'Tooltip', 'Select PCT component or PPT frequency');
    uilabel(panelSequence, 'Position', [10, 10, 90, 20], 'Text', 'Window Type:');
    pptWindowDropdown = uidropdown(panelSequence, 'Position', [90, 10, 90, 20], 'Items', {'hamming', 'hann', 'blackman', 'rectangular', 'flattop'}, 'Value', 'hamming');
    uilabel(panelSequence, 'Position', [200, 10, 80, 20], 'Text', 'Zero-Padding:');
    pptPadField = uieditfield(panelSequence, 'numeric', 'Position', [280, 10, 50, 20], 'Value', 0, 'Limits', [0 Inf], 'Tooltip', 'Frames to pad for FFT');
    uilabel(panelSequence, 'Position', [350, 10, 70, 20], 'Text', 'Truncation:');
    pptTruncField = uieditfield(panelSequence, 'numeric', 'Position', [420, 10, 40, 20], 'Value', 1, 'Limits', [1 Inf], 'Tooltip', 'Frames to skip post-flash');
    %% Variables to store data and analysis results
    thermaldata = [];
    croppedData = [];
    snr_per_pixel = [];
    variance_per_pixel = [];
    damage_indicator = [];
    thermogram_slice = [];
    flashAnalysis = [];
    croppedAnalysis = [];
    currentAnalysis = [];
    frameRate = 383;
    timeVector = [];
    x = 1; y = 1; width = 1; height = 1;
    %% getFieldValue
function val = getFieldValue(field, default)
        val = default;
if ~isempty(field) && isprop(field, 'Value')
            val = field.Value;
end
end
    %% Nested Functions
function toggleWeightedMethod(src, ~)
    if nargin < 1 || isempty(src)
        src = useWeightedCheckbox;
    end

        snrWeightField = findobj(fig, 'Tag', 'snrWeightField');
        varianceWeightField = findobj(fig, 'Tag', 'varianceWeightField');
        damageMethodDropdown = findobj(fig, 'Tag', 'damageMethodDropdown');
        currentMethod = damageMethodDropdown.Value;
% Only enable weights for the original "Weighted" method
if src.Value && strcmp(currentMethod, 'Weighted')
            snrWeightField.Enable = 'on';
            varianceWeightField.Enable = 'on';
else
            snrWeightField.Enable = 'off';
            varianceWeightField.Enable = 'off';
end
% Always refresh when toggling
if ~isempty(damage_indicator)
            generateDamageHeatmap([], []);
end
end
function updateDamageMethod(src, ~)
        selected = src.Value;
        scurveKField = findobj(fig, 'Tag', 'scurveKField');
        scurveX0Field = findobj(fig, 'Tag', 'scurveX0Field');
if strcmp(selected, 'S-Curve')
            scurveKField.Enable = 'on';
            scurveX0Field.Enable = 'on';
else
            scurveKField.Enable = 'off';
            scurveX0Field.Enable = 'off';
end
        toggleWeightedMethod(useWeightedCheckbox, []);
end

function updateWeights(src, ~)
        snrWeightField = findobj(fig, 'Tag', 'snrWeightField');
        varianceWeightField = findobj(fig, 'Tag', 'varianceWeightField');
        useWeightedCheckbox = findobj(fig, 'Tag', 'useWeightedCheckbox');
        damageMethodDropdown = findobj(fig, 'Tag', 'damageMethodDropdown');
        currentMethod = damageMethodDropdown.Value;
% Apply weighting for Weighted, Log Hybrid, AND Log Hybrid v2
if useWeightedCheckbox.Value && ismember(currentMethod, {'Weighted', 'Log Hybrid', 'Log Hybrid v2'})
if src == snrWeightField
                snrWeight = snrWeightField.Value;
                varianceWeightField.Value = 1 - snrWeight;
else
                varianceWeight = varianceWeightField.Value;
                snrWeightField.Value = 1 - varianceWeight;
end
            snrWeightField.Value = max(0, min(1, snrWeightField.Value));
            varianceWeightField.Value = max(0, min(1, varianceWeightField.Value));
% FORCE refresh for all supported methods
if ~isempty(damage_indicator)
                generateDamageHeatmap([], []);
end
end
end

function updateHeatmap(~, ~)
if ~isempty(damage_indicator)
            generateDamageHeatmap([], []);
end
end

function performDistanceMeasurement(~, ~)
        distanceMeasurementDropdown = findobj(fig, 'Tag', 'distanceMeasurementDropdown');
        selectedOption = distanceMeasurementDropdown.Value;
if contains(selectedOption, 'Manual Distance')
            measureDistance([], []);
elseif contains(selectedOption, 'Auto Distance')
            measureDistanceAuto([], []);
end
end

    function measureDistance(~, ~)
    if isempty(croppedAnalysis)
        uialert(fig, 'Crop data first.', 'Error');
        return;
    end
    pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
    useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
    distanceMeasurementDropdown = findobj(fig, 'Tag', 'distanceMeasurementDropdown');
    selectedOption = distanceMeasurementDropdown.Value;
    
    if contains(selectedOption, 'Frame')
        frameIndex = round(frameField.Value);
        if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
            uialert(fig, sprintf('Frame index must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
            return;
        end
        dataToDisplay = croppedAnalysis.data(:,:,frameIndex);
        dataToDisplay = flipud(dataToDisplay);
        dataToDisplay = applyFilters(dataToDisplay, true);
        titleText = sprintf('Select Points for Distance Measurement - Frame %d', frameIndex);
    elseif contains(selectedOption, 'SNR Heatmap')
        if isempty(snr_per_pixel)
            uialert(fig, 'Generate SNR heatmap first.', 'Error');
            return;
        end
        dataToDisplay = snr_per_pixel;
        titleText = 'Select Points for Distance Measurement - SNR Heatmap';
    elseif contains(selectedOption, 'Variance Heatmap')
        if isempty(variance_per_pixel)
            uialert(fig, 'Generate Variance heatmap first.', 'Error');
            return;
        end
        dataToDisplay = variance_per_pixel;
        titleText = 'Select Points for Distance Measurement - Variance Heatmap';
    elseif contains(selectedOption, 'Damage Indicator Heatmap')
        if isempty(damage_indicator)
            uialert(fig, 'Generate Damage Indicator heatmap first.', 'Error');
            return;
        end
        dataToDisplay = damage_indicator;
        titleText = 'Select Points for Distance Measurement - Damage Indicator Heatmap';
    else
        uialert(fig, 'Invalid measurement target selected.', 'Error');
        return;
    end
    
    figure('Name', titleText);
    [height, width] = size(dataToDisplay);
    if useMillimeters
        imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, dataToDisplay);
        xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
        ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
        % Optional nicer round numbers
        xt = xticks; xticks(unique(round(xt,1)));
        yt = yticks; yticks(unique(round(yt,1)));
    else
        imagesc(dataToDisplay);
        xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
    end
    colormap('jet');
    colorbar;
    title(titleText, 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold' );
    set(gca, 'YDir', 'normal');
    axis image;
    
    [x, y] = ginput(2);
    if isempty(x)
        uialert(fig, 'No points selected.', 'Warning');
        close(gcf);
        return;
    end
    
    % Debug: Print raw points
    disp(['Raw ginput points: (' num2str(x(1)) ', ' num2str(y(1)) ') to (' num2str(x(2)) ', ' num2str(y(2)) ')']);
    
    % Calculate distance based on scale mode
    distance_raw = sqrt((x(2) - x(1))^2 + (y(2) - y(1))^2);
    if useMillimeters
        distance_mm = distance_raw;  % Already in mm
        distance_pixels = distance_mm / pixelSize;
    else
        distance_pixels = distance_raw;  % In pixels
        distance_mm = distance_pixels * pixelSize;
    end
    
    hold on;
    plot(x, y, 'ro', 'MarkerSize', 5, 'LineWidth', 2);
    plot(x, y, 'b-', 'LineWidth', 2);
    if useMillimeters
        text(mean(x), mean(y), sprintf('%.2f mm', distance_mm), ...
            'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', 'black', 'Margin', 2);
        uialert(fig, sprintf('Distance: %.2f mm (%.2f pixels)', distance_mm, distance_pixels), ...
            'Distance Measurement');
    else
        text(mean(x), mean(y), sprintf('%.2f pixels', distance_pixels), ...
            'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold', ...
            'BackgroundColor', 'black', 'Margin', 2);
        uialert(fig, sprintf('Distance: %.2f pixels (%.2f mm)', distance_pixels, distance_mm), ...
            'Distance Measurement');
    end
    hold off;
end
function measureDistanceAuto(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        distanceMeasurementDropdown = findobj(fig, 'Tag', 'distanceMeasurementDropdown');
        selectedOption = distanceMeasurementDropdown.Value;
        threshold = getFieldValue(findobj(fig,'Tag','thresholdField'),2);
if contains(selectedOption, 'Frame')
            frameIndex = round(frameField.Value);
if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
                uialert(fig, sprintf('Frame index must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
return;
end
            dataToDisplay = croppedAnalysis.data(:,:,frameIndex);
            dataToDisplay = flipud(dataToDisplay);
            dataToAnalyze = applyFilters(dataToDisplay, false);
            titleText = sprintf('Automated Distance Measurement - Frame %d', frameIndex);
            binaryImage = dataToAnalyze > threshold * mean(dataToAnalyze(:));
elseif contains(selectedOption, 'SNR Heatmap')
if isempty(snr_per_pixel)
                uialert(fig, 'Generate SNR heatmap first.', 'Error');
return;
end
            dataToDisplay = snr_per_pixel;
            dataToAnalyze = snr_per_pixel;
            titleText = 'Automated Distance Measurement - SNR Heatmap';
            binaryImage = dataToAnalyze > threshold * mean(dataToAnalyze(:));
elseif contains(selectedOption, 'Variance Heatmap')
if isempty(variance_per_pixel)
                uialert(fig, 'Generate Variance heatmap first.', 'Error');
return;
end
            dataToDisplay = variance_per_pixel;
            dataToAnalyze = variance_per_pixel;
            titleText = 'Automated Distance Measurement - Variance Heatmap';
            binaryImage = dataToAnalyze > threshold * mean(dataToAnalyze(:));
elseif contains(selectedOption, 'Damage Indicator Heatmap')
if isempty(damage_indicator)
                uialert(fig, 'Generate Damage Indicator heatmap first.', 'Error');
return;
end
            dataToDisplay = damage_indicator;
            dataToAnalyze = damage_indicator;
            titleText = 'Automated Distance Measurement - Damage Indicator Heatmap';
            binaryImage = dataToAnalyze > threshold * mean(dataToAnalyze(:));
else
            uialert(fig, 'Invalid measurement target selected.', 'Error');
return;
end
        binaryImage = imopen(binaryImage, strel('disk', 3));
        binaryImage = imclose(binaryImage, strel('disk', 5));
        cc = bwconncomp(binaryImage);
if cc.NumObjects < 2
            uialert(fig, 'Fewer than two regions detected.', 'Error');
return;
end
        stats = regionprops(cc, 'Centroid', 'Area');
        [~, sortedIndices] = sort([stats.Area], 'descend');
if length(sortedIndices) < 2
            uialert(fig, 'Not enough regions to measure distance.', 'Error');
return;
end
        centroid1 = stats(sortedIndices(1)).Centroid;
        centroid2 = stats(sortedIndices(2)).Centroid;
        distance_pixels = sqrt((centroid2(1) - centroid1(1))^2 + (centroid2(2) - centroid1(2))^2);
        distance_mm = distance_pixels * pixelSize;
        figure('Name', titleText);
        [height, width] = size(dataToDisplay);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, dataToDisplay);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(dataToDisplay);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colormap('jet');
        colorbar;
        title(titleText, 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        set(gca, 'YDir', 'normal');
        axis image;
        hold on;
        plot(centroid1(1), centroid1(2), 'ro', 'MarkerSize', 5, 'LineWidth', 2);
        plot(centroid2(1), centroid2(2), 'ro', 'MarkerSize', 5, 'LineWidth', 2);
        plot([centroid1(1), centroid2(1)], [centroid1(2), centroid2(2)], 'b-', 'LineWidth', 2);
if useMillimeters
            text(mean([centroid1(1), centroid2(1)]), mean([centroid1(2), centroid2(2)]), ...
                sprintf('%.2f mm', distance_mm), 'Color', 'white', 'FontSize', 12, ...
'FontWeight', 'bold', 'BackgroundColor', 'black', 'Margin', 2);
            uialert(fig, sprintf('Distance: %.2f mm (%.2f pixels)', distance_mm, distance_pixels), ...
'Automated Distance Measurement');
else
            text(mean([centroid1(1), centroid2(1)]), mean([centroid1(2), centroid2(2)]), ...
                sprintf('%.2f pixels', distance_pixels), 'Color', 'white', 'FontSize', 12, ...
'FontWeight', 'bold', 'BackgroundColor', 'black', 'Margin', 2);
            uialert(fig, sprintf('Distance: %.2f pixels (%.2f mm)', distance_pixels, distance_mm), ...
'Automated Distance Measurement');
end
        hold off;
end

function autoSetSCurveFromDiffusivity(~, ~)
        hFig = findobj('Type', 'figure', 'Name', 'Frame-Averaged Temperature Rise');
if isempty(hFig)
            uialert(fig, 'First click "Calculate Diffusion" to generate the curve.', 'No Curve Found');
return;
end
        hLine = findobj(hFig, 'Type', 'line', 'Color', 'r');
if isempty(hLine)
            uialert(fig, 'Smoothed curve not found.', 'Error');
return;
end
        tempSmoothed = hLine.YData;
        tempNorm = (tempSmoothed - min(tempSmoothed)) / (max(tempSmoothed) - min(tempSmoothed) + eps);
        sorted = sort(tempNorm);
        n = length(sorted);
        x0 = sorted(round(0.5*n));
        k = 8 / (sorted(round(0.9*n)) - sorted(round(0.1*n)));
        k = k * 3.5; % boost for sharpness
        scurveKField.Value = round(k, 1);
        scurveX0Field.Value = round(x0, 3);
        uialert(fig, sprintf('S-Curve auto-set!\nk = %.1f\nx0 = %.3f\n\nNow click Damage Indicator', k, x0), 'Auto S-Curve');
        generateDamageHeatmap([], []);
end

function calcDiffusivity(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        frameRate = getFieldValue(findobj(fig,'Tag','frameRateField'),383);
        totalFrames = getFieldValue(findobj(fig,'Tag','totalFramesField'),3832);
        pulseDuration = getFieldValue(findobj(fig,'Tag','pulseDurationField'),3000)/1000;
        bgFrames = round(getFieldValue(findobj(fig,'Tag','bgFrameField'),20));
        timeInterval = getFieldValue(findobj(fig,'Tag','timeIntervalField'),6);
        pulseStartTime = getFieldValue(findobj(fig,'Tag','startTimeField'),0.1);
        sourceDepth = getFieldValue(findobj(fig,'Tag','sourceDepthField'),1.8);
        thermalDiffusivityField = findobj(fig,'Tag','thermalDiffusivityField');
        tempProfile = squeeze(mean(croppedAnalysis.data, [1 2], 'double'));
        time = (0:totalFrames-1) / frameRate;
        pulseStartFrame = round(pulseStartTime * frameRate) + 1;
        pulseEndTime = pulseStartTime + pulseDuration;
        pulseEndFrame = round(pulseEndTime * frameRate) + 1;
        backgroundTemp = mean(tempProfile(1:bgFrames));
        tempProfile = tempProfile - backgroundTemp;
        windowSize = 50;
        tempProfileSmoothed = movmean(tempProfile, windowSize);
if max(tempProfileSmoothed) <= 0
            uialert(fig, 'No detectable heat pulse in data.', 'Error');
return;
end
        sampleEndTime = pulseStartTime + timeInterval;
        sampleEndFrame = min(round(sampleEndTime * frameRate) + 1, totalFrames);
if sampleEndFrame <= pulseStartFrame
            uialert(fig, 'Time interval is too short or start time is too late.', 'Error');
return;
end
        t1 = time(pulseStartFrame) - pulseStartTime;
        t2 = time(sampleEndFrame) - pulseStartTime;
        T1 = tempProfileSmoothed(pulseStartFrame);
        T2 = tempProfileSmoothed(sampleEndFrame);
        deltaT = T2 - T1;
        delta_t = t2 - t1;
        alpha = (sourceDepth^2) / (4 * delta_t) * (deltaT / max(tempProfileSmoothed));
        alpha = double(alpha(1));
if alpha <= 0 || alpha > 1
            uialert(fig, sprintf('Invalid diffusivity: %.3f mm²/s.', alpha), 'Error');
return;
end
if ~isempty(thermalDiffusivityField)
            thermalDiffusivityField.Value = alpha;
else
            uialert(fig, 'Thermal Diffusivity field not found. Cannot update value.', 'Error');
return;
end
        uialert(fig, sprintf('Frame-Averaged Diffusivity: %.3f mm²/s', alpha), 'Result');
        hFig = figure('Name', 'Frame-Averaged Temperature Rise');
        plot(time, tempProfile, 'b-', 'DisplayName', 'Raw');
        hold on;
        plot(time, tempProfileSmoothed, 'r-', 'DisplayName', 'Smoothed');
        plot(time(pulseStartFrame), T1, 'go', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Start');
        plot(time(sampleEndFrame), T2, 'gx', 'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', sprintf('End (%.1f s)', delta_t));
        xlabel('Time (s)');
        ylabel('Average Temperature');
        title('Frame-Averaged Temperature Rise');
        legend;
        grid on;
        hold off;
        exportgraphics(hFig, 'FrameAveragedTemperatureRise.png', 'Resolution', 300);
        uialert(fig, 'Graph saved as FrameAveragedTemperatureRise.png', 'Success');
end

function updatePixelSize(~, ~)
        detectorPitch = 0.03;
        focalLength = lensSizeField.Value;
        distance = distanceField.Value;
if focalLength > 0
            ifov = detectorPitch / focalLength;
            pixelSize = distance * ifov;
            pixelSizeField.Value = pixelSize;
else
            pixelSizeField.Value = 0;
end
end

function updateFrameRate(~, ~)
        frameRate = frameRateField.Value;
end

function loadFile(~, ~)
        [filename, filepath] = uigetfile('*.hcc', 'Select Thermal Data File');
if isequal(filename, 0)
            uialert(fig, 'No file selected.', 'Warning');
return;
end
        fpath = fullfile(filepath, filename);
try
            readData = TelopsRead(filename, filepath);
            thermaldata = readData.data;
            timeVector = readData.time;
            frameRate = readData.fps;
if frameRate <= 0 || isnan(frameRate)
                frameRate = 383;
                uialert(fig, 'Invalid frame rate in file. Using default (383 Hz).', 'Warning');
end
            frameRateField.Value = frameRate;
            flashAnalysis = PulseThermography2(thermaldata, frameRateField.Value, timeVector);
            croppedAnalysis = [];
catch ME
            uialert(fig, sprintf('Error loading file: %s', ME.message), 'Error');
end
end

function cropRegion(~, ~)
if isempty(thermaldata)
            uialert(fig, 'Load a file first.', 'Error');
return;
end
        initialFrame = thermaldata(:,:,1);
        cropFig = figure('Name', 'Select Cropping Region');
        imshow(initialFrame, []);
        h = imrect;
        position = wait(h);
        close(cropFig);
        x = max(1, round(position(1)));
        y = max(1, round(position(2)));
        width = round(position(3));
        height = round(position(4));
if width <= 0 || height <= 0
            uialert(fig, 'Invalid cropping region: Width and height must be positive.', 'Error');
return;
end
        x_end = min(x + width - 1, size(thermaldata, 2));
        y_end = min(y + height - 1, size(thermaldata, 1));
        croppedData = thermaldata(y:y_end, x:x_end, :);
        croppedAnalysis = PulseThermography2(croppedData, frameRateField.Value, timeVector);
        croppedAnalysis.setFramestoaverage(round(bgFrameField.Value));
        croppedAnalysis.performAnalysis({'subtractreferenceframe'});
        thermalDiffusivityField.Enable = 'on';
        disp(['croppedAnalysis.data size after crop: ', num2str(size(croppedAnalysis.data))]);
end

function setBgFrames(~, ~)
if isempty(thermaldata)
            uialert(fig, 'Load a file first.', 'Error');
return;
end
if ~isempty(flashAnalysis)
            flashAnalysis.setFramestoaverage(round(bgFrameField.Value));
            flashAnalysis.performAnalysis({'subtractreferenceframe'});
end
if ~isempty(croppedAnalysis)
            croppedAnalysis.setFramestoaverage(round(bgFrameField.Value));
            croppedAnalysis.performAnalysis({'subtractreferenceframe'});
end
        uialert(fig, 'Background frames updated.', 'Success');
end
function clearData(~, ~)
        thermaldata = [];
        croppedData = [];
        snr_per_pixel = [];
        variance_per_pixel = [];
        damage_indicator = [];
        flashAnalysis = [];
        croppedAnalysis = [];
        timeVector = [];
        frameRate = 383;
        frameRateField.Value = frameRate;
        x = 1; y = 1; width = 1; height = 1;
        btnShowResults.Enable = 'off';
        flashFrameLabel.Text = 'N/A';
        uialert(fig, 'Data cleared successfully!', 'Success');
end

function resetBackground(~, ~)
if isempty(thermaldata)
            uialert(fig, 'Load a file first.', 'Error');
return;
end
        bgFrameField.Value = 20;
if ~isempty(flashAnalysis)
            flashAnalysis.setFramestoaverage(round(bgFrameField.Value));
            flashAnalysis.performAnalysis({'subtractreferenceframe'});
end
if ~isempty(croppedAnalysis)
            croppedAnalysis.setFramestoaverage(round(bgFrameField.Value));
            croppedAnalysis.performAnalysis({'subtractreferenceframe'});
end
        uialert(fig, 'Background frames reset to default!', 'Success');
end

function [filteredFrame] = applyFilters(frame, adjust)
if nargin < 2, adjust = true; end
        selectedFilters = filterDropdown.Value;
if ischar(selectedFilters) || (isstring(selectedFilters) && isscalar(selectedFilters))
            selectedFilters = cellstr(selectedFilters);
elseif ~iscellstr(selectedFilters) && ~isstring(selectedFilters)
            selectedFilters = {};
end
        frameFiltered = frame;
for i = 1:numel(selectedFilters)
            filterType = selectedFilters{i};
            filterSize = round(filterSizeField.Value);
            sigma = sigmaField.Value;
switch filterType
case 'Gaussian'
                    frameFiltered = imgaussfilt(frameFiltered, sigma, 'FilterSize', [filterSize filterSize]);
case 'Average'
                    frameFiltered = imfilter(frameFiltered, fspecial('average', filterSize));
case 'Median'
                    frameFiltered = medfilt2(frameFiltered, [filterSize filterSize]);
end
end
if adjust
            filteredFrame = imadjust(frameFiltered);
else
            filteredFrame = frameFiltered;
end
end
function filteredData = applyFilters3D(data)
        selectedFilters = filterDropdown.Value;
if ischar(selectedFilters) || (isstring(selectedFilters) && isscalar(selectedFilters))
            selectedFilters = cellstr(selectedFilters);
elseif ~iscellstr(selectedFilters) && ~isstring(selectedFilters)
            selectedFilters = {};
end
        filteredData = data;
        filterSize = round(filterSizeField.Value);
        sigma = sigmaField.Value;
for i = 1:numel(selectedFilters)
            filterType = selectedFilters{i};
switch filterType
case 'Gaussian'
                    filteredData = imgaussfilt(filteredData, sigma, 'FilterSize', [filterSize filterSize], 'Padding', 'replicate');
case 'Average'
                    h = fspecial('average', filterSize);
for k = 1:size(filteredData, 3)
                        filteredData(:,:,k) = imfilter(filteredData(:,:,k), h, 'replicate');
end
case 'Median'
                    filteredData = medfilt3(filteredData, [filterSize filterSize 1], 'replicate');
end
end
end

function previewFilter(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        frameIndex = round(frameField.Value);
if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
            uialert(fig, sprintf('Frame index must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameToDisplay = croppedAnalysis.data(:,:,frameIndex);
        frameToDisplay = flipud(frameToDisplay);
        frameAdjusted = applyFilters(frameToDisplay, true);
        figure('Name', ['Filtered Frame ' num2str(frameIndex)]);
        [height, width] = size(frameAdjusted);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameAdjusted);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(frameAdjusted);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colormap('gray');
        title(['Filtered Frame ' num2str(frameIndex)], 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        set(gca, 'YDir', 'normal');
        axis image;
end

function showFrame(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        frameIndex = round(frameField.Value);
if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
            uialert(fig, sprintf('Frame index must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameToDisplay = croppedAnalysis.data(:,:,frameIndex);
        frameToDisplay = flipud(frameToDisplay);
        frameAdjusted = applyFilters(frameToDisplay, true);
        figure('Name', ['Frame ' num2str(frameIndex)]);
        [height, width] = size(frameAdjusted);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameAdjusted);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(frameAdjusted);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colormap('gray');
        title(['Frame ' num2str(frameIndex)], 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        set(gca, 'YDir', 'normal');
        axis image;
        disp('showFrame: Updating thermogram slice');
        updateThermogramSlice([], []);
end

function showSurfacePlot(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        frameIndex = round(frameField.Value);
if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
            uialert(fig, sprintf('Frame index must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameToDisplay = croppedAnalysis.data(:,:,frameIndex);
        frameToDisplay = flipud(frameToDisplay);
        frameAdjusted = applyFilters(frameToDisplay, true);
        figure('Name', ['Surface Plot Frame ' num2str(frameIndex)]);
        [xSize, ySize] = size(frameAdjusted);
if useMillimeters
            X = (1:ySize)*pixelSize;
            Y = (1:xSize)*pixelSize;
            xlabel('X-axis (mm)', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
            ylabel('Y-axis (mm)', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
else
            X = 1:ySize;
            Y = 1:xSize;
            xlabel('X-axis (Pixel)', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
            ylabel('Y-axis (Pixel)', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
end
        [X, Y] = meshgrid(X, Y);
        surf(X, Y, frameAdjusted);
        title(['Thermal Surface Plot at Frame ' num2str(frameIndex)], 'FontName', 'Arial', 'FontSize', 22, 'FontWeight', 'bold');
        zlabel('Temperature', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        colormap('jet');
        colorbar;
        set(gca, 'FontSize', 18);
        set(gcf, 'Color', 'w');
        set(gca, 'YDir', 'normal');
end

function createMP4(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        [filename, filepath] = uiputfile('*.mp4', 'Save MP4 Video', 'thermal_animation.mp4');
if isequal(filename, 0)
            uialert(fig, 'No file selected.', 'Warning');
return;
end
        videoFilename = fullfile(filepath, filename);
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        videoWriter = VideoWriter(videoFilename, 'MPEG-4');
        videoWriter.Quality = 100;
        videoWriter.FrameRate = 15;
        open(videoWriter);
        startIndex = 1;
        frameInterval = round(mp4IntervalField.Value);
if frameInterval < 1
            frameInterval = 1;
            mp4IntervalField.Value = 1;
            uialert(fig, 'Frame interval must be at least 1. Set to 1.', 'Warning');
end
        endIndex = size(croppedAnalysis.data, 3);
        selectedFilters = filterDropdown.Value;
if isempty(selectedFilters)
            uialert(fig, 'No filter selected for MP4 creation.', 'Warning');
            close(videoWriter);
return;
end
        disp('Applying 3D filters to all frames...');
        filteredData = applyFilters3D(croppedAnalysis.data(:,:,startIndex:frameInterval:endIndex));
        frameCount = size(filteredData, 3);
        [height, width] = size(filteredData(:,:,1));
for i = 1:frameCount
            frameToWrite = filteredData(:,:,i);
            frameToWrite = flipud(frameToWrite);
            frameMin = min(frameToWrite(:));
            frameMax = max(frameToWrite(:));
if frameMax > frameMin
                frameToWrite = (frameToWrite - frameMin) / (frameMax - frameMin);
end
            frameToWrite = uint8(frameToWrite * 255);
            originalFrameIndex = startIndex + (i-1) * frameInterval;
            figTemp = figure('Visible', 'off');
            if useMillimeters
                imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameToWrite);
                xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
                % Optional nicer round numbers
                xt = xticks; xticks(unique(round(xt,1)));
                yt = yticks; yticks(unique(round(yt,1)));
            else
                imagesc(frameToWrite);
                xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
                ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            end
            colormap('gray');
            set(gca, 'YDir', 'normal');
            axis image;
            title(sprintf('Frame %d', originalFrameIndex));
            frame = getframe(figTemp);
            writeVideo(videoWriter, frame.cdata);
            close(figTemp);
            drawnow;
end
        close(videoWriter);
        uialert(fig, sprintf('MP4 video created successfully at: %s', videoFilename), 'Success');
end

function calculateSNRandVariance(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        z_dim = size(croppedAnalysis.data, 3);
if z_dim < 1
            uialert(fig, 'No frames available.', 'Error');
return;
end
        snr_values = zeros(1, z_dim);
        variance_values = zeros(1, z_dim);
        selectedMethod = snrVarMethodDropdown.Value;
        bgFrames = round(bgFrameField.Value);
if bgFrames >= z_dim
            bgFrames = max(1, z_dim - 1);
            disp(['Adjusted bgFrames to ', num2str(bgFrames)]);
end
        hWait = waitbar(0, 'Calculating SNR and Variance...');
        bg_mean = mean(croppedAnalysis.data(:,:,1:bgFrames), 3);
for idx = 1:z_dim
            frameToDisplay = croppedAnalysis.data(:,:,idx);
            frameFiltered = applyFilters(frameToDisplay, false);
if strcmp(selectedMethod, 'Per Pixel')
                signal_power = frameFiltered.^2;
                noise_power = std(frameFiltered(:))^2;
                snr = 10 * log10(signal_power / (noise_power + eps));
                snr_values(idx) = mean(snr(:));
                variance_values(idx) = var(frameFiltered(:));
else
                signal_power = mean(frameFiltered(:))^2;
                noise_power = std(frameFiltered(:))^2;
                snr_values(idx) = 10 * log10(signal_power / (noise_power + eps));
                variance_values(idx) = var(frameFiltered(:));
end
            waitbar(idx / z_dim, hWait);
end
        close(hWait);
if all(snr_values == 0) && all(variance_values == 0)
            uialert(fig, 'SNR and Variance values are all zero. Check data or filters.', 'Warning');
return;
end
        figure('Name', 'SNR & Variance');
        yyaxis left;
        plot(1:z_dim, snr_values, 'o-', 'DisplayName', 'SNR');
        ylabel('SNR (dB)');
        hold on;
        yyaxis right;
        plot(1:z_dim, variance_values, 'x-', 'DisplayName', 'Variance');
        ylabel('Variance');
        title(sprintf('SNR & Variance (%s)', selectedMethod));
        xlabel('Frame Index');
        legend;
        grid on;
        hold off;
end

function updateThermogramSlice(~, ~)
if isempty(croppedAnalysis)
            thermogram_slice = [];
            disp('updateThermogramSlice: croppedAnalysis is empty');
return;
end
        frameIndex = round(frameField.Value);
        disp(['updateThermogramSlice: frameIndex = ', num2str(frameIndex)]);
if frameIndex < 1 || frameIndex > size(croppedAnalysis.data, 3)
            thermogram_slice = [];
            disp(['updateThermogramSlice: Invalid frame index, data size = ', num2str(size(croppedAnalysis.data))]);
return;
end
        thermogram_slice = croppedAnalysis.data(:,:,frameIndex);
        thermogram_slice = applyFilters(thermogram_slice, false);
        thermogram_slice = flipud(thermogram_slice);
        disp(['updateThermogramSlice: thermogram_slice size = ', num2str(size(thermogram_slice))]);
end

function previewThermogram(~, ~)
if isempty(thermogram_slice)
            uialert(fig, 'Generate thermogram slice first by generating heatmaps.', 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        figure('Name', 'Thermogram Slice Preview');
        [height, width] = size(thermogram_slice);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, thermogram_slice);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(thermogram_slice);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colormap('jet');
        colorbar;
        title('Thermogram Anomaly Map', 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        axis image;
        set(gca, 'YDir', 'normal');
end

function generateHeatmaps(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
        startFrame = round(startFrameField.Value);
        endFrame = round(endFrameField.Value);
if startFrame < 1 || endFrame > size(croppedAnalysis.data, 3) || startFrame > endFrame
            uialert(fig, sprintf('Invalid frame range: Must be between 1 and %d.', size(croppedAnalysis.data, 3)), 'Error');
return;
end
% Get pixel size
        pixelSizeField = findobj(fig, 'Tag', 'pixelSizeField');
if ~isempty(pixelSizeField) && isprop(pixelSizeField, 'Value')
            pixelSize = pixelSizeField.Value; % mm per pixel
else
            pixelSize = 0.6;
            uialert(fig, 'Pixel Size field not found. Using default value of 0.6 mm.', 'Warning');
end
% Get scaling preference
        scaleUnitsCheckbox = findobj(fig, 'Tag', 'scaleUnitsCheckbox');
        useMillimeters = scaleUnitsCheckbox.Value;
        hWait = waitbar(0, 'Generating Heatmaps...');
        waitbar(0.2, hWait, 'Slicing and Filtering Data...');
        sliced_data = croppedAnalysis.data(:,:,startFrame:endFrame);
        filteredData = applyFilters3D(sliced_data);
% Background frames for variance-based and hybrid noise power
        bgFrames = round(bgFrameField.Value);
if bgFrames < 1 || bgFrames > size(croppedAnalysis.data, 3)
            bgFrames = min(20, size(croppedAnalysis.data, 3));
            disp(['Adjusted bgFrames to ', num2str(bgFrames)]);
end
        bg_data = croppedAnalysis.data(:,:,1:bgFrames);
        bg_filteredData = applyFilters3D(bg_data);
        waitbar(0.6, hWait, 'Computing SNR and Variance...');
switch snrMethodDropdown.Value
case 'Mean-Based SNR'
                signal_power = mean(filteredData, 3).^2;
                noise_power = var(filteredData, 0, 3);
case 'Variance-Based SNR'
                pixel_mean = mean(filteredData, 3);
                centered_data = filteredData - pixel_mean;
                signal_power = mean(centered_data.^2, 3);
                bg_pixel_mean = mean(bg_filteredData, 3);
                bg_centered_data = bg_filteredData - bg_pixel_mean;
                noise_power = mean(bg_centered_data.^2, 3);
case 'Hybrid SNR'
                signal_power = mean(filteredData, 3).^2;
                bg_pixel_mean = mean(bg_filteredData, 3);
                bg_centered_data = bg_filteredData - bg_pixel_mean;
                noise_power = mean(bg_centered_data.^2, 3);
case 'Contrast-Based CNR'
% Compute per-pixel CNR
                bg_mean = mean(bg_filteredData, 3); % Per-pixel background mean
                bg_std = std(bg_filteredData, 0, 3); % Per-pixel background std (noise)
                signal_mean = mean(filteredData, 3); % Per-pixel signal mean
                contrast = abs(signal_mean - bg_mean);
                snr_per_pixel = contrast ./ (bg_std + eps); % CNR assigned to snr_per_pixel for damage compatibility


% snr_per_pixel = 20 * log10(snr_per_pixel + eps);
end
if ~strcmp(snrMethodDropdown.Value, 'Contrast-Based CNR')
            snr_per_pixel = 10 * log10(signal_power ./ (noise_power + eps));
end
        variance_per_pixel = var(filteredData, 0, 3);
        snr_per_pixel = flipud(snr_per_pixel);
        variance_per_pixel = flipud(variance_per_pixel);
        waitbar(0.8, hWait, 'Plotting Heatmaps...');
        snrMethod = snrMethodDropdown.Value;
% Plot SNR/CNR Heatmap (shared title based on method)
        figure('Name', 'Per-Pixel SNR/CNR Heatmap');
        [height, width] = size(snr_per_pixel);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, snr_per_pixel);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(snr_per_pixel);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colorbar;
if strcmp(snrMethodDropdown.Value, 'Contrast-Based CNR')
            title(sprintf('Per-Pixel CNR for Frames %d to %d', startFrame, endFrame), ...
'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
else
            title(sprintf('Per-Pixel SNR (dB) for Frames %d to %d (%s)', startFrame, endFrame, snrMethod), ...
'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
end
        colormap('jet');
        axis image;
        set(gca, 'YDir', 'normal');
% Plot Variance Heatmap
        figure('Name', 'Per-Pixel Variance Heatmap');
        [height, width] = size(variance_per_pixel);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, variance_per_pixel);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(variance_per_pixel);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colorbar;
        title(sprintf('Per-Pixel Variance for Frames %d to %d (%s)', startFrame, endFrame, snrMethod), ...
'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        colormap('jet');
        axis image;
        set(gca, 'YDir', 'normal');
        updateThermogramSlice([], []);
        waitbar(1, hWait, 'Heatmaps Generated');
        close(hWait);
end

function generateDamageHeatmap(~, ~)
if isempty(croppedAnalysis)
            uialert(fig, 'Crop data first.', 'Error');
return;
end
% === Get selected input ===
        analysisInputDropdown = findobj(fig, 'Tag', 'analysisInputDropdown');
        analysisInput = analysisInputDropdown.Value;
        selectedData = [];
        methodText = '';
switch analysisInput
case 'Thermogram'
if isempty(thermogram_slice)
                    uialert(fig, 'Show a frame first to generate thermogram slice.', 'Error');
return;
end
                selectedData = thermogram_slice;
                methodText = 'Thermogram';
case 'SNR'
if isempty(snr_per_pixel)
                    uialert(fig, 'Generate SNR heatmap first.', 'Error');
return;
end
                selectedData = snr_per_pixel;
                methodText = 'SNR Heatmap';
case 'Variance'
if isempty(variance_per_pixel)
                    uialert(fig, 'Generate Variance heatmap first.', 'Error');
return;
end
                selectedData = variance_per_pixel;
                methodText = 'Variance Heatmap';
case 'Damage Indicator'
if isempty(damage_indicator)
                    uialert(fig, 'Generate Damage Indicator first.', 'Error');
return;
end
                selectedData = damage_indicator;
                methodText = 'Damage Indicator';
otherwise
                uialert(fig, 'Invalid analysis input.', 'Error');
return;
end
% === Get DI Method and weights ===
        damageMethod = damageMethodDropdown.Value;
        useWeighted = useWeightedCheckbox.Value;
        snrWeight = getFieldValue(snrWeightField, 0.5);
        varWeight = 1 - snrWeight;
% === Always recompute norm_snr and norm_var from raw data (fixes Weighted and advanced methods) ===
        startFrame = round(getFieldValue(startFrameField, 1500));
        endFrame = round(getFieldValue(endFrameField, 2500));
        sliced_data = croppedAnalysis.data(:,:,startFrame:endFrame);
        filteredData = applyFilters3D(sliced_data);
        bgFrames = round(getFieldValue(bgFrameField, 20));
        bg_data = croppedAnalysis.data(:,:,1:bgFrames);
        bg_filteredData = applyFilters3D(bg_data);
switch snrMethodDropdown.Value
case 'Mean-Based SNR'
                signal_power = mean(filteredData, 3).^2;
                noise_power = var(filteredData, 0, 3);
case 'Variance-Based SNR'
                pixel_mean = mean(filteredData, 3);
                centered_data = filteredData - pixel_mean;
                signal_power = mean(centered_data.^2, 3);
                bg_pixel_mean = mean(bg_filteredData, 3);
                bg_centered_data = bg_filteredData - bg_pixel_mean;
                noise_power = mean(bg_centered_data.^2, 3);
case 'Hybrid SNR'
                signal_power = mean(filteredData, 3).^2;
                bg_pixel_mean = mean(bg_filteredData, 3);
                bg_centered_data = bg_filteredData - bg_pixel_mean;
                noise_power = mean(bg_centered_data.^2, 3);
case 'Contrast-Based CNR'
% Compute per-pixel CNR
                bg_mean = mean(bg_filteredData, 3); % Per-pixel background mean
                bg_std = std(bg_filteredData, 0, 3); % Per-pixel background std (noise)
                signal_mean = mean(filteredData, 3); % Per-pixel signal mean
                contrast = abs(signal_mean - bg_mean);
                snr_map = contrast ./ (bg_std + eps); % CNR assigned to snr_map
% Optional: Convert to dB (uncomment if desired)
                snr_map = 20 * log10(snr_map + eps);
end
if ~strcmp(snrMethodDropdown.Value, 'Contrast-Based CNR')
            snr_map = 10 * log10(signal_power ./ (noise_power + eps));
end
        var_map = var(filteredData, 0, 3);
        snr_map = flipud(snr_map);
        var_map = flipud(var_map);
        norm_snr_raw = (snr_map - min(snr_map(:))) / (max(snr_map(:)) - min(snr_map(:)) + eps);
        norm_var_raw = (var_map - min(var_map(:))) / (max(var_map(:)) - min(var_map(:)) + eps);
        norm_snr = 1 - norm_snr_raw;
        norm_var = 1 - norm_var_raw;
% === Normalize the selected input (only used for Multiplicative) ===
        norm_input = (selectedData - min(selectedData(:))) / (max(selectedData(:)) - min(selectedData(:)) + eps);
% === Apply Damage Indicator Method ===
switch damageMethod
case 'Multiplicative'
                damage_indicator = norm_snr .* norm_var;
                methodText = [methodText ' - Multiplicative'];
case 'Weighted'
                damage_indicator = snrWeight * norm_snr + varWeight * norm_var; % FIXED — correct maps
                methodText = sprintf('%s - Weighted (SNR: %.2f, Var: %.2f)', methodText, snrWeight, varWeight);
case 'Logarithmic Add'
                epsilon = 0.01;
                log_snr = log10(norm_snr_raw + epsilon);
                log_var = log10(norm_var_raw + epsilon);
                damage_indicator = log_snr + log_var;
                damage_indicator = (damage_indicator - min(damage_indicator(:))) / (max(damage_indicator(:)) - min(damage_indicator(:)) + eps);
                methodText = [methodText ' - Log Add'];
case 'Logarithmic Mult'
                epsilon = 0.01;
                log_snr = log10(norm_snr_raw + epsilon);
                log_var = log10(norm_var_raw + epsilon);
                damage_indicator = log_snr .* log_var;
                damage_indicator = (damage_indicator - min(damage_indicator(:))) / (max(damage_indicator(:)) - min(damage_indicator(:)) + eps);
                methodText = [methodText ' - Log Mult'];
case 'Log Hybrid'
                epsilon = 0.01;
                log_snr = log10(norm_snr_raw + epsilon);
                log_var = log10(norm_var_raw + epsilon);
                add_log = log_snr + log_var;
                mult_log = log_snr .* log_var;
                add_log = (add_log - min(add_log(:))) / (max(add_log(:)) - min(add_log(:)) + eps);
                mult_log = (mult_log - min(mult_log(:))) / (max(mult_log(:)) - min(mult_log(:)) + eps);
                damage_indicator = max(add_log, mult_log);
                methodText = [methodText ' - Log Hybrid'];
case 'Log Hybrid v2'
                epsilon = 1e-6;
                log_snr = log10(norm_snr_raw + epsilon);
                log_var = log10(norm_var_raw + epsilon);
                var_boost = 1.2;
                add_log = log_snr + var_boost * log_var;
                mult_log = log_snr .* (var_boost * log_var);
                add_log = (add_log - min(add_log(:))) / (max(add_log(:)) - min(add_log(:)) + eps);
                mult_log = (mult_log - min(mult_log(:))) / (max(mult_log(:)) - min(mult_log(:)) + eps);
                damage_indicator = max(add_log, mult_log);
                damage_indicator = imadjust(damage_indicator, [0.12 0.88], [0 1]);
                methodText = [methodText ' - Log Hybrid v2'];
case 'S-Curve'
                k = getFieldValue(scurveKField, 20);
                x0 = getFieldValue(scurveX0Field, 0.5);
                S_snr = 1 ./ (1 + exp(-k * (norm_snr_raw - x0)));
                S_var = 1 ./ (1 + exp(-k * (norm_var_raw - x0)));
                damage_indicator = max(S_snr, S_var);
                damage_indicator = (damage_indicator - min(damage_indicator(:))) / (max(damage_indicator(:)) - min(damage_indicator(:)) + eps);
                methodText = sprintf('%s - S-Curve (k=%.1f, x0=%.3f)', methodText, k, x0);
end
% === Plot ===
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'), 0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'), true);
        figure('Name', 'Damage Indicator Heatmap');
        [h, w] = size(damage_indicator);
        if useMillimeters
            imagesc((0:w-1)*pixelSize, (0:h-1)*pixelSize, damage_indicator);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(damage_indicator);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        colorbar;
        colormap('jet');
        title(methodText, 'FontSize', 16, 'FontWeight', 'bold');
        axis image;
        set(gca, 'YDir', 'normal');
end

function callMeasureDamage(~, ~)
        selectedInput = getSelectedInput();
if isempty(selectedInput)
            uialert(fig,'Select and generate a damage indicator first.','Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        thresholdMultiplier = getFieldValue(findobj(fig,'Tag','thresholdField'),2);
        frameRate = getFieldValue(findobj(fig,'Tag','frameRateField'),383);
        bgFrames = round(getFieldValue(findobj(fig,'Tag','bgFrameField'),20));
        sourceDepth = getFieldValue(findobj(fig,'Tag','sourceDepthField'),1.8);
        startFrame = round(getFieldValue(findobj(fig,'Tag','startFrameField'),1500));
        endFrame = round(getFieldValue(findobj(fig,'Tag','endFrameField'),2500));
        damageSNRStartFrame = round(getFieldValue(findobj(fig,'Tag','damageSNRStartFrameField'),startFrame));
        damageSNREndFrame = round(getFieldValue(findobj(fig,'Tag','damageSNREndFrameField'),endFrame));
        mode_value = damageModeDropdown.Value;
        analysisInput = analysisInputDropdown.Value;
        depthMethod = depthMethodDropdown.Value;
        thermalDiffusivity = getFieldValue(findobj(fig,'Tag','thermalDiffusivityField'),0.1);
        frameIndex = round(getFieldValue(findobj(fig,'Tag','frameField'),1));
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        thresholdMode = thresholdModeDropdown.Value;
if strcmpi(thresholdMode, 'Single')
            SingleThresholdDamageAnalysis.measureDamageArea(fig, croppedAnalysis, selectedInput, ...
                pixelSize, thresholdMultiplier, frameRate, bgFrames, sourceDepth, ...
                startFrame, endFrame, damageSNRStartFrame, damageSNREndFrame, ...
                mode_value, analysisInput, depthMethod, thermalDiffusivity, ...
                frameIndex, useMillimeters);
else
            DualThresholdDamageAnalysis.measureDamageArea(fig, croppedAnalysis, selectedInput, ...
                pixelSize, thresholdMultiplier, frameRate, bgFrames, sourceDepth, ...
                startFrame, endFrame, damageSNRStartFrame, damageSNREndFrame, ...
                mode_value, analysisInput, depthMethod, thermalDiffusivity, ...
                frameIndex, useMillimeters);
end
        uialert(fig,'Damage analysis complete.','Success');
end

function callQuantifyDamage(~, ~)
        selectedInput = getSelectedInput();
if isempty(selectedInput)
            uialert(fig, 'Generate a heatmap or thermogram first.', 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        thresholdMultiplier = getFieldValue(findobj(fig,'Tag','thresholdField'),2);
        thermalDiffusivity = getFieldValue(findobj(fig,'Tag','thermalDiffusivityField'),0.1);
        frameRate = getFieldValue(findobj(fig,'Tag','frameRateField'),383);
        bgFrames = round(getFieldValue(findobj(fig,'Tag','bgFrameField'),20));
        sourceDepth = getFieldValue(findobj(fig,'Tag','sourceDepthField'),1.8);
        damageSNRStartFrame = round(getFieldValue(findobj(fig,'Tag','damageSNRStartFrameField'),1500));
        damageSNREndFrame = round(getFieldValue(findobj(fig,'Tag','damageSNREndFrameField'),2500));
        analysisInput = analysisInputDropdown.Value;
        depthMethod = depthMethodDropdown.Value;
        QuantifyDamage.quantifyDamage(fig, croppedAnalysis, selectedInput, pixelSize, thresholdMultiplier, thermalDiffusivity, frameRate, bgFrames, sourceDepth, damageSNRStartFrame, damageSNREndFrame, analysisInput, depthMethod);
end

function input = getSelectedInput()
switch analysisInputDropdown.Value
case 'Thermogram'
                input = thermogram_slice;
case 'SNR'
                input = snr_per_pixel;
case 'Variance'
                input = variance_per_pixel;
case 'Damage Indicator'
                input = damage_indicator;
otherwise
                input = [];
end
end
function runSequence(~, ~)
if isempty(flashAnalysis)
            uialert(fig, 'Load a file first.', 'Error');
return;
end
        analysisObj = flashAnalysis;
if chkUseCropped.Value && ~isempty(croppedAnalysis)
            analysisObj = croppedAnalysis;
            disp('Using croppedAnalysis for flash pulse sequence.');
else
            disp('Using flashAnalysis for flash pulse sequence.');
end
        [validItems, selectedItem] = performFlashPulseSequence(...
            analysisObj, chkFlash.Value, chkTSR.Value, round(tsrOrderField.Value), ...
            radioPCT.Value, radioPPT.Value, pptWindowDropdown.Value, ...
            round(pptPadField.Value), round(pptTruncField.Value));
        pctPptSelector.Items = validItems;
        pctPptSelector.Value = selectedItem;
        flashFrameLabel.Text = num2str(analysisObj.flashframe);
        currentAnalysis = analysisObj;
        btnShowResults.Enable = 'on';
        uialert(fig, 'Processing sequence completed!', 'Success');
end
function showResults(~, ~)
if isempty(currentAnalysis)
            uialert(fig, 'Run the processing sequence first.', 'Error');
return;
end
        selectedItem = pctPptSelector.Value;
if chkTSR.Value && ~isempty(currentAnalysis.tsrTemperature)
            displayTSRResults(currentAnalysis, frameField.Value, fig);
elseif radioPCT.Value && ~isempty(currentAnalysis.pctOutput)
            displayPCTResults(currentAnalysis, selectedItem, fig);
elseif radioPPT.Value && ~isempty(currentAnalysis.pptPhase)
            displayPPTResults(currentAnalysis, selectedItem, fig);
else
            uialert(fig, 'Selected item not recognized or data unavailable.', 'Error');
end
end

function displayTSRResults(analysisObj, frameIdx, fig)
if frameIdx < 1 || frameIdx > size(analysisObj.tsrTemperature, 3)
            uialert(fig, 'Invalid frame index for TSR.', 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameAdjusted = flipud(analysisObj.tsrTemperature(:,:,frameIdx));
        figure('Name', ['TSR Frame ' num2str(frameIdx)]);
        [height, width] = size(frameAdjusted);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameAdjusted);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(frameAdjusted);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        title(['TSR Reconstructed Frame ' num2str(frameIdx)], 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        colormap('jet');
        colorbar;
        set(gca, 'YDir', 'normal');
        axis image;
end

function displayPCTResults(analysisObj, selectedItem, fig)
        componentIdx = str2double(regexp(selectedItem, '\d+', 'match', 'once'));
if isnan(componentIdx) || componentIdx < 1 || componentIdx > size(analysisObj.pctOutput, 3)
            uialert(fig, sprintf('Invalid or empty PCT component: %s', selectedItem), 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameAdjusted = flipud(analysisObj.pctOutput(:,:,componentIdx));
        figure('Name', ['PCT ' selectedItem]);
        [height, width] = size(frameAdjusted);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameAdjusted);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(frameAdjusted);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        title(['PCT ' selectedItem], 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        colormap('jet');
        colorbar;
        set(gca, 'YDir', 'normal');
        axis image;
end
function displayPPTResults(analysisObj, selectedItem, fig)
        phaseIdx = str2double(regexp(selectedItem, 'Phase (\d+)', 'tokens', 'once'));
if ~isempty(phaseIdx) && iscell(phaseIdx)
            phaseIdx = str2double(phaseIdx{1});
else
            phaseIdx = str2double(regexp(selectedItem, '\d+', 'match', 'once'));
end
if isnan(phaseIdx) || phaseIdx < 1 || phaseIdx > size(analysisObj.pptPhase, 3)
            uialert(fig, sprintf('Invalid PPT phase index: %s', selectedItem), 'Error');
return;
end
        pixelSize = getFieldValue(findobj(fig,'Tag','pixelSizeField'),0.6);
        useMillimeters = getFieldValue(findobj(fig,'Tag','scaleUnitsCheckbox'),true);
        frameAdjusted = flipud(analysisObj.pptPhase(:,:,phaseIdx));
if ~isreal(frameAdjusted)
            frameAdjusted = real(frameAdjusted);
            warning('Complex PPT phase data detected; using real part.');
end
if ~any(frameAdjusted(:))
            uialert(fig, sprintf('PPT phase data for %s is all zeros.', selectedItem), 'Error');
return;
end
        figure('Name', ['PPT ' selectedItem]);
        [height, width] = size(frameAdjusted);
        if useMillimeters
            imagesc((0:width-1)*pixelSize, (0:height-1)*pixelSize, frameAdjusted);
            xlabel('X (mm)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (mm)', 'FontName', 'Arial', 'FontSize', 16);
            % Optional nicer round numbers
            xt = xticks; xticks(unique(round(xt,1)));
            yt = yticks; yticks(unique(round(yt,1)));
        else
            imagesc(frameAdjusted);
            xlabel('X (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
            ylabel('Y (Pixels)', 'FontName', 'Arial', 'FontSize', 16);
        end
        title(['PPT ' selectedItem], 'FontName', 'Arial', 'FontSize', 20, 'FontWeight', 'bold');
        colormap('jet');
        colorbar;
        set(gca, 'YDir', 'normal');
        axis image;
end
% Initialize pixel size on startup
    updatePixelSize([], []);
end