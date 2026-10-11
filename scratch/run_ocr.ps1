param (
    [string]$ImagePath
)

Add-Type -AssemblyName System.Drawing
[Windows.Globalization.Language, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Graphics.Imaging.BitmapDecoder, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null
[Windows.Storage.StorageFile, Windows.Foundation, ContentType = WindowsRuntime] | Out-Null

$lang = New-Object Windows.Globalization.Language("en-US")
$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage($lang)
if (-not $engine) {
    $engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromUserProfileLanguages()
}

if (-not $engine) {
    Write-Output "OCR_UNAVAILABLE"
    exit 1
}

$resolvedPath = (Resolve-Path $ImagePath).Path

# Load SoftwareBitmap via async WinRT helper
$fileTask = [Windows.Storage.StorageFile]::GetFileFromPathAsync($resolvedPath)
$asyncOp = [Windows.Storage.StorageFile].GetMethod("GetFileFromPathAsync", [type[]]@([string])).Invoke($null, @($resolvedPath))
while ($asyncOp.Status -eq "Started") { Start-Sleep -Milliseconds 20 }
$storageFile = $asyncOp.GetResults()

$streamOp = $storageFile.OpenAsync([Windows.Storage.FileAccessMode]::Read)
while ($streamOp.Status -eq "Started") { Start-Sleep -Milliseconds 20 }
$stream = $streamOp.GetResults()

$decoderOp = [Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)
while ($decoderOp.Status -eq "Started") { Start-Sleep -Milliseconds 20 }
$decoder = $decoderOp.GetResults()

$bitmapOp = $decoder.GetSoftwareBitmapAsync()
while ($bitmapOp.Status -eq "Started") { Start-Sleep -Milliseconds 20 }
$softwareBitmap = $bitmapOp.GetResults()

$ocrOp = $engine.RecognizeAsync($softwareBitmap)
while ($ocrOp.Status -eq "Started") { Start-Sleep -Milliseconds 20 }
$ocrResult = $ocrOp.GetResults()

Write-Output "=== EXTRACTED OCR TEXT ==="
Write-Output $ocrResult.Text
Write-Output "=== END OCR TEXT ==="
Write-Output "Total Lines Detected: $($ocrResult.Lines.Count)"
