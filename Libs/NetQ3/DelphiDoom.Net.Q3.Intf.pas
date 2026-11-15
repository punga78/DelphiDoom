{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the contracts of the network of Quake III         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): qcommon.h.      }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types;

type
  /// <summary>
  ///   The bits of a bit stream message: raw bits and the Huffman codes of the bytes (msgHuff of msg.c).
  ///   The messages ask for the coder instead of owning a global one
  /// </summary>
  IQ3HuffmanCoder = interface
    ['{2F6C1E84-93A7-4D50-8B1A-6E5D0C7B3A41}']
    /// <summary>Huff_putBit: one bit at the bit offset; a new byte is cleared first</summary>
    procedure PutBit(ABit: Integer; var AData: TBytes; var AOffset: Integer);
    /// <summary>Huff_getBit</summary>
    function GetBit(const AData: TBytes; var AOffset: Integer): Integer;
    /// <summary>Huff_offsetTransmit with the compressor tree of the messages: the code of a byte</summary>
    procedure Transmit(AValue: Integer; var AData: TBytes; var AOffset: Integer);
    /// <summary>Huff_offsetReceive with the decompressor tree: a symbol (256, the NYT leaf, is possible in a corrupt stream)</summary>
    function Receive(const AData: TBytes; var AOffset: Integer): Integer;
  end;

  /// <summary>
  ///   Where the datagrams of a network channel go (<c>NET_SendPacket</c>). The receiving side is the
  ///   caller: it hands a received datagram to <c>TQ3Netchan.Process</c>
  /// </summary>
  IQ3NetTransport = interface
    ['{7B0D5A39-1C6E-4F82-A9D4-3E8F2B61C705}']
    procedure SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
  end;

  /// <summary>The table of the fields that a state sends (entityStateFields, playerStateFields)</summary>
  IQ3NetFieldTable = interface
    ['{C41A8E27-5D93-4B06-87F2-0A6E9D31B5C8}']
    function Count: Integer;
    function GetField(AIndex: Integer): TQ3NetField;
    property Fields[AIndex: Integer]: TQ3NetField read GetField; default;
  end;

implementation

end.
