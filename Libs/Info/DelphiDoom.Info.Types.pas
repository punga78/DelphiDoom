{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the shared types                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when a table of the library is used wrongly (a negative size, a missing source)</summary>
  EInfoException = class(Exception);

  /// <summary>
  ///   What the library needs to know about a thing (mobjinfo_t) of the game: the name, the
  ///   editor number, the kind of the thing and its states. A state is 0 (S_NULL) when the thing
  ///   does not have it
  /// </summary>
  TInfoMobj = record
    Name: string;
    DoomedNum: Integer;
    InheritsFrom: Integer;
    SpawnHealth: Integer;
    Flags: Integer;
    SpawnState: Integer;
    SeeState: Integer;
    PainState: Integer;
    MeleeState: Integer;
    MissileState: Integer;
    DeathState: Integer;
    XDeathState: Integer;
    RaiseState: Integer;
    HealState: Integer;
    CrashState: Integer;
    CrushState: Integer;
    InteractState: Integer;
  end;

  /// <summary>What the library needs to know about a state (state_t) of the game</summary>
  TInfoState = record
    /// <summary>The index of the sprite name</summary>
    Sprite: Integer;
    /// <summary>The frame, without the flags (the old frame and FF_FRAMEMASK)</summary>
    Frame: Integer;
    /// <summary>The state that follows (S_NULL ends the chain)</summary>
    NextState: Integer;
    Tics: Integer;
  end;

  /// <summary>A name of a group (infighting, projectile, splash) that has a fixed value</summary>
  TInfoGroupName = record
    Name: string;
    Value: Integer;
  end;

implementation

end.
