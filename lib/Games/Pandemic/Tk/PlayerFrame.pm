package Games::Pandemic::Tk::PlayerFrame;
# ABSTRACT: frame to display a player

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Tk::Constants;

# -- attributes

has parent => (
    is => 'ro',
    isa => 'Tk::Widget',
    required => 1,
    weak_ref => 1,
);

has player => (
    is       => 'ro',
    isa      => 'Games::Pandemic::Player',
    required => 1,
    weak_ref => 1,
);

has _button => (
    is => 'rw',
    isa => 'Tk::Button',
    weak_ref => 1,
);

=method $pframe->pack(...);

Regular call to C<Tk::pack> for the player frame.

=cut

has _frame => (
    is => 'rw',
    isa => 'Tk::Frame',
    weak_ref => 1,
    lazy_build => 1,
    handles => [ qw{ pack } ],
);
has _fcards => (
    is => 'rw',
    isa => 'Tk::Frame',
    weak_ref => 1,
);

has _is_opened => (
      metaclass => 'Bool',
      is        => 'rw',
      isa       => 'Bool',
      default   => 1,
      provides  => {
          #set     => 'illuminate',
          #unset   => 'darken',
          toggle  => '_switch_open',
          #not     => 'is_dark'
      }
);



# -- initialization

sub _build__frame {
    my $self = shift;
    my $parent = $self->parent;
    my $f = $parent->Frame;

    my $but = $f->Button(
        -image => $parent->Photo( -file=>$self->player->image('icon', 32) ),
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
    my $f = $self->_fcards;
    $f->Label(-image => $self->parent->Photo(-file=>($card->icon)))->pack(@LEFT);
    $f->Label(-text => $card->label, -anchor=>'w')->pack(@LEFT);
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

=head1 DESCRIPTION

This module implements a frame displaying a player icon with her cards
available. Clicking on the icon hides or shows her cards.



