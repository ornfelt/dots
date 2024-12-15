# Example
# https://dwm.suckless.org/patches/alpha/
# curl -O https://dwm.suckless.org/patches/alpha/dwm-alpha-20230401-348f655.diff
# wget https://dwm.suckless.org/patches/alpha/dwm-alpha-20230401-348f655.diff
# python -c "import urllib.request; urllib.request.urlretrieve('https://dwm.suckless.org/patches/alpha/dwm-alpha-20230401-348f655.diff', 'dwm-alpha-20230401-348f655.diff')"
# exit 0

download_if_not_exists() {
  local url="$1"
  local filename=$(basename "$url") # Extract the file name from the URL

  # Check if the file already exists
  if [[ -f "$filename" ]]; then
    echo "File '$filename' already exists. Skipping download."
  else
    echo "Downloading '$filename'..."
    curl -O "$url"
    if [[ $? -eq 0 ]]; then
      echo "Downloaded '$filename' successfully."
    else
      echo "Failed to download '$filename'."
    fi
  fi
}

# https://dwm.suckless.org/patches/noborder/
download_if_not_exists https://dwm.suckless.org/patches/noborder/dwm-noborder-6.2.diff
#download_if_not_exists https://dwm.suckless.org/patches/noborder/dwm-noborderfloatingfix-6.2.diff
#download_if_not_exists https://dwm.suckless.org/patches/noborder/dwm-noborderselflickerfix-2022042627-d93ff48803f0.diff

# https://dwm.suckless.org/patches/stackmfact/
download_if_not_exists https://dwm.suckless.org/patches/stackmfact/dwm-6.0-smfact.diff

# https://dwm.suckless.org/patches/notitle/
download_if_not_exists https://dwm.suckless.org/patches/notitle/dwm-notitle-20210715-138b405.diff

# https://dwm.suckless.org/patches/sticky/
download_if_not_exists https://dwm.suckless.org/patches/sticky/dwm-sticky-20240927-60f7034.diff

# https://dwm.suckless.org/patches/actualfullscreen/
download_if_not_exists https://dwm.suckless.org/patches/actualfullscreen/dwm-actualfullscreen-20211013-cb3f58a.diff

# https://dwm.suckless.org/patches/tagshift/
download_if_not_exists https://dwm.suckless.org/patches/tagshift/dwm-tagshift-6.3.diff

# https://dwm.suckless.org/patches/statuscmd/
#download_if_not_exists https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-20241009-8933ebc.diff
download_if_not_exists https://dwm.suckless.org/patches/statuscmd/dwm-statuscmd-status2d-20210405-60bb3df.diff

# https://dwm.suckless.org/patches/swallow/
download_if_not_exists https://dwm.suckless.org/patches/swallow/dwm-swallow-6.3.diff

# https://dwm.suckless.org/patches/xresources/
download_if_not_exists https://dwm.suckless.org/patches/xresources/dwm-xresources-20210827-138b405.diff

# https://dwm.suckless.org/patches/hide_vacant_tags/
download_if_not_exists https://dwm.suckless.org/patches/hide_vacant_tags/dwm-hide_vacant_tags-6.4.diff

# https://dwm.suckless.org/patches/stacker/
download_if_not_exists https://dwm.suckless.org/patches/stacker/dwm-stacker-6.2.diff

# https://dwm.suckless.org/patches/vanitygaps/
#download_if_not_exists https://dwm.suckless.org/patches/vanitygaps/dwm-vanitygaps-20190508-6.2.diff
#download_if_not_exists https://dwm.suckless.org/patches/vanitygaps/dwm-vanitygaps-6.2.diff
#download_if_not_exists https://dwm.suckless.org/patches/vanitygaps/dwm-cfacts-vanitygaps-6.2.diff
download_if_not_exists https://dwm.suckless.org/patches/vanitygaps/dwm-cfacts-vanitygaps-6.4_combo.diff

# https://dwm.suckless.org/patches/autostart/
download_if_not_exists https://dwm.suckless.org/patches/autostart/dwm-autostart-20210120-cb3f58a.diff

# https://dwm.suckless.org/patches/scratchpad/
#download_if_not_exists https://dwm.suckless.org/patches/scratchpad/dwm-scratchpad-20240321-061e9fe.diff

#https://dwm.suckless.org/patches/scratchpads/
download_if_not_exists https://dwm.suckless.org/patches/scratchpads/dwm-scratchpads-20200414-728d397b.diff

# https://dwm.suckless.org/patches/focusonclick/
download_if_not_exists https://dwm.suckless.org/patches/focusonclick/dwm-focusonclick-20200110-61bb8b2.diff

# https://dwm.suckless.org/patches/save_floats/
download_if_not_exists https://dwm.suckless.org/patches/save_floats/dwm-savefloats-20181212-b69c870.diff

# https://dwm.suckless.org/patches/status2d/
#download_if_not_exists https://dwm.suckless.org/patches/status2d/dwm-status2d-systray-6.4.diff
download_if_not_exists https://dwm.suckless.org/patches/status2d/dwm-status2d-6.3.diff

