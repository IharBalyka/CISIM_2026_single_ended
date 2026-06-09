% -------------------------------------------------------------------------
% BATCH_CONFIGURABLE_EFFECTS_RANDOM
% Script for batch applying effects with parameters chosen randomly
% within specified ranges (Min/Max).
% -------------------------------------------------------------------------

% =========================================================================
% --- 1. PATH CONFIGURATION ---
% =========================================================================
sourceDir = 'C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\For objective 7 second mono';
targetDir = 'C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\NetworkLagged';
% =========================================================================

% =========================================================================
% --- 2. EFFECT CONFIGURATION (grouped by type) ---
% =========================================================================

% EFFECT 1 & 2: Stuttering and RoboticVoice (same parameter structure)
packet_experiments = [
    % Stuttering
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [10, 10])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [10, 10])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [10, 10])
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [20, 20])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [20, 20])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [20, 20])
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [30, 30])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [30, 30])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [30, 30])
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [40, 40])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [40, 40])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [40, 40])
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [50, 50])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [50, 50])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [50, 50])
    struct('Type', 'Stuttering', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [60, 60])
    struct('Type', 'Stuttering', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [60, 60])
    struct('Type', 'Stuttering', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [60, 60])
    
    % RoboticVoice
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [10, 10])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [10, 10])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [10, 10])
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [20, 20])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [20, 20])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [20, 20])
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [30, 30])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [30, 30])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [30, 30])
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [40, 40])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [40, 40])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [40, 40])
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [50, 50])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [50, 50])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [50, 50])
    struct('Type', 'RoboticVoice', 'LossProb', [0.01, 0.10], 'PacketDur_ms', [60, 60])
    struct('Type', 'RoboticVoice', 'LossProb', [0.10, 0.20], 'PacketDur_ms', [60, 60])
    struct('Type', 'RoboticVoice', 'LossProb', [0.20, 0.30], 'PacketDur_ms', [60, 60])
];

% EFFECT 3: Lag / Latency
lag_experiments = [
    struct('Type', 'LagDelay', 'Delay_ms', [10, 100], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [100, 200], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [200, 300], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [300, 400], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [400, 500], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [500, 600], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [600, 700], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [700, 800], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [800, 900], 'EchoGain', [0.1, 0.6])
    struct('Type', 'LagDelay', 'Delay_ms', [900, 1000], 'EchoGain', [0.1, 0.6])
];

total_experiments = length(packet_experiments) + length(lag_experiments);
disp(['Total experiments found: ', num2str(total_experiments)]);
disp('Starting processing...');

% --- 3. GET LIST OF FILES ---
files = dir(fullfile(sourceDir, '**', '*.wav'));

if isempty(files)
    disp('⚠️ No WAV files found in source directory.');
    return;
end

% =========================================================================
% --- 4. MAIN PROCESSING LOOP ---
% =========================================================================

