#!/bin/bash
#
# script to install MAGNET-STUDENT-MEDIA software with an array. Taken from jamf professional services script
# which can be found here: https://github.com/jamfprofessionalservices/DEP-Notify/blob/master/depNotify.sh

JAMFBIN=/usr/local/bin/jamf
DNLOG=/var/tmp/depnotify.log

# The policy array must be formatted "Progress Bar text,customTrigger". These will be
# run in order as they appear below.
POLICY_ARRAY=(
"Installing Trusted Certificates,trustd65"
"Installing D65 Print Drivers,installd65printdrivers"
"Installing Adobe Acrobat DC,installacrobatdc"
"Installing Adobe Flash,installflash"
"Installing Adobe Shockwave,installshockwave"
"Installing Ave Media Suite,installaversuite"
"Installing Comic Life,installcomiclife"
"Installing Google Backup and Sync,installbackupandsync"
"Installing Google Chrome,installchrome"
"Installing Google Earth,installgoogleearth"
"Installing Kidspiration,installkidspiration"
"Installing Inspiration,installinspiration"
"Installing Silverlight,installsilverlight"
"Installing VLC and VLC Web Plugin,installvlcandvlcwebplugin"
"Installing Legacy GarageBand Loops,installoldgaragebandloops"
"Installing ActivInspire and ActivInspire Resources,installinspire"
"Installing Epson Interactive Driver and Tools,installepsondriverandtools"
"Installing Adobe Creative Suite 6 Design and Web Premium,installcs6"
"Installing Media Lab Apps,installmedialabapps"
"Installing Java and Java for Mac OS X,installjavaandjavaformacos"
"Preventing Adobe Flash Updates,preventflashupdates"
"Installing D65 Student Support Utilites,installd65studentsupportutilities"
)

# Loop to run policies
for POLICY in "${POLICY_ARRAY[@]}"; do
  echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> "$DNLOG"
    "$JAMFBIN" policy -event "$(echo "$POLICY" | cut -d ',' -f2)"
done

# don't update inventory, the provisioning script will do that for you!
