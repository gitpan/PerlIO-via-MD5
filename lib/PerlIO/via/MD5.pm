package PerlIO::via::MD5;

# Set the version info
# Make sure we do things by the book from now on

$VERSION = '0.04';
use strict;

# Make sure the encoding/decoding stuff is available

use Digest::MD5 (); # no need to pollute this namespace

# Initialize the hash with allowable methods
# Set the default method to be used

my %allowed = (digest => 1, hexdigest => 1, b64digest => 1);
my $method = 'hexdigest';

# Satisfy -require-

1;

#-----------------------------------------------------------------------

# Methods for settings that will be used by the objects

#-----------------------------------------------------------------------

#  IN: 1 class (ignored)
#      2 new setting for method (
# OUT: 1 current setting for eol

sub method {

# Lose the class
# If we have a new value
#  Die now if invalid method name
#  Set the new value
# Return whatever we have now

    shift;
    if (@_) {
        die "Invalid digest method '$_[0]'" unless $allowed{$_[0]};
        $method = shift;
    }
    $method;
} #method

#-----------------------------------------------------------------------

# Methods for the actual layer implementation

#-----------------------------------------------------------------------
#  IN: 1 class
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

# Return now if we're not reading
# Create Digest::MD5 object and bless it as ourself

  return -1 if $_[1] ne 'r';
  bless [Digest::MD5->new,$method],$_[0];
} #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 empty string (when still busy) or the digest string (when done)

sub FILL {

# Read the line from the handle
# If there is something to be added
#  Add it
#  Indicate nothing really to be returned yet

    my $line = readline( $_[1] );
    if (defined($line)) {
        $_[0]->[0]->add( $line );
	return '';

# Elsif we still have an MD5 object (and end of data reached)
#  Obtain the MD5 object and method name
#  Remove MD5 object from PerlIO::via::MD5 object (so we'll really exit next)
#  Return the result of the digest

    } elsif ($_[0]->[0]) {
        my ($object,$method) = @{$_[0]};
        $_[0]->[0] = '';
        return $object->$method;

# Else (end of data really reached)
#  Return signalling end of data reached

    } else {
        return undef;
    }
} #FILL

__END__

=head1 NAME

PerlIO::via::MD5 - PerlIO layer for creating an MD5 digest of a file

=head1 SYNOPSIS

 use PerlIO::via::MD5;

 PerlIO::via::MD5->method( 'hexdigest' ); # default, return 32 hex digits
 PerlIO::via::MD5->method( 'digest' );    # return 16-byte binary value
 PerlIO::via::MD5->method( 'b64digest' ); # return 22-byte base64 (MIME) value

 open( my $in,'<:via(MD5)','file' )
  or die "Can't open file for digesting: $!\n";
 my $digest = <$in>;

=head1 DESCRIPTION

This module implements a PerlIO layer that can only read files and return an
MD5 digest of the contents of the file.

=head1 CLASS METHODS

There is one class method.

=head2 method

 $method = PerlIO::via::MD5->method;  # obtain current setting
 PerlIO::via::MD5->method( $method ); # set new digest method

Calling this class method with a new value will cause all subsequently opened
files to assume that new setting.  The method however is remembered within
the layer, so that it becomes part of the information that is associated with
that file.

If it were possible to pass parameters such as this to the layer while opening
the file, that would have been the approach taken.  Since that is not possible
yet, this way of doing it seems to be the next best thing.

=head1 SEE ALSO

L<PerlIO::via>, L<Digest::MD5>, L<PerlIO::via::StripHTML>,
L<PerlIO::via::QuotedPrint>, L<PerlIO::via::Base64>, L<PerlIO::via::Rotate>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
