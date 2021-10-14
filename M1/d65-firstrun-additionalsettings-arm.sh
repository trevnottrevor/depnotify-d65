#!/bin/sh
## postinstall

pathToScript=$0
pathToPackage=$1
targetLocation=$2
targetVolume=$3

# "FirstBoot" setup script for macOS X 10.12.x Sierra and 10.14.x Mojave in District 65 when 
# enrolled through DEP and MDM. This is meant to be bundled in the enroll-firstrun-scripts
# as a part of DEPNotify provision and deployment.
#
# Based on a framework provided by Rich Trouton @ derflounder.wordpress.com
# Download updates at https://github.com/rtrouton/rtrouton_scripts/
# Heavily adapted for use in D65 by Eric Wacker
# Continued adaptation for use in D65 by Trev Kelderman
# Last modified 11-2018

# NOTE 1: The ladmin account is not created by this script. It is created in the Account Settings payload 
# in the PreStage in jamf Pro.

# Comments are ended with a (TK) to indicate code developed by Trev Kelderman
# Comments are ended with an (E) to indicate code developed by Eric Wacker
# Comments ended with (R - FBP - ##) indicate code pulled from Rich's FirstBoot Package script
# Comments ended with (R - FBPI - ##) indicate code pulled from Rich's FirstBoot Package Installer script

# Function that determines if the network is up by looking for any non-loopback network interfaces. (R - FBPI - 20)

# Set error codes (E)
E_AD=82   # AD Replica did not respond to a ping
E_NN=404  # Network connection not found ("no network")

# Set a bunch of variables
log_location="/private/var/log/d65_firstrun.log"
archive_log_location="/private/var/log/d65_firstrun-`date +%Y-%m-%d-%H-%M-%S`.log"
TimeServer1=time.apple.com
TimeZone=America/Chicago
STUCOMP="s"

echo "This log is a record of the d65-firstrun-additionalsettings script which runs post DEP and jamf enrollment and 
in conjunction with DEPNotify"

