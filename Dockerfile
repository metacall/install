#
#	MetaCall Install Script by Parra Studios
#	Cross-platform set of scripts to install MetaCall infrastructure.
#
#	Copyright (C) 2016 - 2020 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
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
FROM debian:bullseye-slim AS debian_root

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

# Fedora Base (root)
FROM fedora:33 AS fedora_root

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
FROM alpine:3.12.1 AS alpine_root

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

# BusyBox Base (download fail safely)
FROM busybox:1.32.0-uclibc AS test_busybox_fail

# BusyBox fails due to lack of SSL implementation in wget (if it fails, then the test passes)
RUN wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh \
	|| if [ $? -ne 0 ]; then exit 0; else exit 1; fi

# TODO: dind for the docker install
# TODO: check interactive mode?
