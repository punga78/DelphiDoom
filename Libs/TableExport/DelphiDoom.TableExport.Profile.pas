{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - what changes from a game to another       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Profile;

interface

uses
  DelphiDoom.TableExport.Types;

type
  /// <summary>The games that have tables to export</summary>
  TExportGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>How a line of a patch is written</summary>
  TExportLineKind = (
    /// <summary>"Label = number"</summary>
    lkNumber,
    /// <summary>"Label = FLAG, FLAG" or "Label = 0"</summary>
    lkFlags,
    /// <summary>"Label = text", Index is a TExportThingText</summary>
    lkName,
    /// <summary>"Label = "text"", Index is a TExportThingText</summary>
    lkQuoted,
    lkRenderStyle,
    lkGender,
    /// <summary>The name of a group of MBF21 (see Group)</summary>
    lkGroup,
    /// <summary>The token of the ammo (or of the mana) of a weapon</summary>
    lkAmmo,
    /// <summary>The level of a weapon (Heretic)</summary>
    lkLevel,
    /// <summary>The name of the action of a state and its arguments; no line if the state has none</summary>
    lkAction,
    /// <summary>A comment line that is written once, before the line that follows (Token is the text)</summary>
    lkComment);

  /// <summary>One line of a section of a patch</summary>
  TExportLine = record
    /// <summary>The token of the field in upper case (the label is made from it), or the text of a comment</summary>
    Token: string;
    Kind: TExportLineKind;
    /// <summary>The number of the field in the thing, state or weapon; the position for ammo and misc</summary>
    Index: Integer;
    FlagSet: TExportFlagSet;
    Group: TExportGroup;
  end;

  /// <summary>How the value of a field is written as Pascal</summary>
  TExportPascalKind = (
    pkInteger, pkFixed, pkState, pkSound, pkFlags, pkText, pkGender, pkRenderStyle, pkGroup,
    pkPushFactor, pkFriction, pkSprite, pkAction, pkNextState);

  /// <summary>One assignment of the Pascal export</summary>
  TExportPascalLine = record
    /// <summary>The name of the field, as it is written in the code</summary>
    Name: string;
    Kind: TExportPascalKind;
    Index: Integer;
    FlagSet: TExportFlagSet;
    Group: TExportGroup;
  end;

  /// <summary>
  ///   What each game has in its patches and in its Pascal tables: the values that the old
  ///   code had in its {$IFDEF DOOM}, {$IFDEF HERETIC}, {$IFDEF HEXEN} and {$IFDEF STRIFE}. The
  ///   profile is data: the writers have no conditions on the game
  /// </summary>
  TExportProfile = record
    Game: TExportGame;
    /// <summary>Doom, Heretic, Hexen or Strife: the comments say "DelphiDoom specific"...</summary>
    GameName: string;
    ThingLines: TArray<TExportLine>;
    StateLines: TArray<TExportLine>;
    WeaponLines: TArray<TExportLine>;
    AmmoLines: TArray<TExportLine>;
    MiscLines: TArray<TExportLine>;
    /// <summary>The header of a weapon has the class of the player (Hexen)</summary>
    WeaponHeaderHasClass: Boolean;
    /// <summary>How many episodes have par times (0 if the game has none)</summary>
    ParEpisodes: Integer;
    ParMaps: Integer;
    ParEpisodeHeader: string;
    /// <summary>The maps of Doom 2 that have a par time (0 if the game has none)</summary>
    ParCommercialMaps: Integer;
    PascalThingLines: TArray<TExportPascalLine>;
    PascalStateLines: TArray<TExportPascalLine>;
  end;

implementation

end.
