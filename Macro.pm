# RRT::Macro (c) 2002-2016 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# A simple macro expander.

# Macros are supplied as a hash of names to subroutines.
# A macro is invoked as $macro or $macro{arg1, arg2, ...}
# Commas in arguments may be escaped with a backslash.
# Unknown macros are ignored.
# Arguments are expanded before the macro is called.
# A macro returns its expansion.

require 5.8.4;
package RRT::Macro;

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 3.11;
  @ISA = qw(Exporter);
  @EXPORT = qw(&expand);
}
our @EXPORT_OK;

sub doMacro {
  my ($macro, $arg, $macros) = @_;
  my @arg = split /(?<!\\),/, ($arg || "");
  for (my $i = 0; $i < $#arg; $i++) {
    $arg[$i] =~ s/\\,/,/; # Remove escaping backslashes
    $arg[$i] = expand($arg[$i]);
  }
  return $macros->{$macro}(@arg) if defined($macros->{$macro});
  my $ret = "\$$macro";
  $ret .= "{$arg}" if defined($arg);
  return $ret;
}

sub expand {
  my ($text, $macros) = @_;
  # FIXME: Allow other (all printable non-{?) characters in macro names
  $text =~ s/\$([[:lower:]]+)(?![[:lower:]{])/doMacro($1, undef, $macros)/ge; # macros without arguments
  $text =~ s/\$([[:lower:]]+){(((?:(?!(?<!\\)[{}])).)*?)(?<!\\)}/doMacro($1, $2, $macros)/ge; # macros with arguments
  return $text;
}



1;                              # return a true value
