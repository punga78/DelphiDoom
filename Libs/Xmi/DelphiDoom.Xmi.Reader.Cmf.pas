{******************************************************************************}
{                                                                              }
{  DelphiDoom: CMF - reads a Creative Music File                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Reader.Cmf;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Song;

type
  /// <summary>
  ///   Reads a CMF file: a header with the offsets of the title and of the
  ///   music, then the music as the events of a standard MIDI track
  /// </summary>
  /// <remarks>
  ///   The song has one track, the division is the number of ticks per second
  ///   the file declares and the tempo one second per quarter note. The
  ///   instruments (FM patches) are of no use to a MIDI file and are not read
  /// </remarks>
  TXmiCmfReader = class
  public
    /// <summary>
    ///   Raises EXmiDataException if the data is not a CMF file of version 1.0
    ///   or 1.1
    /// </summary>
    class function Read(const AData: TBytes): TXmiSong; static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Midi.ByteReader,
  DelphiDoom.Xmi.Midi.Track, DelphiDoom.Xmi.Reader.MidiTrack;

const
  HEADER_SIZE = 36;
  CMF_TAG = 'CTMF';
  VERSION_1_0 = $0100;
  VERSION_1_1 = $0101;
  // One second per quarter note
  CMF_TEMPO = 1000000;
  // Offsets of the fields of the header
  OFFSET_VERSION = 4;
  OFFSET_MUSIC = 8;
  OFFSET_TICKS_PER_SECOND = 12;
  OFFSET_TITLE = 14;
  OFFSET_COMPOSER = 16;
  OFFSET_REMARKS = 18;
  OFFSET_INSTRUMENTS = 6;

function ReadWord(const AData: TBytes; AOffset: Integer): Word;
begin
  Result := Word(AData[AOffset] or (AData[AOffset + 1] shl 8));
end;

// The zero terminated text that starts at AOffset, if it is inside the data
function ReadText(const AData: TBytes; AOffset: Integer): AnsiString;
var
  LEnd: Integer;
begin
  Result := '';
  if (AOffset <= 0) or (AOffset >= Length(AData)) then
    Exit;

  LEnd := AOffset;
  while (LEnd < Length(AData)) and (AData[LEnd] <> 0) do
    Inc(LEnd);
  SetString(Result, PAnsiChar(@AData[AOffset]), LEnd - AOffset);
end;

{ TXmiCmfReader }

class function TXmiCmfReader.Read(const AData: TBytes): TXmiSong;
var
  LVersion: Word;
  LOffsetInstruments: Integer;
  LOffsetMusic: Integer;
  LOffsetTitle: Integer;
  LOffsetComposer: Integer;
  LOffsetRemarks: Integer;
  LDataSize: Integer;
  LTrack: TXmiTrack;
  LReader: TXmiByteReader;
begin
  if Length(AData) < HEADER_SIZE then
    raise EXmiDataException.Create('Not a CMF file');
  if (AData[0] <> Ord(CMF_TAG[1])) or (AData[1] <> Ord(CMF_TAG[2])) or
     (AData[2] <> Ord(CMF_TAG[3])) or (AData[3] <> Ord(CMF_TAG[4])) then
    raise EXmiDataException.Create('Not a CMF file');

  LVersion := ReadWord(AData, OFFSET_VERSION);
  if (LVersion <> VERSION_1_0) and (LVersion <> VERSION_1_1) then
    raise EXmiDataException.Create('Unsupported version of CMF');

  LOffsetInstruments := ReadWord(AData, OFFSET_INSTRUMENTS);
  LOffsetMusic := ReadWord(AData, OFFSET_MUSIC);
  LOffsetTitle := ReadWord(AData, OFFSET_TITLE);
  LOffsetComposer := ReadWord(AData, OFFSET_COMPOSER);
  LOffsetRemarks := ReadWord(AData, OFFSET_REMARKS);

  Result := TXmiSong.Create;
  try
    Result.InitialTempo := CMF_TEMPO;
    Result.Smpte := 0;
    Result.Division := ReadWord(AData, OFFSET_TICKS_PER_SECOND);
    Result.MidiType := XMI_MIDI_TYPE_SINGLE_TRACK;

    // An offset beyond the file is no offset
    if LOffsetTitle >= Length(AData) then
      LOffsetTitle := 0;
    if LOffsetComposer >= Length(AData) then
      LOffsetComposer := 0;
    if LOffsetRemarks >= Length(AData) then
      LOffsetRemarks := 0;
    if LOffsetMusic >= Length(AData) then
      LOffsetMusic := 0;
    if LOffsetMusic = 0 then
      Exit;

    // The music lasts until the next block of the file, if one follows
    LDataSize := Length(AData) - LOffsetMusic;
    if LOffsetTitle >= LOffsetMusic then
      LDataSize := LOffsetTitle - LOffsetMusic
    else if LOffsetComposer >= LOffsetMusic then
      LDataSize := LOffsetComposer - LOffsetMusic
    else if LOffsetRemarks >= LOffsetMusic then
      LDataSize := LOffsetRemarks - LOffsetMusic
    else if LOffsetInstruments >= LOffsetMusic then
      LDataSize := LOffsetInstruments - LOffsetMusic;

    LTrack := Result.AddTrack;
    LTrack.Title := ReadText(AData, LOffsetTitle);
    LReader := TXmiByteReader.Create(AData, LOffsetMusic, LDataSize);
    try
      TXmiMidiTrackReader.Read(LReader, LTrack);
    finally
      LReader.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
