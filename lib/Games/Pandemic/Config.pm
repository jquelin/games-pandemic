package Games::Pandemic::Config;
# ABSTRACT: local configuration for Games::Pandemic

use 5.010;
use Games::Pandemic::Utils;
use MooseX::Singleton;          # should come before any other moose
use MooseX::AttributeHelpers;
use MooseX::FollowPBP;
use YAML::Tiny qw{ LoadFile };

my $default = {foo => 'bar'};

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

sub get {
    my ($self, $key) = @_;
    my $val = $self->_get($key) // $default->{$key}; # /FIXME padre highlight
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