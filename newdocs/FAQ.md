# FAQ

## Gravity Sync 4

These are frequent questions about Gravity Sync implementations. In addition to any known issues outlined here, please review the [GitHub Issues](https://github.com/vmstan/gravity-sync/issues) page for real time user submitted bugs, enhancements or past issue discussions not documented here.

### Why two Pi-hole?

Redundancy.

- If either Pi-hole fails or goes offline due to maintenance, the other Pi-hole continues to serve DNS to your network.
- The most attractive way for people to leverage Pi-hole is on a Raspberry Pi, which are not exactly "enterprise grade" systems, and usually have cheap SD cards that can burn out due to due to frequent write activity.
- If you have your Pi-hole setup as the only DNS target, some devices will get annoyed and commonly will utilize hard coded backup servers, from public DNS resolvers which do not have any of the privacy protections afforded by Pi-hole.
- In some cases people intentionally set those public resolvers as a backup entry in DHCP, thinking it'll only be used if Pi-hole isn't available, **which is not the case.**

### Do you merge the statistics and logs from each Pi-hole?

No.

### Do you sync DHCP?

No.

### Do you support $ALT_PLATFORM?

Yes, and no.

- Gravity Sync is designed to work on Linux systems that the main Pi-hole project [is designed to work on](https://docs.pi-hole.net/main/prerequisites/#supported-operating-systems). This is what I test the code against.
- It is possible for Pi-hole to run on systems other than those listed on their project page. Chances are if Pi-hole will run on it, and you can SSH to a BASH shell on it, you can use Gravity Sync.
- However, since it's impossible for me to test every possible configuration, so if you do run into issues with such a configuration, you may be on your own unless they can either be replicated on a supported install, or generate enough community concern to specifically address within the script.
- Specifically to DietPi, yes Gravity Sync will work, but you must enable OpenSSH instead of the default Dropbear server.

### Can the remote Pi-hole be on a different network?

Yes.

### Does Gravity Sync work with Pi-hole 4?

No.

- Pi-hole 5 implemented a new database called `gravity.db` that contains all the active blocklist settings. Gravity Sync was written specifically for Pi-hole 5.x.