# Push vs Pull

## Gravity Sync 4

With Gravity Sync running on both Pi-hole instances, running `gravity-sync` on either node will detect changes made to components on either side and decide which way the data needs to go to be in-sync. So if the `gravity.db` has been modified on the remoet Pi-hole, but the `custom.list` file has been changed on the local, Gravity Sync will do a _pull_ of the `gravity.db` then _push_ the `custom.list` and then restart the correct components on each server.

It will also only perform a sync of each component if there are changes within each type to replicate. In this example if you've not any changes to your CNAME settings as part of your DNS changes, they will be skipped. It also means that if you only make a small change to your  DNS settings, it doesn't kickoff the larger `gravity.db` replication.

In the event there are configuration changes to the same element within any given replication window (for example, `custom.list` changes at both sides) then Gravity Sync will attempt to determine (based on timestamps) on what side the last changed happened, in which case the latest changes will be considered authoritative and overwrite the other side. Gravity Sync **does not** merge the contents of the files when these replication events happen, it simply overwrites the file on the other side.

However there may be times when you want to force the movement of Pi-hole configurations in either direction. You can do this with specific `push` or `pull` commands.

- `gravity-sync pull` will force changes from the _remote_ Pi-hole, to the _local_ Pi-hole.
- `gravity-sync push` will force changes from the _local_ Pi-hole, to the _remote_ Pi-hole.

When should you push, or when you should pull?

- You are doing a fresh Pi-hole deployment, and you want to make sure that you don't push an empty or temporary copy of your database to the existing Pi-hole system.
- One of your Pi-hole has offline for an extended period of time and there are changes from the active instance that you want to force back.
- You know that in your environment you will never make changes to the configuration of one Pi-hole, perhaps in environments where the secondary is an HA pair behind a load balancer or another virtual IP address provider like keepalived, or in a different network (VPN).
- Your remote Pi-hole is actually in a public cloud provider, and the network requirements are such that pulling data to the secondary are more complicated than pushing them to a device with a dedicated IP address.