# Get the system's UUID to set ByHost prefs (R)
if [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` == "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c51-62 | awk {'print tolower()'}`
elif [[ `ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-50` != "00000000-0000-1000-8000-" ]]; then
	MAC_UUID=`ioreg -rd1 -c IOPlatformExpertDevice | grep -i "UUID" | cut -c27-62`
fi

# AD computer account name; must be less than 15 characters (E)
# See http://support.apple.com/kb/TS1532
# Generate this from the en0 mac address, minus the colons
HOST=mac$(networksetup -getmacaddress en0 | awk '{print $3}' | sed 's/://g' | sed 's/ //g')

SYSNAME=$(scutil --get LocalHostName)
echo "The LocalHostName of this computer is \"$SYSNAME\"."

# Obtain 2 or 3 digit school code from the beginning of the machine's hostname (E)
BLDG=$(scutil --get LocalHostName | awk '{print $1}' | cut -c 1-3 | sed 's/-//g' | sed 's/jec/jeh/g')
echo "The building code for this computer is \"$BLDG\"."

# Configure network time and location services (E)
# Unload LocationD first.
/bin/launchctl unload /System/Library/LaunchDaemons/com.apple.locationd.plist

# Checks to make sure the NPT configuration file exists first and if not, creates it
if [ ! -e /etc/ntp.conf ]; then
	touch /etc/ntp.conf
fi

# Set the primary network server with systemsetup -setnetworktimeserver  (E)
# Using this command will clear /etc/ntp.conf of existing entries and
# add the primary time server as the first line.
/usr/sbin/systemsetup -settimezone $TimeZone
/usr/sbin/systemsetup -setnetworktimeserver $TimeServer1

# Enables the Mac to set its clock using the network time server(s)  (E)
/usr/sbin/systemsetup -setusingnetworktime on 

# Enable location services, so Network Time can update based on changes in Timezone
/usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd.$MAC_UUID LocationServicesEnabled -int 1
chown -R _locationd:_locationd /var/db/locationd

# Re-enable LocationD
/bin/launchctl load /System/Library/LaunchDaemons/com.apple.locationd.plist

# Set variable to the "enX" port interface designation for 'Wi-Fi", e.g., en0 or en1
INTERFACE=`networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/,/Ethernet/' | awk 'NR==2' | cut -d " " -f 2`

# The following are customizations for 10.11.x  (E)
echo "Now to customize a few things..."

# disable automatic login (E)
echo "Disabling automatic login..."
/usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null

# Set the login window to name and password (R - FBP - 97)
echo "Configuring login window to use name and password fields..."
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

# Disable external accounts (i.e. accounts stored on drives other than the boot drive.) (R - FBP - 101)
echo "Disabling external accounts..."
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow EnableExternalAccounts -bool false

# The following are customizations for 10.7+ to set the ability to view additional (R - FBP - 114)
# system info at the Login window when you click on the time display, such as 
# Computer name, OS X build #, and IP address
echo "Enabling system info at the login screen..."
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# First we handle critical updates separately, because they should always be on
# Note: AutomaticCheck must be enabled or Critical Updates won't be found and installed
/usr/bin/defaults write /Library/Preferences/com.apple.softwareupdate AutomaticCheckEnabled -bool true
/usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate.plist CriticalUpdateInstall -bool true

# Now we test to see if a computer has -s- in its name (we check for a value of "s" after the first hyphen)
COMPTYPE=$(scutil --get LocalHostName | awk -F "-" '{print $2}')
if [ "$COMPTYPE" == "$STUCOMP" ]; then
	echo "This is a student computer, so disabling automatic software update checks..."
	/usr/bin/defaults write /Library/Preferences/com.apple.softwareupdate.plist AutomaticDownload -bool false
	/usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
else
	echo "This is a staff computer, so enabling automatic software update checks..."
	/usr/bin/defaults write /Library/Preferences/com.apple.softwareupdate.plist AutomaticDownload -bool true
	/usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool true
fi

# And we always disable the auto-installation of updates requiring restarts because annoying interruptions are annoying
/usr/bin/defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false
 
# Determine OS version and build version  (R - FBP - 174)
# as part of the following actions to disable
# the iCloud and Diagnostic pop-up windows

osvers=$(sw_vers -productVersion | awk -F. '{print $2}')
sw_vers=$(sw_vers -productVersion)
sw_build=$(sw_vers -buildVersion)

# Checks first to see if the Mac is running 10.7+  (R - FBP - 183)
# If so, the script checks the system default user template
# for the presence of the Library/Preferences directory.
#
# If the directory is not found, it is created and then the
# iCloud and Diagnostic pop-up settings are set to be disabled.
# Enables filename extensions

if [[ ${osvers} -ge 7 ]]; then
  echo "Supressing iCloud Setup Assistant, Siri Setup, and Data & Privacy Setup for future users..."
for USER_TEMPLATE in "/System/Library/User Template"/*
do
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/com.apple.SetupAssistant DidSeePrivacy -bool TRUE
  /usr/bin/defaults write "${USER_TEMPLATE}"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions -bool TRUE
done

# Checks first to see if the Mac is running 10.7+  (R - FBP - 200)
# If so, the script checks the existing user folders in /Users
# for the presence of the Library/Preferences directory.
#
# If the directory is not found, it is created and then the
# iCloud pop-up settings are set to be disabled.
# Enables filename extensions

echo "Supressing iCloud Setup Assistant, Siri Setup, and Data & Privacy Setup for existing users..."
for USER_HOME in /Users/*
  do
    USER_UID=`basename "${USER_HOME}"`
    if [ ! "${USER_UID}" = "Shared" ] 
    then 
      if [ ! -d "${USER_HOME}"/Library/Preferences ]
      then
        mkdir -p "${USER_HOME}"/Library/Preferences
        chown "${USER_UID}" "${USER_HOME}"/Library
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences
      fi
      if [ -d "${USER_HOME}"/Library/Preferences ]
      then
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeCloudSetup -bool TRUE
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant GestureMovieSeen none
        /usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenCloudProductVersion "${sw_vers}"
		/usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant LastSeenBuddyBuildVersion "${sw_build}"
		/usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeeSiriSetup -bool TRUE
		/usr/bin/defaults write "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant DidSeePrivacy -bool TRUE
		/usr/bin/defaults write "${USER_HOME}"/Library/Preferences/.GlobalPreferences.plist AppleShowAllExtensions -bool TRUE
        chown "${USER_UID}" "${USER_HOME}"/Library/Preferences/com.apple.SetupAssistant.plist
      fi
    fi
  done
fi

# Set whether you want to send diagnostic info back to  (R - FBP - 230)
# Apple and/or third party app developers. If you want to send diagonostic data 
# to Apple or 3rd party developers, set the following values to TRUE

SUBMIT_DIAGNOSTIC_DATA_TO_APPLE=FALSE
SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS=FALSE

# Checks first to see if the Mac is running 10.11.0 or higher. (R - FBP - 244)
# Set the appropriate number value for AutoSubmitVersion
# and ThirdPartyDataSubmitVersion by the OS version. For
# 10.10.x, the value will be 4. For 10.11.x, the value will
# be 5.

if [[ ${osvers} -eq 10 ]]; then
  VERSIONNUMBER=4
elif [[ ${osvers} -ge 11 ]]; then
  VERSIONNUMBER=5
fi

# Checks first to see if the Mac is running 10.10.0 or higher. 
# If so, the desired diagnostic submission settings are applied.

if [[ ${osvers} -ge 10 ]]; then

  CRASHREPORTER_SUPPORT="/Library/Application Support/CrashReporter"
 
  if [ ! -d "${CRASHREPORTER_SUPPORT}" ]; then
    mkdir "${CRASHREPORTER_SUPPORT}"
    chmod 775 "${CRASHREPORTER_SUPPORT}"
    chown root:admin "${CRASHREPORTER_SUPPORT}"
  fi

 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory AutoSubmit -boolean ${SUBMIT_DIAGNOSTIC_DATA_TO_APPLE}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory AutoSubmitVersion -int ${VERSIONNUMBER}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory ThirdPartyDataSubmit -boolean ${SUBMIT_DIAGNOSTIC_DATA_TO_APP_DEVELOPERS}
 /usr/bin/defaults write "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory ThirdPartyDataSubmitVersion -int ${VERSIONNUMBER}
 /bin/chmod a+r "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory.plist
 /usr/sbin/chown root:admin "$CRASHREPORTER_SUPPORT"/DiagnosticMessagesHistory.plist

fi

echo "Enabling Gatekeeper..."
/usr/sbin/spctl --master-enable

# Set the RSA maximum key size to 32768 bits (32 kilobits) in (R - FBP - 292)
# /Library/Preferences/com.apple.security.plist to provide
# future-proofing against larger TLS certificate key sizes.
#
# For more information about this issue, please see the link below:
# http://blog.shiz.me/post/67305143330/8192-bit-rsa-keys-in-os-x

/usr/bin/defaults write /Library/Preferences/com.apple.security RSAMaxKeySize -int 32768

# Enable SSH access, then create the SACL and then put the ladmin user in it' (E)

echo "Configuring SSH access..."
/usr/sbin/systemsetup -setremotelogin on
dscl . -read /Groups/com.apple.access_ssh RecordName >/dev/null 2>&1
if [ $? -ne 0 ]; then
  dseditgroup -o create com.apple.access_ssh
fi
dseditgroup -o edit -t user -a ladmin com.apple.access_ssh

# Set up ARD so that only the ladmin user has access (Apple KB article HT201710)
echo "Setting up ARD..."
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -allowAccessFor -specifiedUsers
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -users ladmin,jamf -access -on -privs -all
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -menu

# Enabling other CIS Benchmark security measures
# Disabling Apache web server built into macOS
launchctl disable system/org.apache.httpd
# Disabling NFS server built into macOS
launchctl disable system/com.apple.nfsd
# Enables Library Validation
defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation DisableLibraryValidation -bool false
# Sets permissions on Library so no folders are world writeable
chmod -R o-w /System/Volumes/Data/Library/

# Require an administrator password to access system-wide preferences
security authorizationdb read system.preferences > /tmp/system.preferences.plist
defaults write /tmp/system.preferences.plist shared -bool false
security authorizationdb write system.preferences < /tmp/system.preferences.plist

# Configures account lockout threshold to 5
# pwpolicy -n /Local/Default -setglobalpolicy "maxFailedLoginAttempts=5"


# Removed binding from script because it is no longer needed. (TK)

# no need to run jamf recon because it is run in the DEPprovisioning script
exit 0
