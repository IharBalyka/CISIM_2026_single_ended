% -------------------------------------------------------------------------
% BATCH_NOISE_GENERATOR (White Noise & Pink Noise only)
% Script for batch addition of White and Pink Noise 
% with randomized SNR level.
% -------------------------------------------------------------------------

% =========================================================================
% --- 1. PATH AND PARAMETER SETUP ---
% =========================================================================
sourceDir = "C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\For objective 7 second mono";
targetDir = "C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\NoiseAdded_WhitePink"; % Folder for noisy files

snr_range_dB0 = [-5, 15];   % 1. Baseline (from challenging to clean)
snr_range_dB1 = [-10, 0];   % 2. Extreme Robustness (focus on high noise)
snr_range_dB2 = [10, 30];   % 3. Clean Recording (very low noise floor)
snr_range_dB3 = [0, 15];    % 4. Typical VoIP/Communication
snr_range_dB4 = [-15, 20];  % 5. Very Wide (maximum variability)
snr_range_dB5 = [5, 10];    % 6. Moderate Background (noise is audible but not dominant)
snr_range_dB6 = [-5, 5];    % 7. Mid-Low (noise and signal are often equal)
snr_range_dB7 = [15, 25];   % 8. High Quality (excellent environment)
snr_range_dB8 = [-10, 10];  % 9. Low Quality with Spikes (handle quality dips)
snr_range_dB9 = [4, 6];     % 10. Narrow Range (for precise testing)

% =========================================================================
% --- 2. EXPERIMENT CONFIGURATION ---
% =========================================================================
files = dir(fullfile(sourceDir, '**', '*.wav'));
files = files(~ismember({files.name}, {'.', '..'}));

if isempty(files)
    disp('⚠️ WAV files not found in the source directory.');
    return;
end

% Read first file for Fs
inPath_first = fullfile(files(1).folder, files(1).name);
try
    [~, Fs] = audioread(inPath_first);
catch
    error('Failed to read the first audio file. Check the path or file format.');
end
N_sample = 7 * Fs; 

noise_experiments = [
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB0, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB0, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB1, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB1, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB2, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB2, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB3, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB3, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB4, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB4, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB5, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB5, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB6, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB6, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB7, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB7, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB8, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB8, 'VariableSNR', true)
    struct('Type', 'WhiteNoise', 'SNR_range_dB', snr_range_dB9, 'VariableSNR', true) 
    struct('Type', 'PinkNoise', 'SNR_range_dB', snr_range_dB9, 'VariableSNR', true)
];

disp(['Detected noise experiments: ', num2str(length(noise_experiments))]);
disp('Starting spectrum visualization...');

% =========================================================================
% --- 3. NOISE FORM VISUALIZATION (ONCE) ---
% =========================================================================

N_vis = 2^15; 
Fs_vis = Fs; 

% USE CORRECT dsp.ColoredNoise SYNTAX (without SampleRate)
cn_white_vis = dsp.ColoredNoise('Color', 'White', 'SamplesPerFrame', N_vis);
cn_pink_vis = dsp.ColoredNoise('Color', 'Pink', 'SamplesPerFrame', N_vis);

noise_signals_vis = struct();
noise_signals_vis(1).name = 'WhiteNoise';
noise_signals_vis(1).signal = cn_white_vis();
noise_signals_vis(2).name = 'PinkNoise';
noise_signals_vis(2).signal = cn_pink_vis();

release(cn_white_vis);
release(cn_pink_vis);

% --- PLOT GENERATION ---
figure;
title('Noise Power Spectral Density (PSD)');
hold on;
for i = 1:length(noise_signals_vis)
    % Fs_vis is used correctly by the pwelch function
    [Pxx, Freq] = pwelch(noise_signals_vis(i).signal, hanning(512), 256, 512, Fs_vis, 'power');
    Pxx_dB = 10*log10(Pxx / max(Pxx)); 
    plot(Freq, Pxx_dB, 'DisplayName', noise_signals_vis(i).name, 'LineWidth', 1.5);
end

xlabel('Frequency (Hz)');
ylabel('Relative Power (dB)');
legend('show');
grid on;
set(gca, 'XScale', 'log'); 
xlim([20, Fs_vis/2]);
hold off;
disp('✅ Spectrum visualization completed. Continuing with batch processing...');


% =========================================================================
% --- 4. MAIN BATCH NOISE PROCESSING LOOP ---
% =========================================================================

% dsp.ColoredNoise INITIALIZATION for the loop (SamplesPerFrame removed, will be set later)
cn_white_proc = dsp.ColoredNoise('Color', 'White'); % <--- MODIFIED: Without SamplesPerFrame
cn_pink_proc = dsp.ColoredNoise('Color', 'Pink');   % <--- MODIFIED: Without SamplesPerFrame

