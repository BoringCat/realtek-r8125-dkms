#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You must run this with superuser privileges.  Try \"sudo ./dkms-install.sh\"" 2>&1
  exit 1
else
  echo "About to run dkms install steps..."
fi

function getKernelVersions() {
  find /lib/modules     -maxdepth 2 -name kernel -type d | cut -d/ -f4
  find /usr/lib/modules -maxdepth 2 -name kernel -type d | cut -d/ -f5
}

function buildForExistsKernel() {
  for _kver in `getKernelVersions | sort | uniq`
  do
    dkms build -m ${DRV_NAME} -v ${DRV_VERSION} -k ${_kver}
    dkms install -m ${DRV_NAME} -v ${DRV_VERSION} -k ${_kver}
  done
}

DRV_DIR="$(pwd)"
DRV_NAME=r8125
DRV_VERSION=9.015.00
DKMS_DIR=/var/lib/dkms
DRV_VERSION=9.016.01
KERNEL_VERSION="${KERNEL_VERSION:-$(uname -r)}"

set -e

rsync -av --delete-after --delete-excluded \
  --exclude=.git/ --exclude=debian/ --exclude=.gitignore --exclude='*.sh' \
  --exclude-from=.gitignore \
  ${DRV_DIR}/ /usr/src/${DRV_NAME}-${DRV_VERSION}/

[ ! -d "${DKMS_DIR}/${DRV_NAME}/${DRV_VERSION}" ] && dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
buildForExistsKernel
RESULT=$?

echo "Finished running dkms install steps."

exit $RESULT
