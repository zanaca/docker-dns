#!/usr/bin/env sh

for EN in `ifconfig | grep -e "^en[0-9]" | cut -d: -f1`; do
    X=$(ifconfig $EN | grep "status: actisve")
    test "$X" && echo $EN
done