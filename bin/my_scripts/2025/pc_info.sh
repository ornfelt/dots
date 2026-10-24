#!/usr/bin/env bash
# pc_info.sh - OS name and version plus general OS/PC info, then the PC specs:
# CPU, RAM, GPU, storage, network and battery. Everything is read from /etc,
# /proc, /sys (DMI, drm, net, power_supply), udev and the usual util-linux /
# iproute2 tools, no root needed.
# Linux counterpart of windows_dots/my_scripts/pc_info.ps1.
#
# Usage:
#   pc_info.sh

set -uo pipefail

# ------------------------------------------------------------------ colors --
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RESET=$'\033[0m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    CYAN=$'\033[36m'
    MAGENTA=$'\033[35m'
    GRAY=$'\033[37m'
else
    RESET='' GREEN='' YELLOW='' CYAN='' MAGENTA='' GRAY=''
fi

write_ok()      { printf '%s%s%s\n' "$GREEN"  "$1" "$RESET"; }
write_warn()    { printf '%s%s%s\n' "$YELLOW" "$1" "$RESET"; }
write_info()    { printf '%s%s%s\n' "$CYAN"   "$1" "$RESET"; }
write_section() { printf '\n%s== %s ==%s\n' "$MAGENTA" "$1" "$RESET"; }

# --------------------------------------------------------------- constants --
# width of the label column in the "label: value" lines
readonly LABEL_WIDTH=18
readonly GB=1073741824
readonly MB=1048576
# volumes at or above this use are printed as a warning
readonly FULL_PERCENT=90
# how long /proc/stat is sampled for the CPU load
readonly LOAD_SAMPLE_SECONDS=0.5
readonly UNKNOWN_TEXT="?"
readonly DMI_DIR="/sys/class/dmi/id"
readonly DRM_DIR="/sys/class/drm"
readonly NET_DIR="/sys/class/net"
readonly POWER_SUPPLY_DIR="/sys/class/power_supply"
readonly CPU0_DIR="/sys/devices/system/cpu/cpu0"

have() { command -v "$1" >/dev/null 2>&1; }

# prints the file's first line, or nothing when it is missing or unreadable
read_file() { [[ -r "$1" ]] && head -n 1 "$1" 2>/dev/null; }

# "label: value", the label padded to LABEL_WIDTH; $3 = color of the value
write_field() {
    printf '%s  %-*s%s %s%s%s\n' "$GRAY" "$LABEL_WIDTH" "$1:" "$RESET" "${3:-}" "${2:-$UNKNOWN_TEXT}" "${3:+$RESET}"
}

format_gb() { awk -v b="${1:-0}" -v gb="$GB" 'BEGIN { printf "%.1f GB", b / gb }'; }

format_uptime() {
    local s=$1
    printf '%dd %dh %dm' $(( s / 86400 )) $(( s % 86400 / 3600 )) $(( s % 3600 / 60 ))
}

# udev property NAME of a sysfs path
udev_prop() {
    have udevadm || return
    udevadm info -q property -p "$1" 2>/dev/null | awk -F= -v k="$2" '$1 == k { sub(/^[^=]*=/, ""); print; exit }'
}

# vendor + model of a PCI / USB device from the hwdb, by its sysfs path
device_name() {
    local vendor model
    vendor="$(udev_prop "$1" ID_VENDOR_FROM_DATABASE)"
    model="$(udev_prop "$1" ID_MODEL_FROM_DATABASE)"
    printf '%s' "$(echo "$vendor $model" | xargs)"
}

# DMI fields vendors fill with placeholders when they have nothing to say
dmi_value() {
    local v
    v="$(read_file "$DMI_DIR/$1" | xargs)"
    case "$v" in
        ""|"None"|"Default string"|"To be filled by O.E.M."|"System Product Name"|"Not Applicable") ;;
        *) printf '%s' "$v" ;;
    esac
}

