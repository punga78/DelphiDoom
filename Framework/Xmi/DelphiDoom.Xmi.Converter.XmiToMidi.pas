{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI - turns the events of an XMIDI song into standard MIDI      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Converter.XmiToMidi;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Song, DelphiDoom.Xmi.Midi.Track;

type
  /// <summary>
  ///   Gives an XMIDI song the events of a standard MIDI one
  /// </summary>
  /// <remarks>
  ///   An XMIDI note has a duration and no Note Off. The converter turns the
  ///   duration of every note into a Note Off event placed where the note
  ///   ends (the ones that end together in the same tick, the first with the
  ///   delay and the others without), drops the Note Off events some files
  ///   have, and rescales the delays by the tempo events so that they are
  ///   measured with the tempo of the start of the song
  /// </remarks>
  TXmiXmiToMidiConverter = class
  private
    class function ChannelOfNewEvent(ATrack: TXmiTrack): Byte; static;
    class procedure InsertNoteOff(ATrack: TXmiTrack; AIndex: Integer); static;
    class procedure ConvertNotes(ATrack: TXmiTrack); static;
    class procedure ScaleDelays(ATrack: TXmiTrack; AInitialTempo: Cardinal;
      var ATempo: Cardinal); static;
  public
    /// <summary>
    ///   Converts every track of the song in place
    /// </summary>
    class procedure Convert(ASong: TXmiSong); static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types;

const
  STATUS_NOTE_OFF = $80;
  STATUS_NOTE_ON = $90;
  DEFAULT_NOTE = 48;

type
  /// <summary>
  ///   A note that has started and has not been turned off yet
  /// </summary>
  TActiveNote = record
    Channel: Byte;
    Note: Byte;
    RemainingTicks: UInt64;
  end;

{ TXmiXmiToMidiConverter }

class function TXmiXmiToMidiConverter.ChannelOfNewEvent(ATrack: TXmiTrack): Byte;
var
  LIndex: Integer;
begin
  // The channel of the first event that has one. A Note Off is added only
  // for a Note On of the track, so there is always one: the search never
  // goes beyond the last event
  LIndex := 0;
  while not (ATrack.EventAt(LIndex).Status shr 4 in [8..14]) do
    Inc(LIndex);
  Result := ATrack.EventAt(LIndex).Status and 15;
end;

class procedure TXmiXmiToMidiConverter.InsertNoteOff(ATrack: TXmiTrack; AIndex: Integer);
var
  LEvent: TXmiEvent;
begin
  LEvent := Default(TXmiEvent);
  LEvent.Status := STATUS_NOTE_OFF or ChannelOfNewEvent(ATrack);
  LEvent.Param1 := DEFAULT_NOTE;
  LEvent.Param2 := 0;
  // The running status is kept if the event before has this very status
  LEvent.RunningStatus := (AIndex > 0) and
    (LEvent.Status = ATrack.EventAt(AIndex - 1).Status);
  ATrack.Insert(AIndex, LEvent);
end;

class procedure TXmiXmiToMidiConverter.ConvertNotes(ATrack: TXmiTrack);
var
  LActive: TArray<TActiveNote>;
  LActiveCount: Integer;
  LIndex: Integer;
  LNext: Integer;
  LMinimum: UInt64;
  LFound: Boolean;
  LFirst: Boolean;
  LEventTicks: UInt64;

  procedure RemoveActive(AIndex: Integer);
  var
    LMove: Integer;
  begin
    for LMove := AIndex + 1 to LActiveCount - 1 do
      LActive[LMove - 1] := LActive[LMove];
    Dec(LActiveCount);
  end;

  procedure AddActive(AChannel, ANote: Byte; ATicks: UInt64);
  begin
    if LActiveCount = Length(LActive) then
      SetLength(LActive, LActiveCount + 16);
    LActive[LActiveCount].Channel := AChannel;
    LActive[LActiveCount].Note := ANote;
    LActive[LActiveCount].RemainingTicks := ATicks;
    Inc(LActiveCount);
  end;

begin
  LActive := nil;
  LActiveCount := 0;
  LIndex := 0;
  while LIndex < ATrack.Count do
  begin
    // The notes that end before this event are turned off first, each at
    // its time, then the delay left goes to the event itself
    while ATrack.EventAt(LIndex).Ticks > 0 do
    begin
      LEventTicks := ATrack.EventAt(LIndex).Ticks;
      LFound := False;
      LMinimum := 0;
      for LNext := 0 to LActiveCount - 1 do
      begin
        if not LFound then
        begin
          if LActive[LNext].RemainingTicks <= LEventTicks then
          begin
            LMinimum := LActive[LNext].RemainingTicks;
            LFound := True;
          end;
        end
        else if (LActive[LNext].RemainingTicks <= LEventTicks) and
                (LActive[LNext].RemainingTicks < LMinimum) then
          LMinimum := LActive[LNext].RemainingTicks;
      end;

      if not LFound then
      begin
        // No note ends here: they all get closer to their end
        for LNext := 0 to LActiveCount - 1 do
          LActive[LNext].RemainingTicks :=
            LActive[LNext].RemainingTicks - LEventTicks;
        Break;
      end;

      LNext := 0;
      LFirst := True;
      while LNext < LActiveCount do
      begin
        if LActive[LNext].RemainingTicks = LMinimum then
        begin
          InsertNoteOff(ATrack, LIndex);
          ATrack.EventAt(LIndex).Status :=
            STATUS_NOTE_OFF or (LActive[LNext].Channel and $F);
          ATrack.EventAt(LIndex).Param1 := LActive[LNext].Note;
          if LFirst then
            ATrack.EventAt(LIndex).Ticks := LActive[LNext].RemainingTicks
          else
            ATrack.EventAt(LIndex).Ticks := 0;
          Inc(LIndex);
          LFirst := False;
          RemoveActive(LNext);
          Continue;
        end;

        LActive[LNext].RemainingTicks := LActive[LNext].RemainingTicks - LMinimum;
        Inc(LNext);
      end;
      ATrack.EventAt(LIndex).Ticks := ATrack.EventAt(LIndex).Ticks - LMinimum;
    end;

    case ATrack.EventAt(LIndex).Status shr 4 of
      8:
        begin
          // A Note Off: XMIDI does not have them
          ATrack.Delete(LIndex, True);
          Continue;
        end;
      9:
        if ATrack.EventAt(LIndex).Duration = 0 then
        begin
          // A note without duration: off right away
          InsertNoteOff(ATrack, LIndex + 1);
          ATrack.EventAt(LIndex + 1).Status :=
            STATUS_NOTE_OFF or (ATrack.EventAt(LIndex).Status and $F);
          ATrack.EventAt(LIndex + 1).Param1 := ATrack.EventAt(LIndex).Param1;
          Inc(LIndex);
        end
        else
        begin
          AddActive(ATrack.EventAt(LIndex).Status and $F,
            ATrack.EventAt(LIndex).Param1, ATrack.EventAt(LIndex).Duration);
          ATrack.EventAt(LIndex).Duration := 0;
        end;
    end;

    // The notes still on when the track ends are turned off before the end
    if (LActiveCount > 0) and (LIndex = ATrack.Count - 1) and
       (ATrack.EventAt(LIndex).Status = XMI_STATUS_META) and
       (ATrack.EventAt(LIndex).Param1 = XMI_META_END_OF_TRACK) then
    begin
      ATrack.EventAt(LIndex).Ticks := 0;
      for LNext := 0 to LActiveCount - 1 do
        if ATrack.EventAt(LIndex).Ticks < LActive[LNext].RemainingTicks then
          ATrack.EventAt(LIndex).Ticks := LActive[LNext].RemainingTicks;
      Continue;
    end;

    Inc(LIndex);
  end;
end;

class procedure TXmiXmiToMidiConverter.ScaleDelays(ATrack: TXmiTrack;
  AInitialTempo: Cardinal; var ATempo: Cardinal);
var
  LIndex: Integer;
begin
  // The delays are measured with the tempo the song had in the beginning;
  // after a tempo event they have to count for what the new tempo says
  for LIndex := 0 to ATrack.Count - 1 do
  begin
    if ATrack.EventAt(LIndex).Ticks > 0 then
      ATrack.EventAt(LIndex).Ticks :=
        Round(ATrack.EventAt(LIndex).Ticks * AInitialTempo / ATempo);
    if (ATrack.EventAt(LIndex).Status = XMI_STATUS_META) and
       (ATrack.EventAt(LIndex).Param1 = XMI_META_TEMPO) then
      ATempo := Cardinal(ATrack.EventAt(LIndex).Value);
  end;
end;

class procedure TXmiXmiToMidiConverter.Convert(ASong: TXmiSong);
var
  LTrackIndex: Integer;
  LInitialTempo: Cardinal;
  LTempo: Cardinal;
begin
  LInitialTempo := ASong.InitialTempo;
  LTempo := LInitialTempo;
  for LTrackIndex := 0 to ASong.Tracks.Count - 1 do
  begin
    ConvertNotes(ASong.Tracks[LTrackIndex]);
    ScaleDelays(ASong.Tracks[LTrackIndex], LInitialTempo, LTempo);
  end;
end;

end.
