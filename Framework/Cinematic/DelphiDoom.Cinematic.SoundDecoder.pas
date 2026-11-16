{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the DPCM audio of RoQ                       }
{                                                                              }
{  Port of RllSetupTable and RllDecodeMonoToMono, RllDecodeMonoToStereo,       }
{  RllDecodeStereoToStereo and RllDecodeStereoToMono of the RoQ decoder of     }
{  Quake III Arena (cl_cin.c, GPL v2 or later, Copyright (C) 1999-2005 Id      }
{  Software, Inc.).                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.SoundDecoder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Decodes the audio chunks of RoQ: every byte is the index of a signed square that is
  ///   added to the previous sample (a delta coding). The sums wrap at 16 bits, as the
  ///   short of the original does
  /// </summary>
  TRoqSoundDecoder = class
  strict private
    FSquares: array[0..255] of SmallInt;
  public
    constructor Create;
    /// <summary>RllDecodeMonoToMono: one sample per byte; the flags are the first sample</summary>
    function DecodeMonoToMono(const AData: TBytes; ASize: Integer; AFlags: Word): TArray<SmallInt>;
    /// <summary>RllDecodeMonoToStereo: every sample twice (left, right)</summary>
    function DecodeMonoToStereo(const AData: TBytes; ASize: Integer; AFlags: Word): TArray<SmallInt>;
    /// <summary>
    ///   RllDecodeStereoToStereo: the bytes alternate left and right; the high byte of the
    ///   flags starts the left channel and the low one the right channel, both shifted by 8
    /// </summary>
    function DecodeStereoToStereo(const AData: TBytes; ASize: Integer; AFlags: Word): TArray<SmallInt>;
    /// <summary>RllDecodeStereoToMono: the average of the two channels; it reads 2 * ASize bytes and gives ASize samples</summary>
    function DecodeStereoToMono(const AData: TBytes; ASize: Integer; AFlags: Word): TArray<SmallInt>;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types;

resourcestring
  SSoundTooShort = 'The audio chunk has %d bytes but %d are needed';

procedure RequireBytes(const AData: TBytes; ANeeded: Integer);
begin
  if Length(AData) < ANeeded then
    raise ERoqTruncatedException.CreateFmt(SSoundTooShort, [Length(AData), ANeeded]);
end;

{ TRoqSoundDecoder }

constructor TRoqSoundDecoder.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to 127 do
  begin
    FSquares[LIndex] := SmallInt(LIndex * LIndex);
    FSquares[LIndex + 128] := SmallInt(-FSquares[LIndex]);
  end;
end;

function TRoqSoundDecoder.DecodeMonoToMono(const AData: TBytes; ASize: Integer;
  AFlags: Word): TArray<SmallInt>;
var
  LIndex, LPrevious: Integer;
begin
  RequireBytes(AData, ASize);
  SetLength(Result, ASize);
  LPrevious := AFlags;
  for LIndex := 0 to ASize - 1 do
  begin
    LPrevious := SmallInt(LPrevious + FSquares[AData[LIndex]]);
    Result[LIndex] := SmallInt(LPrevious);
  end;
end;

function TRoqSoundDecoder.DecodeMonoToStereo(const AData: TBytes; ASize: Integer;
  AFlags: Word): TArray<SmallInt>;
var
  LIndex, LPrevious: Integer;
begin
  RequireBytes(AData, ASize);
  SetLength(Result, ASize * 2);
  LPrevious := AFlags;
  for LIndex := 0 to ASize - 1 do
  begin
    LPrevious := SmallInt(LPrevious + FSquares[AData[LIndex]]);
    Result[LIndex * 2] := SmallInt(LPrevious);
    Result[LIndex * 2 + 1] := SmallInt(LPrevious);
  end;
end;

function TRoqSoundDecoder.DecodeStereoToStereo(const AData: TBytes; ASize: Integer;
  AFlags: Word): TArray<SmallInt>;
var
  LIndex, LPreviousLeft, LPreviousRight: Integer;
begin
  RequireBytes(AData, ASize);
  // the original writes ASize shorts and reads 2 bytes for every 2 shorts; an odd size
  // would read one byte more than there is, so the pair is dropped
  SetLength(Result, ASize);
  LPreviousLeft := AFlags and $FF00;
  LPreviousRight := (AFlags and $00FF) shl 8;
  LIndex := 0;
  while LIndex + 1 < ASize do
  begin
    LPreviousLeft := SmallInt(LPreviousLeft + FSquares[AData[LIndex]]);
    LPreviousRight := SmallInt(LPreviousRight + FSquares[AData[LIndex + 1]]);
    Result[LIndex] := SmallInt(LPreviousLeft);
    Result[LIndex + 1] := SmallInt(LPreviousRight);
    Inc(LIndex, 2);
  end;
end;

function TRoqSoundDecoder.DecodeStereoToMono(const AData: TBytes; ASize: Integer;
  AFlags: Word): TArray<SmallInt>;
var
  LIndex, LPreviousLeft, LPreviousRight: Integer;
begin
  RequireBytes(AData, ASize * 2);
  SetLength(Result, ASize);
  LPreviousLeft := AFlags and $FF00;
  LPreviousRight := (AFlags and $00FF) shl 8;
  for LIndex := 0 to ASize - 1 do
  begin
    // no 16 bit wrap on the sums here: it is the original that does not
    LPreviousLeft := LPreviousLeft + FSquares[AData[LIndex * 2]];
    LPreviousRight := LPreviousRight + FSquares[AData[LIndex * 2 + 1]];
    Result[LIndex] := SmallInt((LPreviousLeft + LPreviousRight) div 2);
  end;
end;

end.
