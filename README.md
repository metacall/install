<div align="center">
  <a href="https://metacall.io" target="_blank">
    <img src="https://raw.githubusercontent.com/metacall/core/develop/deploy/images/logo.png" alt="METACALL" width="80" height="80" style="max-width:100%;" />
    <p><strong>MetaCall Polyglot Runtime</strong></p>
  </a>
</div>


## 🚀 Introduction

MetaCall is a polyglot runtime that lets you call functions across multiple languages as if they were native. This README covers the one-line installer scripts and how to customize your installation.

**Quick Links:**

* [Official Docs](https://github.com/metacall/core/blob/develop/docs/README.md#41-installation)
* [Releases (Linux)](https://github.com/metacall/distributable-linux/releases)
* [Releases (macOS)](https://github.com/metacall/distributable-macos/releases)
* [Releases (Windows)](https://github.com/metacall/distributable-windows/releases)

---

## ⚙️ Prerequisites

* **curl** or **wget** (for Linux/macOS)
* **PowerShell** v5+ (for Windows)
* Internet access (unless installing from a local tarball)

---

## 🎯 Quick Install

> **One-line installer:**

* **Linux / macOS** (bash/zsh):

  > **curl**
  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh
  ```

  > **wget**
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh
  ```

* **Windows** (PowerShell):

  ```powershell
  powershell -NoProfile -ExecutionPolicy Unrestricted -Command \
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/metacall/install/master/install.ps1')))"
  ```

*By default, these scripts fetch the latest release.*

---

## 🛠️ Advanced Install Options

### Linux / macOS

| Flag                     | Description                                               |
| ------------------------ | --------------------------------------------------------- |
| `--update`               | Update existing MetaCall installation without prompts.    |
| `--uninstall`            | Uninstall MetaCall (overrides `--update`).                |
| `--docker-install`       | Force Docker-based install instead of binary.             |
| `--no-check-certificate` | Skip SSL cert checks when downloading tarball (insecure). |
| `--no-docker-fallback`   | Disable Docker fallback if binary install fails.          |
| `--from-path <path>`     | Install from a local tarball (`<path>` to `.tar.gz`).     |
| `--version <version>`    | Install a specific version (e.g. `0.2.0`). [1]            |
| `--debug`                | Install with debug symbols and sanitizers if possible.    |

[1]: The list of versions are available here: [Linux](https://github.com/metacall/distributable-linux/releases), [MacOS](https://github.com/metacall/distributable-macos/releases).

**Examples:**

- Update in-place without prompts with `curl`:

  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --update
  ```

- Uninstall with `wget`:

  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --uninstall
  ```

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

- Install with `wget` with the fixed version `v0.2.0` of Linux Distributable:
  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --version 0.2.0
  ```

- Install `metacall` in a BusyBox without certificates:
  ```sh
  wget --no-check-certificate -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --no-check-certificate
  ```

### Windows

| Parameter                 | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `-InstallDir <directory>` | Custom install folder (default: `%LocalAppData%\MetaCall`).  |
| `-Version <version>`      | Specific release version to install (default: latest). [1]   |
| `-FromPath <path>`        | Path to a local distributable tarball (`.zip` or `.tar.gz`). |

[1]: The list of versions are available [here](https://github.com/metacall/distributable-windows/releases).

**Example:**

- Install tarball version `v0.1.0` into `D:\MetaCall`:
  ```powershell
  powershell -NoProfile -ExecutionPolicy unrestricted -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/metacall/install/master/install.ps1'))) -InstallDir 'D:\MetaCall' -Version '0.1.0'"
  ```

---

## 💻 Development & Testing

### Linux / MacOS

Requires docker to be installed.

```sh
git clone https://github.com/metacall/install.git metacall-install
cd metacall-install
./test.sh
```

### Windows

Windows does not include a test script yet, but you can use `install.ps1` script for testing yourself on your computer.

```sh
git clone https://github.com/metacall/install.git metacall-install
cd metacall-install
powershell -NoProfile -ExecutionPolicy unrestricted ./install.ps1
```

## 🛠️ Troubleshooting

Sometimes the domain _raw.githubusercontent.com_ maybe blocked by your ISP. Due to this, you may not be able to install metacall directly from previous commands. In that case, you may clone this repo and directly run [install.sh](https://github.com/metacall/install/blob/master/install.sh) for Linux and run [install.ps1](https://github.com/metacall/install/blob/master/install.ps1) for Windows.
