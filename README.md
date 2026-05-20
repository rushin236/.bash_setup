# .bash_setup

**A modular, distribution-agnostic CLI engine for managing your development environment.**

`.bash_setup` is a lightweight, powerful bash-based framework designed to synchronize your developer tools, language runtimes, and system configurations seamlessly across any Linux distribution. Whether you use Arch, Debian, Fedora, or openSUSE, `.bash_setup` ensures your development environment remains consistent, fast, and organized.

## 🚀 Key Features

* **Distro Agnostic:** Built to work natively on **Arch Linux, Debian/Ubuntu, Fedora, and openSUSE**.
* **Modular Architecture:** Organized into specific commands: `pkg` (system packages), `subpkg` (language-specific tools), and `sync` (runtime synchronization).
* **User-Space Focus:** Leverages [mise](https://mise.jdx.dev/) to install runtimes (Python, Node, Go, PHP, etc.) in your home directory, avoiding `sudo` privileges and system-level conflicts.
* **Zero-Overhead Configuration:** Requires only one line added to your `.bashrc`.
* **High Performance:** Optimized bash scripts that utilize batched processing and asynchronous handling for lightning-fast synchronization.

---

## 🛠️ System Prerequisites

Before running the setup, ensure your system has the following core utilities installed (usually present by default): `curl`, `wget`, `git`, `make`, `tar`, and `xz`.

### System Dependencies

To ensure the automated compilation of tools (like PHP, Lua, or Tectonic) works correctly, please install the necessary development headers for your distribution:

**Debian / Ubuntu:**

```bash
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential autoconf bison re2c pkg-config ca-certificates \
    git curl wget make tar xz-utils gzip gawk unzip \
    libxml2-dev libssl-dev libicu-dev libzip-dev libonig-dev \
    libcurl4-openssl-dev libpng-dev libjpeg-dev libfreetype-dev \
    libreadline-dev libbz2-dev libsqlite3-dev libgd-dev libpcre2-dev \
    libharfbuzz-dev libgraphite2-dev
```

**Arch Linux:**

```bash
sudo pacman -Syu --noconfirm base-devel git make curl wget tar \
    xz gawk unzip openssl zlib bzip2 readline sqlite libffi \
    pkgconf re2c bison libxml2 oniguruma libzip gettext \
    harfbuzz harfbuzz-icu graphite fontconfig icu libpng \
    libjpeg-turbo freetype2 gd pcre2
```

**Fedora:**

```bash
sudo dnf install -y @development-tools util-linux git make curl wget tar xz gawk unzip \
    openssl-devel zlib-devel bzip2-devel readline-devel sqlite-devel libffi-devel \
    pkgconfig re2c bison autoconf libxml2-devel oniguruma-devel libcurl-devel \
    libzip-devel gettext-devel libicu-devel libpng-devel libjpeg-turbo-devel \
    freetype-devel gdbm-devel libwebp-devel libXpm-devel gcc-c++ automake libtool \
    harfbuzz-devel graphite2-devel fontconfig-devel gd-devel pcre2-devel \
```

**openSUSE:**

```bash
sudo zypper --non-interactive refresh
sudo zypper --non-interactive install --no-recommends --force-resolution \
    gcc gcc-c++ make autoconf automake libtool bison re2c pkgconf patch gawk unzip \
    findutils git curl tar xz gzip bzip2 zlib-devel libopenssl-devel sqlite3 \
    sqlite3-devel readline-devel libxml2-devel libcurl-devel libzip-devel \
    oniguruma-devel libtirpc-devel glibc-devel linux-glibc-devel \
    ncurses-devel libicu-devel libpng-devel libjpeg-devel libwebp-devel \
    libsodium-devel gmp-devel ca-certificates harfbuzz-devel \
    graphite2-devel fontconfig-devel gd-devel pcre2-devel
```

---
## 📥 Installation

1. **Clone the repository** to your home directory:
```bash
git clone https://github.com/rushin236/.bash_setup.git ~/.bash_setup
```

2. **Configure your shell** by appending this single line to your `~/.bashrc`:
```bash
[ -s "$HOME/.bash_setup/bash_setup.sh" ] && source "$HOME/.bash_setup/bash_setup.sh"
```

3. **Reload your shell** or open a new terminal window to initialize the tool.

---
## ⚡ Usage

`.bash_setup` is controlled via the `tool` command.

* **Synchronize everything:**
```bash
tool sync all
```

* **Manage Runtimes:**
```bash
tool sync runtimes          # Sync all languages
tool sync python node php   # Sync specific languages
```

* **Manage Sub-packages:**
```bash
tool subpkg npm install all   # Install all npm packages from config
tool subpkg cargo remove eza  # Remove a specific cargo package
```

## 🔄 Updating

Keeping your environment up to date is simple. Navigate to your setup directory and pull the latest changes:

```bash
cd ~/.bash_setup
git pull
```
