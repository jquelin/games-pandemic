package Games::Pandemic::Role::Researcher;
# ABSTRACT: researcher pandemic role

use 5.010;
use Locale::TextDomain 'Games-Pandemic';
use Moose;
use MooseX::FollowPBP;

extends 'Games::Pandemic::Role';


# -- default builders

sub _can_share_builder    { 1 }
sub _color_builder        { '#aa7826' }
sub _role_name_builder    { __('Researcher') }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__