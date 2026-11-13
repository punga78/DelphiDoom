{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the events of a song with their time              }
{                                                                              }
{  Port of the times of tml_load (tml.h of TinySoundFont, zlib License,         }
{  (c) 2017, 2018 Bernhard Schelling) as war1 (acoto87/war1) uses them in       }
{  wa_playMidi, (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\  }
{  LICENSE-war1.txt). This is an altered version, not the original.             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.Timeline;

{$Q-}
{$R-}
// the ticks are unsigned numbers that wrap around, as in the original

interface

uses
  System.SysUtils, DelphiDoom.Midi.Types, DelphiDoom.Midi.Intf, DelphiDoom.War.Music.Types,
  DelphiDoom.War.Music.Intf;

type
  /// <summary>
  ///   Reads the song with the sequencer of Libs\Midi (it merges the tracks and counts the ticks) and gives the
  ///   time of each event in whole milliseconds the way tml_load does: the time is the one of the last change of
  ///   tempo plus the ticks since it times the milliseconds of a tick, truncated. Tempo events are not given, they
  ///   only change the time of the events after them
  /// </summary>
  TWarMusicTimeline = class(TInterfacedObject, IWarMusicTimeline)
  strict private
    FSequencer: IMidiStreamSequencer;
    FQueue: TArray<TMidiStreamEvent>;
    FQueuePosition: Integer;
    FFirstBlock: Boolean;
    FFinished: Boolean;
    FLoaded: Boolean;
    FTicks: Cardinal;
    FTempoTicks: Cardinal;
    FTempoMs: Integer;
    FTicksToMs: Double;
    procedure ResetClock;
    function Refill: Boolean;
    function Decode(const ARecord: TMidiStreamEvent; out AEvent: TWarMusicEvent): Boolean;
  public
    constructor Create(const ASequencer: IMidiStreamSequencer);
    function Load(const AMidi: TBytes): Boolean;
    function TryNext(out AEvent: TWarMusicEvent): Boolean;
    procedure Rewind;
  end;

implementation

uses
  DelphiDoom.War.Types;

const
  // the tempo of a song that sets none: 120 beats per minute
  DEFAULT_TEMPO = 500000;

{ TWarMusicTimeline }

constructor TWarMusicTimeline.Create(const ASequencer: IMidiStreamSequencer);
begin
  inherited Create;
  if not Assigned(ASequencer) then
    raise EWarException.Create('The sequencer of the music timeline is nil');
  FSequencer := ASequencer;
  FFinished := True;
end;

procedure TWarMusicTimeline.ResetClock;
begin
  FTicks := 0;
  FTempoTicks := 0;
  FTempoMs := 0;
  if FSequencer.TimeDivision <> 0 then
    FTicksToMs := DEFAULT_TEMPO / (1000.0 * FSequencer.TimeDivision)
  else
    FTicksToMs := 0;
end;

function TWarMusicTimeline.Load(const AMidi: TBytes): Boolean;
begin
  FQueue := nil;
  FQueuePosition := 0;
  FFirstBlock := True;
  FLoaded := False;
  FFinished := True;
  if Length(AMidi) = 0 then
    Exit(False);
  Result := FSequencer.Load(@AMidi[0], Length(AMidi));
  FLoaded := Result;
  FFinished := not Result;
  // a song that sets SMPTE time has no ticks per beat: tml_load refuses it
  if Result and ((FSequencer.TimeDivision = 0) or ((FSequencer.TimeDivision and $8000) <> 0)) then
  begin
    FLoaded := False;
    FFinished := True;
    Exit(False);
  end;
  ResetClock;
end;

procedure TWarMusicTimeline.Rewind;
begin
  if not FLoaded then
    Exit;
  FSequencer.Rewind;
  FQueue := nil;
  FQueuePosition := 0;
  FFirstBlock := True;
  FFinished := False;
  ResetClock;
end;

function TWarMusicTimeline.Refill: Boolean;
var
  LBytes: TBytes;
  LCount: Integer;
  LResult: TMidiConvertResult;
  LTries: Integer;
begin
  Result := False;
  if FFinished then
    Exit;
  // a block can come back empty only when the song has no event left: the next call says it is done
  for LTries := 0 to 1 do
  begin
    LResult := FSequencer.ConvertBlock(FFirstBlock, WAR_MUSIC_STREAM_BYTES, LBytes);
    FFirstBlock := False;
    if LResult = mcrDone then
      Break;
    LCount := Length(LBytes) div MIDI_STREAM_EVENT_SIZE;
    if LCount > 0 then
    begin
      SetLength(FQueue, LCount);
      Move(LBytes[0], FQueue[0], LCount * MIDI_STREAM_EVENT_SIZE);
      FQueuePosition := 0;
      Exit(True);
    end;
  end;
  FFinished := True;
end;

function TWarMusicTimeline.Decode(const ARecord: TMidiStreamEvent; out AEvent: TWarMusicEvent): Boolean;
var
  LStatus: Byte;
  LTempo: Cardinal;
  LMs: Cardinal;
begin
  Inc(FTicks, ARecord.Time);
  // msec = tempo_msec + (int)((ticks - tempo_ticks) * ticks2time)
  LMs := Cardinal(FTempoMs + Trunc(Cardinal(FTicks - FTempoTicks) * FTicksToMs));
  Result := False;
  AEvent := Default(TWarMusicEvent);
  if (ARecord.EventType and $0F) = MIDI_STREAM_TEMPO then
  begin
    LTempo := ARecord.Event and $00FFFFFF;
    FTicksToMs := LTempo / (1000.0 * FSequencer.TimeDivision);
    FTempoMs := Integer(LMs);
    FTempoTicks := FTicks;
    // the original keeps the tempo message in the list: it counts as the last message of the song
    AEvent.TimeMs := LMs;
    AEvent.Kind := wmkIgnored;
    Exit(True);
  end;
  LStatus := ARecord.Data[0];
  AEvent.TimeMs := LMs;
  AEvent.Channel := LStatus and $0F;
  case LStatus and $F0 of
    $80:
      begin
        AEvent.Kind := wmkNoteOff;
        AEvent.Key := ARecord.Data[1] and $7F;
        Result := True;
      end;
    $90:
      begin
        AEvent.Kind := wmkNoteOn;
        AEvent.Key := ARecord.Data[1] and $7F;
        AEvent.Value := ARecord.Data[2] and $7F;
        Result := True;
      end;
    $B0:
      begin
        AEvent.Kind := wmkControlChange;
        AEvent.Key := ARecord.Data[1] and $7F;
        AEvent.Value := ARecord.Data[2] and $7F;
        Result := True;
      end;
    $C0:
      begin
        AEvent.Kind := wmkProgramChange;
        AEvent.Key := ARecord.Data[1] and $7F;
        Result := True;
      end;
    $E0:
      begin
        AEvent.Kind := wmkPitchBend;
        AEvent.Value := ((ARecord.Data[2] and $7F) shl 7) or (ARecord.Data[1] and $7F);
        Result := True;
      end;
    $A0, $D0:
      begin
        // key pressure and channel pressure are messages of the list that wa_playMidi does not play
        AEvent.Kind := wmkIgnored;
        Result := True;
      end;
  end;
end;

function TWarMusicTimeline.TryNext(out AEvent: TWarMusicEvent): Boolean;
begin
  AEvent := Default(TWarMusicEvent);
  while True do
  begin
    if FQueuePosition >= Length(FQueue) then
      if not Refill then
        Exit(False);
    Inc(FQueuePosition);
    if Decode(FQueue[FQueuePosition - 1], AEvent) then
      Exit(True);
  end;
end;

end.
