%% =================== GRS FEATURES ALL PHASES ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%    Computes features from three phases of the GSR signal. 
% The output includes calculated features (e.g., Subject_before.mat, Subject_before.mat), percentage difference visualized in plots, and statistical parameters of features (e.g., GSR_mean.mat).
% Required variables: val_subjectX.mat, ledalab_GSRX.mat  - outputs from Ledalab!, GSR_index_beforeX.mat, GSR_index_afterX.mat
% Set the number of participants (variable a)

% Default path set to current folder – change if needed.

clc;
close all;
clear all;

%% Preparation of all signal phases for input into Ledalab

tic

e = 0;

% Load data
for a = 1:14 % number of participants (1–14)
    clearvars -except a e Subject_med Subject_before Subject_after Prob_after Prob_med Prob_before
    b = 1;
    VAL = load(['val_subject' num2str(a) '.mat']); % load the vector into variable VAL
    val = VAL.val;

    % Processing
    data_all = val.measurements;
    for i = 1:numel(data_all)
        success = false; % loop through each measurement
        clearvars -except a b e i data_all val success Subject_med Subject_before Subject_after Prob_after Prob_med Prob_before
        data = data_all(i).data; % load data values

        % Marker calculation

        if ~isempty(val.measurements(i).data) && (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation')) && (data_all(i).Recognizability == 1)
            marker_start =     data_all(i).questionnaires(7).time;
            marker_start_med = data_all(i).questionnaires(8).time;
            marker_end_med =   data_all(i).questionnaires(9).time;

            % Handle alternate marker structure (double start label)
            if (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation')) && (data_all(i).Recognizability == 1)
                marker_start =     data_all(i).questionnaires(7).time;
                marker_start_med = data_all(i).questionnaires(9).time;
                marker_end_med =   data_all(i).questionnaires(10).time;
            end
            marker_start_time = str2double(marker_start);        % recording start time
            marker_start_time_med = str2double(marker_start_med);% start of meditation phase
            marker_end_time_med = str2double(marker_end_med);    % end of meditation phase

            % Define time markers relative to signal start
            marker_S = (marker_start_time_med - marker_start_time);
            marker_E = (marker_S + (marker_end_time_med - marker_start_time_med));

            % Select and convert relevant data
            data_cell = struct2cell(data); % convert structure to cell array

            GSR_data = data_cell(:, data_cell(1,:) == "GSR")'; % select GSR data

            % GSR time and signal
            GSR_time = str2double(GSR_data(:,2));   % time values
            GSR_signal = str2double(GSR_data(:,3)); % signal values


            %% Split the signal into three parts (meditation phase, pre-/post-meditation phases)
            % Note: Time is in MILLISECONDS!
            S = marker_S + 10000; % meditation start + 10 s
            E = marker_E - 10000; % meditation end - 10 s

            % Remove the first minute of recording
            M_GSR_index_time = find(GSR_time > (GSR_time(1,1) + 60000)); % indices after 1st minute

            M_GSR_time = GSR_time(M_GSR_index_time : max(M_GSR_index_time)); % valid time values
            M_GSR_signal = GSR_signal(M_GSR_index_time : max(M_GSR_index_time)); % valid signal values


            % Continue only if the meditation phase start is after minute 1
            if ~isempty(val.measurements(i).data) && (S > M_GSR_time(1,1))

                % Time indices of the three signal segments
                GSR_index_time_before = find(M_GSR_time < S);                 % before meditation
                GSR_index_time_after = find(M_GSR_time > E);                  % after meditation
                GSR_index_time_med = find(M_GSR_time >= S & M_GSR_time <= E); % meditation phase
                % Check for valid GSR index for meditation phase
                if isempty(GSR_index_time_med)
                    warning('No valid time segment found in GSR signal for meditation phase – skipping this measurement.');
                    success = false;
                    continue;
                end

                % Extract time values
                GSR_time_before = M_GSR_time(1:max(GSR_index_time_before));
                GSR_time_after = M_GSR_time(max(GSR_index_time_med) + 1 : max(GSR_index_time_after));
                GSR_time_med = M_GSR_time(max(GSR_index_time_before) + 1 : max(GSR_index_time_med));

                % Extract signal values
                GSR_signal_before = M_GSR_signal(GSR_index_time_before : max(GSR_index_time_before));
                GSR_signal_after = M_GSR_signal(max(GSR_index_time_med) + 1 : max(GSR_index_time_after));
                GSR_signal_med = M_GSR_signal(max(GSR_index_time_before) + 1 : max(GSR_index_time_med));

                % Combine all segments – ONLY FIRST 4 MINUTES
                GSR_signal = [GSR_signal_before', GSR_signal_med', GSR_signal_after'];
                time = [GSR_time_before', GSR_time_med', GSR_time_after'];   % time values of full signal
                time_2_GSR = time(1,:) - 60000;                              % remove 1st minute
                time_GSR = time_2_GSR(1,:) / 1000;                           % convert ms to s
                % Meditation phase time
                time_3_GSR = GSR_time_med';             % raw times
                time_4_GSR = time_3_GSR - 60000;        % offset 1 minute
                time_5_GSR = time_4_GSR / 1000;         % convert to seconds
                Min_GSR = min(time_5_GSR);
                Max_GSR = time_5_GSR(end);
                length_time_GSR = Max_GSR - Min_GSR;    % duration in seconds
                % Pre-meditation phase time
                time_3_GSR_2 = GSR_time_before';
                time_4_GSR_2 = time_3_GSR_2 - 60000;
                time_5_GSR_2 = time_4_GSR_2 / 1000;
                Min_GSR_2 = min(time_5_GSR_2);
                Max_GSR_2 = time_5_GSR_2(end);
                length_time_GSR_2 = Max_GSR_2 - Min_GSR_2;
                % Post-meditation phase time
                time_3_GSR_3 = GSR_time_after';
                time_4_GSR_3 = time_3_GSR_3 - 60000;
                time_5_GSR_3 = time_4_GSR_3 / 1000;
                Min_GSR_3 = min(time_5_GSR_3);
                Max_GSR_3 = time_5_GSR_3(end);
                length_time_GSR_3 = Max_GSR_3 - Min_GSR_3;

                clear data
                % Check if each phase is at least 240 seconds long
                if length_time_GSR >= 240 && length_time_GSR_2 >= 240 && length_time_GSR_3 >= 240
                    e = e + 1;

                    % --- PRE-MEDITATION PHASE ---
                    % Length_GSR_2: number of samples before meditation
                    Length_GSR_2 = numel(time_5_GSR_2);
                    time_6_GSR_2 = round((240 * Length_GSR_2) / length_time_GSR_2); % number of samples = 240 seconds
                    FM = round(Length_GSR_2 - time_6_GSR_2); % starting point of 4 minutes
                    start_GSR_2 = time_5_GSR_2(FM:end); % time values for 4 minutes before meditation

                    % --- MEDITATION PHASE ---
                    Length_GSR = numel(time_5_GSR); % number of samples in meditation
                    time_6_GSR = round((240 * Length_GSR) / length_time_GSR); % number of samples in 240s
                    start_GSR = time_5_GSR(1:time_6_GSR); % time values for first 4 minutes of meditation

                    % --- POST-MEDITATION PHASE ---
                    Length_GSR_3 = numel(time_5_GSR_3); % samples after meditation
                    time_6_GSR_3 = round((240 * Length_GSR_3) / length_time_GSR_3);
                    start_GSR_3 = time_5_GSR_3(1:time_6_GSR_3); % time values for 4 minutes after meditation

                    % --- LOAD DECOMPOSED GSR SIGNAL (from Ledalab output) ---
                    input_dir = pwd; % <- adjust as needed
                    filename = sprintf('ledalab_GSR_p%02d_m%02d.mat', a, i); % if indexing according to a, i
                    if exist(fullfile(input_dir, filename), 'file')
                        Analysis = load(fullfile(input_dir, filename));
                    else
                        warning('File not found: %s', fullfile(input_dir, filename));
                        continue
                    end
                    analysis = Analysis.analysis; % analysis structure (contains tonic/phasic components)
                    data = Analysis.data;         % original signal + events
                    signal = data.conductance;    % full GSR signal (skin conductance)
                    time = data.time;             % time vector in seconds

                    % Events are manually defined start/end of meditation phase
                    event_start = data.event(1).time; % start of meditation (s)
                    event_end = data.event(2).time;   % end of meditation (s)

                    % --- LOAD INDEX FOR PRE-MEDITATION PHASE ---
                    filename_before = sprintf('GSR_index_before_p%02d_m%02d.mat', a, i);
                    filepath_before = fullfile(input_dir, filename_before);
                    
                    if exist(filepath_before, 'file')
                        Index_before = load(filepath_before);
                        index_before = Index_before.index_before;
                    else
                        warning('Missing file: %s – skipping.', filepath_before);
                        continue
                    end
                    
                    % --- LOAD INDEX FOR MEDITATION PHASE ---
                    filename_med = sprintf('GSR_index_p%02d_m%02d.mat', a, i);
                    filepath_med = fullfile(input_dir, filename_med);
                    
                    if exist(filepath_med, 'file')
                        Index_med = load(filepath_med);
                        index = Index_med.index_med;
                    else
                        warning('Missing file: %s – skipping.', filepath_med);
                        continue
                    end
                    
                    % --- LOAD INDEX FOR POST-MEDITATION PHASE ---
                    filename_after = sprintf('GSR_index_after_p%02d_m%02d.mat', a, i);
                    filepath_after = fullfile(input_dir, filename_after);
                    
                    if exist(filepath_after, 'file')
                        Index_after = load(filepath_after);
                        index_after = Index_after.index_after;
                    else
                        warning('Missing file: %s – skipping.', filepath_after);
                        continue
                    end


                    % --- EXTRACT PHASIC COMPONENT FROM LEDALAB ---
                    % analysis.phasicData is the signal corresponding to fast EDA changes (SCR)
                    PH = analysis.phasicData; % Extract 4-minute segments of phasic EDA signal
                    signal_PH_before = PH(index_before(1,1) : index_before(end));
                    signal_PH = PH(index(1,1) : index(end)); % 4 min of meditation
                    signal_PH_after = PH(index_after(1,1) : index_after(end));


                    %% Feature extraction (phasic EDA – meditation phase)

                    % 1. Area under the curve (AUC) of phasic activity
                    Subject_before{a}(b,1) = trapz(time(index_before(1,1) : index_before(end)), signal_PH_before);
                    Subject_med{a}(b,1) = trapz(time(index(1,1) : index(end)), signal_PH);
                    Subject_after{a}(b,1) = trapz(time(index_after(1,1) : index_after(end)), signal_PH_after);

                    % 2. Mean phasic EDA – average value of the phasic component
                    Subject_before{a}(b,2) = mean(signal_PH_before); 
                    Subject_med{a}(b,2) = mean(signal_PH); 
                    Subject_after{a}(b,2) = mean(signal_PH_after); 

                    % 3. Standard deviation of phasic EDA
                    Subject_before{a}(b,3) = std(signal_PH_before);
                    Subject_med{a}(b,3) = std(signal_PH);
                    Subject_after{a}(b,3) = std(signal_PH_after);

                    % 4. Number of peaks – total number of peaks in the meditation phase

                    % Determine the indices of peaks in each phase
                    index_event_before = find(time(index_before(1,1)) <= analysis.impulsePeakTime & analysis.impulsePeakTime < event_start);
                    index_event = find(event_start <= analysis.impulsePeakTime & analysis.impulsePeakTime <= event_end);
                    index_event_after = find(event_end < analysis.impulsePeakTime & analysis.impulsePeakTime < time(index_after(end)));

                    if index_event == 0 % No peaks found in meditation phase
                        Subject_med{a}(b,4) = 0;  
                        Subject_med{a}(b,5) = 0;
                        Subject_med{a}(b,6) = 0;
                        Subject_med{a}(b,7) = 0; 
                        Subject_med{a}(b,8) = 0; 
                    else 
                        % Detect local minima and maxima in phasic signal
                        Lmin = islocalmin(signal_PH); % local minima
                        Lmax = islocalmax(signal_PH); % local maxima

                        % Number of peaks in phasic activity
                        number_peaks = sum(Lmax == 1);
                        Subject_med{a}(b,4) = number_peaks;

                        % 5. Mean amplitude of peaks
                        index_max = find(Lmax == 1); % indices of local maxima (peaks)
                        index_min = find(Lmin == 1); % indices of local minima (valleys)

                        if index_min(1,1) < index_max(1,1) && numel(index_max) == numel(index_min)
                             for j = 1:numel(index_max) 
                             amplituda(j) = signal_PH(index_max(j)) - signal_PH(index_min(j));
                             end
                        else % offset pairing if minima comes after maxima
                             for j = 2:numel(index_max) 
                             amplituda(j-1) = signal_PH(index_max(j)) - signal_PH(index_min(j-1));
                             end
                        end

                        Subject_med{a}(b,5) = mean(amplituda); % mean amplitude of peaks

                        % 7. Sum of peak amplitudes
                        Subject_med{a}(b,6) = sum(amplituda);

                        % 8. Entropy of peak timing distribution
                        A = time(index(1,1):index(end)); % time vector
                        TIME = A(index_max); % times of peaks

                        Length = event_end - event_start; % total duration of meditation phase
                            for q = 2:number_peaks
                                X(q) = (TIME(q) - TIME(q-1)) / Length;
                            end

                        X(1) = (TIME(1) - event_start) / Length;
                        X(end) = (event_end - TIME(end)) / Length;

                        % Replace NaNs in entropy calculation with 0
                        entropy_terms = X .* log(X);
                        NaN_mask = isnan(entropy_terms);
                        entropy_terms(NaN_mask) = 0;

                        Subject_med{a}(b,7) = sum(entropy_terms); % entropy of peak spacing

                        % 9. Second moment (temporal dispersion) of peaks
                        Subject_med{a}(b,8) = sum(X.^2);
                    
                    end % end of peak feature extraction
                 
                %% Feature extraction for pre-meditation phase
                if index_event_before == 0   % No peaks detected before meditation
                    Subject_before{a}(b,4) = 0;  
                    Subject_before{a}(b,5) = 0;
                    Subject_before{a}(b,6) = 0;
                    Subject_before{a}(b,7) = 0; 
                    Subject_before{a}(b,8) = 0;

                else
                    % Detect local minima and maxima in phasic signal
                    Lmin_before = islocalmin(signal_PH_before);
                    Lmax_before = islocalmax(signal_PH_before);

                    % 4. Number of peaks
                    number_peaks_before = sum(Lmax_before == 1);
                    Subject_before{a}(b,4) = number_peaks_before;

                    % 5. Mean amplitude of peaks
                    index_max_before = find(Lmax_before == 1); % indices of local maxima
                    index_min_before = find(Lmin_before == 1); % indices of local minima

                    if index_min_before(1) < index_max_before(1) && numel(index_max_before) == numel(index_min_before)
                        for j = 1:numel(index_max_before)
                            amplituda_before(j) = signal_PH_before(index_max_before(j)) - signal_PH_before(index_min_before(j));
                        end
                    else
                        for j = 2:numel(index_max_before)
                            amplituda_before(j-1) = signal_PH_before(index_max_before(j)) - signal_PH_before(index_min_before(j-1));
                        end
                    end

                    Subject_before{a}(b,5) = mean(amplituda_before); % mean peak amplitude
                    Subject_before{a}(b,6) = sum(amplituda_before);  % sum of amplitudes

                    % 7. Entropy of peak timing distribution
                    clear Length soucin
                    B = time(index_before(1,1) : index_before(end));
                    TIME_before = B(index_max_before);

                    Length = time(index_before(end)) - time(index_before(1,1));
                    for q = 2:number_peaks_before
                        Y(q) = (TIME_before(q) - TIME_before(q-1)) / Length;
                    end
                    Y(1) = (TIME_before(1) - event_start) / Length;
                    Y(end) = (event_end - TIME_before(end)) / Length;

                    soucin = Y .* log(Y);
                    NaN_mask = isnan(soucin);
                    soucin(NaN_mask) = 0;

                    Subject_before{a}(b,7) = sum(soucin); % entropy
                    Subject_before{a}(b,8) = sum(Y.^2);   % second moment
                end

                %% Feature extraction for post-meditation phase
                if index_event_after == 0
                    % No peaks detected after meditation
                    Subject_after{a}(b,4:8) = 0;
                else
                    % Detect local minima and maxima
                    Lmin_after = islocalmin(signal_PH_after);
                    Lmax_after = islocalmax(signal_PH_after);

                    % 4. Number of peaks
                    number_peaks_after = sum(Lmax_after == 1);
                    Subject_after{a}(b,4) = number_peaks_after;

                    % 5. Mean amplitude of peaks
                    index_max_after = find(Lmax_after == 1);
                    index_min_after = find(Lmin_after == 1);

                    if index_min_after(1) < index_max_after(1) && numel(index_max_after) == numel(index_min_after)
                        for j = 1:numel(index_max_after)
                            amplituda_after(j) = signal_PH_after(index_max_after(j)) - signal_PH_after(index_min_after(j));
                        end
                    else
                        for j = 2:numel(index_max_after)
                            amplituda_after(j-1) = signal_PH_after(index_max_after(j)) - signal_PH_after(index_min_after(j-1));
                        end
                    end

                    Subject_after{a}(b,5) = mean(amplituda_after);
                    Subject_after{a}(b,6) = sum(amplituda_after);

                    % 7. Entropy of peak timing distribution
                    clear soucin Length
                    C = time(index_after(1,1) : index_after(end));
                    TIME_after = C(index_max_after);

                    Length = time(index_after(end)) - time(index_after(1,1));
                    for q = 2:number_peaks_after
                        Z(q) = (TIME_after(q) - TIME_after(q-1)) / Length;
                    end
                    Z(1) = (TIME_after(1) - event_start) / Length;
                    Z(end) = (event_end - TIME_after(end)) / Length;

                    soucin = Z .* log(Z);
                    NaN_mask = isnan(soucin);
                    soucin(NaN_mask) = 0;

                    Subject_after{a}(b,7) = sum(soucin); % entropy
                    Subject_after{a}(b,8) = sum(Z.^2);   % second moment
                end

                if success
    b = b + 1;
end % increment sample counter
        end % if duration ≥ 240 s
    end % if contains signal S
    end % if meditation markers exist
end % end of measurements loop

%% Save extracted features for each participant
filesignal = sprintf('Subject_med.mat');
save(['file path' filesignal], 'Subject_med');
filesignal = sprintf('Subject_before.mat');
save(['file path' filesignal], 'Subject_before');
filesignal = sprintf('Subject_after.mat');
save(['file path' filesignal], 'Subject_after');


%-------------------------------------------------------------------------------------------------------%% Participant statistics %% %% Participant statistics (per phase)

% Pre-meditation phase

GSR_mean{a}(1,:)    = mean(Subject_before{1,a});
GSR_var{a}(1,:)     = var(Subject_before{1,a});
GSR_std{a}(1,:)     = std(Subject_before{1,a});
GSR_median{a}(1,:)  = median(Subject_before{1,a});
GSR_varkoef{a}(1,:) = GSR_std{a}(1,:) ./ GSR_mean{a}(1,:) * 100;


% Meditation phase
GSR_mean{a}(2,:) = mean(Subject_med{1,a});
GSR_var{a}(2,:) = var(Subject_med{1,a});
GSR_std{a}(2,:) = std(Subject_med{1,a});
GSR_median{a}(2,:) = median(Subject_med{1,a});
GSR_varkoef{a}(2,:) = GSR_std{a}(2,:) ./ GSR_mean{a}(2,:) * 100;

% Post-meditation phase
GSR_mean{a}(3,:) = mean(Subject_after{1,a});
GSR_var{a}(3,:) = var(Subject_after{1,a});
GSR_std{a}(3,:) = std(Subject_after{1,a});
GSR_median{a}(3,:) = median(Subject_after{1,a});
GSR_varkoef{a}(3,:) = GSR_std{a}(3,:) ./ GSR_mean{a}(3,:) * 100;

%% Save statistics to .mat files
filesignal = 'GSR_mean.mat';
save(['file path' filesignal], 'GSR_mean');
filesignal = 'GSR_var.mat';
save(['file path' filesignal], 'GSR_var');
filesignal = 'GSR_std.mat';
save(['file path' filesignal], 'GSR_std');
filesignal = 'GSR_median.mat';
save(['file path' filesignal], 'GSR_median');
filesignal = 'GSR_varkoef.mat';
save(['file path' filesignal], 'GSR_varkoef');

end % End of loop over participants
%---------------------------------------------------------------------------------------------------
%% Analysis of GSR phases
clearvars -except Subject_before Subject_med Subject_after

% Combine feature matrices across all participants
before = real([Subject_before{1}; Subject_before{2}; Subject_before{3}; Subject_before{4};
               Subject_before{5}; Subject_before{6}; Subject_before{7}; Subject_before{8};
               Subject_before{9}; Subject_before{10}; Subject_before{11}; Subject_before{12};
               Subject_before{13}; Subject_before{14}]);

med = real([Subject_med{1}; Subject_med{2}; Subject_med{3}; Subject_med{4};
            Subject_med{5}; Subject_med{6}; Subject_med{7}; Subject_med{8};
            Subject_med{9}; Subject_med{10}; Subject_med{11}; Subject_med{12};
            Subject_med{13}; Subject_med{14}]);

after = real([Subject_after{1}; Subject_after{2}; Subject_after{3}; Subject_after{4};
              Subject_after{5}; Subject_after{6}; Subject_after{7}; Subject_after{8};
              Subject_after{9}; Subject_after{10}; Subject_after{11}; Subject_after{12};
              Subject_after{13}; Subject_after{14}]);

% Calculate means, medians, standard deviations, and variances for each phase
MEAN_before = mean(before);
MEAN_med = mean(med);
MEAN_after = mean(after);

MED_before = median(before);
MED_med = median(med);
MED_after = median(after);

std_before = std(before);
std_med = std(med);
std_after = std(after);

VAR_before = var(before);
VAR_med = var(med);
VAR_after = var(after);

% Coefficients of variation
koef_before = (std_before ./ MEAN_before) * 100;
koef_med = (std_med ./ MEAN_med) * 100;
koef_after = (std_after ./ MEAN_after) * 100;

% Calculate percentage ratios (before/med and after/med) for selected features
% Feature index 1: AUC, 4: peak count, 5: avg amplitude, 6: sum of amplitudes
procenta_before_med_mean_plocha     = round((MEAN_before(1) / MEAN_med(1)) * 100, 2);
procenta_after_med_mean_plocha      = round((MEAN_after(1) / MEAN_med(1)) * 100, 2);

procenta_before_med_mean_peak       = round((MEAN_before(4) / MEAN_med(4)) * 100, 2);
procenta_after_med_mean_peak        = round((MEAN_after(4) / MEAN_med(4)) * 100, 2);

procenta_before_med_mean_pr_peak    = round((MEAN_before(5) / MEAN_med(5)) * 100, 2);
procenta_after_med_mean_pr_peak     = round((MEAN_after(5) / MEAN_med(5)) * 100, 2);

procenta_before_med_mean_suma_peak  = round((MEAN_before(6) / MEAN_med(6)) * 100, 2);
procenta_after_med_mean_suma_peak   = round((MEAN_after(6) / MEAN_med(6)) * 100, 2);

%% Visualization: bar chart comparing means across phases (as % of meditation phase)

fig = figure('WindowState', 'maximized');

X = categorical({'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});
X = reordercats(X, {'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});

% Create grouped bar chart to compare selected features (means) 
% between three phases: before meditation, during meditation, and after meditation.
% The meditation phase is used as the reference (100%) for normalization,
% so the middle bar in each group is always set to 100%.

% Bar plot: [before | med (100%) | after]
b = bar(X, [
    procenta_before_med_mean_plocha     100 procenta_after_med_mean_plocha;
    procenta_before_med_mean_peak       100 procenta_after_med_mean_peak;
    procenta_before_med_mean_pr_peak    100 procenta_after_med_mean_pr_peak;
    procenta_before_med_mean_suma_peak  100 procenta_after_med_mean_suma_peak
]);

set(gca, 'FontName', 'Times');

% Color coding
b(1).FaceColor = 'blue';   % before meditation
b(2).FaceColor = 'green';  % during meditation (reference 100%)
b(3).FaceColor = 'red';    % after meditation

% Add data labels to each bar
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

% Axis labels and title
ylabel('Percentage Comparison (%)','FontName', 'Times');
xlabel('Feature','FontName', 'Times');
ylim([50 600]);

t = title('Percentage Comparison of Mean Values Across GSR Phases');
t.FontName = 'Times';

legend('Before meditation', 'Meditation phase', 'After meditation', 'FontName', 'Times');

% Save figure as PDF
filename = sprintf('procentualni_porovnani_prumer.pdf');
path = pwd;
if ~exist(path, 'dir')
    mkdir(path);  % Creates a folder if it does not exist
end
file = fullfile(path, filename);
set(fig, 'visible', 'on');
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%--------------------------------------------------------------------------%% Calculate variance ratios (before/meditation and after/meditation)
% Feature indices: 1 – AUC, 4 – number of peaks, 5 – mean amplitude, 6 – sum of amplitudes

procenta_before_med_var_plocha     = round((VAR_before(1,1) / VAR_med(1,1)) * 100, 2);
procenta_after_med_var_plocha      = round((VAR_after(1,1) / VAR_med(1,1)) * 100, 2);

procenta_before_med_var_peak       = round((VAR_before(1,4) / VAR_med(1,4)) * 100, 2);
procenta_after_med_var_peak        = round((VAR_after(1,4) / VAR_med(1,4)) * 100, 2);

procenta_before_med_var_pr_peak    = round((VAR_before(1,5) / VAR_med(1,5)) * 100, 2);
procenta_after_med_var_pr_peak     = round((VAR_after(1,5) / VAR_med(1,5)) * 100, 2);

procenta_before_med_var_suma_peak  = round((VAR_before(1,6) / VAR_med(1,6)) * 100, 2);
procenta_after_med_var_suma_peak   = round((VAR_after(1,6) / VAR_med(1,6)) * 100, 2);

%% Create bar chart to visualize percentage variance comparison

fig = figure('WindowState', 'maximized');

X = categorical({'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});
X = reordercats(X, {'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});

% Plot variance values for each phase, normalized to 100% for the meditation phase
b = bar(X, [
    procenta_before_med_var_plocha     100 procenta_after_med_var_plocha;
    procenta_before_med_var_peak       100 procenta_after_med_var_peak;
    procenta_before_med_var_pr_peak    100 procenta_after_med_var_pr_peak;
    procenta_before_med_var_suma_peak  100 procenta_after_med_var_suma_peak
]);

set(gca, 'FontName', 'Times');

% Set custom colors for bars representing different phases
b(1).FaceColor = 'blue';   % before meditation
b(2).FaceColor = 'green';  % meditation (reference, 100%)
b(3).FaceColor = 'red';    % after meditation

% Add value labels to each bar
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

% Chart title and labels
ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([50 17000]); % Adjust Y-axis range for clarity

t = title('Percentage Comparison of Variances Across GSR Phases');
t.FontName = 'Times';

legend('Before meditation', 'Meditation phase', 'After meditation', 'FontName', 'Times');

%% Export figure to PDF
filename = sprintf('percentage_comparison_variability.pdf');
path = pwd;
file = fullfile(path, filename);

set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%--------------------------------------------------------------------------
procenta_before_med_std_plocha = round((std_before(1,1)/std_med(1,1))*100,2);
procenta_after_med_std_plocha = round((std_after(1,1)/std_med(1,1))*100,2);

procenta_before_med_std_peak = round((std_before(1,4)/std_med(1,4))*100,2);
procenta_after_med_std_peak = round((std_after(1,4)/std_med(1,4))*100,2);

procenta_before_med_std_pr_peak = round((std_before(1,5)/std_med(1,5))*100,2);
procenta_after_med_std_pr_peak = round((std_after(1,5)/std_med(1,5))*100,2);

procenta_before_med_std_suma_peak = round((std_before(1,6)/std_med(1,6))*100,2);
procenta_after_med_std_suma_peak = round((std_after(1,6)/std_med(1,6))*100,2);


fig = figure('WindowState', 'maximized');
X = categorical({'area under curve','number of peaks', 'mean peak amplitude','sum of peak amplitude'});
X = reordercats(X,{'area under curve','number of peaks', 'mean peak amplitude','sum of peak amplitude'});

b = bar(X,[procenta_before_med_std_plocha 100 procenta_after_med_std_plocha; 
     procenta_before_med_std_peak 100  procenta_after_med_std_peak;
     procenta_before_med_std_pr_peak 100 procenta_after_med_std_pr_peak;
     procenta_before_med_std_suma_peak 100  procenta_after_med_std_suma_peak]);

set(gca,'FontName','Times');

b(1).FaceColor = 'blue'; 
b(2).FaceColor = 'green'; 
b(3).FaceColor = 'red'; 

xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1,ytips1,labels1,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2,ytips2,labels2,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3,ytips3,labels3,'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

ylabel('Percentual comparison (%)','FontName', 'Times');
xlabel('Feature','FontName', 'Times');
ylim([50 1400]);
t = title('Percentual comparison of GSR standard deviation');
t.FontName = 'Times'; % Change font
legend('phase before meditation','meditation phase','phase after meditation','FontName', 'Times');

% save *pdf
filename = sprintf('percentage_comparison_std.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file,'Resolution', 300);
close(fig)

%--------------------------------------------------------------------------%% Calculate median ratios (before/meditation and after/meditation)
% Feature indices: 1 – Area under curve, 4 – number of peaks, 5 – mean amplitude, 6 – sum of amplitudes

procenta_before_med_med_plocha     = round((MED_before(1,1) / MED_med(1,1)) * 100, 2);
procenta_after_med_med_plocha      = round((MED_after(1,1) / MED_med(1,1)) * 100, 2);

procenta_before_med_med_peak       = round((MED_before(1,4) / MED_med(1,4)) * 100, 2);
procenta_after_med_med_peak        = round((MED_after(1,4) / MED_med(1,4)) * 100, 2);

procenta_before_med_med_pr_peak    = round((MED_before(1,5) / MED_med(1,5)) * 100, 2);
procenta_after_med_med_pr_peak     = round((MED_after(1,5) / MED_med(1,5)) * 100, 2);

procenta_before_med_med_suma_peak  = round((MED_before(1,6) / MED_med(1,6)) * 100, 2);
procenta_after_med_med_suma_peak   = round((MED_after(1,6) / MED_med(1,6)) * 100, 2);

%% Bar chart: median comparison across GSR phases

fig = figure('WindowState', 'maximized');

X = categorical({'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});
X = reordercats(X, {'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});

% Create grouped bar chart with meditation phase as baseline (100%)
b = bar(X, [
    procenta_before_med_med_plocha     100 procenta_after_med_med_plocha;
    procenta_before_med_med_peak       100 procenta_after_med_med_peak;
    procenta_before_med_med_pr_peak    100 procenta_after_med_med_pr_peak;
    procenta_before_med_med_suma_peak  100 procenta_after_med_med_suma_peak
]);

set(gca, 'FontName', 'Times');

% Color-code bars: blue = before, green = meditation (100%), red = after
b(1).FaceColor = 'blue';
b(2).FaceColor = 'green';
b(3).FaceColor = 'red';

% Add percentage labels above bars
xtips1 = b(1).XEndPoints; ytips1 = b(1).YEndPoints; labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips2 = b(2).XEndPoints; ytips2 = b(2).YEndPoints; labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

xtips3 = b(3).XEndPoints; ytips3 = b(3).YEndPoints; labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 8);

% Axes labels and title
ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([40 600]);

t = title('Percentage Comparison of Medians Across GSR Phases');
t.FontName = 'Times';

legend('Before meditation', 'Meditation phase', 'After meditation', 'FontName', 'Times');

%% Save chart as PDF
filename = sprintf('procentualni_porovnani_median.pdf');
path = pwd;
file = fullfile(path, filename);

set(fig, 'visible', 'on');
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%--------------------------------------------------------------------------%% Calculate coefficient of variation ratios (before/meditation and after/meditation)
% Feature indices: 1 – AUC, 4 – number of peaks, 5 – mean amplitude, 6 – sum of amplitudes

procenta_before_koef_plocha     = round((koef_before(1,1) / koef_med(1,1)) * 100, 2);
procenta_after_koef_plocha      = round((koef_after(1,1) / koef_med(1,1)) * 100, 2);

procenta_before_koef_peak       = round((koef_before(1,4) / koef_med(1,4)) * 100, 2);
procenta_after_koef_peak        = round((koef_after(1,4) / koef_med(1,4)) * 100, 2);

procenta_before_koef_pr_peak    = round((koef_before(1,5) / koef_med(1,5)) * 100, 2);
procenta_after_koef_pr_peak     = round((koef_after(1,5) / koef_med(1,5)) * 100, 2);

procenta_before_koef_suma_peak  = round((koef_before(1,6) / koef_med(1,6)) * 100, 2);
procenta_after_koef_suma_peak   = round((koef_after(1,6) / koef_med(1,6)) * 100, 2);

%% Bar chart: coefficient of variation comparison across GSR phases

fig = figure('WindowState', 'maximized');

X = categorical({'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});
X = reordercats(X, {'Area under curve', 'Number of peaks', 'Mean peak amplitude', 'Sum of peak amplitudes'});

% Create grouped bar chart with meditation phase as baseline (100%)
b = bar(X, [
    procenta_before_koef_plocha     100 procenta_after_koef_plocha;
    procenta_before_koef_peak       100 procenta_after_koef_peak;
    procenta_before_koef_pr_peak    100 procenta_after_koef_pr_peak;
    procenta_before_koef_suma_peak  100 procenta_after_koef_suma_peak
]);

set(gca, 'FontName', 'Times');

% Color coding for clarity
b(1).FaceColor = 'blue';   % before meditation
b(2).FaceColor = 'green';  % during meditation (baseline)
b(3).FaceColor = 'red';    % after meditation

% Add labels to each bar
xtips1 = b(1).XEndPoints; ytips1 = b(1).YEndPoints; labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 10);

xtips2 = b(2).XEndPoints; ytips2 = b(2).YEndPoints; labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 10);

xtips3 = b(3).XEndPoints; ytips3 = b(3).YEndPoints; labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize', 10);

% Axis labels and title
ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([50 600]);

t = title('Percentage Comparison of Coefficients of Variation Across GSR Phases');
t.FontName = 'Times';

legend('Before meditation', 'Meditation phase', 'After meditation', 'FontName', 'Times');

%% Export chart to PDF
filename = sprintf('percentual_comparison_var_coef.pdf');
path = pwd;
file = fullfile(path, filename);

set(fig, 'visible', 'on');
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%% End of GSR analysis section
toc

