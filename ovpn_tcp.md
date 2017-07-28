# NAME

ovpn\_tcp.pl - openvpn tcp to udp connector

# SYNOPSIS

**ovpn\_tcp.pl** \[**-listen\_addr** _listen\_addr_\] \[**-listen\_port**
_listen\_port_\] \[**-peer\_addr** _peer\_addr_\] \[**-peer\_port** _peer\_port_\]

# DESCRIPTION

`ovpn_tcp.pl` listenes on a TCP server socket and allocates a UDP socket
for every connected client.
The inbound TCP stream is chunked into openvpn packets that are 
forwarded via UDP to the openvpn server.
Response packets from the server are streamed to the connected client.

# OPTIONS

- **-listen\_addr** _listen\_addr_

    _listen\_addr_ is the address the server binds to.
    Default: 0.0.0.0

- **-listen\_port** _listen\_port_

    The server will listen on port _listen\_port_.
    Default: 1194

- **-peer\_addr** _peer\_addr_

    Incoming requests are forwarded to the openvpn server on
    _peer\_addr_ openvpn server.
    Default: localhost

- **-peer\_port** _peer\_port_

    Incoming requests are forwarded to _peer\_port_.
    Default: 1194

# SEE ALSO

POE, openvpn

# AUTHOR

Joerg Sommrey
