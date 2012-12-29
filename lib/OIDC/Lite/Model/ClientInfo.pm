package OIDC::Lite::Model::ClientInfo;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw(
    client_id
    client_secret
    registration_access_token
    expires_at
));

use Params::Validate;

sub new {
    my $class = shift;
    my @args = @_ == 1 ? %{$_[0]} : @_;
    my %params = Params::Validate::validate_with(
        params => \@args,
        spec => {
            client_id       => 1,
            client_secret   => { optional => 1 },
            redistration_access_token   => { optional => 1 },
            expires_at => { optional => 1 },
        },
        allow_extra => 1,
    );
    my $self = bless \%params, $class;
    return $self;
}

=head1 NAME

OIDC::Lite::Model::ClientInfo - model class that represents client info.

=head1 ACCESSORS

=head2 client_id

=head2 client_secret

=head2 registration_access_token;

=head2 expires_in

=head1 AUTHOR

Ryo Ito, E<lt>ritou.06@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ryo Ito

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

