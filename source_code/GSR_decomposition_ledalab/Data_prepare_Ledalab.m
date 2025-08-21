%% =================== DATA PREPARE LEDALAB   ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%    An algorithm that prepares data for Ledalab input:
%    - Filters GSR signal with a recognizable meditation phase, removes the first minute of recording, saves markers of the 4-minute meditation phase (e.g., ledalab_GSR1.mat), and saves indices of the 4-minute meditation phase (e.g., ledalab_index1.mat).
% Set the number of participants (variable a)
% Required files: val_subjectX.mat
% Output: ledalab_GSRX.mat, ledalab_indexX.mat

% Default path set to current folder – change if needed.

clc;
clear variables;
close all;

tic

c = 0;

%% Load data
for a = 1:14 % number of participants (1–14)
    clearvars -except a c val
VAL = load(['val_subject' num2str(a) '.mat']); % load the vector into variable VAL
val = VAL.val; 

%% Processing
data_all = val.measurements;
for i = 1:numel(data_all) % loop through each measurement
    fprintf('Processing participant %02d, measurement %02d...\n', a, i);
    clearvars -except a i data_all val c
    data = data_all(i).data; % load questionnaire values

    if ~isempty(val.measurements(i).questionnaires) && ...
       (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation')) && ...
       (data_all(i).Recognizability == 1)
        marker_start =     data_all(i).questionnaires(7).time;
        marker_start_med = data_all(i).questionnaires(8).time;
        marker_end_med =   data_all(i).questionnaires(9).time;

        if (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && ...
            strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && ...
            strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation')) && ...
            (data_all(i).Recognizability == 1)
            
            marker_start =     data_all(i).questionnaires(7).time;
            marker_start_med = data_all(i).questionnaires(9).time;
            marker_end_med =   data_all(i).questionnaires(10).time;
        end % end of conditional block for alternative structure

        marker_start_time = str2double(marker_start); % recording start
        marker_start_time_med = str2double(marker_start_med); % meditation phase start
        marker_end_time_med = str2double(marker_end_med); % meditation phase end

        % Marker definition
        marker_S = (marker_start_time_med - marker_start_time);
        marker_E = (marker_S + (marker_end_time_med - marker_start_time_med));
        
        %% Select relevant data and convert
        data_cell = struct2cell(data); % convert structure to cell array 
        
        GSR_data = data_cell(:, data_cell(1,:) == "GSR")'; % select GSR data
                        
        % GSR data
        GSR_time = str2double(GSR_data(:,2)); % GSR time values
        GSR_signal = str2double(GSR_data(:,3)); % GSR signal values
        
        %% Split the signal into three parts (meditation phase, before/after meditation)
        % Note: time is in MILLISECONDS
        S = marker_S + 10000; % meditation start + 10 s
        E = marker_E - 10000; % meditation end - 10 s
        
        % Remove the first minute of recording
        M_GSR_index_time = find(GSR_time > (GSR_time(1,1) + 60000)); % find valid indices
        
        M_GSR_time = GSR_time(M_GSR_index_time : max(M_GSR_index_time)); % time values
        M_GSR_signal = GSR_signal(M_GSR_index_time : max(M_GSR_index_time)); % signal values

        if ~isempty(val.measurements(i).data) && (S > M_GSR_time(1,1))  % check if the signal contains S
            % GSR
            GSR_index_time_before = find(M_GSR_time < S); % indices for pre-meditation phase
            GSR_index_time_after = find(M_GSR_time > E); % indices for post-meditation phase
            fprintf('S = %d, E = %d, GSR range = %d–%d\n', S, E, min(M_GSR_time), max(M_GSR_time));
            % Try to find indices of meditation phase
            GSR_index_time_med = find(M_GSR_time >= S & M_GSR_time <= E);
            
            % Check for NaN or empty results
            if isempty(GSR_index_time_med) || any(isnan(M_GSR_time))
                warning(['Skipping participant %d, measurement %d – no valid GSR samples in meditation phase ' ...
                         'or NaNs in signal. S = %d, E = %d, GSR range = %d–%d'], ...
                         a, i, S, E, min(M_GSR_time), max(M_GSR_time));
                continue
            end

            GSR_time_before = M_GSR_time(1:max(GSR_index_time_before)); % pre-meditation time
            GSR_time_after = M_GSR_time(max(GSR_index_time_med) + 1:max(GSR_index_time_after)); % post-meditation time
            GSR_time_med = M_GSR_time(max(GSR_index_time_before) + 1:max(GSR_index_time_med)); % meditation time
                             
            % signal parts
            GSR_signal_before = M_GSR_signal(GSR_index_time_before:max(GSR_index_time_before)); % pre-meditation signal
            GSR_signal_after = M_GSR_signal(max(GSR_index_time_med) + 1:max(GSR_index_time_after)); % post-meditation signal
            GSR_signal_med = M_GSR_signal(max(GSR_index_time_before) + 1:max(GSR_index_time_med)); % meditation signal
            
            clear data
            % FOR THE WHOLE SIGNAL – !!!only the FIRST 4 MINUTES!!!
            data.conductance = [GSR_signal_before', GSR_signal_med', GSR_signal_after']; % complete signal (conductance)
            time = [GSR_time_before', GSR_time_med', GSR_time_after']; % complete signal (time)
            time_2 = time(1,:) - 60000; % remove the first minute
            data.time = time_2(1,:) / 1000; % convert ms to s 

            % event
            time_3 = (GSR_time_med'); % meditation phase time values
            time_4 = time_3(1,:) - 60000; % remove the first minute
            time_5 = time_4(1,:) / 1000; % convert to seconds
            Min = min(time_5);
            Max = time_5(end);
            length_time = Max - Min; % duration of meditation phase in seconds

            if length_time >= 240 
                length = numel(time_5); % number of samples in meditation phase
                time_6 = floor((240 * length) / length_time); % number of samples for 240 s
                start = time_5(1:time_6); % 4-minute meditation time values

                for m = 1:2
                   if m == 1
                        data.event(m).time = start(1,1) + time_2(1,1)/1000;
                        data.event(m).nid = S - 60000;
                        data.event(m).name = 'začátek'; % "start"
                        data.event(m).userdata = 0;
                   else 
                        data.event(m).time = start(end) + time_2(1,1)/1000;
                        data.event(m).nid = E - 60000;
                        data.event(m).name = 'konec'; % "end"
                        data.event(m).userdata = 0;
                   end
                end   

                % Mark the time offset as zero (required by Ledalab)
                data.timeoff = 0;
                
                % Ensure the signal is in the correct numeric format
                data.time = double(data.time);
                data.conductance = double(data.conductance);

                % Save GSR signal (phasic + tonic)
                output_dir = pwd;
                
                % The file name contains the number of the subject and the measurement.
                filename_gsr = sprintf('ledalab_GSR_s%02d_m%02d.mat', a, i);
                save(fullfile(output_dir, filename_gsr), 'data');
                
                % Saving indexes for the first 4 minutes of the meditation phase
                index_med = find(start(1) <= data.time & data.time <= start(end));
                filename_index = sprintf('ledalab_index_s%02d_m%02d.mat', a, i);
                save(fullfile(output_dir, filename_index), 'index_med');

            else 
                continue
            end % end of condition: minimum 240 seconds

        else
            continue
        end % end of condition: contains signal S
        
    else
        continue
    end % end of condition: meditation markers available
    
end % end of loop through measurements

end % end of loop through participants

toc

