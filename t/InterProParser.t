# -*-Perl-*-
## Bioperl Test Harness Script for Modules
## $GNF: projects/gi/symgene/src/perl/seqproc/t/InterProParser.t,v 1.7 2003/02/07 22:05:58 pdimitro Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    if( $@ ) {
        use lib 't';
    }
    use Test;
    plan tests => 39;
}

use Bio::OntologyIO;
use Bio::Root::IO;

my $io = Bio::Root::IO->new();

ok (1);

my $ipp = Bio::OntologyIO->new( -format => 'interpro',
				-file =>
				$io->catfile('t','data','interpro_short.xml'),
				-ontology_engine => 'simple' );
ok ($ipp);

my $ip;
while(my $ont = $ipp->next_ontology()) {
    # there should be only one ontology
    ok ($ip, undef);
    $ip = $ont;
}
#print $ip->to_string."\n";
my @rt = sort { $a->name cmp $b->name; } $ip->get_root_terms();

# there should be 4 root terms: InterPro Domain, InterPro Family,
# InterPro Repeat, and InterPro PTM (Post Translational Modification)
ok (scalar(@rt), 4);

# every InterPro term should have an ontology,
foreach ($ip->get_leaf_terms, @rt) {
    ok ($_->ontology);
    ok ($_->ontology->name, "InterPro",
	"term ".$_->name." not in ontology InterPro");
}

# there are 6 fully instantiated InterPro terms in total, which should be returned as the leafs
ok (scalar($ip->get_leaf_terms()), 6);
# roots and leafs together:
ok (scalar($ip->get_all_terms()), 11);

# descendants and children (synonymous here because of depth 1)
# note that the sort should have placed Domain first and Family second
ok (scalar($ip->get_descendant_terms($rt[0])), 4); # 4 InterPro Domains
ok (scalar($ip->get_child_terms($rt[0])), 4);      # dto.
ok (scalar($ip->get_descendant_terms($rt[1])), 3); # 3 Interpro Family
ok (scalar($ip->get_child_terms($rt[1])), 3);      # dto.

# test for ancestors and parents (synonymous here because of depth 1)
foreach my $t ($ip->get_leaf_terms) {
    # every InterPro term has exactly one parent - namely either 
    # Domain, Family, Repeat, or PTM(Post Transl. Modification)
    if (!($t->identifier eq "Repeat" || $t->identifier eq "PTM")) {
	ok (scalar($ip->get_parent_terms($t)), 1);
	ok (scalar($ip->get_ancestor_terms($t)), 1);
    }
}

# test for secondary accession map
ok(scalar(keys %{$ipp->secondary_accessions_map}), 2);
