Central to Gravity Sync is the idea of a primary and secondary Pi-hole. This has been there since the beginning. Originally the intention was only to take data from the primary and replicate it to the secondary. Since the secondary wouldn't have as much load on it under normal conditions, it seemed logical for Gravity Sync to run there since frequent restarts of the Pi-hole service wouldn't disrupt normal DNS user traffic. 

Gravity Sync would _pull_ the data from the primary (remote) Pi-hole, to the secondary (local) server.

Almost immediately after release of 1.0, the small group of users who were testing the script asked what happened if you made changes on the secondary while the primary was down. You'd need a way to _push_ the changes back the other way. 

So version 1.1 broke out the original functionality into `./gravity-sync.sh pull` and created `./gravity-sync.sh push` to go the other way.

This is the way it functioned until version 2.0. `./gravity-sync.sh smart` or just a simple `./gravity-sync.sh` will detect which way the data needs to go. So if the gravity.db has been modified on the primary Pi-hole, but the custom.list file has been changed on the secondary, Gravity Sync will do a _pull_ of the gravity.db then _push_ custom.list and then restart the correct components on each server. It will also only perform a sync of each component, if there are changes within each type to replicate. Now, if you only make a small change to your Local DNS settings, it doesn't kickoff the larger gravity.db replication.

This allows you to be more flexible in where you make your configuration changes, but it's considered best practice to continue making changes on one side where possible. In the event there are configuration changes to the same element within any given replication window (for example, custom.list changes at both sides) then Gravity Sync will attempt to determine (based on timestamps) on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync **does not** merge the contents of the files when these replication events happen, it simply overwrites the file on the other side.

The previous `./gravity-sync.sh pull` and `./gravity-sync.sh push` commands continue to function as they did previously, with no intention to break this functionality.

### When to Pull

`./gravity-sync.sh pull` can/should be run when:

- You are doing a fresh secondary Pi-hole deployment, and setting up Gravity Sync along side it, and you want to make sure that you don't push an empty or temporary copy of your database to the primary system.
- You know that your environment will never make changes to the secondary, perhaps in environments where the secondary is an HA pair behind a load balancer or another virtual IP address provider like keepalived, or in a different network (VPN).

### When to Push

`./gravity-sync.sh pull` can/should be run when:

- Your primary Pi-hole been offline for an extended period of time and there are changes from the secondary that you want to force back.
- Your secondary Pi-hole is actually in a public cloud provider, and the network requirements are such that pulling data to the secondary are more complicated than pushing them to a device with a dedicate IP address. (Note, in this case Gravity Sync actually would configured to run _on the primary internal/LAN_ Pi-hole.)
- You've done a restore of the gravity.db or custom.list to the secondary using `./gravity-sync.sh restore` and want to make sure those changes are replicated to the primary.