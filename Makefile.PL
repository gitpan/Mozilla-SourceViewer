use warnings FATAL => 'all';
use strict;

use 5.008008;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use ExtUtils::Depends;

my %pkgcfg = ExtUtils::PkgConfig->find("mozilla-gtkmozembed >= 1.8"
		, "firefox-gtkmozembed >= 2.0");
my $dep = ExtUtils::Depends->new('Mozilla::SourceViewer', 'Gtk2::MozEmbed');
$dep->set_inc($pkgcfg{cflags});
$dep->set_libs($pkgcfg{libs});
$dep->add_c("nsWeakReference.c");
$dep->add_xs("SourceViewer.xs");

WriteMakefile(
    NAME              => 'Mozilla::SourceViewer',
    VERSION_FROM      => 'lib/Mozilla/SourceViewer.pm', # finds $VERSION
    PREREQ_PM         => { 'Mozilla::Mechanize' => 0.05 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mozilla/SourceViewer.pm', # retrieve abstract from module
       AUTHOR         => 'Boris Sukholitko <boriss@gmail.com>') : ()),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    CC            => 'g++',
    LD            => "$Config{ld}",
  $dep->get_makefile_vars,
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
