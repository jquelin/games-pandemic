package Games::Pandemic::Role::OperationsExpert;
# ABSTRACT: operations expert pandemic role

use 5.010;
use Moose;
use MooseX::FollowPBP;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_build_builder    { 1 }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__