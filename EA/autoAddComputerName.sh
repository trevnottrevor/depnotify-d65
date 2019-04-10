#!/bin/sh
computerName=`scutil --get ComputerName | tr "[a-z]" "[A-Z]"`

mkdir /Library/JAMF\ D65
mkdir /Library/JAMF\ D65/ComputerName
chflags hidden /Library/JAMF\ D65

echo $computerName > /Library/JAMF\ D65/ComputerName/ComputerName.txt
