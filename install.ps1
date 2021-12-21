#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2020 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
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
#>
[cmdletbinding()]
param(
   [string]$InstallDir="<auto>",
   [string]$Version="latest",
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
				$request = Invoke-WebRequest -Method Head -Uri $Uri
				if ($request.BaseResponse.ResponseUri -ne $null) {
					# This is for Powershell 5
					$redirectUri = $request.BaseResponse.ResponseUri.AbsoluteUri
				}
				elseif ($request.BaseResponse.RequestMessage.RequestUri -ne $null) {
					# This is for Powershell core
					$redirectUri = $request.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
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
		$LatestTag = $(Get-RedirectedUri "https://github.com/metacall/distributable-linux/releases/latest")
		return $LatestTag.substring(1)
	}
	else {
		return $Version
	}
}

function Download-Tarball([string]$InstallDir) {
	$InstallRoot = Resolve-Installation-Path $InstallDir
	$InstallVersion = Resolve-Version $Version

	# TODO
}




# TODO: python -m pip install --upgrade --force-reinstall pip
# TODO: Replace in the files D:/ and D:\
