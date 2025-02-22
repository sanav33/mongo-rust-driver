#!/bin/bash

set -o xtrace
set -o errexit

export RUSTUP_HOME="${PROJECT_DIRECTORY}/.rustup"
export CARGO_HOME="${PROJECT_DIRECTORY}/.cargo"

# Make sure to use msvc toolchain rather than gnu, which is the default for cygwin
if [ "Windows_NT" == "$OS" ]; then
    export DEFAULT_HOST_OPTIONS='--default-host x86_64-pc-windows-msvc'
    # rustup/cargo need the native Windows paths; $PROJECT_DIRECTORY is a cygwin path
    export RUSTUP_HOME=$(cygpath ${RUSTUP_HOME} --windows)
    export CARGO_HOME=$(cygpath ${CARGO_HOME} --windows)
fi

curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path $DEFAULT_HOST_OPTIONS

# This file is not created by default on Windows
echo 'export PATH="$PATH:${CARGO_HOME}/bin"' >> ${CARGO_HOME}/env
echo "export CARGO_NET_GIT_FETCH_WITH_CLI=true" >> ${CARGO_HOME}/env

source ${CARGO_HOME}/env

# Install nightly rustfmt
rustup toolchain install nightly -c rustfmt

# Install tool for converting cargo test output to junit
cargo install cargo2junit

# Install the manual rendering tool
cargo install mdbook

# install npm/node
./.evergreen/install-node.sh

source ./.evergreen/env.sh

# Install tool for merging different junit reports into a single one
set +o errexit
set -o pipefail

npm install -g junit-report-merger --cache $(mktemp -d) 2>&1 | tee npm-install-output
RESULT=$?
MATCH=$(grep -o '/\S*-debug.log' npm-install-output)
if [[ $MATCH != "" ]]; then
    echo ===== BEGIN NPM LOG =====
    cat $MATCH
    echo ===== END NPM LOG =====
fi

exit $RESULT
