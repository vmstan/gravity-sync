<p align="center">
<img src="https://vmstan.com/content/images/2021/02/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# Gravity Sync

</span>

###

What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking trackers, advertisements, and other malicious domains on your network? That's right, **two** Pi-hole blocking all that junk on your network! 

- [Seriously. Why two Pi-hole?](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions#why-do-i-need-more-than-one-pi-hole)

But if you have redundant Pi-hole in your network you'll want a simple way to keep the list configurations and local DNS settings identical between the two. That's where Gravity Sync comes in. Setup should only take a few minutes.

## Features

Gravity Sync replicates the core of Pi-hole's resolver settings, which includes:

- Adlist settings with status and comments.
- Domain whitelist and blacklist along with status with comments.
- Custom RegEx whitelist and blacklists.
- Clients and groups, along with any list assignments.
- Local DNS Records.
- Local CNAME Records.

### Limitations

Gravity Sync will **not**:

- Modify the individual Pi-hole's upstream DNS resolvers.
- Sync DHCP settings or monitor device leases.
- Merge long term data, query logs, or statistics.

## Setup Steps

1. [Review System Requirements](https://github.com/vmstan/gravity-sync/wiki/System-Requirements)
2. [Install Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing)
3. [Configure Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#configuration)
4. [Execute Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#execution)
5. [Automate Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#automation)

## Disclaimer

Gravity Sync is not developed by or affiliated with the Pi-hole project. This is project an unofficial, community effort, that seeks to implement replication (which is currently not a part of the core Pi-hole product) in a way that provides stability and value to Pi-hole users. The code has been tested across multiple user environments but there always is an element of risk involved with running any arbitrary software you find on the Internet.

Pi-hole is and the Pi-hole logo are [registered trademarks](https://pi-hole.net/trademark-rules-and-brand-guidelines/) of Pi-hole LLC.

## Additional Documentation

Please refer to the [Wiki](https://github.com/vmstan/gravity-sync/wiki) for more information:

- [Frequently Asked Questions](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions)
- [Advanced Installation Options](https://github.com/vmstan/gravity-sync/wiki/Under-The-Covers)
- [Changelog](https://github.com/vmstan/gravity-sync/wiki/Changelog)
