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

# Set up colors
if [ -t 1 ] && command -v tput > /dev/null; then
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
	printf "%b\n" "${yellow:-}‼${normal:-} $1"
}

# Error message
err() {
	printf "%b\n" "${red:-}✘${normal:-} $1" >&2
}

# Print message
print() {
	printf "%b\n" "${normal:-}▷ $1" >&3
}

# Success message
success() {
	printf "%b\n" "${green:-}✔${normal:-} $1" >&3
}

warning "hello world"
err "hello world"
print "hello world"
success "hello world"
