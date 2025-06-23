#!/bin/bash

move_files() {
    local only_mkv="$1"
    sleep 30
    for file in *; do
        if [[ -f "$file" ]]; then
            if [[ "$only_mkv" == "true" && "$file" == *.mkv ]]; then
                #sudo mv "$file" /media2/my_files/my_docs/youtube/new/
                #sudo rsync -a --remove-source-files "$file" /media2/my_files/my_docs/youtube/new/
                sudo cp "$file" /media2/my_files/my_docs/youtube/new/
                rm "$file"
            elif [[ "$only_mkv" != "true" && "$file" != *.sh ]]; then
                #sudo mv "$file" /media2/my_files/my_docs/youtube/new/
                #sudo rsync -a --remove-source-files "$file" /media2/my_files/my_docs/youtube/new/
                sudo cp "$file" /media2/my_files/my_docs/youtube/new/
                rm "$file"
            fi
        fi
    done
}

# Aerospark 4 (WotLK) Fire Mage PvP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=WC0WVVXHY4k" &&

# Random 3 [Unfinished]
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=OD85Hnz2uyw" &&

# WoW 80 Wotlk Chinese Mage PvP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=B37cH_Nc8Ak" &&

#move_files false

# World of Warcraft: Rainfalls - LVL 80 Frost Mage World PvP / WotLK
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=OR-bIxvAzR0" &&

# Vanilla Flashback 5 - Naxxramas Frost Mage PvP (1.12.1)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=v_OoUNtunIw" &&

# shaman

# Elemental shaman 5.3 wow pvp montage (roarrage 6)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=N049IjM4Cfs" &&
#
#move_files false
#
## Castiiel 2 Elemental Shaman PvP 5.4 Movie
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=UNl0Crb9_T4" &&
#
## Elemental Shaman PvP BG Domination Montage 5.4
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=S8IIZ13L24k" &&
#
## Castiiel Elemental Shaman PvP 5.4 Movie, 1vX, High Rated Arena, RBG, BG's
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=d2ComIws-r8" &&
#
#move_files false
#
## Bra the Ele | Shadowlands | Elemental shaman PVP Video
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=1R9swPP1QDU" &&
#
## WOTLK lvl 80 elemental Shaman PvP Khim
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=iNZIJ_Le-nE" &&
#
## Classic Ele Shaman PvP | Bra the Ele | Re-Origin
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=WQiBexvbLeY" &&
#
#move_files false
#
## A Shaman Playlist (World of Warcraft PvP)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=usE1EbRbazM" &&
#
## Devils Shaman - SoM PvP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=z00VKHWutg4" &&
#
## TBC Beta Arenas Expectation Vs Reality Ele Shaman
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=JsOUDuoMVdE" &&
#
#move_files false
#
## WoW TBC PVP Elemental Shaman - random arena/bg highlights
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=G1yNfVJzKgo" &&
#
## TBC Elemental Shaman 2v2 Arena PvP! With Live Comms!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=xAO65ZrVI3c" &&
#
## Black Temple All Bosses | Elemental Shaman POV | TBC Phase 4 | #97
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=wOrNcgN1VyY" &&
#
#move_files false
#
## TBC Elemental Shaman 2v2 Arena PVP - Live Comms & Road to 2k - Ele Shaman + Frost Mage
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=aPF8pZQVb24" &&
#
## Elemental Shaman vs Demon Hunter Duels - Legion PvP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=hqZSHEJ6YWw" &&
#
#move_files false
#
## Live Vanilla Elemental Shaman Duels!!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=dAzJqQ6QL0M" &&
#
## xar
#
## Xaryu with the INSANE vanilla PVP comeback!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=MsWHzb_WhJI" &&
#
#move_files false
#
## Rivah III - Classic TBC Frost Mage Arena | Endless 2.4.3
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=XefN0CSt2gQ" &&
#
## Noob Frost Mage Shatter Crits: WoW TBC Classic Frost Mage Battleground and World PvP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=7dXM8rqFv3c" &&
#
#move_files false

# xar_hansol (mop and above)

# FIRE MAGE PVP MOVIE - HANSOL 4 [5.4]
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=MThFyrvzsFQ" &&

# FIRE MAGE PVP MOVIE - HANSOL 5 [6.2]
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=YAyJIvONms8" &&

