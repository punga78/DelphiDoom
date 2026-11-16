{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a sound effect of the AdLib card                  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  AdLibSound and Instrument of id_sd.h                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.AdLibSound;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

const
  /// <summary>The bytes of an AdLibSound before its data: SoundCommon, the instrument and the block</summary>
  KEEN_ADLIB_HEADER_BYTES = 23;

type
  /// <summary>Instrument of id_sd.h: the registers of the modulator and of the carrier of a channel</summary>
  TKeenAdLibInstrument = packed record
    ModulatorChar: Byte;
    CarrierChar: Byte;
    ModulatorScale: Byte;
    CarrierScale: Byte;
    ModulatorAttack: Byte;
    CarrierAttack: Byte;
    ModulatorSustain: Byte;
    CarrierSustain: Byte;
    ModulatorWave: Byte;
    CarrierWave: Byte;
    Connection: Byte;
    Unused: array[0..4] of Byte;
  end;

  /// <summary>
  ///   AdLibSound: the length in service ticks, the priority, the instrument of the channel 0, the octave (block)
  ///   and a byte for each tick: 0 turns the note off, another number is the low byte of the frequency
  /// </summary>
  TKeenAdLibSound = record
    Length: Cardinal;
    Priority: Word;
    Instrument: TKeenAdLibInstrument;
    Block: Byte;
    Data: TBytes;
  end;

  /// <summary>Reads the chunk of an AdLib sound of the audio file</summary>
  TKeenAdLibSoundReader = class
  public
    /// <summary>
    ///   The sound of a chunk. A chunk that ends inside the instrument or before the block has zeros for what is
    ///   missing (the C reads what is after the chunk); less than the 6 bytes of SoundCommon is an error
    /// </summary>
    class function Parse(const AChunk: TBytes): TKeenAdLibSound; static;
  end;

implementation

{ TKeenAdLibSoundReader }

class function TKeenAdLibSoundReader.Parse(const AChunk: TBytes): TKeenAdLibSound;
var
  LHeader: array[0..KEEN_ADLIB_HEADER_BYTES - 1] of Byte;
  LAvailable: Integer;
begin
  if System.Length(AChunk) < SizeOf(TKeenSoundCommon) then
    raise EKeenDataException.CreateFmt(SKeenSoundChunkShort, [System.Length(AChunk)]);
  FillChar(LHeader, SizeOf(LHeader), 0);
  LAvailable := System.Length(AChunk);
  if LAvailable > KEEN_ADLIB_HEADER_BYTES then
    LAvailable := KEEN_ADLIB_HEADER_BYTES;
  Move(AChunk[0], LHeader[0], LAvailable);
  Result.Length := Cardinal(LHeader[0]) or (Cardinal(LHeader[1]) shl 8) or (Cardinal(LHeader[2]) shl 16) or
    (Cardinal(LHeader[3]) shl 24);
  Result.Priority := Word(LHeader[4]) or (Word(LHeader[5]) shl 8);
  Move(LHeader[6], Result.Instrument, SizeOf(TKeenAdLibInstrument));
  Result.Block := LHeader[22];
  LAvailable := System.Length(AChunk) - KEEN_ADLIB_HEADER_BYTES;
  if LAvailable < 0 then
    LAvailable := 0;
  SetLength(Result.Data, LAvailable);
  if LAvailable > 0 then
    Move(AChunk[KEEN_ADLIB_HEADER_BYTES], Result.Data[0], LAvailable);
end;

end.
