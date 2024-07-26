<p align="center">
<img src="images/gs-logo.svg" width="300" alt="Gravity Sync">
</p>

<span align="center">

# Gravity Sync

</span>

### Effective July 26, 2024, this project has been retired. Thank you for your use and enthusiasm for a project that began as a few lines of bash in a Slack channel and envolved into something far more complex, and used by many thousands of Pi-hole enthusiasts over the last four years. 

### The last released version of Gravity Sync (4.0.7) should continue to work with Pi-hole 5.x, but not with Pi-hole 6+ due to architecture changes.

What is better than a [Pi-hole](https://github.com/pi-hole/pi-hole) blocking trackers, advertisements, and other malicious domains on your network? That's right, **two** Pi-hole blocking all that junk on your network!

- [Seriously. Why two Pi-hole?](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions#why-do-i-need-more-than-one-pi-hole)

But if you have redundant Pi-hole in your network you'll want a simple way to keep the list configurations and local DNS settings identical between the two. That's where Gravity Sync comes in. Setup should only take a few minutes.

## Features

Gravity Sync replicates the core of Pi-hole's ad/telemetry blocking settings, which includes:

- Adlist settings with status and comments.
- Domain/RegEx whitelists and blacklist along with status and comments.
- Clients and group assignments, along with status and descriptions.

Gravity Sync also replicates local network DNS/DHCP settings, which includes:

- Local DNS Records.
- Local CNAME Records.
- Static DHCP Assignments.

### Limitations

Gravity Sync will **not**:

- Modify or sync the individual Pi-hole's upstream DNS resolvers.
- Merge query logs, statistics, long-term data, caches, or other resolution information.
- Sync individual Pi-hole DHCP scoping information or leases.

## Setup Steps

1. [Review System Requirements](https://github.com/vmstan/gravity-sync/wiki/System-Requirements)
2. [Install Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing)
3. [Configure Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Installing#configuration)
4. [Execute Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Engaging)
5. [Automate Gravity Sync](https://github.com/vmstan/gravity-sync/wiki/Automation)

## Disclaimer

Gravity Sync is not developed by or affiliated with the Pi-hole project. This is project an unofficial, community effort, that seeks to implement replication (which is currently not a part of the core Pi-hole product) in a way that provides stability and value to Pi-hole users. The code has been tested across multiple user environments but there always is an element of risk involved with running any arbitrary software you find on the Internet.

Pi-hole is and the Pi-hole logo are [registered trademarks](https://pi-hole.net/trademark-rules-and-brand-guidelines/) of Pi-hole LLC.

## Additional Documentation

Please refer to the [Wiki](https://github.com/vmstan/gravity-sync/wiki) for more information:

- [Frequently Asked Questions](https://github.com/vmstan/gravity-sync/wiki/Frequent-Questions)
- [Changelog](https://github.com/vmstan/gravity-sync/wiki/Changelog)
