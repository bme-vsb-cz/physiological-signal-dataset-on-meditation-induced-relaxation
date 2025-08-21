%% =================== BATCH MODE   ===================
% Authors: Eliska Szalbotova, Jan Kubicek, Terezie Kauzlaricova, Tereza Hrncirova
% Contact: Jan Kubicek, jan.kubicek@vsb.cz
% Last update: August 2025
% Description:
%    A command for automatic signal decomposition in Ledalab.    
% Set the number of participants (variable a)
% Required files: ledalab_GSR_sX_mY.mat
% Output: batchmode_protocol.mat

% Default path set to current folder – change if needed.

clc;
clear variables;
close all;

% ======= 1. Set the folder containing the input files =======
inputFolder = pwd; % <-- change if needed

% ======= 2. Set (or create) the output folder =======
outputFolder = pwd;
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% ======= 3. Find all .mat files in the input folder =======
%files = dir(fullfile(inputFolder, 'ledalab_GSR*.mat'));  % or simply *.mat if needed
files = dir(fullfile(inputFolder, 'ledalab_GSR_s01_m01.mat'));  

% ======= 4. Loop through all found files =======
for i = 1:length(files)
    filePath = fullfile(inputFolder, files(i).name);
    
    fprintf('Analyzing: %s\n', files(i).name);
    
    % Set the output folder as current working directory (important!)
    cd(outputFolder);
    
    % Run Ledalab with CDA and full optimization
    Ledalab(filePath, 'open', 'mat', 'analyze', 'CDA', 'optimize', 2);
end

fprintf('✅ All files have been processed. Output saved in: %s\n', outputFolder);
