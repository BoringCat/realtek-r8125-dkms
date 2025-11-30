#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You must run this with superuser privileges.  Try \"sudo ./dkms-install.sh\"" 2>&1
  exit 1
else
  echo "About to run dkms install steps..."
fi

function getKernelVersions() {
  exec 3< <(
    echo "$@"
    find /lib/modules     -mindepth 2 -maxdepth 2 -name kernel -type d -printf '%P\n' | cut -d/ -f1
    find /usr/lib/modules -mindepth 2 -maxdepth 2 -name kernel -type d -printf '%P\n' | cut -d/ -f1
  )
  while read -u3 kver; do
    # Only show exists kernel.
    if [ ! -z "${kver}" ] && [ -d "/lib/modules/${kver}" -o -d "/usr/lib/modules/${kver}" ]; then
      echo "${kver}"
    fi
  done | sort | uniq
}

function buildForExistsKernel() {
  for _kver in `getKernelVersions "$@"`
  do
    dkms build   -m ${DRV_NAME} -v ${DRV_VERSION} -k ${_kver}
    dkms install -m ${DRV_NAME} -v ${DRV_VERSION} -k ${_kver}
  done
}

DRV_DIR="$(pwd)"
DRV_NAME=r8125
DKMS_DIR=/var/lib/dkms
DRV_VERSION=9.016.01
KERNEL_VERSION="${KERNEL_VERSION:-$(uname -r)}"

set -euo pipefail

rsync -av --delete-after --delete-excluded --chown=root:root \
  --exclude=.git/ --exclude=debian/ --exclude=.gitignore --exclude='*.sh' \
  --exclude-from=.gitignore \
  ${DRV_DIR}/ /usr/src/${DRV_NAME}-${DRV_VERSION}/

[ ! -d "${DKMS_DIR}/${DRV_NAME}/${DRV_VERSION}" ] && dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
buildForExistsKernel ${KERNEL_VERSION}
RESULT=$?

echo "Finished running dkms install steps."

exit $RESULT
