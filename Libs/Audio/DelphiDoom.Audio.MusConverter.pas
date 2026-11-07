{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - MUS songs to events of the midi stream          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.MusConverter;

{$Q-}
{$R-}
// The delays of the events are built with shifts that wrap around, as in the old code

interface

uses
  System.SysUtils,
  DelphiDoom.Audio.Types,
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Turns a MUS song into the events that the midi stream of Windows plays, as GetSongLength
  ///   and I_MusToMidi of the old i_music did: two tempo events, then one event for every event
  ///   of the score (the drums go from channel 15 to 9 and back), the last one is the end of the
  ///   song. The number of events is counted before, on the bytes of the song
  /// </summary>
  /// <remarks>
  ///   A byte after the end of the song is read as zero (the old code read the memory after it);
  ///   a controller number over 9 gives the controller 0 (the old code read after its table)
  /// </remarks>
  TMusConverter = class
  public
    /// <summary>The bytes start with MUS and $1A</summary>
    class function IsMus(AData: PByte; ASize: Integer): Boolean; static;
    /// <summary>The bytes start with MThd: a standard MIDI file</summary>
    class function IsMidiFile(AData: PByte; ASize: Integer): Boolean; static;
    /// <summary>
    ///   The number of events that the song gives (two of tempo, the end included); two if it is
    ///   not a MUS song
    /// </summary>
    class function EventCount(AData: PByte; ASize: Integer): Integer; static;
    /// <summary>
    ///   The events of a MUS song, with ATempo in the two tempo events. False, with no events, for
    ///   a MIDI file (silent) or for bytes that are not MUS (a warning to the log)
    /// </summary>
    /// <exception cref="EMusConversionException">
    ///   a controller of the system that MUS does not have, or more events than counted
    /// </exception>
    class function TryConvert(AData: PByte; ASize: Integer; ATempo: Byte; const ALog: ILog;
      out AEvents: TArray<TMusMidiEvent>): Boolean; static;
  end;

implementation

const
  MUS_ID = $1A53554D;
  MIDI_FILE_ID = $6468544D;
  // the offset of scoreStart in the header of a MUS song
  MUS_SCORE_START = 6;
  TEMPO_EVENTS = 2;

  // the event types of MMSystem: MEVT_SHORTMSG and MEVT_TEMPO
  EVENT_SHORT_MESSAGE = 0;
  EVENT_TEMPO = 1;

  MUS_CONTROLLERS: packed array[0..9] of Byte = (0, 0, 1, 7, 10, 11, 91, 93, 64, 67);

  SNotMus = 'I_MusToMidi(): Not a MUS file'#13#10;
  SUnknownControl = 'XLateMUSControl(): Unknown control %d';
  SOverflow = 'I_MusToMidi(): Overflow';

type
  /// <summary>The bytes of a song, zero after the end</summary>
  TMusBytes = record
    Data: PByte;
    Size: Integer;
    function At(AIndex: Integer): Byte; inline;
  end;

function TMusBytes.At(AIndex: Integer): Byte;
begin
  if (AIndex >= 0) and (AIndex < Size) then
    Result := PByte(NativeUInt(Data) + NativeUInt(AIndex))^
  else
    Result := 0;
end;

function LongAt(const ABytes: TMusBytes; AIndex: Integer): Cardinal;
begin
  Result := ABytes.At(AIndex) or (Cardinal(ABytes.At(AIndex + 1)) shl 8) or
    (Cardinal(ABytes.At(AIndex + 2)) shl 16) or (Cardinal(ABytes.At(AIndex + 3)) shl 24);
end;

function SystemController(AControl: Byte): Byte;
begin
  case AControl of
    10: Result := 120;
    11: Result := 123;
    12: Result := 126;
    13: Result := 127;
    14: Result := 121;
  else
    raise EMusConversionException.CreateFmt(SUnknownControl, [AControl]);
  end;
end;

{ TMusConverter }

class function TMusConverter.IsMus(AData: PByte; ASize: Integer): Boolean;
var
  LBytes: TMusBytes;
begin
  LBytes.Data := AData;
  LBytes.Size := ASize;
  Result := Assigned(AData) and (LongAt(LBytes, 0) = MUS_ID);
end;

class function TMusConverter.IsMidiFile(AData: PByte; ASize: Integer): Boolean;
var
  LBytes: TMusBytes;
begin
  LBytes.Data := AData;
  LBytes.Size := ASize;
  Result := Assigned(AData) and (LongAt(LBytes, 0) = MIDI_FILE_ID);
end;

class function TMusConverter.EventCount(AData: PByte; ASize: Integer): Integer;
var
  LBytes: TMusBytes;
  LDone: Boolean;
  LEvents: Integer;
  LTime: Boolean;
  LIndex: Integer;

  // the old _inc_i: true while the index is not past the end (the end itself included)
  function Advance: Boolean;
  begin
    Inc(LIndex);
    Result := LIndex <= ASize;
  end;

begin
  LBytes.Data := AData;
  LBytes.Size := ASize;
  LIndex := LBytes.At(MUS_SCORE_START) or (Integer(LBytes.At(MUS_SCORE_START + 1)) shl 8);
  LEvents := 0;
  LDone := not IsMus(AData, ASize);
  LTime := False;
  while not LDone do
  begin
    if LBytes.At(LIndex) and $80 <> 0 then
      LTime := True;
    if not Advance then
      Break;
    case (LBytes.At(LIndex - 1) shr 4) and 7 of
      1:
        begin
          if LBytes.At(LIndex) and $80 <> 0 then
            if not Advance then
              Break;
          if not Advance then
            Break;
        end;
      0, 2, 3:
        if not Advance then
          Break;
      4:
        begin
          if not Advance then
            Break;
          if not Advance then
            Break;
        end;
    else
      LDone := True;
    end;
    Inc(LEvents);
    if LTime then
    begin
      // a Break here leaves only the loop of the delay, as in the old code
      while LBytes.At(LIndex) and $80 <> 0 do
        if not Advance then
          Break;
      if not Advance then
        Break;
      LTime := False;
    end;
  end;
  Result := LEvents + TEMPO_EVENTS;
end;

class function TMusConverter.TryConvert(AData: PByte; ASize: Integer; ATempo: Byte;
  const ALog: ILog; out AEvents: TArray<TMusMidiEvent>): Boolean;
var
  LBytes: TMusBytes;
  LScore: Integer;
  LCount: Integer;
  LPosition: Integer;
  LEvent: Integer;
  LChannel: Byte;
  LType: Integer;
  LDelta: Integer;
  LFinished: Boolean;
  LVolumes: array[0..15] of Byte;
  LIndex: Integer;
  LByte: Byte;

  function ScoreAt(AOffset: Integer): Byte;
  begin
    Result := LBytes.At(LScore + AOffset);
  end;

begin
  AEvents := nil;
  if IsMidiFile(AData, ASize) then
    Exit(False);
  if not IsMus(AData, ASize) then
  begin
    if Assigned(ALog) then
      ALog.Warning(SNotMus);
    Exit(False);
  end;

  LBytes.Data := AData;
  LBytes.Size := ASize;
  LScore := LBytes.At(MUS_SCORE_START) or (Integer(LBytes.At(MUS_SCORE_START + 1)) shl 8);
  LCount := EventCount(AData, ASize);
  // one more than counted: the old code wrote the event that overflows before it stopped
  SetLength(AEvents, LCount + 1);
  FillChar(AEvents[0], Length(AEvents) * SizeOf(TMusMidiEvent), 0);

  LEvent := 0;
  for LIndex := 0 to TEMPO_EVENTS - 1 do
  begin
    AEvents[LEvent].EventType := EVENT_TEMPO;
    AEvents[LEvent].Data[0] := $00;
    AEvents[LEvent].Data[1] := ATempo;
    AEvents[LEvent].Data[2] := $02;
    Inc(LEvent);
  end;

  LDelta := 0;
  LPosition := 0;
  FillChar(LVolumes, SizeOf(LVolumes), 0);
  LFinished := False;
  while True do
  begin
    AEvents[LEvent].Time := Cardinal(LDelta);
    LDelta := 0;
    AEvents[LEvent].StreamId := 0;
    LByte := ScoreAt(LPosition);
    LType := (LByte shr 4) and 7;
    AEvents[LEvent].EventType := EVENT_SHORT_MESSAGE;
    LChannel := LByte and 15;
    // MUS has the drums on channel 15, MIDI on channel 9
    if LChannel = 9 then
      LChannel := 15
    else if LChannel = 15 then
      LChannel := 9;
    if LByte and $80 <> 0 then
      LDelta := -1;
    Inc(LPosition);
    case LType of
      0:
        begin
          AEvents[LEvent].Data[0] := LChannel or $80;
          AEvents[LEvent].Data[1] := ScoreAt(LPosition);
          Inc(LPosition);
          AEvents[LEvent].Data[2] := LVolumes[LChannel];
        end;
      1:
        begin
          AEvents[LEvent].Data[0] := LChannel or $90;
          AEvents[LEvent].Data[1] := ScoreAt(LPosition) and 127;
          if ScoreAt(LPosition) and 128 <> 0 then
          begin
            Inc(LPosition);
            LVolumes[LChannel] := ScoreAt(LPosition);
          end;
          Inc(LPosition);
          AEvents[LEvent].Data[2] := LVolumes[LChannel];
        end;
      2:
        begin
          AEvents[LEvent].Data[0] := LChannel or $E0;
          // the fix of the pitch of JVAL (20171030): the first byte is always zero
          AEvents[LEvent].Data[1] := (ScoreAt(LPosition) and 1) shr 6;
          AEvents[LEvent].Data[2] := (ScoreAt(LPosition) div 2) and 127;
          Inc(LPosition);
        end;
      3:
        begin
          AEvents[LEvent].Data[0] := LChannel or $B0;
          AEvents[LEvent].Data[1] := SystemController(ScoreAt(LPosition));
          Inc(LPosition);
          AEvents[LEvent].Data[2] := 0;
        end;
      4:
        begin
          if ScoreAt(LPosition) <> 0 then
          begin
            AEvents[LEvent].Data[0] := LChannel or $B0;
            if ScoreAt(LPosition) <= High(MUS_CONTROLLERS) then
              AEvents[LEvent].Data[1] := MUS_CONTROLLERS[ScoreAt(LPosition)]
            else
              AEvents[LEvent].Data[1] := 0;
            Inc(LPosition);
            AEvents[LEvent].Data[2] := ScoreAt(LPosition);
            Inc(LPosition);
          end
          else
          begin
            AEvents[LEvent].Data[0] := LChannel or $C0;
            Inc(LPosition);
            AEvents[LEvent].Data[1] := ScoreAt(LPosition);
            Inc(LPosition);
            AEvents[LEvent].Data[2] := 64;
          end;
        end;
    else
      LFinished := True;
    end;
    if LFinished then
      Break;
    Inc(LEvent);
    Dec(LCount);
    if LCount < 3 then
      raise EMusConversionException.Create(SOverflow);
    if LDelta = -1 then
    begin
      LDelta := 0;
      while ScoreAt(LPosition) and 128 <> 0 do
      begin
        LDelta := LDelta shl 7;
        LDelta := LDelta + ScoreAt(LPosition) and 127;
        Inc(LPosition);
      end;
      LDelta := LDelta + ScoreAt(LPosition);
      Inc(LPosition);
    end;
  end;
  SetLength(AEvents, Length(AEvents) - 1);
  Result := True;
end;

end.
