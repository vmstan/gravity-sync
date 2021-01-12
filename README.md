<p align="center">
    <img src="https://raw.githubusercontent.com/vmstan/gravity-sync/master/docs/gravity-header.svg" width="80%" alt="Gravity Sync">
</p>

What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking ads via DNS on your network? That's right, **two** Pi-hole blocking ads on your network!

- [Seriously. Why two Pi-hole?](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions#why-do-i-need-more-than-one-pi-hole)

But if you have more than one Pi-hole in your network you'll want a simple way to keep the list configurations and local DNS settings identical between the two. That's Gravity Sync. With proper preparation it should only take a few minutes to install. Ideally you set up Gravity Sync and forget about it -- and in the long term, it would be awesome if the Pi-hole team made this entire script unnecessary.

# Features

Gravity Sync replicates the `gravity.db` database, which includes:

- Blocklist settings with status and comments.
- Domain whitelist and blacklist along with status with comments.
- Custom RegEx whitelist and blacklists.
- Clients and groups along with any list assignments.

Gravity Sync can also (optionally) replicate FTLDNS/DNSMASQ configuration files, including:

- Local DNS (A Records) which are stored in a separate `custom.list` file within the `/etc/pihole` directory.
- CNAME Records which are stored in a separate `05-pihole-custom-cname.conf` file in the `/etc/dnsmasq.d` directory.

### Limitations

Gravity Sync will **not**:

- Overwrite device specific Pi-hole settings specific to the local network configuration.
- Change the Pi-hole admin/API passwords, nor does not leverage these at all.
- Modify the individual Pi-hole's upstream DNS resolvers.
- Sync DHCP settings or monitor device leases.
- Merge long term data, query logs, or statistics.

# Setup Steps

1. [Review System Requirements](https://github.com/vmstan/gravity-sync/wiki/System-Requirements)
2. [Prepare Your Pi-hole](https://github.com/vmstan/gravity-sync/wiki/Installing#primary-pi-hole)
3. [Install Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#secondary-pi-hole) (or [Upgrade](https://github.com/vmstan/gravity-sync/wiki/Updating))
4. [Configure Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#configuration)
5. [Execute Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#execution)
6. [Automate Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#automation)
7. [Profit](https://memory-alpha.fandom.com/wiki/Rules_of_Acquisition)

# Disclaimer

Gravity Sync is not developed by or affiliated with the Pi-hole project. This is project an unofficial, community effort, that seeks to implement replication (which is currently not a part of the core Pi-hole product) in a way that provides stability and value to Pi-hole users. The code has been tested across multiple user environments but there always is an element of risk involved with running any arbitrary software you find on the Internet.

Pi-hole is and the Pi-hole logo are [registered trademarks](https://pi-hole.net/trademark-rules-and-brand-guidelines/) of Pi-hole LLC.

# Additional Documentation

Please refer to the [Wiki](https://github.com/vmstan/gravity-sync/wiki) for more information:

- [Frequently Asked Questions](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions)
- [Advanced Installation Options](https://github.com/vmstan/gravity-sync/wiki/Under-The-Covers)
- [Changelog](https://github.com/vmstan/gravity-sync/blob/master/CHANGELOG.md)
