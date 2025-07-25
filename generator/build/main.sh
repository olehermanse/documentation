#!/bin/bash

if [ "$#" != 4 ]; then
    echo "Pass 4 args, please:"
    echo BRANCH
    echo PACKAGE_JOB
    echo PACKAGE_UPLOAD_DIRECTORY
    echo PACKAGE_BUILD
    exit 1
fi

export BRANCH=$1
export PACKAGE_JOB=$2
export PACKAGE_UPLOAD_DIRECTORY=$3
export PACKAGE_BUILD=$4

export JOB_TO_UPLOAD=$PACKAGE_JOB
export FLAG_FILE_URL="http://buildcache.cfengine.com/packages/$PACKAGE_JOB/$PACKAGE_UPLOAD_DIRECTORY/PACKAGES_HUB_x86_64_linux_ubuntu_22/core-commitID"
export NO_OUTPUT_DIR=1

env
set -x

# take ownersip of all files
sudo chown -R jenkins:jenkins .

WRKDIR=$(pwd)
export WRKDIR

cd "$WRKDIR"/documentation/generator


### Download CFEngine:

# c https://github.com/cfengine/misc/blob/master/vagrant_quickstart/build.sh

function fetch_file() {
    # $1 -- URL to fetch
    # $2 -- destination
    # $3 -- number of tries (with 10s pauses) [optional, default=1]
    local target="$1"
    local destination="$2"
    local tries=1
    if [ $# -gt 2 ]; then
        tries="$3"
    fi
    local success=1                     # 1 means False in bash, 0 means True
    set +e
    for i in $(seq 1 "$tries"); do
        wget "$target" -O "$destination" && success=0 && break
        if [ "$i" -lt "$tries" ]; then
            sleep 10s
        fi
    done
    set -e
    return $success
}

set -ex

# these env variables must be set by calling script
test ! -z "$JOB_TO_UPLOAD"
test ! -z "$PACKAGE_UPLOAD_DIRECTORY"
test ! -z "$PACKAGE_BUILD"


echo "Waiting for flag file to appear"
for i in $(seq 30); do
    if wget -O- "$FLAG_FILE_URL"; then
      break
    fi
    echo "Waiting 10 sec"
    sleep 10
done
# check if flag file is there - if not, script will fail here
wget -O- "$FLAG_FILE_URL"

echo "Detecting version"
HUB_DIR_NAME=PACKAGES_HUB_x86_64_linux_ubuntu_22
HUB_DIR_URL="http://buildcache.cfengine.com/packages/$PACKAGE_JOB/$PACKAGE_UPLOAD_DIRECTORY/$HUB_DIR_NAME/"
HUB_PACKAGE_NAME="$(wget "$HUB_DIR_URL" -O- | sed '/\.deb/!d;s/.*"\([^"]*\.deb\)".*/\1/')"

fetch_file "$HUB_DIR_URL$HUB_PACKAGE_NAME" "cfengine-nova-hub.deb" 12

sudo apt-get -y purge cfengine-nova-hub || true
sudo rm -rf /*/cfengine

# unpack
sudo dpkg --unpack cfengine-nova-hub.deb
rm cfengine-nova-hub.deb
sudo cp -a /var/cfengine/share/NovaBase/masterfiles "$WRKDIR"
sudo chmod -R a+rX "$WRKDIR"/masterfiles

# write current branch into the config.yml
echo "branch: $BRANCH" >> "$WRKDIR"/documentation/generator/_config.yml

# replace %branch% placeholder with actual branch name
sed -i "s/%branch%/$BRANCH/g" "$WRKDIR"/documentation/hugo/config.toml

# Generate syntax data
./_regenerate_json.sh || exit 4

# Preprocess Documentation with custom macros
./_scripts/cfdoc_preprocess.py "$BRANCH" || exit 5

# rvm commands are insane scripts which pollut output
# so instead of set -x we just echo each command ourselves
set +x

export LC_ALL=C.UTF-8
bash ./build/install_hugo.sh
echo "+ bash -x ./_scripts/_run.sh $BRANCH || exit 6"
bash -x ./_scripts/_run.sh "$BRANCH" || exit 6
