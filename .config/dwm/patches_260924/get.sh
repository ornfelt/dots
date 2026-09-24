#!/usr/bin/env bash
# Newest versions (checked 2026-09-24) of the dwm patches used by the dwmr (Rust) port.
# See the "Porting plan: dwmr" section in $my_notes_path/linux/dwm_customizations.md.
# Only patches that the port needs are listed; cfacts, alpha, smfact and autostart are left out.
# Run from this directory: ./get.sh

download_if_not_exists() {
  local url="$1"
  local filename=$(basename "$url") # Extract the file name from the URL

  # Check if the file already exists
  if [[ -f "$filename" ]]; then
    echo "File '$filename' already exists. Skipping download."
  else
    echo "Downloading '$filename'..."
    curl -fsSLO "$url"
    if [[ $? -eq 0 ]]; then
      echo "Downloaded '$filename' successfully."
    else
      echo "Failed to download '$filename'."
    fi
  fi
}

# 1. https://dwm.suckless.org/patches/actualfullscreen/ (newer: 6.8; only togglefullscr is used, not the isfullscreen rule)
download_if_not_exists https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-6.8.diff
# 2. https://dwm.suckless.org/patches/focusonclick/ (newer: based on 44dbc68, same base as dwmr)
download_if_not_exists https://dwm.suckless.org/patches/focusonclick/dwm-focusonclick-20260516-44dbc68.diff
# 3. https://dwm.suckless.org/patches/notitle/ (newer: 6.5)
download_if_not_exists https://dwm.suckless.org/patches/notitle/dwm-notitle-6.5.diff
# 4. https://dwm.suckless.org/patches/hide_vacant_tags/
download_if_not_exists https://dwm.suckless.org/patches/hide_vacant_tags/dwm-hide_vacant_tags-6.4.diff
# 5. https://dwm.suckless.org/patches/noborder/
download_if_not_exists https://dwm.suckless.org/patches/noborder/dwm-noborder-6.2.diff
# 6. https://dwm.suckless.org/patches/save_floats/
download_if_not_exists https://dwm.suckless.org/patches/save_floats/dwm-savefloats-20181212-b69c870.diff
# 6. https://dwm.suckless.org/patches/togglefloatingcenter/
download_if_not_exists https://dwm.suckless.org/patches/togglefloatingcenter/dwm-togglefloatingcenter-20210806-138b405f.diff
# 7. https://dwm.suckless.org/patches/stacker/ (newer: 6.6)
download_if_not_exists https://dwm.suckless.org/patches/stacker/dwm-stacker-6.6.diff
# 8. https://dwm.suckless.org/patches/sticky/ (same content as dwm-sticky-20240927-60f7034.diff)
download_if_not_exists https://dwm.suckless.org/patches/sticky/dwm-sticky-6.5.diff
# 9. https://dwm.suckless.org/patches/scratchpads/
download_if_not_exists https://dwm.suckless.org/patches/scratchpads/dwm-scratchpads-20200414-728d397b.diff
# 10. https://dwm.suckless.org/patches/tagshift/ and https://dwm.suckless.org/patches/shift-tools/
download_if_not_exists https://dwm.suckless.org/patches/tagshift/dwm-tagshift-6.3.diff
download_if_not_exists https://dwm.suckless.org/patches/shift-tools/shift-tools-scratchpads.c
# 11. https://dwm.suckless.org/patches/vanitygaps/
download_if_not_exists https://dwm.suckless.org/patches/vanitygaps/dwm-cfacts-vanitygaps-6.4_combo.diff
# 12. https://dwm.suckless.org/patches/swallow/
download_if_not_exists https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff
# 13. https://dwm.suckless.org/patches/status2d/
download_if_not_exists https://dwm.suckless.org/patches/status2d/dwm-status2d-6.3.diff
# 14. https://dwm.suckless.org/patches/statuscmd/ (the status2d variant is still the newest one for status2d)
download_if_not_exists https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-status2d-20210405-60bb3df.diff
# 15. https://dwm.suckless.org/patches/xresources/ (newer: based on 44dbc68, with runtime reload and font)
download_if_not_exists https://dwm.suckless.org/patches/xresources/dwm-xresources-20260524-44dbc68.diff
