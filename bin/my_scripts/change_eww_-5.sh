#! /bin/bash
# sed -i 's/word1/word2/g' input.file

echo "Processing eww file..."

sed -i 's/y "135px"/y "130px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "105px"/y "100px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "490px"/y "485px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "685px"/y "680px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "615px"/y "610px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "535px"/y "530px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "335px"/y "330px"/g' ~/.config/eww/eww.yuck
sed -i 's/y "433px"/y "428px"/g' ~/.config/eww/eww.yuck

echo "Done..."