# SMBIOS chassis type number to its name (the common ones)
chassis_name() {
    case "$1" in
        3) echo "Desktop" ;;        4) echo "Low profile desktop" ;;
        6) echo "Mini tower" ;;     7) echo "Tower" ;;
        8) echo "Portable" ;;       9) echo "Laptop" ;;
        10) echo "Notebook" ;;      11) echo "Hand held" ;;
        13) echo "All in one" ;;    14) echo "Sub notebook" ;;
        30) echo "Tablet" ;;        31) echo "Convertible" ;;
        32) echo "Detachable" ;;    35) echo "Mini PC" ;;
        36) echo "Stick PC" ;;      *) echo "" ;;
    esac
}

# idle and total jiffies of all CPUs, from the first line of /proc/stat
cpu_jiffies() {
    awk '/^cpu / { idle = $5 + $6; total = 0; for (i = 2; i <= NF; i++) total += $i; print idle, total; exit }' /proc/stat
}

lscpu_field() { lscpu 2>/dev/null | awk -F: -v k="$1" '$1 == k { sub(/^[^:]*:[ \t]*/, ""); print; exit }'; }

# ---------------------------------------------------------------- OS
# shellcheck disable=SC1091
[[ -r /etc/os-release ]] && . /etc/os-release
write_section "Operating system"
write_field "OS" "${PRETTY_NAME:-$(uname -o)}"
version="${VERSION:-${VERSION_ID:-}}"
[[ -n "${DEBIAN_VERSION_FULL:-}" ]] && version="$DEBIAN_VERSION_FULL${VERSION_CODENAME:+ ($VERSION_CODENAME)}"
write_field "Version" "$version"
write_field "Kernel version" "$(uname -r)"
write_field "Architecture" "$(uname -m)"
write_field "Distro ID" "${ID:-}${ID_LIKE:+ (like $ID_LIKE)}"
# the root filesystem's birth time is the closest thing to an install date
birth="$(stat -c %W / 2>/dev/null)"
if [[ -n "$birth" && "$birth" != "0" ]]; then
    write_field "Installed" "$(date -d "@$birth" '+%Y-%m-%d %H:%M')"
else
    write_field "Installed" ""
fi
write_field "Last boot" "$(date -d "$(uptime -s)" '+%Y-%m-%d %H:%M')"
write_field "Uptime" "$(format_uptime "$(cut -d. -f1 /proc/uptime)")"
[[ -d /sys/firmware/efi ]] && firmware="UEFI" || firmware="Legacy BIOS"
write_field "Firmware" "$firmware"
write_field "Init" "$(ps -p 1 -o comm= 2>/dev/null)"
session="$(echo "${XDG_CURRENT_DESKTOP:-none}${XDG_SESSION_TYPE:+ ($XDG_SESSION_TYPE)}" | xargs)"
write_field "Desktop" "$session"
write_field "Locale" "${LC_ALL:-${LANG:-}}"
tz="$(timedatectl show -p Timezone --value 2>/dev/null)"
[[ -z "$tz" ]] && tz="$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')"
write_field "Time zone" "$tz ($(date +%Z), UTC$(date +%:z))"
write_field "Shell" "${SHELL:-} (this script: bash $BASH_VERSION)"

# ---------------------------------------------------------------- PC
write_section "Computer"
write_field "Name" "$(hostname)"
write_field "User" "$(id -un) (uid $(id -u))"
domain="$(hostname -d 2>/dev/null)"
write_field "Domain" "${domain:-none}"
write_field "Manufacturer" "$(dmi_value sys_vendor)"
# Lenovo and a few others put the readable model name in product_version
product="$(dmi_value product_name)"
product_version="$(dmi_value product_version)"
if [[ -n "$product_version" && "$product_version" != "$product" ]]; then
    write_field "Model" "$product_version ($product)"
else
    write_field "Model" "$product"
