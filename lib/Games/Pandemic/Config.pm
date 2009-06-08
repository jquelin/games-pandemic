package Games::Pandemic::Config;
# ABSTRACT: local configuration for Games::Pandemic

use 5.010;
use Games::Pandemic::Utils;
use MooseX::Singleton;
use MooseX::AttributeHelpers;
use YAML::Tiny qw{ LoadFile };

my $default = {foo => 'bar'};

# -- Accessors

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

# -- Public methods

sub get {
    my ($self, $key) = @_;
    my $val = $self->_get($key) // $default->{$key}; # /FIXME padre highlight
}

# -- Private subs

sub _build_options {
    my $yaml = eval { LoadFile( "$CONFIGDIR/config.yaml" ) };
    return $@ ? {} : $yaml;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