% Process packet-based effects
for exp_idx = 1:length(packet_experiments)
    
    current_exp = packet_experiments(exp_idx);
    exp_type = current_exp.Type;
    
    % Get parameter ranges
    min_L = current_exp.LossProb(1);
    max_L = current_exp.LossProb(2);
    min_P = current_exp.PacketDur_ms(1);
    max_P = current_exp.PacketDur_ms(2);
    
    % Create folder for the experiment (includes ranges in name)
    folderName = sprintf('%s_L%.2f-%.2f_P%d-%dms', exp_type, min_L, max_L, min_P, max_P);
    
    mainEffectDir = fullfile(targetDir, folderName);
    
    if ~exist(mainEffectDir, 'dir')
        mkdir(mainEffectDir);
        disp(['Created experiment folder: ', folderName]);
    end
    
    % --- Loop over files ---
    for k = 1:length(files)
        
        % GENERATE RANDOM VALUES FOR EACH FILE
        loss_prob_value = min_L + (max_L - min_L) * rand();
        packet_dur_ms_value = randi([min_P, max_P]);
        
        inPath = fullfile(files(k).folder, files(k).name);
        [y, Fs] = audioread(inPath);
        
        if size(y, 2) > 1
            audio_mono = mean(y, 2);
        else
            audio_mono = y;
        end
        N = length(audio_mono);
        
        relPath = strrep(files(k).folder, sourceDir, '');
        if startsWith(relPath, filesep)
            relPath = relPath(2:end);
        end
        
        effectSubDir = fullfile(mainEffectDir, relPath);
        if ~exist(effectSubDir, 'dir')
            mkdir(effectSubDir);
        end
        outPath = fullfile(effectSubDir, files(k).name);
        
        % --- APPLY EFFECT ---
        distorted_audio = audio_mono;
        
        loss_prob = loss_prob_value;
        packet_dur_s = packet_dur_ms_value / 1000;
        
        packet_size = round(packet_dur_s * Fs);
        num_packets = floor(N / packet_size);
        last_good_packet = zeros(packet_size, 1);
        
        for i = 1:num_packets
            start_idx = (i - 1) * packet_size + 1;
            end_idx = i * packet_size;
            current_packet = audio_mono(start_idx:end_idx);
            
            if rand() < loss_prob
                if strcmp(exp_type, 'Stuttering')
                    distorted_audio(start_idx:end_idx) = 0; 
                else % RoboticVoice
                    distorted_audio(start_idx:end_idx) = last_good_packet;
                end
            else
                distorted_audio(start_idx:end_idx) = current_packet;
                last_good_packet = current_packet;
            end
        end
        
        audiowrite(outPath, distorted_audio, Fs);
    end
    disp(['✅ Experiment ', folderName, ' completed.']);
end

% Process lag-based effects
for exp_idx = 1:length(lag_experiments)
    
    current_exp = lag_experiments(exp_idx);
    exp_type = current_exp.Type;
    
    % Get parameter ranges
    min_D = current_exp.Delay_ms(1);
    max_D = current_exp.Delay_ms(2);
    min_G = current_exp.EchoGain(1);
    max_G = current_exp.EchoGain(2);
    
    % Create folder for the experiment
    folderName = sprintf('LagDelay_D%d-%dms_G%.2f-%.2f', min_D, max_D, min_G, max_G);
    
    mainEffectDir = fullfile(targetDir, folderName);
    
    if ~exist(mainEffectDir, 'dir')
        mkdir(mainEffectDir);
        disp(['Created experiment folder: ', folderName]);
    end
    
    % --- Loop over files ---
    for k = 1:length(files)
        
        % GENERATE RANDOM VALUES FOR EACH FILE
        delay_ms_value = randi([min_D, max_D]);
        echo_gain_value = min_G + (max_G - min_G) * rand();
        
        inPath = fullfile(files(k).folder, files(k).name);
        [y, Fs] = audioread(inPath);
        
        if size(y, 2) > 1
            audio_mono = mean(y, 2);
        else
            audio_mono = y;
        end
        N = length(audio_mono);
        
        relPath = strrep(files(k).folder, sourceDir, '');
        if startsWith(relPath, filesep)
            relPath = relPath(2:end);
        end
        
        effectSubDir = fullfile(mainEffectDir, relPath);
        if ~exist(effectSubDir, 'dir')
            mkdir(effectSubDir);
        end
        outPath = fullfile(effectSubDir, files(k).name);
        
        % --- APPLY EFFECT ---
        delay_samples = round(delay_ms_value / 1000 * Fs);
        delayed_signal = [zeros(delay_samples, 1); audio_mono * echo_gain_value];
        
        if length(delayed_signal) > N
            delayed_signal = delayed_signal(1:N);
        else
            padding = N - length(delayed_signal);
            delayed_signal = [delayed_signal; zeros(padding, 1)];
        end
        
        distorted_audio = audio_mono + delayed_signal;
        
        audiowrite(outPath, distorted_audio, Fs);
    end
    disp(['✅ Experiment ', folderName, ' completed.']);
end

disp('--- ALL BATCH PROCESSING COMPLETED. ---');