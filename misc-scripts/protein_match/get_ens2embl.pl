use strict;

=head1 Get_ens2ensembl.pl

=head1 Description

=head2 Aims
The aim of thi script is to get from the database the corresponding clones for each Ensembl peptides. This will be then used to postprocess pmatch and get a more sensible mapping.

=cut


use Bio::SeqIO;
use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::DBLoader;
use Getopt::Long;
use Bio::SeqIO;


my $dbpass = undef;
my $dbuser = 'ensro';
my $ensdbname = 'ensembl080';
my $host = 'ecs1c.sanger.ac.uk';
my $output;


&GetOptions(
	    'db:s' => \$ensdbname,
	    'host:s'=> \$host,
	    'dbuser:s'=> \$dbuser,
	    'output:s' => \$output
	    );


my $enslocator = "Bio::EnsEMBL::DBSQL::Obj/host=$host;dbname=$ensdbname;user=$dbuser;pass=$dbpass;perlonlyfeatures=1";
my $ensdb =  Bio::EnsEMBL::DBLoader->new($enslocator);


my $sth = $ensdb->prepare ("select t.id,cl.embl_id from transcript as t, exon_transcript as et, clone as cl, contig as c, exon as e where t.id=et.transcript and et.exon = e.id and e.contig = c.internal_id and c.clone = cl.internal_id");

$sth->execute;

my %hash;
my %seen;

print STDERR "Getting data\n";
while (my @row = $sth->fetchrow) {
    if (! defined $seen{$row[1]}) {
	push(@{$hash{$row[0]}},$row[1]);
	$seen{$row[1]} = 1;
    }
}
    
print STDERR "Writing out\n";
open (OUT,">$output");

foreach my $keys (keys %hash) {
    my @array = @{$hash{$keys}};
    
    foreach my $arr (@array) {
	print OUT "ENSEMBL\t$keys\tEMBL\t$arr\n";
    }
}






