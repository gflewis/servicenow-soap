package ServiceNow::SOAP:Table;

our $VERSION = '0.21';
# v 0.10 2015-04-05 LewisGF initial version based on AltServiceNow

use strict;

use SOAP::Lite;
use LWP::UserAgent;
use HTTP::Cookies;
use MIME::Base64;
use XML::Simple;
use Time::HiRes;
use Carp;

our $DEFAULT_CHUNK = 200;
our $DEFAULT_DV = 0;

# utility function to return true if argument is a sys_id
sub _isGUID { 
    return $_[0] =~ /^[0-9A-Fa-f]{32}$/; 
}

# utility function to truncate a string
our $TRACE_LENGTH = 100;
sub _trunc { 
    my ($str, $len) = @_;
    $len = $TRACE_LENGTH unless $len;
    return length($str) < $len ? $str : substr($str, 0, $len - 2) . "..";
}

sub new {
    my ($pkg, $session, $name) = @_;
    $context = $session;
    my $baseurl = $session->{url}; 
    my $cookie_jar = $session->{cookie_jar};
    my $endpoint = "$baseurl/$name.do?SOAP";
    my $client = SOAP::Lite->proxy($endpoint, cookie_jar => $cookie_jar);
    my $new = bless {
        session => $session,
        name => $name,
        endpoint => $endpoint,
        client => $client,
        dv => $DEFAULT_DV,
        chunk => $DEFAULT_CHUNK,
        trace => $session->{trace}
    }, $pkg;
    return $new;
}

sub _soapParams {
    my @params;
    # if there are at least 2 parameters then they must be name/value pairs
    while (scalar(@_) > 1) {
        my $name = shift;
        my $value = shift;
        push @params, SOAP::Data->name($name, $value);
    }
    if (@_) {
        # there is one parameter left
        $_ = shift;
        if ($_ eq '*') { } # ignore an asterisk
        elsif (/^[0-9A-Fa-f]{32}$/) { 
            # it looks like a sys_id
            push @params, SOAP::Data->name(sys_id => $_); 
        }
        else {
            # assume any left over unnamed param is an encoded query
            push @params, SOAP::Data->name(__encoded_query => $_)
        }
    }
    return @params;
}

sub callMethod {
    my $self = shift;
    my $methodname = shift;
    my $trace = $self->{trace};
    my $baseurl = $self->{session}->{url};
    my $tablename = $self->{name};
    my $endpoint = "$baseurl/$tablename.do?SOAP";
    if (($methodname eq 'get' || $methodname eq 'getRecords') && $self->{dv}) {
        my $dv = $self->{dv};
        $endpoint = "$baseurl/$tablename.do?displayvalue=" . $dv . "&SOAP";
    }
    $context = $self->{session};
    my $method = SOAP::Data->name($methodname)->attr({xmlns => $xmlns});
    my $client = $self->{client};
    my $som = $client->endpoint($endpoint)->call($method => @_);
    Carp::croak $som->faultdetail if $som->fault;        
    return $som;
}

our $startTime;

sub traceBefore {
    my ($self, $methodname) = @_;
    my $trace = $self->{trace};
    return unless $trace;
    my $tablename = $self->{name};
    $| = 1;
    print "$tablename $methodname...";
    $startTime = Time::HiRes::time();
}

sub traceAfterContent {
    my $self = shift;
    my $content = shift;
    my $trace = $self->{trace};
    return unless $trace;
    my $finishTime = Time::HiRes::time();
    my $elapsed = $finishTime - $startTime;
    print sprintf(" %.2fs ", $elapsed), @_, "\n";
    if ($trace > 1) {
        $content = $self->{client}->transport()->http_response()->content() unless $content;
        print $content, "\n";
    }
}

sub traceAfter {
    my $self = shift;
    $self->traceAfterContent('', @_);
}

=head2 get

=head3 Description

Retrieves a single record.  The result is returned as a reference to a hash.

If no matching record is found then null is returned.

