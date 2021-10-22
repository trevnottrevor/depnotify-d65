#!/bin/bash

# Triggers for the policies to be chained.  Please leave the double quotes around the name of the trigger 
policyA="depnotifyenrollm1"
####################################################################################################
# Code
# Do not modify below this line
####################################################################################################
#Check to see if this is a new computer record, or has a jamf.log that is greater than 50 lines. 
old=$(cat /var/log/jamf.log | wc -l | awk '{print$1}')
if [ "$old" -gt 50 ]; 
then
	echo "It looks like this computer has likely been enrolled before.  The jamf.log contains $old lines"
	exit 0
else
#Running DEPNotify enrollment policy:
echo "Running DEPNotify enrollment M1 Policy...."
/usr/local/bin/jamf policy -event "$policyA"
exitCode="$?"

if [ $exitCode == 0 ]; 
then
	echo "DEPNotify enrollment M1 policy executed successfully."
	else
		echo "First policy failed.  Exit code is $exitCode.."
		exit $exitCode
fi

fi