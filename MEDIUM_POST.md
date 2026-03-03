# From "It Works on My Machine" to "It Works Everywhere": Building the Ultimate Polyglot Bootstrap

We have all been there. You get a new laptop, or you spin up a fresh cloud instance, and the excitement of a clean slate is immediately replaced by the dread of **The Setup**.

You spend four hours installing `nvm`, then `pyenv`, then realizing your system Python conflicts with your project Python. Then you install `zsh`, but your aliases are in `.bashrc`. You try to run a C++ build, but `cmake` is too old.

I decided to solve this problem once and for all. I didn't just want a dotfiles repo; I wanted a **System State Engine**. I wanted a single command that could turn a bare-bones Ubuntu server or a fresh Docker container into a world-class, AI-enhanced, polyglot engineering environment.

Here is the journey of building **rbk-dotfiles**.

---

## The Requirements: High-Performance & Polyglot

I am not just building a web app. My workflow requires a heavy-duty, polyglot stack. A standard "install node and git" script wouldn't cut it. I needed:

1.  **Polyglot Runtimes**: Node.js (LTS), Python 3.12+, Java 21, and CMake 3.28+.
2.  **Modern C++ Toolchain**: Clang, Ninja, Ccache, and GDB.
3.  **AI-Native Workflow**: Gemini and Claude CLIs integrated directly into the shell.
4.  **Container Compatibility**: The script must run on my laptop *and* inside a CI/Docker container without human intervention.
5.  **Verification**: A way to prove the environment is correct programmatically.

## The Stack Selection

To achieve this, I moved away from the old school `apt-get install everything` approach and embraced modern tooling.

### 1. The Runtime Manager: `mise`
I ditched `nvm`, `pyenv`, and `jenv` in favor of **mise**.
Mise (formerly rtx) is written in Rust. It’s blazing fast, manages multiple languages via a single CLI, and handles environment variables better than the competition.

### 2. The Dotfile Manager: `chezmoi`
Symlinking files manually is fragile. **chezmoi** allows me to manage dotfiles as templates. It handles permissions securely and allows me to inject machine-specific configurations dynamically.

### 3. The Shell: Bash + Starship
While Zsh is popular, Bash is universal. I decided to optimize Bash with **Starship**, a cross-shell prompt that gives me git status, package versions, and execution time at a glance.

---

## The Challenge: The "Bootstrap" Paradox

The hardest part of automating a setup is the "chicken and egg" problem. You need tools to install tools.

### Solving the Container vs. Sudo Problem
One of the biggest headaches was making the script work in Docker. Standard Ubuntu containers run as `root` but don't have `sudo` installed. My local machine runs as a user *with* `sudo`.

I wrote a logic block in `bootstrap.sh` to detect the environment and adapt:

```bash
# Container/CI compatibility: Ensure sudo exists or we are root
if ! command -v sudo &> /dev/null; then
  if [ "$(id -u)" -eq 0 ]; then
    echo "⚠️  Running as root without sudo. Installing sudo for compatibility..."
    apt-get update && apt-get install -y sudo
  else
    echo "❌ Error: This script requires 'sudo' or root privileges."
    exit 1
  fi
fi
```

This ensures the script is portable across bare metal and cloud containers.

### The "Shim" Wars: Installing AI CLIs
I wanted the Google Gemini CLI available globally. However, installing global NPM packages via `mise` sometimes results in path issues where the binary isn't immediately visible to the shell.

I had to write a custom detection loop to find where `npm` put the binary and force-link it to `~/.local/bin`:

```bash
# Discover the global npm bin dir for mise's node
BIN_DIR="$(mise exec node@lts -- npm prefix -g 2>/dev/null)/bin"

# Look for variations of the binary name
CANDS=(gemini gemini-cli gemini-chat generative-ai-cli)
for b in "${CANDS[@]}"; do
  if [ -x "$BIN_DIR/$b" ]; then
    ln -sf "$BIN_DIR/$b" "$HOME/.local/bin/gemini"
    break
  fi
done
```

This guarantees that when I type `gemini`, it actually works, regardless of how the upstream package names their binary.

---

## The "Secret Sauce": AI Integration

This isn't just a coding environment; it's a **thinking** environment. I integrated custom AI commands directly into the workflow.

I created a configuration for `gemini` specifically for high-frequency trading architecture design. By placing a TOML file in `~/.gemini/commands/trade-engine.toml`, I can trigger a specific persona:

```toml
name = "trade-engine"
description = "Design and implementation plan for an Always-On AI Hedging Engine."
prompt = '''
You are a Senior Quantitative Systems Architect specializing in Ultra-Low Latency (ULL)...
Technical Stack: C++20/23, Aeron IPC, QuestDB, LibTorch...
'''
```

Now, I simply type `gemini trade-engine` in my terminal, and I have an AI architect context-aware of my specific C++ stack ready to help.

---

## Trust but Verify: The Testing Harness

A bootstrap script is code, and code needs tests. I didn't want to wipe my laptop every time I tweaked a line of code.

I built a **Docker Test Harness** (`test-in-docker.sh`). It mounts the current repository into a fresh `ubuntu:latest` container and runs the bootstrap.