For additional information
refer to the ServiceNow documentation on the 
L<"get" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#get>.

=head3 Syntax

    $rec = $table->get(sys_id => $sys_id);
    $rec = $table->get($sys_id);

=head3 Example
    
    my $rec = $table->get($sys_id);
    print $rec->{name};
    
=cut

sub get {
    my $self = shift;
    my $tablename = $self->{name};
    # Carp::croak("get $tablename: no parameter") unless @_; 
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    $self->traceBefore('get');
    my $som = $self->callMethod('get' => _soapParams(@_));
    $self->traceAfter();
    my $result = $som->body->{getResponse};
    return $result;
}

=head2 getKeys

=head3 Description

Returns a list of keys.
Note that this method returns a list of keys, B<NOT> a comma delimited list.

For additional information on available parameters
refer to the ServiceNow documentation on the 
L<"getKeys" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#getKeys>.

=head3 Syntax

    @keys = $table->getKeys(%parameters);
    @keys = $table->getKeys($encodedquery);

=head3 Examples

    my $cmdb_ci_computer = $sn->table("cmdb_ci_computer");
    
    my @keys = $cmdb_ci_computer->getKeys(operational_status => 1, virtual => "false");
    # or
    my @keys = $cmdb_ci_computer->getKeys("operational_status=1^virtual=false");
    
=cut

sub getKeys {
    my $self = shift;
    my @params = _soapParams(@_);
    $self->traceBefore('getKeys');
    my $som = $self->callMethod('getKeys', @params);
    my @keys = split /,/, $som->result;
    my $count = @keys;
    $self->traceAfter("$count keys");
    return @keys;
}

=head2 getRecords

=head3 Description

Returns a list of records. Actually, it returns a list of hash references.
You may pass this function either a single encoded query,
or a list of name/value pairs.

For additional information on available parameters
refer to the ServiceNow documentation on the 
L<"getRecords" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#getRecords>.

B<Important Note>: This method will return at most 250 records, unless
you specify a C<__limit> parameter as documented in the ServiceNow wiki under
L<Extended Query Parameters|http://wiki.servicenow.com/index.php?title=Direct_Web_Services#Extended_Query_Parameters>.

=head3 Syntax

    @recs = $table->getRecords(%parameters);
    @recs = $table->getRecords($encodedquery);

=head3 Example

    my $sys_user_group = $sn->table("sys_user_group");
    my @grps = $sys_user_group->getRecords(
        active => true, __limit => 500, __order_by => "name");
    foreach my $grp (@grps) {
        print $grp->{name}, "\n";
    }
    
=cut

sub getRecords {
    my $self = shift;
    $self->traceBefore('getRecords');
    my $som = $self->callMethod('getRecords' => _soapParams(@_));
    my $response = $som->body->{getRecordsResponse};
    unless (ref $response eq 'HASH') {
        $self->traceAfter("0 records");
        return ();
    }
    my $result = $response->{getRecordsResult};
    my $type = ref($result);
    die "getRecords: Unexpected $type" unless ($type eq 'ARRAY' || $type eq 'HASH');
    my @records = ($type eq 'ARRAY') ? @{$result} : ($result);
    my $count = @records;
    $self->traceAfter("$count records");
    return @records;
}

=head2 getRecord

=head3 Description

Returns a single qualifying records.  
Returns null if there are no qualifying records.
Dies if there are multiple qualifying records.

=head3 Syntax

    $rec = $table->getRecord(%parameters);
    $rec = $table->getRecord($encodedquery);
    
=head3 Example

    my $number = "CHG12345";
    my $chgRec = $sn->table("change_request")->getRecord(number => $number);
    if ($chgRec) {
        print "Short description = ", $chgRec->{short_description}, "\n";
    }
    else {
        print "$number not found\n";
    }

The following two examples are equivalent.

    my $rec = $table->getRecord(%parameters);
    
    my @recs = $table->getRecords(%parameters);
    die "Too many records" if scalar(@recs) > 1;
    my $rec = $recs[0];
    
=cut

