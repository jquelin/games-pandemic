package Games::Pandemic::Role;
# ABSTRACT: base class for pandemic roles

use 5.010;
use Moose;
use MooseX::FollowPBP;

# -- accessors

has can_build    => ( is=>'ro', isa=>'Bool', builder=>'_can_build_builder'    );
has can_share    => ( is=>'ro', isa=>'Bool', builder=>'_can_share_builder'    );
has cards_needed => ( is=>'ro', isa=>'Int',  builder=>'_cards_needed_builder' );
has max_cards    => ( is=>'ro', isa=>'Int',  builder=>'_max_cards_builder'    );
has role_name    => ( is=>'ro', isa=>'Str',  builder=>'_role_name_builder'    );


# -- default builders

sub _can_build_builder    { 0 }
sub _can_share_builder    { 0 }
sub _cards_needed_builder { 5 }
sub _max_cards_builder    { 7 }


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__