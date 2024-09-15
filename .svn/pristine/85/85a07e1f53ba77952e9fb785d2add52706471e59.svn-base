#!/bin/bash

################################################################################
# Transfers ISSM distributable package for macOS to ISSM website.
#
# NOTE:
# - Assumes that the following constants are defined,
#
#		COMPRESSED_PKG
#		ISSM_BINARIES_REPO_PASS
#		ISSM_BINARIES_REPO_USER
#		SIGNED_REPO_COPY
#		SIGNED_REPO_URL
#
# See also:
# - packagers/mac/complete-issm-mac-binaries-matlab.sh
# - packagers/mac/complete-issm-mac-binaries-python-2.sh
# - packagers/mac/complete-issm-mac-binaries-python-3.sh
################################################################################

# Expand aliases within the context of this script
shopt -s expand_aliases

# From https://developer.apple.com/documentation/macos-release-notes/macos-catalina-10_15-release-notes,
#
#	Command line tool support for Subversion — including svn, git-svn, and 
#	related commands — is no longer provided by Xcode. (50266910)
#
# which results in,
#
#	svn: error: The subversion command line tools are no longer provided by 
#	Xcode.
#
# when calling svn, even when subversion is installed via Homebrew and its path 
# is available in PATH.
#
# NOTE: May be able to remove this after updating macOS.
#
#alias svn='/usr/local/bin/svn'

## Override certain other aliases
#
alias cp=$(which cp)
alias grep=$(which grep)

## Functions
#
checkout_signed_repo_copy(){
	echo "Checking out copy of repository for signed packages"

	# NOTE: Get empty copy because we do not want to have to check out package 
	#		from previous signing.
	#
	svn checkout \
		--trust-server-cert \
		--non-interactive \
		--depth empty \
		--username ${ISSM_BINARIES_REPO_USER} \
		--password ${ISSM_BINARIES_REPO_USER} \
		${SIGNED_REPO_URL} \
		${SIGNED_REPO_COPY} > /dev/null 2>&1
}
validate_signed_repo_copy(){
	# Validate copy of repository for signed binaries (e.g. 
	# 'Check-out Strategy' was set to 'Use 'svn update' as much as possible'; 
	# initial checkout failed)
	if [[ ! -d ${SIGNED_REPO_COPY} || ! -d ${SIGNED_REPO_COPY}/.svn ]]; then
		rm -rf ${SIGNED_REPO_COPY}
		checkout_signed_repo_copy
	fi
}

# Check if working copy of repository for signed packages is missing
validate_signed_repo_copy

# Retrieve signed and notarized package
svn update \
	--trust-server-cert \
	--non-interactive \
	--username ${ISSM_BINARIES_REPO_USER} \
	--password ${ISSM_BINARIES_REPO_PASS} \
	${SIGNED_REPO_COPY}/${COMPRESSED_PKG}

# Transfer signed package to ISSM Web site
echo "Transferring signed package to ISSM Web site"
scp -i ~/.ssh/pine_island_to_ross ${SIGNED_REPO_COPY}/${COMPRESSED_PKG} jenkins@ross.ics.uci.edu:/var/www/html/${COMPRESSED_PKG}

if [ $? -ne 0 ]; then
	echo "Transfer failed! Verify connection then build this project again (with -t/--transferonly option to skip building, packaging, and signing)."
	exit 1
fi