sub getRecord {
    my $self = shift;
    my $tablename = $self->{name};
    my @recs = $self->getRecords(@_);
    Carp::croak("get $tablename: multiple records returned") if @recs > 1;
    return $recs[0];
}

=head2 count

=head3 Description

Counts the number of records in a table, 
or the number of records that match a set of parameters.

This method requres installation of the
L<Aggregate Web Service plugin|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#aggregate>.

=head3 Syntax 

    my $count = $table->count();
    my $count = $table->count(%parameters);
    my $count = $table->count($encodedquery);

=head3 Examples

Count the total number of users:

    my $count = $sn->table("sys_user")->count();
    
Count the number of active users:

    my $count = $sn->table("sys_user")->count(active => true);
    
=cut

sub count {
    my $self = shift;
    my @params = (SOAP::Data->name(COUNT => 'sys_id'));
    push @params, _soapParams(@_) if @_;
    $self->traceBefore('aggregate count');
    my $som = $self->callMethod('aggregate' => @params);
    my $count = $som->body->{aggregateResponse}->{aggregateResult}->{COUNT};
    $self->traceAfter("count=$count");
    return $count;
}

=head2 insert

=head3 Description

Inserts a record.
In a scalar context, this function returns a sys_id only.
In a list context, this function returns a list of name/value pairs.

For information on available parameters
refer to the ServiceNow documentation on the 
L<"insert" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#insert>.

=head3 Syntax

    my $sys_id = $table->insert(%values);
    my %result = $table->insert(%values);
    
=head3 Examples

    my $incident = $sn->table("incident");

In a scalar context, the function returns a sys_id.

    my $sys_id = $incident->insert(
        short_description => $short_description,
        assignment_group => "Network Support",
        impact => 3);
    print "sys_id=", $sys_id, "\n";

In a list context, the function returns a list of name/value pairs.

    my %result = $incident->insert(
        short_description => $short_description,
        assignment_group => "Network Support",
        impact => 3);
    print "number=", $result{number}, "\n";
    print "sys_id=", $result{sys_id}, "\n";

You can also call it this way:

    my %rec;
    $rec{short_description} = $short_description;
    $rec{assignment_group} = "Network Support";
    $rec{impact} = 3;
    my $sys_id = $incident->insert(%rec);

Note that for reference fields (e.g. assignment_group, assigned_to)
you may pass in either a sys_id or a display value.

=cut

sub insert {
    my $self = shift;
    $self->traceBefore('insert');
    my $som = $self->callMethod('insert' => _soapParams(@_));
    my $response = $som->body->{insertResponse};
    my $sysid = $response->{sys_id};
    $self->traceAfter();
    return wantarray ? %{$response} : $sysid;
}

=head2 update

=head3 Description

Updates a record.
For information on available parameters
refer to the ServiceNow documentation on the 
L<"update" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#update>.

=head3 Syntax

    $table->update(%parameters);
    $table->update($sys_id, %parameters);

Note: If the first syntax is used, 
then the C<sys_id> must be included among the parameters.
If the second syntax is used, then the C<sys_id>
must be the first parameter.

For reference fields (e.g. assignment_group, assigned_to)
you may pass in either a sys_id or a display value.

=head3 Examples

The following three examples are equivalent.

    $incident->update(
        sys_id => $sys_id, 
        assigned_to => "5137153cc611227c000bbd1bd8cd2005",
        incient_state => 2);
        
    $incident->update(
        sys_id => $sys_id, 
        assigned_to => "Fred Luddy", 
        incident_state => 2);
    
    $incident->update($sys_id, 
        assigned_to => "Fred Luddy", 
        incident_state => 2);

=cut

sub update {
    my $self = shift;
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    my %values = @_;
    my $sysid = $values{sys_id};
    $self->traceBefore("update $sysid");
    my $som = $self->callMethod('update' => _soapParams(@_));
    $self->traceAfter();
    return $self;
}

=head2 deleteRecord

=head3 Description

