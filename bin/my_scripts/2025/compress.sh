#!/bin/bash

set -e

# see:
# {my_notes_path}/linux/script_ideas.txt

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}$1${NC}"
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

# Get compression info: required command, arch package, debian package, extension
get_compression_info() {
    local format="$1"
    local lowercase="${format,,}"

    case "$lowercase" in
        zip)
            echo "zip:zip:zip:.zip"
            ;;
        tar)
            echo "tar:tar:tar:.tar"
            ;;
        tar.gz|tgz|targz)
            echo "tar:tar:tar:.tar.gz"
            ;;
        tar.bz2|tbz2|tbz|tarbz2)
            echo "tar:tar:tar:.tar.bz2"
            ;;
        tar.xz|txz|tarxz)
            echo "tar:tar:tar:.tar.xz"
            ;;
        tar.zst|tzst|tarzst)
            echo "tar:tar:tar:.tar.zst"
            ;;
        tar.lz|tlz|tarlz)
            echo "tar:tar:tar:.tar.lz"
            ;;
        tar.lzma|tarlzma)
            echo "tar:tar:tar:.tar.lzma"
            ;;
        7z|7zip)
            echo "7z:p7zip:p7zip-full:.7z"
            ;;
        rar)
            echo "rar:rar:rar:.rar"
            ;;
        gz|gzip)
            echo "gzip:gzip:gzip:.gz"
            ;;
        bz2|bzip2)
            echo "bzip2:bzip2:bzip2:.bz2"
            ;;
        xz)
            echo "xz:xz:xz-utils:.xz"
            ;;
        zst|zstd)
            echo "zstd:zstd:zstd:.zst"
            ;;
        lz|lzip)
            echo "lzip:lzip:lzip:.lz"
            ;;
        lzma)
            echo "lzma:xz:xz-utils:.lzma"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Find next available filename with suffix
get_available_filename() {
    local base_path="$1"
    local extension="$2"
    local full_path="${base_path}${extension}"

    if [ ! -e "$full_path" ]; then
        echo "$full_path"
        return
    fi

    local counter=2
    while [ -e "${base_path}-${counter}${extension}" ]; do
        ((counter++))
    done

    echo "${base_path}-${counter}${extension}"
}

# Compress the file/directory
compress_target() {
    local source="$1"
    local dest="$2"
    local format="$3"
    local lowercase="${format,,}"
    local source_name="$(basename "$source")"
    local source_dir="$(dirname "$source")"

    case "$lowercase" in
        zip)
            (cd "$source_dir" && zip -rq "$dest" "$source_name")
            ;;
        tar)
            tar -cf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.gz|tgz|targz)
            tar -czf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.bz2|tbz2|tbz|tarbz2)
            tar -cjf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.xz|txz|tarxz)
            tar -cJf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.zst|tzst|tarzst)
            tar --zstd -cf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.lz|tlz|tarlz)
            tar --lzip -cf "$dest" -C "$source_dir" "$source_name"
            ;;
        tar.lzma|tarlzma)
            tar --lzma -cf "$dest" -C "$source_dir" "$source_name"
            ;;
        7z|7zip)
            7z a -bso0 -bsp0 "$dest" "$source"
            ;;
        rar)
            rar a -inul "$dest" "$source"
            ;;
        gz|gzip)
            if [ -d "$source" ]; then
                print_error "gzip cannot compress directories. Use tar.gz instead."
                return 1
            fi
            gzip -c "$source" > "$dest"
            ;;
        bz2|bzip2)
            if [ -d "$source" ]; then
                print_error "bzip2 cannot compress directories. Use tar.bz2 instead."
                return 1
            fi
            bzip2 -c "$source" > "$dest"
            ;;
        xz)
            if [ -d "$source" ]; then
                print_error "xz cannot compress directories. Use tar.xz instead."
                return 1
            fi
            xz -c "$source" > "$dest"
            ;;
        zst|zstd)
            if [ -d "$source" ]; then
                print_error "zstd cannot compress directories. Use tar.zst instead."
                return 1
            fi
            zstd -q "$source" -o "$dest"
            ;;
        lz|lzip)
            if [ -d "$source" ]; then
                print_error "lzip cannot compress directories. Use tar.lz instead."
                return 1
            fi
            lzip -c "$source" > "$dest"
            ;;
        lzma)
            if [ -d "$source" ]; then
                print_error "lzma cannot compress directories. Use tar.lzma instead."
                return 1
            fi
            lzma -c "$source" > "$dest"
            ;;
        *)
            print_error "Unknown compression format"
            return 1
            ;;
    esac
}

