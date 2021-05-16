# Join ESXi hosts to Active Directory
# Author: Nick Marriotti
# Date: 5/14/2021

# Domain info
$DOMAIN = "home.lab.local"
$DOMAIN_USER = "Administrator"
$DOMAIN_PASS = ''

# vCenter info
$VCENTER_IP = "192.168.1.111"
$VCENTER_USER = "vsphere.local\Administrator"
$VCENTER_PASS = ''

$ErrorActionPreference = 'SilentlyContinue'

Function joinDomain()
{
    param(
        [String[]]$IPAddress
    )

    try
    {
        echo "Attempting to join $IPAddress to the domain."

        # Create new hostname with format: esxi<last_octet>
        $hostname = "esxi$($IPAddress.Split('.')[-1].Trim())"

        # Update hostname and DNS
        Get-VMHostNetwork -VMHost $IPAddress | Set-VMHostNetwork -HostName $hostname -DnsAddress "192.168.1.66", "192.168.1.1" -DomainName "localdomain.localhost" -Confirm:$false | Out-Null
        $auth = Get-VMHostAuthentication -VMHost $IPAddress

        # Check if this host is already joined to Active Directory
        if(($auth.Domain -eq $DOMAIN) -and ($auth.DomainMembershipStatus -eq "Ok"))
        {
            echo "$IPAddress is already joined to domain."
        }
        else
        {
            # Join Active Directory
            $joindomain = Get-VMHostAuthentication -VMHost $IPAddress  | Set-VMHostAuthentication -JoinDomain -Domain $DOMAIN -User $DOMAIN_USER -Password $DOMAIN_PASS -Confirm:$false
            if($joindomain.DomainMembershipStatus -eq "Ok")
            {
                echo "$IPAddress joined the domain."
                Get-AdvancedSetting -Entity $IPAddress -Name "Config.HostAgent.plugins.hostsvc.esxAdminsGroup" | Set-AdvancedSetting -Value "Domain Admins" -Confirm:$false | Out-Null
            }
            else
            {
                throw $error[0].Exception
            }
        }
    }
    catch
    {
        echo $_.Exception.Message
    }

}

# Connect to vCenter
Connect-VIServer -Server $VCENTER_IP -User $VCENTER_USER -Password $VCENTER_PASS -Force | Out-Null

# Gather all ESXi hosts
$esxihosts = Get-VMHost | Select-Object Name

# Loop over every host
foreach($vmhost in $esxihosts)
{
    joinDomain -IPAddress $vmhost.Name
}

Disconnect-VIServer -Confirm:$false -Force