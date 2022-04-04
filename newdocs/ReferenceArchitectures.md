The designation of primary and secondary is purely at your discretion. The doesn't matter if you're using an HA process like keepalived to present a single DNS IP address to clients, or handing out two DNS resolvers via DHCP. Generally it is expected that the two (or more) Pi-hole(s) will be at the same physical location, or at least on the same internal networks. It should also be possible to to replicate to a secondary Pi-hole across networks, either over a VPN or open-Internet, with the appropriate firewall/NAT configuration.

There are three reference architectures that I'll outline. All of them require an external DHCP server (such as a router, or dedicated DHCP server) handing out the DNS address(es) for your Pi-holes. Use of the integrated DHCP function in Pi-hole when using Gravity Sync is discouraged, although I'm sure there are ways to make it work. **Gravity Sync does not manage any DHCP settings.**

### Easy Peasy

![Easy Peasy](https://user-images.githubusercontent.com/3002053/87058413-ac378e80-c1cd-11ea-9f21-376170e69ff3.png)

This design requires the least amount of overhead, or additional software/network configuration beyond Pi-hole and Gravity Sync.

1. Client requests an IP address from a DHCP server on the network and receives it along with DNS and gateway information back. Two DNS servers (Pi-hole) are returned to the client.
2. Client queries one of the two DNS servers, and Pi-hole does it's thing.

You can make changes to your block-list, exceptions, etc, on either Pi-hole and they will be sync'd to the other within the timeframe you establish (here, 15 minutes.) The downside in the above design is you have two places where your clients are logging lookup requests to. Gravity Sync will let you change filter settings in either location, but if you're doing it often things may get overwritten.

### Stay Alive

![Stay Alive](https://user-images.githubusercontent.com/3002053/87058415-acd02500-c1cd-11ea-8884-6579a2d5eedc.png)

One way to get around having logging in two places is by using keepalived and present a single virtual IP address of the two Pi-hole, to clients in an active/passive mode. The two nodes will check their own status, and each other, and hand the VIP around if there are issues.

1. Client requests an IP address from a DHCP server on the network and receives it along with DNS and gateway information back. One DNS server (VIP) is returned to the client.
2. The VIP managed by the keepalived service will determine which Pi-hole responds. You make your configuration changes to the active VIP address.
3. Client queries the single DNS servers, and Pi-hole does it's thing.

You make your configuration changes to the active VIP address and they will be sync'd to the other within the timeframe you establish (here, 15 minutes.)