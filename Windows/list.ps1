foreach ($Key in Get-ChildItem Microsoft.PowerShell.Core\Registry::HKEY_CLASSES_ROOT) {
    $Path = $Key.PSPath + '\shell\open\command'
    $HasURLProtocol = $Key.Property -contains 'URL Protocol'

    if (($HasURLProtocol) -and (Test-Path $Path))
    {
        $CommandKey = Get-Item $Path
        $Scheme = $Key.Name.SubString($Key.Name.IndexOf('\') + 1) + ':'
        Write-Host $Scheme $CommandKey.GetValue('')
    }
}
