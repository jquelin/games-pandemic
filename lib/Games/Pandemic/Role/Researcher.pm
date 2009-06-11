package Games::Pandemic::Role::Researcher;
# ABSTRACT: researcher pandemic role

use 5.010;
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_share_builder    { 1 }
sub _color_builder        { '#aa7826' }
sub _image_builder        { 'researcher.png' }
sub _role_name_builder    { T('Researcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__