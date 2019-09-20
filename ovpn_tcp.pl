#!/usr/bin/perl 

use strict;
use warnings;

use IO::Socket::INET;
use POE qw(Wheel::SocketFactory Wheel::ReadWrite Filter::Block);
use Getopt::Long;
use Pod::Usage;

use constant DATAGRAM_MAXLEN => 64 * 1024;

my $peer_addr = "localhost";
my $peer_port = 1194;
my $listen_addr = "0.0.0.0";
my $listen_port = 1194;
my ($help, $man);

GetOptions(
	"peer_addr=s" => \$peer_addr,
	"peer_port=i" => \$peer_port,
	"listen_addr=s" => \$listen_addr,
	"listen_port=i" => \$listen_port,
	help => \$help,
	man => \$man,
) or pod2usage();

pod2usage(-verbose => 1) if $help;
pod2usage(-verbose => 2) if $man;


my $sockaddr = pack_sockaddr_in($peer_port, inet_aton($peer_addr));

my $blockFilter = POE::Filter::Block->new(
  LengthCodec => [
	sub {
	  # Encoder: insert lenght field
	  my $buffer = shift;
	  substr($$buffer, 0, 0) = pack("n", length($$buffer));
	},
	sub {
	  # Decoder: extract lenght field
	  my $buffer = shift;
	  my $length = substr($$buffer, 0, 2, "");
	  return unpack("n", $length);
	}
  ]
);

POE::Session->create(
  inline_states => {
    _start => sub {
      # Start the server.
      $_[HEAP]{server} = POE::Wheel::SocketFactory->new(
	BindAddress => $listen_addr,
        BindPort => $listen_port,
        SuccessEvent => "on_client_accept",
        FailureEvent => "on_server_error",
      );
	  printf STDERR "server started: tcp/%s:%i <-> udp/%s:%i\n",
		$listen_addr, $listen_port, $peer_addr, $peer_port;
    },
    on_client_accept => sub {
      # Begin interacting with the client.
      my ($kernel, $client_socket, $remote_addr, $remote_port) =
		@_[KERNEL, ARG0..ARG2];
      my $io_wheel = POE::Wheel::ReadWrite->new(
        Handle => $client_socket,
		Filter => $blockFilter,
        InputEvent => "on_client_input",
        ErrorEvent => "on_client_error",
      );
	  printf(STDERR "client connect failed\n"), return unless $io_wheel;
      $_[HEAP]{client}{ $io_wheel->ID() } = $io_wheel;
	  my $udp_socket = IO::Socket::INET->new(
		Type => SOCK_DGRAM,
		Proto => 'udp',
		LocalAddr => 'localhost',
	  );
	  printf STDERR "client %d connected tcp/%s:%i <-> udp/%s:%i\n",
			$io_wheel->ID(), inet_ntoa($remote_addr), $remote_port,
			$udp_socket->sockhost(), $udp_socket->sockport();
	  if ($udp_socket) {
  		$kernel->select_read($udp_socket, "on_datagram", $io_wheel->ID());
    	$_[HEAP]{udp_socket}{ $io_wheel->ID() } = $udp_socket;
	  } else {
		$io_wheel->shutdown_input();
		delete $_[HEAP]{client}{$io_wheel->ID()};
		printf STDERR "open socket failed\n";
	  }
    },
    on_server_error => sub {
      # Shut down server.
      my ($operation, $errnum, $errstr) = @_[ARG0..ARG2];
	  printf STDERR "Server %s error %i: %s\n", $operation, $errnum, $errstr;
      delete $_[HEAP]{server};
    },
    on_client_input => sub {
      # Handle client input.
      my ($input, $wheel_id) = @_[ARG0, ARG1];
      my $bytes = send($_[HEAP]{udp_socket}{$wheel_id}, $input, 0, $sockaddr);
    },
    on_client_error => sub {
      # Handle client error, including disconnect.
      my ($kernel, $wheel_id) = @_[KERNEL, ARG3];
	  printf STDERR "client %d disconnected\n", $wheel_id;
      delete $_[HEAP]{client}{$wheel_id};
	  my $udp_socket = $_[HEAP]{udp_socket}{$wheel_id};
	  $udp_socket->shutdown(2);
  	  $kernel->select_read($udp_socket);
	  delete $_[HEAP]{udp_socket}{$wheel_id};
    },
	on_datagram => sub {
	  # Handle server responses
	  my ($udp_socket, $client_id) = @_[ARG0, ARG2];
	  my $msg;
	  my $remote = recv($udp_socket, $msg, DATAGRAM_MAXLEN, 0);
	  return unless $remote;
	  $_[HEAP]{client}{$client_id}->put($msg);
	},
  }
);

POE::Kernel->run();
exit;

__END__

=encoding utf8

=head1 NAME

ovpn_tcp.pl - openvpn tcp to udp connector

=head1 SYNOPSIS

B<ovpn_tcp.pl> [B<-listen_addr> I<listen_addr>] [B<-listen_port>
I<listen_port>] [B<-peer_addr> I<peer_addr>] [B<-peer_port> I<peer_port>]

=head1 DESCRIPTION

C<ovpn_tcp.pl> listenes on a TCP server socket and allocates a UDP socket
for every connected client.
The inbound TCP stream is chunked into openvpn packets that are 
forwarded via UDP to the openvpn server.
Response packets from the server are streamed to the connected client.

=head1 OPTIONS

=over

=item B<-listen_addr> I<listen_addr>

I<listen_addr> is the address the server binds to.
Default: 0.0.0.0

=item B<-listen_port> I<listen_port>

The server will listen on port I<listen_port>.
Default: 1194

=item B<-peer_addr> I<peer_addr>

Incoming requests are forwarded to the openvpn server on
I<peer_addr> openvpn server.
Default: localhost

=item B<-peer_port> I<peer_port>

Incoming requests are forwarded to I<peer_port>.
Default: 1194

=back

=head1 SEE ALSO

L<POE>, L<openvpn>

=head1 AUTHOR

Jörg Sommrey

=cut

# vi:ts=4:
