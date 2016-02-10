# See bottom of file for license and copyright information
package Foswiki::Search::Parser;
use v5.14;

=begin TML

---+ package Foswiki::Search::Parser

Parse SEARCH token strings into Foswiki::Search::Node objects.

=cut

use Try::Tiny;

use Foswiki::Search::Node ();

use Moo;
use namespace::clean;
extends qw(Foswiki::Object);

use Assert;

BEGIN {
    if ( $Foswiki::cfg{UseLocale} ) {
        require locale;
        import locale();
    }
}

our $MARKER = "\0";

=begin TML

---++ ClassMethod new($session)

=cut

has session => (
    is       => 'rw',
    weak_ref => 1,
);
has initialised => (
    is      => 'rw',
    default => 0,
);
has stopwords => ( is => 'rw', );

# Initialise on demand before a first parse
sub _initialise {
    my $this = shift;

    return if ( $this->initialised );

    # Build pattern of stop words
    my $WMARK = chr(0);                  # Set a word marker
    my $prefs = $this->session->prefs;
    ASSERT($prefs) if DEBUG;
    my $stopwords = $prefs->getPreference('SEARCHSTOPWORDS') || '';
    $stopwords =~ s/[\s\,]+/$WMARK/g;
    $stopwords = quotemeta $stopwords;
    $stopwords =~ s/\\$WMARK/|/g;
    $this->stopwords($stopwords);

    $this->initialised(1);
}

=begin TML

---++ ObjectMethod finish()
Break circular references.

=cut

#sub finish {
#    my $self = shift;
#
#    undef $self->{session};
#    undef $self->{stopwords};
#    undef $self->{initialised};
#}

=begin TML

---++ ObjectMethod parse($string, $options) -> Foswiki::Search::Node.

Parses a SEARCH string and makes a token container to pass to the search
algorithm (see Foswiki::Store::SearchAlgorithm)

=cut

# Split the search string into tokens depending on type of search.
# Search is an 'AND' of all tokens - various syntaxes implemented
# by this routine.
sub parse {
    my ( $this, $searchString, $options ) = @_;

    $this->_initialise();

    my @tokens = ();
    if ( $options->{type} eq 'regex' ) {

        # Regular expression search Example: soap;wsdl;web service;!shampoo
        @tokens = split( /;/, $searchString );

    }
    elsif ( $options->{type} eq 'literal' || $options->{type} eq 'query' ) {

        if ( $searchString eq '' ) {

            # Legacy: empty search returns nothing
        }
        else {

            # Literal search (old style) or query
            $tokens[0] = $searchString;
        }

    }
    else {

        # Keyword search (Google-style) - implemented by converting
        # to regex format. Example: soap +wsdl +"web service" -shampoo

        # Prevent tokenizing on spaces in "literal string"
        $searchString =~ s/(\".*?)\"/_protectLiteral($1)/ge;
        $searchString =~ s/[\+\-]\s+//g;

        # Tokenize string taking account of literal strings, then remove
        # stop words and convert '+' and '-' syntax.
        my $stopwords = $this->stopwords;
        @tokens =
          grep { !/^($stopwords)$/i }    # remove stopwords
          map {
            s/^\+//;
            s/^\-/\!/;
            s/^"//;
            $_
          }                              # remove +, change - to !, remove "
          map { s/$MARKER/ /go; $_ }     # restore space
          split( /\s+/, $searchString ); # split on spaces
    }

    my $result = Foswiki::Search::Node->new(
        search  => $searchString,
        tokens  => \@tokens,
        options => $options
    );
    return $result;
}

# Convert spaces into NULs to protect literal strings
sub _protectLiteral {
    my $text = shift;
    $text =~ s/\s+/$MARKER/g;
    return $text;
}

1;
__END__
Author: Sven Dowideit - http://fosiki.com

Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

Additional copyrights apply to some or all of the code in this
file as follows:

Copyright (C) 2005-2007 TWiki Contributors. All Rights Reserved.
TWiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
