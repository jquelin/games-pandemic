package Games::Pandemic::Role::Scientist;
# ABSTRACT: scientist pandemic role

use 5.010;
use Moose;
use MooseX::FollowPBP;

extends 'Games::Pandemic::Role';


# -- default builders

sub _cards_needed_builder { 4 }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__