# this is what 18 YEARS of mage looks like
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=s17_1aCz3QY" &&

# A really painful 1v2 Loss... for them
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=EzHxvGtky7M" &&

# I did the Imposssible -- the PERFECT 6-0 Solo Shuffle Match
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=jitokV6svqk" &&

# I Just Hit Rank 1... In the World
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=Fp4PqTUjo98" &&

# Pulling off the 1v2 on the Mage AND the ROGUE?!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=RrwXzEbaF9c" &&

# Destroying EVERY Pillager in CLASSIC HARDCORE (i'm so addicted)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=A5A8Gb46m7o" &&

# The Absolute BEST 1v2 I Have EVER Done!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=xh7MJpVIa0w" &&

# 16 Minutes of INSANE 1v2's
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=iax0Qdf4JSQ" &&

# INSANE 1v2 Fire Mage Arena Games!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=u1n9StCm_d4" &&

# XARYU INSANE 1v2 (IT'S LONG)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=iYPtOeq8Er0" &&

# Xaryu vs. Pikaboo (THE ONE MILLION GOLD DUEL)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=mr5YmTQRjJk" &&

# Xaryu's 1v2 against Jahmilli & Abn
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=EXgTIJ11CbA" &&

# classic / tbc / wotlk

# Mega Compilation of SHANNON CLASSIC HARDCORE Leveling Journey (1 to 30)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=_PmLlMj6dDw" &&
#
## classic:
#
## Taking a closer look at my Mage vs Shaman duel in the Classic Duelers League...
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=PDphBIH09_E" &&
#
#move_files false
#
## Classic Duelers Breakdown: Xaryu vs Samiyam
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=4L0FPmRc6W0" &&
#
## Xaryu with the INSANE 1 vs 5! (WORLD PVP MONTAGE)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=X4A-LgmMjlc" &&
#
#move_files false
#
## Xaryu with the INSANE vanilla PVP comeback!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=MsWHzb_WhJI" &&
#
## Dueling ANYONE for GOLD (and I Just Dinged 60)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=uZOk5sdJU1g" &&
#
#move_files false
#
## tbc:
#
## Xaryu & Hydra Playing TBC ARENA! (MAGE PRIEST DREAM TEAM?!)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=IHKf1ldgpt8" &&
#
## So We Got World First 2200 Rating in TBC... (PART 0-1900)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=VB6YlMfuATU" &&
#
#move_files false
#
## So We Got World First 2200 Rating in TBC... (FINAL PART)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=l_be_tgCy3Q" &&
#
## Xaryu Realises Why TBC PvP Is So Unique (And More Arena With Pikaboo)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=QL8sYAM28Qs" &&
#
#move_files false
#
## INSANE DUELS in THE BURNING CRUSADE!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=9wzmvSjjUzY" &&
#
## Xaryu Shares Funny Stories While playing TBC Arena…
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=JU0lh0SD51Y" &&
#
#move_files false
#
## Rank 1 Frost Mage PvP Talents Guide (CLASSIC TBC)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=C-VRrlbxv_c" &&
#
## A Mage Challenged Xaryu to a 2000 GOLD duel (NEVER BEEN SO CLOSE!)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=lFQSrXMcfso" &&
#
#move_files false
#
## wotlk:
#
## Xaryu got DESTROYED by a WOW LEGEND.. (WOTLK ARENA'S)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=CkvyE8qAtmc" &&
#
## Practicing for the $40,000 dueling tournament!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=9DID-v722lw" &&
#
#move_files false

