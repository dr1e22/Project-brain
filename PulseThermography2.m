classdef PulseThermography2 < handle
    properties
        data
        frameRate
        timeVector = [] % Added for precise timing from TelopsRead
        flashframe = 400
        framestoaverage = 20
        tsrOrder = 4
        tsrTemperature
        tsrDiff
        tsrDiff2
        pptWindowType = 'hamming'
        pptN = 0 % Default to 0 padding if unspecified
        pptTruncation = 1
        pptFrequencies
        pptPhase
        pctOutput
        filterTypes = {'Gaussian'} % Default filter
        filterSize = 5
        filterSigma = 1
        filterAlpha = 0.2
        usercolormap = 'jet'
    end

    methods
        % ####### Setup Functions #######

        % Constructor
        function obj = PulseThermography2(data, frameRate, timeVector)
            if ~isnumeric(data) || ndims(data) ~= 3
                error('First argument, thermal data, should be a 3D array.');
            end
            if ~isnumeric(frameRate) || ~isscalar(frameRate) || frameRate ~= round(frameRate)
                error('Second argument, camera framerate, should be a single integer.');
            end
            if ndims(frameRate) == 3
                error(['You might have swapped the arguments. ' ...
                       '\nPlease provide the 3D array of thermal data (3rd dim is time) as the first argument\n ' ...
                       'and the single integer for the camera framerate as the second argument.']);
            end
            obj.data = data;
            obj.frameRate = frameRate;
            if nargin > 2 && ~isempty(timeVector)
                obj.timeVector = timeVector;
            end
        end

        % Set TSR processing settings
        function setTSR(obj, tsrOrder)
            if ~isnumeric(tsrOrder) || ~isscalar(tsrOrder) || tsrOrder ~= round(tsrOrder)
                error('tsrOrder should be a single integer.');
            end
            if tsrOrder < 4 || tsrOrder > 8
                warning('TSR polynomial order should typically be between 4 and 7; consider changing the specified order.');
            end
            obj.tsrOrder = tsrOrder;
        end

        % Set PPT processing settings (Updated)
        function setPPT(obj, pptWindowType, pptN, pptTruncation)
            if ~ischar(pptWindowType) || ~ismember(lower(pptWindowType), {'hamming', 'hann', 'blackman', 'rectangular', 'flattop'})
                error('pptWindowType must be one of ''hamming'', ''hann'', ''blackman'', ''rectangular'', or ''flattop''.');
            end
            if ~isnumeric(pptN) || ~isscalar(pptN) || pptN < 0 || pptN ~= round(pptN)
                error('pptN must be a non-negative integer.');
            end
            if ~isnumeric(pptTruncation) || ~isscalar(pptTruncation) || pptTruncation < 1 || pptTruncation ~= round(pptTruncation)
                error('pptTruncation must be a positive integer.');
            end
            obj.pptWindowType = lower(pptWindowType); % Normalize to lowercase
            obj.pptN = pptN;
            obj.pptTruncation = pptTruncation;
        end

        % Set flash frame manually
        function setFlashFrame(obj, flashframe)
            if ~isnumeric(flashframe) || ~isscalar(flashframe) || flashframe ~= round(flashframe)
                error('Flashframe should be a single integer.');
            end
            obj.flashframe = flashframe;
        end

        % Set number of frames to average for reference frame subtraction
        function setFramestoaverage(obj, framestoaverage)
            if ~isnumeric(framestoaverage) || ~isscalar(framestoaverage) || framestoaverage ~= round(framestoaverage)
                error('Number of frames should be a single integer.');
            end
            if framestoaverage < 1 || framestoaverage > size(obj.data, 3)
                error('framestoaverage must be between 1 and the number of frames in the data.');
            end
            obj.framestoaverage = framestoaverage;
        end

        % Set filter parameters
        function setFilters(obj, filterTypes, filterSize, filterSigma, filterAlpha)
            if ~iscellstr(filterTypes) || isempty(filterTypes)
                error('filterTypes must be a non-empty cell array of strings.');
            end
            validFilters = {'Gaussian', 'Average', 'Median'};
            if ~all(ismember(filterTypes, validFilters))
                error('filterTypes must contain only: ''Gaussian'', ''Average'', ''Median''.');
            end
            if ~isnumeric(filterSize) || filterSize < 1 || mod(filterSize, 2) == 0
                error('filterSize must be a positive odd integer.');
            end
            if ~isnumeric(filterSigma) || filterSigma <= 0
                error('filterSigma must be a positive number.');
            end
            if ~isnumeric(filterAlpha) || filterAlpha < 0 || filterAlpha > 1
                error('filterAlpha must be between 0 and 1.');
            end
            obj.filterTypes = filterTypes;
            obj.filterSize = filterSize;
            obj.filterSigma = filterSigma;
            obj.filterAlpha = filterAlpha;
        end

        % ####### Data Processing Functions #######

        function estimateflashframe(obj)
            assert(~isempty(obj.data), 'Temperature data is not set.');
            flash = find(mean(mean(obj.data, 1), 2) == max(mean(mean(obj.data, 1), 2)), 1);
            fprintf('Estimated Flash Frame: %d\n', flash);
            obj.setFlashFrame(flash);
        end

        function subtractreferenceframe(obj)
            obj.opening();
            fprintf('Background Subtraction (Frames: %d)\nProcessing...\n', obj.framestoaverage);
            assert(obj.framestoaverage <= size(obj.data, 3), 'Not enough frames for background subtraction.');
            Ref = mean(obj.data(:, :, 1:obj.framestoaverage), 3);
            obj.data = obj.data - Ref;
            obj.closing();
        end

        function applyFilters(obj)
            obj.opening();
            fprintf('Applying Filters: %s\nProcessing...\n', strjoin(obj.filterTypes, ', '));
            for t = 1:size(obj.data, 3)
                frame = obj.data(:,:,t);
                for i = 1:length(obj.filterTypes)
                    switch obj.filterTypes{i}
                        case 'Gaussian'
                            frame = imgaussfilt(frame, obj.filterSigma, 'FilterSize', [obj.filterSize obj.filterSize]);
                        case 'Average'
                            frame = imfilter(frame, fspecial('average', obj.filterSize));
                        case 'Median'
                            frame = medfilt2(frame, [obj.filterSize obj.filterSize]);
                    end
                end
                obj.data(:,:,t) = frame;
            end
            obj.closing();
        end

        function performPCT(obj)
            obj.opening();
            fprintf('Principal Component Thermography\nProcessing...\n');
            assert(~isempty(obj.data), 'Temperature data is not set.');
            assert(~isempty(obj.flashframe), 'Flash frame is not set.');
            assert(obj.flashframe < size(obj.data, 3), 'Flash frame exceeds data length.');

            pctdata = obj.data(:,:,obj.flashframe:end);
            [rows, cols, frames] = size(pctdata);
            if frames < 2
                error('Insufficient frames after flash for PCT processing.');
            end
            els = numel(pctdata(:,:,1));

            A = zeros(els, frames);
            for i = 1:frames
                A(:,i) = reshape(pctdata(:,:,i), 1, []);
            end

            N = A .* 0;
            for i = 1:size(N, 2)
                stdA = std(A(:,i));
                if stdA == 0
                    N(:,i) = 0; % Avoid division by zero
                else
                    N(:,i) = (A(:,i) - mean(A(:,i))) / stdA;
                end
            end

            [~, score, ~] = pca(N);

            pctOut = zeros(size(pctdata));
            for i = 1:frames
                pctOut(:,:,i) = reshape(score(:,i), rows, cols);
            end

            obj.pctOutput = pctOut;
            obj.closing();
        end

        function performTSR(obj)
            obj.opening();
            fprintf('TSR Processing (Order: %d, Frame Rate: %d FPS)\nProcessing...\n', obj.tsrOrder, obj.frameRate);
            assert(~isempty(obj.data), 'Temperature data is not set.');
            assert(~isempty(obj.flashframe), 'Flash frame is not set.');
            assert(~isempty(obj.tsrOrder), 'TSR order is not set.');
            assert(~isempty(obj.frameRate), 'FPS is not set.');

            if obj.tsrOrder > 8
                fprintf('Suggest lowering polynomial order below 8\n');
            elseif obj.tsrOrder < 4
                fprintf('Suggest increasing polynomial order above 4\n');
            end

            tsrData = obj.data(:,:,obj.flashframe+1:end-1);
            if size(tsrData, 3) < obj.tsrOrder + 1
                error('Insufficient frames after flash for TSR with order %d.', obj.tsrOrder);
            end
            tsrln = log(tsrData);
            if ~isempty(obj.timeVector)
                tsrTime = log(obj.timeVector(obj.flashframe+1:end-1));
            else
                tsrTime = log((1:size(tsrln,3))/obj.frameRate);
            end

            coefs = zeros(size(tsrln,1), size(tsrln,2), (obj.tsrOrder+1));
            q = zeros(size(tsrln,1), size(tsrln,2), size(tsrln,3));

            for i = 1:size(tsrln,1)
                for j = 1:size(tsrln,2)
                    tmp = polyfit(tsrTime, reshape(tsrln(i,j,:), 1, size(tsrln,3)), obj.tsrOrder);
                    q(i,j,:) = polyval(tmp, tsrTime);
                    coefs(i,j,:) = tmp;
                end
            end

            fprintf('Calculating derivatives...\n');
            obj.tsrDiff = diff(q, 1, 3);
            obj.tsrDiff2 = -diff(q, 2, 3);

            fprintf('Reconstructing thermal data...\n');
            obj.tsrTemperature = exp(q);
            obj.closing();
        end

        function performPPT(obj)
            obj.opening();
            fprintf('PPT Processing (Window: %s, Pad: %d, Trunc: %d)\nProcessing...\n', ...
                obj.pptWindowType, obj.pptN, obj.pptTruncation);
            assert(~isempty(obj.data), 'Temperature data is not set.');
            assert(~isempty(obj.flashframe), 'Flash frame is not set.');
            assert(~isempty(obj.pptTruncation), 'PPT truncation is not set.');
            
            totalFramesAvailable = size(obj.data, 3);
            startIdx = obj.flashframe + obj.pptTruncation;
            if startIdx > totalFramesAvailable
                error('Flash frame (%d) + truncation (%d) exceeds data length (%d).', ...
                      obj.flashframe, obj.pptTruncation, totalFramesAvailable);
            end
        
            dataTruncated = obj.data(:,:,startIdx:end);
            numFrames = size(dataTruncated, 3);
            fprintf('Number of frames after truncation: %d\n', numFrames);
            if numFrames < 2
                warning('Insufficient frames after truncation (%d); padding to minimum of 2.', numFrames);
                dataTruncated = padarray(dataTruncated, [0, 0, 2 - numFrames], 'post');
                numFrames = 2;
            end
            
            % Apply the specified window function
            switch obj.pptWindowType
                case 'rectangular'
                    window = rectwin(numFrames);
                case 'flattop'
                    window = flattopwin(numFrames);
                otherwise
                    window = feval(obj.pptWindowType, numFrames);
            end
            windowedData = bsxfun(@times, dataTruncated, reshape(window, 1, 1, []));
            
            minFreqs = 12;
            baseFrames = max(numFrames, minFreqs);
            padSize = max(0, obj.pptN);
            totalFrames = baseFrames + padSize;
            fprintf('Total frames after padding: %d (base: %d, pad: %d)\n', totalFrames, baseFrames, padSize);
            inputPadded = padarray(windowedData, [0, 0, totalFrames - numFrames], 'post');
            
            output = fft(inputPadded, totalFrames, 3);
            obj.pptPhase = angle(output(:,:,1:round(totalFrames/2)));
            if isempty(obj.pptPhase)
                error('pptPhase is empty after computation.');
            end
            fprintf('pptPhase size: %s\n', num2str(size(obj.pptPhase)));
            
            % Frequency calculation
            if ~isempty(obj.timeVector)
                validTime = obj.timeVector(startIdx:end);
                if length(validTime) < numFrames
                    validTime = [validTime; validTime(end) + (1:numFrames-length(validTime))' * (validTime(end)-validTime(end-1))];
                end
                if totalFrames > numFrames
                    dt = validTime(end) - validTime(end-1);
                    validTime = [validTime; validTime(end) + (1:totalFrames-numFrames)' * dt];
                end
                obj.pptFrequencies = (0:totalFrames-1) ./ (validTime(end) - validTime(1));
                obj.pptFrequencies = obj.pptFrequencies(1:round(totalFrames/2));
            else
                obj.pptFrequencies = (0:round(totalFrames/2)-1) .* (obj.frameRate/totalFrames);
            end
            fprintf('pptFrequencies length: %d\n', length(obj.pptFrequencies));
            obj.closing();
        end

        function performAnalysis(obj, processingSequence)
            obj.opening();
            fprintf('Starting Thermal Analysis Pipeline\n');
            for i = 1:numel(processingSequence)
                fprintf('Executing step %d: %s\n', i, processingSequence{i});
                switch processingSequence{i}
                    case 'estimateflashframe'
                        obj.estimateflashframe();
                    case 'subtractreferenceframe'
                        obj.subtractreferenceframe();
                    case 'applyFilters'
                        obj.applyFilters();
                    case 'performPCT'
                        obj.performPCT();
                    case 'performTSR'
                        obj.performTSR();
                    case 'performPPT'
                        obj.performPPT();
                    otherwise
                        warning('Unsupported processing step: %s', processingSequence{i});
                end
            end
            fprintf('All processing in pipeline complete\n');
            obj.closing();
        end

        % ####### Data Visualization Functions #######
        function imshow(obj, data)
            figure;
            imagesc(data);
            axis image;
            axis('off');
            colorbar;
            colormap(obj.usercolormap);
            set(gca, 'fontsize', 14);
        end
    end % Public methods

    methods(Access = private)
        function opening(obj)
            fprintf('\n-------------------------------------------------------\n');
        end

        function closing(obj)
            fprintf('Complete\n');
            obj.opening();
        end
    end % Private methods
end % classdef