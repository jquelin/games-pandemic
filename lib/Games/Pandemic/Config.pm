use 5.010;
use strict;
use warnings;

package Games::Pandemic::Config;
# ABSTRACT: pandemic local configuration

use Games::Pandemic::Utils;
use MooseX::Singleton;          # should come before any other moose
use Moose      0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;
use YAML::Tiny qw{ LoadFile };

my $default = {
    canvas_height => 600,
    canvas_width  => 1024,
    win_height => 600+30+16,
    win_width  => 1024+70,
};

# -- accessors

has _options => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef[Str]',
    builder => '_build_options',
    handles => {
        set     => 'set',
        _get    => 'get',
        _exists => 'exists',
    }
);

# -- initializer

sub _build_options {
    my $yaml = eval { LoadFile( "$CONFIGDIR/config.yaml" ) };
    return $@ ? {} : $yaml;
}


# -- public methods

=method my $value = $config->get( $key )

Return the C<$value> associated to C<$key> in the configuration.
Note that if there's no local configuration defined, a default will
be provided.

=cut

sub get {
    my ($self, $key) = @_;
    my $val = $self->_get($key) // $default->{$key};
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

    use Games::Pandemic::Config;
    my $config = Games::Pandemic::Config->instance;
    my $width  = $config->get( 'canvas_width' );

=head1 DESCRIPTION

This module implements a basic persistant configuration, using key /
value pairs.

The module itself is implemented as a singleton, available with the
C<instance()> class method.
