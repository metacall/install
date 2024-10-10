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

function Get-Machine-Architecture() {
	# On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
	# To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
	# PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
	# Possible values: amd64, x64, x86, arm64, arm

	if( $ENV:PROCESSOR_ARCHITEW6432 -ne $null )
	{
		return $ENV:PROCESSOR_ARCHITEW6432
	}

	return $ENV:PROCESSOR_ARCHITECTURE
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
				$request = Invoke-WebRequest -UseBasicParsing -Method Head -Uri $Uri
				if ($request.BaseResponse.ResponseUri -ne $null) {
					# This is for Powershell 5
					$redirectUri = $request.BaseResponse.ResponseUri
				}
				elseif ($request.BaseResponse.RequestMessage.RequestUri -ne $null) {
					# This is for Powershell core
					$redirectUri = $request.BaseResponse.RequestMessage.RequestUri
				}

				$retry = $false
			}
			catch {
				if (($_.Exception.GetType() -match "HttpResponseException") -and ($_.Exception -match "302")) {
					$Uri = $_.Exception.Response.Headers.Location.AbsoluteUri
					$retry = $true
				}
				else {
					throw $_
				}
			}
		} while ($retry)

		$redirectUri
	}
}

function Resolve-Version([string]$Version) {
	if ($Version.ToLowerInvariant() -eq "latest") {
		$LatestTag = $(Get-RedirectedUri "https://github.com/metacall/distributable-windows/releases/latest")
		return $LatestTag.Segments[$LatestTag.Segments.Count - 1]
	}
	else {
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
$($InstallLocation)\runtimes\python\python.exe -m pip install --upgrade --force-reinstall pip
endlocal
"@
	# PIP_TARGET here might be incorrect here, for more info check https://github.com/metacall/distributable-windows/pull/20
	$InstallPythonScriptOneLine = $($InstallPythonScript.Trim()).replace("`n", " && ")
	cmd /V /C "$InstallPythonScriptOneLine"

	# Install Additional Packages
	Install-MetaCall-AdditionalPackages -Component "deploy"
	Install-MetaCall-AdditionalPackages -Component "faas"

	# TODO: Replace in the files D:/ and D:\
}

function Path-Install([string]$InstallRoot) {
	# Add safely MetaCall command to the PATH (and persist it)

	# To add folder containing metacall.bat to PATH
	$persistedPaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split ';'
	if ($persistedPaths -notcontains $InstallRoot) {
		[Environment]::SetEnvironmentVariable('PATH', $env:PATH+";"+$InstallRoot, [EnvironmentVariableTarget]::User)
	}

	# To verify if PATH isn't already added
	$envPaths = $env:Path -split ';'
	if ($envPaths -notcontains $InstallRoot) {
		$envPaths = $envPaths + $InstallRoot | where { $_ }
		$env:Path = $envPaths -join ';'
	}

	if ($env:GITHUB_ENV -ne $null) {
		echo "PATH=$env:PATH" >> $env:GITHUB_ENV
	}
}

# TODO: Use this for implementing uninstall
function Path-Uninstall([string]$Path) {
	$persistedPaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split ';'
	if ($persistedPaths -contains $Path) {
		$persistedPaths = $persistedPaths | where { $_ -and $_ -ne $Path }
		[Environment]::SetEnvironmentVariable('PATH', $persistedPaths -join ';', [EnvironmentVariableTarget]::User)
	}

	$envPaths = $env:Path -split ';'
	if ($envPaths -contains $Path) {
		$envPaths = $envPaths | where { $_ -and $_ -ne $Path }
		$env:Path = $envPaths -join ';'
	}
}

function Install-Tarball([string]$InstallDir, [string]$Version) {
	$InstallRoot = Resolve-Installation-Path $InstallDir
	$InstallOutput = Join-Path -Path $InstallRoot -ChildPath "metacall-tarball-win.zip"
        # Delete directory contents if any
        if (Test-Path $InstallRoot) {
           Remove-Item -Recurse -Force $InstallRoot | Out-Null
        }

        # Create directory if it does not exist
        New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
	
        if (!$FromPath) { 
           $InstallVersion = Resolve-Version $Version
           $InstallArchitecture = Get-CLI-Architecture
           $DownloadUri = "https://github.com/metacall/distributable-windows/releases/download/$InstallVersion/metacall-tarball-win-$InstallArchitecture.zip"

           # Download the tarball
           Invoke-WebRequest -Uri $DownloadUri -OutFile $InstallOutput
	} else {
           # Copy the tarball from the path
           Copy-Item -Path $FromPath -Destination $InstallOutput
	}

	# Unzip the tarball
	Expand-Archive -Path $InstallOutput -DestinationPath $InstallRoot -Force

	# Delete the tarball
	Remove-Item -Force $InstallOutput | Out-Null

	# Run post install scripts
	Post-Install $InstallRoot

	# Add MetaCall CLI to PATH
	Path-Install $InstallRoot
}

function Set-NodePath {
	param (
		[string]$FilePath
	)
	$NodePath = "`"$env:LocalAppData\MetaCall\metacall\runtimes\nodejs\node.exe`""
	if (-not (Test-Path $FilePath)) {
		Write-Error "The file $FilePath does not exist."
		return
	}
	$content = Get-Content -Path "$FilePath"
	$content = $content -replace '%dp0%\\node.exe', "$NodePath"
	$content = $content -replace '""', '"'
	Set-Content -Path "$FilePath" -Value "$content"
}

function Install-MetaCall-AdditionalPackages {
	param (
		[string]$Component
	)
	$InstallRoot = Resolve-Installation-Path "$InstallDir"
	$InstallDir = Join-Path -Path "$InstallRoot" -ChildPath "deps\$Component"

	if (-not (Test-Path $InstallDir)) {
		New-Item -ItemType Directory -Force -Path "$InstallDir" | Out-Null
	}

	Write-Host "MetaCall $($Component) Installation"
	Invoke-Expression "npm install --global --prefix=`"$InstallDir`" @metacall/$Component"
	Set-NodePath "$InstallDir\metacall-$Component.cmd"
	Write-Host "MetaCall $Component has been installed."
}

# Install the tarball and post scripts
Install-Tarball $InstallDir $Version
