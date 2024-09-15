#!/bin/bash

################################################################################
# Intended to be run in the context of a Jenkins project on a JPL 
# Cybersecurity server for signing macOS applications. Polls SCM of the 
# Subversion repository hosted at 
# https://issm.ess.uci.edu/svn/issm-binaries/mac/matlab/unsigned to trigger new 
# builds.
#
# In order to replicate the requried Jenkins project configuration:
# - First, navigate to 'Manage Jenkins' -> 'Manage Plugins' and install the 
#	'Credentials Bindings Plugin' if it is not already installed.
# - Contact one of the members of the ISSM development team for credentials for 
#	the ISSM binaries repository (mention that the credentials are stored in 
#	ISSM-Infrastructure.pdf).
# - Navigate to 'Manage Jenkins' -> 'Manage Credentials' -> <domain> -> 
#	'Add Credentials' and enter the credentials from above.
# - From the 'Dashboard', select 'New Item' -> 'Freestyle project'.
# - Under 'Source Code Management', select 'Subversion'.
#		- The 'Repository URL' text field should be set to 
#		"https://issm.ess.uci.edu/svn/issm-binaries/mac/matlab/unsigned".
#		- The 'Credentials' select menu should be set to the new credentials 
#		created previously.
#		- The 'Local module directory' text field should be set to the same 
#		value as the constant UNSIGNED_REPO_COPY (set below to './unsigned').
# - Under 'Build Triggers', check the box for 'Poll SCM' and set the 
#	'Schedule' text area to "H/5 * * * *".
# - Under 'Build Environment', check the box for 'Use secret text(s) or 
#	file(s)', then under 'Bindings' click the 'Add...' button and select 
#	'Username and password (separated)'.
#		- Set 'Username Variable' to "ISSM_BINARIES_USER".
#		- Set 'Password Variable' to "ISSM_BINARIES_PASS".
# - Under 'Credentials', select the same, new credentials that created 
#	previously.
# - The contents of this script can be copied/pasted directly into the ‘Build' 
#	-> 'Execute Shell' -> ‘Command' textarea of the project configuration (or 
#	you can simply store the script on disk and call it from there).
# - Make sure to click the 'Save' button.
#
# Current point of contact at JPL Cybersecurity:
#	Alex Coward, alexander.g.coward@jpl.nasa.gov
#
# NOTE:
# - Assumes that "ISSM_BINARIES_USER" and "ISSM_BINARIES_PASS" are set up in 
#	the 'Bindings' section under a 'Username and password (separated)' binding 
#	(requires 'Credentials Binding Plugin').
# - For local debugging, the aforementioned credentials can be hardcoded into 
#	the 'USERNAME' and 'PASSWORD' constants below.
################################################################################

# Expand aliases within the context of this script
shopt -s expand_aliases

# NOTE: For some reason, calling svn from within the context of this script 
#		gives,
#
#			svn: command not found
#
#		even though it is installed via Homebrew and available at the following 
#		path.
#
alias svn='/usr/local/bin/svn'

## Override certain other aliases
#
alias cp=$(which cp)
alias grep=$(which grep)

## Constants
#
AD_IDENTITY="**********" # Apple Developer identity
AD_USERNAME="**********" # Apple Developer username
ALTOOL_PASSWORD="@keychain:**********" # altool password (assumed to be stored in keychain)
ASC_PROVIDER="**********"
MAX_SVN_ATTEMPTS=10
NOTARIZATION_CHECK_ATTEMPTS=20
NOTARIZATION_CHECK_PERIOD=60
NOTARIZATION_LOGFILE="notarization.log"
NOTARIZATION_LOGFILE_PATH="."
PASSWORD=${ISSM_BINARIES_PASS}
PKG="ISSM-macOS-MATLAB"
PRIMARY_BUNDLE_ID="gov.nasa.jpl.issm.matlab"
SIGNED_REPO_COPY="./signed"
SIGNED_REPO_URL="https://issm.ess.uci.edu/svn/issm-binaries/mac/matlab/signed"
SIGNING_LOCK_FILE="signing.lock"
SUCCESS_LOGFILE="${SIGNED_REPO_COPY}/success.log"
UNSIGNED_REPO_COPY="./unsigned"
UNSIGNED_REPO_URL="https://issm.ess.uci.edu/svn/issm-binaries/mac/matlab/unsigned"
USERNAME=${ISSM_BINARIES_USER}

COMPRESSED_PKG="${PKG}.zip"
EXE_ENTITLEMENTS_PLIST="${PKG}/bin/entitlements.plist"

# NOTE: Uncomment the following for local testing (Jenkins checks out copy of 
#		repository for unsigned packages to working directory)
#

