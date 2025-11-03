# Swift Installation on Linux

## Purpose

This document provides a step-by-step guide for installing Swift on Linux systems (Ubuntu/Debian-based distributions). It is essential for developers working on ISOInspector to have a consistent Swift development environment for building and testing the project.

---

## Prerequisites

### System Requirements

- **Linux Distribution**: Ubuntu 20.04, 22.04, or 24.04 LTS (or compatible Debian-based distro)
- **Architecture**: x86_64 or ARM64
- **Disk Space**: ~1.5 GB for Swift toolchain
- **Network**: Internet connection for downloading Swift

### Check Your System

```bash
# Check Ubuntu version
lsb_release -a

# Check architecture
uname -m

# Check available disk space
df -h ~
```

---

## Installation Steps

### Step 1: Update System Packages

```bash
sudo apt update && sudo apt upgrade
```

### Step 2: Install Dependencies

Swift requires several system libraries and tools:

```bash
# For Ubuntu 24.04
sudo apt install -y \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-9-dev \
    libpython3.8 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
```

**Note:** Package names may vary for different Ubuntu versions. For Ubuntu 20.04 or 22.04, adjust package versions accordingly (e.g., `libpython3.8` → `libpython3.10`).

### Step 3: Download Swift

Visit the official Swift download page: [https://www.swift.org/download/](https://www.swift.org/download/)

Or download directly using `wget`:

```bash
# Navigate to a temporary directory
cd /tmp

# Download Swift 6.0.3 for Ubuntu 24.04 (example)
wget https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
```

**Important:** Replace the URL with the version and distribution that matches your system:
- Ubuntu 24.04: `ubuntu2404`
- Ubuntu 22.04: `ubuntu2204`
- Ubuntu 20.04: `ubuntu2004`

### Step 4: Verify Download (Optional but Recommended)

Download and verify the signature:

```bash
# Download signature
wget https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz.sig

# Import Swift keys
wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -

# Verify signature
gpg --verify swift-6.0.3-RELEASE-ubuntu24.04.tar.gz.sig
```

### Step 5: Extract Swift Archive

```bash
# Extract the archive
tar -xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz

# Create installation directory
mkdir -p ~/.local/swift

# Move extracted files to installation directory
mv swift-6.0.3-RELEASE-ubuntu24.04 ~/.local/swift/
```

**Alternative:** System-wide installation (requires sudo):

```bash
sudo mv swift-6.0.3-RELEASE-ubuntu24.04 /usr/share/swift
```

### Step 6: Add Swift to PATH

#### For User Installation (~/.local/swift)

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`):

```bash
# Add this line to ~/.bashrc
export PATH="$HOME/.local/swift/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin:$PATH"
```

Apply changes:

```bash
source ~/.bashrc
```

#### For System-wide Installation (/usr/share/swift)

```bash
# Add this line to ~/.bashrc
export PATH="/usr/share/swift/usr/bin:$PATH"
```

Apply changes:

```bash
source ~/.bashrc
```

### Step 7: Verify Installation

```bash
# Check Swift version
swift --version

# Expected output:
# Swift version 6.0.3 (swift-6.0.3-RELEASE)
# Target: x86_64-unknown-linux-gnu
```

Test REPL:

```bash
# Start Swift REPL
swift

# Type in REPL:
print("Hello, Swift!")

# Exit REPL
:quit
```

---

## Testing Swift with ISOInspector

### Build the Project

```bash
cd /path/to/ISOInspector
swift build
```

### Run Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter TolerantTraversalRegressionTests

# Run with verbose output
swift test -v
```

### Build for Release

```bash
swift build -c release
```

---

## Version Management

### Managing Multiple Swift Versions

If you need to work with multiple Swift versions, you can:

1. **Install to versioned directories:**
   ```bash
   ~/.local/swift/swift-6.0.3/
   ~/.local/swift/swift-5.10/
   ```

2. **Use symbolic links:**
   ```bash
   ln -sf ~/.local/swift/swift-6.0.3-RELEASE-ubuntu24.04 ~/.local/swift/current
   export PATH="$HOME/.local/swift/current/usr/bin:$PATH"
   ```

3. **Use swiftly (Swift version manager):**
   ```bash
   # Install swiftly
   curl -L https://swift-server.github.io/swiftly/swiftly-install.sh | bash

   # Install Swift version
   swiftly install 6.0.3

   # Switch versions
   swiftly use 6.0.3
   ```

---

## Troubleshooting

### Issue: "swift: command not found"

**Solution:** PATH not set correctly. Verify:

```bash
echo $PATH
# Should contain Swift bin directory

# Re-source your profile
source ~/.bashrc
```

### Issue: Missing Dependencies

**Solution:** Install missing packages:

```bash
# Check for missing libraries
ldd ~/.local/swift/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin/swift

# Install missing dependencies via apt
sudo apt install <package-name>
```

### Issue: "cannot open shared object file"

**Solution:** Install required system libraries:

```bash
sudo apt install -y libpython3.8 libcurl4 libxml2
```

### Issue: Tests Fail to Build

**Solution:** Clean build artifacts and rebuild:

```bash
swift package clean
swift build
swift test
```

---

## Performance Optimization

### Enable Compiler Optimizations

```bash
# Build with optimizations
swift build -c release -Xswiftc -O

# Use whole module optimization
swift build -c release -Xswiftc -whole-module-optimization
```

### Parallel Test Execution

```bash
# Run tests in parallel (default)
swift test --parallel

# Specify number of workers
swift test --num-workers 4
```

---

## ISOInspector-Specific Notes

### Verified Versions

The following Swift versions are tested and confirmed working with ISOInspector:

- **Swift 6.0.3** ✅ (Recommended)
- **Swift 5.10.x** ✅
- **Swift 5.9.x** ⚠️ (May have compatibility issues)

### Required Swift Package Manager Version

ISOInspector requires Swift Package Manager (SPM) 5.9 or later.

```bash
swift package --version
```

### Dependencies

ISOInspector depends on:
- `swift-argument-parser` (^1.6.0)
- `swift-docc-plugin` (^1.4.0)
- `NestedA11yIDs` (^1.0.0)

These are automatically fetched during build.

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Swift Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Install Swift
        run: |
          wget https://download.swift.org/swift-6.0.3-release/ubuntu2404/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
          tar -xzf swift-6.0.3-RELEASE-ubuntu24.04.tar.gz
          sudo mv swift-6.0.3-RELEASE-ubuntu24.04 /usr/share/swift
          echo "/usr/share/swift/usr/bin" >> $GITHUB_PATH

      - name: Build
        run: swift build

      - name: Test
        run: swift test
```

### Docker Example

```dockerfile
FROM swift:6.0.3-jammy

WORKDIR /app

COPY . .

RUN swift build -c release

CMD ["swift", "test"]
```

---

## Updating Swift

To update to a newer Swift version:

1. Download the new version
2. Extract to a new directory
3. Update PATH or symbolic link
4. Test compatibility with ISOInspector
5. Update this documentation with verified version

```bash
# Example: Updating from 6.0.3 to 6.1.0
cd /tmp
wget https://download.swift.org/swift-6.1.0-release/ubuntu2404/swift-6.1.0-RELEASE/swift-6.1.0-RELEASE-ubuntu24.04.tar.gz
tar -xzf swift-6.1.0-RELEASE-ubuntu24.04.tar.gz
mv swift-6.1.0-RELEASE-ubuntu24.04 ~/.local/swift/
ln -sf ~/.local/swift/swift-6.1.0-RELEASE-ubuntu24.04 ~/.local/swift/current
source ~/.bashrc
swift --version
```

---

## Uninstallation

To remove Swift:

```bash
# Remove installation directory
rm -rf ~/.local/swift/swift-6.0.3-RELEASE-ubuntu24.04

# Remove PATH entry from ~/.bashrc
# (Edit file manually or use sed)
sed -i '/swift.*usr\/bin/d' ~/.bashrc

# Re-source profile
source ~/.bashrc
```

---

## References

- **Official Swift Downloads**: [https://www.swift.org/download/](https://www.swift.org/download/)
- **Swift on Linux Documentation**: [https://www.swift.org/getting-started/#using-the-package-manager](https://www.swift.org/getting-started/#using-the-package-manager)
- **Swift Package Manager**: [https://github.com/apple/swift-package-manager](https://github.com/apple/swift-package-manager)
- **Swiftly Version Manager**: [https://github.com/swift-server/swiftly](https://github.com/swift-server/swiftly)
- **Swift Forums**: [https://forums.swift.org/](https://forums.swift.org/)

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-03 | 1.0 | Initial version - Swift 6.0.3 on Ubuntu 24.04 | Claude |

---

## Notes

- Always use the latest stable Swift version compatible with ISOInspector
- Keep this document updated when testing new Swift releases
- Report compatibility issues in project issue tracker
- For production deployments, pin to specific Swift version in CI/CD
