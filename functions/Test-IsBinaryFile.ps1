function Test-IsBinaryFile {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path -PathType Leaf)) {
        throw "File not found: $Path"
    }

    $textExtensions = @(
        ".txt",".ini",".cfg",".json",".xml",".yml",".yaml",
        ".csv",".log",".md",".ps1",".bat",".cmd",
        ".html",".css",".js",".ts",".sql",".properties"
    )

    $ext = [System.IO.Path]::GetExtension($Path).ToLower()

    if ($textExtensions -contains $ext) {
        return $false
    }

    $fs = [System.IO.File]::OpenRead($Path)

    try {
        $buffer = [byte[]]::new(4096)
        $read = $fs.Read($buffer, 0, $buffer.Length)
    }
    finally {
        $fs.Dispose()
    }

    if ($read -eq 0) {
        return $false
    }

    if ($read -lt $buffer.Length) {
        $buffer = $buffer[0..($read-1)]
    }

    if ($buffer.Length -ge 2) {
        if (($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or
            ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF)) {
            return $false
        }
    }

    return ([Array]::IndexOf($buffer, [byte]0) -ne -1)
}