% NORMALIZING sourceDir FOR RELIABLE PATH CONSTRUCTION
if ~endsWith(sourceDir, filesep)
    % Convert to char type for concatenation
    normalizedSourceDir = [char(sourceDir), filesep];
else
    normalizedSourceDir = char(sourceDir);
end

for exp_idx = 1:length(noise_experiments)
    
    current_exp = noise_experiments(exp_idx);
    exp_type = current_exp.Type;
    
    % Create experiment folder
    folderName = sprintf('%s_SNR%d-%ddB', exp_type, current_exp.SNR_range_dB(1), current_exp.SNR_range_dB(2));
    mainEffectDir = fullfile(targetDir, folderName);
    
    if ~exist(mainEffectDir, 'dir')
        mkdir(mainEffectDir);
        disp(['Created folder for experiment: ', folderName]);
    end
    
    for k = 1:length(files)
        
        inPath = fullfile(files(k).folder, files(k).name);
        [y, Fs] = audioread(inPath); 
        
        if size(y, 2) > 1
            audio_clean = mean(y, 2);
        else
            audio_clean = y;
        end
        N = length(audio_clean); 
        
        % -----------------------------------------------------------------
        % A. NOISE GENERATION
        % -----------------------------------------------------------------
        
        noise_signal = zeros(N, 1);
        
        if strcmp(exp_type, 'WhiteNoise')
            release(cn_white_proc); % <--- ERROR FIX: Unlock before changing the property
            cn_white_proc.SamplesPerFrame = N;
            noise_signal = cn_white_proc();
            
        elseif strcmp(exp_type, 'PinkNoise')
            release(cn_pink_proc);  % <--- ERROR FIX: Unlock before changing the property
            cn_pink_proc.SamplesPerFrame = N;
            noise_signal = cn_pink_proc();
        end
        
        % RMS normalization 
        noise_signal = noise_signal / rms(noise_signal); 
        
        % -----------------------------------------------------------------
        % B. APPLYING VARIABLE SNR AND MIXING
        % -----------------------------------------------------------------
        
        min_snr = current_exp.SNR_range_dB(1);
        max_snr = current_exp.SNR_range_dB(2);
        
        start_snr_dB = min_snr + (max_snr - min_snr) * rand();
        end_snr_dB = min_snr + (max_snr - min_snr) * rand();
        
        if ~current_exp.VariableSNR
             end_snr_dB = start_snr_dB; 
        end
        
        snr_vector_dB = linspace(start_snr_dB, end_snr_dB, N);
        % Calculate gain factor for noise: P_noise = P_signal / 10^(SNR/10)
        % For amplitude: A_noise = A_signal / 10^(SNR/20)
        snr_gain_factor = 10.^(-snr_vector_dB / 20); 
        
        scaled_noise_signal = noise_signal .* snr_gain_factor'; 
        
        audio_noisy = audio_clean + scaled_noise_signal;
        
        % Output normalization to prevent clipping (0.99 for safety margin)
        audio_noisy = audio_noisy / max(abs(audio_noisy)) * 0.99; 
        
        % -----------------------------------------------------------------
        % C. SAVING FILE (Preserving sourceDir structure)
        % -----------------------------------------------------------------
        
        % 1. Determine relative path using normalizedSourceDir
        relPath = strrep(char(files(k).folder), normalizedSourceDir, ''); 
        
        % 2. Formulate save path: targetDir/ExperimentFolder/relPath
        saveDir = fullfile(mainEffectDir, relPath);
        
        % 3. Create nested folders if they don't exist (IMPROVED CHECK)
        if ischar(saveDir) || isstring(saveDir) % <--- ERROR FIX: Check type before exist
            if ~exist(saveDir, 'dir')
                [status, ~, ~] = mkdir(saveDir);
                if status == 0
                    % If mkdir failed (rare), save to the main folder
                    warning('Failed to create nested path. Saving to the main experiment folder.');
                    saveDir = mainEffectDir;
                end
            end
        else
            % If saveDir is not a string (error), save to the main folder
            warning('Critical error: Save path is not a string. Saving to the main experiment folder.');
            saveDir = mainEffectDir;
        end
        
        % 4. Formulate file name
        outFileName = files(k).name;
        outPath = fullfile(saveDir, outFileName);
        
        audiowrite(outPath, audio_noisy, Fs);
    end
    disp(['✅ Experiment ', folderName, ' finished.']);
end

release(cn_white_proc);
release(cn_pink_proc);

disp('--- ALL BATCH NOISE PROCESSING COMPLETED. ---');