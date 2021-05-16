# Synchronize Time

echo "Syncing time with NTP servers..."

$update_time_provider = w32tm /config /syncfromflags:manual /manualpeerlist:"192.168.1.67" /update

$sync = w32tm /resync /force

if($sync -like "*did not resync*")
{
    echo $sync
    echo "`nFAILED"
}
else
{
    echo "`nSUCCESS`n"
    w32tm /query /status
}
