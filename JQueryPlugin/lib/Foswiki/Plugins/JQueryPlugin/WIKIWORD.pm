# See bottom of file for license and copyright information
package Foswiki::Plugins::JQueryPlugin::WIKIWORD;
use v5.14;

use Moo;
extends qw( Foswiki::Plugins::JQueryPlugin::Plugin );

=begin TML

---+ package Foswiki::Plugins::JQueryPlugin::WIKIWORD

This is the perl stub for the jquery.wikiword plugin.

=cut

=begin TML

---++ ClassMethod new( $class, ... )

Constructor

=cut

our %pluginsParams = (
    name         => 'WikiWord',
    version      => '3.20',
    author       => 'Michael Daum',
    homepage     => 'http://foswiki.org/Extensions/JQueryPlugin',
    javascript   => ['wikiword.js'],
    dependencies => [ 'JQUERYPLUGIN', 'FOSWIKI', 'livequery', 'metadata' ],
);

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2010-2016 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
