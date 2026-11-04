{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - loads a Scream Tracker 3 module (S3M)                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Loader.S3m;

interface

uses
  System.SysUtils,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Reads an S3M file: the PCM samples (the adlib instruments are kept as
  ///   empty samples), the patterns and the channel settings
  /// </summary>
  TTrackerS3mLoader = class
  public
    /// <summary>True if the bytes have the "SCRM" signature of an S3M</summary>
    class function Detect(const AData: TBytes): Boolean; static;

    /// <exception cref="ETrackerException">bad or truncated module</exception>
    class function Load(const AData: TBytes): TTrackerModule; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.ByteReader;

const
  SIGNATURE_OFFSET = $2C;
  ROWS_PER_PATTERN = 64;
  CHANNEL_SETTINGS = 32;
  // S3M numbers its notes from C-0 with C-5 at the C5 speed of the sample:
  // the model puts the center frequency at C-4, an octave lower
  S3M_C5_NOTE = 61;
  FLAG_LOOP = 1;
  FLAG_16BIT = 4;
  FLAG_STEREO = 2;
  DEFAULT_PANNING_PRESENT = 252;

{ TTrackerS3mLoader }

class function TTrackerS3mLoader.Detect(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= SIGNATURE_OFFSET + 4) and (AData[SIGNATURE_OFFSET] = Ord('S')) and
    (AData[SIGNATURE_OFFSET + 1] = Ord('C')) and (AData[SIGNATURE_OFFSET + 2] = Ord('R')) and
    (AData[SIGNATURE_OFFSET + 3] = Ord('M'));
end;

class function TTrackerS3mLoader.Load(const AData: TBytes): TTrackerModule;
var
  LReader: TTrackerByteReader;
  LOrderCount, LInstrumentCount, LPatternCount, LIndex, LChannel: Integer;
  LInitialSpeed, LInitialTempo, LMasterVolume, LDefaultPanning, LRow: Integer;
  LInstrumentPointers, LPatternPointers: TArray<Integer>;
  LChannelSettings: array[0..CHANNEL_SETTINGS - 1] of Byte;
  LChannelMap: array[0..CHANNEL_SETTINGS - 1] of Boolean;
  LUsedChannels: Integer;
  LInstrument: TTrackerInstrument;
  LSample: TTrackerSample;
  LPattern: TTrackerPattern;
  LCell: TTrackerCell;
  LSampleFormat: Integer;

  procedure LoadInstrument(const AParagraph: Integer);
  var
    LType, LSampleFlags, LVolume: Integer;
    LLength, LLoopStart, LLoopEnd, LC5Speed: Cardinal;
    LDataOffset: Integer;
    LRaw: TBytes;
    LWord: Integer;
    LSampleIndex: Integer;
  begin
    LInstrument := TTrackerInstrument.Create;
    Result.Instruments.Add(LInstrument);
    LSample := TTrackerSample.Create;
    Result.Samples.Add(LSample);
    LInstrument.Samples.Add(LSample);
    if AParagraph = 0 then
      Exit;

    LReader.Seek(AParagraph * 16);
    LType := LReader.ReadByte;
    LReader.Skip(12);
    LDataOffset := LReader.ReadByte shl 16;
    Inc(LDataOffset, LReader.ReadWord);
    LLength := LReader.ReadCardinal;
    LLoopStart := LReader.ReadCardinal;
    LLoopEnd := LReader.ReadCardinal;
    LVolume := LReader.ReadByte;
    LReader.Skip(2);
    LSampleFlags := LReader.ReadByte;
    LC5Speed := LReader.ReadCardinal;
    LReader.Skip(12);
    LInstrument.Name := LReader.ReadText(28);
    LSample.Name := LInstrument.Name;
    LSample.Volume := Min(LVolume, 64);
    // The C5 speed is for C-5; the model has the center frequency at C-4
    if LC5Speed = 0 then
      LC5Speed := TRACKER_DEFAULT_CENTER_FREQUENCY * 2;
    LSample.CenterFrequency := Max(1, Integer(LC5Speed div 2));

    // Only the sample type 1 (PCM) has data
    if (LType <> 1) or (LLength = 0) then
      Exit;
    if (LSampleFlags and FLAG_16BIT) <> 0 then
      LLength := LLength * 2;
    if (LSampleFlags and FLAG_STEREO) <> 0 then
      LLength := LLength * 2;
    LReader.Seek(Min(LDataOffset * 16, LReader.Size));
    LRaw := LReader.ReadBytes(Integer(LLength), True);

    if (LSampleFlags and FLAG_16BIT) <> 0 then
    begin
      SetLength(LSample.Data, Length(LRaw) div 2);
      for LSampleIndex := 0 to High(LSample.Data) do
      begin
        LWord := LRaw[2 * LSampleIndex] or (LRaw[2 * LSampleIndex + 1] shl 8);
        if LSampleFormat = 2 then
          LWord := LWord - 32768
        else if LWord >= 32768 then
          LWord := LWord - 65536;
        LSample.Data[LSampleIndex] := LWord;
      end;
    end
    else
    begin
      SetLength(LSample.Data, Length(LRaw));
      for LSampleIndex := 0 to High(LRaw) do
      begin
        if LSampleFormat = 2 then
          LSample.Data[LSampleIndex] := (Integer(LRaw[LSampleIndex]) - 128) * 256
        else
          LSample.Data[LSampleIndex] := ShortInt(LRaw[LSampleIndex]) * 256;
      end;
    end;

    if (LSampleFlags and FLAG_LOOP) <> 0 then
    begin
      if LLoopEnd > Cardinal(Length(LSample.Data)) then
        LLoopEnd := Length(LSample.Data);
      if LLoopStart < LLoopEnd then
      begin
        LSample.LoopType := tlForward;
        LSample.LoopStart := LLoopStart;
        LSample.LoopEnd := LLoopEnd;
      end;
    end;
  end;

  procedure LoadPattern(const AParagraph: Integer);
  var
    LPackedLength, LRowIndex, LFlag, LNote: Integer;
    LEnd: Integer;
  begin
    LPattern := TTrackerPattern.Create(ROWS_PER_PATTERN, LUsedChannels);
    Result.Patterns.Add(LPattern);
    if AParagraph = 0 then
      Exit;

    LReader.Seek(AParagraph * 16);
    LPackedLength := LReader.ReadWord;
    LEnd := Min(LReader.Position + LPackedLength - 2, LReader.Size);

    LRowIndex := 0;
    while (LRowIndex < ROWS_PER_PATTERN) and (LReader.Position < LEnd) do
    begin
      LFlag := LReader.ReadByte;
      if LFlag = 0 then
      begin
        Inc(LRowIndex);
        Continue;
      end;

      LChannel := LFlag and 31;
      // Fields of a channel that is not used are read and dropped
      FillChar(LCell, SizeOf(LCell), 0);
      LCell.Volume := -1;
      if (LFlag and 32) <> 0 then
      begin
        LNote := LReader.ReadByte;
        if LNote = 254 then
          LCell.Note := TRACKER_NOTE_CUT
        else if LNote <> 255 then
          LCell.Note := Min((LNote shr 4) * 12 + (LNote and $0F) + 1, TRACKER_NOTE_LAST);
        LCell.Instrument := LReader.ReadByte;
      end;
      if (LFlag and 64) <> 0 then
        LCell.Volume := Min(LReader.ReadByte, 64);
      if (LFlag and 128) <> 0 then
      begin
        LCell.Effect := LReader.ReadByte;
        LCell.Param := LReader.ReadByte;
      end;

      if (LChannel < CHANNEL_SETTINGS) and LChannelMap[LChannel] then
        LPattern.Cells[LRowIndex, LChannel] := LCell;
    end;
  end;

begin
  if not Detect(AData) then
    raise ETrackerException.Create('Not an S3M (no SCRM signature)');

  LReader := TTrackerByteReader.Create(AData);
  Result := TTrackerModule.Create;
  try
    Result.Format := tfS3m;
    Result.Title := LReader.ReadText(28);
    LReader.Seek($20);
    LOrderCount := LReader.ReadWord;
    LInstrumentCount := LReader.ReadWord;
    LPatternCount := LReader.ReadWord;
    // The flags (the options of the effects) are not kept
    LReader.Skip(4);
    LSampleFormat := LReader.ReadWord;
    LReader.Seek($30);
    Result.GlobalVolume := Min(LReader.ReadByte, 64) * 2;
    LInitialSpeed := LReader.ReadByte;
    LInitialTempo := LReader.ReadByte;
    LMasterVolume := LReader.ReadByte;
    LReader.Skip(1);
    LDefaultPanning := LReader.ReadByte;
    if LInitialSpeed > 0 then
      Result.InitialSpeed := LInitialSpeed;
    if LInitialTempo >= 32 then
      Result.InitialTempo := LInitialTempo;

    LReader.Seek($40);
    for LIndex := 0 to CHANNEL_SETTINGS - 1 do
      LChannelSettings[LIndex] := LReader.ReadByte;

    // The used channels: the settings of the unused ones are 255. The channel
    // number of a cell is kept, so that the pattern has a column for each
    LUsedChannels := 0;
    for LIndex := 0 to CHANNEL_SETTINGS - 1 do
    begin
      LChannelMap[LIndex] := LChannelSettings[LIndex] < 16;
      if LChannelMap[LIndex] then
        LUsedChannels := LIndex + 1;
    end;
    if LUsedChannels = 0 then
      raise ETrackerException.Create('The S3M has no channels');
    Result.Channels := LUsedChannels;

    SetLength(Result.Orders, LOrderCount);
    for LIndex := 0 to LOrderCount - 1 do
      Result.Orders[LIndex] := LReader.ReadByte;
    SetLength(LInstrumentPointers, LInstrumentCount);
    for LIndex := 0 to LInstrumentCount - 1 do
      LInstrumentPointers[LIndex] := LReader.ReadWord;
    SetLength(LPatternPointers, LPatternCount);
    for LIndex := 0 to LPatternCount - 1 do
      LPatternPointers[LIndex] := LReader.ReadWord;

    // Panning: left channels 0..7 and right 8..15 by default; the table, if
    // present, gives each channel its own (bit 5 set means a value in the low nibble)
    SetLength(Result.ChannelPanning, LUsedChannels);
    for LChannel := 0 to LUsedChannels - 1 do
    begin
      if LChannelSettings[LChannel] < 8 then
        Result.ChannelPanning[LChannel] := 51
      else if LChannelSettings[LChannel] < 16 then
        Result.ChannelPanning[LChannel] := 204
      else
        Result.ChannelPanning[LChannel] := 128;
    end;
    // A mono module: every channel is in the middle
    if (LMasterVolume and $80) = 0 then
    begin
      for LChannel := 0 to LUsedChannels - 1 do
        Result.ChannelPanning[LChannel] := 128;
    end
    else if LDefaultPanning = DEFAULT_PANNING_PRESENT then
    begin
      for LChannel := 0 to CHANNEL_SETTINGS - 1 do
      begin
        LIndex := LReader.ReadByte;
        if ((LIndex and $20) <> 0) and (LChannel < LUsedChannels) then
          Result.ChannelPanning[LChannel] := (LIndex and $0F) * 17;
      end;
    end;

    for LIndex := 0 to LInstrumentCount - 1 do
      LoadInstrument(LInstrumentPointers[LIndex]);
    for LIndex := 0 to LPatternCount - 1 do
      LoadPattern(LPatternPointers[LIndex]);

  except
    LReader.Free;
    Result.Free;
    raise;
  end;
  LReader.Free;
end;

end.

