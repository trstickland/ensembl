package XrefMapper::Methods::ExonerateUngappedBest1;

use XrefMapper::Methods::ExonerateBasic;

use vars '@ISA';

@ISA = qw{XrefMapper::Methods::ExonerateBasic};



sub options {

  return ('--model', 'affine:local', '--subopt', 'no', '--bestn', '1');

}



1;
