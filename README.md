# ServiceNow::SOAP

This module and this site are still **UNDER CONSTRUCTION**.

View the perldoc at http://gflewis.github.io/servicenow-soap/perldoc.html

## Description

A better Perl API for ServiceNow.

Features of this module include:

* Simple API which closely mirrors
ServiceNow's Direct Web Services API documentation.

* Easy to use methods for reading tables
that follow best practice recommendations
and overcome ServiceNow's built-in default limitation
of 250 records per Web Services call.

* Specialized functions such as attachFile and getVariables.

## Installation

To install this module

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

## Dependencies

This module requires these and other modules and libraries:

    SOAP::Lite
    LWP::UserAgent
    HTTP::Cookies
    MIME::Base64
    XML::Simple
    Time::HiRes

## License and Copyright

Copyright (C) 2015 Giles Lewis

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0).

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

