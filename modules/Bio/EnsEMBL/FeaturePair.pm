
#
# BioPerl module for Bio::EnsEMBL::FeaturePair
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::FeaturePair - Stores sequence features which are
                            themselves hits to other sequence features.

=head1 SYNOPSIS

    my $feat  = new Bio::EnsEMBL::FeaturePair(-feature1 => $f1,
					      -feature2 => $f2,
					      );

    # Bio::SeqFeatureI methods can be used
    my $start = $feat->start;
    my $end   = $feat->end;

    # Bio::EnsEMBL::SeqFeatureI methods can be used
    my $analysis = $feat->analysis;
    
    $feat->validate  || $feat->throw("Invalid data in $feat");

    # Bio::FeaturePair methods can be used
    my $hstart = $feat->hstart;
    my $hend   = $feat->hend;

=head1 DESCRIPTION

A sequence feature object where the feature is itself a feature on another 
sequence - e.g. a blast hit where residues 1-40 of a  protein sequence 
SW:HBA_HUMAN has hit to bases 100 - 220 on a genomic sequence HS120G22.  
The genomic sequence coordinates are used to create one sequence feature 
$f1 and the protein coordinates are used to create feature $f2.  
A FeaturePair object can then be made

    my $fp = new Bio::EnsEMBL::FeaturePair(-feature1 => $f1,   # genomic
					   -feature2 => $f2,   # protein
					   );

This object can be used as a standard Bio::SeqFeatureI in which case

    my $gstart = $fp->start  # returns start coord on feature1 - genomic seq.
    my $gend   = $fp->end    # returns end coord on feature1.

In general standard Bio::SeqFeatureI method calls return information
in feature1.

Data in the feature 2 object are generally obtained using the standard
methods prefixed by h (for hit!)

    my $pstart = $fp->hstart # returns start coord on feature2 = protein seq.
    my $pend   = $fp->hend   # returns end coord on feature2.


If you wish to swap feature1 and feature2 around :

    $feat->invert

    $feat->start # etc. returns data in $feature2 object


=head1 CONTACT

Describe contact details here

=head1 APPENDIX

The rest of the documentation details each of the object methods. 
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::EnsEMBL::FeaturePair;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::SeqFeature;

@ISA = qw(Bio::EnsEMBL::SeqFeature);


sub new {
  my($class,@args) = @_;
  my $self = {};

  if( ref( $class) ) {
    $class = ref( $class );
  }

  bless ($self,$class);

  my ($feature1,$feature2) = 
      $self->_rearrange([qw(FEATURE1
			    FEATURE2
			    )],@args);

  if($feature1) {
    $self = $self->SUPER::new(-ANALYSIS => $feature1->analysis(),
		      -SEQNAME  => $feature1->seqname(),
		      -START    => $feature1->start(),
		      -END      => $feature1->end(),
		      -STRAND   => $feature1->strand(),
		      -FRAME    => $feature1->frame(),
		      -SCORE    => $feature1->score(),
		      -PERCENT_ID => $feature1->percent_id(),
		      -P_VALUE => $feature1->p_value(),
		      -PHASE => $feature1->phase(),
		      -END_PHASE => $feature1->end_phase());

    if($feature1->entire_seq()) {
      $self->attach_seq($feature1->entire_seq());
    }
  } else {
    $self->SUPER::new();
  }

  $feature2 && $self->feature2($feature2);

  # set stuff in self from @args
  return $self; # success - we hope!
}


=head2 feature1

 Title   : feature1
 Usage   : $f = $featpair->feature1
           $featpair->feature1($feature)
 Function: Get/set for the query feature
 Returns : Bio::SeqFeatureI
 Args    : none

=cut


sub feature1 {
  my ($self,$arg) = @_;

  if($arg) {
      $self->start($arg->start());
      $self->end($arg->end());
      $self->strand($arg->strand());
      $self->frame($arg->frame());
      $self->score($arg->score());
      $self->seqname($arg->seqname());
      $self->percent_id($arg->percent_id());
      $self->p_value($arg->p_value());
      $self->phase($arg->phase());
      $self->end_phase($arg->end_phase());
      $self->analysis($arg->analysis);
      $self->attach_seq($arg->entire_seq);
    }

  return $self;
}

=head2 feature2

 Title   : feature2
 Usage   : $f = $featpair->feature2
           $featpair->feature2($feature)
 Function: Get/set for the hit feature
 Returns : Bio::SeqFeatureI
 Args    : none


