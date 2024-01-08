
$ConnectionName = "XYZ9"
$ServerAddress = "egx.xyz9.net"

Get-VpnConnection


Remove-VpnConnection  -Name $ConnectionName

Add-VpnConnection -Name $ConnectionName `
 -ServerAddress $ServerAddress `
 -TunnelType "Ikev2" `
 -AuthenticationMethod

Set-VpnConnectionIPsecConfiguration -ConnectionName $ConnectionName `
 -AuthenticationTransformConstants SHA256128 `
 -CipherTransformConstants AES256 `
 -EncryptionMethod AES256 `
 -IntegrityCheckMethod SHA256 `
 -DHGroup Group2 `
 -PfsGroup None