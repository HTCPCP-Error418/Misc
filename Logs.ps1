<#
    This script is designed to monitor the health of a Windows 10 box, hopefully catching any signs of imminent failure prior
    to losing information.
#>

#Variables (change to customize script to environment)
$LogDir = ""                #directory to save logs
$Err_Thresh = 10                                      #number of "Error" events before alerting
$Warn_Thresh = 25                                     #number of "Warning" events before alerting

######## Housekeeping stuff ########
#check for log directory, create if non-existant
If (!(Test-Path -Path $LogDir)) {
    New-Item -ItemType directory | Out-Null
}

#function for handling of possible indicators
Function Raise-Error {
    param ($Indicator)
    
    #raise warning popup
    [System.Windows.MessageBox]::Show("ERRORS DETECTED.`nPlease provide $LogDir\FOR_ADMIN.zip to administrator",'Anomaly Detected','OK','Error')

    #write section to check (to help admin)
    Write-Output $Indicator | Out-File -FilePath "$LogDir\INDICATOR.txt"

    #compress log directory for easier transport
    Compress-Archive -Path $LogDir -CompressionLevel Fastest -DestinationPath "$LogDir\FOR_ADMIN"
}


######## Check Event Logs ########

#create variable to only check logs created in last 24 hours
$yesterday = (Get-Date).AddHours(-24)

#get all Application and System logs at level "Error"
$LogError = Get-WinEvent -FilterHashtable @{LogName='Application','System'; Level=2; StartTime=$yesterday} -ErrorAction SilentlyContinue | Select-Object TimeCreated,LogName,ProviderName,Id,LevelDisplayName,Message

#get all Application and System logs at level "Warning"
$LogWarn = Get-WinEvent -FilterHashtable @{LogName='Application','System'; Level=3; StartTime=$yesterday} -ErrorAction SilentlyContinue | Select-Object TimeCreated,LogName,ProviderName,Id,LevelDisplayName,Message

#output to file
$LogError | Sort TimeCreated | Out-File -FilePath "$LogDir\error.log"
$LogWarn | Sort TimeCreated | Out-File -FilePath "$LogDir\warn.log"

#count entries in logfiles and store to variables
$ErrCount = (Get-Content "$LogDir\error.log" | Select-String -Pattern "TimeCreated").length
$WarnCount = (Get-Content "$LogDir\warn.log" | Select-String -Pattern "TimeCreated").length



######## System File Checker ########

#run 

#check for errors



######## Check Disk ########

#run CHKDSK and output results to log directory
CHKDSK /scan | Out-File -FilePath "$LogDir\chkdsk.log"

#check for errors



######## Check Backups ########

#



######## DEBUG ########
#Write-Output $ErrCount
#Write-Output $WarnCount




######## Create Popup On Anomalies ########

#TEST THESE

If ($ErrCount -ge 10) {
    Raise-Error -Indicator "Event Logs - Errors"
} ElseIf ($WarnCount -ge 25) {
    Raise-Error -Indicator "Event Logs - Warnings"
}



