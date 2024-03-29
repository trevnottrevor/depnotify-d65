#!/bin/bash
#
# script to install BASE-STAFF software with an array. Taken from jamf professional services script
# which can be found here: https://github.com/jamfprofessionalservices/DEP-Notify/blob/master/depNotify.sh

JAMFBIN=/usr/local/bin/jamf
DNLOG=/var/tmp/depnotify.log

# The policy array must be formatted "Progress Bar text,customTrigger". These will be
# run in order as they appear below.
POLICY_ARRAY=(
"Installing D65 Print Drivers,installd65printdrivers"
"Installing Adobe Acrobat DC,installacrobatdc"
"Installing Adobe Flash,installflash"
"Installing Adobe Shockwave,installshockwave"
"Installing Ave Media Suite,installaversuite"
"Installing Comic Life,installcomiclife"
"Installing Google Chrome,installchrome"
"Installing Google Earth,installgoogleearth"
"Installing Microsoft Office 2008,installoffice"
"Installing Silverlight,installsilverlight"
"Installing VLC and VLC Web Plugin,installvlcandvlcwebplugin"
"Installing Legacy GarageBand Loops,installoldgaragebandloops"
"Installing Java and Java for Mac OS X,installjavaandjavaformacos"
"Installing ActivInspire and ActivInspire Resources,installinspire"
"Installing Epson Interactive Driver and Tools,installepsondriverandtools"
"Installing NoMAD,installnomad"
"Installing D65 Staff Support Utilites,installd65staffsupportutilities"
)

# Loop to run policies
for POLICY in "${POLICY_ARRAY[@]}"; do
  echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> "$DNLOG"
    "$JAMFBIN" policy -event "$(echo "$POLICY" | cut -d ',' -f2)"
done

# don't update inventory, the provisioning script will do that for you!
