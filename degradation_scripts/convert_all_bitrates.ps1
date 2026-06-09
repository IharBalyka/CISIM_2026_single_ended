<#
 convert_with_encoders.ps1
 Recursively convert audio files from $Src, preserving directory structure under $Dst.
 You can configure an array $Encoders with encoder id and encoder-specific arguments.
#>

[CmdletBinding()]
param(
    [string]$Src  = "C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\For objective 7 second mono",
    [string]$Dst  = "C:\Users\balyk\OneDrive - Politechnika Białostocka\Pulpit\Database for tests\freac test",
    [string]$Freac = "C:\Program Files\freac\freaccmd.exe",
    [string[]]$Exts = @("wav","flac","ogg","m4a","aiff","aif","mp3","opus","mp2"),
    [switch]$Overwrite,
    [string]$ExhalePath = "C:\Program Files\freac\codecs\cmdline\exhale.exe"
)

# ----------------- Configure encoders here -----------------
# Each entry is a hashtable with:
#  - Id: encoder id accepted by freaccmd (lowercase, e.g. "lame","flac","opus")
#  - Args: array of encoder-specific CLI args to pass AFTER the encoder selection
#  - OutExt: desired output file extension (e.g. ".mp3", ".flac", ".opus")
# Example entries below. Edit, add or remove entries as needed.
$Encoders = @(
    @{ Id = "lame"; Args = @("-m","CBR","-b","24","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","32","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","48","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","64","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","96","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","128","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","160","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","192","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","256","--superfast"); OutExt = ".mp3" },
    @{ Id = "lame"; Args = @("-m","CBR","-b","320","--superfast"); OutExt = ".mp3" },
    @{ Id = "twolame"; Args = @("-b","24","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","32","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","48","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","64","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","96","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","128","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","160","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","192","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","256","--superfast"); OutExt = ".mp2" },
    @{ Id = "twolame"; Args = @("-b","320","--superfast"); OutExt = ".mp2" },
    @{ Id = "vorbis"; Args = @("-b","48","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","64","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","96","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","128","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","160","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","192","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","256","--superfast"); OutExt = ".ogg" },
    @{ Id = "vorbis"; Args = @("-b","320","--superfast"); OutExt = ".ogg" },
    @{ Id = "opus"; Args = @("--bitrate","24","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","32","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","48","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","64","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","96","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","128","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","160","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","192","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","256","--superfast"); OutExt = ".opus" },
    @{ Id = "opus"; Args = @("--bitrate","320","--superfast"); OutExt = ".opus" },
    @{ Id = "fdkaac"; Args = @("-b","24","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","32","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","48","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","64","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","96","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","128","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","160","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","192","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-b","256","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","24","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","32","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","48","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","64","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","96","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","128","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","160","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","192","--superfast"); OutExt = ".m4a" },
    @{ Id = "fdkaac"; Args = @("-m", "HE","-b","256","--superfast"); OutExt = ".m4a" },
    @{ Id = "exhale"; Args = @("0"); OutExt = ".m4a" },
    @{ Id = "exhale"; Args = @("1"); OutExt = ".m4a" },
    @{ Id = "exhale"; Args = @("3"); OutExt = ".m4a" },
    @{ Id = "exhale"; Args = @("5"); OutExt = ".m4a" },
    @{ Id = "exhale"; Args = @("9"); OutExt = ".m4a" }
)
# ----------------------------------------------------------

"Source: $Src"
"Dest:   $Dst"
"Freac:  $Freac"
""

# checks
if (-not (Test-Path -LiteralPath $Freac)) {
    Write-Host "ERROR: freaccmd.exe not found at: $Freac" -ForegroundColor Red
    "ERROR: freaccmd not found: $Freac"
    pause; exit 1
}
if (-not (Test-Path -LiteralPath $Src)) {
    Write-Host "ERROR: Source folder not found: $Src" -ForegroundColor Red
    "ERROR: source not found: $Src"
    pause; exit 1
}
if (-not (Test-Path -LiteralPath $Dst)) { New-Item -ItemType Directory -Path $Dst -Force | Out-Null }

# collect files
$files = Get-ChildItem -LiteralPath $Src -Recurse -File | Where-Object {
    $ext = $_.Extension.TrimStart(".").ToLowerInvariant()
    $Exts -contains $ext
}
if ($files.Count -eq 0) {
    Write-Host "No files found in $Src matching extensions: $($Exts -join ', ')" -ForegroundColor Yellow
    "No files found."
    pause; exit 0
}

$files = $files | Sort-Object {Get-Random}
# files = $files | Select-Object -First 500

# main loop
foreach ($f in $files) {
    $relative = $f.FullName.Substring($Src.Length).TrimStart('\','/')
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($relative)
    $relDir = [System.IO.Path]::GetDirectoryName($relative)
    if ($relDir -eq $null) { $relDir = "" }

    $Encoders = $Encoders | Sort-Object {Get-Random}

    foreach ($enc in $Encoders) {
        $encId = $enc.Id
        $encArgs = @()
        if ($enc.Args) { $encArgs = $enc.Args }
        $outExt = $enc.OutExt
        if (-not $outExt) { $outExt = ".out" }

        # choose output directory: you get subfolder per encoder id (avoid collisions)
        $safeEncName = ($encId -replace '[\\/:*?"<>|]','_') + ($encArgs -join '_')
        $safeEncName = $safeEncName -replace '\s+','_'
        $safeEncName = $safeEncName.TrimEnd('_')
        $outDir = Join-Path -Path $Dst -ChildPath $safeEncName
        if ($relDir -ne "") { $outDir = Join-Path -Path $outDir -ChildPath $relDir }
        if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

        $outFile = Join-Path -Path $outDir -ChildPath ($baseName + $outExt)

        if ((Test-Path -LiteralPath $outFile) -and (-not $Overwrite)) {
            Write-Host "Skipping (exists): $outFile" -ForegroundColor DarkGray
            ("SKIP: $outFile")
            continue
        }

        Write-Host "Convert: $($f.FullName) -> $outFile  (encoder: $encId  args: $($encArgs -join ' '))"
        ("RUN: $($f.FullName) -> $outFile  (encoder: $encId args: $($encArgs -join ' '))")

        # build final argument array: encoder selection via -e <id>, then encoder-specific args, then -o <outfile> and input file
        $args = @("-e", $encId) + $encArgs + @("-o", $outFile, $f.FullName)

        try {
            if ($encId -eq "exhale") {
                if (-not (Test-Path -LiteralPath $ExhalePath)) {
                    throw "Custom encoder not found: $ExhalePath"
                }
                # Вызов: exhale.exe <args> <input> <output>
                & "$ExhalePath" @encArgs $f.FullName $outFile
            } else {
                # Стандартный вызов freaccmd.exe
                $args = @("-e", $encId) + $encArgs + @("-o", $outFile, $f.FullName)
                & "$Freac" @args
            }
            $exit = $LASTEXITCODE
        } catch {
            $exit = 1
            $errMsg = $_.Exception.Message
            ("EXCEPTION: $errMsg -- File: $($f.FullName) Encoder: $encId")
            Write-Host "Exception calling freaccmd: $errMsg" -ForegroundColor Red
        }

        if ($exit -ne 0) {
            $msg = "ERROR: freaccmd returned exit code $exit for file $($f.FullName) encoder $encId args: $($encArgs -join ' ')"
            Write-Host $msg -ForegroundColor Red
            $msg
        } else {
            $msg = "OK: $outFile"
            $msg
        }
    }
}

"=== finished: $(Get-Date -Format 's') ==="
Write-Host "Done." -ForegroundColor Green
pause