package Games::Pandemic::Tk::PlayerCards;
# ABSTRACT: window holding player cards for Games::Pandemic

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Tk::Utils;
use Games::Pandemic::Utils;

# -- attributes & accessors

has parent    => ( is=>'ro', required=>1, weak_ref=>1, isa=>'Tk::Widget' );
has _toplevel => ( is=>'rw', isa=>'Tk::Toplevel', handles => [ qw{ destroy } ] );


# -- initialization

#
# BUILD()
#
# called during object initialization.
#
sub BUILD {
    my $self = shift;
    $self->_build_gui;
}


#
# DEMOLISH()
#
# called as destructor
#
sub DEMOLISH {
    my $self = shift;
    debug( "~player cards: $self\n" );
}



# -- private methods

#
# dialog->_build_gui;
#
# create the various gui elements.
#
sub _build_gui {
    my $self = shift;
    my $parent = $self->parent;

    my $top = $parent->Toplevel;
    $self->_set_toplevel($top);
    $top->withdraw;

    # window title
    $top->title( T('Cards') );
    $top->iconimage( pandemic_icon($top) );

    # center window & make it appear
    $top->Popup( -popover => $parent );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD
DEMOLISH

=end Pod::Coverage
