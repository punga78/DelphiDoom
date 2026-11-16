{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - merges the tracks of a type 1 MIDI file           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.TrackMerger;

interface

uses
  DelphiDoom.M2m.MidiFile;

type
  /// <summary>
  ///   Combines the tracks of a type 1 file, which play alongside, into the
  ///   single track of a type 0 file
  /// </summary>
  TMidiTrackMerger = class
  public
    /// <summary>
    ///   Takes the events in the order of their time. The end of track events
    ///   of all the tracks but the last are dropped, so that the result has
    ///   only one, at its end
    /// </summary>
    /// <returns>A new file; the caller frees it</returns>
    /// <exception cref="EM2mException">AMidi is not a type 1 file</exception>
    class function Merge(const AMidi: TMidiFile): TMidiFile; overload; static;
    /// <summary>
    ///   As Merge, but with AKeepEndOfTrackDelta the time of an end of track event that is
    ///   dropped is added to the delta of the next event kept, so that the absolute time of
    ///   every event is the one of the file. Without it (the plain overload, as the old
    ///   libm2m did) that time is lost
    /// </summary>
    class function Merge(const AMidi: TMidiFile;
      AKeepEndOfTrackDelta: Boolean): TMidiFile; overload; static;
  end;

implementation

uses
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.Types;

const
  EVENTS_GROWTH = 100;
  NO_EVENT_SOON = $7FFFFFFF;
  UNSIGNED_MASK = $FFFFFFFF;

{ TMidiTrackMerger }

class function TMidiTrackMerger.Merge(const AMidi: TMidiFile): TMidiFile;
begin
  Result := Merge(AMidi, False);
end;

class function TMidiTrackMerger.Merge(const AMidi: TMidiFile;
  AKeepEndOfTrackDelta: Boolean): TMidiFile;
var
  LPosition: TArray<Integer>;
  LElapsed: TArray<Int64>;
  LEnded: TArray<Boolean>;
  LEvents: TArray<TMidiEvent>;
  LCount, LTrack, LNextTrack, LIndex: Integer;
  LNext, LRemaining, LCarry: Int64;
  LEvent: TMidiEvent;
  LAllEnded: Boolean;
begin
  if not Assigned(AMidi) or (AMidi.Mode <> 1) then
    raise EM2mException.CreateCode(M2M_ERROR_MIDI);

  Result := TMidiFile.Create;
  Result.Mode := 0;
  Result.SmpteFps := AMidi.SmpteFps;
  Result.Timing := AMidi.Timing;

  SetLength(LPosition, Length(AMidi.Tracks));
  SetLength(LElapsed, Length(AMidi.Tracks));
  SetLength(LEnded, Length(AMidi.Tracks));
  LCount := 0;
  LCarry := 0;

  while True do
  begin
    // The track whose next event comes first: the delta of an event is counted
    // from the previous event of its own track, LElapsed says how much has gone by
    LNext := NO_EVENT_SOON;
    LNextTrack := -1;
    for LTrack := 0 to High(AMidi.Tracks) do
    begin
      if LPosition[LTrack] < Length(AMidi.Tracks[LTrack].Events) then
      begin
        LRemaining := (Int64(AMidi.Tracks[LTrack].Events[LPosition[LTrack]].Delta) - LElapsed[LTrack]) and
          UNSIGNED_MASK;
        if LRemaining < LNext then
        begin
          LNext := LRemaining;
          LNextTrack := LTrack;
        end;
      end;
    end;
    if LNextTrack = -1 then
      Break;

    LEvent := AMidi.Tracks[LNextTrack].Events[LPosition[LNextTrack]];
    if (LEvent.EventType = metMeta) and (LEvent.Param1 = META_ENDTRACK) then
    begin
      // The tracks need not be as long as each other, and the result has one end of
      // track event, at its end: the others are eaten, unless every track has ended
      LEnded[LNextTrack] := True;
      LAllEnded := True;
      for LIndex := 0 to High(LEnded) do
      begin
        if not LEnded[LIndex] then
          LAllEnded := False;
      end;
      if not LAllEnded then
      begin
        for LIndex := 0 to High(LElapsed) do
          Inc(LElapsed[LIndex], LNext);
        if AKeepEndOfTrackDelta then
          Inc(LCarry, LNext);
        Inc(LPosition[LNextTrack]);
        Continue;
      end;
    end;

    for LIndex := 0 to High(LElapsed) do
    begin
      if LIndex <> LNextTrack then
        Inc(LElapsed[LIndex], LNext)
      else
        LElapsed[LIndex] := 0;
    end;

    if LCount = Length(LEvents) then
      SetLength(LEvents, LCount + EVENTS_GROWTH);
    LEvents[LCount] := LEvent;
    LEvents[LCount].Delta := Cardinal(LNext + LCarry);
    LCarry := 0;
    Inc(LCount);
    Inc(LPosition[LNextTrack]);
  end;

  SetLength(LEvents, LCount);
  SetLength(Result.Tracks, 1);
  Result.Tracks[0].Events := LEvents;
end;

end.
