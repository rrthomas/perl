# RRT::Macro (c) 2002-2016 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# A simple macro expander.

# Macros are supplied as a hash of names to subroutines.
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

sub doMacro {
  my ($macro, $arg, $Macros) = @_;
  my @arg = split /(?<!\\),/, ($arg || "");
  return $Macros->{$macro}(@arg) if defined($Macros->{$macro});
  $macro =~ s/^(.)/\u$1/; # Convert unknown $macro to $Macro
  my $ret = "\$$macro";
  $ret .= "{$arg}" if $arg;
  return $ret;
}

sub doMacros {
  my ($text, $macros) = @_;
  1 while (($text =~ s/\$([[:lower:]]+)(?![[:lower:]{])/doMacro($1, "", $macros)/ge) || # macros without arguments
           ($text =~ s/\$([[:lower:]]+){(((?:(?!(?<!\\)[{}])).)*?)(?<!\\)}/doMacro($1, $2, $macros)/ge)); # macros with arguments
  return $text;
}

sub expand {
  my ($text, $macros) = @_;
  $text = doMacros($text, $macros);
  # Convert `$Macro' back to `$macro'
  $text =~ s/(?!<\\)(?<=\$)([[:upper:]])(?=[[:lower:]]*)/lc($1)/ge;
  return $text;
}



1;                              # return a true value
