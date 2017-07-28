# openvpn-tcp-connector
Adapter between an UDP OpenVPN server and TCP OpenVPN clients

The program [ovpn_tcp.pl](ovpn_tcp.pl) accepts clients on a TCP port, splits the incoming data stream into chunks that are
forwarded as UDP packets to the OpenVPN server.
The response packets from the server are streamed back to the client.
See [perldoc](ovpn_tcp.md) for details.

This is mostly a proof-of-concept and an exercise in using the POE framework.
Almost all of the code is taken from the examples in the perldoc of the used modules.

The conversion between the TCP stream and the UDP packets is based on the protocol description in
[ssl.h](https://sourceforge.net/p/openvpn/openvpn/ci/v2.1.4/tree/ssl.h "link to the sourceforge project").

Also provided is a systemd unit description [ovpn_tcp.service](ovpn_tcp.service) that enables `ovpn_tcp.pl` as a
systemd service.
