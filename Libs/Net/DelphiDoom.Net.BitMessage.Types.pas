{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - types of the bit messages (idBitMsg)              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\BitMsg.h,          }
{  BitMsg.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.BitMessage.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_STRING_CHARS: the buffer size that the original gives to the strings it reads</summary>
  BITMSG_MAX_STRING_CHARS = 1024;
  /// <summary>MAX_DATA_BUFFER of idBitMsgDelta: the largest string or data block it compares to the base</summary>
  BITMSG_MAX_DATA_BUFFER = 1024;

  SBitMessageCannotWrite = 'idBitMsg: cannot write to message';
  SBitMessageCannotRead = 'idBitMsg: cannot read from message';
  SBitMessageBadNumBits = 'idBitMsg: bad numBits %d';
  SBitMessageOverflowNotAllowed = 'idBitMsg: overflow without allowOverflow set';
  SBitMessageBitsLargerThanMessage = 'idBitMsg: %d bits is > full message size';
  SBitMessageBufferTooSmall = 'idBitMsg: the length %d is larger than the buffer (%d bytes)';
  SBitMessageBadMaxLength = 'idBitMsg: WriteString with maxLength 0 (the original writes outside the message)';

type
  /// <summary>
  ///   The error of the bit messages: <c>common->Error</c> and <c>common->FatalError</c> of the original
  ///   (a bad number of bits, a write to a read only message, an overflow that is not allowed)
  /// </summary>
  EBitMessageException = class(Exception);

  /// <summary>
  ///   netadr_t as idBitMsg writes it: four bytes of the IPv4 address and the port. 6 bytes, no padding,
  ///   the same at 32 and at 64 bit (the type of the address, NA_IP, is implicit)
  /// </summary>
  TBitMessageNetAddress = packed record
    Ip: array[0..3] of Byte;
    Port: Word;
  end;

implementation

end.
