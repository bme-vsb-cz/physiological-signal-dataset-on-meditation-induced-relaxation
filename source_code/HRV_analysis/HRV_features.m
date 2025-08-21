%% =================== HRV FEATURES ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%   Computes features from three parts of the HRV signal.
% The output includes calculated features (e.g., HRV_feature_before.mat), boxplots, percentage differences in graphs, and statistical parameters of features (e.g., HRV_feature_mean.mat).
% Required variables: val_subjectX.mat
% Set number of subjects (variable 'a')

% Default path set to current folder – change if needed.

clc;
clear variables;
close all;

tic

%% HRV feature computation
c = 0;

% --- Set output path (make sure the folder exists) ---
output_path = pwd; % <- adjust if necessary
if ~exist(output_path, 'dir')
    mkdir(output_path);
end

% load data
for a = 1:14 % number of subjects (1-14)
    clearvars -except a c output_path HRV_feature_before HRV_feature_after HRV_feature_med 
    b = 1;
    VAL = load(['val_proband' num2str(a) '.mat']);
    val = VAL.val;

    data_all = val.measurements;
    for i = 1:numel(data_all) % iterate over measurements
        clearvars -except a b i data_all val c output_path HRV_feature_before HRV_feature_after HRV_feature_med

        data = data_all(i).data;

        % --- marker calculation ---
        
        if ~isempty(val.measurements(i).data) && ...
           numel(data_all(i).questionnaires) >= 9 && ...  % added: check if the array is long enough
           strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && ...
           strcmp(data_all(i).questionnaires(9).answer, 'End of the meditation') && ...
           (data_all(i).Recognizability == 1)
        
            marker_start     = data_all(i).questionnaires(7).time;
            marker_start_med = data_all(i).questionnaires(8).time;
            marker_end_med   = data_all(i).questionnaires(9).time;
        
        elseif numel(data_all(i).questionnaires) >= 10 && ...  % added: check if the array is long enough
               strcmp(data_all(i).questionnaires(8).answer, 'Start of the meditation') && ...
               strcmp(data_all(i).questionnaires(9).answer, 'Start of the meditation') && ...
               strcmp(data_all(i).questionnaires(10).answer, 'End of the meditation') && ...
               (data_all(i).Recognizability == 1)
        
            marker_start     = data_all(i).questionnaires(7).time;
            marker_start_med = data_all(i).questionnaires(9).time;
            marker_end_med   = data_all(i).questionnaires(10).time;
        
        else
            continue
        end


        marker_start_time = str2double(marker_start);
        marker_start_time_med = str2double(marker_start_med);
        marker_end_time_med = str2double(marker_end_med);

        marker_S = (marker_start_time_med - marker_start_time);
        marker_E = marker_S + (marker_end_time_med - marker_start_time_med);

        % convert structure to cell array
        data_cell = struct2cell(data);

        GSR_data = data_cell(:, data_cell(1,:) == "GSR")';
        RR_data = data_cell(:, data_cell(1,:) == "RR")';

        GSR_time = str2double(GSR_data(:,2));
        GSR_signal = str2double(GSR_data(:,3));
        RR_time = str2double(RR_data(:,2));
        RR_signal = str2double(RR_data(:,3));

        % divide signal into three phases
        S = marker_S + 10000;
        E = marker_E - 10000;

        % remove first minute of recording
        M_RR_index_time = find(RR_time > (RR_time(1) + 60000));
        M_RR_time = RR_time(M_RR_index_time:end);
        M_RR_signal = RR_signal(M_RR_index_time:end);

        if isempty(M_RR_time) || S <= M_RR_time(1)
            continue
        end

        RR_index_before = find(M_RR_time < S);
        RR_index_med = find(M_RR_time >= S & M_RR_time <= E);
        RR_index_after = find(M_RR_time > E);

        if isempty(RR_index_before) || isempty(RR_index_med) || isempty(RR_index_after)
            continue
        end

        RR_signal_before = M_RR_signal(RR_index_before);
        RR_signal_med = M_RR_signal(RR_index_med);
        RR_signal_after = M_RR_signal(RR_index_after);

        signal_RR = [RR_signal_before', RR_signal_med', RR_signal_after'];
        time_RR = [M_RR_time(RR_index_before)', M_RR_time(RR_index_med)', M_RR_time(RR_index_after)'];
        time_RR = (time_RR - 60000) / 1000;

        % calculate HRV features only if all segments are >= 240s
        if range(time_RR) < 720
            continue
        end

        c = c + 1;
        index_before = find(time_RR >= time_RR(1) & time_RR <= time_RR(1) + 240);
        index_med = find(time_RR >= time_RR(index_before(end) + 1) & time_RR <= time_RR(index_before(end) + 1) + 240);
        index_after = find(time_RR >= time_RR(index_med(end) + 1) & time_RR <= time_RR(index_med(end) + 1) + 240);

        
        
        % Save RR_index_before
        filesignal = sprintf('RR_index_before%d.mat', c);
        save(fullfile(output_path, filesignal), 'index_before');
        
        % Save RR_index (med)
        filesignal = sprintf('RR_index%d.mat', c);
        save(fullfile(output_path, filesignal), 'index_med');
        
        % Save RR_index_after
        filesignal = sprintf('RR_index_after%d.mat', c);
        save(fullfile(output_path, filesignal), 'index_after');


        % HRV features: mean RR, HR, SDNN, SDSD, RMSSD, pNN50
        HRV_feature_before{a}(b,1) = mean(signal_RR(index_before));
        HRV_feature_med{a}(b,1) = mean(signal_RR(index_med));
        HRV_feature_after{a}(b,1) = mean(signal_RR(index_after));

        HRV_feature_before{a}(b,2) = 60000 / HRV_feature_before{a}(b,1);
        HRV_feature_med{a}(b,2) = 60000 / HRV_feature_med{a}(b,1);
        HRV_feature_after{a}(b,2) = 60000 / HRV_feature_after{a}(b,1);

        HRV_feature_before{a}(b,3) = std(signal_RR(index_before));
        HRV_feature_med{a}(b,3) = std(signal_RR(index_med));
        HRV_feature_after{a}(b,3) = std(signal_RR(index_after));

        L = diff(signal_RR(index_before));
        HRV_feature_before{a}(b,4) = sqrt(mean((abs(L) - mean(L)).^2));
        HRV_feature_before{a}(b,5) = sqrt(mean(L.^2));
        HRV_feature_before{a}(b,6) = (sum(abs(L) > 50) / (length(L)-1)) * 100;

        D = diff(signal_RR(index_med));
        HRV_feature_med{a}(b,4) = sqrt(mean((abs(D) - mean(D)).^2));
        HRV_feature_med{a}(b,5) = sqrt(mean(D.^2));
        HRV_feature_med{a}(b,6) = (sum(abs(D) > 50) / (length(D)-1)) * 100;

        K = diff(signal_RR(index_after));
        HRV_feature_after{a}(b,4) = sqrt(mean((abs(K) - mean(K)).^2));
        HRV_feature_after{a}(b,5) = sqrt(mean(K.^2));
        HRV_feature_after{a}(b,6) = (sum(abs(K) > 50) / (length(K)-1)) * 100;

        b = b + 1;
    end
end

% Save results
save(fullfile(output_path, 'HRV_feature_before.mat'), 'HRV_feature_before');
save(fullfile(output_path, 'HRV_feature_med.mat'), 'HRV_feature_med');
save(fullfile(output_path, 'HRV_feature_after.mat'), 'HRV_feature_after');

%--------------------------------------------------------------------------
%% subject-level HRV feature statistics

% features before meditation
HRV_mean{a}(1,:) = mean(HRV_feature_before{1,a}); % mean value of features for each subject
HRV_var{a}(1,:) = var(HRV_feature_before{1,a}); % variance of features for each subject
HRV_std{a}(1,:) = std(HRV_feature_before{1,a}); % standard deviation of features for each subject
HRV_median{a}(1,:) = median(HRV_feature_before{1,a}); % median of features for each subject
HRV_coefvar{a}(1,:) = HRV_std{a}(1,:) ./ HRV_mean{a}(1,:) * 100; % coefficient of variation (std/mean) for each subject

% features during meditation
HRV_mean{a}(2,:) = mean(HRV_feature_med{1,a});
HRV_var{a}(2,:) = var(HRV_feature_med{1,a});
HRV_std{a}(2,:) = std(HRV_feature_med{1,a});
HRV_median{a}(2,:) = median(HRV_feature_med{1,a});
HRV_coefvar{a}(2,:) = HRV_std{a}(2,:) ./ HRV_mean{a}(2,:) * 100;

% features after meditation
HRV_mean{a}(3,:) = mean(HRV_feature_after{1,a});
HRV_var{a}(3,:) = var(HRV_feature_after{1,a});
HRV_std{a}(3,:) = std(HRV_feature_after{1,a});
HRV_median{a}(3,:) = median(HRV_feature_after{1,a});
HRV_coefvar{a}(3,:) = HRV_std{a}(3,:) ./ HRV_mean{a}(3,:) * 100;

% Saving results (original filenames preserved)
filesignal = 'HRV_feature_mean.mat';
save(fullfile(output_path, filesignal), 'HRV_mean');
filesignal = 'HRV_feature_var.mat';
save(fullfile(output_path, filesignal), 'HRV_var');
filesignal = 'HRV_feature_std.mat';
save(fullfile(output_path, filesignal), 'HRV_std');
filesignal = 'HRV_feature_median.mat';
save(fullfile(output_path, filesignal), 'HRV_median');
filesignal = 'HRV_feature_varkoef.mat';
save(fullfile(output_path, filesignal), 'HRV_coefvar');

%--------------------------------------------------------------------------
%% Boxplots
fig = figure('WindowState', 'maximized');

% Convert cell arrays to numeric matrices
HRV_before = cell2mat(HRV_feature_before');
HRV_med    = cell2mat(HRV_feature_med');
HRV_after  = cell2mat(HRV_feature_after');

% Subplot for the pre-meditation phase
subplot(3,1,1)
boxplot([HRV_before(:,2), HRV_before(:,3), HRV_before(:,4), HRV_before(:,5), HRV_before(:,6)], ...
        'Labels', {'average HR (bpm)', 'SDNN', 'RMSSD', 'pNN50', 'HRV Triangular Index'});
set(gca, 'FontName', 'Times');
ylabel('Values', 'FontName', 'Times');
grid on;
t = title(sprintf('HRV features – pre-meditation phase, subject %d', a));
t.FontName = 'Times';

% Subplot for the meditation phase
subplot(3,1,2)
boxplot([HRV_med(:,2), HRV_med(:,3), HRV_med(:,4), HRV_med(:,5), HRV_med(:,6)], ...
    'Labels', {'average HR (bpm)', 'SDNN (ms)', 'SDSD (ms)', 'RMSSD (ms)', 'pNN50 (%)'});
set(gca, 'FontName', 'Times');
ylabel('Values', 'FontName', 'Times');
grid on;
t = title(sprintf('HRV features – meditation phase, subject %d', a));
t.FontName = 'Times';

% Subplot for the post-meditation phase
subplot(3,1,3)
boxplot([HRV_after(:,2), HRV_after(:,3), HRV_after(:,4), HRV_after(:,5), HRV_after(:,6)], ...
    'Labels', {'average HR (bpm)', 'SDNN (ms)', 'SDSD (ms)', 'RMSSD (ms)', 'pNN50 (%)'});
set(gca, 'FontName', 'Times');
ylabel('Values', 'FontName', 'Times');
grid on;
t = title(sprintf('HRV features – post-meditation phase, subject %d', a));
t.FontName = 'Times';

% Save the figure as a PDF
filename = sprintf('boxplot_subject_%d.pdf', a);
output_path = pwd;  % change to your target directory
if ~exist(output_path, 'dir')
    mkdir(output_path);
end
file = fullfile(output_path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);



%--------------------------------------------------------------------------
%% Percentage Differences
clearvars -except HRV_before HRV_med HRV_after

% Concatenate HRV features for all participants across each phase.
% Each variable (before, med, after) contains a vertically concatenated matrix 
% of HRV features from all 14 participants for the respective phase:

before = HRV_before;
med    = HRV_med;
after  = HRV_after;


%before = [HRV_feature_before{1}; HRV_feature_before{2}; HRV_feature_before{3}; HRV_feature_before{4}; HRV_feature_before{5}; ...
%          HRV_feature_before{6}; HRV_feature_before{7}; HRV_feature_before{8}; HRV_feature_before{9}; HRV_feature_before{10}; ...
%          HRV_feature_before{11}; HRV_feature_before{12}; HRV_feature_before{13}; HRV_feature_before{14}];

%med = [HRV_feature_med{1}; HRV_feature_med{2}; HRV_feature_med{3}; HRV_feature_med{4}; HRV_feature_med{5}; ...
%       HRV_feature_med{6}; HRV_feature_med{7}; HRV_feature_med{8}; HRV_feature_med{9}; HRV_feature_med{10}; ...
%       HRV_feature_med{11}; HRV_feature_med{12}; HRV_feature_med{13}; HRV_feature_med{14}];

%after = [HRV_feature_after{1}; HRV_feature_after{2}; HRV_feature_after{3}; HRV_feature_after{4}; HRV_feature_after{5}; ...
%         HRV_feature_after{6}; HRV_feature_after{7}; HRV_feature_after{8}; HRV_feature_after{9}; HRV_feature_after{10}; ...
%         HRV_feature_after{11}; HRV_feature_after{12}; HRV_feature_after{13}; HRV_feature_after{14}];

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

koef_before = (std_before./MEAN_before)*100; % coefficient of variation (%)
koef_med = (std_med./MEAN_med)*100;
koef_after = (std_after./MEAN_after)*100;
% Calculate percentage ratios of mean values (before and after meditation relative to during meditation)

percent_before_med_mean_HR = round((MEAN_before(1,2) / MEAN_med(1,2)) * 100, 2);
percent_after_med_mean_HR = round((MEAN_after(1,2) / MEAN_med(1,2)) * 100, 2);

percent_before_med_mean_SDNN = round((MEAN_before(1,3) / MEAN_med(1,3)) * 100, 2);
percent_after_med_mean_SDNN = round((MEAN_after(1,3) / MEAN_med(1,3)) * 100, 2);

percent_before_med_mean_RMSSD = round((MEAN_before(1,5) / MEAN_med(1,5)) * 100, 2);
percent_after_med_mean_RMSSD = round((MEAN_after(1,5) / MEAN_med(1,5)) * 100, 2);

percent_before_med_mean_pNN50 = round((MEAN_before(1,6) / MEAN_med(1,6)) * 100, 2);
percent_after_med_mean_pNN50 = round((MEAN_after(1,6) / MEAN_med(1,6)) * 100, 2);

% Create a bar plot comparing percentage ratios for selected HRV features
fig = figure('WindowState', 'maximized');
X = categorical({'average HR', 'SDNN', 'RMSSD', 'pNN50'});
X = reordercats(X, {'average HR', 'SDNN', 'RMSSD', 'pNN50'});

b = bar(X, [percent_before_med_mean_HR 100 percent_after_med_mean_HR;
            percent_before_med_mean_SDNN 100 percent_after_med_mean_SDNN;
            percent_before_med_mean_RMSSD 100 percent_after_med_mean_RMSSD;
            percent_before_med_mean_pNN50 100 percent_after_med_mean_pNN50]);

set(gca, 'FontName', 'Times');

b(1).FaceColor = 'blue';   % make the 1st column blue (before)
b(2).FaceColor = 'green';  % make the 2nd column green (meditation)
b(3).FaceColor = 'red';    % make the 3rd column red (after)

% Add value labels on each bar
xtips1 = b(1).XEndPoints; ytips1 = b(1).YEndPoints; labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints; ytips2 = b(2).YEndPoints; labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints; ytips3 = b(3).YEndPoints; labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

ylabel('percentage comparison (%)', 'FontName', 'Times');
xlabel('feature', 'FontName', 'Times');
ylim([60 350]);
t = title('Percentage comparison of means between HRV phases');
t.FontName = 'Times';
legend('before meditation', 'meditation', 'after meditation', 'FontName', 'Times');

% Save the figure to PDF
filename = sprintf('HRV_percentage_comparison_average.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%--------------------------------------------------------------------------
% Calculate percentage differences in variance (VAR) of HRV features
% Relative to the meditation phase, which is normalized to 100%

% HR (mean heart rate)
percent_before_med_var_HR = round((VAR_before(1,2) / VAR_med(1,2)) * 100, 2);
percent_after_med_var_HR = round((VAR_after(1,2) / VAR_med(1,2)) * 100, 2);

% SDNN (standard deviation of NN intervals)
percent_before_med_var_SDNN = round((VAR_before(1,3) / VAR_med(1,3)) * 100, 2);
percent_after_med_var_SDNN = round((VAR_after(1,3) / VAR_med(1,3)) * 100, 2);

% RMSSD (root mean square of successive differences)
percent_before_med_var_RMSSD = round((VAR_before(1,5) / VAR_med(1,5)) * 100, 2);
percent_after_med_var_RMSSD = round((VAR_after(1,5) / VAR_med(1,5)) * 100, 2);

% pNN50 (percentage of successive NN intervals > 50 ms)
percent_before_med_var_pNN50 = round((VAR_before(1,6) / VAR_med(1,6)) * 100, 2);
percent_after_med_var_pNN50 = round((VAR_after(1,6) / VAR_med(1,6)) * 100, 2);

% Create bar chart comparing variance of each feature across phases
fig = figure('WindowState', 'maximized');
X = categorical({'mean HR','SDNN','RMSSD','pNN50'});
X = reordercats(X,{'mean HR','SDNN','RMSSD','pNN50'});

% Bar plot: blue = before, green = during (reference, set to 100), red = after
b = bar(X, [percent_before_med_var_HR 100 percent_after_med_var_HR;
            percent_before_med_var_SDNN 100 percent_after_med_var_SDNN;
            percent_before_med_var_RMSSD 100 percent_after_med_var_RMSSD;
            percent_before_med_var_pNN50 100 percent_after_med_var_pNN50]);

set(gca, 'FontName', 'Times');

b(1).FaceColor = 'blue';  % before meditation
b(2).FaceColor = 'green'; % during meditation
b(3).FaceColor = 'red';   % after meditation

% Annotate each bar with its value
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([60 1000]); % Adjust Y-axis limits as needed
title('Percentage Comparison of HRV Feature Variances Across Phases', 'FontName', 'Times');
legend('Before Meditation', 'During Meditation', 'After Meditation', 'FontName', 'Times');

% Save the chart as PDF
filename = sprintf('HRV_percentage_comparison_variance.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);


%--------------------------------------------------------------------------
% Calculate percentage differences in median (MED) of HRV features
% Relative to the meditation phase, which is normalized to 100%

% HR (mean heart rate)
percent_before_med_med_HR = round((MED_before(1,2) / MED_med(1,2)) * 100, 2);
percent_after_med_med_HR = round((MED_after(1,2) / MED_med(1,2)) * 100, 2);

% SDNN (standard deviation of NN intervals)
percent_before_med_med_SDNN = round((MED_before(1,3) / MED_med(1,3)) * 100, 2);
percent_after_med_med_SDNN = round((MED_after(1,3) / MED_med(1,3)) * 100, 2);

% RMSSD (root mean square of successive differences)
percent_before_med_med_RMSSD = round((MED_before(1,5) / MED_med(1,5)) * 100, 2);
percent_after_med_med_RMSSD = round((MED_after(1,5) / MED_med(1,5)) * 100, 2);

% pNN50 (percentage of successive NN intervals > 50 ms)
percent_before_med_med_pNN50 = round((MED_before(1,6) / MED_med(1,6)) * 100, 2);
percent_after_med_med_pNN50 = round((MED_after(1,6) / MED_med(1,6)) * 100, 2);

% Plotting the percentage comparison of medians
fig = figure('WindowState', 'maximized');
X = categorical({'mean HR','SDNN','RMSSD','pNN50'});
X = reordercats(X, {'mean HR','SDNN','RMSSD','pNN50'});

% Bar chart: blue = before meditation, green = meditation phase (baseline = 100%), red = after meditation
b = bar(X, [percent_before_med_med_HR 100 percent_after_med_med_HR;
            percent_before_med_med_SDNN 100 percent_after_med_med_SDNN;
            percent_before_med_med_RMSSD 100 percent_after_med_med_RMSSD;
            percent_before_med_med_pNN50 100 percent_after_med_med_pNN50]);

set(gca, 'FontName', 'Times');

% Set colors for each bar group
b(1).FaceColor = 'blue';  % before meditation
b(2).FaceColor = 'green'; % during meditation (reference)
b(3).FaceColor = 'red';   % after meditation

% Add data labels above each bar
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([60 350]); % Adjust Y-axis limits as needed
title('Percentage Comparison of HRV Medians Across Phases', 'FontName', 'Times');
legend('Before Meditation', 'Meditation Phase', 'After Meditation', 'FontName', 'Times');

% Save the chart as PDF
filename = sprintf('HRV_percentage_comparison_median.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

%--------------------------------------------------------------------------
% Calculate percentage differences in standard deviation (STD) of HRV features
% All values are calculated relative to the meditation phase, which is normalized to 100%

% HR (mean heart rate)
percent_before_med_std_HR = round((std_before(1,2) / std_med(1,2)) * 100, 2);
percent_after_med_std_HR = round((std_after(1,2) / std_med(1,2)) * 100, 2);

% SDNN (standard deviation of NN intervals)
percent_before_med_std_SDNN = round((std_before(1,3) / std_med(1,3)) * 100, 2);
percent_after_med_std_SDNN = round((std_after(1,3) / std_med(1,3)) * 100, 2);

% RMSSD (root mean square of successive differences)
percent_before_med_std_RMSSD = round((std_before(1,5) / std_med(1,5)) * 100, 2);
percent_after_med_std_RMSSD = round((std_after(1,5) / std_med(1,5)) * 100, 2);

% pNN50 (percentage of successive NN intervals > 50 ms)
percent_before_med_std_pNN50 = round((std_before(1,6) / std_med(1,6)) * 100, 2);
percent_after_med_std_pNN50 = round((std_after(1,6) / std_med(1,6)) * 100, 2);

% Visualization
fig = figure('WindowState', 'maximized');
X = categorical({'mean HR','SDNN','RMSSD','pNN50'});
X = reordercats(X, {'mean HR','SDNN','RMSSD','pNN50'});

% Bar chart: blue = before meditation, green = during meditation, red = after meditation
b = bar(X, [percent_before_med_std_HR 100 percent_after_med_std_HR;
            percent_before_med_std_SDNN 100 percent_after_med_std_SDNN;
            percent_before_med_std_RMSSD 100 percent_after_med_std_RMSSD;
            percent_before_med_std_pNN50 100 percent_after_med_std_pNN50]);

set(gca, 'FontName', 'Times');

% Set custom colors
b(1).FaceColor = 'blue';   % before meditation
b(2).FaceColor = 'green';  % during meditation (reference)
b(3).FaceColor = 'red';    % after meditation

% Add value labels above each bar
xtips1 = b(1).XEndPoints;
ytips1 = b(1).YEndPoints;
labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints;
ytips2 = b(2).YEndPoints;
labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints;
ytips3 = b(3).YEndPoints;
labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);

ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([60 350]); % Set y-axis range
t = title('Percentage Comparison of Standard Deviations Across HRV Phases');
t.FontName = 'Times';
legend('Before Meditation','Meditation Phase','After Meditation','FontName', 'Times');

% Save the figure as a PDF
filename = sprintf('HRV_percentage_comparison_std.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);


%--------------------------------------------------------------------------
% Calculate percentage ratios of the coefficient of variation (CV)
% CV = standard deviation / mean * 100
% All values are normalized to the meditation phase (i.e., meditation = 100%)

percent_before_med_cv_HR = round((koef_before(1,2) / koef_med(1,2)) * 100, 2);
percent_after_med_cv_HR = round((koef_after(1,2) / koef_med(1,2)) * 100, 2);

percent_before_med_cv_SDNN = round((koef_before(1,3) / koef_med(1,3)) * 100, 2);
percent_after_med_cv_SDNN = round((koef_after(1,3) / koef_med(1,3)) * 100, 2);

percent_before_med_cv_RMSSD = round((koef_before(1,5) / koef_med(1,5)) * 100, 2);
percent_after_med_cv_RMSSD = round((koef_after(1,5) / koef_med(1,5)) * 100, 2);

percent_before_med_cv_pNN50 = round((koef_before(1,6) / koef_med(1,6)) * 100, 2);
percent_after_med_cv_pNN50 = round((koef_after(1,6) / koef_med(1,6)) * 100, 2);

% Create bar plot for percentage comparison
fig = figure('WindowState', 'maximized');
X = categorical({'mean HR','SDNN','RMSSD','pNN50'});
X = reordercats(X, {'mean HR','SDNN','RMSSD','pNN50'});

b = bar(X, [percent_before_med_cv_HR 100 percent_after_med_cv_HR;
            percent_before_med_cv_SDNN 100 percent_after_med_cv_SDNN;
            percent_before_med_cv_RMSSD 100 percent_after_med_cv_RMSSD;
            percent_before_med_cv_pNN50 100 percent_after_med_cv_pNN50]);

% Set font and color settings
set(gca, 'FontName', 'Times');
b(1).FaceColor = 'blue';   % before meditation
b(2).FaceColor = 'green';  % during meditation (reference phase)
b(3).FaceColor = 'red';    % after meditation

% Add data labels above each bar
xtips1 = b(1).XEndPoints; ytips1 = b(1).YEndPoints; labels1 = string(b(1).YData);
text(xtips1, ytips1, labels1, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

xtips2 = b(2).XEndPoints; ytips2 = b(2).YEndPoints; labels2 = string(b(2).YData);
text(xtips2, ytips2, labels2, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

xtips3 = b(3).XEndPoints; ytips3 = b(3).YEndPoints; labels3 = string(b(3).YData);
text(xtips3, ytips3, labels3, 'HorizontalAlignment','center', 'VerticalAlignment','bottom', 'FontSize', 8);

% Set axis labels and title
ylabel('Percentage Comparison (%)', 'FontName', 'Times');
xlabel('Feature', 'FontName', 'Times');
ylim([60 350]);

t = title('Percentage Comparison of HRV Coefficients of Variation Across Phases');
t.FontName = 'Times';

legend('Before Meditation','Meditation Phase','After Meditation','FontName', 'Times');

% Save figure to PDF
filename = sprintf('HRV_percentage_comparison_cv.pdf');
path = pwd;
file = fullfile(path, filename);
set(fig, 'visible', 'on'); 
exportgraphics(fig, file, 'Resolution', 300);
close(fig);

