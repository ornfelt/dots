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

# https://st.suckless.org/patches/font2/
download_if_not_exists https://st.suckless.org/patches/font2/st-font2-0.8.5.diff

# https://st.suckless.org/patches/scrollback/
download_if_not_exists https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff
download_if_not_exists https://st.suckless.org/patches/scrollback/st-scrollback-mouse-0.9.2.diff
# More efficient scrolling
#download_if_not_exists https://st.suckless.org/patches/scrollback/st-scrollback-ringbuffer-0.9.2.diff

# https://st.suckless.org/patches/xresources/
download_if_not_exists https://st.suckless.org/patches/xresources/st-xresources-20200604-9ba7ecf.diff

# https://st.suckless.org/patches/alpha/
download_if_not_exists https://st.suckless.org/patches/alpha/st-alpha-20240814-a0274bc.diff

# https://st.suckless.org/patches/ligatures/
download_if_not_exists https://st.suckless.org/patches/ligatures/0.9.2/st-ligatures-alpha-scrollback-20240427-0.9.2.diff
#download_if_not_exists https://st.suckless.org/patches/ligatures/0.9.2/st-ligatures-alpha-scrollback-ringbuffer-20240427-0.9.2.diff
#download_if_not_exists https://st.suckless.org/patches/ligatures/0.9.2/st-ligatures-boxdraw-20240427-0.9.2.diff

# https://st.suckless.org/patches/boxdraw/
#download_if_not_exists https://st.suckless.org/patches/boxdraw/st-boxdraw_v2-0.8.5.diff

# https://st.suckless.org/patches/workingdir/
download_if_not_exists https://st.suckless.org/patches/workingdir/st-workingdir-20200317-51e19ea.diff

# https://st.suckless.org/patches/changealpha/
download_if_not_exists https://st.suckless.org/patches/changealpha/st-changealpha-20230519-b44f2ad.diff

# https://st.suckless.org/patches/externalpipe/
download_if_not_exists https://st.suckless.org/patches/externalpipe/st-externalpipe-0.8.5.diff

