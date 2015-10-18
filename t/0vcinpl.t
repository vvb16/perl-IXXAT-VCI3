# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl IXXAT-VCI3.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN
{
  use_ok('Win32::API');
}

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok(Win32::API->Import("vcinpl", "long vciInitialize()"), "Import vciInitialize") || diag "Error: " . $^E;
ok(vciInitialize() == 0, "Call vciInitialize()");
ok(Win32::API->Import("vcinpl", "void vciFormatError(long hrError, PCHAR pszText)"), "Import vciFormatError") || diag "Error: " . $^E;
my $error_text = " " x 256;
vciFormatError(0, $error_text);
ok(Win32::API->Import("vcinpl", "long vciEnumDeviceOpen(PHANDLE phEnum)"), "Import vciEnumDeviceOpen") || diag "Error: " . $^E;
