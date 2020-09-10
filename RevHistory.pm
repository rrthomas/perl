# RRT::RevHistory (c) 2003 Reuben Thomas
# Distributed under the GNU General Public License

require 5.003;
package RRT::RevHistory;

use strict;
use warnings;

our $VERSION = '1.01';


=head1 NAME

RRT::RevHistory - revision histories using VCS::Lite

=head1 SYNOPSIS

  use RRT::RevHistory;

  $hist = RRT::RevHistory->new($text);
  $hist->add($text);
  $text = $hist->get($version);
  $current = $hist->current;
  $hist->del(2);

=head1 DESCRIPTION

This module provides simple revision history objects (intended for
text files) using VCS::Lite to make the diffs and retrieve revisions.
VCS::Lite is in turn based on Algorithm::Diff.

There's nothing stopping you use it to store arbitrary text, but given
that the underlying representation is the current revision and a
series of diffs, it's pretty inefficient used for anything but texts
that only change slightly from revision to revision.

=head2 new

  my $hist = RRT::RevHistory->new($text);

Creates a new revision object given an initial text.

=head2 add

  $hist->add($text);

Adds a revision to a revision object. The given $text becomes the
current revision.

=head2 del

  $hist->del($version);

Removes all versions back to the given version. If no version is
given, it removes just the most recent version.

=head2 current

  $current = $hist->current;

Returns the current revision. Revisions are numbered sequentially from
1 upwards.

=head2 get

  $text = $hist->get($version);

Returns revision number $version.

=head1 AUTHOR

Reuben Thomas, <lt>rrt@sc3d.org<gt>

=head1 SEE ALSO

L<VCS::Lite>, L<Algorithm::Diff>.

=cut


use VCS::Lite 0.03;


# Create a new revision object with the given $text
sub new {
  my ($class, $text) = @_;
  return bless {
    TEXT => VCS::Lite->new([split /$\//, $text]),
    DIFFS => [],
  }, $class;
}

# Add a new revision $text
sub add {
  my ($self, $text) = @_;
  $text = VCS::Lite->new([split /$\//, $text]);
  unshift @{$self->{DIFFS}}, $text->diff($self->{TEXT});
  $self->{TEXT} = $text;
}

# Delete back to revision $version (default current - 1)
sub del {
  my ($self, $version) = @_;
  $version ||= 1;
  $version = $self->current - $version;
  my $text = $self->{TEXT};
  for (my $i = 0; $i < $version; $i++) {
    $text = $text->patch(shift @{$self->{DIFFS}});
  }
  $self->{TEXT} = $text;
}

# Get revision $version
sub get {
  my ($self, $version) = @_;
  $version ||= $self->current;
  $version = $self->current - $version;
  my $text = $self->{TEXT};
  for (my $i = 0; $i < $version; $i++) {
    $text = $text->patch(@{$self->{DIFFS}}[$i]);
  }
  return scalar($text->text);
}

# Return the current revision
sub current {
  my ($self) = @_;
  # versions are numbered from 1; a history with 1 revision has 0
  # diffs
  return $#{$self->{DIFFS}} + 2;
}
