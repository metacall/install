#!/usr/bin/env bash

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

# Get test list (any target prefixed by 'test_')
TEST_LIST=$(cat Dockerfile | grep 'AS test_' | awk '{print $4}')

# Run tests
for test in ${TEST_LIST}; do
	docker build --progress=plain --target ${test} -t metacall/install:${test} .
	result=$?
	if [[ $result -ne 0 ]]; then
		echo "Test ${test} failed. Abort."
		exit 1
	fi
done

# Clean tests
for test in ${TEST_LIST}; do
	docker rmi metacall/install:${test}
done

# Test Docker Install
DOCKER_HOST_PATH=`pwd`/test

docker run --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${DOCKER_HOST_PATH}:/metacall/source -it docker:19.03.13-dind \
	sh -c "wget -O - https://raw.githubusercontent.com/metacall/install/master/install.sh | sh -s -- --docker-install \
		&& mkdir -p ${DOCKER_HOST_PATH} \
		&& cd ${DOCKER_HOST_PATH} \
		&& metacall script.js | grep '123456'"

result=$?
if [[ $result -ne 0 ]]; then
	echo "Test test_docker failed. Abort."
	exit 1
fi
