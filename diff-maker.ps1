param (
    [Parameter(Mandatory)]
    [String]$sourceFolder,
    [Parameter(Mandatory)]
    [String]$targetFolder,
    [Parameter(Mandatory)]
    [String]$outputFolder,
    [Parameter(Mandatory=$false)]
    [switch]$NoXDelta3,
    [Parameter(Mandatory=$false)]
    [switch]$NonInteractive
)

# Import functions
Get-ChildItem "$PSScriptRoot/functions/*.ps1" | ForEach-Object {
    . $_.FullName
}

# Validate input parameters
$sourceFolder = (Resolve-Path $SourceFolder).ProviderPath
$targetFolder = (Resolve-Path $TargetFolder).ProviderPath
$outputFolder = (Resolve-Path $OutputFolder).ProviderPath

if (-not (Test-Path $sourceFolder -PathType Container)) {
    throw "Source folder not found: $sourceFolder"
}

if (-not (Test-Path $targetFolder -PathType Container)) {
    throw "Target folder not found: $targetFolder"
}

if (-not $NoXDelta3) {
    if (-not (Test-Path ".\xdelta3.exe" -PathType Leaf)) {
        throw "xdelta3 executable not found in script folder: .\xdelta3.exe"
    }
}

# Init variables for scans
[string[]]$sourceFiles =  @()
[string[]]$targetFiles =  @()

# Init variables for results
[string[]]$addedFiles = @()
[string[]]$deletedFiles = @()
[string[]]$modifiedFiles = @()
$movedFiles = [System.Collections.Generic.Dictionary[string,string]]::new()

# Start timer
$startTime = Get-Date

# Scan files in both folders
Get-ChildItem -Path $sourceFolder -Recurse -File | ForEach-Object {
    $filePath = Get-RelativePath $_.FullName $sourceFolder
    $sourceFiles += $filePath
}
Get-ChildItem -Path $targetFolder -Recurse -File | ForEach-Object {
    $filePath = Get-RelativePath $_.FullName $targetFolder
    $targetFiles += $filePath
}

# Loop on targetFiles to find added/modified/unmodified files
foreach ($targetFile in $targetFiles) {
    if ($sourceFiles -contains $targetFile) {
        if (-not (Compare-Files "$sourceFolder\$targetFile" "$targetFolder\$targetFile")) {
            $modifiedFiles += $targetFile
        }
    } else {
        $addedFiles += $targetFile
    }
}

# Loop on sourceFiles to find deleted files
foreach ($sourceFile in $sourceFiles) {
    if (-not ($targetFiles -contains $sourceFile)) {
        $deletedFiles += $sourceFile
    }
}

# At this step, it is possible than some "addedFiles" or "deletedFiles" are actually "movedFiles"
# Let's calculate the hash of each "addedFiles" and "deletedFiles" to find "movedFiles", then clean the "addedFiles" and "deletedFiles" lists
$addedHashes = @{}
foreach ($addedFile in $addedFiles) {
    $addedHash = (Get-FileHash "$targetFolder\$addedFile" -Algorithm SHA1).Hash
    $addedHashes[$addedHash] = $addedFile
}
foreach ($deletedFile in $deletedFiles) {
    $deletedHash = (Get-FileHash "$sourceFolder\$deletedFile" -Algorithm SHA1).Hash
    if ($addedHashes.ContainsKey($deletedHash)) {
        $addedFile = $addedHashes[$deletedHash]
        Write-Output "Moved: $deletedFile => $addedFile"
        $movedFiles[$deletedFile] = $addedFile
        $deletedFiles = $deletedFiles | Where-Object { $_ -ne $deletedFile }
        $addedFiles = $addedFiles | Where-Object { $_ -ne $addedFile }
    }
}

# Output results
Write-Output "Added files:"
$addedFiles | ForEach-Object { Write-Output "  $_" }
Write-Output "Deleted files:"
$deletedFiles | ForEach-Object { Write-Output "  $_" }
Write-Output "Modified files:"
$modifiedFiles | ForEach-Object { Write-Output "  $_" }
Write-Output "Moved files:"
$movedFiles.GetEnumerator() | ForEach-Object { Write-Output "  $($_.Key) => $($_.Value)" }

# End timer and output duration
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Output "Analysis duration: $($duration.TotalSeconds) seconds"

if (-not $NonInteractive) {
    Read-Host -Prompt 'Press Enter to continue to output folder'
}

foreach ($addedFile in $addedFiles) {
    $targetPath = "$targetFolder\$addedFile"
    $outputPath = "$outputFolder\$addedFile"
    New-Item -ItemType Directory -Path (Split-Path $outputPath) -Force | Out-Null
    Copy-Item -Path $targetPath -Destination $outputPath
    Write-Output "[NEW_COPY] $addedFile"
}

foreach ($modifiedFile in $modifiedFiles) {
    $targetPath = "$targetFolder\$modifiedFile"
    $outputPath = "$outputFolder\$modifiedFile"
    New-Item -ItemType Directory -Path (Split-Path $outputPath) -Force | Out-Null
    if ($NoXDelta3 -or -not (Test-IsBinaryFile "$targetFolder\$modifiedFile")) {
        # If xdelta3 is disabled or the file is a text file (not binary), copy it
        Write-Output "[MOD_COPY] $modifiedFile"
        Copy-Item -Path $targetPath -Destination $outputPath
    } else {
        # If xdelta3 is enabled and the file is binary, generate the xdelta patch
        Write-Output "[MOD_XDT3] $modifiedFile"
        $sourcePath = "$sourceFolder\$modifiedFile"
        $outputPath += ".xdelta"
        Start-XDelta3 -SourcePath $sourcePath -TargetPath $targetPath -OutputPath $outputPath
    }
}

if ($deletedFiles.Count -eq 0 -and $movedFiles.Count -eq 0) {
    Write-Output "No deleted or moved files, exiting early."
    Exit
}

$nsisFilePath = "$outputFolder\@nsis.txt"

if (Test-Path $nsisFilePath) {
    # Clear file if already exists
    Clear-Content $nsisFilePath
} else {
    # Or create empty file
    New-Item -Path $nsisFilePath -ItemType File | Out-Null
}

foreach ($movedFile in $movedFiles.GetEnumerator()) {
    Add-Content -Path $nsisFilePath -Value "Rename ""$($movedFile.Key)"" ""$($movedFile.Value)"""
}

foreach ($deletedFile in $deletedFiles | Sort-Object) {
    Add-Content -Path $nsisFilePath -Value "Delete ""$deletedFile"""
}
