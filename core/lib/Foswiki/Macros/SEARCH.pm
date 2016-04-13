# See bottom of file for license and copyright information
package Foswiki::Macros;

use strict;
use warnings;
use Try::Tiny;
use Assert;

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

sub SEARCH {
    my ( $this, $params, $topicObject ) = @_;

    # pass on all attrs, and add some more
    #$params->{_callback} = undef;
    $params->{baseweb}   = $topicObject->web;
    $params->{basetopic} = $topicObject->topic;
    $params->{search}    = $params->{_DEFAULT} if defined $params->{_DEFAULT};
    $params->{type}      = $this->prefs->getPreference('SEARCHVARDEFAULTTYPE')
      unless ( $params->{type} );

#TODO: this is a common default that should be extracted into a 'test, default and refine' parameters for all formatResult calls
    if ( defined( $params->{separator} ) ) {
        $params->{separator} =
          $this->expandStandardEscapes( $params->{separator} );
    }

    # newline feature replaces newlines within each search result
    if ( defined( $params->{newline} ) ) {
        $params->{newline} = $this->expandStandardEscapes( $params->{newline} );
    }

    my $s;
    try {
        $s = $this->search->searchWeb(%$params);
    }
    catch {
        my $exception = $_;
        my $message;

        if ( !ref($_) ) {
            Foswiki::Exception::Fatal->rethrow($_);
        }

        # If an unhandled system error took place then let lower level code take
        # care of it.
        # If code is executed in unit test mode then avoid HTMLization of error
        # report.
        if ( $Foswiki::inUnitTestMode
            && !$exception->isa('Foswiki::Infix::Error') )
        {
            Foswiki::Exception::Fatal->rethrow($exception);
        }

        if (DEBUG) {
            $message = $exception->stringify();
        }
        else {
            $message = $exception->text;
            my @lines = split( /\n/, $message );
            $message = $lines[0];
            $message =~ s/ at .*? line \d+\.?$//;
        }

        # Block recursions kicked off by the text being repeated in the
        # error message
        $message =~ s/%([A-Z]*[{%])/%<nop>$1/g;
        $message =~ s/\n/<br \/>/g;
        $s = $this->inlineAlert( 'alerts', 'bad_search', $message );
    };
    return $s;
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 1999-2007 Peter Thoeny, peter@thoeny.org
and TWiki Contributors. All Rights Reserved. TWiki Contributors
are listed in the AUTHORS file in the root of this distribution.
Based on parts of Ward Cunninghams original Wiki and JosWiki.
Copyright (C) 1998 Markus Peter - SPiN GmbH (warpi@spin.de)
Some changes by Dave Harris (drh@bhresearch.co.uk) incorporated

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
