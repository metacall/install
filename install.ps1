#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2024 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

<#
.SYNOPSIS
	Installs MetaCall CLI
.DESCRIPTION
	MetaCall is a extensible, embeddable and interoperable cross-platform polyglot runtime. It supports NodeJS, Vanilla JavaScript, TypeScript, Python, Ruby, C#, Java, WASM, Go, C, C++, Rust, D, Cobol and more.
.PARAMETER Version
	Default: latest
	Version of the tarball to be downloaded. Versions are available here: https://github.com/metacall/distributable-windows/releases.
	Possible values are:
	- latest - most latest build
	- 3-part version in a format A.B.C - represents specific version of build
			examples: 0.2.0, 0.1.0, 0.0.22
.PARAMETER InstallDir
	Default: %LocalAppData%\MetaCall
	Path to where to install MetaCall. Note that binaries will be placed directly in a given directory.
.PARAMETER FromPath
	Default: $null
	Path to the tarball to be installed. If specified, this parameter will override the Version parameter.
#>

[cmdletbinding()]
param(
	[string]$InstallDir="<auto>",
	[string]$Version="latest",
	[string]$FromPath=$null
)

Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
$ProgressPreference="SilentlyContinue"

function Print-With-Fallback([string]$Message) {
	try {
		Write-Host "$Message"
	} catch {
		Write-Output "$Message"
	}
}

function Print-Title([string]$Message) {
	Print-With-Fallback "$Message`n"
}

function Print-Info([string]$Message) {
	Print-With-Fallback "$([char]0x25B7) $Message"
}

function Print-Success([string]$Message) {
	Print-With-Fallback "$([char]0x2714) $Message"
}

function Print-Warning([string]$Message) {
	Print-With-Fallback "$([char]0x26A0) $Message"
}

function Print-Error([string]$Message) {
	Print-With-Fallback "$([char]0x2718) $Message"
}

function Print-Debug([string]$Message) {
	if ($env:METACALL_INSTALL_DEBUG) {
		Print-With-Fallback "$([char]0x2699) $Message"
	}
}

function Get-Machine-Architecture() {
	# On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
	# To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
	# PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
	# Possible values: amd64, x64, x86, arm64, arm

	if( $env:PROCESSOR_ARCHITEW6432 -ne $null )
	{
		return $env:PROCESSOR_ARCHITEW6432
	}

	return $env:PROCESSOR_ARCHITECTURE
}

function Get-CLI-Architecture() {
	$Architecture = $(Get-Machine-Architecture)
	switch ($Architecture.ToLowerInvariant()) {
		{ ($_ -eq "amd64") -or ($_ -eq "x64") } { return "x64" }
		# TODO:
		# { $_ -eq "x86" } { return "x86" }
		# { $_ -eq "arm" } { return "arm" }
		# { $_ -eq "arm64" } { return "arm64" }
		default { throw "Architecture '$Architecture' not supported. If you are interested in this platform feel free to contribute to https://github.com/metacall/distributable-windows" }
	}
}

function Get-User-Share-Path() {
	$InstallRoot = $env:METACALL_INSTALL_DIR
	if (!$InstallRoot) {
		$InstallRoot = "$env:LocalAppData\MetaCall"
	}
	return $InstallRoot
}

function Resolve-Installation-Path([string]$InstallDir) {
	if ($InstallDir -eq "<auto>") {
		return Get-User-Share-Path
	}
	return $InstallDir
}

function Get-RedirectedUri {
	<#
	.SYNOPSIS
		Gets the real download URL from the redirection.
	.DESCRIPTION
		Used to get the real URL for downloading a file, this will not work if downloading the file directly.
	.EXAMPLE
		Get-RedirectedURL -URL "https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US"
	.PARAMETER URL
		URL for the redirected URL to be un-obfuscated
	.NOTES
		Code from: Redone per issue #2896 in core https://github.com/PowerShell/PowerShell/issues/2896
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$Uri
	)
	process {
		do {
			try {
				$Request = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $Uri
				if ($Request.BaseResponse.ResponseUri -ne $null) {
					# This is for Powershell 5
					$RedirectUri = $Request.BaseResponse.ResponseUri
				}
				elseif ($Request.BaseResponse.RequestMessage.RequestUri -ne $null) {
					# This is for Powershell core
					$RedirectUri = $Request.BaseResponse.RequestMessage.RequestUri
				}

				$Retry = $false
			}
			catch {
				if (($_.Exception.GetType() -match "HttpResponseException") -and ($_.Exception -match "302")) {
					$Uri = $_.Exception.Response.Headers.Location.AbsoluteUri
					$Retry = $true
				}
				else {
					throw $_
				}
			}
		} while ($Retry)

		$RedirectUri
	}
}

function Resolve-Version([string]$Version) {
	if ($Version.ToLowerInvariant() -eq "latest") {
		$LatestTag = $(Get-RedirectedUri "https://github.com/metacall/distributable-windows/releases/latest")
		return $LatestTag.Segments[$LatestTag.Segments.Count - 1]
	} else {
		return "v$Version"
	}
}

