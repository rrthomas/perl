# RRT::Macro (c) 2002-2008 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# A simple macro expander.

# Macros are supplied as subroutines in the hash %Macros.
# A macro is invoked as $macro or $macro{arg1, arg2, ...}
# Commas in arguments may be escaped with a backslash.
# Unknown macros are ignored.

require 5.8.4;
package RRT::Macro;

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 0.01;
  @ISA = qw(Exporter);
  @EXPORT = qw(&expand);
}
our @EXPORT_OK;

# Macros (supplied by caller)
use vars qw(%Macros);

sub doMacro {
  my ($macro, $arg) = @_;
  my @arg = split /(?<!\\),/, ($arg || "");
  # FIXME: The next line is Smut/DarkGlass-specific
  map { s/&#(\pN+);/chr($1)/ge; $_ } @arg; # Turn entities into characters
  return $Macros{$macro}(@arg) if $Macros{$macro};
  $macro =~ s/^(.)/\u$1/; # Convert unknown $macro to $Macro
  my $ret = "\$$macro";
  $ret .= "{$arg}" if $arg;
  return $ret;
}

sub doMacros {
  my ($text) = shift;
  %Macros = %{shift()};
  1 while (($text =~ s/\$([[:lower:]]+)(?![[:lower:]{])/doMacro($1)/ge) || # macros without arguments
           ($text =~ s/\$([[:lower:]]+){(((?:(?!(?<!\\)[{}])).)*?)(?<!\\)}/doMacro($1, $2)/ge)); # macros with arguments
  return $text;
}

sub expand {
  my ($text, $macros) = @_;
  $text = doMacros($text, $macros);
  $text =~ s/(?!<\\)\$([[:upper:]])/\$\l$1/g; # Convert $Macro back to $macro
  return $text;
}



1;                              # return a true value
