<div align="center">
  <a href="https://metacall.io" target="_blank"><img src="https://raw.githubusercontent.com/metacall/core/develop/deploy/images/logo.png" alt="METACALL" style="max-width:100%; margin: 0 auto;" width="80" height="80">
  <p><b>MetaCall Polyglot Runtime</b></p></a>
</div>

# Abstract

Cross-platform set of scripts to install MetaCall Core infrastructure. For advanced install information, [check the documentation](https://github.com/metacall/core/blob/develop/docs/README.md#41-installation).

# Install

The following scripts are provided in order to install MetaCall:
- [install.sh](https://raw.githubusercontent.com/metacall/install/master/install.sh) `bash or zsh | Linux or MacOS`

- [install.ps1](https://raw.githubusercontent.com/metacall/install/master/install.ps1) `PowerShell | Windows`

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
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/metacall/install/master/install.ps1')))"
  ```

## Install Linux or MacOS

Additional parameters for the install script:

- `--update`: Updates automatically MetaCall if it is already installed without asking to the user.
- `--uninstall`: Uninstalls MetaCall if it is already installed without asking to the user. Overwrites the update command.
- `--docker-install`: Runs Docker installation overwriting Docker fallback option over binary installation.
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

- Install `metacall` in a BusyBox without certificates:
  ```sh
  wget --no-check-certificate -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --no-check-certificate
  ```

## Install Windows

Additional parameters for the install script:

- `-InstallDir <directory>`: Defines a custom folder in order to install MetaCall in, otherwise it uses `%LocalAppData%\MetaCall` by default.
- `-Version <version>`: Version of the tarball to be downloaded. Versions are available [here](https://github.com/metacall/distributable-windows/releases). Uses latest version by default.
- `-FromPath <path>`: Install MetaCall from an existing distributable tarball, path must point to a tarball downloaded from [releases](https://github.com/metacall/distributable-windows/releases).

Example usage:

- Install tarball version `v0.1.0` into `D:\metacall`:
  ```powershell
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/metacall/install/master/install.ps1'))) -InstallDir 'D:\metacall' -Version '0.1.0'"
  ```

# Testing

### In linux or mac:
1. Docker must be installed
2. Clone the repo
3. cd install and enter the command
```sh
./test.sh   # To be used for cli and Linux/Mac
```

### In Windows:
1. Clone the repo
2. cd install and enter the command
```sh
./install.ps1 # To be used in powershell 
```

# Troubleshooting
Sometimes the domain _raw.githubusercontent.com_ maybe blocked by your ISP. Due to this, you may not be able to install metacall directly from previous commands. In that case, you may clone this repo and directly run [install.sh](https://github.com/metacall/install/blob/master/install.sh) for Linux and run [install.ps1](https://github.com/metacall/install/blob/master/install.ps1) for Windows.
