function Get-RelativePath {
    param(
        [Parameter(Mandatory)] [string]$FullPath,
        [Parameter(Mandatory)] [string]$BasePath
    )

    # Normaliser les chemins
    $basePathNorm = $BasePath.TrimEnd([IO.Path]::DirectorySeparatorChar)
    $fullPathNorm = $FullPath.TrimEnd([IO.Path]::DirectorySeparatorChar)

    # Vérification et extraction du chemin relatif
    if ($fullPathNorm.StartsWith($basePathNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPathNorm.Substring($basePathNorm.Length).TrimStart([IO.Path]::DirectorySeparatorChar)
    } else {
        throw "FullPath is not under BasePath"
    }
}
