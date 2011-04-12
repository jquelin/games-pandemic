use 5.010;
use strict;
use warnings;

package Games::Pandemic::Utils;
# ABSTRACT: various utilities for pandemic

use Devel::CheckOS        qw{ os_is };
use Encode;
use File::HomeDir         qw{ my_data };
use File::ShareDir::PathClass;
use File::Spec::Functions qw{ catdir updir };
use FindBin               qw{ $Bin };
use Locale::TextDomain    'Games-Pandemic';
use Moose;
use Readonly;
 
extends 'Exporter';
our @EXPORT = qw{ $CONFIGDIR $SHAREDIR T debug };

Readonly our $CONFIGDIR => _find_config_dir();
our $SHAREDIR = File::ShareDir::PathClass->dist_dir("Games-Pandemic");


# -- public subs

=method my $locstr = T( $string )

Performs a call to C<gettext> on C<$string>, convert it from utf8 and
return the result. Note that i18n is using C<Locale::TextDomain>
underneath, so refer to this module for more information.

=cut

sub T { return decode('utf8', __($_[0])); }


=method debug( @stuff );

Output C<@stuff> on stderr if we're in a local git checkout. Do nothing
in regular builds.

=cut

my $debug = -d catdir( $Bin, updir(), '.git' );
sub debug {
    return unless $debug;
    warn "@_";
}


# -- private subs

#
# my $path = _find_config_dir();
#
# return the absolute path where local customization will be saved.
#
sub _find_config_dir {
    my $subdir = os_is('MicrosoftWindows' ) ? 'Perl' : '.perl';
    return catdir( my_data(), $subdir, 'Games-Pandemic' );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 DESCRIPTION

This module provides some helper variables and subs, to be used on
various occasions throughout the code.

