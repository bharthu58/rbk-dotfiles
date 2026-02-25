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
    git clone https://github.com/yourusername/rbk-dotfiles.git
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