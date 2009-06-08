package Games::Pandemic::Utils;

use 5.010;
use Moose;
use Devel::CheckOS        qw{ os_is };
use File::Basename        qw{ fileparse };
use File::HomeDir         qw{ my_data };
use File::Spec::Functions qw{ catdir rel2abs };
use Module::Util          qw{ find_installed };
use Readonly;
 
extends 'Exporter';
our @EXPORT = qw{ $CONFIGDIR $SHAREDIR };

Readonly our $CONFIGDIR => _find_config_dir();
Readonly our $SHAREDIR  => _find_share_dir();



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


1;
