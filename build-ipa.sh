#!/usr/bin/env bash
set -ex

TMPDIR=$(mktemp -d -p /var/tmp)
TMPDIR_RAMDISK=$(mktemp -d -p /var/tmp)
IPA_RAMDISK_ARCH=$(uname -m)
IPA_RAMDISK_VERSION=$(rpm -q --queryformat "%{VERSION}-%{RELEASE}" rhosp-director-images-ipa-${IPA_RAMDISK_ARCH})

chmod 755 $TMPDIR $TMPDIR_RAMDISK
cd $TMPDIR
tar -xf /usr/share/rhosp-director-images/ironic-python-agent-${IPA_RAMDISK_VERSION}.${IPA_RAMDISK_ARCH}.tar
cd $TMPDIR_RAMDISK

# Extract the ipa-ramdisk filesystem
/usr/lib/dracut/skipcpio $TMPDIR/ironic-python-agent.initramfs | zcat | cpio -ivd

# NOTE(elfosardo) to prevent the ``BDB0091 DB_VERSION_MISMATCH: Database
# environment version mismatch`` error, we need to remove the rpm lock.
rm var/lib/rpm/.rpm.lock

# Prepare the chroot environment
cp /etc/resolv.conf etc/resolv.conf
mv etc/yum.repos.d/* .
cp /etc/yum.repos.d/* etc/yum.repos.d/
cp /usr/local/bin/chrooted.sh .
cp /tmp/ipa-ramdisk-packages-list.txt tmp/

# Modify the ipa-ramdisk in chroot
chroot . ./chrooted.sh

# Provide list of packages installed in the ipa-ramdisk
cp ipa-ramdisk-pkgs-list.txt /var/tmp/

# Compress the ipa-ramdisk and copy it in the right place
find . 2>/dev/null | cpio -c -o | gzip -8  > /var/tmp/ironic-python-agent.initramfs
cp $TMPDIR/ironic-python-agent.kernel /var/tmp/

# Clean temp directories
rm -fr $TMPDIR $TMPDIR_RAMDISK

# Debug Steps
cd /var/tmp
ls -la
