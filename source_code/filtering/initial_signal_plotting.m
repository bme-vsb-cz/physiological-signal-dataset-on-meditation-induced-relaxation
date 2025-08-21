%% =================== INITIAL SIGNAL PLOTTING   ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%    Part 1: Plots the GSR signal with markers of the meditation phase. The goal is to define a recognizable meditation phase (1), an unrecognizable meditation phase (0), and unusable signal (2).
%    Part 2: The results must be manually written into a vector and the vector saved (e.g., subject_1.mat).
%    Part 3: The code then assigns the saved vectors to a structure and stores this information in the variable val, which is loaded in other scripts.
%            -Each measurement is also assigned an ID for further analysis.
% Required files: input data in .json format - manually enter subject number (e.g., subject_1.json)
% Output: subject_X.mat, val_subjectX.mat 
% Note: We highly recommend running the script in parts.

% Default path set to current folder – change if needed.

clc;
clear all;
close all;

%% Displaying the signal
% loading data
fname = 'subject_1.json'; % select subject
fid = fopen(fname); 
raw = fread(fid, inf); % read all data from "fid" as unsigned chars into a column vector
str = native2unicode(raw', 'UTF-8'); % convert to UTF-8 string
fclose(fid); 
val = jsondecode(str); % decode the .json format
data_all(i)
% processing
data_all = val.measurements;
for i = 1:numel(data_all) % loop through all measurements
    clearvars -except i data_all 
    %data = data_all(i).questionnaires; % load questionnaire data
    data = data_all(i).data;

    if ~isempty(data_all(i).data) && (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation'))
        marker_start =     data_all(i).questionnaires(7).time;
        marker_start_med = data_all(i).questionnaires(8).time;
        marker_end_med =   data_all(i).questionnaires(9).time;
    elseif ~isempty(data_all(i).data) && (strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation')) 
        marker_start =     data_all(i).questionnaires(7).time;
        marker_start_med = data_all(i).questionnaires(9).time;
        marker_end_med =   data_all(i).questionnaires(10).time;
    end

    if exist('marker_start', 'var')
        marker_start_time = str2double(marker_start); % start of recording
        marker_start_time_med = str2double(marker_start_med); % start of meditation
        marker_end_time_med = str2double(marker_end_med); % end of meditation

        % marker definition
        marker_S = (marker_start_time_med - marker_start_time);
        marker_E = (marker_S + (marker_end_time_med - marker_start_time_med));

        %% select data and convert
        data_cell = struct2cell(data); % convert structure to cell array

        GSR_data = data_cell(:,data_cell(1,:) == "GSR")'; % select GSR data

        % GSR data
        GSR_time = str2double(GSR_data(:,2)); % extract time values
        GSR_signal = str2double(GSR_data(:,3)); % extract signal values

        if ~all(isnan(GSR_signal))
            % plot
            figure(i)
            plot(GSR_time/60000, GSR_signal);
            hold on
            plot(marker_S/60000, 0, 'r*', 'MarkerSize', 10)
            plot(marker_E/60000, 0, 'r*', 'MarkerSize', 10)
            A = max(GSR_time/60000);
            xlim([0 A]);
            ylabel('GSR (-)');
            xlabel('Time (min)');
            legend('Signal','Meditation phase');
        else 
            figure(i)
            title('Measurement does not contain a valid GSR signal')
        end

    elseif ~isempty(data_all(i).data)
        data_cell = struct2cell(data);
        GSR_data = data_cell(:,data_cell(1,:) == "GSR")';
        GSR_time = str2double(GSR_data(:,2));
        GSR_signal = str2double(GSR_data(:,3));

        if ~all(isnan(GSR_signal))
            figure(i)
            plot(GSR_time/60000, GSR_signal);
            xlabel('Time (min)');
            ylabel('GSR (-)');
            title('No meditation phase info -> unusable signal');
        else 
            figure(i)
            title('Unusable signal');
        end
    else       
        figure(i)
        title('Unusable signal');
    end

end

%% ------------------------------------------------------------------------
%% Meditation phase recognizability
% Recognizable = 1, Unrecognizable = 0, Unusable = 2
%            1; 2; 3; 4; 5; 6; 7; 8; 9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32;33;34;35;36;37;38;39;40;41;42;43;44;45;46;47;48;49;50;51;52;53;54;55;56;57;58;59;60;61;62;63;64;65;66;67,68,69,70,71;
subject_1 = [1; 0; 2; 0; 1; 1; 1; 1; 1; 0; 0; 0; 1; 1; 0; 0; 0; 1; 0; 1; 1; 1; 1; 0; 1; 0; 0; 1; 0; 0; 1; 0; 1; 1; 1; 1; 1; 1; 2; 1; 0; 1; 2; 0; 1; 0; 1; 1; 1; 0; 0; 2; 0; 0; 1; 1; 1; 2; 0; 1; 1; 1; 0; 0];
subject_2 = [2; 2; 2; 2; 1; 0; 1; 0; 1; 1; 1; 0; 1; 1; 1; 1; 2; 1; 1; 1; 0; 1; 1; 0; 1; 1; 1; 1; 1; 0; 0; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 0; 0; 1; 0; 1; 1; 1; 2; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 0];
subject_3 = [2; 0; 0; 2; 0; 0; 0; 2; 2; 1; 2; 1; 0; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 0; 0; 1; 1; 1; 0; 1; 0; 1; 1; 1; 1; 1; 1; 1; 0; 0; 1; 0; 0; 1; 1; 1; 1; 0; 1; 1; 1; 0; 1; 0; 0; 1; 1; 1; 0; 1; 0; 1; 1];
subject_4 = [1; 1; 1; 0; 0; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 1; 0; 0; 2; 2; 1; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 1; 2; 1; 1; 0; 0; 0; 1; 1; 1; 1; 1; 0; 0; 0; 1; 1; 0; 0; 0; 1; 2; 1; 1; 1; 0; 0; 0; 0; 1; 0; 0; 0; 1; 1; 0; 0; 1];
subject_5 = [0; 0; 1; 1; 0; 1; 0; 1; 1; 0; 1; 1; 1; 1; 1; 1; 0; 0; 0; 1; 1; 1; 0; 1; 1; 0; 1; 1; 1; 0; 1; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 1; 0; 2; 0; 1; 1; 1; 0; 1; 1; 0; 1; 1; 1; 0; 0; 0; 0; 0; 1; 1];
subject_6 = [0; 0; 1; 2; 1; 0; 1; 0; 0; 1; 1; 2; 0; 1; 0; 1; 0; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 1; 1; 1; 1; 1; 0; 0; 1; 1; 1; 1; 1; 1; 0; 0; 0; 1; 0; 1; 1; 1; 1; 1; 2; 0; 1; 0; 1; 1; 1; 1; 2; 1; 1; 1; 0; 1];
subject_7 = [1; 1; 2; 1; 1; 0; 2; 2; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 1; 2; 1; 2; 1; 0; 0; 1; 0; 1; 0; 1; 0; 2; 0; 1; 0; 1; 1; 1; 1; 1; 0; 1; 1; 1; 0; 1; 0; 0; 1; 1; 0; 1; 1; 0; 1; 2; 0; 1; 1; 1; 1; 0; 1; 0; 0; 0];
subject_8 = [1; 1; 1; 0; 1; 1; 0; 1; 1; 0; 1; 0; 0; 1; 2; 1; 1; 1; 1; 1; 0; 1; 0; 0; 1; 1; 1; 1; 2; 0; 0; 1; 0; 0; 0; 1; 1; 1; 1; 1; 0; 1; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 2; 1];
subject_9 = [2; 2; 2; 2; 2; 2; 2; 2; 2; 0; 0; 1; 2; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 2; 1; 1; 1; 1; 0; 0; 1; 1; 0; 1; 1; 1; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1; 0; 0; 1; 1; 1; 1; 1; 0; 1; 1; 1; 1; 0; 0; 1; 0; 1; 2; 0; 1];
subject_10 = [0; 0; 1; 0; 1; 0; 1; 1; 0; 1; 0; 0; 0; 1; 1; 1; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 2; 0; 0; 0; 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0];
subject_11 = [2; 1; 0; 1; 0; 1; 0; 0; 0; 0; 0; 1; 2; 0; 1; 1; 0; 0; 0; 0; 1; 1; 0; 0; 0; 1; 1; 1; 1; 1; 0; 1; 0; 1; 0; 1; 0; 1; 1; 2; 1; 0; 0; 1; 1; 0; 1; 1; 0; 0; 1; 1; 0; 1; 0];
subject_12 = [0; 1; 1; 0; 0; 0; 0; 0; 0; 1; 1; 0; 1; 1; 1; 1; 0; 0; 1; 1; 0; 1; 1; 1; 1; 1; 0; 1; 0; 0; 0; 0; 1; 1; 0; 1; 0; 0; 1; 0; 1; 1; 2; 0; 1; 1; 1; 1; 0; 1; 1; 0; 0; 0; 0; 0; 1; 0; 0; 1; 1];
subject_13 = [2; 2; 0; 0; 1; 1; 2; 2; 1; 1; 1; 1; 1; 1; 1; 0; 1; 0; 1; 1; 1; 1; 2; 1; 1; 1; 1; 0; 0; 0; 0; 1; 0; 0; 1; 1; 0; 1; 0; 1; 0; 0; 1; 1; 1; 0; 0; 2; 0; 0; 1; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0];
subject_14 = [2; 0; 0; 0; 0; 1; 2; 1; 2; 2; 0; 1; 1; 0; 0; 0; 0; 2; 0; 1; 1; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 1; 1; 0; 0; 1; 0; 2; 0; 2; 0; 0; 0; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0];

% saving
output_dir = pwd;  % file path where you'd like to save the file

% Save all subject variables into separate .mat files
for i = 1:14
    varname = sprintf('subject_%d', i);       % create the variable name as a string
    filename = sprintf('subject_rec_%d.mat', i);  % create the file name
    % Get the data from the variable using its name
    data = eval(varname);
    % Save the variable under its original name into a .mat file
    save(fullfile(output_dir, filename), varname);
end

%% -------------------------------------------------------------------------
%% Assigning phase recognizability to the structure
clear all;

for a = 1:14 % number of subjects (1–14)
    clearvars -except a 

    % load .json file
    fname = sprintf('subject_%d.json', a);
    fid = fopen(fname); 
    raw = fread(fid, inf); % read all data from "fid" as unsigned characters
    str = native2unicode(raw', 'UTF-8'); % convert characters to UTF-8 string
    fclose(fid); 
    val = jsondecode(str); % decode JSON format into a MATLAB structure

    % load .mat vector (contains recognizability labels for each signal)
    St = load(['subject_rec_' num2str(a) '.mat']); % load vector into variable St
    subject = St.(sprintf('subject_%d', a)); 

    % assign recognizability values: 1 = recognizable, 0 = unrecognizable, 2 = unusable
    for b = 1:numel(subject)
        val.measurements(b).Recognizability = subject(b);
    end

    % assign unique IDs to each measurement
    vector = (1:numel(val.measurements))';
    for p = 1:numel(val.measurements)
        val.measurements(p).ID = vector(p);
    end
        
    % Save the updated structure to a .mat file
    output_dir = pwd;  % <-- set your desired output path here
    filesignal = sprintf('val_subject%d.mat', a);
    save(fullfile(output_dir, filesignal), 'val');
end

