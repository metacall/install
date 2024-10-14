#!/usr/bin/env bash

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

set -xuo pipefail

# Run with Buildkit
export DOCKER_BUILDKIT=1

# Get current root folder
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Get test list (any target prefixed by 'test_')
TEST_LIST=$(cat Dockerfile | grep -v '^#' | grep 'AS test_' | awk '{print $4}')

# Define default certificate setup
METACALL_INSTALL_CERTS="${METACALL_INSTALL_CERTS:-certificates_local}"

# Run a local server static file server for tricking the tests into using the
# current version of install.sh script instead the one from GitHub URL
docker build -t metacall/install_nginx -f proxy/Dockerfile .

# Stop the container if it is already running
if [ $(docker ps -f "name=metacall_install_nginx" --format '{{.Names}}') = "metacall_install_nginx" ]; then
	docker stop metacall_install_nginx
fi

# Run the proxy for serving install.sh locally under raw.githubusercontent.com domain
docker run --rm \
	--name metacall_install_nginx \
	-p 80:80 \
	-p 443:443 \
	--network host \
	-d metacall/install_nginx

# Fake the DNS entry pointing to our interceptor proxy when testing locally
if [ "${METACALL_INSTALL_CERTS}" = "certificates_local" ]; then
	METACALL_INSTALL_DNS=--add-host="raw.githubusercontent.com:127.0.0.1"
else
	METACALL_INSTALL_DNS=
fi

# Run tests
for test in ${TEST_LIST}; do
	docker build \
		--no-cache \
		--progress=plain \
		--target ${test} \
		--build-arg "METACALL_INSTALL_CERTS=${METACALL_INSTALL_CERTS}" \
		--network host \
		${METACALL_INSTALL_DNS} \
		-t metacall/install:${test} .

	result=$?
	if [[ $result -ne 0 ]]; then
		echo "Test ${test} failed. Abort."
		exit 1
	fi

	# Clean test on each iteration in order to not clog the disk
	if [[ "${CI:-}" == "true" ]]; then
		docker system prune -f --all
	fi
done

# Clear the proxy
docker stop metacall_install_nginx

# Clean
docker system prune -f --all

# Test Docker Install
DOCKER_HOST_PATH="${SCRIPT_DIR}/test"

if [ "${METACALL_INSTALL_CERTS}" = "certificates_local" ]; then
	DOCKER_ADDITIONAL_VOLUME="-v ${SCRIPT_DIR}/install.sh:/bin/install.sh"
	DOCKER_INSTALL_CMD="sh /bin/install.sh"
	DOCKER_FALLBACK_CMD="true"
else
	DOCKER_ADDITIONAL_VOLUME=""
	DOCKER_INSTALL_CMD="wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s --"
	DOCKER_FALLBACK_CMD="wget https://raw.githubusercontent.com/metacall/install/master/install.sh -O /bin/install.sh"
fi

# Run Docker install with --docker-install parameter
docker run --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${DOCKER_HOST_PATH}:/metacall/source \
	${DOCKER_ADDITIONAL_VOLUME} \
	-t docker:19.03.13-dind \
	sh -c "${DOCKER_INSTALL_CMD} --docker-install \
		&& mkdir -p ${DOCKER_HOST_PATH} \
		&& cd ${DOCKER_HOST_PATH} \
		&& metacall script.js | grep '123456' \
		&& metacall deploy --version | grep -e '^v.*\..*\..*' \
		&& metacall faas --version | grep -e '^v.*\..*\..*'"

result=$?
if [[ $result -ne 0 ]]; then
	echo "Test test_docker failed. Abort."
	exit 1
fi

# Run Docker install with fallback (remove wget during the install phase in order to trigger the fallback)
docker run --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${DOCKER_HOST_PATH}:/metacall/source \
	${DOCKER_ADDITIONAL_VOLUME} \
	-t docker:19.03.13-dind \
	sh -c "${DOCKER_FALLBACK_CMD} \
		&& rm -rf /usr/bin/wget \
		&& sh /bin/install.sh \
		&& mkdir -p ${DOCKER_HOST_PATH} \
		&& cd ${DOCKER_HOST_PATH} \
		&& metacall script.js | grep '123456' \
		&& metacall deploy --version | grep -e '^v.*\..*\..*' \
		&& metacall faas --version | grep -e '^v.*\..*\..*'"

result=$?
if [[ $result -ne 0 ]]; then
	echo "Test test_docker_fallback failed. Abort."
	exit 1
fi

echo "All tests passed."
