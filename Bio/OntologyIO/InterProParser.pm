# $GNF: projects/gi/symgene/src/perl/seqproc/Bio/OntologyIO/InterProParser.pm,v 1.5 2003/02/07 22:05:58 pdimitro Exp $
#
# BioPerl module for InterProParser
#
# Cared for by Peter Dimitrov <dimitrov@gnf.org>
#
# Copyright Peter Dimitrov
# (c) Peter Dimitrov, dimitrov@gnf.org, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# POD documentation - main docs before the code

=head1 NAME

InterProParser - Parser for InterPro xml files.

=head1 SYNOPSIS

    # don't use this module directly - use Bio::OntologyIO with instead
    my $ipp = Bio::OntologyIO->new( -format  => 'interpro',
                                    -file    => 't/data/interpro.xml',
                                    -ontology_engine => 'simple' );

=head1 DESCRIPTION

  Use InterProParser to parse InterPro files in xml format. Typical
  use is the interpro.xml file published by EBI. The xml records
  should follow the format described in interpro.dtd, although the dtd
  file is not needed, and the XML file will not be validated against
  it.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
email or the web:

  bioperl-bugs@bioperl.org
  http://bugzilla.bioperl.org/

=head1 AUTHOR - Peter Dimitrov

Email dimitrov@gnf.org

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::OntologyIO::InterProParser;
use vars qw(@ISA);
use strict;
use Carp;
use XML::Parser::PerlSAX;
use Bio::OntologyIO;
use Bio::OntologyIO::Handlers::InterProHandler;

@ISA = qw( Bio::OntologyIO );

=head2 new

 Title   : new
 Usage   :
 Function: Initializes objects needed for parsing.
 Example : $ipp = Bio::OntologyIO::InterProParser->new( -file => 't/interpro.xml',
							-ontology_engine => 'simple' )

           Note that this method really is _initialize, which is
           automatically called by OntologyIO::new().

 Returns : Object of class Bio::OntologyIO::InterProParser.
 Args    :

  -file            - file name
  -ontology_engine - type of ontology engine. Should satisfy the
                     OntologyEngine interface requirements. Currently
                     the only option is 'simple'. In the future
                     Graph.pm based engine will be added to the
                     choices.


=cut

# in reality we let OntologyIO handle the first pass initialization
# and instead override _initialize().
sub _initialize{
    my $self = shift;

    $self->SUPER::_initialize(@_);

    my ($eng_type) = $self->_rearrange([qw(ONTOLOGY_ENGINE
					   )
					], @_);
    my $ont_eng;
    if(lc($eng_type) eq 'simple') {
	$ont_eng = Bio::Ontology::SimpleOntologyEngine->new();
    } else {
	$self->throw("ontology engine type '$eng_type' not implemented yet");
    }

    my $ip_h = Bio::OntologyIO::Handlers::InterProHandler->new;
    $ip_h->ontology_engine($ont_eng);
    $self->{_parser} = XML::Parser::PerlSAX->new( Handler => $ip_h );
    $self->{_ontology_engine} = $ont_eng;
    $self->{_interpro_handler} = $ip_h;

}

=head2 parse

 Title   : parse
 Usage   :
 Function: Performs the actual parsing.
 Example : $ipp->parse();
 Returns : 
 Args    :


=cut

sub parse{
   my $self = shift;

   my $ret = $self->{_parser}->parse( Source => {
       SystemId => $self->file() } );
   $self->_is_parsed(1);
   return $ret;
}

=head2 next_ontology

 Title   : next_ontology
 Usage   : $ipp->next_ontology()
 Function: Parses the input file and returns the next InterPro ontology
           available.

           Usually there will be only one ontology returned from an
           InterPro XML input.

 Example : $ipp->next_ontology();
 Returns : Returns the ontology as a L<Bio::Ontology::OntologyEngineI>
           compliant object.
 Args    : 


=cut

sub next_ontology{
  my $self = shift;

  $self->parse() unless $self->_is_parsed();
  # there is only one ontology in an InterPro source file
  if(exists($self->{'_ontology_engine'})) {
      my $ont = $self->{_interpro_handler}->ontology();
      delete $self->{_ontology_engine};
      return $ont;
  }
  return undef;
}

=head2 _is_parsed

 Title   : _is_parsed
 Usage   : $obj->_is_parsed($newval)
 Function: 
 Example : 
 Returns : value of _is_parsed (a scalar)
 Args    : on set, new value (a scalar or undef, optional)


=cut

sub _is_parsed{
    my $self = shift;

    return $self->{'_is_parsed'} = shift if @_;
    return $self->{'_is_parsed'};
}

=head2 secondary_accessions_map

 Title   : secondary_accessions_map
 Usage   : $obj->secondary_accessions_map()
 Function:  This method is merely for convenience, and one should
 normally use the InterProTerm secondary_ids method to access
 the secondary accessions.
 Example : $map = $interpro_parser->secondary_accessions_map;
 Returns : Reference to a hash that maps InterPro identifier to an
  array reference of secondary accessions following the InterPro
 xml schema.
 Args    : Empty hash reference

=cut

sub secondary_accessions_map{
  my ($self) = @_;

  return $self->{_interpro_handler}->{secondary_accessions_map};
}

1;
