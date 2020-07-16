#!/bin/sh

DEBIAN_RELEASE=stretch
APT_MIRROR=ftp.tw.debian.org
APT_SECURITY_MIRROR=security.debian.org

ROOTFS_PATH=/tmp/rootfs-$$

echo "Use temp rootfs: ${ROOTFS_PATH}"

mkdir ${ROOTFS_PATH}


# debootstrap rootfs from minbase

debootstrap --variant=minbase --include=$(cat packages.list | tr '\n' ',') stretch "${ROOTFS_PATH}" http://opensource.nchc.org.tw/debian


# Apply some patches to the new rootfs

patch -p1 -d "${ROOTFS_PATH}" < rootfs.patch
cat sources.list | sed "s/DEBIAN_RELEASE/${DEBIAN_RELEASE}/g" | sed "s/APT_MIRROR/${APT_MIRROR}/g" | sed "s/APT_SECURITY_MIRROR/${APT_SECURITY_MIRROR}/g" > ${ROOTFS_PATH}/etc/apt/sources.list
chroot ${ROOTFS_PATH} locale-gen
chroot ${ROOTFS_PATH} sh -c "aptitude update && aptitude safe-upgrade -y && aptitude clean"

cp ${ROOTFS_PATH}/boot/vmlinuz* ./
rm -f ${ROOTFS_PATH}/initrd* ${ROOTFS_PATH}/vmlinuz*

rm -rf ${ROOTFS_PATH}/var/cache/* ${ROOTFS_PATH}/var/lib/apt*
mkdir -p ${ROOTFS_PATH}/var/lib/aptitude
rm -rf ${ROOTFS_PATH}/boot ${ROOTFS_PATH}/media ${ROOTFS_PATH}/srv ${ROOTFS_PATH}/opt
rm -f ${ROOTFS_PATH}/root/.bash_history

cd ${ROOTFS_PATH}
find . | cpio -o -H newc | xz -T0 --check=crc32 > ${OLDPWD}/initrd.img
cd ${OLDPWD}