=cut

sub feature2 {
    my ($self,$arg) = @_;

    if (defined($arg)) {
      unless(ref($arg) ne "" && $arg->isa("Bio::SeqFeatureI")) {
	$self->throw("Argument [$arg] must be a Bio::SeqFeatureI");
      }

      $self->{_hstart}      = $arg->start();
      $self->{_hend}        = $arg->end();
      $self->{_hstrand}     = $arg->strand();
      $self->{_hseqname}    = $arg->seqname();
      $self->{_hphase}      = $arg->phase();
      $self->{_hend_phase}  = $arg->end_phase();
      $self->{_hentire_seq} = $arg->entire_seq();
      return $arg;
    } 
    
    my $seq = new Bio::EnsEMBL::SeqFeature(
		    -SEQNAME    => $self->{_hseqname},
		    -START      => $self->{_hstart},
		    -END        => $self->{_hend},
                    -STRAND     => $self->{_hstrand},
		    -SCORE      => $self->score(),
		    -PERCENT_ID => $self->percent_id(),
		    -P_VALUE    => $self->p_value(),
		    -PHASE      => $self->{_hphase},
		    -END_PHASE  => $self->{_hend_phase},
		    -ANALYSIS   => $self->analysis);

    if($self->{_hentire_seq}) {
      $seq->attach_seq($self->{_hentire_seq});
    }

    return $seq;
}


=head2 hseqname

 Title   : hseqname
 Usage   : $featpair->hseqname($newval)
 Function: Get/set method for the name of
           feature2.
 Returns : value of $feature2->seqname
 Args    : newvalue (optional)


=cut

sub hseqname {
    my ($self,$arg) = @_;

    if (defined($arg)) {
      $self->{_hseqname} = $arg;
    }

    return $self->{_hseqname};
}


=head2 hstart

 Title   : hstart
 Usage   : $start = $featpair->hstart
           $featpair->hstart(20)
 Function: Get/set on the start coordinate of feature2
 Returns : integer
 Args    : none

=cut

sub hstart {
  my ($self,$value) = @_;
  
  if (defined($value)) {
    $self->{_hstart} = $value;
  }
  
  return $self->{_hstart};
}

=head2 hend

 Title   : hend
 Usage   : $end = $featpair->hend
           $featpair->hend($end)
 Function: get/set on the end coordinate of feature2
 Returns : integer
 Args    : none

=cut

sub hend{
    my ($self,$value) = @_;

    if (defined($value)) {
      $self->{_hend} = $value;
    }

    return $self->{_hend};
}

=head2 hstrand

 Title   : hstrand
 Usage   : $strand = $feat->strand()
           $feat->strand($strand)
 Function: get/set on strand information, being 1,-1 or 0
 Returns : -1,1 or 0
 Args    : none

=cut

sub hstrand{
    my ($self,$arg) = @_;

    if (defined($arg)) {
      $self->{_hstrand} = $arg;
    } 
    
    return $self->{_hstrand};
}



=head2 invert

 Title   : invert
 Usage   : $tag = $feat->invert
 Function: Swaps feature1 and feature2 around
 Returns : Nothing
 Args    : none


=cut

sub invert {
    my ($self) = @_;

    my $tmp = $self->feature2;


    $self->feature2($self->feature1);
    $self->feature1($tmp);
}

=head2 validate

 Title   : validate
 Usage   : $sf->validate
 Function: Checks whether all data fields are filled
           in in the object and whether it is of
           the correct type.
           Throws an exception if it finds problems
 Example : $sf->validate
 Returns : nothing
 Args    : none


=cut

sub validate {
  my ($self) = @_;
  
  $self->SUPER::validate();
  $self->feature2->validate();
  
  # Now the analysis object
  if (defined($self->analysis)) {
    unless($self->analysis->isa("Bio::EnsEMBL::Analysis")) {
      $self->throw("Wrong type of analysis object");
    }
  } else {
    $self->throw("No analysis object defined");
  }
}

=head2 validate_prot_feature

 Title   : validate_prot_feature
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub validate_prot_feature{
   my ($self) = @_;

   $self->SUPER::validate_prot_feature(1);
   $self->feature2->validate_prot_feature(2);

   if (defined($self->analysis)) {
     unless($self->analysis->isa("Bio::EnsEMBL::Analysis")) {
       $self->throw("Wrong type of analysis object");
     }
   } else {
     $self->throw("No analysis object defined");
   }
 }

