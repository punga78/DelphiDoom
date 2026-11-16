{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the contracts                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Intf;

interface

uses
  DelphiDoom.TableExport.Types;

type
  /// <summary>The things (mobjinfo) of the game</summary>
  IExportThingSource = interface
    ['{5B1D7E32-9A04-4C68-B2F1-83E60D4A79C5}']
    function Count: Integer;
    function Get(AIndex: Integer): TExportThing;
  end;

  /// <summary>The states of the game, their names and their owners</summary>
  IExportStateSource = interface
    ['{C9406A1F-3E7D-48B2-A5D0-12F8B7E63C94}']
    function Count: Integer;
    function Get(AIndex: Integer): TExportState;
    /// <summary>How many states have a name of the engine (the states after them have none)</summary>
    function NameCount: Integer;
    function StateName(AIndex: Integer): string;
    /// <summary>The numbers of the things that own the state; empty if nobody does</summary>
    function Owners(AIndex: Integer): TArray<Integer>;
    function SpriteCount: Integer;
    /// <summary>The four characters of a sprite</summary>
    function SpriteName(AIndex: Integer): string;
  end;

  /// <summary>The weapons of the game in the order that the exports write them</summary>
  IExportWeaponSource = interface
    ['{E27A5C08-6D31-4F94-9B7E-A0C4D81F2563}']
    function Count: Integer;
    function Get(AIndex: Integer): TExportWeapon;
  end;

  /// <summary>What the patch has besides things, states and weapons</summary>
  IExportSettingsSource = interface
    ['{4A8F1B63-D2E5-47C9-8036-B91E7A5D0C42}']
    /// <summary>The version and the build of the program</summary>
    function CreatedWith: string;
    /// <summary>The name of the program and its arguments</summary>
    function CommandLine: string;
    function AmmoCount: Integer;
    /// <summary>AValue 0 is the maximum, 1 is the ammo of a pick up</summary>
    function Ammo(AIndex, AValue: Integer): Integer;
    /// <summary>The value of the line of the section Misc that has that position</summary>
    function Misc(AIndex: Integer): Integer;
    /// <summary>The par time of an episode of the first three games and of Heretic</summary>
    function Par(AEpisode, AMap: Integer): Integer;
    /// <summary>The par time of a map of Doom 2</summary>
    function CommercialPar(AMap: Integer): Integer;
    function StringCount: Integer;
    function StringName(AIndex: Integer): string;
    function StringValue(AIndex: Integer): string;
    /// <summary>The songs are numbered from 1 up to MusicCount - 1</summary>
    function MusicCount: Integer;
    function MusicName(AIndex: Integer): string;
    /// <summary>The map that plays the song; empty if none does</summary>
    function MusicMapName(AIndex: Integer): string;
    /// <summary>The sounds are numbered from 1 up to SoundCount - 1</summary>
    function SoundCount: Integer;
    function SoundName(AIndex: Integer): string;
  end;

  /// <summary>The names of the bits of the lists of flags</summary>
  IExportFlagNames = interface
    ['{7D3B90E4-1C58-4A26-B6F3-5E0A92D4C871}']
    /// <summary>In the order of the bits</summary>
    function Names(ASet: TExportFlagSet): TArray<string>;
  end;

  /// <summary>The names of the values of the enumerations of the engine</summary>
  IExportEnumNames = interface
    ['{A1C6F837-5E92-4D0B-93A4-7B28E01D6F35}']
    /// <summary>How many values of the enumeration have a name that the exports write</summary>
    function Count(AKind: TExportEnum): Integer;
    /// <summary>The name of a value that is below Count, in the case of the declaration of the enumeration</summary>
    function Name(AKind: TExportEnum; AOrdinal: Integer): string;
  end;

  /// <summary>The names that the engine gives to things, sounds and tokens of patches</summary>
  IExportLookups = interface
    ['{2F94D5A8-B03E-4716-8C1D-E6A37B50924F}']
    function ThingName(AIndex: Integer): string;
    function SoundName(ASound: Integer): string;
    /// <summary>The name of a blood colour; empty if it has none</summary>
    function BloodName(AColor: Integer): string;
    function GroupName(AGroup: TExportGroup; AValue: Integer): string;
    function RenderStyleToken(AValue: Integer): string;
    function GenderToken(AValue: Integer): string;
    function AmmoToken(AIndex: Integer): string;
    function WeaponToken(AIndex: Integer): string;
    function PlayerClassToken(AIndex: Integer): string;
  end;

  /// <summary>Writes the tables as a patch (DEHACKED/BEX), one line per item</summary>
  IExportDehWriter = interface
    ['{0E5A2D91-7C48-4B13-A6F0-D8349B1E7C50}']
    function Write: TArray<string>;
  end;

  /// <summary>Writes the tables as the CSV files that a spreadsheet reads</summary>
  IExportCsvWriter = interface
    ['{93B7E04C-A168-4D52-8F2A-1C05D7B6E394}']
    /// <summary>The things, from the lines of a patch (the result of IExportDehWriter)</summary>
    function MobjInfo(const APatch: TArray<string>): TArray<string>;
    /// <summary>The states, from the lines of a patch</summary>
    function States(const APatch: TArray<string>): TArray<string>;
    function Sprites: TArray<string>;
  end;

  /// <summary>Writes the things as ACTOR definitions</summary>
  IExportActorDefWriter = interface
    ['{6D20C8B5-F347-4E91-A0D6-3B8E15F7A942}']
    /// <summary>Everything, one actor after the other</summary>
    function WriteAll: string;
    function Write(AIndex: Integer): string;
  end;

  /// <summary>Writes the weapons as WEAPON definitions</summary>
  IExportWeaponDefWriter = interface
    ['{B4F81E26-2A7D-43C0-9E59-C60D31A8E7F2}']
    function WriteAll: string;
  end;

  /// <summary>Writes what states belong to what things</summary>
  IExportStateOwnersWriter = interface
    ['{19C3A7D0-E654-4B8F-82A1-F5D0937B2E46}']
    function Write: string;
  end;

  /// <summary>Writes the tables as Pascal code</summary>
  IExportPascalWriter = interface
    ['{D8052F4B-6E91-47A3-B1C8-A39E70D5F642}']
    /// <summary>Assignments to mobjinfo[]; AFinish below 0 means the last thing</summary>
    function Things(AStart: Integer = 0; AFinish: Integer = -1): string;
    /// <summary>The things as the constants of a typed array; the built in table is used for the built in range</summary>
    function ThingConstants(AStart: Integer = 0; AFinish: Integer = -1): string;
    /// <summary>Assignments to states[]</summary>
    function States(AStart: Integer = 0; AFinish: Integer = -1): string;
  end;

implementation

end.
