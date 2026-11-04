{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - loads a ProTracker module (MOD)                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Loader.ProTracker;

interface

uses
  System.SysUtils,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Reads a MOD file with 31 samples: M.K., M!K!, 4CHN, 6CHN, 8CHN,
  ///   FLT4, FLT8, OCTA, OKTA, CD81 and the xxCH forms. The module has
  ///   64 row patterns; the samples become 16 bit
  /// </summary>
  TTrackerModLoader = class
  public
    /// <summary>
    ///   Number of channels that the signature at offset 1080 means, or zero
    ///   if it is not one of a MOD with 31 samples
    /// </summary>
    class function ChannelsOfSignature(const ASignature: string): Integer; static;

    /// <summary>True if the bytes look like a MOD with 31 samples</summary>
    class function Detect(const AData: TBytes): Boolean; static;

    /// <summary>The note that an Amiga period means (428 is C-4 of the model)</summary>
    class function NoteOfPeriod(const APeriod: Integer): Byte; static;

    /// <exception cref="ETrackerException">bad or truncated module</exception>
    class function Load(const AData: TBytes): TTrackerModule; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.ByteReader;

const
  SIGNATURE_OFFSET = 1080;
  SAMPLE_COUNT = 31;
  ROWS_PER_PATTERN = 64;
  ORDER_COUNT = 128;
  // Period of the C-2 of ProTracker, which the model puts at TRACKER_CENTER_NOTE
  CENTER_PERIOD = 428;

{ TTrackerModLoader }

class function TTrackerModLoader.ChannelsOfSignature(const ASignature: string): Integer;
begin
  Result := 0;
  if Length(ASignature) <> 4 then
    Exit;

  if (ASignature = 'M.K.') or (ASignature = 'M!K!') or (ASignature = '4CHN') or
    (ASignature = 'FLT4') then
    Exit(4);
  if ASignature = '6CHN' then
    Exit(6);
  if (ASignature = '8CHN') or (ASignature = 'FLT8') or (ASignature = 'OCTA') or
    (ASignature = 'OKTA') or (ASignature = 'CD81') then
    Exit(8);

  // 1CHN to 9CHN, and 10CH to 32CH
  if (ASignature[2] = 'C') and (ASignature[3] = 'H') and (ASignature[4] = 'N') and
    CharInSet(ASignature[1], ['1'..'9']) then
    Exit(Ord(ASignature[1]) - Ord('0'));
  if (ASignature[3] = 'C') and (ASignature[4] = 'H') and
    CharInSet(ASignature[1], ['0'..'9']) and CharInSet(ASignature[2], ['0'..'9']) then
  begin
    Result := (Ord(ASignature[1]) - Ord('0')) * 10 + (Ord(ASignature[2]) - Ord('0'));
    if (Result < 2) or (Result > TRACKER_MAX_CHANNELS) then
      Result := 0;
  end;
end;

class function TTrackerModLoader.Detect(const AData: TBytes): Boolean;
var
  LSignature: string;
  LIndex: Integer;
begin
  Result := False;
  if Length(AData) < SIGNATURE_OFFSET + 4 then
    Exit;
  LSignature := '';
  for LIndex := 0 to 3 do
    LSignature := LSignature + Char(AData[SIGNATURE_OFFSET + LIndex]);
  Result := ChannelsOfSignature(LSignature) > 0;
end;

class function TTrackerModLoader.NoteOfPeriod(const APeriod: Integer): Byte;
var
  LNote: Integer;
begin
  if APeriod <= 0 then
    Exit(TRACKER_NOTE_NONE);
  // One semitone is a factor of the twelfth root of two in the period
  LNote := TRACKER_CENTER_NOTE + Round(12 * Log2(CENTER_PERIOD / APeriod));
  if LNote < TRACKER_NOTE_FIRST then
    LNote := TRACKER_NOTE_FIRST;
  if LNote > TRACKER_NOTE_LAST then
    LNote := TRACKER_NOTE_LAST;
  Result := LNote;
end;

class function TTrackerModLoader.Load(const AData: TBytes): TTrackerModule;
var
  LReader: TTrackerByteReader;
  LSignature: string;
  LChannels, LIndex, LPatternCount, LSongLength, LRow, LChannel: Integer;
  LInstrument: TTrackerInstrument;
  LSample: TTrackerSample;
  LLengths, LLoopStarts, LLoopLengths: array[0..SAMPLE_COUNT - 1] of Integer;
  LFinetune: Integer;
  LByte0, LByte1, LByte2, LByte3: Byte;
  LPattern: TTrackerPattern;
  LCell: TTrackerCell;
  LRaw: TBytes;
begin
  if Length(AData) < SIGNATURE_OFFSET + 4 then
    raise ETrackerException.Create('The file is too short to be a MOD');

  LReader := TTrackerByteReader.Create(AData);
  Result := TTrackerModule.Create;
  try
    LReader.Seek(SIGNATURE_OFFSET);
    LSignature := LReader.ReadText(4);
    LChannels := ChannelsOfSignature(LSignature);
    if LChannels = 0 then
      raise ETrackerException.Create('Not a MOD with 31 samples (unknown signature)');
    Result.Format := tfMod;
    Result.Channels := LChannels;

    LReader.Seek(0);
    Result.Title := LReader.ReadText(20);

    // The sample headers (the data follows the patterns)
    for LIndex := 0 to SAMPLE_COUNT - 1 do
    begin
      LInstrument := TTrackerInstrument.Create;
      Result.Instruments.Add(LInstrument);
      LSample := TTrackerSample.Create;
      Result.Samples.Add(LSample);
      LInstrument.Samples.Add(LSample);

      LInstrument.Name := LReader.ReadText(22);
      LSample.Name := LInstrument.Name;
      LLengths[LIndex] := LReader.ReadWordBE * 2;
      LFinetune := LReader.ReadByte and $0F;
      if LFinetune > 7 then
        Dec(LFinetune, 16);
      LSample.Volume := Min(LReader.ReadByte, 64);
      LLoopStarts[LIndex] := LReader.ReadWordBE * 2;
      LLoopLengths[LIndex] := LReader.ReadWordBE * 2;
      // The finetune is an eighth of a semitone
      LSample.CenterFrequency := Round(TRACKER_DEFAULT_CENTER_FREQUENCY *
        Power(2, LFinetune / 96));
    end;

    LSongLength := LReader.ReadByte;
    Result.RestartPosition := LReader.ReadByte;
    SetLength(Result.Orders, ORDER_COUNT);
    LPatternCount := 0;
    for LIndex := 0 to ORDER_COUNT - 1 do
    begin
      Result.Orders[LIndex] := LReader.ReadByte;
      if Result.Orders[LIndex] >= LPatternCount then
        LPatternCount := Result.Orders[LIndex] + 1;
    end;
    if (LSongLength = 0) or (LSongLength > ORDER_COUNT) then
      LSongLength := ORDER_COUNT;
    SetLength(Result.Orders, LSongLength);
    if Result.RestartPosition >= LSongLength then
      Result.RestartPosition := 0;

    // The patterns
    LReader.Seek(SIGNATURE_OFFSET + 4);
    for LIndex := 0 to LPatternCount - 1 do
    begin
      LPattern := TTrackerPattern.Create(ROWS_PER_PATTERN, LChannels);
      Result.Patterns.Add(LPattern);
      for LRow := 0 to ROWS_PER_PATTERN - 1 do
      begin
        for LChannel := 0 to LChannels - 1 do
        begin
          LByte0 := LReader.ReadByte;
          LByte1 := LReader.ReadByte;
          LByte2 := LReader.ReadByte;
          LByte3 := LReader.ReadByte;

          LCell := LPattern.Cells[LRow, LChannel];
          LCell.Note := NoteOfPeriod(((LByte0 and $0F) shl 8) or LByte1);
          LCell.Instrument := (LByte0 and $F0) or (LByte2 shr 4);
          LCell.Effect := LByte2 and $0F;
          LCell.Param := LByte3;
          LPattern.Cells[LRow, LChannel] := LCell;
        end;
      end;
    end;

    // The sample data, 8 bit signed; a truncated file gets silence at the end
    for LIndex := 0 to SAMPLE_COUNT - 1 do
    begin
      LSample := Result.Instruments[LIndex].Samples[0];
      LRaw := LReader.ReadBytes(LLengths[LIndex], True);
      SetLength(LSample.Data, LLengths[LIndex]);
      for LRow := 0 to High(LRaw) do
        LSample.Data[LRow] := SmallInt(ShortInt(LRaw[LRow])) * 256;

      // A loop of one word or less means no loop
      if (LLoopLengths[LIndex] > 2) and (LLoopStarts[LIndex] < LLengths[LIndex]) then
      begin
        LSample.LoopType := tlForward;
        LSample.LoopStart := LLoopStarts[LIndex];
        LSample.LoopEnd := Min(LLoopStarts[LIndex] + LLoopLengths[LIndex], LLengths[LIndex]);
      end;
    end;

    // The Amiga panning: left, right, right, left
    SetLength(Result.ChannelPanning, LChannels);
    for LIndex := 0 to LChannels - 1 do
    begin
      if (LIndex mod 4) in [0, 3] then
        Result.ChannelPanning[LIndex] := 0
      else
        Result.ChannelPanning[LIndex] := 255;
    end;
  except
    LReader.Free;
    Result.Free;
    raise;
  end;
  LReader.Free;
end;

end.
