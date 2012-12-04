package Plack::Middleware::Auth::OIDC::ProtectedResource;

use strict;
use warnings;

use parent 'Plack::Middleware';

use Plack::Request;
use Plack::Util::Accessor qw(realm data_handler error_uri);
use Try::Tiny;
use Carp ();

use OAuth::Lite2::Server::Error;
use OAuth::Lite2::ParamMethods;

sub call {
    my ($self, $env) = @_;
    my $is_legacy = 0;

    my $error_res = try {

        my $req = Plack::Request->new($env);

        # after draft-v6, signature is not required, so always each connection
        # should be under TLS.
        # warn "insecure bearere token request" unless $req->secure;

        my $parser = OAuth::Lite2::ParamMethods->get_param_parser($req)
            or OAuth::Lite2::Server::Error::InvalidRequest->throw;

        $is_legacy = $parser->is_legacy($req);

        # after draft-v6, $params aren't required.
        my ($token, $params) = $parser->parse($req);
        OAuth::Lite2::Server::Error::InvalidRequest->throw unless $token;

        my $dh = $self->{data_handler}->new;

        my $access_token = $dh->get_access_token($token);

        OAuth::Lite2::Server::Error::InvalidToken->throw
            unless $access_token;

        Carp::croak "OIDC::Lite::Server::DataHandler::get_access_token doesn't return OAuth::Lite2::Model::AccessToken"
            unless $access_token->isa("OAuth::Lite2::Model::AccessToken");

        unless ($access_token->created_on + $access_token->expires_in > time())
        {
            if($is_legacy){
                OAuth::Lite2::Server::Error::ExpiredTokenLegacy->throw;
            }else{
                OAuth::Lite2::Server::Error::ExpiredToken->throw;
            }
        }

        my $auth_info = $dh->get_auth_info_by_id($access_token->auth_id);

        OAuth::Lite2::Server::Error::InvalidToken->throw
            unless $auth_info;

        Carp::croak "OIDC::Lite::Server::DataHandler::get_auth_info_by_id doesn't return OIDC::Lite::Model::AuthInfo"
            unless $auth_info->isa("OIDC::Lite::Model::AuthInfo");

        $dh->validate_client_by_id($auth_info->client_id)
            or OAuth::Lite2::Server::Error::InvalidToken->throw;

        $dh->validate_user_by_id($auth_info->user_id)
            or OAuth::Lite2::Server::Error::InvalidToken->throw;

        $env->{REMOTE_USER}    = $auth_info->user_id;
        $env->{X_OAUTH_CLIENT} = $auth_info->client_id;
        $env->{X_OAUTH_SCOPE}  = $auth_info->scope if $auth_info->scope;
        $env->{X_OIDC_USERINFO_CLAIMS}  = $auth_info->userinfo_claims if $auth_info->userinfo_claims;
        # pass legacy flag
        $env->{X_OAUTH_IS_LEGACY}   = ($is_legacy);

        return;

    } catch {

        if ($_->isa("OAuth::Lite2::Server::Error")) {

            my @params;
            if($is_legacy){
                push(@params, sprintf(q{error='%s'}, $_->type));
                push(@params, sprintf(q{error-desc='%s'}, $_->description))
                    if $_->description;
                push(@params, sprintf(q{error-uri='%s'}, $self->{error_uri}))
                    if $self->{error_uri};
                push(@params, sprintf(q{realm='%s'}, $self->{realm}))
                    if $self->{realm};

                return [ $_->code, [ "WWW-Authenticate" =>
                    "OAuth " . join(',', @params) ], [  ] ];
            }else{
                push(@params, sprintf(q{realm="%s"}, $self->{realm}))
                    if $self->{realm};
                push(@params, sprintf(q{error="%s"}, $_->type));
                push(@params, sprintf(q{error_description="%s"}, $_->description))
                    if $_->description;
                push(@params, sprintf(q{error_uri="%s"}, $self->{error_uri}))
                    if $self->{error_uri};

                return [ $_->code, [ "WWW-Authenticate" =>
                    "Bearer " . join(', ', @params) ], [  ] ];
            }

        } else {

            # rethrow
            die $_;

        }

    };

    return $error_res || $self->app->($env);
}

=head1 NAME

Plack::Middleware::Auth::OIDC::ProtectedResource - middleware for OpenID Connect Protected Resource endpoint

=head1 SYNOPSIS

    my $app = sub {...};
    builder {
        enable "Plack::Middleware::Auth::OIDC::ProtectedResource",
            data_handler => "YourApp::DataHandler",
            error_uri    => q{http://example.org/error/description};
        enable "Plack::Middleware::JSONP";
        enable "Plack::Middleware::ContentLength";
        $app;
    };

    # and on your controller
    $plack_request->env->{REMOTE_USER};
    $plack_request->env->{X_OAUTH_CLIENT_ID};
    $plack_request->env->{X_OAUTH_SCOPE};
    $plack_request->env->{X_OIDC_USERINFO_CLAIMS};
    $plack_request->env->{X_OAUTH_IS_LEGACY};

=head1 DESCRIPTION

middleware for OpenID Connect Protected Resource endpoint

=head1 METHODS

=head2 call( $env )

=head1 ENV VALUES

After successful verifying authorization within middleware layer,
Following 4 type of values are set in env.

=over 4

=item REMOTE_USER

Identifier of user who grant the client to access the user's protected
resource that is stored on service provider.

=item X_OAUTH_CLIENT

Identifier of the client that accesses to user's protected resource
on beharf of the user.

=item X_OAUTH_SCOPE

Scope parameter that represents what kind of resources that
the user grant client to access.

=item X_OIDC_USERINFO_CLAIMS

User Attributes required by client.
This claims include UserInfo response.

=back

=head1 AUTHOR

Ryo Ito, E<lt>ritou.06@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ryo Ito

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
