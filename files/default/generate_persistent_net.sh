#!/bin/sh
RULES=/etc/udev/rules.d/75-persistent-net.rules
if [ -f $RULES ]; then
    echo "$RULES is already exists."
    exit 1
fi


echo "#" > $RULES
echo "# Generated by `readlink -f $0`." >> $RULES
echo "#" >> $RULES
echo "" >> $RULES
for eth in eth2 eth3; do
IFS='
'
    macaddr=""
    for msg in `dmesg -t | grep ">$eth"`; do
        echo "# $msg" >> $RULES
        if [ -z "$macaddr" ]; then
            macaddr=`echo $msg | cut -d " " -f 6`
         fi
    done
    echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"$macaddr\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$eth\"" >> $RULES
    echo "" >> $RULES
done