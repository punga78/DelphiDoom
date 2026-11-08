{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - the volume of the songs                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.Volume;

{$Q-}
{$R-}
// The events are words of the stream and the masks are the ones of the old code

interface

uses
  DelphiDoom.Midi.Types;

type
  /// <summary>
  ///   The volume controller of the channels: the table of the sound menu (0..15), the change of
  ///   controller that sets a volume, and the volume of a song that is already in events
  /// </summary>
  TMidiVolume = class
  public
    /// <summary>
    ///   The volume of the menu (0..15, a value outside is the nearest one) as a percent
    ///   (0..100): the old midivolumecontrol
    /// </summary>
    class function PercentOfLevel(ALevel: Integer): Integer; static;
    /// <summary>A percent (0..100) as a value of the volume controller (0..127)</summary>
    class function ControllerValueOfPercent(APercent: Integer): Integer; static;
    /// <summary>
    ///   The message that sets the volume controller of a channel to AValue: what
    ///   midiOutShortMsg takes
    /// </summary>
    class function ControlChangeMessage(AChannel: Cardinal; AValue: Cardinal): Cardinal; static;
    /// <summary>
    ///   Gives the volume AValue to every change of the volume controller among AEvents: the
    ///   event is the one of AOriginals (the song as it was converted) with its third byte
    ///   replaced. AEvents and AOriginals have ACount events each
    /// </summary>
    class procedure ApplyToEvents(AEvents, AOriginals: PMidiStreamEvent; ACount: Integer;
      AValue: Cardinal); static;
  end;

implementation

const
  // the volume of the menu, in percent
  LEVEL_PERCENTS: array[0..15] of Integer = (
    0, 7, 13, 20, 27, 33, 40, 47, 53, 60, 67, 73, 80, 87, 93, 100
  );
  MAXIMUM_LEVEL = 15;
  EVENT_TYPE_MASK = $000000F0;
  EVENT_DATA1_MASK = $0000FF00;
  EVENT_DATA1_SHIFT = 8;
  // the old code cleared the low seven bits of the third byte only
  EVENT_KEEP_MASK = $FF80FFFF;
  EVENT_DATA2_SHIFT = 16;

{ TMidiVolume }

class function TMidiVolume.PercentOfLevel(ALevel: Integer): Integer;
begin
  if ALevel < 0 then
    ALevel := 0
  else if ALevel > MAXIMUM_LEVEL then
    ALevel := MAXIMUM_LEVEL;
  Result := LEVEL_PERCENTS[ALevel];
end;

class function TMidiVolume.ControllerValueOfPercent(APercent: Integer): Integer;
begin
  Result := APercent * MIDI_CONTROLLER_MAXIMUM div MIDI_VOLUME_FULL;
end;

class function TMidiVolume.ControlChangeMessage(AChannel: Cardinal; AValue: Cardinal): Cardinal;
begin
  Result := Cardinal(MIDI_CONTROL_CHANGE) or AChannel or
    (Cardinal(MIDI_CONTROLLER_VOLUME) shl EVENT_DATA1_SHIFT) or (AValue shl EVENT_DATA2_SHIFT);
end;

class procedure TMidiVolume.ApplyToEvents(AEvents, AOriginals: PMidiStreamEvent; ACount: Integer;
  AValue: Cardinal);
var
  LIndex: Integer;
  LEvent: PMidiStreamEvent;
  LOriginal: PMidiStreamEvent;
begin
  LEvent := AEvents;
  LOriginal := AOriginals;
  for LIndex := 0 to ACount - 1 do
  begin
    if (LEvent^.Event and EVENT_TYPE_MASK) = MIDI_CONTROL_CHANGE then
      if ((LEvent^.Event and EVENT_DATA1_MASK) shr EVENT_DATA1_SHIFT) = MIDI_CONTROLLER_VOLUME then
        LEvent^.Event := (LOriginal^.Event and EVENT_KEEP_MASK) or
          (AValue shl EVENT_DATA2_SHIFT);
    Inc(LEvent);
    Inc(LOriginal);
  end;
end;

end.
