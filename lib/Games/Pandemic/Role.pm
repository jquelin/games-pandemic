package Games::Pandemic::Role;
# ABSTRACT: base class for pandemic roles

use 5.010;
use strict;
use warnings;

use File::Spec::Functions qw{ catfile };
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- accessors

has auto_clean_on_cure => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has can_build          => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has can_join_others    => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has can_move_others    => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has can_share          => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has cards_needed       => ( is=>'ro', isa=>'Int',  lazy_build=>1 );
has color              => ( is=>'ro', isa=>'Str',  lazy_build=>1 );
has cure_all           => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has _image             => ( is=>'ro', isa=>'Str',  lazy_build=>1 );
has max_cards          => ( is=>'ro', isa=>'Int',  lazy_build=>1 );
has role_name          => ( is=>'ro', isa=>'Str',  lazy_build=>1 );


# -- default builders

sub _build_auto_clean_on_cure { 0 }
sub _build_can_build          { 0 }
sub _build_can_join_others    { 0 }
sub _build_can_move_others    { 0 }
sub _build_can_share          { 0 }
sub _build_cards_needed       { 5 }
sub _build_cure_all           { 0 }
sub _build_max_cards          { 7 }


# -- public methods

=method my $path = $self->icon;

Return the C$<path> to an 32x32 icon of the role.

=cut

sub icon {
    my $self = shift;
    return catfile( $SHAREDIR, 'roles', $self->_image . '-32.png' );
}

=method my $path = $self->image;

Return the C$<path> to an image of the role.

=cut

sub image {
    my $self = shift;
    return catfile( $SHAREDIR, 'roles', $self->_image . '.png' );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__