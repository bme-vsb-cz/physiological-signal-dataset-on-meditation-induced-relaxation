%% =================== PREPARE DATA FOR LEDALAB ALL PHASES ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%    An algorithm that filters GSR signal with a recognizable meditation phase, removes the first minute of recording, saves markers of the 4-minute meditation phase (e.g., ledalab_GSR1.mat), and saves indices of the 4-minute meditation phase, as well as pre/post-meditation phases (e.g., index1.mat, GSR_index_beforeX.mat, GSR_index_afterX.mat).
% Required variables: val_subjectX.mat
% Output files: ledalab_GSRX.mat, indexX.mat, GSR_index_beforeX.mat, GSR_index_afterX.mat
% Set the number of participants (variable a)

% Default path set to current folder – change if needed.


clc;
close all;
clear all;

tic

%% Data preparation for Ledalab
c = 0;

% Load participant data
for a = 1:14 % Number of participants (1–14)
    clearvars -except a c
VAL = load(['val_subject' num2str(a) '.mat']); % Load struct into variable VAL
val = VAL.val;

% Main loop – iterate over measurements
data_all = val.measurements;
for i = 1:numel(data_all) % Select i-th measurement
    clearvars -except a i c data_all val
    data = data_all(i).data; % Load data values

    %% Marker calculation
    % Conditions: data present, correct labels, correct experiment type (Recognizability == 1)

    % Check if measurement data exist,
    % if label start of meditation is at position 8,
    % and end of meditation is at position 9,
    % and if the recording is marked as valid (Recognizability == 1)

    if ~isempty(val.measurements(i).questionnaires) && ...
       length(data_all(i).questionnaires) >= 9 && ...
       strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && ...
       strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation') && ...
       data_all(i).Recognizability == 1
    
        marker_start     = data_all(i).questionnaires(7).time;
        marker_start_med = data_all(i).questionnaires(8).time;
        marker_end_med   = data_all(i).questionnaires(9).time;
    
        if length(data_all(i).questionnaires) >= 10 && ...
           strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && ...
           strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && ...
           strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation') && ...
           data_all(i).Recognizability == 1
    
        marker_start     = data_all(i).questionnaires(7).time;
        marker_start_med = data_all(i).questionnaires(9).time;
        marker_end_med   = data_all(i).questionnaires(10).time;
    
        end


    % Convert string timestamps to numeric (milliseconds)
    marker_start_time     = str2double(marker_start);      % Start of recording
    marker_start_time_med = str2double(marker_start_med);  % Start of meditation
    marker_end_time_med   = str2double(marker_end_med);    % End of meditation

    % Define marker positions relative to recording start - miliseconds
    marker_S = (marker_start_time_med - marker_start_time);
    marker_E = marker_S + (marker_end_time_med - marker_start_time_med);

    %% Data extraction and conversion
    data_cell = struct2cell(data); % Convert struct to cell array
    GSR_data = data_cell(:, data_cell(1,:) == "GSR")'; % Extract GSR values

    % Time and signal values for GSR
    GSR_time = str2double(GSR_data(:,2));    % GSR time (ms)
    GSR_signal = str2double(GSR_data(:,3));  % GSR signal (µS)

    %% Signal segmentation into 3 parts: before, during, after meditation
    % Time units: milliseconds
    S = marker_S + 10000; % Meditation start + 10 s
    E = marker_E - 10000; % Meditation end − 10 s

    % Remove the first minute of the recording
    M_GSR_index_time = find(GSR_time > 60000); % remove first minute

    % Extract cleaned time and signal vectors
    M_GSR_time = GSR_time(M_GSR_index_time) - 60000;  % The start will be in 0 ms; time values (ms)
    M_GSR_signal = GSR_signal(M_GSR_index_time);  % Signal values (µS)


    if ~isempty(val.measurements(i).data) && (S > M_GSR_time(1,1)) 
    % Condition: ensure that measurement data exists and 
    % signal segment S starts after the first minute (cleaned data)

        % Index time segments for each phase
        GSR_index_time_before = find(M_GSR_time < S);         % Indices before meditation
        GSR_index_time_after = find(M_GSR_time > E);          % Indices after meditation
        GSR_index_time_med = find(M_GSR_time >= S & M_GSR_time <= E); % Indices for meditation phase
        % Check if any segment is empty
        if isempty(GSR_index_time_before) || isempty(GSR_index_time_med) || isempty(GSR_index_time_after)
            warning('Empty GSR index segment(s) for participant %d, measurement %d – skipping.', a, i);
            continue
        end

        % Time segments
        GSR_time_before = M_GSR_time(1:max(GSR_index_time_before));
        GSR_time_after = M_GSR_time(max(GSR_index_time_med)+1:max(GSR_index_time_after));
        GSR_time_med = M_GSR_time(max(GSR_index_time_before)+1:max(GSR_index_time_med));

        % Signal segments
        GSR_signal_before = M_GSR_signal(GSR_index_time_before:max(GSR_index_time_before));
        GSR_signal_after = M_GSR_signal(max(GSR_index_time_med)+1:max(GSR_index_time_after));
        GSR_signal_med = M_GSR_signal(max(GSR_index_time_before)+1:max(GSR_index_time_med));

        clear data

        % Create combined signal and time vector (only first 4 minutes used later)
        data.conductance = [GSR_signal_before', GSR_signal_med', GSR_signal_after'];
        time = [GSR_time_before', GSR_time_med', GSR_time_after']; 
        data.time = time(1,:) / 1000; % Convert time to seconds for Ledalab compatibility and easier interpretation

        
            % --- Define meditation start and end events for Ledalab
            idx_start = numel(GSR_time_before) + 1;
            idx_end = idx_start + numel(GSR_time_med) - 1;
            
            data.event(1).time = data.time(idx_start);  % Start of meditation
            data.event(1).nid = S - 60000;
            data.event(1).name = 'start';
            data.event(1).userdata = 0;
            
            data.event(2).time = data.time(idx_end);    % End of meditation
            data.event(2).nid = E - 60000;
            data.event(2).name = 'end';
            data.event(2).userdata = 0;
            
            data.timeoff = 0; % No time offset



            % --- Save data (if valid)
            output_dir = pwd; % adjust as needed
            data.time = double(data.time);
            data.conductance = double(data.conductance);
            
            if any(isnan(data.time)) || any(isnan(data.conductance))
                warning('NaNs found in data for participant %d, measurement %d – skipping.', a, i);
                continue
            end
            
            % Save main Ledalab data structure
            c = c + 1;
            filesignal = sprintf('ledalab_GSR_s%02d_m%02d.mat', a, i);
            save(fullfile(output_dir, filesignal), 'data');
            
            % --- Save phase indices based on segment lengths
            % Compute index lengths
            len_before = numel(GSR_signal_before);
            len_med = numel(GSR_signal_med);
            len_after = numel(GSR_signal_after);
            
            % Index ranges in concatenated signal
            index_before = 1 : len_before;
            index_med = len_before + 1 : len_before + len_med;
            index_after = len_before + len_med + 1 : len_before + len_med + len_after;
            
            % Save pre-meditation index
            filesignal = sprintf('GSR_index_before_s%02d_m%02d.mat', a, i);
            save(fullfile(output_dir, filesignal), 'index_before');
            
            % Save meditation index
            filesignal = sprintf('GSR_index_s%02d_m%02d.mat', a, i);
            save(fullfile(output_dir, filesignal), 'index_med');
            
            % Save post-meditation index
            filesignal = sprintf('GSR_index_after_s%02d_m%02d.mat', a, i);
            save(fullfile(output_dir, filesignal), 'index_after');


    end
    end
end
end

toc

