
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
  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh
  ```
- `wget`:
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh
  ```
- `powershell`:
  ```powershell
  powershell -exec bypass -c "(New-Object Net.WebClient).Proxy.Credentials=[Net.CredentialCache]::DefaultNetworkCredentials;iwr('https://raw.githubusercontent.com/metacall/install/master/install.ps1')|iex"
  ```

# Install Parameters

Additional parameters for the install script:

- `--docker-install`: Runs Docker installation overwriting Docker fallback option from binary installation.
- `--no-check-certificate`: When running binary installation (the default one), disables checking certificates when downloading the tarball. Useful for environments where there is not certificates, but insecure.
- `--no-docker-fallback`: When running binary installation (the default one), disables Docker installation as fallback if the binary installation fails.

Example usage:

- `curl`:
  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --no-check-certificate --no-docker-fallback
  ```
- `wget`:
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --docker-install
  ```