show_usage() {
    echo "Usage: $0 <file_or_directory> [format]"
    echo ""
    echo "Arguments:"
    echo "  file_or_directory  Path to the file or directory to compress"
    echo "  format             Compression format (default: zip)"
    echo ""
    echo "Supported formats:"
    echo "  zip                      - ZIP archive"
    echo "  tar                      - TAR archive (no compression)"
    echo "  tar.gz, tgz              - TAR + Gzip"
    echo "  tar.bz2, tbz2            - TAR + Bzip2"
    echo "  tar.xz, txz              - TAR + XZ"
    echo "  tar.zst, tzst            - TAR + Zstandard"
    echo "  tar.lz, tlz              - TAR + Lzip"
    echo "  tar.lzma                 - TAR + LZMA"
    echo "  7z                       - 7-Zip archive"
    echo "  rar                      - RAR archive"
    echo "  gz, bz2, xz, zst, lz     - Single file compression only"
    echo ""
    echo "Examples:"
    echo "  $0 mydir                 # Creates mydir.zip"
    echo "  $0 mydir tar.gz          # Creates mydir.tar.gz"
    echo "  $0 file.txt 7z           # Creates file.txt.7z"
}

# Main script
main() {
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        show_usage
        exit 1
    fi

    local source_path="$1"
    local format="${2:-zip}"

    # Check if source exists
    if [ ! -e "$source_path" ]; then
        print_error "Path not found: $source_path"
        exit 1
    fi

    # Get absolute path and remove trailing slash
    source_path="$(realpath "$source_path")"
    source_path="${source_path%/}"
    
    local source_dir="$(dirname "$source_path")"
    local source_name="$(basename "$source_path")"

    # Get compression info
    local compression_info
    compression_info=$(get_compression_info "$format")

    if [ -z "$compression_info" ]; then
        print_error "Unsupported compression format: $format"
        echo ""
        show_usage
        exit 1
    fi

    # Parse compression info
    IFS=':' read -r required_cmd arch_pkg debian_pkg extension <<< "$compression_info"

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

    # Check for additional dependencies for tar compression
    case "${format,,}" in
        tar.zst|tzst|tarzst)
            if ! command_exists "zstd"; then
                print_error "Required command 'zstd' is not installed for zstd compression."
                local distro=$(detect_distro)
                local install_cmd=$(get_install_cmd "$distro" "zstd" "zstd")
                if [ -n "$install_cmd" ]; then
                    print_warning "To install: $install_cmd"
                fi
                exit 1
            fi
            ;;
        tar.lz|tlz|tarlz)
            if ! command_exists "lzip"; then
                print_error "Required command 'lzip' is not installed for lzip compression."
                local distro=$(detect_distro)
                local install_cmd=$(get_install_cmd "$distro" "lzip" "lzip")
                if [ -n "$install_cmd" ]; then
                    print_warning "To install: $install_cmd"
                fi
                exit 1
            fi
            ;;
    esac

    # Get the output filename
    local base_path="$source_dir/$source_name"
    local output_path
    output_path=$(get_available_filename "$base_path" "$extension")

    echo "Compressing: $source_path"
    echo "     Format: $format"
    echo "     Output: $output_path"
    echo ""

    # Compress
    if compress_target "$source_path" "$output_path" "$format"; then
        local size
        size=$(du -h "$output_path" | cut -f1)
        print_success "Done! Created: $output_path ($size)"
    else
        # Cleanup on failure
        rm -f "$output_path" 2>/dev/null || true
        print_error "Compression failed"
        exit 1
    fi
}

main "$@"

