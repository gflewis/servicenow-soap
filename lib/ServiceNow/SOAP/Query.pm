package ServiceNow::SOAP::Query;

our $VERSION = '0.10';

use strict;

use ServiceNow::SOAP::Table;
use Carp;

package ServiceNow::SOAP::Query;
  
=head1 DESCRIPTION

A Query object is essentially a list of keys (sys_ids) for a particular table,
and a pointer to the current position in that list.
Query objects and the related functions
implement the ServiceNow best practice recommendations
for using Web Services to query large tables as documented 
here:
L<http://wiki.servicenow.com/index.php?title=Web_Services_Integrations_Best_Practices#Queries>.

To construct a new Query object use the L<Table/query> 
or L<Table/asQuery> method.

=over

=item *

L</query> makes a Web Services call (L</getKeys>) to retrieve a list of keys.

=item *

L</asQuery> simply converts an exsiting list of keys into a Query object.

=back

Once constructed, the L<fetch|/fetch> and L<fetchAll|/fetchAll> functions
can be used to get the actual records in chunks.

=head1 EXAMPLE

This example illustrates the use of Query objects to traverse 
the C<cmdb_rel_ci> table.
The example involves two tables:
C<cmdb_ci> and C<cmdb_rel_ci>.

    my $cmdb_ci = $sn->table("cmdb_ci");
    my $cmdb_rel_ci = $sn->table("cmdb_rel_ci");
    
We assume that C<$parentKey> is the sys_id of a known configuration item.
The objective is to print a list of all other configuration items 
on which this item immediately depends.
In otherwords, all items which are one level downstream.

First we query C<cmdb_rel_ci> to retrieve a list of 
records for which this item is the parent.
C<@relData> is this list of C<cmdb_rel_ci> records.

    my @relData = $cmdb_rel_ci->query(parent => $parentKey)->fetchAll();

Next we extract the C<child> field from each of these C<cmdb_rel_ci>
records to create a new list of sys_ids   

    my @childKeys = map { $_->{child} } @relData;

C<@childKeys> now contains a lists of sys_ids for configuration items.
We convert this list of keys into a query object
and fetch the records from the C<cmdb_ci> table.
If there are more than 200 records, C<fetchAll> will loop internally 
until all records have been retrieved.
    
    @childRecs = $cmdb_ci->asQuery(@childKeys)->fetchAll();
    foreach my $childRec (@childRecs) {
        print $childRec->{name}, "\n";            
    }

=cut

sub new {
    my ($pkg, $table) = @_;
    return bless {
        table => $table,
        chunk => $table->{chunk},
        count => 0,
        index => 0
    }, $pkg;
}

=head1 METHODS

=head2 fetch

=head3 Description

Fetch the next chunk of records from a table.
In a list context it returns a list of hashes.
In a scalar context it returns a reference to an array of hashes.

This function calls L</getRecords> to retrieve the records.
An optional parameter allows specification of the number of records to be retrieved.
If not specified, then the number of records will be based on 
the default chunk size for this Query object.
If there are no remaining records, then an empty list will be returned.

=head3 Syntax
    
    my @recs = $query->fetch();
    my @recs = $query->fetch($numrecs);

=head3 Example

This example prints the names of all active users.
Each call to L</getRecords> returns up to 100 users.

    my $query = $sn->table("sys_user")->query(active => "true", __order_by => "name");
    while (@recs = $query->fetch(100)) {
        foreach my $rec (@recs) {
            print $rec->{name}, "\n";
        }
    }

=cut

sub fetch {
    my ($self, $chunk) = @_;
    $chunk = $self->{chunk} unless $chunk;
    my @result;
    my $first = $self->{index};
    my $count = $self->{count};
    if ($first < $count) {
        my $table = $self->{table};
        my $last = $first + $chunk - 1;
        my %params = %{$self->{params}};
        $params{__limit} = $chunk if $chunk;
        $last = $count - 1 if $last >= $count;
        my $encodedquery = "sys_idIN" . join(",", @{$self->{keys}}[$first .. $last]);
        @result = $table->getRecords(__encoded_query => $encodedquery, %params);
        $self->{index} = $last + 1;
    }
    return wantarray ? @result : \@result;
}

=head2 fetchAll

=head3 Description

Fetch all the records in a Query by calling L</fetch> repeatedly
until there are no more records.
In a list context it returns a list of hashes.
In a scalar context it returns a reference to an array of hashes.

=head3 Syntax

    my @recs = $query->fetchAll();
    my @recs = $query->fetchAll($chunkSize);
    
=head3 Example

This example prints the names of all active users.
Each call to L</getRecords> returns up to 200 users
since no chunk size was specified and the default is 200.

    my @recs = $sn->table("sys_user")->query(active => "true", __order_by => "name")->fetchAll();
    foreach my $rec (@recs) {
         print $rec->{name}, "\n";
    }

=cut

sub fetchAll {
    my ($self, $chunk) = @_;
    $chunk = $self->{chunk} unless $chunk;
    my @result = ();
    my $recs;
    while ($recs = $self->fetch($chunk) and @$recs > 0) {
        push @result, @$recs;
    }
    return wantarray ? @result : \@result;    
}

=head2 setColumns

=head3 Description

Restricts the list of columns that will be returned.
Returns a reference to the modified Query object.

For some reason the Direct Web Services API allows you to specify a 
list of columns to be excluded from the query result,
but there is no similar capability to specify a list of columns to be included.
This function implements the more obviously needed behavior by inverting the list.
It uses the WSDL to generate a list of columns returned by L</getRecords>,
and subtracts the specified names to create an C<"__exclude_columns">
extended query parameter.

By restricting the results to the needed columns, 
it is possible to significantly reduce the time required for large queries.

=head3 Syntax

    $query->setColumns(@list_of_columns);
    $query->setColumns($comma_delimited_list_of_columns);
    
=head3 Example

    my $tbl = $sn->table("cmdb_ci_computer");
    my $qry = $tbl->query()->setColumns(qw(
        sys_id name sys_class_name 
        operational_status sys_updated_on));
    my @recs = $qry->fetchAll();    

=cut

sub setColumns {
    my $self = shift;
    my $table = $self->{table};
    my @exclude = $table->getExcluded(split /,/, join(',', @_));
    $self->{params}{__exclude_columns} = join(',', @exclude);
    return $self;
}

sub setChunk {
    my $self = shift;
    $self->{chunk} = shift || $DEFAULT_CHUNK;
    return $self;
}

sub getChunk {
    my $self = shift;
    return $self->{chunk};
}

sub setIndex {
    my $self = shift;
    $self->{index} = shift;
    return $self;
}

sub getCount {
    my $self = shift;
    return $self->{count};
}

sub getKeys {
    my $self = shift;
    return @{$self->{keys}};
}

1;

=head1 AUTHOR

Giles Lewis 

=cut