=head2 set_featurepair_fields

 Title   : set_featurepair_fields
 Usage   : $fp->set_featurepair_fields($start, $end, $strand,
           $score, $seqname, $hstart, $hend, $hstrand, $hscore,
	   $hseqname, $analysis);
 Returns : nothing
 Args    : listed above, followed by optional $e_value, $perc_id, 
           $phase, $end_phase

=cut

sub set_featurepair_fields {
   my ($self, $start, $end, $strand, $score, $seqname, $hstart, $hend,
        $hstrand, $hscore, $hseqname, $analysis, $e_value, $perc_id, 
        $phase, $end_phase) = @_;
   
   $self->throw('interface fault') if (@_ < 12 or @_ > 16);

   $self->start($start);
   $self->end($end);
   $self->strand($strand);
   $self->score($score);
   $self->seqname($seqname);
   $self->hstart($hstart);
   $self->hend($hend);
   $self->hstrand($hstrand);
   $self->hscore($hscore);
   $self->hseqname($hseqname);
   $self->analysis($analysis);
   $self->p_value    ($e_value)   if (defined $e_value);
   $self->percent_id ($perc_id)   if (defined $perc_id);
   $self->phase      ($phase)     if (defined $phase);
   $self->end_phase  ($end_phase) if (defined $end_phase);
}

sub set_all_fields{
   my ($self, $start, $end, $strand, $score, $source, $primary, $seqname,
       $hstart, $hend, $hstrand, $hscore, $hsource, $hprimary, $hseqname, 
       $e_value, $perc_id, $phase, $end_phase) = @_;
    
   $self->warn("set_all_fields deprecated, use set_featurepair_fields instead\n- note this is not just a change of name, set_featurepair_fields\nexpects different arguments! $!");

    $self->start($start);
    $self->end($end);
    $self->strand($strand);
    $self->score($score);
    $self->source_tag($source);
    $self->primary_tag($primary);
    $self->seqname($seqname);
    $self->hstart($hstart);
    $self->hend($hend);
    $self->hstrand($hstrand);
    $self->hscore($hscore);
    $self->hsource_tag($hsource);
    $self->hprimary_tag($hprimary);
    $self->hseqname($hseqname);
    $self->p_value    ($e_value)   if (defined $e_value);
    $self->percent_id ($perc_id)   if (defined $perc_id);
    $self->phase      ($phase)     if (defined $phase);
    $self->end_phase  ($end_phase) if (defined $end_phase);
}

=head2 to_FTHelper

 Title   : to_FTHelper
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub to_FTHelper{
   my ($self) = @_;

   # Make new FTHelper, and fill in the key
   my $fth = Bio::SeqIO::FTHelper->new;
   $fth->key('similarity');
   
   # Add location line
   my $g_start = $self->start;
   my $g_end   = $self->end;
   my $loc = "$g_start..$g_end";
   if ($self->strand == -1) {
        $loc = "complement($loc)";
    }
   $fth->loc($loc);
   
   # Add note describing similarity
   my $type    = $self->hseqname;
   my $r_start = $self->hstart;
   my $r_end   = $self->hend;
   $fth->add_field('note', "$type: matches $r_start to $r_end");
   $fth->add_field('note', "score=".$self->score);
   
   return $fth;
}


sub gffstring {
    my ($self) = @_;

    my $str;
    my $strand = "+";

    if ($self->strand == -1) {
      $strand = "-";
    }

    #hope this doesn't slow things down too much
    $str .= (defined $self->seqname)    ?   $self->seqname."\t"     :  "\t";
    $str .= (defined $self->source_tag) ?   $self->source_tag."\t"  :  "\t";
    $str .= (defined $self->primary_tag)?   $self->primary_tag."\t" :  "\t";
    $str .= (defined $self->start)      ?   $self->start."\t"       :  "\t";
    $str .= (defined $self->end)        ?   $self->end."\t"         :  "\t";
    $str .= (defined $self->score)      ?   $self->score."\t"       :  "\t";
    $str .= $strand . "\t";
    $str .= (defined $self->phase)      ?   $self->phase."\t"       :  ".\t";
    $str .= (defined $self->hseqname)   ?   $self->hseqname."\t"    :  "\t";
    $str .= (defined $self->hstart)     ?   $self->hstart."\t"      :  "\t";
    $str .= (defined $self->hend)       ?   $self->hend."\t"        :  "\t";
    $str .= (defined $self->hstrand)    ?   $self->hstrand."\t"     :  "\t";
    $str .= (defined $self->hphase)     ?   $self->hphase."\t"      :  ".\t";
    
    return $str;
}




