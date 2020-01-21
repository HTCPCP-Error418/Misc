#This script is meant to override the applications pinned to the taskbar by GPOs
#since I don't want some of the items down there.
#
#USAGE:
#	Set-PinnedApplication -Action PinToTaskbar -FilePath "C:\path\to\application"
#	Set-PinnedApplication -Action UnPinFromTaskbar -FilePath "C:\path\to\application"
#	Set-PinnedApplication -Action PinToStartMenu -FilePath "C:\path\to\application"
#	Set-PinnedApplication -Action UnPinFromStartMenu -FilePath "C:\path\to\application"

function Set-PinnedApplication {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$Action,
		[Parameter(Mandatory=$true)][string]$FilePath
	)
	if(-not (test-path $FilePath)) {
		throw "[!]	FilePath: $FilePath does not exist"
	}

	function InvokeVerb {
		param([string]$FilePath,$verb)
		$verb = $verb.Replace("&","")
		$path = Split-Path $FilePath
		$shell = New-Object -com "Shell.Application"
		$folder = $shell.Namespace($path)
		$item = $folder.Parsename((Split-Path $FilePath -Leaf))
		$itemVerb = $item.Verbs() | ? {$_.Name.Replace("&","") -eq $verb}
		if($itemVerb -eq $null) {
			throw "[!]	Verb: $verb not found"
		} else {
			$itemVerb.DoIt()
		}
	}

	function GetVerb {
		param([int]$verbId)
		try {
			$t = [type]"CosmosKey.Util.MuiHelper"
		} catch {
			$def = [Text.StringBuilder]""
			[void]$def.AppendLine('[DllImport("user32.dll")]')
			[void]$def.AppendLine('public static extern int LoadString(IntPtr h, uint id, System.Text.StringBuilder sb, int maxBuffer);')
			[void]$def.AppendLine('[DllImport("kernel32.dll")]')
			[void]$def.AppendLine('public static extern Inptr LoadLibrary(string s);')
			Add-Type -MemberDefinition $def.ToString() -name MuiHelper -Namespace CosmosKey.Util
		}
		if($global:CosmosKey_Utils_MuiHelper_Shell32 -eq $null) {
			$global:CosmosKey_Utils_MuiHelper_Shell32 = [CosmosKey.Util.MuiHelper]::LoadLibrary("shell32.dll")
		}
		$maxVerbLength = 255
		$verbBuilder = New-Object Text.StringBuilder "", $maxVerbLength
		[void][CosmosKey.Util.MuiHelper]::LoadString($CosmosKey_Utils_MuiHelper_Shell32,$verbId,$verbBuilder,$maxVerbLength)
		return $verbBuilder.ToString()
	}

	$verbs = @{
		"PinToStartMenu" = 5381
		"UnpinFromStartMenu" = 5382
		"PinToTaskbar" = 5386
		"UnPinFromTaskbar" = 5387
	}

	if($verbs.$Action -eq $null) {
		throw "[!]	Action: $Action not supported.`nSupported Actions:`n`tPinToStartMenu`n`tUnPinFromStartMenu`n`tPinToTaskbar`n`tUnPinFromTaskbar"
	}
	InvokeVerb -FilePath $FilePath -verb $(GetVerb -verbId $verbs.$Action)
}

Export-ModuleMember Set-PinnedApplication