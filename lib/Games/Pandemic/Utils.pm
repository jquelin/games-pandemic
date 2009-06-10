package Games::Pandemic::Utils;
# ABSTRACT: various utilities for Games::Pandemic

use 5.010;
use Devel::CheckOS        qw{ os_is };
use Encode;
use File::Basename        qw{ fileparse };
use File::HomeDir         qw{ my_data };
use File::Spec::Functions qw{ catdir rel2abs };
use Locale::TextDomain    'Games-Pandemic';
use Module::Util          qw{ find_installed };
use Moose;
use Readonly;
 
extends 'Exporter';
our @EXPORT = qw{ $CONFIGDIR $SHAREDIR T };

Readonly our $CONFIGDIR => _find_config_dir();
Readonly our $SHAREDIR  => _find_share_dir();


# -- public subs

sub T { return decode('utf8', __($_[0])); }


# -- private subs

#
# my $path = _find_config_dir();
#
# return the absolute path where local customization will be saved.
#
sub _find_config_dir {
    my $subdir = os_is('MicrosoftWindows' ) ? 'Perl' : '.perl';
    return rel2abs( catdir( my_data(), $subdir, 'Games-Pandemic' ) );
}


#
# my $path = _find_share_dir();
#
# return the absolute path where all resources will be placed.
#
sub _find_share_dir {
    my $path = find_installed(__PACKAGE__);
    my ($undef, $dirname) = fileparse($path);
    return rel2abs( catdir($dirname, 'share') );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
