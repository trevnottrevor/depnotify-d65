#!/bin/bash
#
#
# Created by John Mahlman, University of the Arts Philadelphia (jmahlman@uarts.edu)
# Name: DEP-DEPNotify-assignFacstaff
#
# Purpose: Will populate the server with appropriate username and rename the machine
# at deployment time. Run AFTER DEPNotify collects information.
#
# Changelog
#
# 8/22/18  - New script to go with single DEPprovisioning instance.
#
#
# Get the JSS URL from the Mac's jamf plist file
if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
	JSSURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
else
	echo "No JSS server set. Exiting..."
	exit 1
fi

# Define API username and password information & JSS Group name from passed parameters
if [ ! -z "$4" ]; then
    APIUSER="$4"
else
    echo "No value passed to $4 for api username. Exiting..."
    exit 1
fi

if [ ! -z "$5" ]; then
    APIPASS="$5"
else
    echo "No value passed to $5 for api password. Exiting..."
    exit 1
fi

SERIAL=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')
MODEL=$(system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}')
if echo "$MODEL" | grep -q "MacBookAir"
then
    PREFIX="MBA"
elif echo "$MODEL" | grep -q "MacBookPro"
then
    PREFIX="MBP"
else
    echo "No model identifier found."
    PREFIX=""
fi
DNPLIST=/var/tmp/DEPNotify.plist
USERNAME=$(/usr/libexec/plistbuddy $DNPLIST -c "print 'Computer or User Name'" | tr [A-Z] [a-z])
COMPUTERNAME="${USERNAME}-${PREFIX}"
COMPUTERNAME=`echo ${COMPUTERNAME:0:15}`

# Update User in JSS
cat << EOF > /var/tmp/tempInfo.xml
<computer>
    <location>
      <username>$USERNAME</username>
    </location>
</computer>
EOF
## Upload the xml file
/usr/bin/curl -sfku "$APIUSER":"$APIPASS" "$JSSURL"JSSResource/computers/serialnumber/"$SERIAL" -H "Content-type: text/xml" -T /var/tmp/tempInfo.xml -X PUT
rm -Rf /var/tmp/tempInfo.xml

# rename the computer
/usr/local/jamf/bin/jamf setComputerName -name "${COMPUTERNAME}"