{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - the profile that a game borrows             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.Aliases;

interface

type
  /// <summary>
  ///   The libraries of the engine that choose a profile by the name of the game. A game that is
  ///   built on the rules of Doom borrows the profile of Doom in the areas where the rules
  ///   coincide; the other areas keep the name of the game and give an error until the game has a
  ///   profile of its own
  /// </summary>
  TGameProfileArea = (
    Dehacked,
    Udmf,
    Lights,
    Platforms,
    Doors,
    ActorDef,
    TableExport,
    Iwad,
    Script
  );

  /// <summary>
  ///   Which profile a game uses in each area (the way to add a game that is a fork of Doom without
  ///   a new {$IFDEF} in every library: the composition root asks here, once per profile). The four
  ///   games of the engine and the unknown names are their own profile
  /// </summary>
  TGameAliases = class
  public
    /// <summary>The name to give to TryFromName of the library of AArea</summary>
    class function ProfileOf(const AGame: string; AArea: TGameProfileArea): string; static;
    /// <summary>True (Speed, Radix) when the game borrows the profile of another game in at least one area</summary>
    class function IsAlias(const AGame: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

const
  DOOM_NAME = 'Doom';
  SPEED_NAME = 'Speed';
  RADIX_NAME = 'Radix';

{ TGameAliases }

class function TGameAliases.ProfileOf(const AGame: string; AArea: TGameProfileArea): string;
begin
  Result := AGame;
  if SameText(AGame, SPEED_NAME) then
    // Speed (a racing game on the engine of Doom) has the rules of floors, ceilings, platforms,
    // doors and lights of Doom, and the map formats; its tables of things, states and weapons and its
    // data files are its own: until it has them the tables of Doom stand in (a provisional alias,
    // see README.md) and the IWAD is not borrowed
    if AArea <> TGameProfileArea.Iwad then
      Result := DOOM_NAME;
  if SameText(AGame, RADIX_NAME) then
    // Radix (a space shooter on the engine of Doom) moves floors, ceilings, platforms, doors and
    // lights as Doom does (the analysis of the fork, docs\INTEGRAZIONE_GIOCHI.md) and has the map
    // formats of Doom; its tables of things, states and weapons (radix info.pas, radix_actions) are
    // its own: until it has them the tables of Doom stand in for Dehacked, ACTORDEF and the table
    // exports (a provisional alias, like Speed). The IWAD is not borrowed: its data are RADIX.DAT
    if AArea <> TGameProfileArea.Iwad then
      Result := DOOM_NAME;
end;

class function TGameAliases.IsAlias(const AGame: string): Boolean;
begin
  Result := SameText(AGame, SPEED_NAME) or SameText(AGame, RADIX_NAME);
end;

end.