# # Clean up from previous packaging (not necessary for single builds on Jenkins, 
# # but useful when testing packaging locally)
# echo "Cleaning up existing assets"
# rm -rf ${COMPRESSED_PKG} ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE} ${UNSIGNED_REPO_COPY}

# # Check out copy of repository for unsigned packages
# echo "Checking out copy of repository for unsigned packages"
# svn checkout \
# 	--trust-server-cert \
# 	--non-interactive \
# 	--username ${USERNAME} \
# 	--password ${PASSWORD} \
# 	${UNSIGNED_REPO_URL} \
# 	${UNSIGNED_REPO_COPY}

rm -rf ${PKG} ${SIGNED_REPO_COPY}

# Extract package contents
echo "Extracting package contents"
ditto -xk ${UNSIGNED_REPO_COPY}/${COMPRESSED_PKG} .

# Clear extended attributes on all files
xattr -cr ${PKG}

# Build list of ISSM executables
ISSM_BINS=$(\
	find ${PKG}/bin -type f -name *.exe; \
	find ${PKG}/lib -type f -name *.mexmaci64; \
)

# Build list of third party executables
THIRD_PARTY_BINS=$(\
	echo ${PKG}/bin/mpiexec; \
	echo ${PKG}/bin/hydra_pmi_proxy; \
	echo ${PKG}/bin/gdalsrsinfo; \
	echo ${PKG}/bin/gdaltransform; \
	echo ${PKG}/bin/gmt; \
	echo ${PKG}/bin/gmtselect; \
	echo ${PKG}/bin/gmsh; \
)

# Sign all executables in package
echo "Signing all executables in package"
codesign -s ${AD_IDENTITY} --timestamp --options=runtime --entitlements ${EXE_ENTITLEMENTS_PLIST} ${ISSM_BINS}
codesign -s ${AD_IDENTITY} --timestamp --options=runtime ${THIRD_PARTY_BINS}

# NOTE: Skipping signature validation because this is not a true package nor app

# Compress signed package
echo "Compressing signed package"
ditto -ck --sequesterRsrc --keepParent ${PKG} ${COMPRESSED_PKG}

# Submit compressed package for notarization
echo "Submitting signed package to Apple for notarization"
xcrun altool --notarize-app --primary-bundle-id ${PRIMARY_BUNDLE_ID} --username ${AD_USERNAME} --password ${ALTOOL_PASSWORD} --asc-provider ${ASC_PROVIDER} --file ${COMPRESSED_PKG} &> ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE}

# Sleep until notarization request response is received
echo "Waiting for notarization request response"
while [[ ! -f ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE} || ! -z $(find ${NOTARIZATION_LOGFILE_PATH} -empty -name ${NOTARIZATION_LOGFILE}) ]]; do
	sleep 30
done

echo "Notarization request response received"

# Check if UUID exists in response
HAS_UUID=$(grep 'RequestUUID = ' ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE}) # NOTE: Checking for "RequestUUID = " because "RequestUUID" shows up in some error messages
if [ -z "${HAS_UUID}" ]; then
	echo "Notarization failed!"
	echo "----------------------- Contents of notarization logfile -----------------------"
	cat ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE}
	echo "--------------------------------------------------------------------------------"

	# Clean up
	rm -rf ${PKG} ${COMPRESSED_PKG}

	exit 1
fi

# Get UUID from notarization request response
UUID=$(echo ${HAS_UUID} | sed 's/[[:space:]]*RequestUUID = //')
echo "UUID: ${UUID}" 

# Check notarization status
#
# NOTE: Currently, this checks if notarization was successful, but we are not 
#		able to staple notarization as this is not a true package nor app and, 
#		at the very least, MATLAB Mex files cannot be stapled. As such, clients 
#		will not be able to clear Gatekeeper if they are offline.
#
echo "Checking notarization status"
SUCCESS=0
for ATTEMPT in $(seq 1 ${NOTARIZATION_CHECK_ATTEMPTS}); do
	echo "    Attempt #${ATTEMPT}..."
	xcrun altool --notarization-info ${UUID} --username ${AD_USERNAME} --password ${ALTOOL_PASSWORD} &> ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE}
	if [[ -f ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE} && -z $(find ${NOTARIZATION_LOGFILE_PATH} -empty -name ${NOTARIZATION_LOGFILE}) ]]; then

		# First, check if there is an error
		ERROR_CHECK=$(grep 'Error' ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE})
		if [ ! -z "${ERROR_CHECK}" ]; then
			break
		fi

		# No error, so check status
		STATUS=$(grep 'Status:' ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE} | sed -e 's/[[:space:]]*Status: //')
		if [[ "${STATUS}" == "success" ]]; then
			# Staple notarization to all elements of package that were previously signed
			#xcrun stapler staple ${EXECUTABLES} # NOTE: Fails with "Stapler is incapable of working with MATLAB Mex files."

			# Validate stapling of notarization
			#xcrun stapler validation ${EXECUTABLES} # NOTE: Skipping notarization stapling validation because this is not a true package nor app

			# Compress signed and notarized package
			ditto -ck --sequesterRsrc --keepParent ${PKG} ${COMPRESSED_PKG}

			# Set flag indicating notarization was successful
			SUCCESS=1

			break
		elif [[ "${STATUS}" == "in progress" ]]; then
			echo "    ...in progress still; checking again in ${NOTARIZATION_CHECK_PERIOD} seconds."
			sleep ${NOTARIZATION_CHECK_PERIOD}
		elif [[ "${STATUS}" == "invalid" ]]; then
			break
		fi
	else
		if [ ${ATTEMPT} -lt ${NOTARIZATION_CHECK_ATTEMPTS} ]; then
			echo "    ...not ready yet; checking again in ${NOTARIZATION_CHECK_PERIOD} seconds."
			sleep ${NOTARIZATION_CHECK_PERIOD}
		else
			echo "    ...maximum attempts reached, but no response, or something else went wrong."
			echo "    If contents of notarization status check logfile appear to be valid, increase NOTARIZATION_CHECK_ATTEMPTS and run again."
			break
		fi
	fi
