
<div align="center">
  <a href="https://metacall.io" target="_blank"><img src="https://raw.githubusercontent.com/metacall/core/develop/deploy/images/logo.png" alt="M E T A C A L L" style="max-width:100%;" width="32" height="32">
  <p><b>M E T A C A L L</b></p></a>
  <p>A library for providing inter-language foreign function interface calls</p>
</div>

# Abstract

Cross-platform set of scripts to install MetaCall Core infrastructure.

# Install

The following scripts are provided in order to install MetaCall:
- [install.sh](https://raw.githubusercontent.com/metacall/install/master/install.sh) `bash or zsh | Linux or MacOS`

- [install.ps1](https://raw.githubusercontent.com/metacall/install/master/install.ps1) `PowerShell | Windows` (Not implemented yet)

In order to install MetaCall in one line, curl or wget or powershell can be used:
- `curl`:
  ```bash
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | bash
  ```
- `wget`:
  ```bash
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash
  ```
- `powershell`:
  ```powershell
  powershell -exec bypass -c "(New-Object Net.WebClient).Proxy.Credentials=[Net.CredentialCache]::DefaultNetworkCredentials;iwr('https://raw.githubusercontent.com/metacall/install/master/install.ps1')|iex"
  ```
