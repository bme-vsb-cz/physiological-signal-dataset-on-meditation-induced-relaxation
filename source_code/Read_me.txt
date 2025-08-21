The folder 'filtering' contains the following code:
        --initial_signal_plotting.m:  Part 1: Plots the GSR signal with markers of the meditation phase. The goal is to define a recognizable meditation phase (1), an unrecognizable meditation phase (0), and unusable signal (2).
                                      Part 2: The results must be manually written into a vector and the vector saved (e.g., subject_1.mat).
                                      Part 3: The code then assigns the saved vectors to a structure and stores this information in the variable val, which is loaded in other scripts.
                                      -Each measurement is also assigned an ID for further analysis.
                                      Required files: input data in .json format
                                      Note: the script must be run in parts.


The folder 'GSR_decomposition_ledalab' contains:
       --A ledalab_master folder, which includes all necessary scripts for GSR signal decomposition. MATLAB must have access to this folder when running the Ledalab software.

       --prepare_data_for_ledalab.m: An algorithm that prepares data for Ledalab input:
                                     -Filters GSR signal with a recognizable meditation phase, removes the first minute of recording, saves markers of the 4-minute meditation phase (e.g., ledalab_GSR1.mat), and saves indices of the 4-minute meditation phase (e.g., ledalab_index1.mat).
                                     Required variables: val_subjectX.mat

        --batch_mode.m: A command for automatic signal decomposition in Ledalab.


The folder 'features' contains:
        --features_GSR.m: An algorithm that computes features from the phasic component of the GSR signal.
                          The output includes real features (Subject_med.mat), normalized features (Subject_norm.mat), and measurement IDs (ID_GS.mat), which can be used in further analysis.
                          Required variables: val_subjectX.mat, ledalab_GSRX.mat


The folder 'GSR_analysis' contains:
         --prepare_data_for_ledalab_all_phases.m: An algorithm that filters GSR signal with a recognizable meditation phase, removes the first minute of recording, saves markers of the 4-minute meditation phase (e.g., ledalab_GSR1.mat), and saves indices of the 4-minute meditation phase, as well as pre/post-meditation phases (e.g., index1.mat, GSR_index_beforeX.mat, GSR_index_afterX.mat).
                                                  Required variables: val_subjectX.mat

         --GSR_features_all_phases.m: Computes features from three phases of the GSR signal. The output includes calculated features (e.g., Subject_before.mat, Subject_before.mat), percentage difference visualized in plots, and statistical parameters of features (e.g., GSR_mean.mat).
                                      Required variables: val_subjectX.mat, ledalab_GSRX.mat, GSR_index_beforeX.mat, GSR_index_afterX.mat


The folder 'HRV_analysis' contains:
         --HRV_features.m: Computes features from three parts of the HRV signal. The output includes calculated features (e.g., HRV_feature_before.mat), boxplots, percentage differences in graphs, and statistical parameters of features (e.g., HRV_feature_mean.mat).
                           Required variables: val_subjectX.mat
