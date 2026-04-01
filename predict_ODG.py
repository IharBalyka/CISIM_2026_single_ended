import os
import argparse
import csv
import subprocess
import tempfile
from glob import glob

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
import librosa
from tqdm import tqdm

# ==========================================================
# SETTINGS
# ==========================================================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

MODELS = {
    "ODG_DeepMS(RES)": {
        "ckpt": os.path.join(SCRIPT_DIR, "DeepMS(RES).pth"),
        "type": "big",
    },
    "ODG_MS+RAW": {
        "ckpt": os.path.join(SCRIPT_DIR, "MS+RAW_best.pth"),
        "type": "small",
    },
}

SAMPLE_RATE   = 44100
DURATION_SEC  = 7
N_FFT         = 2048
HOP_LENGTH    = 256
TARGET_LENGTH = SAMPLE_RATE * DURATION_SEC

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# ==========================================================
# AUDIO LOADERS
# ==========================================================

def _load_via_ffmpeg(path: str, target_sr: int) -> tuple[np.ndarray, int]:
    cmd = ["ffmpeg", "-v", "quiet", "-i", path, "-f", "f32le", "-acodec", "pcm_f32le", "-ar", str(target_sr), "-ac", "1", "pipe:1"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode != 0 or len(result.stdout) == 0: raise RuntimeError("ffmpeg failed")
    return np.frombuffer(result.stdout, dtype=np.float32).copy(), target_sr

def _load_audio(path: str, target_sr: int) -> tuple[np.ndarray, int]:
    try:
        y, sr = librosa.load(path, sr=None, mono=False)
        return y, sr
    except:
        return _load_via_ffmpeg(path, target_sr)

# ==========================================================
# DATASET (Sliding Window Implementation)
# ==========================================================

class AudioDataset(Dataset):
    def __init__(self, wav_files, full_audio=False):
        self.wav_files = wav_files
        self.full_audio = full_audio

    def __len__(self):
        return len(self.wav_files)

    def __getitem__(self, idx):
        path = self.wav_files[idx]
        try:
            y, sr = _load_audio(path, SAMPLE_RATE)

            if y.ndim > 1:
                y = np.nan_to_num(y, nan=0.0)
                y = np.mean(y.astype(np.float64), axis=0)
            else:
                y = y.astype(np.float64)

            y = np.nan_to_num(y).astype(np.float32)
            if sr != SAMPLE_RATE:
                y = librosa.resample(y, orig_sr=sr, target_sr=SAMPLE_RATE)

            slices = []
            # If full_audio is False or file is short, take first 7s (original behavior)
            if not self.full_audio or len(y) <= TARGET_LENGTH:
                if len(y) > TARGET_LENGTH:
                    slices.append(y[:TARGET_LENGTH])
                else:
                    slices.append(np.pad(y, (0, TARGET_LENGTH - len(y)), mode="constant"))
            else:
                # Sliding window with 50% overlap (3.5s steps)
                step = TARGET_LENGTH // 2
                for start in range(0, len(y) - TARGET_LENGTH + 1, step):
                    slices.append(y[start : start + TARGET_LENGTH])
                
                # Catch the tail end if it wasn't perfectly reached
                if (len(y) - TARGET_LENGTH) % step != 0:
                    slices.append(y[-TARGET_LENGTH:])

            specs, waves = [], []
            for s in slices:
                stft = librosa.stft(s, n_fft=N_FFT, hop_length=HOP_LENGTH)
                log_spec = librosa.amplitude_to_db(np.abs(stft), ref=np.max)
                specs.append(log_spec.astype(np.float32))
                waves.append(s.astype(np.float32))

            return torch.from_numpy(np.array(specs)), torch.from_numpy(np.array(waves)), path

        except Exception as e:
            print(f"Error loading {path}: {e}")
            return None

def safe_collate(batch):
    batch = [b for b in batch if b is not None]
    return batch if batch else None

# ==========================================================
# ORIGINAL ARCHITECTURES (RESTORED EXACTLY)
# ==========================================================

class AdaptiveDropout(nn.Module):
    def __init__(self, p_min=0.0, p_max=0.9, initial_p=0.1, delta=0.05, ema_alpha=0.2):
        super().__init__()
        self.p = initial_p
        self.dropout = nn.Dropout(p=self.p)
    def forward(self, x):
        self.dropout.p = self.p
        return self.dropout(x)

class ResBlock(nn.Module):
    def __init__(self, channels):
        super().__init__()
        self.block = nn.Sequential(
            nn.Conv2d(channels, channels, kernel_size=3, padding=1),
            nn.BatchNorm2d(channels), nn.ReLU(),
            nn.Conv2d(channels, channels, kernel_size=3, padding=1),
            nn.BatchNorm2d(channels),
        )
        self.relu = nn.ReLU()
    def forward(self, x): return self.relu(self.block(x) + x)

def _make_backbone(use_res: bool):
    def stage(in_ch, out_ch):
        layers = [nn.Conv2d(in_ch, out_ch, kernel_size=3, padding=1), nn.BatchNorm2d(out_ch), nn.ReLU()]
        if use_res: layers.append(ResBlock(out_ch))
        layers.append(nn.MaxPool2d(2))
        return layers
    return nn.Sequential(*stage(1, 32), *stage(32, 64), *stage(64, 128), *stage(128, 256), *stage(256, 512))

class ModelLogOnly(nn.Module):
    def __init__(self):
        super().__init__()
        self.backbone = _make_backbone(use_res=True)
        self.pool = nn.AdaptiveAvgPool2d((1, 1))
        self.head = nn.Sequential(
            nn.Linear(512, 256), nn.ReLU(), AdaptiveDropout(),
            nn.Linear(256, 128), nn.ReLU(), AdaptiveDropout(), nn.Linear(128, 1)
        )
    def forward(self, x_linear):
        x = self.backbone(x_linear.unsqueeze(1))
        x = self.pool(x).flatten(1)
        return self.head(x)

class ModelLogWave(nn.Module):
    def __init__(self):
        super().__init__()
        self.linear_adapt = nn.Sequential(nn.Conv2d(1, 3, kernel_size=(11, 11), padding=5), nn.ReLU())
        self.linear_branch = nn.Sequential(
            nn.Conv2d(3, 32, 3, padding=1), nn.BatchNorm2d(32), nn.ReLU(), nn.MaxPool2d(2),
            nn.Conv2d(32, 64, 3, padding=1), nn.BatchNorm2d(64), nn.ReLU(), nn.MaxPool2d(2),
            nn.Conv2d(64, 128, 3, padding=1), nn.ReLU(), nn.AdaptiveAvgPool2d((1, 1))
        )
        self.linear_sqz = nn.Linear(128, 128)
        self.waveform_branch = nn.Sequential(
            nn.Conv1d(1, 32, 64, stride=4, padding=32), nn.BatchNorm1d(32), nn.ReLU(), nn.MaxPool1d(2),
            nn.Conv1d(32, 64, 16, stride=1, padding=8), nn.BatchNorm1d(64), nn.ReLU(),
            nn.Conv1d(64, 64, 16, stride=1, padding=8), nn.BatchNorm1d(64), nn.ReLU(), nn.MaxPool1d(4),
            nn.Conv1d(64, 128, 8, stride=1, padding=4), nn.BatchNorm1d(128), nn.ReLU(),
            nn.Conv1d(128, 128, 8, stride=1, padding=4), nn.BatchNorm1d(128), nn.ReLU(), nn.MaxPool1d(4),
            nn.Conv1d(128, 256, kernel_size=3, padding=1), nn.BatchNorm1d(256), nn.ReLU(),
            nn.Conv1d(256, 512, kernel_size=3, padding=1), nn.ReLU(), nn.AdaptiveAvgPool1d(1)
        )
        self.wave_sqz = nn.Linear(512, 128)
        self.common_head = nn.Sequential(
            nn.Linear(256, 256), nn.ReLU(), AdaptiveDropout(),
            nn.Linear(256, 128), nn.ReLU(), AdaptiveDropout()
        )
        self.head_peaq = nn.Linear(128, 1)

    def forward(self, x_linear, x_wave):
        x = self.linear_adapt(x_linear.unsqueeze(1))
        x = F.interpolate(x, size=(224, 224), mode="bilinear", align_corners=False)
        feat_linear = self.linear_sqz(self.linear_branch(x).flatten(1))
        feat_wave = self.wave_sqz(self.waveform_branch(x_wave.unsqueeze(1)).flatten(1))
        combined = torch.cat((feat_linear, feat_wave), dim=1)
        return self.head_peaq(self.common_head(combined))

# ==========================================================
# MAIN LOGIC
# ==========================================================

def load_model(model_type: str, ckpt_path: str) -> nn.Module:
    net = ModelLogOnly() if model_type == "big" else ModelLogWave()
    ckpt = torch.load(ckpt_path, map_location="cpu")
    state = ckpt.get("state_dict", ckpt)
    state = {k.replace("model.", "", 1): v for k, v in state.items()}
    net.load_state_dict(state, strict=False)
    return net.to(DEVICE).eval()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_dir", required=True)
    parser.add_argument("--output", default="results.csv")
    parser.add_argument("--recursive", action="store_true")
    parser.add_argument("--full_audio", action="store_true")
    parser.add_argument("--models", choices=["small", "big", "both"], default="both")
    args = parser.parse_args()

    pattern = os.path.join(args.input_dir, "**/*.wav") if args.recursive else os.path.join(args.input_dir, "*.wav")
    wav_files = sorted(glob(pattern, recursive=args.recursive))

    loaded_models = {}
    for name, info in MODELS.items():
        if args.models != "both" and info["type"] != args.models: continue
        if os.path.exists(info["ckpt"]):
            print(f"Loading {name}...")
            loaded_models[name] = {"net": load_model(info["type"], info["ckpt"]), "type": info["type"]}

    dataset = AudioDataset(wav_files, full_audio=args.full_audio)
    loader = DataLoader(dataset, batch_size=1, collate_fn=safe_collate)

    rows = []
    with torch.no_grad():
        for batch in tqdm(loader, desc="Predicting"):
            if batch is None: continue
            for specs, waves, path in batch:
                specs, waves = specs.to(DEVICE), waves.to(DEVICE)
                row = {"filename": path}
                for name, m in loaded_models.items():
                    preds = m["net"](specs) if m["type"] == "big" else m["net"](specs, waves)
                    row[name] = preds.mean().item()
                rows.append(row)

    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["filename"] + list(loaded_models.keys()))
        writer.writeheader()
        writer.writerows(rows)

if __name__ == "__main__":
    main()