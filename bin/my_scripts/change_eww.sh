#! /bin/bash
# sed -i 's/word1/word2/g' input.file

echo "Processing eww file..."

sed -i 's/y "135px"/y "160px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "105px"/y "130px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "490px"/y "515px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "685px"/y "710px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "615px"/y "640px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "535px"/y "560px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "335px"/y "360px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "433px"/y "458px"/g' ~/.config/eww/eww.yuck

echo "Done..."
