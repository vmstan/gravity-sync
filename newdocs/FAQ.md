These are frequent questions about Gravity Sync implementations. In addition to any known issues outlined here, please review the [GitHub Issues](https://github.com/vmstan/gravity-sync/issues) page for real time user submitted bugs, enhancements or active/past discussions.

### Why do I need more than one Pi-hole?

- Redundancy.
- If either Pi-hole fails or goes offline due to maintenance, the other Pi-hole continues to serve DNS to your network.
- The most attractive way for people to leverage Pi-hole is on a Raspberry Pi, which while awesome pieces of kit, are not exactly enterprise grade systems, and can have component failures (ex: cheap SD cards that cannot handle frequent write activity.)
- If you have your Pi-hole setup in the router as the only DNS target, there is often no other DNS server offered to clients. Some devices will get annoyed if you only have one DNS address. In some cases those devices will utilize hard coded backup servers, which often do not have any of the privacy protections/controls afforded by Pi-hole.
- Some people attempt to hand out public resolvers as a backup thinking it'll only be used if Pi-hole isn't available, which is not the case. (IOT devices are especially guilty of this.)

### Do you merge the statistics and logs from each Pi-hole?

- No.

### How come you don't support DHCP syncing?

- If I’m being honest, it’s because I don’t use Pi-hole for DHCP in my own environment and it’s hard for me to support something I’m not actively using. This is the same reason why it took me until version 3.1 to get around to making Docker work properly.
- I’ve also not been confident in my ability to make it work reliability. I find DNS settings change so infrequently in most environments that even polling the sync every 15 minutes is probably overkill. DHCP device leases tend to be a lot more fluid. It’s not just a matter of taking this entire database from this side and putting it over here instead, if a device gets a lease from one server or the other then it disappears, problems arise. This also doesn't even begin to get into the dynamic DNS addresses that the devices register.

### Do you support DietPi, Unraid, Synology, LXD, Something Else?

- Yes and no. 
- Gravity Sync is designed to work on Linux systems that the main Pi-hole project [is designed to work on](https://docs.pi-hole.net/main/prerequisites/#supported-operating-systems). This is what I test the code against. 
- It is possible for Pi-hole to run on systems other than those listed on their project page. Chances are if Pi-hole will run on it, and you can SSH to a BASH shell on it, so will Gravity Sync. However, it's impossible for me to test every possible configuration, so if you do run into issues with a unofficial configuration you may be on your own unless they can either be replicated on a supported install, or generate enough community concern to specifically address within the script.
- Specifically to DietPi, yes Gravity Sync will work, but you must enable OpenSSH instead of the default Dropbear server. (Dropbear was supported for a time in older releases of Gravity Sync, but was problematic.)

### Can Gravity Sync run inside of a Docker container?

- No.
- Gravity Sync is designed to work with Docker deployments of Pi-hole, but it is expected that Gravity Sync itself will run on the container host operating system. It is a bash script that needs access to the commands and components of the host OS filesystem.

### Can I sync to a remote Pi that is not on the same LAN?

- Yes.
- As long as the two systems are reachable to each over SSH, they can sync.
- These can be on the same physical network separated by different VLANs, or two Pi-hole with connectivity through a VPN. 
- If it links, it syncs.

### Can I sync to a Pi-hole server in AWS? (or another cloud provider)

- Yes.
- Gravity Sync just needs to be able to connect to the remote server via SSH (port 22 by default) -- if you have a Pi-hole running within your LAN, and one in the public cloud, then the easiest way is to install Gravity Sync on the LAN based Pi-hole and use it to `push` the configuration out to the cloud based instance. The cloud instance will likely have it's own public IP address, with access to SSH already enabled.
- The alternative would be to put Gravity Sync on your cloud instance and use it to `pull` the configuration over, but this would require you to open the SSH port on your local firewall and then NAT this traffic to your internal Pi-hole device.

### Can I put Gravity Sync on both Pi-hole for even more redundancy?

- Not recommended.
- Gravity Sync already moves data in both directions. If you have it running from both Pi-hole against each other then you could probably get into a condition where they are both trying to push/pull at the same time, causing them to get confused, or possibly resulting in data loss.
- If you have a third Pi-hole, perhaps at a remote/cloud site, that you want to sync with your first to, you should install Gravity Sync on a second of the three and use it only to pull data from one of the first two Pi-hole.

### Does Gravity Sync work with Pi-hole 4?

- No.
- Pi-hole 5 implemented a new database called `gravity.db` that contains all the active blocklist settings. Gravity Sync was written specifically for Pi-hole 5.

### Does Gravity Sync work with Pi-hole v5.x?

- Probably.
- I am pretty good about tracking their releases, and expect that if there are breaking changes I would adapt to those quickly, but I do not anticipate any issues.
- Unless otherwise stated, it's expected you're running the latest production release of Pi-hole.