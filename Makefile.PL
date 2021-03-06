use 5.016000;
use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IXXAT::VCI3',
    VERSION_FROM      => 'lib/IXXAT/VCI3.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IXXAT/VCI3.pm', # retrieve abstract from module
       AUTHOR         => 'Vitaly Belekhov <rmrf17@gmail.com>') : ()),
    CONFIGURE_REQUIRES  =>  {
        'Inline::MakeMaker'     => 0.45,
        'ExtUtils::MakeMaker'   => 6.52,
    },
    BUILD_REQUIRES  =>  {
        'Inline::C'     => 0.76,
    },
);
