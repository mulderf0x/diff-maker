function Start-XDelta3 {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [Parameter(Mandatory)]
        [string]$OutputPath
    )

    if (-not (Test-Path $SourcePath -PathType Leaf)) {
        throw "Source file not found: $SourcePath"
    }

    if (-not (Test-Path $TargetPath -PathType Leaf)) {
        throw "Target file not found: $TargetPath"
    }

    $quotedSourcePath = '"' + $SourcePath + '"'
    $quotedTargetPath = '"' + $TargetPath + '"'
    $quotedOutputPath = '"' + $OutputPath + '"'

    $process = Start-Process `
        -FilePath (Join-Path $PSScriptRoot "..\xdelta3.exe") `
        -ArgumentList "-e -0 -S none -s $quotedSourcePath $quotedTargetPath $quotedOutputPath" `
        -NoNewWindow `
        -Wait `
        -PassThru

    if ($process.ExitCode -ne 0) {
        throw "xdelta3 failed with exit code $($process.ExitCode)"
    }
}