fi
chassis="$(chassis_name "$(read_file "$DMI_DIR/chassis_type")")"
write_field "System type" "$(uname -m)${chassis:+, $chassis}"
write_field "Motherboard" "$(echo "$(dmi_value board_vendor) $(dmi_value board_name)" | xargs)"
# bios_date is mm/dd/yyyy
bios_date="$(read_file "$DMI_DIR/bios_date" | awk -F/ 'NF == 3 { print $3 "-" $1 "-" $2 }')"
write_field "BIOS" "$(dmi_value bios_vendor) $(dmi_value bios_version)${bios_date:+ ($bios_date)}"

# ---------------------------------------------------------------- CPU
write_section "CPU"
read -r idle0 total0 < <(cpu_jiffies)
sleep "$LOAD_SAMPLE_SECONDS"
read -r idle1 total1 < <(cpu_jiffies)
write_field "Name" "$(lscpu_field "Model name")"
sockets="$(lscpu_field "Socket(s)")"
cores=$(( $(lscpu_field "Core(s) per socket") * ${sockets:-1} ))
write_field "Cores / threads" "$cores / $(nproc --all)"
# intel_pstate exposes the base clock, amd-pstate the CPPC nominal one (MHz)
base_khz="$(read_file "$CPU0_DIR/cpufreq/base_frequency")"
[[ -z "$base_khz" ]] && nominal_mhz="$(read_file "$CPU0_DIR/acpi_cppc/nominal_freq")" && [[ -n "$nominal_mhz" ]] && base_khz=$(( nominal_mhz * 1000 ))
[[ -n "$base_khz" ]] && write_field "Base clock" "$(awk -v k="$base_khz" 'BEGIN { printf "%.2f GHz", k / 1e6 }')"
max_khz="$(read_file "$CPU0_DIR/cpufreq/cpuinfo_max_freq")"
[[ -n "$max_khz" ]] && write_field "Max clock" "$(awk -v k="$max_khz" 'BEGIN { printf "%.2f GHz", k / 1e6 }')"
cache_bytes() { lscpu -B -C=NAME,ALL-SIZE 2>/dev/null | awk -v n="$1" '$1 == n { print $2 }'; }
write_field "L2 / L3 cache" "$(awk -v l2="$(cache_bytes L2)" -v l3="$(cache_bytes L3)" -v mb="$MB" \
    'BEGIN { printf "%g MB / %g MB", int(l2 / mb * 10 + 0.5) / 10, int(l3 / mb * 10 + 0.5) / 10 }')"
write_field "Sockets" "${sockets:-}"
write_field "Load" "$(( (100 * ((total1 - total0) - (idle1 - idle0))) / ((total1 - total0) ? (total1 - total0) : 1) ))%"
virt_ext="$(lscpu_field "Virtualization")"
guest="$(systemd-detect-virt --vm 2>/dev/null)"
if [[ -n "$guest" && "$guest" != "none" ]]; then
    virt="running as a VM guest ($guest)"
elif [[ -e /dev/kvm ]]; then
    virt="enabled (${virt_ext:-kvm}, /dev/kvm present)"
elif [[ -n "$virt_ext" ]]; then
    virt="supported ($virt_ext), kvm not loaded"
else
    virt="disabled"
fi
write_field "Virtualization" "$virt"

# ---------------------------------------------------------------- RAM
write_section "Memory (RAM)"
total=$(( $(awk '/^MemTotal:/ { print $2 }' /proc/meminfo) * 1024 ))
free=$(( $(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo) * 1024 ))
used=$(( total - free ))
# the modules come from the SMBIOS memory devices udev imports onto the DMI node
dmi_props="$(have udevadm && udevadm info -q property -p /sys/devices/virtual/dmi/id 2>/dev/null)"
mem_prop() { awk -F= -v k="$1" '$1 == k { sub(/^[^=]*=/, ""); print; exit }' <<< "$dmi_props"; }
module_ids=()
installed=0
for id in $(grep -oE '^MEMORY_DEVICE_[0-9]+_SIZE=' <<< "$dmi_props" | grep -oE '[0-9]+' | sort -n); do
    size="$(mem_prop "MEMORY_DEVICE_${id}_SIZE")"
    (( size > 0 )) || continue
    module_ids+=("$id")
    installed=$(( installed + size ))
