#!/bin/bash

set -e

# see:
# {my_notes_path}/linux/script_ideas.txt

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            arch|manjaro|endeavouros)
                echo "arch"
                ;;
            debian|ubuntu|linuxmint|pop)
                echo "debian"
                ;;
            *)
                echo "unsupported"
                ;;
        esac
    else
        echo "unsupported"
    fi
}

# Get installation command for a package based on distro
get_install_cmd() {
    local distro="$1"
    local arch_pkg="$2"
    local debian_pkg="$3"

    case "$distro" in
        arch)
            echo "sudo pacman -S $arch_pkg"
            ;;
        debian)
            echo "sudo apt install $debian_pkg"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get archive info: required command, arch package, debian package
get_archive_info() {
    local file="$1"
    local lowercase_file="${file,,}"

    case "$lowercase_file" in
        *.tar.gz|*.tgz)
            echo "tar:tar:tar"
            ;;
        *.tar.bz2|*.tbz2|*.tbz)
            echo "tar:tar:tar"
            ;;
        *.tar.xz|*.txz)
            echo "tar:tar:tar"
            ;;
        *.tar.zst|*.tzst)
            echo "tar:tar:tar"
            ;;
        *.tar.lz|*.tlz)
            echo "tar:tar:tar"
            ;;
        *.tar.lzma)
            echo "tar:tar:tar"
            ;;
        *.tar)
            echo "tar:tar:tar"
            ;;
        *.zip|*.cbz)
            echo "unzip:unzip:unzip"
            ;;
        *.7z)
            echo "7z:p7zip:p7zip-full"
            ;;
        *.rar|*.cbr)
            echo "unrar:unrar:unrar"
            ;;
        *.gz)
            echo "gunzip:gzip:gzip"
            ;;
        *.bz2)
            echo "bunzip2:bzip2:bzip2"
            ;;
        *.xz)
            echo "unxz:xz:xz-utils"
            ;;
        *.zst)
            echo "unzstd:zstd:zstd"
            ;;
        *.lz)
            echo "lzip:lzip:lzip"
            ;;
        *.lzma)
            echo "unlzma:xz:xz-utils"
            ;;
        *.Z)
            echo "uncompress:ncompress:ncompress"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Get the directory name (archive name without extension)
get_extract_dir_name() {
    local file="$1"
    local basename="${file##*/}"
    local lowercase="${basename,,}"

    # Remove known extensions (order matters - check compound extensions first)
    case "$lowercase" in
        *.tar.gz)   echo "${basename%.tar.gz}" ;;
        *.tar.bz2)  echo "${basename%.tar.bz2}" ;;
        *.tar.xz)   echo "${basename%.tar.xz}" ;;
        *.tar.zst)  echo "${basename%.tar.zst}" ;;
        *.tar.lz)   echo "${basename%.tar.lz}" ;;
        *.tar.lzma) echo "${basename%.tar.lzma}" ;;
        *.tgz)      echo "${basename%.tgz}" ;;
        *.tbz2)     echo "${basename%.tbz2}" ;;
        *.tbz)      echo "${basename%.tbz}" ;;
        *.txz)      echo "${basename%.txz}" ;;
        *.tzst)     echo "${basename%.tzst}" ;;
        *.tlz)      echo "${basename%.tlz}" ;;
        *.tar)      echo "${basename%.tar}" ;;
        *.zip)      echo "${basename%.zip}" ;;
        *.cbz)      echo "${basename%.cbz}" ;;
        *.7z)       echo "${basename%.7z}" ;;
        *.rar)      echo "${basename%.rar}" ;;
        *.cbr)      echo "${basename%.cbr}" ;;
        *.gz)       echo "${basename%.gz}" ;;
        *.bz2)      echo "${basename%.bz2}" ;;
        *.xz)       echo "${basename%.xz}" ;;
        *.zst)      echo "${basename%.zst}" ;;
        *.lz)       echo "${basename%.lz}" ;;
        *.lzma)     echo "${basename%.lzma}" ;;
        *.Z)        echo "${basename%.Z}" ;;
        *)          echo "$basename" ;;
    esac
}

# Find next available directory name with suffix
get_available_dir() {
    local base_dir="$1"

    if [ ! -e "$base_dir" ]; then
        echo "$base_dir"
        return
    fi

    local counter=2
    while [ -e "${base_dir}-${counter}" ]; do
        ((counter++))
    done

    echo "${base_dir}-${counter}"
}

