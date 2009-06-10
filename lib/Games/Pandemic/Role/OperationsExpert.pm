package Games::Pandemic::Role::OperationsExpert;
# ABSTRACT: operations expert pandemic role

use 5.010;
use Locale::TextDomain 'Games-Pandemic';
use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_build_builder    { 1 }
sub _color_builder        { '#79af00' }
sub _role_name_builder    { __('Operations Expert') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__