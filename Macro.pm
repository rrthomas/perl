# RRT::Macro (c) 2002-2016 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

# A simple macro expander.

# Macros are supplied as a hash of names to subroutines.
# A macro is invoked as $macro or $macro{arg1, arg2, ...}
# Commas in arguments may be escaped with a backslash.
# Unknown macros are ignored.
# Arguments are expanded before the macro is called.
# A macro returns two results: the first is its expansion. If the second
# return value is false, the result is itself expanded before being
# returned.

require 5.8.4;
package RRT::Macro;

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 2.00;
  @ISA = qw(Exporter);
  @EXPORT = qw(&expand);
}
our @EXPORT_OK;

sub doMacro {
  my ($macro, $arg, $macros) = @_;
  my @arg = split /(?<!\\),/, ($arg || "");
  for (my $i = 0; $i < $#arg; $i++) {
    $arg[$i] = expand($arg[$i]);
  }
  if (defined($macros->{$macro})) {
    my ($ret, $stop) = $macros->{$macro}(@arg);
    $ret = expand($ret, $macros) unless $stop;
    return $ret;
  }
  my $ret = "\$$macro";
  $ret .= "{$arg}" if defined($arg);
  return $ret;
}

sub expand {
  my ($text, $macros) = @_;
  $text =~ s/\$([[:lower:]]+)(?![[:lower:]{])/doMacro($1, undef, $macros)/ge; # macros without arguments
  $text =~ s/\$([[:lower:]]+){(((?:(?!(?<!\\)[{}])).)*?)(?<!\\)}/doMacro($1, $2, $macros)/ge; # macros with arguments
  return $text;
}



1;                              # return a true value
