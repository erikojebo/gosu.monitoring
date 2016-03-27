$CounterName = 'gosu_logman'
$LogsDirectory = 'c:\temp\logs\gosu_logman\'
$LogFilnamePrefix = 'log'
$LogsArchiveDirectory = 'c:\temp\logs\gosu_logman\archive\'
$CounterConfigPath = 'c:\code\gosu.monitoring\windows\powershell\counters.config'
$SampleIntervalInSeconds = 10
$RunForTimeSpan = '00:01:00'

Write-Output (Get-Date -format "yyyy-MM-dd HH:mm:ss") + ": Script starting..."

$IsCounterInstalled = (logman query) -match $CounterName

if (-not $IsCounterInstalled)
{
	Write-Output "Creating $CounterName..."
	logman create counter $CounterName -si $SampleIntervalInSeconds -f csv -rf $RunForTimeSpan -v mmddhhmm -o (Join-Path $LogsDirectory $LogFilnamePrefix) -cf $CounterConfigPath
}

$IsCounterRunning = (logman query $CounterName) -match 'status:\s*running'

if ($IsCounterRunning)
{
	Write-Output "Stopping $CounterName..."
	logman stop $CounterName
	
	Start-Sleep 1
}

# Move log files to the archive directory
if (-not [string]::IsNullOrWhiteSpace($LogsArchiveDirectory))
{
	$LogsArchiveDirectoryExists = Test-Path $LogsArchiveDirectory
	
	if (-not $LogsArchiveDirectoryExists)
	{
		Write-Output "Creating logs archive directory..."
		New-Item -type directory $LogsArchiveDirectory
	}
	
	# Append seconds to the log files to make sure there is no risk of reusing the file names if the
	# counter is stoppend and started during the same minute.
	# The logman versioning does not seem to support seconds in the versioning suffix
	Get-ChildItem $LogsDirectory\*.csv | Rename-Item -NewName {$_.Name -replace '.csv', ('_' + (Get-Date).ToString("ss") + '.csv')}
	
	Write-Output "Moving log files to $LogsArchiveDirectory..."
	Move-Item $LogsDirectory\*.csv $LogsArchiveDirectory
}

Write-Output "Starting $CounterName..."
logman start $CounterName