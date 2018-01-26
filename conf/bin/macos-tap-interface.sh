#!/usr/bin/env sh

[[ "$UID" -ne "0" ]] && echo "Error, you are not root" && exit 1

INT=-1
for EN in $(ifconfig | grep -e "^tap[0-9]" | cut -d: -f1); do
    INT=$(echo $EN | sed -e 's/[a-z]//g');
done
INT_NEXT=$(echo $INT+1 | bc);

IP=$(ifconfig tap$INT_NEXT | grep inet\  | cut -d\  -f2)

if [ "$IP" != "172.17.0.1" ]; then
    exec 4<>/dev/tap$INT_NEXT
    ifconfig tap$INT_NEXT 172.17.0.1 172.17.0.255
    ifconfig tap$INT_NEXT up
fi
