#======================================================================
# Makefile Maker for LaTeXML-Plugin-Cortex
# d.ginev@jacobs-university.de
#======================================================================
use ExtUtils::MakeMaker;
use strict;
use warnings;

use FindBin;

#======================================================================
# Use "perl Makefile.PL <options>"
#======================================================================
our @EXCLUSIONS=();
our $MORE_MACROS = {};
our $MORE_MAKERULES=''; 

WriteMakefile(
  NAME => 'LaTeXML::Plugin::Cortex',
  AUTHOR => 'Deyan Ginev <d.ginev@jacobs-university.de>',
  ABSTRACT => "A CorTeX worker for LaTeXML",
  VERSION => '0.1',
  PREREQ_PM => { 
    'File::Temp' => 0,
    'File::Spec' => 0,
    'File::Find' => 0,
    'File::Path' => 0,
    'ZMQ::LibZMQ3' => '1.19',
    'LaTeXML'=>'0.8.1',
    'List::Util' => 0,
    'Archive::Zip'=>0,
    'Unix::Processors'=>0,
    'Proc::ProcessTable'=>0
  },
  EXE_FILES => ['bin/latexml_worker', 'bin/latexml_harness'],
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/dginev/LaTeXML-Plugin-Cortex.git',
          web => 'https://github.com/dginev/LaTeXML-Plugin-Cortex',
        }}})
  : ()),
);
