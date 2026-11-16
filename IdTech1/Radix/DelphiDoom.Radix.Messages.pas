{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixMessages                                  }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{  Copyright (C) 1995 by Epic MegaGames, Inc. (Radix - beyond the void)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_messages.pas of Rad-X and of the numbers of the sounds of     }
{  radix_sounds.pas that the actions of the levels use                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Messages;

interface

type
  /// <summary>A message that an action of a level shows to the pilot</summary>
  TRadixMessage = record
    Text: string;
    /// <summary>The number of the sound of RADIX.DAT that is played with it; -1 for none</summary>
    Sound: Integer;
    /// <summary>True for a message that an action shows only once</summary>
    AutoDisable: Boolean;
  end;

  /// <summary>The thirteen messages of the levels of Radix and the message of the start of a level</summary>
  TRadixMessages = class
  public
    const
      COUNT = 13;
      SECONDARY_OBJECTIVE_COMPLETED = 12;
      NO_SOUND = -1;
      // the numbers of the sounds of RADIX.DAT (radixsound_t), in the order of TRadixSoundPart.SoundNames
      SOUND_GRAVITY_WELL = 9;
      SOUND_END_OF_LEVEL = 16;
      SOUND_PRIMARY_AHEAD = 37;
      SOUND_PRIMARY_COMPLETE = 38;
      SOUND_PRIMARY_INCOMPLETE = 39;
      SOUND_TARGETS_AHEAD = 40;
      SOUND_ENEMY = 41;
      SOUND_SECONDARY_AHEAD = 42;
      SOUND_SECONDARY_COMPLETE = 43;
      SOUND_COUNT = 45;
      /// <summary>The prefix of the names that SNDINFO gives to the sounds of RADIX.DAT</summary>
      SOUND_PREFIX = 'radix/';
  public
    class function IsMessage(AMessage: Integer): Boolean; static;
    /// <summary>The message with that number; an empty one without sound for a number that is not a message</summary>
    class function Get(AMessage: Integer): TRadixMessage; static;
    /// <summary>What the pilot reads when a level starts: the first levels of an episode also name the help</summary>
    class function StartUp(AEpisode, AMap: Integer): string; static;
  end;

implementation

const
  SStartUpWithHelp = 'PRESS F1 FOR HELP. F12 FOR MISSION OBJECTIVES';
  SStartUp = 'PRESS F12 FOR MISSION OBJECTIVES';

  MESSAGES: array[0..TRadixMessages.COUNT - 1] of TRadixMessage = (
    (Text: 'Primary target ahead'; Sound: TRadixMessages.SOUND_PRIMARY_AHEAD; AutoDisable: False),
    (Text: 'Secondary target ahead'; Sound: TRadixMessages.SOUND_SECONDARY_AHEAD; AutoDisable: False),
    (Text: 'Shoot doors to gain entry'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Multiple targets ahead'; Sound: TRadixMessages.SOUND_TARGETS_AHEAD; AutoDisable: False),
    (Text: 'Kill enemies to continue'; Sound: TRadixMessages.SOUND_ENEMY; AutoDisable: False),
    (Text: 'Powerful Enemy approaching'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Exit above current position'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Exit below current position'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Watch For Seeking Missiles'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Primary Objective Completed'; Sound: TRadixMessages.SOUND_PRIMARY_COMPLETE; AutoDisable: True),
    (Text: 'Primary Objective Incomplete'; Sound: TRadixMessages.SOUND_PRIMARY_INCOMPLETE; AutoDisable: False),
    (Text: 'Kill all Skyfires to continue'; Sound: TRadixMessages.NO_SOUND; AutoDisable: False),
    (Text: 'Secondary Objective Completed'; Sound: TRadixMessages.SOUND_SECONDARY_COMPLETE; AutoDisable: True));

{ TRadixMessages }

class function TRadixMessages.IsMessage(AMessage: Integer): Boolean;
begin
  Result := (AMessage >= 0) and (AMessage < COUNT);
end;

class function TRadixMessages.Get(AMessage: Integer): TRadixMessage;
begin
  if IsMessage(AMessage) then
    Result := MESSAGES[AMessage]
  else
  begin
    Result.Text := '';
    Result.Sound := NO_SOUND;
    Result.AutoDisable := False;
  end;
end;

class function TRadixMessages.StartUp(AEpisode, AMap: Integer): string;
var
  LWithHelp: Boolean;
begin
  case AEpisode of
    1: LWithHelp := AMap < 5;
    2: LWithHelp := AMap < 4;
    3: LWithHelp := AMap = 1;
  else
    LWithHelp := False;
  end;
  if LWithHelp then
    Result := SStartUpWithHelp
  else
    Result := SStartUp;
end;

end.
