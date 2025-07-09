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

  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh
  # or
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
| `--version <version>`    | Install a specific version (e.g. `0.2.0`).                |

**Examples:**

* Update in-place without prompts:

  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --update
  ```

* Install v0.2.0 without Docker fallback:

  ```sh
  wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --version 0.2.0 --no-docker-fallback
  ```

* Install from local tarball:

  ```sh
  curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --from-path /path/to/metacall-linux-amd64.tar.gz
  ```

### Windows

| Parameter                 | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| `-InstallDir <directory>` | Custom install folder (default: `%LocalAppData%\MetaCall`).  |
| `-Version <version>`      | Specific release version to install (default: latest).       |
| `-FromPath <path>`        | Path to a local distributable tarball (`.zip` or `.tar.gz`). |

**Example:**

```powershell
# Install v0.1.0 into D:\MetaCall
powershell -NoProfile -ExecutionPolicy Unrestricted -Command \
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
  &([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/metacall/install/master/install.ps1'))) \
  -InstallDir 'D:\MetaCall' -Version '0.1.0'"
```

---

## 🔍 Testing

After installation, verify your setup:

### Linux / macOS

```sh
# Clone installer and run tests
git clone https://github.com/metacall/install.git metacall-install
cd metacall-install
env INSTALL_SCRIPT=./install.sh ./test.sh
```

### Windows

```powershell
git clone https://github.com/metacall/install.git metacall-install
cd metacall-install
powershell -NoProfile -ExecutionPolicy Unrestricted .\install.ps1
# (no built-in test harness yet)
```

---

## 🛠️ Troubleshooting

* **Blocked `raw.githubusercontent.com`**: Clone the repo and run scripts locally:

  ```sh
  git clone https://github.com/metacall/install.git
  cd install
  ./install.sh      # or .\install.ps1 on Windows
  ```

* **Permission issues**: Ensure your user has execution rights:

  ```sh
  chmod +x install.sh
  ```

* **Proxy environments**: Set `HTTP_PROXY` / `HTTPS_PROXY` before running scripts.

---

© 2025 MetaCall Contributors

