{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - loads an Impulse Tracker module (IT)                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Loader.It;

interface

uses
  System.SysUtils,
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Reads an IT file of version 2.00 or later: the packed patterns, the
  ///   instruments with their envelopes and note maps, and the samples
  ///   (plain, delta coded and compressed)
  /// </summary>
  TTrackerItLoader = class
  public
    /// <summary>True if the bytes start with "IMPM"</summary>
    class function Detect(const AData: TBytes): Boolean; static;

    /// <exception cref="ETrackerException">bad, truncated or too old module</exception>
    class function Load(const AData: TBytes): TTrackerModule; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tracker.ByteReader,
  DelphiDoom.Tracker.Decompressor.It;

const
  FLAG_INSTRUMENTS = $04;
  FLAG_LINEAR = $08;

  SAMPLE_HAS_DATA = $01;
  SAMPLE_16BIT = $02;
  SAMPLE_COMPRESSED = $08;
  SAMPLE_LOOP = $10;
  SAMPLE_PINGPONG = $40;

  CONVERT_SIGNED = $01;
  CONVERT_DELTA = $04;

  ENVELOPE_NODES = 25;
  CHANNELS = 64;
  PAN_SURROUND = 100;
  FIRST_NEW_INSTRUMENT_VERSION = $0200;

{ TTrackerItLoader }

class function TTrackerItLoader.Detect(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= 192) and (AData[0] = Ord('I')) and (AData[1] = Ord('M')) and
    (AData[2] = Ord('P')) and (AData[3] = Ord('M'));
end;

class function TTrackerItLoader.Load(const AData: TBytes): TTrackerModule;
var
  LReader: TTrackerByteReader;
  LOrderCount, LInstrumentCount, LSampleCount, LPatternCount, LFlags, LIndex: Integer;
  LCompatibleVersion: Integer;
  LChannelPan: array[0..CHANNELS - 1] of Byte;
  LUsedChannels: Integer;
  LInstrumentOffsets, LSampleOffsets, LPatternOffsets: TArray<Integer>;

  procedure LoadSample(const AOffset: Integer);
  var
    LSample: TTrackerSample;
    LFlagsOfSample, LConvert, LDefaultPan, LVolume, LC5Speed, LLength, LLoopBegin, LLoopEnd,
      LPointer, LPosition, LValue, LOld: Integer;
    LRaw: TBytes;
    LName: string;
  begin
    LSample := TTrackerSample.Create;
    Result.Samples.Add(LSample);
    if AOffset = 0 then
      Exit;

    LReader.Seek(AOffset);
    LReader.Skip(4);
    LReader.Skip(12);
    LReader.Skip(1);
    LReader.Skip(1);
    LFlagsOfSample := LReader.ReadByte;
    LVolume := LReader.ReadByte;
    LName := LReader.ReadText(26);
    LConvert := LReader.ReadByte;
    LDefaultPan := LReader.ReadByte;
    LLength := Integer(LReader.ReadCardinal);
    LLoopBegin := Integer(LReader.ReadCardinal);
    LLoopEnd := Integer(LReader.ReadCardinal);
    LC5Speed := Integer(LReader.ReadCardinal);
    LReader.Skip(8);
    LPointer := Integer(LReader.ReadCardinal);

    LSample.Name := LName;
    LSample.Volume := Min(LVolume, 64);
    // The C5 speed is for C-5; the model has the center frequency at C-4
    if LC5Speed <= 0 then
      LC5Speed := TRACKER_DEFAULT_CENTER_FREQUENCY * 2;
    LSample.CenterFrequency := Max(1, LC5Speed div 2);
    if (LDefaultPan and $80) <> 0 then
      LSample.Panning := Min((LDefaultPan and $7F) * 4, 255);

    if ((LFlagsOfSample and SAMPLE_HAS_DATA) = 0) or (LLength <= 0) or (LPointer <= 0) then
      Exit;

    LReader.Seek(Min(LPointer, LReader.Size));
    if (LFlagsOfSample and SAMPLE_COMPRESSED) <> 0 then
    begin
      LRaw := LReader.ReadBytes(LReader.Remaining);
      LSample.Data := TTrackerItDecompressor.Unpack(LRaw, LLength,
        (LFlagsOfSample and SAMPLE_16BIT) <> 0, (LConvert and CONVERT_DELTA) <> 0);
      // The compressed samples are always signed
    end
    else if (LFlagsOfSample and SAMPLE_16BIT) <> 0 then
    begin
      // Of a stereo sample only the left half is kept
      LRaw := LReader.ReadBytes(LLength * 2, True);
      SetLength(LSample.Data, LLength);
      LOld := 0;
      for LPosition := 0 to Length(LRaw) div 2 - 1 do
      begin
        LValue := LRaw[2 * LPosition] or (LRaw[2 * LPosition + 1] shl 8);
        if (LConvert and CONVERT_DELTA) <> 0 then
        begin
          LOld := (LOld + LValue) and $FFFF;
          LValue := LOld;
        end;
        if (LConvert and CONVERT_SIGNED) <> 0 then
        begin
          if LValue >= 32768 then
            LValue := LValue - 65536;
        end
        else
          LValue := LValue - 32768;
        LSample.Data[LPosition] := LValue;
      end;
    end
    else
    begin
      LRaw := LReader.ReadBytes(LLength, True);
      SetLength(LSample.Data, LLength);
      LOld := 0;
      for LPosition := 0 to High(LRaw) do
      begin
        LValue := LRaw[LPosition];
        if (LConvert and CONVERT_DELTA) <> 0 then
        begin
          LOld := (LOld + LValue) and $FF;
          LValue := LOld;
        end;
        if (LConvert and CONVERT_SIGNED) <> 0 then
        begin
          if LValue >= 128 then
            LValue := LValue - 256;
        end
        else
          LValue := LValue - 128;
        LSample.Data[LPosition] := LValue * 256;
      end;
    end;

    if ((LFlagsOfSample and SAMPLE_LOOP) <> 0) and (LLoopBegin < LLoopEnd) and
      (LLoopBegin < Length(LSample.Data)) then
    begin
      if (LFlagsOfSample and SAMPLE_PINGPONG) <> 0 then
        LSample.LoopType := tlPingPong
      else
        LSample.LoopType := tlForward;
      LSample.LoopStart := LLoopBegin;
      LSample.LoopEnd := Min(LLoopEnd, Length(LSample.Data));
    end;
  end;

  function ReadEnvelope(const AIsSigned: Boolean): TTrackerEnvelope;
  var
    LEnvelopeFlags, LNodes, LNode, LValue: Integer;
  begin
    LEnvelopeFlags := LReader.ReadByte;
    LNodes := Min(LReader.ReadByte, ENVELOPE_NODES);
    Result.LoopStart := LReader.ReadByte;
    Result.LoopEnd := LReader.ReadByte;
    Result.SustainStart := LReader.ReadByte;
    Result.SustainEnd := LReader.ReadByte;
    Result.Enabled := (LEnvelopeFlags and $01) <> 0;
    Result.Loop := (LEnvelopeFlags and $02) <> 0;
    Result.Sustain := (LEnvelopeFlags and $04) <> 0;
    SetLength(Result.Points, LNodes);
    for LNode := 0 to ENVELOPE_NODES - 1 do
    begin
      LValue := LReader.ReadByte;
      if LNode < LNodes then
      begin
        // The panning and pitch envelopes are signed (-32..32): 32 is the middle
        if AIsSigned then
          LValue := ShortInt(LValue) + 32;
        Result.Points[LNode].Value := Max(0, Min(LValue, 64));
        Result.Points[LNode].Tick := LReader.ReadWord;
      end
      else
        LReader.Skip(2);
    end;
    // One byte of padding
    LReader.Skip(1);
  end;

  procedure LoadInstrument(const AOffset: Integer);
  var
    LInstrument: TTrackerInstrument;
    LNote, LSampleNumber, LListIndex, LDefaultPan: Integer;
    LNotes, LSamples: array[0..119] of Byte;
    LUsed: array of Integer;
    LFound: Boolean;
  begin
    LInstrument := TTrackerInstrument.Create;
    Result.Instruments.Add(LInstrument);
    if AOffset = 0 then
      Exit;

    LReader.Seek(AOffset);
    LReader.Skip(4);
    LReader.Skip(12);
    LReader.Skip(1);
    LInstrument.NewNoteAction := TTrackerNewNoteAction(Min(LReader.ReadByte, 3));
    LInstrument.DuplicateCheckType := LReader.ReadByte;
    LInstrument.DuplicateCheckAction := LReader.ReadByte;
    LInstrument.FadeOut := LReader.ReadWord;
    LInstrument.PitchPanSeparation := ShortInt(LReader.ReadByte);
    LInstrument.PitchPanCenter := LReader.ReadByte;
    LInstrument.GlobalVolume := Min(LReader.ReadByte, 128);
    LDefaultPan := LReader.ReadByte;
    if (LDefaultPan and $80) = 0 then
      LInstrument.DefaultPanning := Min(LDefaultPan * 4, 255);
    LReader.Seek(AOffset + 32);
    LInstrument.Name := LReader.ReadText(26);
    LReader.Seek(AOffset + 64);
    for LNote := 0 to 119 do
    begin
      LNotes[LNote] := LReader.ReadByte;
      LSamples[LNote] := LReader.ReadByte;
    end;
    LInstrument.VolumeEnvelope := ReadEnvelope(False);
    LInstrument.PanningEnvelope := ReadEnvelope(True);
    LInstrument.PitchEnvelope := ReadEnvelope(True);

    // The samples that the instrument uses, in order of first use
    SetLength(LUsed, 0);
    for LNote := 0 to 119 do
    begin
      LSampleNumber := LSamples[LNote];
      LInstrument.NoteMap[LNote] := Min(LNotes[LNote], 119) + 1;
      if (LSampleNumber < 1) or (LSampleNumber > Result.Samples.Count) then
        Continue;

      LFound := False;
      for LListIndex := 0 to High(LUsed) do
      begin
        if LUsed[LListIndex] = LSampleNumber then
        begin
          LFound := True;
          Break;
        end;
      end;
      if not LFound then
      begin
        SetLength(LUsed, Length(LUsed) + 1);
        LUsed[High(LUsed)] := LSampleNumber;
        LInstrument.Samples.Add(Result.Samples[LSampleNumber - 1]);
      end;

      for LListIndex := 0 to High(LUsed) do
      begin
        if LUsed[LListIndex] = LSampleNumber then
          LInstrument.SampleMap[LNote] := LListIndex;
      end;
    end;
  end;

  procedure LoadPattern(const AOffset: Integer);
  var
    LPattern: TTrackerPattern;
    LPackedLength, LRows, LRow, LChannel, LVariable, LMask, LEnd, LNote: Integer;
    LLastMask: array[0..CHANNELS - 1] of Byte;
    LLastNote, LLastInstrument, LLastVolume, LLastEffect, LLastParam: array[0..CHANNELS - 1] of Byte;
    LCell: TTrackerCell;
  begin
    if AOffset = 0 then
    begin
      LPattern := TTrackerPattern.Create(64, CHANNELS);
      Result.Patterns.Add(LPattern);
      Exit;
    end;

    LReader.Seek(AOffset);
    LPackedLength := LReader.ReadWord;
    LRows := LReader.ReadWord;
    LReader.Skip(4);
    if (LRows < 1) or (LRows > 200) then
      raise ETrackerException.Create('A pattern has a wrong number of rows');
    LPattern := TTrackerPattern.Create(LRows, CHANNELS);
    Result.Patterns.Add(LPattern);

    LEnd := LReader.Position + LPackedLength;
    if LEnd > LReader.Size then
      raise ETrackerException.Create('The module is truncated');
    FillChar(LLastMask, SizeOf(LLastMask), 0);
    FillChar(LLastNote, SizeOf(LLastNote), 0);
    FillChar(LLastInstrument, SizeOf(LLastInstrument), 0);
    FillChar(LLastVolume, SizeOf(LLastVolume), 0);
    FillChar(LLastEffect, SizeOf(LLastEffect), 0);
    FillChar(LLastParam, SizeOf(LLastParam), 0);

    LRow := 0;
    while (LRow < LRows) and (LReader.Position < LEnd) do
    begin
      LVariable := LReader.ReadByte;
      if LVariable = 0 then
      begin
        Inc(LRow);
        Continue;
      end;

      LChannel := (LVariable - 1) and 63;
      if (LVariable and $80) <> 0 then
        LLastMask[LChannel] := LReader.ReadByte;
      LMask := LLastMask[LChannel];

      if (LMask and $01) <> 0 then
        LLastNote[LChannel] := LReader.ReadByte;
      if (LMask and $02) <> 0 then
        LLastInstrument[LChannel] := LReader.ReadByte;
      if (LMask and $04) <> 0 then
        LLastVolume[LChannel] := LReader.ReadByte;
      if (LMask and $08) <> 0 then
      begin
        LLastEffect[LChannel] := LReader.ReadByte;
        LLastParam[LChannel] := LReader.ReadByte;
      end;

      FillChar(LCell, SizeOf(LCell), 0);
      LCell.Volume := -1;
      if (LMask and $11) <> 0 then
      begin
        LNote := LLastNote[LChannel];
        if LNote < 120 then
          LCell.Note := LNote + 1
        else if LNote = 254 then
          LCell.Note := TRACKER_NOTE_CUT
        else
          // 255 is the note off and 253 the note fade
          LCell.Note := TRACKER_NOTE_OFF;
      end;
      if (LMask and $22) <> 0 then
        LCell.Instrument := LLastInstrument[LChannel];
      if (LMask and $44) <> 0 then
        LCell.Volume := LLastVolume[LChannel];
      if (LMask and $88) <> 0 then
      begin
        LCell.Effect := LLastEffect[LChannel];
        LCell.Param := LLastParam[LChannel];
      end;

      LPattern.Cells[LRow, LChannel] := LCell;
      if LChannel + 1 > LUsedChannels then
        LUsedChannels := LChannel + 1;
    end;
  end;

begin
  if not Detect(AData) then
    raise ETrackerException.Create('Not an IT (no IMPM signature)');

  LReader := TTrackerByteReader.Create(AData);
  Result := TTrackerModule.Create;
  try
    Result.Format := tfIt;
    LReader.Seek(4);
    Result.Title := LReader.ReadText(26);
    LReader.Seek(32);
    LOrderCount := LReader.ReadWord;
    LInstrumentCount := LReader.ReadWord;
    LSampleCount := LReader.ReadWord;
    LPatternCount := LReader.ReadWord;
    LReader.Skip(2);
    LCompatibleVersion := LReader.ReadWord;
    LFlags := LReader.ReadWord;
    LReader.Seek(48);
    Result.GlobalVolume := Min(LReader.ReadByte, 128);
    LReader.Skip(1);
    Result.InitialSpeed := Max(1, LReader.ReadByte);
    Result.InitialTempo := Max(32, LReader.ReadByte);
    Result.LinearSlides := (LFlags and FLAG_LINEAR) <> 0;

    if LCompatibleVersion < FIRST_NEW_INSTRUMENT_VERSION then
      raise ETrackerException.Create('Only the IT of version 2.00 or later is supported');

    LReader.Seek(64);
    for LIndex := 0 to CHANNELS - 1 do
      LChannelPan[LIndex] := LReader.ReadByte;
    LReader.Seek(192);
    SetLength(Result.Orders, LOrderCount);
    for LIndex := 0 to LOrderCount - 1 do
      Result.Orders[LIndex] := LReader.ReadByte;
    SetLength(LInstrumentOffsets, LInstrumentCount);
    for LIndex := 0 to LInstrumentCount - 1 do
      LInstrumentOffsets[LIndex] := Integer(LReader.ReadCardinal);
    SetLength(LSampleOffsets, LSampleCount);
    for LIndex := 0 to LSampleCount - 1 do
      LSampleOffsets[LIndex] := Integer(LReader.ReadCardinal);
    SetLength(LPatternOffsets, LPatternCount);
    for LIndex := 0 to LPatternCount - 1 do
      LPatternOffsets[LIndex] := Integer(LReader.ReadCardinal);

    for LIndex := 0 to LSampleCount - 1 do
      LoadSample(LSampleOffsets[LIndex]);
    LUsedChannels := 0;
    for LIndex := 0 to LPatternCount - 1 do
      LoadPattern(LPatternOffsets[LIndex]);
    Result.Channels := Max(1, LUsedChannels);

    if (LFlags and FLAG_INSTRUMENTS) <> 0 then
    begin
      for LIndex := 0 to LInstrumentCount - 1 do
        LoadInstrument(LInstrumentOffsets[LIndex]);
    end
    else
    begin
      // Without instruments, the notes use the samples directly
      for LIndex := 0 to LSampleCount - 1 do
      begin
        Result.Instruments.Add(TTrackerInstrument.Create);
        Result.Instruments[LIndex].Name := Result.Samples[LIndex].Name;
        Result.Instruments[LIndex].Samples.Add(Result.Samples[LIndex]);
      end;
    end;

    // The panning of the channels: 0..64 (left to right), 100 for surround
    // (the middle); the disabled channels keep their value
    SetLength(Result.ChannelPanning, Result.Channels);
    for LIndex := 0 to Result.Channels - 1 do
    begin
      if (LChannelPan[LIndex] and $7F) = PAN_SURROUND then
        Result.ChannelPanning[LIndex] := 128
      else
        Result.ChannelPanning[LIndex] := Min((LChannelPan[LIndex] and $7F) * 4, 255);
    end;
  except
    LReader.Free;
    Result.Free;
    raise;
  end;
  LReader.Free;
end;

end.