Deletes a record.
For information on available parameters
refer to the ServiceNow documentation on the 
L<"deleteRecord" Direct SOAP API method|http://wiki.servicenow.com/index.php?title=SOAP_Direct_Web_Service_API#deleteRecord>.

=head3 Syntax

    $table->deleteRecord(sys_id => $sys_id);
    $table->deleteRecord($sys_id);

=cut

sub deleteRecord {
    my $self = shift;
    if (_isGUID($_[0])) { unshift @_, 'sys_id' };
    my %values = @_;
    my $sysid = $values{sys_id};
    $self->traceBefore("delete $sysid");
    my $som = $self->callMethod('delete' => _soapParams(@_));
    $self->traceAfter();
    return $self;
}

=head2 query

=head3 Description

This function creates a new Query object
by calling L</getKeys>.

=head3 Syntax

    my $query = $table->query(%parameters);
    my $query = $table->query($encodedquery};
    
=head3 Example

The following example builds a list of all Incidents 
created between 1/1/2014 and 2/1/2014 sorted by creation date/time.
The C<fetchAll> method fetches chunks of records 
until all records have been retrieved.

    my $filter = "sys_created_on>=2014-01-01^sys_created_on<2014-02-01";
    my $qry = $sn->table("incident")->query(
        __encoded_query => $filter,
        __order_by => "sys_created_on);
    my @recs = $qry->fetchAll();

=cut

sub query {
    my $self = shift;
    my $query = ServiceNow::SOAP::Query->new($self);
    my @keys = $self->getKeys(@_);
    # parameters which affect order or columns must be preserved
    # so that they can be passed to getRecords
    my %params = @_;
    for my $k (keys %params) {
        delete $params{$k} unless $k =~ /^(__order|__exclude|__use_view)/;
    }
    $query->{keys} = \@keys;
    $query->{count} = scalar(@keys);
    $query->{params} = \%params;
    $query->{index} = 0;
    return $query;
}

=head2 asQuery

=head3 Description

This function creates a new Query object from a list of keys.
It does not make any Web Services calls.
It simply makes a copy of the list.
Each item in the list must be a sys_id for the respective table.

=head3 Syntax

    my $query = $table->asQuery(@keys);

=head3 Example

In this example, we assume that C<@incRecs> contains an array of C<incident> records
from a previous query.
We need an array of C<sys_user_group> records
for all referenced assignment groups.
We use C<map> to extract a list of assignment group keys from the C<@incRecs>;
C<grep> to discard the blanks; and C<uniq> to discard the duplicates.
C<@grpKeys> contains the list of C<sys_user_group> keys.
This array is then used to construct a new Query using L</asQuery>
and L</fetchAll> is used to retrieve the records.

    use List::MoreUtils qw(uniq);

    my @grpKeys = uniq grep { !/^$/ } map { $_->{assignment_group} } @incRecs;
    my @grpRecs = $sn->table("sys_user_group")->asQuery(@grpKeys)->fetchAll();
        
=cut

sub asQuery {
    my $self = shift;
    my $query = ServiceNow::SOAP::Query->new($self);
    my @keys = @_;
    $query->{keys} = \@keys;
    $query->{count} = scalar(@keys);
    $query->{params} = {};
    $query->{index} = 0;
    return $query;
}
    
=head2 attachFile

=head3 Description

If you are using Perl to create incident tickets,
then you may have a requirement to attach files to those tickets.

This function implements the
L<attachment creator API|http://wiki.servicenow.com/index.php?title=AttachmentCreator_SOAP_Web_Service>.
The function requires insert permissions on the C<ecc_queue> table.

You will need to specify a MIME type.
If no type is specified,
this function will use a default type of "text/plain" 
For a list of MIME types, refer to 
L<http://en.wikipedia.org/wiki/Internet_media_type>.

When you attach a file to a ServiceNow record,
you can also specify an attachment name
which is different from the actual file name.
If no attachment name is specified,
this function will
assume that the attachment name is the same as the file name.

This function will die if the file cannot be read.

=head3 Syntax

    $table->attachFile($sys_id, $filename, $mime_type, $attachment_name);

=head3 Example

    $incident->attachFile($sys_id, "screenshot.png", "image/png");
    
=cut

sub attachFile {
    my $self = shift;
    my ($sysid, $filename, $mimetype, $attachname) = @_;
    Carp::croak "attachFile: No such record" unless $self->get($sysid);
    $mimetype = "text/plain" unless $mimetype;
    $attachname = $filename unless $attachname;
    Carp::croak "Unable to read file \"$filename\"" unless -r $filename;
    my $session = $self->{session};
    my $ecc_queue = $self->{ecc_queue} ||
        ($self->{ecc_queue} = $session->table('ecc_queue'));
    open(FILE, $filename) or die "Unable to open \"$filename\"\n$!";
    my ($buf, $base64);
    # encode in multiples of 57 bytes to ensure no padding in the middle
    while (read(FILE, $buf, 60*57)) {
        $base64 .= MIME::Base64::encode_base64($buf);
    }
    close FILE;
    my $tablename = $self->{name};
    my $sysid = $ecc_queue->insert(
        topic => 'AttachmentCreator',
        name => "$attachname:$mimetype",
        source => "$tablename:$sysid",
        payload => $base64
    );
    die "attachFile failed" unless $sysid;
}

=head2 getVariables

=head3 Description

This function returns a list of hashes 
of the variables attached to a Requested Item (RITM).

B<Note>: This function currently works only for the C<sc_req_item> table.

Each hash contains the following four fields:

=over

=item *

name - Name of the variable.

=item *

question - The question text.

=item *

reference - If the variable is a reference, then the name of the table.
Otherwise blank.

=item *

value - Value of the question response.
If the variable is a reference, then value will contain a sys_id.

=item *

order - Order (useful for sorting).

=back

=head3 Syntax

    $sc_req_item = $sn->table("sc_req_item");
    @vars = $sc_req_item->getVariables($sys_id);
    
=head3 Example

    my $sc_req_item = $sn->table("sc_req_item");
    my $ritmRec = $sc_req_item->getRecord(number => $ritm_number);
    my @vars = $sc_req_item->getVariables($ritmRec->{sys_id});
    foreach my $var (sort { $a->{order} <=> $b->{order} } @vars) {
        print "$var->{name} = $var->{value}\n";
    }

=cut

sub getVariables {
    my $self = shift;
    Carp::croak "getVariables: invalid table" unless $self->{name} eq 'sc_req_item';
    my $sysid = shift;
    Carp::croak "getVariables: invalid sys_id: $sysid" unless _isGUID($sysid);
    my $session = $self->{session};
    my $sc_item_option = $self->{sc_item_option} ||
        ($self->{sc_item_option} = $session->table('sc_item_option'));
    my $sc_item_option_mtom = $self->{sc_item_option_mtom} ||
        ($self->{sc_item_option_mtom} = $session->table('sc_item_option_mtom'));
    my $item_option_new = $self->{item_option_new} ||
        ($self->{item_option_new} = $session->table('item_option_new'));
    my @vmtom = $sc_item_option_mtom->getRecords('request_item', $sysid);
    my $vrefkeys = join ',', map { $_->{sc_item_option} } @vmtom;
    my @vref = $sc_item_option->getRecords('sys_idIN' . $vrefkeys);
    my $vvalkeys = join ',', map { $_->{item_option_new} } @vref;
    my @vval = $item_option_new->getRecords('sys_idIN' . $vvalkeys);
    my %vvalhash = map { $_->{sys_id} => $_ } @vval;
    my @result;
    foreach my $v (@vref) {
        next unless _isGUID($v->{item_option_new});
        my $n = $vvalhash{$v->{item_option_new}};
        my $var = {
            name      => $n->{name},
            reference => $n->{reference},
            question  => $n->{question_text},
            value     => $v->{value},
            order     => $n->{order}
        };
        push @result, $var;
    }
    return @result;
}

=head2 setDV

=head3 Description

Used to enable (or disable) display values in queries.
All subsequent calls to L</get>, L</getRecords> or L</getRecord> 
for this table will be affected.
This function returns the modified Table object.

For additional information regarding display values refer to the ServiceNow documentation on
L<"Return Display Value for Reference Variables"|http://wiki.servicenow.com/index.php?title=Direct_Web_Services#Return_Display_Value_for_Reference_Variables>

=head3 Syntax

    $table->setDV("true");
    $table->setDV("all");
    $table->setDv("");  # restore default setting

=head3 Examples

    my $sys_user_group = $session->table("sys_user_group")->setDV("true");
    my $grp = $sys_user_group->getRecord(name => "Network Support");
    print "manager=", $grp->{manager}, "\n";

    my $sys_user_group = $session->table("sys_user_group")->setDV("all");
    my $grp = $sys_user_group->getRecord(name => "Network Support");
    print "manager=", $grp->{dv_manager}, "\n";
    
=cut

sub setDV {
    my ($self, $dv) = @_;
    $self->{dv} = $dv;
    return $self;
}

sub setTrace {
    my ($self, $trace) = @_;
    $self->{trace} = $trace;
    return $self;
}

sub setChunk {
    my $self = shift;
    $self->{chunk} = shift || $DEFAULT_CHUNK;
    return $self;
}

=head2 setTimeout

=head3 Description

Set the value of the SOAP Web Services client HTTP timeout.
In addition, you may need to increase the ServiceNow system property
C<glide.soap.request_processing_timeout>.
    
=head3 syntax

    $table->setTimeout($seconds);
    
=cut

sub setTimeout {
    my ($self, $seconds) = @_;
	$seconds = 180 unless defined($seconds) && $seconds =~ /\d+/;
	$self->{client}->transport()->timeout($seconds);
	return $self;
}

sub getSchema {
    my $self = shift;
    return $self->{wsdl} if $self->{wsdl};
    my $session = $self->{session};
    my $user = $session->{user};
    my $pass = $session->{pass};
    my $baseurl = $session->{url};
    my $host = $baseurl; $host =~ s!^https?://!!;
    my $useragent = LWP::UserAgent->new();
    $useragent->credentials("$host:443", "Service-now", $user, $pass);
    my $tablename = $self->{name};
    $self->traceBefore('wsdl');
    my $response = $useragent->get("$baseurl/$tablename.do?WSDL");
    die $response->status_line unless $response->is_success;
    $self->traceAfterContent($response->content);
    my $wsdl = XML::Simple::XMLin($response->content);
    $self->{wsdl} = $wsdl;
    return $wsdl;
}

=head2 getFields

=head3 Description

Returns a hash of the fields in an sequence (complex type) from the WSDL.  
The hash key is the field name.
The hash value is the field type.

=head3 Syntax

    %fields = $table->getFields($type);
    
=head3 Example

    my %fields = $sn->table("sys_user_group")->getFields("getRecordsResponse");
    foreach my $name (sort keys %fields) {
        print "name=$name type=$fields{$name}\n";
    }

=cut

sub getFields {
    my ($self, $schematype) = @_;
    my $wsdl = $self->getSchema();
    my $schematype = 'getResponse' unless $schematype;
    my $elements = $wsdl->{'wsdl:types'}{'xsd:schema'}{'xsd:element'}{$schematype}
        {'xsd:complexType'}{'xsd:sequence'}{'xsd:element'};
    my %result = map { $_ => $elements->{$_}{'type'} } keys %{$elements};
    return %result;
}

sub getColumns {
    my $self = shift;
    return @{$self->{columns}} if $self->{columns};
    my %fields = $self->getFields();
    my @columns = sort keys %fields;
    $self->{columns} = \@columns;
    return @columns;
}

sub getExcluded {
    my $self = shift;
    my %names = map { $_ => 1 } @_;
    my @result = grep { !$names{$_} } $self->getColumns();
    return @result;
}