```bash
docker run --rm -it \
  -v "$REPO_ROOT:/root/dotfiles" \
  -w /root/dotfiles \
  -e TEST_MODE=true \
  ubuntu:latest \
  bash -c "bash bootstrap.sh && bash verify-bs.sh"
```

But I went a step further. I wrote a **Verification Script** (`verify-bs.sh`). It’s essentially a unit test suite for my operating system. It checks:
1.  Are `node`, `python`, `java`, `cmake` accessible?
2.  Is the C++ toolchain (`clang`, `ninja`) healthy?
3.  Did `chezmoi` apply the config files?
4.  Is `starship` hooked into `.bashrc`?

If `verify-bs.sh` exits with code 0, I know the environment is perfect.

---

## The Result

The final result is a repository that I can clone on any machine, run `./bootstrap.sh`, and within minutes, have a production-ready environment.

*   **No more version conflicts.**
*   **No more missing paths.**
*   **No more "it works on my machine."**

It installs everything from `neovim` and `tmux` to `clang-tidy` and `gemini-cli`. It configures my shell with safety aliases (like `rm -I`) and modern tools (`ripgrep` instead of `grep`).

If you are tired of manual setups, I highly recommend adopting a "Bootstrap + Verify" pattern. It turns your development environment into immutable infrastructure.

## Entire README for the project:

# RBK Dotfiles & Bootstrap

A robust, automated bootstrap solution for setting up a high-performance, polyglot development environment on Ubuntu/Debian systems. This project uses modern tooling to ensure reproducibility, speed, and developer ergonomics.

## 🚀 Features

*   **Polyglot Runtime Management**: Uses [mise](https://mise.jdx.dev/) to manage versions for:
    *   **Node.js** (LTS + project specific)
    *   **Python** (3.12+)
    *   **Java** (Temurin 21)
    *   **CMake** (3.28+)
*   **Modern C++ Toolchain**:
    *   Clang, GCC, Ninja, Ccache, GDB/LLDB.
    *   Includes `clang-format` and `clang-tidy`.
*   **AI-Native Workflow**:
    *   **Gemini CLI**: Pre-configured with shim generation and custom command support (e.g., `trade-engine`).
    *   **Claude Code CLI**: Integrated directly into the path.
*   **Shell Experience**:
    *   **Bash**: Optimized configuration with `starship` prompt.
    *   **Aliases**: Smart defaults for `ls`, `grep`, `git`, and safety guards for `rm`/`cp`.
    *   **Modern Replacements**: `ripgrep` (rg), `fd`, `bat` (aliased to cat), `neovim`.
*   **Dotfile Management**: Powered by chezmoi for secure and scriptable dotfile application.

## 📋 Prerequisites

*   **OS**: Ubuntu 20.04/22.04/24.04 or Debian-based equivalent.
*   **Permissions**: Root access or `sudo` privileges (the script will auto-install `sudo` if missing in containers).
*   **Network**: Active internet connection for downloading packages.

## ⚡ Quick Start

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/bharthu58/rbk-dotfiles.git
    cd rbk-dotfiles
    ```

2.  **Run the bootstrap script:**
    ```bash
    ./bootstrap.sh
    ```
    *This will install system packages, setup `mise`, install language runtimes, configure the shell, and apply dotfiles.*

3.  **Reload your shell:**
    The script attempts to reload automatically, but you may need to run:
    ```bash
    exec bash -l
    ```

## ✅ Verification

To ensure the environment is correctly set up, run the included verification script. It checks for binary presence, version health, and configuration integrity.

```bash
./verify-bs.sh
```

## 🐳 Testing in Docker

You can test the entire bootstrap process in a clean, isolated Ubuntu container without affecting your host machine.

```bash
./test-in-docker.sh
```

*   **Mounts**:
    *   Maps the current repo to `/root/dotfiles`.
    *   Maps `~/.gemini` (if it exists) to test custom AI commands.
*   **Automation**: Runs `bootstrap.sh` followed immediately by `verify-bs.sh`.

## 📂 Project Structure

```text
.
├── bootstrap.sh             # Main installation script
├── verify-bs.sh             # Post-install health check
├── test-in-docker.sh        # CI/Local testing harness
├── generate_bash_config.sh  # Generates dot_bashrc, dot_bash_profile, etc.
├── .tool-versions           # Pinned versions for mise (Python, Node, Java)
├── .gitignore               # Ignores binaries and generated dotfiles
└── README.md                # Project documentation
```

## 🛠 Customization

### Shell Configuration
Bash configuration files (`.bashrc`, `.bash_profile`, `.bash_aliases`) are dynamically generated.
*   **Edit**: Modify `generate_bash_config.sh`.
*   **Apply**: Run `./bootstrap.sh` again or manually run `chezmoi apply`.

### Tool Versions
To change the default versions of Python, Node, or Java:
1.  Edit `.tool-versions`.
2.  Run `mise install`.

### Custom AI Commands
The environment supports custom Gemini CLI commands defined in TOML.
1.  Place your TOML files in `~/.gemini/commands/`.
2.  Example `trade-engine.toml`:
    ```toml
    name = "trade-engine"
    description = "AI Hedging Engine Design"
    prompt = "..."
    ```
3.  Run via: `gemini trade-engine`

## 📄 License
MIT