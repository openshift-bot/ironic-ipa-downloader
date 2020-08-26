set -ex

# Install the packages we need in the ipa-ramdisk
dnf --best install -y \
    openstack-ironic-python-agent \
    python3-ironic-python-agent \
    python3-ironic-lib

# Update netconfig to use MAC for DUID/IAID combo (same as RHCOS)
# FIXME: we need an alternative of this packaged
mkdir -p /etc/NetworkManager/conf.d /etc/NetworkManager/dispatcher.d
echo -e '[main]\ndhcp=dhclient\n[connection]\nipv6.dhcp-duid=ll' > /etc/NetworkManager/conf.d/clientid.conf
echo -e '[[ "$DHCP6_FQDN_FQDN" =~ - ]] && hostname $DHCP6_FQDN_FQDN' > /etc/NetworkManager/dispatcher.d/01-hostname
chmod +x /etc/NetworkManager/dispatcher.d/01-hostname

# Provide a list of packages installed in the ipa-ramdisk
rpm -qa | sort > ipa-ramdisk-pkgs-list.txt

# Cleaning steps
dnf clean all
rm -rf /var/cache/{yum,dnf}/*
rm -f /etc/resolv.conf
rm -f /etc/yum.repos.d/*
mv /*.repo /etc/yum.repos.d/
