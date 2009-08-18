package Games::Pandemic::Tk::Dialog;
# ABSTRACT: base class for Games::Pandemic dialog windows

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;
use Tk;

use Games::Pandemic::Utils;
use Games::Pandemic::Tk::Utils;


# -- accessors

has parent    => ( is=>'ro', isa=>'Tk::Widget', required=>1, weak_ref=>1, );
has title     => ( is=>'rw', isa=>'Str',  lazy_build=>1 );
has header    => ( is=>'rw', isa=>'Str',  lazy_build=>1 );
has resizable => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has _toplevel => ( is=>'rw', isa=>'Tk::Toplevel' );
has _ok       => ( is=>'ro', isa=>'Str', lazy_build=>1 );
has _cancel   => ( is=>'ro', isa=>'Str', lazy_build=>1 );


# a hash to store the widgets for easier reference.
has _widgets => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => {
        'set' => '_set_w',
        'get' => '_w',
    },
);

# -- initialization / finalization

#
# BUILD()
#
# called as constructor initialization
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
    debug( "~dialog: $self\n" );
}

# lazy builders
sub _build_title     { T('Pandemic') }
sub _build_header    { '' }
sub _build_resizable { 0 }
sub _build__ok       { '' }
sub _build__cancel   { '' }


# -- gui methods

#
# $dialog->_close;
#
# request to destroy the dialog.
#
sub _close {
    my $self = shift;
    $self->_toplevel->destroy;
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
    $top->title( $self->title );
    $top->iconimage( pandemic_icon($top) );

    # dialog name
    if ( $self->header ) {
        my $font = $top->Font(-size=>16);
        $top->Label(
            -text => $self->header,
            -bg   => 'black',
            -fg   => 'white',
            -font => $font,
        )->pack(@TOP, @PAD10, @IPAD10, @FILL2);
    }

    # build sub-class gui elems
    inner();

    # the dialog buttons.
    # note that we specify a bogus width in order for both buttons to be
    # the same width. since we pack them with expand set to true, their
    # width will grow - but equally. otherwise, their size would be
    # proportional to their english text.
    my $fbuttons = $top->Frame->pack(@TOP, @FILLX);
    if ( $self->_ok ) {
        my $but = $fbuttons->Button(
            -text    => $self->_ok,
            -width   => 10,
            -command => sub { $self->_valid },
        )->pack(@LEFT, @XFILL2);
        $self->_set_w('ok', $but);
    }
    if ( $self->_cancel ) {
        my $but = $fbuttons->Button(
            -text    => $self->_cancel,
            -width   => 10,
            -command => sub { $self->_close },
        )->pack(@LEFT, @XFILL2);
        $self->_set_w('cancel', $but);
    }

    # center window & make it appear
    $top->Popup( -popover => $parent );
    if ( $self->resizable ) {
        $top->minsize($top->width, $top->height);
    } else {
        $top->resizable(0,0);
    }
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=begin Pod::Coverage

BUILD
DEMOLISH

=end Pod::Coverage


=head1 DESCRIPTION

C<Games::Pandemic::Tk::Dialog> is meant to be used as a base class for
Pandemic dialogs, and should not be used directly.

It will create a new toplevel with the Pandemic icon, a title and
possibly a header.

It accepts the following attributes:

=over 4

=item * parent - the parent window of the dialog, required

=item * title - the dialog title, default to C<Pandemic>

=item * header - a header to display at the top of the window, no default

=back

To subclass it, declare your own attributes, create the lazy builders
for the attributes, and C<augment> the C<_build_gui()> method to create
the bottom of the dialog window.