done

if [ ${SUCCESS} -eq 1 ]; then
	echo "Notarization successful!"
else
	echo "Notarization failed!"
	echo "----------------------- Contents of notarization logfile -----------------------"
	cat ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE}
	echo "--------------------------------------------------------------------------------"
fi

# Check out copy of repository for signed packages
echo "Checking out copy of repository for signed packages"
SVN_ATTEMPT=0
SVN_SUCCESS=0
while [[ ${SVN_ATTEMPT} -lt ${MAX_SVN_ATTEMPTS} && ${SVN_SUCCESS} -eq 0 ]]; do
	rm -rf ${SIGNED_REPO_COPY}
	svn checkout \
		--trust-server-cert \
		--non-interactive \
		--username ${USERNAME} \
		--password ${PASSWORD} \
		${SIGNED_REPO_URL} \
		${SIGNED_REPO_COPY} > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		SVN_SUCCESS=1
		break
	else
		((++SVN_ATTEMPT))
		sleep 5
	fi
done

if [ ${SVN_SUCCESS} -eq 0 ]; then
	echo "Checkout of repository for signed packages failed"
	exit 1
fi

# Copy notarization file to repository for signed packages
cp ${NOTARIZATION_LOGFILE_PATH}/${NOTARIZATION_LOGFILE} ${SIGNED_REPO_COPY}
svn add ${SIGNED_REPO_COPY}/${NOTARIZATION_LOGFILE} > /dev/null 2>&1

# Remove lock file from repository for signed packages
svn delete ${SIGNED_REPO_COPY}/${SIGNING_LOCK_FILE} > /dev/null 2>&1

SVN_ATTEMPT=0
SVN_SUCCESS=0
if [ ${SUCCESS} -eq 1 ]; then
	# Copy signed package to repository for signed packages
	cp ${COMPRESSED_PKG} ${SIGNED_REPO_COPY}
	svn add ${SIGNED_REPO_COPY}/${COMPRESSED_PKG} > /dev/null 2>&1

	# Commit changes
	echo "Committing changes to repository for signed packages"
	while [[ ${SVN_ATTEMPT} -lt ${MAX_SVN_ATTEMPTS} && ${SVN_SUCCESS} -eq 0 ]]; do
		svn commit \
			--trust-server-cert \
			--non-interactive \
			--username ${USERNAME} \
			--password ${PASSWORD} \
			--message "CHG: New signed package (success)" ${SIGNED_REPO_COPY} > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			SVN_SUCCESS=1
			break
		else
			((++SVN_ATTEMPT))
			sleep 5
		fi
	done

	if [ ${SVN_SUCCESS} -eq 0 ]; then
		echo "Commit to repository for signed packages failed"
		exit 1
	fi
else
	# Commit changes
	echo "Committing changes to repository for signed packages"
	while [[ ${SVN_ATTEMPT} -lt ${MAX_SVN_ATTEMPTS} && ${SVN_SUCCESS} -eq 0 ]]; do
		svn commit \
			--trust-server-cert \
			--non-interactive \
			--username ${USERNAME} \
			--password ${PASSWORD} \
			--message "CHG: New signed package (failure)" ${SIGNED_REPO_COPY} > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			SVN_SUCCESS=1
			break
		else
			((++SVN_ATTEMPT))
			sleep 5
		fi
	done

	if [ ${SVN_SUCCESS} -eq 0 ]; then
		echo "Commit to repository for signed packages failed"
		exit 1
	fi

	exit 1
fi