# Xaryu DESTROYING WARLOCKS in duels
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=XKUcsTHkDdg" &&
#
## The HARDEST match up for me... (Classic WoW)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=8678CssUkdA" &&
#
#move_files false
#
## Doing the IMPOSSIBLE in Classic!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=rnbCSe_8eL8" &&
#
## The secrets to BEATING another mage..
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=F3EwbP681aw" &&
#
#move_files false
#
## Xaryu with the INSANE vanilla PVP comeback!
##yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=MsWHzb_WhJI" &&
#
## All The Classic Addons I Use (And what they do)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=Nsz1I5yGmdw" &&
#
## Xaryu with the INSANE 1 vs 5! (WORLD PVP MONTAGE)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=X4A-LgmMjlc" &&
#
#move_files false
#
## Multi Rank 1 PVP Premade WINNING WSG (Good communication this time)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=AizREFnAwgs" &&
#
## Xaryu duels vs Pikaboo, Ziqo, Sonydigital and Frawg (CLASSIC BETA)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=XaZ-_mW_mDw" &&
#
## this is what happens EVERYTIME the Gurubashi Arena event starts (CLASSIC BETA)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=H9Y9xg1J1H0" &&
#
#move_files false
#
## Revealing my SECRET Classic Mage MACRO'S!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=CsiWYl_SKuM" &&
#
## Classic Duels: MAGE vs MAGE
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=oP7O-JotxFg" &&
#
#move_files false
#
## Clearing SM Cathedral with 5 CASTERS (WORLD FIRST)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=mXtjm5UK5nM" &&
#
## ARATHI BASIN - Horde Premade vs Alliance Premade
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=xVALgGjqYu4" &&
#
#move_files false
#
## tbc:
#
## Sweating Hard Playing Versus Rogue/Priest...
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=cD5frCczyKI" &&
#
## When you play like you've already won.. (INSANE TBC ARENA WITH NAHJ!)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=jAGXxXvrP6g" &&
#
#move_files false
#
## Xaryu fight RAIKU and RIVAH in an INSANE series of ARENAS!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=FV-PODL0jhs" &&
#
## Trying out ARENA at LVL 60 with PHASE 1 GEAR!
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=uLUwpxB0zwA" &&
#
#move_files false

# How to Solo Carry Battlegrounds
#yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=04A-EWMjHnc" &&

# HILARIOUS RATED ARENA ON TBC WITH PIKABOO!
#yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=pOFuw-UftzM" &&

# Xaryu Plays With The Legend Mir... (Fighting Raiku)
#yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=yxbHNgyA2qU" &&

move_files false

# WHEN THE NOVA JUST DOESNT BREAK!
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=P_dMi1aBuhs" &&

# MORE FUNNY TBC ARENA WITH PAYO!
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=KPFNYGh4RNQ" &&

move_files false

# Xaryu & Payo vs. Snutz & Samiyam (BEST OF 5 ARENA)
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=D4zdQDT7Xn0" &&

# Double Mage Is The Most Broken Thing in TBC..
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=HDjBI5kHDFc" &&

move_files false

# When The Plays Are Just Perfect...
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=c1TJb8ZNb9Y" &&

# We Got Deleted By Triple Mage... (HIGH RATED TBC 3V3)
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=9YMl9QQG5f8" &&

move_files false

# Make One Mistake and You Lose...
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=cKIJsmrZc5c" &&

# INSANE GAMES VERSUS INSANE PLAYERS
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=1COTc3e9Gdg&pp=0gcJCbAJAYcqIYzv" &&

move_files false

# This Just Couldn't Be More Perfect... (INSANE TBC ARENA)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=Pg1pD9XS0kw" &&

# FIRST TIME PLAYING RANKED 3s AND DOMINATING! (and holy moly it's so much fun)
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=-pvU5DV0ZpY" &&

move_files false

# Xaryu and Nahj: CLIMBING THE LADDER! (currently rank 2)
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=y5_I9R8aSbE" &&

# The Best Comeback of ALL TIME!
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=WWZdtU7ZhsI" &&

move_files false

# INSANE 2400+ RATED GAMES /W NAHJ
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=Acr4nuZ4Ulc" &&

# 3V3 TURNS INTO 1V1..
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=aiEy0gbVWP8" &&

move_files false

# How Well Does Rogue Mage Do vs. Mage Priest?
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=ISN6Q3wRhwc" &&

# Crazy 5v5 Game Turns Into 3v3...
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=TILDxb75xFQ" &&

move_files false

# So We Got World First 2200 Rating in TBC... (PART 1900-2100)
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=kAxoozEichQ" &&

# Xaryu's CRAZY wotlk MAGE PLAYS
yt-dlp --cookies-from-browser firefox -S "res:1080" "https://www.youtube.com/watch?v=byDZrivV5NU" &&

# CLIMBING TO RANK 1 /W THIS GOD COMP
#yt-dlp -S "res:1080" "https://www.youtube.com/watch?v=jty8E-lvfbw"

move_files false

