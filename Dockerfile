#
#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2024 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
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
#

FROM scratch AS testing

# Image descriptor
LABEL copyright.name="Vicente Eduardo Ferrer Garcia" \
	copyright.address="vic798@gmail.com" \
	maintainer.name="Vicente Eduardo Ferrer Garcia" \
	maintainer.address="vic798@gmail.com" \
	vendor="MetaCall Inc." \
	version="0.1"

# Debian Base (root)
FROM debian:trixie-slim AS debian_root

COPY test/ /test/

# Install dependencies and set up a sudo user without password
RUN apt-get update \
	&& apt-get install -y --no-install-recommends sudo curl wget ca-certificates \
	&& apt-get clean && rm -rf /var/lib/apt/lists/ \
	&& adduser --disabled-password --gecos "" user \
	&& usermod -aG sudo user \
	&& echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	&& chown -R user /test \
	&& chmod -R 500 /test/*

# Debian Base (user)
FROM debian_root AS debian_user

USER user

# Test install debian with root and wget from path
FROM debian_root AS test_debian_root_wget_from_path

RUN wget https://github.com/metacall/distributable-linux/releases/download/v0.7.0/metacall-tarball-linux-amd64.tar.gz \
	&& wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash -s -- --from-path /metacall-tarball-linux-amd64.tar.gz \
	&& metacall /test/script.js | grep '123456'

# Test install Debian with root and curl
FROM debian_root AS test_debian_root_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Debian with root and wget
FROM debian_root AS test_debian_root_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Debian without root and curl
FROM debian_user AS test_debian_user_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Debian without root and wget
FROM debian_user AS test_debian_user_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test reinstall Debian without root and wget
FROM test_debian_user_wget AS test_debian_user_wget_reinstall

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash -s -- --update \
	&& metacall /test/script.js | grep '123456'

# Test pip installation
FROM test_debian_user_wget AS test_debian_user_pip

RUN metacall pip3 install -r /test/requirements.txt \
	&& metacall /test/requirements.py | grep '123456'

# Test PYTHONPATH
FROM test_debian_user_wget AS test_debian_user_pythonpath

RUN metacall /test/async.py | grep 'Async Done'

# Fedora Base (root)
FROM fedora:latest AS fedora_root

COPY test/ /test/

# Install dependencies and set up a sudo user without password
RUN dnf update -y \
	&& dnf install -y sudo curl wget ca-certificates findutils \
	&& dnf clean all \
	&& adduser user \
	&& usermod -aG wheel user \
	&& echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	&& chown -R user /test \
	&& chmod -R 500 /test/*

# Fedora Base (user)
FROM fedora_root AS fedora_user

USER user

# Test install Fedora with root and curl
FROM fedora_root AS test_fedora_root_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Fedora with root and wget
FROM fedora_root AS test_fedora_root_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Fedora without root and curl
FROM fedora_user AS test_fedora_user_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Test install Fedora without root and wget
FROM fedora_user AS test_fedora_user_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | bash \
	&& metacall /test/script.js | grep '123456'

# Alpine Base (root)
FROM alpine:latest AS alpine_root

COPY test/ /test/

# Install dependencies and set up a sudo user without password
RUN apk update \
	&& apk add --no-cache sudo curl wget ca-certificates \
	&& rm -rf /var/cache/apk/* \
	&& adduser --disabled-password --gecos "" user \
	&& echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
	&& chown -R user /test \
	&& chmod -R 500 /test/*

# Alpine Base (user)
FROM alpine_root AS alpine_user

USER user

# Test install Alpine with root and curl
FROM alpine_root AS test_alpine_root_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	&& metacall /test/script.js | grep '123456'

# Test install Alpine with root and wget
FROM alpine_root AS test_alpine_root_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	&& metacall /test/script.js | grep '123456'

# Test install Alpine without root and curl
FROM alpine_user AS test_alpine_user_curl

RUN curl -sL https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	&& metacall /test/script.js | grep '123456'

# Test install Alpine without root and wget
FROM alpine_user AS test_alpine_user_wget

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	&& metacall /test/script.js | grep '123456'

# BusyBox Base
FROM busybox:stable-uclibc AS test_busybox

# Test install BusyBox fail due to lack of SSL implementation in wget (if it fails, then the test passes)
FROM test_busybox AS test_busybox_fail

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	|| if [ $? -ne 0 ]; then exit 0; else exit 1; fi

# BusyBox Base (with sources)
FROM test_busybox AS test_busybox_base

COPY test/ /test/

# Test install BusyBox without certificates
FROM test_busybox_base AS test_busybox_without_certificates

RUN wget --no-check-certificate -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	-s -- --no-check-certificate \
	&& sh /usr/local/bin/metacall /test/script.js | grep '123456'

# Test certificates in Debian with root (comparing against <!doctype html> in buffer format)
FROM test_debian_root_curl AS test_debian_root_certificates

RUN export WEB_RESULT="`printf 'load py /test/script.py\ninspect\ncall fetch_https(\"www.google.com\")\nexit' | metacall`" \
	&& export WEB_BUFFER="{\"data\":[60,33,100,111,99,116,121,112,101,32,104,116,109,108,62" \
	&& [ -z "${WEB_RESULT##*$WEB_BUFFER*}" ] || exit 1

# Test certificates in Debian with user (comparing against <!doctype html> in buffer format)
FROM test_debian_user_curl AS test_debian_user_certificates

RUN export WEB_RESULT="`printf 'load py /test/script.py\ninspect\ncall fetch_https(\"www.google.com\")\nexit' | metacall`" \
	&& export WEB_BUFFER="{\"data\":[60,33,100,111,99,116,121,112,101,32,104,116,109,108,62" \
	&& [ -z "${WEB_RESULT##*$WEB_BUFFER*}" ] || exit 1

# Test update Alpine
FROM test_alpine_user_wget AS test_alpine_user_wget_update

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh \
	| sh -s -- --update \
	| grep 'MetaCall has been installed'

# Test uninstall alpine
FROM test_alpine_user_wget AS test_alpine_user_wget_uninstall

RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh \
	| sh -s -- --uninstall \
	| grep 'MetaCall has been successfully uninstalled'
