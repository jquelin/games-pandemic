use 5.010;
use strict;
use warnings;

package Games::Pandemic::Tk::Dialog;
# ABSTRACT: base class for pandemic dialog windows

use Moose 0.92;
use MooseX::SemiAffordanceAccessor;
use Tk;
use Tk::Sugar;

use Games::Pandemic::Tk::Utils qw{ pandemic_icon };
use Games::Pandemic::Utils;


# -- accessors

has parent    => ( is=>'ro', isa=>'Tk::Widget', required=>1, weak_ref=>1, );
has title     => ( is=>'ro', isa=>'Str',  lazy_build=>1 );
has header    => ( is=>'ro', isa=>'Str',  lazy_build=>1 );
has resizable => ( is=>'ro', isa=>'Bool', lazy_build=>1 );
has _toplevel => ( is=>'rw', isa=>'Tk::Toplevel' );
has _ok       => ( is=>'ro', isa=>'Str', lazy_build=>1 );
has _cancel   => ( is=>'ro', isa=>'Str', lazy_build=>1 );


# a hash to store the widgets for easier reference.
has _widgets => (
    traits => ['Hash'],
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    handles => {
        _set_w => 'set',
        _w     => 'get',
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
        )->pack(top, pad10, ipad10, fill2);
    }

    # build sub-class gui elems
    inner();

    # the dialog buttons.
    # note that we specify a bogus width in order for both buttons to be
    # the same width. since we pack them with expand set to true, their
    # width will grow - but equally. otherwise, their size would be
    # proportional to their english text.
    my $fbuttons = $top->Frame->pack(top, fillx);
    if ( $self->_ok ) {
        my $but = $fbuttons->Button(
            -text    => $self->_ok,
            -width   => 10,
            -command => sub { $self->_valid },
        )->pack(left, xfill2);
        $self->_set_w('ok', $but);
        $top->bind('<Return>', sub { $self->_valid });
        $top->bind('<Escape>', sub { $self->_valid }) unless $self->_cancel;
    }
    if ( $self->_cancel ) {
        my $but = $fbuttons->Button(
            -text    => $self->_cancel,
            -width   => 10,
            -command => sub { $self->_close },
        )->pack(left, xfill2);
        $self->_set_w('cancel', $but);
        $top->bind('<Escape>', sub { $self->_close });
        $top->bind('<Return>', sub { $self->_close }) unless $self->_ok;
    }

    # center window & make it appear
    $top->Popup( -popover => $parent );
    if ( $self->resizable ) {
        $top->minsize($top->width, $top->height);
    } else {
        $top->resizable(0,0);
    }

    # allow dialogs to finish once everything is in place
    $self->_finish_gui if $self->can('_finish_gui');
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for Pod::Coverage
    BUILD
    DEMOLISH


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
for the attributes, C<augment> the C<_build_gui()> method to create the
bottom of the dialog window, and implement the C<_valid()> method that
would be called when ok button is pressed.

