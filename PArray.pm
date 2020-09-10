# PArray (c) 2003 Reuben Thomas
# Distributed under the GNU General Public License

# Persistent arrays: stores arrays as text files using Data::Dumper

require 5.003;
package RRT::PArray;

use strict;
use warnings;

use Tie::Array;
use Data::Dumper;
$Data::Dumper::Terse = 1;       # Store array as simple expression, not assignment
$Data::Dumper::Indent = 1;      # Be reasonably brief
use RRT::Misc;


sub TIEARRAY {
  my ($class, $file) = @_;
  my $val = eval(untaint(readFile($file)) || "[]");
  return bless {
    FILE => $file,
    ARRAY => $val,
  }, $class;
}

sub FETCH {
  my ($self, $index)  = @_;
  return $self->{ARRAY}->[$index];
}

sub STORE {
  my ($self, $index, $value) = @_;
  $self->{ARRAY}->[$index] = $value;
}

sub FETCHSIZE {
  my ($self) = @_;
  return scalar @{$self->{ARRAY}};
}

sub STORESIZE {
  my ($self, $count) = @_;
  $#{$self->{ARRAY}} = $count if $count < $self->FETCHSIZE();
}

sub EXISTS {
  my ($self, $index) = @_;
  return defined $self->{ARRAY}->[$index];
}

sub DELETE {
  my ($self, $index) = @_;
  $self->{ARRAY}->[$index] = undef;
}

sub DESTROY {
  my ($self) = @_;
  $self->UNTIE() if $self->{ARRAY};
}

sub UNTIE {
  my ($self) = @_;
  writeFile($self->{FILE}, Dumper($self->{ARRAY}));
  undef $self->{ARRAY};
}
