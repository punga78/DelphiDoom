{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - the blocks of events of the midi stream           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from the CMIDI sample of Microsoft (ConvertToBuffer)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.StreamSequencer;

{$Q-}
{$R-}
// Times and tempos are unsigned numbers that wrap around, as in the old player

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Intf;

type
  /// <summary>
  ///   The old ConvertToBuffer / AddEventToStreamBuffer of TMidi (i_midi_new) without the
  ///   device: it walks the merged events of a song and writes them, one block at a time, as
  ///   the MIDIEVENT records of the midi stream
  /// </summary>
  /// <remarks>
  ///   It keeps what the old code did, defects included, so that the blocks are the same bytes:
  ///   the time of an event that is not written (system exclusive, meta) is counted in the
  ///   delta of the next one; an event that does not fit a block and waits for the next one has
  ///   a delta of zero; the position in time is not reset when the song loops, so the first
  ///   event after the end has a delta that wraps around. The only difference is the tempo
  ///   event inserted by RequestTempoEvent: the old code wrote the event that follows it 192
  ///   bytes farther than the 12 that it counted (a pointer to a record of 16 bytes moved by 12
  ///   steps), so the stream played what the buffer held before; here it follows at once
  /// </remarks>
  TMidiStreamSequencer = class(TInterfacedObject, IMidiStreamSequencer)
  strict private
    type
      /// <summary>The block being written: the old TCONVERTINFO</summary>
      TBlockState = record
        Bytes: TBytes;
        MaxLength: Integer;
        BytesRecorded: Integer;
        TickStart: Cardinal;
        TimesUp: Boolean;
      end;
    var
      FLog: ILog;
      FEvents: TArray<TMidiSequenceEvent>;
      FNextEvent: Integer;
      FDivision: Word;
      FLooped: Boolean;
      FDone: Boolean;
      FPendingValid: Boolean;
      FPending: TMidiSequenceEvent;
      FCurrentTime: Cardinal;
      FBufferTickLength: Cardinal;
      FCurrentTempo: Cardinal;
      FTempoPercent: Cardinal;
      FInsertTempo: Boolean;
    function GetTimeDivision: Word;
    function GetLooped: Boolean;
    procedure SetLooped(AValue: Boolean);
    function GetTempoPercent: Cardinal;
    procedure SetTempoPercent(AValue: Cardinal);
    function HasRoom(const AState: TBlockState): Boolean;
    procedure WriteEvent(var AState: TBlockState; ADelta, AEventValue: Cardinal);
    function TempoValue(ATempo: Cardinal): Cardinal;
    /// <summary>False when the event does not fit the block: it stays for the next one</summary>
    function AddEvent(const AEvent: TMidiSequenceEvent; var AState: TBlockState): Boolean;
    function ConvertInto(AReset: Boolean; var AState: TBlockState): TMidiConvertResult;
  public
    /// <summary>ALog may be nil</summary>
    constructor Create(const ALog: ILog);
    function Load(AData: Pointer; ASize: Integer): Boolean;
    function ConvertBlock(AReset: Boolean; AMaxLength: Integer;
      out ABytes: TBytes): TMidiConvertResult;
    procedure Rewind;
    procedure RequestTempoEvent;
  end;

implementation

uses
  DelphiDoom.Midi.SequenceLoader;

const
  // the milliseconds of a song that a block covers
  BUFFER_TIME_LENGTH = 60;
  DEFAULT_TEMPO_PERCENT = 100;

{ TMidiStreamSequencer }

constructor TMidiStreamSequencer.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
  FTempoPercent := DEFAULT_TEMPO_PERCENT;
end;

function TMidiStreamSequencer.GetTimeDivision: Word;
begin
  Result := FDivision;
end;

function TMidiStreamSequencer.GetLooped: Boolean;
begin
  Result := FLooped;
end;

procedure TMidiStreamSequencer.SetLooped(AValue: Boolean);
begin
  FLooped := AValue;
end;

function TMidiStreamSequencer.GetTempoPercent: Cardinal;
begin
  Result := FTempoPercent;
end;

procedure TMidiStreamSequencer.SetTempoPercent(AValue: Cardinal);
begin
  if AValue <> 0 then
    FTempoPercent := AValue
  else
    FTempoPercent := 1;
  FInsertTempo := True;
end;

function TMidiStreamSequencer.Load(AData: Pointer; ASize: Integer): Boolean;
begin
  Result := TMidiSequenceLoader.TryLoad(AData, ASize, FLog, FEvents, FDivision);
  FNextEvent := 0;
  FDone := False;
  FPendingValid := False;
  FPending := Default(TMidiSequenceEvent);
  FCurrentTime := 0;
  FBufferTickLength := 0;
  FCurrentTempo := 0;
  FInsertTempo := False;
end;

procedure TMidiStreamSequencer.Rewind;
begin
  // the old code always cleared the state of the conversion after rewinding the tracks
  FNextEvent := 0;
  FDone := False;
  FPendingValid := False;
end;

procedure TMidiStreamSequencer.RequestTempoEvent;
begin
  FInsertTempo := True;
end;

function TMidiStreamSequencer.HasRoom(const AState: TBlockState): Boolean;
begin
  Result := AState.MaxLength - AState.BytesRecorded >= MIDI_STREAM_EVENT_SIZE;
end;

procedure TMidiStreamSequencer.WriteEvent(var AState: TBlockState; ADelta, AEventValue: Cardinal);
var
  LEvent: TMidiStreamEvent;
begin
  LEvent.Time := ADelta;
  LEvent.StreamId := 0;
  LEvent.Event := AEventValue;
  Move(LEvent, AState.Bytes[AState.BytesRecorded], MIDI_STREAM_EVENT_SIZE);
  Inc(AState.BytesRecorded, MIDI_STREAM_EVENT_SIZE);
end;

function TMidiStreamSequencer.TempoValue(ATempo: Cardinal): Cardinal;
begin
  // the tempo of the file is scaled by the speed of the playback
  Result := Cardinal((Int64(ATempo) * 100) div Int64(FTempoPercent)) or
    (Cardinal(MIDI_STREAM_TEMPO) shl 24);
end;

function TMidiStreamSequencer.AddEvent(const AEvent: TMidiSequenceEvent;
  var AState: TBlockState): Boolean;
var
  LDelta: Cardinal;
  LValue: Cardinal;
begin
  // a new, empty block starts at the current time
  if AState.BytesRecorded = 0 then
    AState.TickStart := FCurrentTime;

  // when the block has covered its time it is full, but only the second event over that limit
  // is left for the next block
  if Cardinal(FCurrentTime - AState.TickStart) > FBufferTickLength then
  begin
    if AState.TimesUp then
    begin
      AState.TimesUp := False;
      Result := False;
      Exit;
    end;
    AState.TimesUp := True;
  end;

  LDelta := Cardinal(AEvent.Time - FCurrentTime);
  FCurrentTime := AEvent.Time;

  if FInsertTempo then
  begin
    FInsertTempo := False;
    if not HasRoom(AState) then
    begin
      Result := False;
      Exit;
    end;
    if FCurrentTempo <> 0 then
      WriteEvent(AState, 0, TempoValue(FCurrentTempo));
  end;

  case AEvent.Kind of
    mskChannel:
      begin
        if not HasRoom(AState) then
        begin
          Result := False;
          Exit;
        end;
        LValue := Cardinal(AEvent.Status) or (Cardinal(AEvent.Data1) shl 8) or
          (Cardinal(AEvent.Data2) shl 16);
        // a change of volume asks for a callback: the player keeps the volume of the channel
        if ((AEvent.Status and $F0) = MIDI_CONTROL_CHANGE) and (AEvent.Data1 = MIDI_CONTROLLER_VOLUME) then
          LValue := LValue or MIDI_STREAM_CALLBACK;
        WriteEvent(AState, LDelta, LValue);
      end;
    mskTempo:
      begin
        if not HasRoom(AState) then
        begin
          Result := False;
          Exit;
        end;
        FCurrentTempo := AEvent.Tempo;
        WriteEvent(AState, LDelta, TempoValue(FCurrentTempo));
        FBufferTickLength := Cardinal((Int64(FDivision) * 1000 * BUFFER_TIME_LENGTH) div Int64(FCurrentTempo));
      end;
  else
    // system exclusive and the other meta events are not played
  end;
  Result := True;
end;

function TMidiStreamSequencer.ConvertInto(AReset: Boolean;
  var AState: TBlockState): TMidiConvertResult;
begin
  Result := mcrNoError;
  if AReset then
  begin
    FDone := False;
    FPendingValid := False;
  end;

  if FDone then
  begin
    if not FLooped then
    begin
      Result := mcrDone;
      Exit;
    end;
    Rewind;
  end
  else if FPendingValid then
  begin
    // the event that did not fit the last block goes first
    FPendingValid := False;
    if not AddEvent(FPending, AState) then
    begin
      FPendingValid := True;
      Exit;
    end;
  end;

  while True do
  begin
    if FNextEvent >= Length(FEvents) then
    begin
      FDone := True;
      Exit;
    end;
    FPending := FEvents[FNextEvent];
    Inc(FNextEvent);
    if not AddEvent(FPending, AState) then
    begin
      FPendingValid := True;
      Exit;
    end;
  end;
end;

function TMidiStreamSequencer.ConvertBlock(AReset: Boolean; AMaxLength: Integer;
  out ABytes: TBytes): TMidiConvertResult;
var
  LState: TBlockState;
begin
  LState := Default(TBlockState);
  if AMaxLength < 0 then
    AMaxLength := 0;
  LState.MaxLength := AMaxLength;
  SetLength(LState.Bytes, AMaxLength);
  Result := ConvertInto(AReset, LState);
  SetLength(LState.Bytes, LState.BytesRecorded);
  ABytes := LState.Bytes;
end;

end.
