package IXXAT::VCI3;

use 5.016000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use IXXAT::VCI3 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
pvciInitialize pvciFormatError openChannel closeChannel channelActivate readMessage sendMessage	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.08';


# Preloaded methods go here.

use Inline (C => Config =>
                libs => '-L../../../../IXXAT-SDK/lib/' . lc($ENV{PROCESSOR_ARCHITECTURE}) . ' -lvcinpl',
                inc => '-I../../../../IXXAT-SDK/inc',
                ccflagsex => '-std=c99',
               );

use Inline C => 'DATA',
           VERSION => '0.08',
           NAME => 'IXXAT::VCI3';

Inline->init();

1;

__DATA__

=pod

=head1 NAME

IXXAT::VCI3 - Use IXXAT VCI3 library functions in perl.

=cut

__C__
#include "vcinpl.h"

unsigned long pvciInitialize()
{
  return vciInitialize();
}

SV* pvciFormatError(unsigned long hrError)
{
  char errText[VCI_MAX_ERRSTRLEN];
  vciFormatError(hrError, &errText[0], VCI_MAX_ERRSTRLEN);
  return newSVpv(&errText[0], 0);
}

unsigned long openChannel(SV* channel)
{
  HANDLE hEnum = 0;
  HRESULT result = vciEnumDeviceOpen(&hEnum);
  if ( result != VCI_OK )
    return result;

  VCIDEVICEINFO deviceInfo;
  result = vciEnumDeviceNext(hEnum, &deviceInfo);
  if ( result != VCI_OK )
  {
    vciEnumDeviceClose(hEnum);
    return result;
  }

  result = vciEnumDeviceClose(hEnum);
  if ( result != VCI_OK )
    return result;

  HANDLE hDevice = 0;
  result = vciDeviceOpen(&deviceInfo.VciObjectId, &hDevice);
  if ( result != VCI_OK )
    return result;

  HANDLE hControl = 0;
  result = canControlOpen(hDevice, 0, &hControl);
  if ( result != VCI_OK )
  {
    vciDeviceClose(hDevice);
    return result;
  }

  HANDLE hChannel = 0;
  result = canChannelOpen(hDevice, 0, FALSE, &hChannel);
  if ( result != VCI_OK )
  {
    canControlClose(hControl);
    vciDeviceClose(hDevice);
    return result;
  }

  result = vciDeviceClose(hDevice);
  if ( result != VCI_OK )
  {
    canControlClose(hControl);
    canChannelClose(hChannel);
    return result;
  }

  result = canControlInitialize(hControl,
    CAN_OPMODE_STANDARD,
    CAN_BT0_125KB, CAN_BT1_125KB);
  if ( result != VCI_OK )
  {
    canChannelClose(hChannel);
    canControlClose(hControl);
    return result;
  }

  result = canControlStart(hControl, TRUE);
  if ( result != VCI_OK )
  {
    canChannelClose(hChannel);
    canControlClose(hControl);
    return result;
  }

  result = canControlClose(hControl);
  if ( result != VCI_OK )
  {
    canChannelClose(hChannel);
    return result;
  }

  result = canChannelInitialize(hChannel, 2000, 1, 2000, 2000-1);
  if ( result != VCI_OK )
  {
    canChannelClose(hChannel);
    return result;
  }

  sv_setuv(channel, (UV)hChannel);
  return 0;
}

unsigned long closeChannel(UV channel)
{
  return canChannelClose((HANDLE)channel);
}

unsigned long channelActivate(UV channel)
{
  return canChannelActivate((HANDLE)channel, TRUE);
}

static char type_Id[] = "type";
static char key_Id[] = "Id";
static char key_data[] = "data";

unsigned long readMessages(UV channel, unsigned int msTimeout, unsigned int maxMessages, SV* messages)
{
  CANMSG msg;
  HRESULT result;
  AV* recieved = newAV();
  while ( maxMessages > 0 && (result = canChannelReadMessage((HANDLE)channel, msTimeout, &msg)) == VCI_OK )
  {
    if ( msg.uMsgInfo.Bits.type != CAN_MSGTYPE_DATA )
      continue;
    --maxMessages;
    AV* data = newAV();
    for ( int len = msg.uMsgInfo.Bits.dlc, cnt = 0; cnt < len; ++cnt )
    {
      av_push(data, newSVuv(msg.abData[cnt]));
    }
    HV* hv = newHV();
    hv_store(hv, key_Id, sizeof(key_Id) - 1, newSVuv(msg.dwMsgId), 0);
    hv_store(hv, key_data, sizeof(key_data) - 1, newRV_noinc((SV*)data), 0);

    av_push(recieved, newRV_noinc((SV*)hv));
  }
  sv_setsv(messages, newRV_noinc((SV*)recieved));

  return result;
}

unsigned long readMessage(UV channel, unsigned int msTimeout, HV* message)
{
  CANMSG msg;
  HRESULT result;
  for ( ; ; )
  {
  if ( (result = canChannelReadMessage((HANDLE)channel, msTimeout, &msg)) == VCI_OK )
  {
    SV* data = newSVpvn(&msg.abData[0], msg.uMsgInfo.Bits.dlc);
    hv_store(message, type_Id, sizeof(type_Id) - 1, newSVuv(msg.uMsgInfo.Bits.type), 0);
    hv_store(message, key_Id, sizeof(key_Id) - 1, newSVuv(msg.dwMsgId), 0);
    hv_store(message, key_data, sizeof(key_data) - 1, data, 0);
  }
  return result;
  }
}

unsigned long sendMessage(UV channel, unsigned int msTimeout, unsigned int id, unsigned char len, unsigned char *bytes)
{
  CANMSG msg = {0};

  msg.dwMsgId = id;
  msg.uMsgInfo.Bits.type = CAN_MSGTYPE_DATA;
  msg.uMsgInfo.Bits.dlc = len;
  memcpy(&msg.abData[0], bytes, len);

  return canChannelSendMessage((HANDLE)channel, msTimeout, &msg);
}

__END__
