package Games::Pandemic::Tk::GiveCard;
# ABSTRACT: sharing dialog window for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::POE;
use MooseX::SemiAffordanceAccessor;
use POE;
use Readonly;
use Tk;

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;

Readonly my $K  => $poe_kernel;


# -- accessors

has cards => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

has parent => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Tk::Widget' );

has players => (
    is         => 'ro',
    isa        => 'ArrayRef',
    required   => 1,
    auto_deref => 1,
);

# it's not usually a good idea to retain a reference on a poe session,
# since poe is already taking care of the references for us. however, we
# need the session to call ->postback() to set the various gui callbacks
# that will be fired upon gui events.
has _session => ( is=>'rw', isa=>'POE::Session', weak_ref=>1 );


# -- initialization

#
# START()
#
# called as poe session initialization.
#
sub START {
    my ($self, $session) = @_[OBJECT, SESSION];
    $K->alias_set('give_card');
    $self->_set_session($session);
    $self->_build_gui;
}


# -- public events



# -- private events

# -- gui events


# -- gui creation

#
# $main->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;

    my $top = $self->parent->Toplevel;

    # set windowtitle
    $top->title(T('Sharing knowledge...'));
    #$top->iconimage( image( catfile($SHAREDIR, 'icon.png') ) );

}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

START

=end Pod::Coverage


