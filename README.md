# codevar

Generate encoded variables using secrets and text with base encoding support.

## Description

`codevar` is a command-line utility for generating encoded variables using a secret key and text input. It supports multiple base encoding schemes (base64, base85, base91, base122) and includes a base encoding/decoding utility (`base91`) that can handle all these formats.

## Features

- **Secret-based encoding**: Generate encoded variables using secrets with optional year protection
- **Multiple encoding schemes**: Support for base64, base85, base91, and base122
- **Configurable**: Default values can be set in `~/.config/codevar/config.ini`
- **Base encoding utility**: Included `base91` program for encoding/decoding data
- **Comprehensive build system**: Supports both Makefile and Meson builds
- **Debian packaging**: Ready for Debian/Ubuntu package creation
- **Documentation**: Man pages and bash completion included
- **Test suite**: Automated tests for both codevar and base91

## Installation

### From Source

#### Using Makefile

```bash
make
sudo make install
```

#### Using Meson

```bash
meson setup build
ninja -C build
sudo ninja -C build install
```

### Build Options

- `PREFIX`: Installation prefix (default: `/usr`)
- `DESTDIR`: Staging directory for packaging

Example:
```bash
make install PREFIX=/usr/local DESTDIR=/tmp/staging
```

### Install Symlinks

To create symlinks in `/usr/bin` (hardcoded):
```bash
sudo make install-symlinks
```

This creates:
- `/usr/bin/base85` → project base91
- `/usr/bin/base91` → project base91
- `/usr/bin/base122` → project base91

## Usage

### codevar

```bash
codevar [OPTIONS] TEXT
```

#### Options

- `-s, --secret=SECRET`: Secret key to use
- `-l, --length=LEN`: Trim output to length (default: 8)
- `-d, --digest=DGST`: Digest algorithm (default: sha256)
- `-y, --year`: Protect secret with year around: yyyy + SECRET + yyyy
- `-e, --encoding=ENCODE`: Encoding method (default: base64)
- `-b, --base64`: Use base64 encoding
- `-8, --base85`: Use base85 encoding
- `-9, --base91`: Use base91 encoding
- `-B, --base122`: Use base122 encoding
- `-v, --verbose`: Increase verbosity
- `-q, --quiet`: Decrease verbosity
- `-h, --help`: Show help
- `--version`: Show version

#### Examples

```bash
# Basic usage
codevar -s "mysecret" "hello world"

# With year protection
codevar -s "mysecret" -y "hello world"

# Custom length and encoding
codevar -s "mysecret" -9 -l 12 "hello world"

# Using config file defaults
codevar "hello world"
```

#### Configuration File

Create `~/.config/codevar/config.ini`:

```ini
secret=defaultsecret
length=10
digest=sha256
encoding=base64
```

### base91

```bash
base91 [OPTIONS] FILES...
```

If `FILES` is `-` or not specified, read from stdin.

If the program name ends with `64/85/91/122`, that determines the default encoding.

#### Options

- `-b, --binary`: Input is binary
- `-t, --text`: Input is text (default)
- `-d, --decode`: Decode data
- `-i, --ignore-garbage`: When decoding, ignore non-alphabet characters
- `-w, --wrap=COLS`: Wrap encoded lines after COLS characters (default: 76, use 0 to disable)
- `-6, --base64`: Use base64 encoding
- `-8, --base85`: Use base85 encoding
- `-9, --base91`: Use base91 encoding
- `-B, --base122`: Use base122 encoding
- `-h, --help`: Show help
- `--version`: Show version

#### Examples

```bash
# Encode file
base91 file.txt

# Decode from stdin
echo "encoded_string" | base91 -d -i

# Use as base64 encoder (via symlink)
ln -s base91 base64
./base64 file.txt

# Encode with no line wrapping
base91 -w 0 file.txt
```

## Mechanism

The codevar encoding mechanism:

1. Generate secret prime: `secret' = digest(yyyy + SECRET + yyyy)` (when `-y` flag is used)
2. Combine: `secret' + TEXT + secret'`
3. Encode: Apply base encoding (base64/base85/base91/base122)
4. Trim: Trim to specified length

## Building

### Requirements

- C compiler (gcc or clang)
- Make (for Makefile build)
- Meson and Ninja (for Meson build)
- OpenSSL (for digest operations in codevar)
- shlib (for codevar shell script)

### Makefile Build

```bash
make              # Build base91
make clean        # Clean build artifacts
make install      # Install to PREFIX
make uninstall    # Remove installed files
```

### Meson Build

```bash
meson setup build
ninja -C build
ninja -C build install
```

### Debian Package

```bash
dpkg-buildpackage -us -uc
```

## Testing

Run the test suite:

```bash
cd test
make test
```

Or run individual tests:

```bash
./test/test_base91.sh
./test/test_codevar.sh
```

## Project Structure

```
codevar/
├── codevar              # Main shell script
├── base91.c             # Base encoding C program
├── Makefile             # Traditional build system
├── meson.build          # Meson build configuration
├── debian/              # Debian packaging files
├── test/                # Test suite
├── *.1                  # Man pages
├── *.bash-completion    # Bash completion scripts
└── README.md            # This file
```

## Documentation

- `man codevar` - codevar manual page
- `man base91` - base91 manual page

## License

GPL-3.0-or-later - see `debian/copyright` or `LICENSE` file for details.

## Author

Lenik (谢继雷) <lenik@bodz.net>

## Repository

https://github.com/lenik/codevar

