package Games::Pandemic::Role::OperationsExpert;
# ABSTRACT: operations expert pandemic role

use 5.010;
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_build_builder    { 1 }
sub _color_builder        { '#79af00' }
sub _image_builder        { 'ops-expert.png' }
sub _role_name_builder    { T('Operations Expert') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__