=head2 hphase

 Title   : hphase
 Usage   : $hphase = $fp->hphase()
           $fp->hphase($hphase)
 Function: get/set on start hphase of predicted feature2
 Returns : [0,1,2]
 Args    : none if get, 0,1 or 2 if set. 

=cut

sub hphase {
  my ($self, $value) = @_;
  
  if (defined($value)) {
    $self->{_hphase} = $value;
  }
  
  return $self->{_hphase};
}


=head2 hend_phase

 Title   : hend_phase
 Usage   : $hend_phase = $feat->hend_phase()
           $feat->hend_phase($hend_phase)
 Function: get/set on end phase of predicted feature2
 Returns : [0,1,2]
 Args    : none if get, 0,1 or 2 if set. 

=cut

sub hend_phase {
  my ($self, $value) = @_;
    
  if (defined($value)) {
    $self->{_hend_phase} = $value;
  }
  
  return $self->{_hend_phase};
}






=head2 hscore

 Title   : hscore
 Usage   : $score = $feat->score()
           $feat->score($score)
 Function: get/set on score information
 Returns : float
 Args    : none if get, the new value if set


=cut

sub hscore {
    my ($self,$arg) = @_;

    $self->warn("FeaturePair::hscore is deprecated.  " .
		"Just use FeaturePair::score");
    
    if (defined($arg)) {
	$self->{_hscore} = $arg;
    } 

    return $self->{_hscore};
}


=head2 hframe

 Title   : hframe
 Usage   : $frame = $feat->frame()
           $feat->frame($frame)
 Function: get/set on frame information
 Returns : 0,1,2
 Args    : none if get, the new value if set

=cut

sub hframe {
  my ($self,$arg) = @_;
 
  $self->warn("FeaturePair::hframe is deprecated just use FeaturePair::frame");
 
  if (defined($arg)) {
    $self->{_hframe} = $arg;
  } 
  
  return $self->{_hframe};
}

=head2 hprimary_tag

 Title   : hprimary_tag
 Usage   : $ptag = $featpair->hprimary_tag
 Function: Get/set on the primary_tag of feature2
 Returns : 0,1,2
 Args    : none if get, the new value if set

=cut

sub hprimary_tag{
  my ($self,$arg) = @_;
  
  $self->warn("FeaturePair::hprimary_tag is deprecated, this is now part of" .
	      "the analysis object accessable by FeaturePair::analysis");
  
  if (defined($arg)) {
    $self->{_hprimary_tag} = $arg;
  }

  return $self->{_hprimary_tag};
}

=head2 hsource_tag

 Title   : hsource_tag
 Usage   : $tag = $feat->hsource_tag()
           $feat->source_tag('genscan');
 Function: Returns the source tag for a feature,
           eg, 'genscan' 
 Returns : a string 
 Args    : none

=cut

sub hsource_tag{
    my ($self,$arg) = @_;

 $self->warn("FeaturePair::hprimary_tag is deprecated, this is now part of" .
	      "the analysis object accessable by FeaturePair::analysis");

    if (defined($arg)) {
	$self->{_hsource_tag} = $arg;
    }

    return $self->{_hsource_tag};
}

=head2 hpercent_id

 Title   : hpercent_id
 Usage   : $percent_id = $featpair->hpercent_id
           $featpair->hpercent_id($pid)
 Function: Get/set on the percent_id of feature2
 Returns : integer
 Args    : none

=cut

sub hpercent_id {
    my ($self,$value) = @_;
    
    $self->warn("FeaturePair::hpercent_id is deprecated " .
		"Just use FeaturePair::percent_id");

    if (defined($value)) {
      $self->{_hpercent_id} = $value;
    }     
    
    return $self->{_hpercent_id};
}


=head2 hp_value

 Title   : hp_value
 Usage   : $p_value = $featpair->hp_value
           $featpair->hp_value($p_value)
 Function: Get/set on the p_value of feature2
 Returns : integer
 Args    : none

=cut

sub hp_value {
  my ($self,$value) = @_;

  $self->warn("FeaturePair::hp_value is deprecated. " .
	      "Just use FeaturePair::p_value"); 
    
  if($value) {
    $self->{_hp_value} = $value;
  }

  return $self->{_hp_value};
}


1;
