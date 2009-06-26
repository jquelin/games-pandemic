package Games::Pandemic::Tk::PlayerFrame;
# ABSTRACT: frame to display a player

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Tk::Utils;

# -- attributes

has parent => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Tk::Widget' );
has player => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Games::Pandemic::Player' );

has _button => ( is=>'rw', weak_ref=>1, isa=>'Tk::Button' ); # player icon
has _fcards => ( is=>'rw', weak_ref=>1, isa=>'Tk::Frame'  ); # cards frame
has _cards => (
    metaclass  => 'Collection::Hash',
    is         => 'ro',
    isa        => 'HashRef[Tk::Frame]',
    default    => sub { {} },
    auto_deref => 1,
    provides   => {
        delete  => '_rm_fcard',       # $pframe->_rm_fcard( $card );
        set     => '_add_fcard',      # $pframe->_add_fcard( $card, $frame );
    }
);

=method $pframe->pack(...);

Regular call to C<Tk::pack> for the player frame.

=cut

# the main object frame
has _frame => (
    is         => 'rw',
    isa        => 'Tk::Frame',
    weak_ref   => 1,
    lazy_build => 1,
    handles    => [ qw{ pack } ],
);


# whether the card frame is visible or not
has _is_opened => (
      metaclass => 'Bool',
      is        => 'rw',
      isa       => 'Bool',
      default   => 1,
      provides  => {
          toggle  => '_switch_open',
      }
);


# -- initialization

sub _build__frame {
    my $self = shift;
    my $f = $self->parent->Frame;

    my $but = $f->Button(
        -image => image( $self->player->image('icon', 32) ),
        -command => sub { $self->_toggle_visibility },
    )->pack(@LEFT);
    $self->_set_button($but);

    my $fcards = $f->Frame->pack(@LEFT, @FILLY);
    $self->_set_fcards($fcards);

    return $f;
}


# -- public methods

=method $pframe->add_card( $card );

Draw the new C<$card> in the card frame.

=cut

sub add_card {
    my ($self, $card) = @_;
    my $fcards = $self->_fcards;
    my $f = $fcards->Frame->pack(@LEFT);
    $f->Label( -image => image( $card->icon ) )->pack(@LEFT);
    $f->Label( -text => $card->label, -anchor=>'w' )->pack(@LEFT);
    $self->_add_fcard( $card, $f );
}

=method $pframe->rm_card( $card );

Remove the C<$card> in the card frame.

=cut

sub rm_card {
    my ($self, $card) = @_;
    my $frame = $self->_rm_fcard( $card );
    $frame->destroy;
}


# -- private methods

#
# $pframe->_toggle_visibility;
#
# hide/show the cards visibility, depending on its current state.
#
sub _toggle_visibility {
    my $self = shift;
    if ( $self->_is_opened ) {
        $self->_fcards->packForget;
    } else {
        $self->_fcards->pack(@LEFT, @FILLY);
    }
    $self->_switch_open;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 SYNOPSIS

    my $pframe = Games::Pandemic::Tk::PlayerFrame->new(
        parent => $f,
        player => $player,
    )->pack(@LEFT);
    $pframe->add_card($card);

=head1 DESCRIPTION

This module implements a frame displaying a player icon with her cards
available. Clicking on the icon hides or shows her cards.

The constructor accepts the following arguments:

=over 4

=item * parent => $widget - the parent widget

=item * player => $player - the player to display

=back

