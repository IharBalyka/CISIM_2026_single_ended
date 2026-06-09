% Filter parameters
Fs      = 44100;       % Sampling frequency (Hz)
N       = 13;          % Filter order
Fc      = 3500;        % Cutoff frequency (Hz)
Fsupp   = 4000;        % Stopband start frequency (Hz)
Rp      = 0.1;         % Passband ripple (dB)
Rs      = 50;          % Stopband attenuation (dB)

% Normalized passband edge (relative to Nyquist)
Wp_norm = Fc / (Fs/2);

% Normalized stopband edge for Chebyshev type II
Ws_norm = Fsupp / (Fs/2);
[~, Wstop] = cheb2ord(Wp_norm, Ws_norm, Rp, Rs);  % Stopband edge from order estimation

% Filter design
[b_butter, a_butter] = butter(N, Wp_norm, 'low');                % Butterworth
[b_cheb1,  a_cheb1]  = cheby1(N, Rp, Wp_norm, 'low');           % Chebyshev type I
[b_cheb2,  a_cheb2]  = cheby2(N, Rs, Wstop, 'low');             % Chebyshev type II
[b_ellip,  a_ellip]  = ellip(N, Rp, Rs, Wp_norm, 'low');        % Elliptic (Cauer)

%% Magnitude response plot
figure;
hold on;

[H, f] = freqz(b_butter, a_butter, 1024, Fs);
%plot(f/1000, 20*log10(abs(H)), 'b', 'DisplayName', 'Butterworth');

[H, f] = freqz(b_cheb1, a_cheb1, 1024, Fs);
plot(f/1000, 20*log10(abs(H)), 'r', 'DisplayName', 'Chebyshev I');

[H, f] = freqz(b_cheb2, a_cheb2, 1024, Fs);
%plot(f/1000, 20*log10(abs(H)), 'g', 'DisplayName', 'Chebyshev II');

[H, f] = freqz(b_ellip, a_ellip, 1024, Fs);
%plot(f/1000, 20*log10(abs(H)), 'm', 'DisplayName', 'Elliptic');

xlabel('Frequency (kHz)');
ylabel('Magnitude (dB)');
title('Magnitude response of filters');
legend('Location','SouthWest');
grid on;

%% Phase response plot
figure;
hold on;

[phi, f] = phasez(b_butter, a_butter, 1024, Fs);
%plot(f/1000, unwrap(phi)*180/pi, 'b', 'DisplayName', 'Butterworth');

[phi, f] = phasez(b_cheb1, a_cheb1, 1024, Fs);
plot(f/1000, unwrap(phi)*180/pi, 'r', 'DisplayName', 'Chebyshev I');

[phi, f] = phasez(b_cheb2, a_cheb2, 1024, Fs);
%plot(f/1000, unwrap(phi)*180/pi, 'g', 'DisplayName', 'Chebyshev II');

[phi, f] = phasez(b_ellip, a_ellip, 1024, Fs);
%plot(f/1000, unwrap(phi)*180/pi, 'm', 'DisplayName', 'Elliptic');

xlabel('Frequency (kHz)');
ylabel('Phase (degrees)');
title('Phase response of filters');
legend('Location','SouthWest');
grid on;

%% Helper functions

function y_filtered = filter_cheby1(x, Fs, Fc)
% filter_cheby1 — Filtering audio signal with Chebyshev type I filter
%
% Input arguments:
%   x  — input audio signal (vector)
%   Fs — sampling frequency (Hz)
%   Fc — filter cutoff frequency (Hz)
%
% Output:
%   y_filtered — filtered signal

    N  = 13;      % filter order
    Rp = 0.1;     % passband ripple (dB)

    Wn = Fc / (Fs/2);          % normalized cutoff frequency
    [b, a] = cheby1(N, Rp, Wn, 'low');
    y_filtered = filtfilt(b, a, x);   % zero-phase forward-backward filtering
end

function filter_folder_cheby1_multifreq(folderPath, cutoff_freqs)
% filter_folder_cheby1_multifreq — Filter all WAV files recursively with
% a list of Chebyshev type I cutoffs
%
% Input:
%   folderPath   — path to folder containing WAV files
%   cutoff_freqs — vector of cutoff frequencies in Hz, e.g. [1000 2000 3000]

    N  = 13;      % filter order
    Rp = 0.1;     % passband ripple (dB)

    % Recursively list all WAV files
    files = dir(fullfile(folderPath, '**', '*.wav'));

    for k = 1:length(files)
        fullFilePath = fullfile(files(k).folder, files(k).name);
        [x, Fs] = audioread(fullFilePath);
        [~, baseName, ~] = fileparts(files(k).name);

        for i = 1:length(cutoff_freqs)
            Fc = cutoff_freqs(i);
            Wn = Fc / (Fs/2);
            [b, a] = cheby1(N, Rp, Wn, 'low');
            y = filtfilt(b, a, x);

            outName = sprintf('%s_%05dHz.wav', baseName, Fc);
            outPath = fullfile(files(k).folder, outName);
            audiowrite(outPath, y, Fs);

            fprintf('✔ %s → %s\n', files(k).name, outName);
        end
    end
end

% Example usage (commented out)
% folder = 'C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\For objective 7 second filtered';
% cutoff_freqs = [3500 5000 6500 8000 10000 12000 14000 16000];  % cutoff frequencies in Hz
% filter_folder_cheby1_multifreq(folder, cutoff_freqs);