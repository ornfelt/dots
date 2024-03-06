#! /bin/bash

# You can skip rtl8852be-dkms-git / rtw89... and 
# replace picom-pijulius-git with regular picom if you wish...

# Other optional packages:
# lf, bat
# Not sure if these are required for lf previews: ffmpegthumbnailer, epub-thumbnailer-git, chafa

# Other picom animation repos:
# https://github.com/dccsillag/picom
# https://github.com/jonaburg/picom

#for x in $(cat packages.txt); do yay -S --noconfirm $x; done

for x in $(cat pk1); do yay -S --noconfirm $x; done
sleep 5
for x in $(cat pk2); do yay -S --noconfirm $x; done
sleep 5
for x in $(cat pk3); do yay -S --noconfirm $x; done
