# Create Shared Folder

if(-Not (Get-Item -Path C:\Share -ErrorAction SilentlyContinue))
{
    New-Item -Path C:\Share -ItemType directory | Out-Null
}

if(-Not (Get-SmbShare -Name Share))
{
    New-SmbShare -Name Share -Path C:\Share
}

Revoke-SmbShareAccess -Name Share -AccountName Everyone -Confirm:$false | Out-Null
Grant-SmbShareAccess -Name Share -AccountName "HOME\Domain Admins" -AccessRight Full -Confirm:$false | Out-Null

echo "C:\Share is now being shared"