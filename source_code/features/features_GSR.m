%% =================== FEATURES GRS ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%   An algorithm that computes features from the phasic component of the GSR signal.

% The output includes real features (Subject_med.mat), normalized features (Subject_norm.mat), and measurement IDs (ID_GS.mat), which can be used in further analysis.
% Required variables: val_subjectX.mat, ledalab_GSRX.mat (results from Ledalab, not raw input!)

% Default path set to current folder – change if needed.

% Variable name       | Explanation
% ------------------------------------------------------------
% Subject             | Participant – features from phasic GSR signals
% Subject_med         | Participant – features during meditation phase only
% Subject_norm        | Normalized participant features
% ID_GS               | Participant/session ID linked to GSR features
% val_subjectX        | Raw session data for participant X
% ledalab_GSRX        | Decomposed GSR signals from Ledalab for participant X
% marker_start        | Start of recording
% marker_start_med    | Start of meditation phase
% marker_end_med      | End of meditation phase
% signal_PH           | Phasic component of the GSR signal
% amplitude           | Peak amplitudes of phasic responses
% factor              | Product used in entropy calculation (X * log(X))

% These identifiers have been used across scripts for data loading,
% analysis, and figure generation. If translating or adapting this code,
% you may rename these variables, but ensure compatibility with connected
% data structures and filenames.
% ================================================================

clc;
clear variables;
close all;

tic

e = 0;              % Index for saved Ledalab files
matrix = [];        % Storage for feature matrix

