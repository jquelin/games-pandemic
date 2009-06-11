package Games::Pandemic::Role;
# ABSTRACT: base class for pandemic roles

use 5.010;
use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- accessors

has auto_clean_on_cure => ( is=>'ro', isa=>'Bool', builder=>'_auto_clean_on_cure_builder' );
has can_build          => ( is=>'ro', isa=>'Bool', builder=>'_can_build_builder'          );
has can_join_others    => ( is=>'ro', isa=>'Bool', builder=>'_can_join_others_builder'    );
has can_move_others    => ( is=>'ro', isa=>'Bool', builder=>'_can_move_others_builder'    );
has can_share          => ( is=>'ro', isa=>'Bool', builder=>'_can_share_builder'          );
has cards_needed       => ( is=>'ro', isa=>'Int',  builder=>'_cards_needed_builder'       );
has color              => ( is=>'ro', isa=>'Str',  builder=>'_color_builder'              );
has cure_all           => ( is=>'ro', isa=>'Bool', builder=>'_cure_all_builder'           );
has _image             => ( is=>'ro', isa=>'Str',  builder=>'_imager_builder'             );
has max_cards          => ( is=>'ro', isa=>'Int',  builder=>'_max_cards_builder'          );
has role_name          => ( is=>'ro', isa=>'Str',  builder=>'_role_name_builder'          );


# -- default builders

sub _auto_clean_on_cure_builder { 0 }
sub _can_build_builder          { 0 }
sub _can_join_others_builder    { 0 }
sub _can_move_others_builder    { 0 }
sub _can_share_builder          { 0 }
sub _cards_needed_builder       { 5 }
sub _cure_all_builder           { 0 }
sub _max_cards_builder          { 7 }


# -- public methods

=method my $path = $self->image;

Return the C$<path> to an image of the role.

=cut

sub image {
    my $self = shift;
    return catfile( $SHAREDIR, 'roles', $self->_image );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__