function Post-Install([string]$InstallRoot) {
	# Reinstall Python Pip to the latest version (needed in order to patch the python.exe location)
	$InstallLocation = Join-Path -Path $InstallRoot -ChildPath "metacall"
	$InstallPythonScript = @"
setlocal
set "PYTHONHOME=$($InstallLocation)\runtimes\python"
set "PIP_TARGET=$($InstallLocation)\runtimes\python\Pip"
set "PATH=$($InstallLocation)\runtimes\python;$($InstallLocation)\runtimes\python\Scripts"
start "" "$($InstallLocation)\runtimes\python\python.exe" -m pip install --upgrade --force-reinstall pip
endlocal
"@
	# PIP_TARGET here might be incorrect here, for more info check https://github.com/metacall/distributable-windows/pull/20
	$InstallPythonScriptOneLine = $($InstallPythonScript.Trim()).replace("`n", " && ")
	cmd /V /C "$InstallPythonScriptOneLine"

	# Install Additional Packages
	Install-Additional-Packages -InstallRoot $InstallRoot -Component "deploy"
	Install-Additional-Packages -InstallRoot $InstallRoot -Component "faas"

	# TODO: Replace in the files D:/ and D:\
}

function Path-Install([string]$InstallRoot) {
	# Add safely MetaCall command to the PATH (and persist it)

	# To add folder containing metacall.bat to PATH
	$PersistedPaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split ';'
	if ($PersistedPaths -notcontains $InstallRoot) {
		[Environment]::SetEnvironmentVariable('PATH', $env:PATH+";"+$InstallRoot, [EnvironmentVariableTarget]::User)
	}

	# To verify if PATH isn't already added
	$EnvPaths = $env:PATH -split ';'
	if ($EnvPaths -notcontains $InstallRoot) {
		$EnvPaths = $EnvPaths + $InstallRoot | where { $_ }
		$env:Path = $EnvPaths -join ';'
	}

	# Support for GitHub actions environment
	if ($env:GITHUB_ENV -ne $null) {
		echo "PATH=$env:PATH" >> $env:GITHUB_ENV
	}
}

# TODO: Use this for implementing uninstall
function Path-Uninstall([string]$Path) {
	$PersistedPaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split ';'
	if ($PersistedPaths -contains $Path) {
		$PersistedPaths = $PersistedPaths | where { $_ -and $_ -ne $Path }
		[Environment]::SetEnvironmentVariable('PATH', $PersistedPaths -join ';', [EnvironmentVariableTarget]::User)
	}

	$EnvPaths = $env:PATH -split ';'

	if ($EnvPaths -contains $Path) {
		$EnvPaths = $EnvPaths | where { $_ -and $_ -ne $Path }
		$env:Path = $EnvPaths -join ';'
	}
}

function Install-Tarball([string]$InstallDir, [string]$Version) {
	Print-Title "MetaCall Binary Installation."

	$InstallRoot = Resolve-Installation-Path $InstallDir
	$InstallOutput = Join-Path -Path $InstallRoot -ChildPath "metacall-tarball-win.zip"

	# Delete directory contents if any
	if (Test-Path $InstallRoot) {
		Remove-Item -Recurse -Force $InstallRoot | Out-Null
	}

	Print-Debug "Install MetaCall in folder: $InstallRoot"

	# Create directory if it does not exist
	New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
	
	if (!$FromPath) {
		Print-Info "Downloading tarball."

		$InstallVersion = Resolve-Version $Version
		$InstallArchitecture = Get-CLI-Architecture
		$DownloadUri = "https://github.com/metacall/distributable-windows/releases/download/$InstallVersion/metacall-tarball-win-$InstallArchitecture.zip"

		# Download the tarball
		Invoke-WebRequest -Uri $DownloadUri -OutFile $InstallOutput

		Print-Success "Tarball downloaded."
	} else {
		# Copy the tarball from the path
		Copy-Item -Path $FromPath -Destination $InstallOutput
	}

	Print-Info "Uncompressing tarball."

	# Unzip the tarball
	Expand-Archive -Path $InstallOutput -DestinationPath $InstallRoot -Force

	Print-Success "Tarball extracted correctly."

	# Delete the tarball
	Remove-Item -Force $InstallOutput | Out-Null

	Print-Info "Running post-install scripts."

	# Run post install scripts
	Post-Install $InstallRoot

	Print-Info "Adding MetaCall to PATH."

	# Add MetaCall CLI to PATH
	Path-Install $InstallRoot

	Print-Success "MetaCall installed successfully."
}

function Set-NodePath {
	param (
		[string]$NodePath,
		[string]$FilePath
	)

	if (-not (Test-Path "$FilePath")) {
		Print-Error "Failed to set up an additional package, the file $FilePath does not exist."
		return
	}

	$Content = Get-Content -Path $FilePath

	Print-Debug "Replace $FilePath content:`n$Content"

	$Content = $Content -replace '%dp0%\\node.exe', $NodePath
	$Content = $Content -replace '""', '"'

	Print-Debug "With new content:`n$Content"

	Set-Content -Path $FilePath -Value $Content
}

function Install-Additional-Packages {
	param (
		[string]$InstallRoot,
		[string]$Component
	)

	$ComponentDir = Join-Path -Path $InstallRoot -ChildPath "deps\$Component"

	if (-not (Test-Path $ComponentDir)) {
		New-Item -ItemType Directory -Force -Path $ComponentDir | Out-Null
	}

	Print-Info "Installing '$Component' additional package."

	$NodePath = Join-Path -Path $InstallRoot -ChildPath "metacall\runtimes\nodejs\node.exe"
	Invoke-Expression "npm install --global --prefix=`"$ComponentDir`" @metacall/$Component"
	Set-NodePath -NodePath $NodePath -FilePath "$ComponentDir\metacall-$Component.cmd"

	Print-Success "Package '$Component' has been installed."
}

# Install the tarball and post scripts
Install-Tarball $InstallDir $Version
