use 5.010;
use strict;
use warnings;

package Games::Pandemic::Config;
# ABSTRACT: local configuration for Games::Pandemic

use Games::Pandemic::Utils;
use MooseX::Singleton;          # should come before any other moose
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;
use YAML::Tiny qw{ LoadFile };

my $default = {
    canvas_height => 600,
    canvas_width  => 1024,
    win_height => 600+30+16,
    win_width  => 1024+70,
};

# -- accessors

has '_options' => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef[Str]',
    builder   => '_build_options',
    provides  => {
        'set'    => 'set',
        'get'    => '_get',
        'exists' => '_exists',
    }
);

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

# -- private subs

sub _build_options {
    my $yaml = eval { LoadFile( "$CONFIGDIR/config.yaml" ) };
    return $@ ? {} : $yaml;
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
