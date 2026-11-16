{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - loads a FastTracker 2 module (XM)                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Loader.Xm;

interface

uses
  System.SysUtils,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Reads an XM file of version 1.04: the packed patterns, the
  ///   instruments with their envelopes and the delta coded samples
  /// </summary>
  TTrackerXmLoader = class
  public
    /// <summary>True if the bytes start with "Extended Module: "</summary>
    class function Detect(const AData: TBytes): Boolean; static;

    /// <exception cref="ETrackerException">bad, truncated or old module</exception>
    class function Load(const AData: TBytes): TTrackerModule; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.ByteReader;

const
  SIGNATURE = 'Extended Module: ';
  SUPPORTED_VERSION = $0104;
  MAX_CHANNELS = 32;
  ENVELOPE_POINTS = 12;
  MIN_INSTRUMENT_HEADER = 29;
  XM_KEY_OFF = 97;
  SAMPLE_16BIT = $10;
  SAMPLE_LOOP_MASK = $03;
  ADPCM_MARK = $AD;

type
  // Header of a sample, with the length and loop in bytes as in the file
  TXmSampleHeader = record
    Length: Integer;
    LoopStart: Integer;
    LoopLength: Integer;
    Volume: Integer;
    Finetune: Integer;
    SampleType: Integer;
    Panning: Integer;
    RelativeNote: Integer;
    Reserved: Integer;
    Name: string;
  end;

{ TTrackerXmLoader }

class function TTrackerXmLoader.Detect(const AData: TBytes): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(AData) >= 60;
  if not Result then
    Exit;
  for LIndex := 1 to Length(SIGNATURE) do
  begin
    if AData[LIndex - 1] <> Ord(SIGNATURE[LIndex]) then
      Exit(False);
  end;
end;

class function TTrackerXmLoader.Load(const AData: TBytes): TTrackerModule;
var
  LReader: TTrackerByteReader;
  LHeaderSize, LSongLength, LPatternCount, LInstrumentCount, LFlags: Integer;
  LIndex: Integer;

  procedure LoadPattern;
  var
    LHeaderLength, LRows, LPackedSize, LRow, LChannel, LFlag, LEnd: Integer;
    LPattern: TTrackerPattern;
    LCell: TTrackerCell;
  begin
    LHeaderLength := Integer(LReader.ReadCardinal);
    LReader.ReadByte;
    LRows := LReader.ReadWord;
    LPackedSize := LReader.ReadWord;
    // The header may be longer than the nine bytes that are known
    if LHeaderLength > 9 then
      LReader.Skip(LHeaderLength - 9);
    if (LRows < 1) or (LRows > 256) then
      raise ETrackerException.Create('A pattern has a wrong number of rows');

    LPattern := TTrackerPattern.Create(LRows, Result.Channels);
    Result.Patterns.Add(LPattern);
    if LPackedSize = 0 then
      Exit;

    LEnd := LReader.Position + LPackedSize;
    if LEnd > LReader.Size then
      raise ETrackerException.Create('The module is truncated');

    for LRow := 0 to LRows - 1 do
    begin
      for LChannel := 0 to Result.Channels - 1 do
      begin
        FillChar(LCell, SizeOf(LCell), 0);
        LCell.Volume := -1;

        LFlag := LReader.ReadByte;
        if (LFlag and $80) <> 0 then
        begin
          if (LFlag and $01) <> 0 then
            LCell.Note := LReader.ReadByte;
          if (LFlag and $02) <> 0 then
            LCell.Instrument := LReader.ReadByte;
          if (LFlag and $04) <> 0 then
            LCell.Volume := LReader.ReadByte;
          if (LFlag and $08) <> 0 then
            LCell.Effect := LReader.ReadByte;
          if (LFlag and $10) <> 0 then
            LCell.Param := LReader.ReadByte;
        end
        else
        begin
          // An unpacked cell: the first byte is the note
          LCell.Note := LFlag;
          LCell.Instrument := LReader.ReadByte;
          LCell.Volume := LReader.ReadByte;
          LCell.Effect := LReader.ReadByte;
          LCell.Param := LReader.ReadByte;
        end;

        if LCell.Note = XM_KEY_OFF then
          LCell.Note := TRACKER_NOTE_OFF
        else if LCell.Note > TRACKER_NOTE_LAST then
          LCell.Note := 0;
        // The volume column: zero is "nothing"
        if LCell.Volume = 0 then
          LCell.Volume := -1;
        LPattern.Cells[LRow, LChannel] := LCell;
      end;
    end;
    LReader.Seek(LEnd);
  end;

  function ReadEnvelope(const APoints, ASustain, ALoopStart, ALoopEnd, AType: Integer;
    const ARaw: TBytes): TTrackerEnvelope;
  var
    LPoint: Integer;
  begin
    Result.Enabled := (AType and $01) <> 0;
    Result.Sustain := (AType and $02) <> 0;
    Result.Loop := (AType and $04) <> 0;
    Result.SustainStart := ASustain;
    Result.SustainEnd := ASustain;
    Result.LoopStart := ALoopStart;
    Result.LoopEnd := ALoopEnd;
    SetLength(Result.Points, Min(APoints, ENVELOPE_POINTS));
    for LPoint := 0 to High(Result.Points) do
    begin
      Result.Points[LPoint].Tick := ARaw[4 * LPoint] or (ARaw[4 * LPoint + 1] shl 8);
      Result.Points[LPoint].Value := Min(ARaw[4 * LPoint + 2] or (ARaw[4 * LPoint + 3] shl 8), 64);
    end;
  end;

  procedure LoadInstrument;
  var
    LStart, LHeaderSizeOfInstrument, LSampleCount, LSampleHeaderSize, LSample, LMapIndex: Integer;
    LInstrument: TTrackerInstrument;
    LSampleMap, LVolumeRaw, LPanningRaw: TBytes;
    LVolumePoints, LPanningPoints, LVolumeSustain, LVolumeLoopStart, LVolumeLoopEnd: Integer;
    LPanningSustain, LPanningLoopStart, LPanningLoopEnd, LVolumeType, LPanningType: Integer;
    LHeaders: array of TXmSampleHeader;
    LHeaderStart: Integer;
    LTrack: TTrackerSample;
    LRaw: TBytes;
    LValue, LOld, LPosition: Integer;
  begin
    LSampleHeaderSize := 0;
    LStart := LReader.Position;
    LHeaderSizeOfInstrument := Integer(LReader.ReadCardinal);
    if LHeaderSizeOfInstrument < MIN_INSTRUMENT_HEADER then
      raise ETrackerException.Create('An instrument has a wrong header');

    LInstrument := TTrackerInstrument.Create;
    Result.Instruments.Add(LInstrument);
    LInstrument.Name := LReader.ReadText(22);
    LReader.ReadByte;
    LSampleCount := LReader.ReadWord;

    if LSampleCount > 0 then
    begin
      LSampleHeaderSize := Integer(LReader.ReadCardinal);
      LSampleMap := LReader.ReadBytes(96);
      LVolumeRaw := LReader.ReadBytes(48);
      LPanningRaw := LReader.ReadBytes(48);
      LVolumePoints := LReader.ReadByte;
      LPanningPoints := LReader.ReadByte;
      LVolumeSustain := LReader.ReadByte;
      LVolumeLoopStart := LReader.ReadByte;
      LVolumeLoopEnd := LReader.ReadByte;
      LPanningSustain := LReader.ReadByte;
      LPanningLoopStart := LReader.ReadByte;
      LPanningLoopEnd := LReader.ReadByte;
      LVolumeType := LReader.ReadByte;
      LPanningType := LReader.ReadByte;
      // The vibrato: type, sweep, depth and rate
      LReader.Skip(4);
      LInstrument.FadeOut := LReader.ReadWord;

      LInstrument.VolumeEnvelope := ReadEnvelope(LVolumePoints, LVolumeSustain, LVolumeLoopStart,
        LVolumeLoopEnd, LVolumeType, LVolumeRaw);
      LInstrument.PanningEnvelope := ReadEnvelope(LPanningPoints, LPanningSustain, LPanningLoopStart,
        LPanningLoopEnd, LPanningType, LPanningRaw);
      for LMapIndex := 0 to 119 do
        LInstrument.SampleMap[LMapIndex] := LSampleMap[Min(LMapIndex, 95)];
    end;

    LReader.Seek(LStart + LHeaderSizeOfInstrument);
    if LSampleCount = 0 then
      Exit;
    if LSampleHeaderSize < 40 then
      raise ETrackerException.Create('An instrument has a wrong sample header');

    // All the sample headers come first, then all the sample data
    SetLength(LHeaders, LSampleCount);
    for LSample := 0 to LSampleCount - 1 do
    begin
      LHeaderStart := LReader.Position;
      LHeaders[LSample].Length := Integer(LReader.ReadCardinal);
      LHeaders[LSample].LoopStart := Integer(LReader.ReadCardinal);
      LHeaders[LSample].LoopLength := Integer(LReader.ReadCardinal);
      LHeaders[LSample].Volume := LReader.ReadByte;
      LHeaders[LSample].Finetune := ShortInt(LReader.ReadByte);
      LHeaders[LSample].SampleType := LReader.ReadByte;
      LHeaders[LSample].Panning := LReader.ReadByte;
      LHeaders[LSample].RelativeNote := ShortInt(LReader.ReadByte);
      LHeaders[LSample].Reserved := LReader.ReadByte;
      LHeaders[LSample].Name := LReader.ReadText(22);
      LReader.Seek(LHeaderStart + LSampleHeaderSize);
    end;

    for LSample := 0 to LSampleCount - 1 do
    begin
      LTrack := TTrackerSample.Create;
      Result.Samples.Add(LTrack);
      LInstrument.Samples.Add(LTrack);

      LTrack.Name := LHeaders[LSample].Name;
      LTrack.Volume := Min(LHeaders[LSample].Volume, 64);
      LTrack.Panning := LHeaders[LSample].Panning;
      LTrack.CenterFrequency := Max(1, Integer(Round(TRACKER_DEFAULT_CENTER_FREQUENCY *
        Power(2, (LHeaders[LSample].RelativeNote + LHeaders[LSample].Finetune / 128) / 12))));

      if LHeaders[LSample].Reserved = ADPCM_MARK then
      begin
        // ADPCM samples are not supported: they are skipped and stay empty
        LReader.Skip(Min(16 + (LHeaders[LSample].Length + 1) div 2, LReader.Remaining));
        Continue;
      end;
      if LHeaders[LSample].Length <= 0 then
        Continue;

      LRaw := LReader.ReadBytes(LHeaders[LSample].Length, True);
      LOld := 0;
      if (LHeaders[LSample].SampleType and SAMPLE_16BIT) <> 0 then
      begin
        SetLength(LTrack.Data, LHeaders[LSample].Length div 2);
        for LPosition := 0 to Length(LRaw) div 2 - 1 do
        begin
          LValue := LRaw[2 * LPosition] or (LRaw[2 * LPosition + 1] shl 8);
          LOld := (LOld + LValue) and $FFFF;
          if LOld >= 32768 then
            LTrack.Data[LPosition] := LOld - 65536
          else
            LTrack.Data[LPosition] := LOld;
        end;
        LHeaders[LSample].LoopStart := LHeaders[LSample].LoopStart div 2;
        LHeaders[LSample].LoopLength := LHeaders[LSample].LoopLength div 2;
      end
      else
      begin
        SetLength(LTrack.Data, LHeaders[LSample].Length);
        for LPosition := 0 to High(LRaw) do
        begin
          LOld := (LOld + LRaw[LPosition]) and $FF;
          if LOld >= 128 then
            LTrack.Data[LPosition] := (LOld - 256) * 256
          else
            LTrack.Data[LPosition] := LOld * 256;
        end;
      end;

      if ((LHeaders[LSample].SampleType and SAMPLE_LOOP_MASK) <> 0) and
        (LHeaders[LSample].LoopLength > 0) and (LHeaders[LSample].LoopStart < Length(LTrack.Data)) then
      begin
        if (LHeaders[LSample].SampleType and SAMPLE_LOOP_MASK) = 1 then
          LTrack.LoopType := tlForward
        else
          LTrack.LoopType := tlPingPong;
        LTrack.LoopStart := LHeaders[LSample].LoopStart;
        LTrack.LoopEnd := Min(LHeaders[LSample].LoopStart + LHeaders[LSample].LoopLength,
          Length(LTrack.Data));
      end;
    end;
  end;

begin
  if not Detect(AData) then
    raise ETrackerException.Create('Not an XM (no "Extended Module" signature)');

  LReader := TTrackerByteReader.Create(AData);
  Result := TTrackerModule.Create;
  try
    Result.Format := tfXm;
    LReader.Seek(17);
    Result.Title := LReader.ReadText(20);
    LReader.Seek(58);
    if LReader.ReadWord <> SUPPORTED_VERSION then
      raise ETrackerException.Create('Only the version 1.04 of XM is supported');
    LHeaderSize := Integer(LReader.ReadCardinal);
    LSongLength := LReader.ReadWord;
    Result.RestartPosition := LReader.ReadWord;
    Result.Channels := LReader.ReadWord;
    LPatternCount := LReader.ReadWord;
    LInstrumentCount := LReader.ReadWord;
    LFlags := LReader.ReadWord;
    Result.InitialSpeed := Max(1, LReader.ReadWord);
    Result.InitialTempo := Max(32, LReader.ReadWord);
    Result.LinearSlides := (LFlags and $01) <> 0;

    if (Result.Channels < 1) or (Result.Channels > MAX_CHANNELS) then
      raise ETrackerException.Create('The XM has a wrong number of channels');
    if (LSongLength < 1) or (LSongLength > 256) then
      raise ETrackerException.Create('The XM has a wrong song length');

    SetLength(Result.Orders, LSongLength);
    for LIndex := 0 to LSongLength - 1 do
      Result.Orders[LIndex] := LReader.ReadByte;
    if Result.RestartPosition >= LSongLength then
      Result.RestartPosition := 0;

    LReader.Seek(60 + LHeaderSize);
    for LIndex := 0 to LPatternCount - 1 do
      LoadPattern;
    for LIndex := 0 to LInstrumentCount - 1 do
      LoadInstrument;

    // XM has no panning for the channels
    SetLength(Result.ChannelPanning, Result.Channels);
    for LIndex := 0 to Result.Channels - 1 do
      Result.ChannelPanning[LIndex] := TRACKER_NO_PANNING;
  except
    LReader.Free;
    Result.Free;
    raise;
  end;
  LReader.Free;
end;

end.

