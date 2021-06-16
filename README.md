<div align="center">
  <a href="https://metacall.io" target="_blank"><img src="https://raw.githubusercontent.com/metacall/core/develop/deploy/images/logo.png" alt="METACALL" style="max-width:100%; margin: 0 auto;" width="80" height="80">
  <p><b>MetaCall Polyglot Runtime</b></p></a>
</div>

# Abstract

Cross-platform set of scripts to install MetaCall Core infrastructure. For advanced install information, [check the documentation](https://github.com/metacall/core/blob/develop/docs/README.md#41-installation).

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
- `powershell` (Not implemented yet):
  ```powershell
  powershell -exec bypass -c "(New-Object Net.WebClient).Proxy.Credentials=[Net.CredentialCache]::DefaultNetworkCredentials;iwr('https://raw.githubusercontent.com/metacall/install/master/install.ps1')|iex"
  ```

# Install Parameters

Additional parameters for the install script:

- `--update`: Updates automatically MetaCall if it is already installed without asking to the user.
- `--uninstall`: Uninstalls MetaCall if it is already installed without asking to the user. Overwrites the update command.
- `--docker-install`: Runs Docker installation overwriting Docker fallback option from binary installation.
- `--no-check-certificate`: When running binary installation (the default one), disables checking certificates when downloading the tarball. Useful for environments where there is not certificates, but insecure.
- `--no-docker-fallback`: When running binary installation (the default one), disables Docker installation as fallback if the binary installation fails.
- `--from-path <path>`: Installs MetaCall from specific path, the `<path>` points to a previously download tarball located in your file system.

Example usage:


- Install with `curl` without checking certificates and without docker fallback:
  ```sh
  curl --insecure -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --no-check-certificate --no-docker-fallback
  ```


- Install with `wget` using Docker installer:
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --docker-install
  ```


- Install with `wget` from a existing tarball located at `/root/downloads/metacall-tarball-linux-amd64.tar.gz`:
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --from-path /root/downloads/metacall-tarball-linux-amd64.tar.gz
  ```