# Extract the archive
extract_archive() {
    local file="$1"
    local dest_dir="$2"
    local lowercase_file="${file,,}"

    case "$lowercase_file" in
        *.tar.gz|*.tgz)
            tar -xzf "$file" -C "$dest_dir"
            ;;
        *.tar.bz2|*.tbz2|*.tbz)
            tar -xjf "$file" -C "$dest_dir"
            ;;
        *.tar.xz|*.txz)
            tar -xJf "$file" -C "$dest_dir"
            ;;
        *.tar.zst|*.tzst)
            tar --zstd -xf "$file" -C "$dest_dir"
            ;;
        *.tar.lz|*.tlz)
            tar --lzip -xf "$file" -C "$dest_dir"
            ;;
        *.tar.lzma)
            tar --lzma -xf "$file" -C "$dest_dir"
            ;;
        *.tar)
            tar -xf "$file" -C "$dest_dir"
            ;;
        *.zip|*.cbz)
            unzip -q "$file" -d "$dest_dir"
            ;;
        *.7z)
            7z x "$file" -o"$dest_dir" > /dev/null
            ;;
        *.rar|*.cbr)
            unrar x -inul "$file" "$dest_dir/"
            ;;
        *.gz)
            gunzip -c "$file" > "$dest_dir/$(basename "${file%.gz}")"
            ;;
        *.bz2)
            bunzip2 -c "$file" > "$dest_dir/$(basename "${file%.bz2}")"
            ;;
        *.xz)
            unxz -c "$file" > "$dest_dir/$(basename "${file%.xz}")"
            ;;
        *.zst)
            unzstd -q -c "$file" > "$dest_dir/$(basename "${file%.zst}")"
            ;;
        *.lz)
            lzip -dc "$file" > "$dest_dir/$(basename "${file%.lz}")"
            ;;
        *.lzma)
            unlzma -c "$file" > "$dest_dir/$(basename "${file%.lzma}")"
            ;;
        *.Z)
            uncompress -c "$file" > "$dest_dir/$(basename "${file%.Z}")"
            ;;
        *)
            print_error "Unknown archive format"
            return 1
            ;;
    esac
}

# Main script
main() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <archive_file>"
        echo ""
        echo "Supported formats:"
        echo "  tar, tar.gz, tgz, tar.bz2, tbz2, tar.xz, txz, tar.zst, tar.lz, tar.lzma"
        echo "  zip, cbz, 7z, rar, cbr, gz, bz2, xz, zst, lz, lzma, Z"
        exit 1
    fi

    local archive_path="$1"

    # Check if file exists
    if [ ! -f "$archive_path" ]; then
        print_error "File not found: $archive_path"
        exit 1
    fi

    # Get absolute path
    archive_path="$(realpath "$archive_path")"
    local archive_dir="$(dirname "$archive_path")"

    # Get archive info
    local archive_info
    archive_info=$(get_archive_info "$archive_path")

    if [ -z "$archive_info" ]; then
        print_error "Unsupported archive format: $archive_path"
        exit 1
    fi

    # Parse archive info
    IFS=':' read -r required_cmd arch_pkg debian_pkg <<< "$archive_info"

    # Check if required command exists
    if ! command_exists "$required_cmd"; then
        print_error "Required command '$required_cmd' is not installed."
        echo ""

        local distro
        distro=$(detect_distro)
        local install_cmd
        install_cmd=$(get_install_cmd "$distro" "$arch_pkg" "$debian_pkg")

        if [ -n "$install_cmd" ]; then
            print_warning "To install on your system, run:"
            echo "  $install_cmd"
        else
            print_warning "Unsupported distribution. Please install '$required_cmd' manually."
            echo ""
            echo "Package names:"
            echo "  Arch Linux: $arch_pkg"
            echo "  Debian/Ubuntu: $debian_pkg"
        fi
        exit 1
    fi

    # Get extraction directory name with auto-increment suffix if needed
    local extract_name
    extract_name=$(get_extract_dir_name "$archive_path")
    local extract_dir
    extract_dir=$(get_available_dir "$archive_dir/$extract_name")

    # Create the directory
    mkdir -p "$extract_dir"

    echo "Extracting: $(basename "$archive_path")"
    echo "       To: $extract_dir"
    echo ""

    # Extract the archive
    if extract_archive "$archive_path" "$extract_dir"; then
        print_success "Done! Extracted to: $extract_dir"
    else
        # Cleanup on failure
        rmdir "$extract_dir" 2>/dev/null || true
        print_error "Extraction failed"
        exit 1
    fi
}

main "$@"

