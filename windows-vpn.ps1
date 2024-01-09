
$ConnectionName = "XYZ9"
$ServerAddress = "egx.xyz9.net"

<<<<<<< HEAD
Get-VpnConnection


Remove-VpnConnection  -Name $ConnectionName
=======
$Connection = Get-VpnConnection -Name $ConnectionName
if ($Connection.Name) {
    $Connection = Remove-VpnConnection  -Name $ConnectionName
    if ($Connection) {
        Write-Host Could not remove $ConnectionName
        Exit
    }
}
>>>>>>> 82f5978e9118cb57f75ca06c956e8d030c81a75a

Add-VpnConnection -Name $ConnectionName `
 -ServerAddress $ServerAddress `
 -TunnelType 'Ikev2' `
 -AuthenticationMethod MachineCertificate `
 -EncryptionLevel Maximum `
 -DnsSuffix xyz9.net `
 
 

Set-VpnConnectionIPsecConfiguration -ConnectionName $ConnectionName `
 -AuthenticationTransformConstants SHA256128 `
 -CipherTransformConstants AES256 `
 -EncryptionMethod AES256 `
 -IntegrityCheckMethod SHA256 `
 -DHGroup Group2 `
 -PfsGroup PFS2048 
