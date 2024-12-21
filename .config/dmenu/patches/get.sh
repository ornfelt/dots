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

# https://tools.suckless.org/dmenu/patches/xresources/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/xresources/dmenu-xresources-4.9.diff

# https://tools.suckless.org/dmenu/patches/alpha/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/alpha/dmenu-alpha-20230110-5.2.diff

# https://tools.suckless.org/dmenu/patches/gruvbox/
download_if_not_exists https://tools.suckless.org/dmenu/patches/gruvbox/dmenu-gruvbox-20210329-9ae8ea5.diff

# https://tools.suckless.org/dmenu/patches/mouse-support/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/mouse-support/dmenu-mousesupport-5.3.diff

# https://tools.suckless.org/dmenu/patches/emoji-highlight/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/emoji-highlight/dmenu-emoji-highlight-5.0.diff

# https://tools.suckless.org/dmenu/patches/bar_height/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/bar_height/dmenu-bar-height-5.2.diff

# https://tools.suckless.org/dmenu/patches/border/
download_if_not_exists https://tools.suckless.org/dmenu/patches/border/dmenu-border-20230512-0fe460d.diff

# https://tools.suckless.org/dmenu/patches/center/
download_if_not_exists https://tools.suckless.org/dmenu/patches/center/dmenu-center-20240616-36c3d68.diff

# https://tools.suckless.org/dmenu/patches/highlight/
download_if_not_exists https://tools.suckless.org/dmenu/patches/highlight/dmenu-highlight-20201211-fcdc159.diff

# https://tools.suckless.org/dmenu/patches/fuzzyhighlight/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/fuzzyhighlight/dmenu-fuzzyhighlight-5.3.diff

# https://tools.suckless.org/dmenu/patches/fuzzymatch/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/fuzzymatch/dmenu-fuzzymatch-5.3.diff

# https://tools.suckless.org/dmenu/patches/vi-mode/
#download_if_not_exists https://tools.suckless.org/dmenu/patches/vi-mode/dmenu-vi_mode-20230416-0fe460d.diff