done
# without module data, the online memory blocks are the next best count
(( installed )) || installed="$(lsmem -b --summary=only 2>/dev/null | awk -F: '/online memory/ { gsub(/ /, "", $2); print $2; exit }')"
# installed is what the modules add up to; usable is that minus what the
# firmware, the kernel and an integrated GPU reserve
write_field "Installed" "$(format_gb "$installed")"
write_field "Usable" "$(format_gb "$total")"
write_field "In use" "$(format_gb "$used") ($(( used * 100 / total ))%)"
write_field "Available" "$(format_gb "$free")"
write_field "Slots used" "${#module_ids[@]} of $(mem_prop MEMORY_ARRAY_NUM_DEVICES)"
i=0
for id in "${module_ids[@]}"; do
    i=$(( i + 1 ))
    p="MEMORY_DEVICE_${id}"
    rated="$(mem_prop "${p}_SPEED_MTS")"
    configured="$(mem_prop "${p}_CONFIGURED_SPEED_MTS")"
    # the configured speed is what it runs at, the plain one is the module's rated speed
    if [[ -n "$configured" ]]; then speed="$configured MT/s (rated $rated)"; else speed="$rated MT/s"; fi
    # soldered memory often gives every module the same locator, so number them
    write_field "  Module $i" "$(format_gb "$(mem_prop "${p}_SIZE")") $(mem_prop "${p}_TYPE"), $speed, $(mem_prop "${p}_MANUFACTURER") $(mem_prop "${p}_PART_NUMBER") [$(echo "$(mem_prop "${p}_BANK_LOCATOR") $(mem_prop "${p}_LOCATOR")" | xargs)]"
