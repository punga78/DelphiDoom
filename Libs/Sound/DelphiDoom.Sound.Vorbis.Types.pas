{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Vorbis, shared types and error codes            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libvorbis by the Xiph.Org Foundation (BSD licence)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Vorbis.Types;

interface

uses
  DelphiDoom.Ogg.Types;

const
  OV_EREAD = -128;
  OV_EFAULT = -129;
  OV_EIMPL = -130;
  OV_EINVAL = -131;
  OV_ENOTVORBIS = -132;
  OV_EBADHEADER = -133;
  OV_EVERSION = -134;
  OV_ENOTAUDIO = -135;
  OV_EBADPACKET = -136;

type
  PSingleArray = ^TSingleArray;
  TSingleArray = array[0..MaxInt div SizeOf(Single) - 1] of Single;

  /// <summary>
  ///   What a packet decodes to: the window it uses and the spectrum, turned
  ///   into samples by the mapping. The bit reader is that of the packet
  /// </summary>
  TVorbisBlock = record
    Opb: TOggPackBuffer;
    /// <summary>One vector of PcmEnd values for each channel</summary>
    Pcm: TArray<TArray<Single>>;
    PcmEnd: Integer;
    Mode: Integer;
    W: Integer;
    LW: Integer;
    NW: Integer;
    GranulePosition: Int64;
    Sequence: Int64;
    EndOfStream: Integer;
  end;

/// <summary>Number of bits of a value, the way libvorbis counts them (ov_ilog)</summary>
function OvIlog(AValue: Cardinal): Integer;

implementation

function OvIlog(AValue: Cardinal): Integer;
begin
  Result := 0;
  while AValue <> 0 do
  begin
    Inc(Result);
    AValue := AValue shr 1;
  end;
end;

end.
