#!/usr/bin/env bash

#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2019 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#		http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

# Set mode
set -eu -o pipefail

# Expose stream 3 as a pipe to the standard output of itself
exec 3>&1

# Check if program exists
program() {
	[ -t 1 ] && command -v $1 > /dev/null
}

# Set up colors
if program tput; then
	ncolors=$(tput colors)
	if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
		bold="$(tput bold		|| echo)"
		normal="$(tput sgr0		|| echo)"
		black="$(tput setaf 0	|| echo)"
		red="$(tput setaf 1		|| echo)"
		green="$(tput setaf 2	|| echo)"
		yellow="$(tput setaf 3	|| echo)"
		blue="$(tput setaf 4	|| echo)"
		magenta="$(tput setaf 5	|| echo)"
		cyan="$(tput setaf 6	|| echo)"
		white="$(tput setaf 7	|| echo)"
	fi
fi

# Warning message
warning() {
	printf "%b\n" "${yellow:-}‼${normal:-} $@"
}

# Error message
err() {
	printf "%b\n" "${red:-}✘${normal:-} $@" >&2
}

# Print message
print() {
	printf "%b\n" "${normal:-}▷ $@" >&3
}

# Success message
success() {
	printf "%b\n" "${green:-}✔${normal:-} $@" >&3
}

# Check if required programs are installed
REQUIRED_PROGRAMS=(sort head)

for req_prog in "${REQUIRED_PROGRAMS[@]}"; do
	if ! program $req_prog; then
	err "The program '$req_prog' is not found, it is required to run the installer. Aborting installation."
	exit 1
	fi
done

# Set up package manager
PACKAGE_MAN_LIST=(apt apt-get) # TODO: apk yum pacman emerge zypp up2date dnf
PACKAGE_MAN=

for pkg_man in "${PACKAGE_MAN_LIST[@]}"; do
	if program $pkg_man; then
		PACKAGE_MAN=$pkg_man
		break
	fi
done

if [ -z "$PACKAGE_MAN" ]; then
	err "The package manager of this system is not yet supported." \
		"  Available package managers: ${PACKAGE_MAN_LIST[*]}." \
		"  Please, refer to https://github.com/metacall/install/issues and create a new issue."
	exit 1
fi

# TODO: do automatic or prompt option selection
echo "$@"


# Check available versions



verlte() {
	[ "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
	[ "$1" = "$2" ] && return 1 || verlte $1 $2
}


# apt-cache madison python


# # ...
# warning "hello world"
# err "hello world"
# print "hello world"
# success "hello world"