done
(( ${#module_ids[@]} )) || write_warn "  no per-module data (udev has no SMBIOS memory info; sudo dmidecode -t memory has it)"

# ---------------------------------------------------------------- GPU
write_section "GPU"
# current modes of the X screen's outputs (XWayland under wayland), output -> mode
declare -A x_modes=()
if [[ -n "${DISPLAY:-}" ]] && have xrandr; then
    while read -r out mode; do x_modes["$out"]="$mode"; done < <(xrandr --current 2>/dev/null | awk '
        / connected/ { out = $1 }
        /\*/ && out != "" { for (i = 2; i <= NF; i++) if ($i ~ /\*/) { r = $i; gsub(/[*+]/, "", r); print out, $1 " @ " r " Hz"; break }; out = "" }')
fi
for card in "$DRM_DIR"/card[0-9]*; do
    [[ "${card##*/}" =~ ^card[0-9]+$ && -e "$card/device" ]] || continue
    dev="$(readlink -f "$card/device")"
    write_info "  $(device_name "$dev")"
    driver="$(basename "$(readlink "$dev/driver")" 2>/dev/null)"
    vram="$(read_file "$dev/mem_info_vram_total")"
    if [[ -z "$vram" && "$driver" == "nvidia" ]] && have nvidia-smi; then
        vram="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i "${dev##*/}" 2>/dev/null | awk '{ print $1 * 1048576 }')"
    fi
    write_field "Memory" "$( [[ -n "$vram" ]] && format_gb "$vram" || echo "shared / unknown")"
    driver_version="$(read_file /proc/driver/nvidia/version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    [[ "$driver" == "nvidia" && -n "$driver_version" ]] || driver_version="in-tree, kernel $(uname -r)"
    write_field "Driver" "${driver:-none} ($driver_version)"
    for conn in "$card"-*; do
        [[ "$(read_file "$conn/status")" == "connected" ]] || continue
        name="${conn##*/${card##*/}-}"
        # xrandr drops the -1 from some names (eDP-1 is eDP on amdgpu)
        mode="${x_modes[$name]:-${x_modes[${name%-*}]:-}}"
        [[ -n "$mode" ]] || mode="$(read_file "$conn/modes") (preferred)"
        write_field "Mode $name" "$mode"
    done
    write_field "Power state" "$(read_file "$dev/power_state")"
done
if [[ -n "${DISPLAY:-}" ]] && have glxinfo; then
    glx="$(glxinfo -B 2>/dev/null)"
    write_field "OpenGL renderer" "$(awk -F': ' '/OpenGL renderer string/ { print $2; exit }' <<< "$glx")"
    write_field "OpenGL version" "$(awk -F': ' '/OpenGL version string/ { print $2; exit }' <<< "$glx")"
fi

# ---------------------------------------------------------------- storage
write_section "Storage"
while read -r line; do
    eval "$line"
    if [[ "$ROTA" == "1" ]]; then media="HDD"; else media="SSD"; fi
    write_field "Disk $NAME" "${MODEL:-$UNKNOWN_TEXT}, $(format_gb "$SIZE"), $media ${TRAN^^}"
done < <(lsblk -d -b -n -P -o NAME,MODEL,SIZE,ROTA,TRAN,TYPE 2>/dev/null | grep 'TYPE="disk"' | grep -v '^NAME="zram')
while read -r src fstype size avail target; do
    [[ "$src" == /dev/* ]] || continue
    pct=$(( size ? (size - avail) * 100 / size : 0 ))
    label="$(lsblk -n -o LABEL "$src" 2>/dev/null | head -n 1)"
    line="$(format_gb "$avail") free of $(format_gb "$size") ($pct% used), $fstype${label:+ $label} [$src]"
    if (( pct >= FULL_PERCENT )); then write_field "$target" "$line" "$YELLOW"; else write_field "$target" "$line"; fi
done < <(df -B1 -l --output=source,fstype,size,avail,target 2>/dev/null | tail -n +2)

# ---------------------------------------------------------------- network
write_section "Network"
for ifc in $(ip -o link show up 2>/dev/null | awk -F': ' '/LOWER_UP/ && !/LOOPBACK/ { sub(/@.*/, "", $2); print $2 }' | sort); do
    path="$NET_DIR/$ifc"
    if [[ -e "$path/device" ]]; then
        desc="$(device_name "$(readlink -f "$path/device")")"
        [[ -n "$desc" ]] || desc="$(basename "$(readlink "$path/device/driver")")"
    elif [[ -e "$path/tun_flags" ]]; then
        desc="virtual (tun)"
    else
        desc="virtual"
    fi
    if [[ -d "$path/wireless" ]] && have iw; then
        link="$(iw dev "$ifc" link 2>/dev/null | awk -F': ' '/tx bitrate/ { split($2, a, " "); r = a[1] " " a[2] } /SSID/ { s = $2 } END { print r (s != "" ? " (" s ")" : "") }')"
    else
        speed="$(read_file "$path/speed")"
        if [[ -n "$speed" && "$speed" -gt 0 ]] 2>/dev/null; then link="$speed Mbps"; else link="no link speed"; fi
    fi
    mac="$(read_file "$path/address")"
    [[ -z "$mac" || "$mac" == "00:00:00:00:00:00" ]] && mac="no MAC"
    ip4="$(ip -4 -o addr show dev "$ifc" 2>/dev/null | awk '{ sub(/\/.*/, "", $4); print $4; exit }')"
    write_field "$ifc" "$desc, ${link:-$UNKNOWN_TEXT}, $mac, ${ip4:-no IPv4}"
done

# ---------------------------------------------------------------- battery
batteries=()
for b in "$POWER_SUPPLY_DIR"/*; do
    [[ "$(read_file "$b/type")" == "Battery" ]] && batteries+=("$b")
done
if (( ${#batteries[@]} )); then
    write_section "Battery"
    for b in "${batteries[@]}"; do
        write_field "${b##*/}" "$(read_file "$b/capacity")% ($(read_file "$b/status"))"
    done
fi

echo
write_ok "Done."
