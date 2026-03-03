# Contributing to RBK Dotfiles

Thank you for your interest in contributing! This project aims to provide a robust, "always-working" bootstrap for high-performance development environments.

## 📂 Project Structure

*   **`bootstrap.sh`**: The main engine. Handles OS packages, `mise` setup, and tool installation.
*   **`generate_bash_config.sh`**: Generates the `.bashrc`, `.bash_profile`, and `.bash_aliases` files. Edit this to change shell behavior.
*   **`verify-bs.sh`**: The integration test suite. Checks if tools are installed and configs are applied.
*   **`test-in-docker.sh`**: The local CI harness. Runs the bootstrap in a clean Ubuntu container.
*   **`.tool-versions`**: Defines the specific versions of Node, Python, Java, etc.

## 🛠 How to Make Changes

### Adding a System Package
1.  Edit `bootstrap.sh`.
2.  Add the package to the `apt install` list under the "Base System Packages" section.
3.  Add a check for the command in `verify-bs.sh`.

### Adding a New Tool via Mise
1.  If it's a global tool (like `node` or `python`), update `.tool-versions` or the `mise install` section in `bootstrap.sh`.
2.  If it requires a shim or specific setup (like the Gemini CLI), add a dedicated section in `bootstrap.sh`.

### Modifying Shell Configuration
**Do not edit `.bashrc` directly.**
1.  Edit `generate_bash_config.sh`.
2.  This script generates the `dot_` files that `chezmoi` applies.

## 🧪 Testing (Mandatory)

We prioritize stability. You **must** test your changes in a clean environment before submitting a PR.

### Run the Docker Test Harness
We provide a script that mounts your local changes into a fresh Ubuntu container and runs the full bootstrap + verification process.

```bash
./test-in-docker.sh
```

**Success Criteria:**
1.  The script completes without errors.
2.  The `verify-bs.sh` script (ran automatically at the end) reports **0 failed checks**.
3.  You see `🎉 System verification successful!` in the output.

## ✅ Verification Script

If you add a new tool or configuration file, please update `verify-bs.sh` to ensure it is checked.

*   Use `check_cmd <command>` to verify a binary exists.
*   Add file paths to `FILES_TO_CHECK` to verify file creation.

## 📝 Style Guidelines

*   **Shell Scripts**:
    *   Always use `#!/usr/bin/env bash`.
    *   Always include `set -euo pipefail` at the top for robustness.
    *   Use 2 spaces for indentation.
*   **Commits**:
    *   Use clear, descriptive commit messages (e.g., `feat: add rust support`, `fix: resolve gemini cli path`).

## 🚀 Submitting a Pull Request

1.  Fork the repository.
2.  Create a feature branch (`git checkout -b feature/my-feature`).
3.  Commit your changes.
4.  **Run `./test-in-docker.sh` and ensure it passes.**
5.  Push to your fork and submit a PR.
6.  In the PR description, confirm that you have run the Docker tests.