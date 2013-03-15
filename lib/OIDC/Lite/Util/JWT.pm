package OIDC::Lite::Util::JWT;

use strict;
use warnings;

use Try::Tiny;
use Params::Validate;
use JSON::XS qw/decode_json encode_json/;
use MIME::Base64;

use constant {
    JWT_ALG_LEN     => 2,
    JWT_BITS_LEN    => 3,
    JWT_ALG_NONE    => q{none},
    JWT_ALG_HMAC    => q{HS},
    JWT_ALG_RSA     => q{RS},
    JWT_ALG_ECDSA   => q{ES},
};

=head1 NAME

OIDC::Lite::Util::JWT - JSON Web Token

=head1 SYNOPSIS

TBD

=head1 DESCRIPTION

JSON Web Token utility class.

=head1 METHODS

=head2 header( $jwt )

Returns hash reference of JWT Header.

    my $jwt = q{...}:
    my $header  = OIDC::Lite::Util::JWT::header($jwt);

=cut

sub header {
    my ($jwt) = @_;
    my $segments = [split(/\./, $jwt)];
    return {}
        unless (@$segments == 2 or @$segments == 3);

    my ($header_segment, $payload_segment, $crypt_segment) = @$segments;
    my $header;
    try {
        $header = decode_json(MIME::Base64::decode_base64url($header_segment));
    } catch {
        return {} if defined $_;
        return $header;
    };
}

=head2 payload( $jwt )

Returns hash reference of JWT Payload.

    my $jwt = q{...}:
    my $payload  = OIDC::Lite::Util::JWT::payload($jwt);

=cut

sub payload {
    my ($jwt) = @_;
    my $segments = [split(/\./, $jwt)];
    return {}
        unless (@$segments == 2 or @$segments == 3);

    my ($header_segment, $payload_segment, $crypt_segment) = @$segments;
    my $payload;
    try {
        $payload = decode_json(MIME::Base64::decode_base64url($payload_segment));
    } catch {
        return {} if defined $_;
        return $payload;
    };
}

=head1 AUTHOR

Ryo Ito E<lt>ritou.06@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ryo Ito

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
