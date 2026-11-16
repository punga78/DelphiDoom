{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the types of the model                      }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Types;

interface

const
  /// <summary>Tics per second: the par time of UMAPINFO is in seconds, the model keeps tics</summary>
  MAPINFO_TICRATE = 35;
  /// <summary>The longest name of a lump (map, music, pictures, textures)</summary>
  MAPINFO_LUMP_NAME_LENGTH = 8;
  /// <summary>The longest level name and label (they were short strings of 255 characters)</summary>
  MAPINFO_TITLE_LENGTH = 255;

type
  /// <summary>An action to do when the boss of the level dies (UMAPINFO bossaction)</summary>
  TMapInfoBossAction = record
    /// <summary>The number of the thing type, from the actor resolver</summary>
    ActorType: Integer;
    Special: Integer;
    Tag: Integer;
  end;

  /// <summary>
  ///   What UMAPINFO says about a map. An empty text, a zero or a False is "not said": a
  ///   merge of two entries only takes what the newer one says. The engine reads this model;
  ///   nothing here depends on the types of the engine
  /// </summary>
  TMapInfoEntry = record
    MapName: string;
    LevelName: string;
    /// <summary>"-" means that the label is cleared on purpose</summary>
    MapLabel: string;
    InterText: string;
    InterTextSecret: string;
    LevelPic: string;
    NextMap: string;
    NextSecret: string;
    Music: string;
    /// <summary>The number the music resolver gave to Music</summary>
    MusicNumber: Integer;
    SkyTexture: string;
    SkyTexture2: string;
    /// <summary>A picture, or "$CAST", "$BUNNY", "!" (end of the game) or "-" (none)</summary>
    EndPic: string;
    ExitPic: string;
    EnterPic: string;
    InterBackdrop: string;
    InterMusic: string;
    InterMusicNumber: Integer;
    /// <summary>In tics</summary>
    ParTime: Integer;
    NoIntermission: Boolean;
    Lightning: Boolean;
    NoJump: Boolean;
    NoCrouch: Boolean;
    BossActions: TArray<TMapInfoBossAction>;
    /// <summary>"bossaction = clear": the level has no boss actions (the list is empty)</summary>
    BossActionsCleared: Boolean;
    /// <summary>True if the entry says something about the boss actions: a clear or a list</summary>
    function SaysBossActions: Boolean;
  end;

implementation

{ TMapInfoEntry }

function TMapInfoEntry.SaysBossActions: Boolean;
begin
  Result := BossActionsCleared or (Length(BossActions) > 0);
end;

end.
