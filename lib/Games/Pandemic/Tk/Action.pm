package Games::Pandemic::Tk::Action;
# ABSTRACT: action item for main Games::Pandemic window

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::AttributeHelpers;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Tk::Utils;


# -- attributes & accessors

# a hash with action widgets.
has _widgets => (
    metaclass => 'Collection::Hash',
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
    provides  => {
        delete  => 'rm_widget',
        set     => '_set_widget',       # $action->_set_widget($widget, $widget);
        values  => '_all_widgets',      # my @widgets = $action->_all_widgets;
    },
);

has is_enabled => (
    metaclass => 'Bool',
    is        => 'ro',
    isa       => 'Bool',
    default   => 1,
    provides  => {
        set   => '_enable',
        unset => '_disable',
    },
);

has callback => ( is => 'ro', isa => 'CodeRef',    required => 1, );
has window   => ( is => 'ro', isa => 'Tk::Widget', required => 1, );



# -- public methods

=method $action->add_widget( $widget );

Associate C<$widget> with C<$action>. Enable or disable it depending on
current action status.

=cut

sub add_widget {
    my ($self, $widget) = @_;
    $self->_set_widget($widget, $widget);
    $widget->configure( $self->is_enabled ? @ENON : @ENOFF );
}


=method $action->rm_widget( $widget );

De-associate C<$widget> with C$<action>.

=cut

# rm_widget() implemented in _widget attribute declaration


=method $action->enable;

Activate all associated widgets.

=cut

sub enable {
    my $self = shift;
    $_->configure(@ENON) for $self->_all_widgets;
    $self->_enable;
}


=method $action->disable;

De-activate all associated widgets.

=cut

sub disable {
    my $self = shift;
    $_->configure(@ENOFF) for $self->_all_widgets;
    $self->_disable;
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 SYNOPSIS

    my $action = Games::Pandemic::Tk::Action->new(
        window   => $mw,
        callback => $session->postback('event'),
    );
    $action->add_widget( $menu_entry );
    $action->add_widget( $button );
    $action->enable;
    ...
    $action->disable;


=head1 DESCRIPTION

Menu entries are often also available in toolbars or other widgets. And
sometimes, we want to enable or disable a given action, and this means
having to update everything this action is allowed.

This module helps managing actions in a GUI: just create a new object,
associate some widgets with C<add_widget()> and then de/activate the
whole action at once with C<enable()> or C<disable()>.

