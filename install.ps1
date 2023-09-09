# . { iwr -useb https://raw.github.com/twork22/cs/main/install.ps1 } | iex
Function Set-MouseSpeed {
    [CmdletBinding()]
    param (
        [validateRange(1, 20)]
        [int] $Value
    )

    $winApi = add-type -name user32 -namespace tq84 -passThru -memberDefinition '
   [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(
       uint uiAction,
       uint uiParam ,
       uint pvParam ,
       uint fWinIni
    );
'

    $SPI_SETMOUSESPEED = 0x0071
    $MouseSpeedRegPath = 'hkcu:\Control Panel\Mouse'
    Write-Verbose "MouseSensitivity before WinAPI call:  $((get-itemProperty $MouseSpeedRegPath).MouseSensitivity)"

    $null = $winApi::SystemParametersInfo($SPI_SETMOUSESPEED, 0, $Value, 0)

    #
    #    Calling SystemParametersInfo() does not permanently store the modification
    #    of the mouse speed. It needs to be changed in the registry as well
    #

    set-itemProperty $MouseSpeedRegPath -name MouseSensitivity -value $Value

    Write-Verbose   "MouseSensitivity after WinAPI call:  $((get-itemProperty $MouseSpeedRegPath).MouseSensitivity)"

    Write-Verbose "Disabling MouseAccel (MouseSpeed / 'Enhance Pointer Precision')"
    $code=@'
		[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
		 public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, int[] pvParam, uint fWinIni);
'@
	Add-Type $code -name Win32 -NameSpace System;
	[System.Win32]::SystemParametersInfo(4,0,0,2);
}
Set-MouseSpeed -Value 20 -Verbose

$onlinePath = "https://raw.github.com/twork22/cs/main/"
Function Get-Folder($where = "") {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null;

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog;
    $foldername.Description = $where;
    $foldername.rootfolder = "MyComputer";
    $foldername.SelectedPath = "";
	$foldername.ShowNewFolderButton = $false;

    if ($foldername.ShowDialog() -eq "OK") {
        $folder += $foldername.SelectedPath;
		return $folder;
    }

	return $null;
}
Function Check-Existence($location = "") {
	if (-Not($location)) {
		Write-Host "Invalid location to check.";
		return 1;
	}

	$exist = Test-Path $location;
	Write-Host "[Existence][$exist] $location";
	return $exist;
}
Function Download($filename = "", $dest = "", $customFileName = "") {
	if (-Not($dest)) {
		Write-Host "Destination is not supplied.";
		return
	}
	if (-Not($filename)) {
		Write-Host "File name is not supplied.";
		return
	}

	$path = "$onlinePath"
	$path += $filename;

	$outFileName = $customFileName;
	if (-Not($outFileName)) {
		$outFileName = $filename;
	}
	Invoke-Webrequest -URI $path -UseBasicParsing -OutFile "$dest/$outFileName" -Headers @{"Cache-Control"="no-cache"};
}

# Global: CSGO Directory
$csgoDir = Get-Folder "Select CSGO Root Folder`n`ne.g. %steamapps%/common/Counter-Strike Global Offensive";

# Autoexec
Function InstallAutoexec() {
	Write-Host "`nInstalling Autoexec.";
	if (-Not($csgoDir)) {
		Write-Host "CSGO Dir not present. Skipping...";
		return 1;
	}

	$localAutoexec = "$PSScriptRoot/autoexec.cfg";
	$isLocalAutoexecPresent = Check-Existence $localAutoexec;

	$autoexecPath = "$csgodir/csgo/cfg";
	$isAutoexecDirPresent = Check-Existence $autoexecPath;
	if (-Not($isAutoexecDirPresent)) {
		Write-Host "CSGO cfg dir test failed. Skipping...";
		return 2;
	}

	if ($isLocalAutoexecPresent) {
		Copy-Item $localAutoexec -Destination $autoexecPath;
	} else {
		Write-Host "Downloading autoexec.cfg";
		Download "autoexec.cfg" $autoexecPath;
	}

	# Fail-safe for user config
	$localConfPresent = "$PSScriptRoot/config.cfg";
	$isLocalConfPresent = Check-Existence $localConfPresent;
	if ($isLocalConfPresent) {
		Copy-Item $localConfPresent -Destination $autoexecPath;
	} else {
		Write-Host "Downloading config.cfg -> $autoexecPath/ducki.cfg";
		Download "config.cfg" $autoexecPath "ducki.cfg";
	}

	if (Check-Existence "$autoexecPath/autoexec.cfg") {
		return 0;
	} else {
		return 3;
	}
}
$rtAutoExec = $null;
$rtAutoExec = InstallAutoexec;

# Colormod
Function InstallColormod() {
	Write-Host "`nInstalling Colormod.";
	if (-Not($csgoDir)) {
		Write-Host "CSGO Dir not present. Skipping...";
		return 1;
	}

	$localColormod = "$PSScriptRoot/csgo_colormod.txt";
	$isLocalColormodPresent = Check-Existence $localColormod;

	$resourcePath = "$csgodir/csgo/resource";
	$isResourceDirPresent = Check-Existence $resourcePath;
	if (-Not($isResourceDirPresent)) {
		Write-Host "CSGO resource dir test failed. Skipping...";
		return 2;
	}

	if ($isLocalColormodPresent) {
		Copy-Item $localColormod -Destination $resourcePath;
	} else {
		Write-Host "Downloading cscolormod.txt";
		Download "csgo_colormod.txt" $resourcePath;
	}

	if (Check-Existence "$resourcePath/csgo_colormod.txt") {
		return 0;
	} else {
		return 3;
	}
}
$rtColormod = $null;
$rtColormod = InstallColormod;

# Simple Radar
Function InstallSimpleRadar () {
	Write-Host "`nInstalling SimpleRadar.";
	if (-Not($csgoDir)) {
		Write-Host "CSGO Dir not present. Skipping...";
		return 1;
	}

	$overviewsPath = "$csgodir/csgo/resource/overviews";
	$isResourceDirPresent = Check-Existence $overviewsPath;
	if (-Not($isResourceDirPresent)) {
		Write-Host "CSGO resource/overviews dir test failed. Skipping...";
		return 2;
	}

	$overviewsBakPath = "$csgodir/csgo/resource/overviews_bak.zip";
	$isOverviewsBackupPresent = Check-Existence $overviewsBakPath;
	if (-Not($isOverviewsBackupPresent)) {
		Write-Host "Backup-ing resource/overviews...";
		Compress-Archive -Path $overviewsPath -DestinationPath $overviewsBakPath;
	} else {
		Write-Host "CSGO resource/overviews backup present.";
	}

	$localSRZip = "$PSScriptRoot/SimpleRadarConfigured.zip";
	$isLocalSRPresent = Check-Existence $localSRZip;

	if ($isLocalSRPresent) {
		Write-Host "Unzipping SimpleRadarConfigured.zip...";
		Expand-Archive $localSRZip -DestinationPath $overviewsPath -Force;
	} else {
		Write-Host "Downloading SimpleRadarConfigured.zip...";
		Download "SimpleRadarConfigured.zip" $env:temp;
		Expand-Archive "$env:temp/SimpleRadarConfigured.zip" -DestinationPath $overviewsPath -Force;
	}

	return 0;
}
$rtSimpleRadar = $null;
$rtSimpleRadar = InstallSimpleRadar;

# UserConfig
Function InstallUserCfg() {
	Write-Host "`nInstalling User Config.";

	$localUserCfg = "$PSScriptRoot/config.cfg";
	$isLocalUserCfgPresent = Check-Existence $localUserCfg;

	$loggedInUser = Get-ItemPropertyValue -Path "HKCU:\Software\valve\Steam\ActiveProcess" -Name "ActiveUser";
	if ($loggedInUser) {
		Write-Host "Logged In UID: $loggedInUser";
	} else {
		Write-Host "[STEAM] No active user present.";
		return 1;
	}

	$steamPath = Get-Folder "Select STEAM Root Folder`n`ne.g. %Programfilesx86%/Steam";
	$userCfgDir = "$steamPath/userdata/$loggedInUser/730/local/cfg";
	if (-Not(Check-Existence $userCfgDir)) {
		Write-Host "[User Cfg Path] Attempt to create user cfg path";
		New-Item $userCfgDir -ItemType Directory -Force;
	}

	if ($isLocalUserCfgPresent) {
		Copy-Item $localUserCfg -Destination $userCfgDir;
	} else {
		Write-Host "Downloading config.cfg";
		Download "config.cfg" $userCfgDir;
	}

	if (Check-Existence "$userCfgDir/config.cfg") {
		return 0;
	} else {
		return 2;
	}
}
$rtUserCfg = $null;
$rtUserCfg = InstallUserCfg;

# Overview
$overviewTable = @(
	[pscustomobject]@{Module="Autoexec";ExitCode="$rtAutoExec"},
	# [pscustomobject]@{Module="ColorMod";ExitCode="$rtColormod"},
	# [pscustomobject]@{Module="SimpleRadar";ExitCode="$rtSimpleRadar"},
	[pscustomobject]@{Module="UserConfig";ExitCode="$rtUserCfg"}
);

$overviewTable | Format-Table;