%% Load and process GSR data for each participant
for a = 1:14   % Number of participants (1-14)
    clearvars -except a b e i data_all val Subject Subject_med row matrix ID_GS amplitude
    b = 1;
    VAL = load(['val_subject' num2str(a) '.mat']); % Load participant session
    val = VAL.val;

    data_all = val.measurements; % Get all measurements
    for i = 1:numel(data_all)    % Loop through each session
        clearvars -except a b e i data_all val Subject Subject_med row matrix ID_GS
        data = data_all(i).data;

        % Extract event markers
        if ~isempty(val.measurements(i).questionnaires) && strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation') && data_all(i).Recognizability == 1

            marker_start = data_all(i).questionnaires(7).time;
            marker_start_med = data_all(i).questionnaires(8).time;
            marker_end_med = data_all(i).questionnaires(9).time;

            % Alternative case with repeated marker 'Start of the meditation'
            if strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation') && data_all(i).Recognizability == 1

                marker_start = data_all(i).questionnaires(7).time;
                marker_start_med = data_all(i).questionnaires(9).time;
                marker_end_med = data_all(i).questionnaires(10).time;
            end

            % Convert markers to numeric time (ms)
            marker_S = str2double(marker_start_med) - str2double(marker_start); % Start of meditation phase
            marker_E = marker_S + (str2double(marker_end_med) - str2double(marker_start_med)); % End

            % Extract GSR signal
            data_cell = struct2cell(data);
            GSR_data = data_cell(:, data_cell(1,:) == "GSR")';
            GSR_time = str2double(GSR_data(:,2));
            GSR_signal = str2double(GSR_data(:,3));

            % Use only data after first minute
            M_GSR_index_time = find(GSR_time > (GSR_time(1) + 60000));
            M_GSR_time = GSR_time(M_GSR_index_time);
            M_GSR_signal = GSR_signal(M_GSR_index_time);

            if ~isempty(val.measurements(i).data) && (marker_S + 10000 > M_GSR_time(1))
                % Segment signal into before, during, and after meditation
                S = marker_S + 10000;
                E = marker_E - 10000;

                GSR_index_time_before = find(M_GSR_time < S);
                GSR_index_time_after = find(M_GSR_time > E);
                GSR_index_time_med = find(M_GSR_time <= E & M_GSR_time >= S);
                % Safety check: meditation segment exists and no NaNs in time vector
                if isempty(GSR_index_time_med) || any(isnan(M_GSR_time))
                    fprintf('Skipping participant %d, measurement %d – invalid or missing GSR samples in meditation window.\n', a, i);
                    continue;
                end


                % Extract corresponding time and signal segments
                GSR_time_before = M_GSR_time(1:max(GSR_index_time_before));
                GSR_time_after = M_GSR_time(max(GSR_index_time_med) + 1:max(GSR_index_time_after));
                GSR_time_med = M_GSR_time(max(GSR_index_time_before) + 1:max(GSR_index_time_med));

                GSR_signal_before = M_GSR_signal(1:max(GSR_index_time_before));
                GSR_signal_after = M_GSR_signal(max(GSR_index_time_med) + 1:max(GSR_index_time_after));
                GSR_signal_med = M_GSR_signal(max(GSR_index_time_before) + 1:max(GSR_index_time_med));

                % Merge signal for whole session (only first 4 minutes used later)
                signal_GSR = [GSR_signal_before', GSR_signal_med', GSR_signal_after'];
                time_GSR = ([GSR_time_before', GSR_time_med', GSR_time_after'] - 60000) / 1000;

                % Calculate duration of meditation phase
                time_5 = (GSR_time_med' - 60000) / 1000;
                % Skip if time_5 is empty
                if isempty(time_5)
                    fprintf('Skipping participant %d, measurement %d – time_5 is empty.\n', a, i);
                    continue;
                end

                length_time = time_5(end) - min(time_5);

                % Proceed only if meditation duration is at least 4 minutes
                if length_time >= 240 
                    e = e + 1;
                    if e ~= 394 % Skip corrupted record
                        % length = numel(time_5);
                        time_6 = floor((240 * length) / length_time);
                        start = time_5(1:time_6);

                        % Save ID
                        ID_GS{1,a}(b,1) = data_all(i).ID;

                        
                        % =================== LOAD LEDALAB OUTPUT ===================
                        % Load phasic GSR signal decomposition for the current session
                        % using the Ledalab output file (e.g., ledalab_GSR1.mat).
                        % Make sure the correct folder path is set in 'ledalab_folder'.
                        % ===========================================================
                        % Load decomposed signal from Ledalab
                        ledalab_folder = pwd;  % <- adjust according to your folder structure
                        
                        % ===================== SAFETY CHECK =====================
                        % Not all sessions may have been processed by Ledalab due to 
                        % quality constraints (e.g., short duration, missing markers, etc.).
                        % Therefore, we check whether the expected file exists before loading.
                        % ========================================================
                        filename = fullfile(ledalab_folder, sprintf('ledalab_GSR_p%02d_m%02d.mat', a, i));


                        if exist(filename, 'file')
                            Analysis = load(filename);
                        else
                            fprintf('File not found: %s (Participant %d, Measurement %d) – skipping.\n', ...
    filename, a, i);            
                            continue;  % Skip this entry if Ledalab output is missing
                        end

                        analysis = Analysis.analysis;
                        data = Analysis.data;
                        % Convert to double and check for NaNs
                        if ~isa(data.time, 'double')
                            data.time = str2double(data.time);
                        end
                        if ~isa(data.conductance, 'double')
                            data.conductance = str2double(data.conductance);
                        end
                        if any(isnan(data.time)) || any(isnan(data.conductance))
                            fprintf('Skipping participant %d, measurement %d – NaNs in Ledalab output.\n', a, i);
                            continue;
                        end

                        signal = data.conductance;
                        time = data.time;
                        event_start = data.event(1).time;
                        event_end = data.event(2).time;

                        % Extract 4-minute phasic data segment
                        index = find(event_start <= time & time <= event_end);
                        signal_PH = analysis.phasicData(index(1):index(end));

                        %% Feature extraction
                        Subject{a}(b,1) = trapz(time(index(1):index(end)), signal_PH);  % Area under curve
                        Subject{a}(b,2) = mean(signal_PH);                              % Mean
                        Subject{a}(b,3) = std(signal_PH);                               % Standard deviation

                        % Peak detection
                        index_event = find(event_start <= analysis.impulsePeakTime & analysis.impulsePeakTime <= event_end);
                        if index_event > 0
                            Lmin = islocalmin(signal_PH);
                            Lmax = islocalmax(signal_PH);
                            index_max = find(Lmax);
                            index_min = find(Lmin);

                            number_peaks = sum(Lmax);
                            Subject{a}(b,4) = number_peaks;

                            amplitude = [];  % Initialize amplitude array for this measurement
                            % Amplitude calculation
                            if index_min(1) < index_max(1)
                                for j = 1:numel(index_max)
                                    amplitude(j) = signal_PH(index_max(j)) - signal_PH(index_min(j));
                                end
                            else
                                for j = 2:numel(index_max)
                                    amplitude(j-1) = signal_PH(index_max(j)) - signal_PH(index_min(j-1));
                                end
                            end
                            Subject{a}(b,5) = mean(amplitude);
                            Subject{a}(b,6) = sum(amplitude);

                            % Entropy
                            A = time(index(1):index(end));
                            TIME = A(index_max);
                            Length = event_end - event_start;
                            for c = 2:number_peaks
                                X(c) = (TIME(c) - TIME(c-1)) / Length;
                            end
                            X(1) = (TIME(1) - event_start)/Length;
                            X(end+1) = (event_end - TIME(end))/Length;

                            factor = X .* log(X);
                            factor(isnan(factor)) = 0;

                            Subject{a}(b,7) = sum(factor);
                            Subject{a}(b,8) = sum(X.^2); % Second moment
                        else
                            Subject{a}(b,4:8) = 0;
                        end
                        b = b + 1;
                    end
                end
            end
        end
    end

    %% Normalization across participants
    Subject_med{a} = real(Subject{a});
    row(a,1) = size(Subject_med{a},1);
    matrix = [matrix; Subject_med{a}];
end

for s = 1:size(matrix,2)
    minimum = min(matrix(:,s));
    maximum = max(matrix(:,s));
    norm(:,s) = (matrix(:,s) + ((maximum-101*minimum)/100)) ./ ((maximum-minimum)*(102/100));
end

% Reconstruct normalized features for each participant
u = 1;
o = 0;
for z = 1:size(row,1)
    Subject_norm{z} = norm(u:row(z)+o,:);
    u = u + row(z);
    o = o + row(z);
end



% ========================= SAVE RESULTS =========================
% The extracted GSR features for all participants are saved into a single 
% .mat file. By default, the file is stored in the current working directory.
% To save the file elsewhere, adjust the 'output_filename' path accordingly.
% Make sure the target directory exists before saving.
% ================================================================
% Save all results into one .mat file
timestamp = datestr(now, 'yyyymmdd_HHMM');
output_filename = ['GSR_features_' timestamp '.mat'];
save(output_filename, 'ID_GS', 'Subject_med', 'Subject', 'Subject_norm');
disp(['Results saved to file: ', output_filename]);


toc

