function Compare-Files {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceFile,

        [Parameter(Mandatory)]
        [string]$TargetFile
    )

    if (-not (Test-Path $SourceFile -PathType Leaf)) {
        throw "Source file not found: $SourceFile"
    }

    if (-not (Test-Path $TargetFile -PathType Leaf)) {
        throw "Target file not found: $TargetFile"
    }

    $sourceSize = (Get-Item $SourceFile -ErrorAction Stop).Length
    $targetSize = (Get-Item $TargetFile -ErrorAction Stop).Length

    if ($sourceSize -ne $targetSize) {
        return $false
    }

    $sourceHash = (Get-FileHash -Path $SourceFile -Algorithm SHA1).Hash
    $targetHash = (Get-FileHash -Path $TargetFile -Algorithm SHA1).Hash

    return ($sourceHash -eq $targetHash)
}
