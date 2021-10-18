#!/bin/sh
## postinstall

echo  "disable auto updates ASAP" >> /var/log/jamf.log
	# Disable Software Updates during imaging
	/usr/sbin/softwareupdate --schedule off

echo  "set power management" >> /var/log/jamf.log
#set power management settings
	pmset -c displaysleep 60 disksleep 0 sleep 0 womp 0 ring 0 autorestart 0 halfdim 1 sms 1
	pmset -b displaysleep 5 disksleep 1 sleep 10 womp 0 ring 0 autorestart 0 halfdim 1 sms 1

## Make the main script executable
echo  "setting main script permissions" >> /var/log/jamf.log
	chmod a+x /var/d65/scripts/d65-DEPprovisioning-arm.sh

## Set permissions and ownership for launch daemon
echo  "set LaunchDaemon permissions" >> /var/log/jamf.log
	chmod 755 /Library/LaunchDaemons/com.d65.launch-arm.plist
	chown root:wheel /Library/LaunchDaemons/com.d65.launch-arm.plist

## Load launch daemon into the Launchd system
echo  "load LaunchDaemon" >> /var/log/jamf.log
	launchctl load /Library/LaunchDaemons/com.d65.launch-arm.plist

## Load launch daemon into the Launchd system
echo  "creating hidden directory used for storing D65 JAMF data" >> /var/log/jamf.log
	mkdir /Library/JAMF\ D65
	mkdir /Library/JAMF\ D65/ComputerName
	chflags hidden /Library/JAMF\ D65

# We have to wait for the login window to show because the machine will reboot...
# so let's start this after the setup assistant is done.
CURRENTUSER=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
while [[ "$CURRENTUSER" == "_mbsetupuser" ]]; do
	sleep 5
	CURRENTUSER=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
done

echo  "add auto-login user" >> /var/log/jamf.log
	/usr/local/jamf/bin/jamf policy -event dep-autologin-m1

echo "Rebooting!" >> /var/log/jamf.log
	/sbin/shutdown -r +1 &

# Wait a few seconds
sleep 5

exit 0		## Success
exit 1		## Failure
