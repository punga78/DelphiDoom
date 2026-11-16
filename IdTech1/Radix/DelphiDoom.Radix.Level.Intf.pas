{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the contracts of the levels                     }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.DoomMap;

type
  /// <summary>Reads the bytes of a level of Radix</summary>
  IRadixLevelReader = interface
    ['{7B2E4C90-1A53-4D86-9E07-3C58F1A2B4D6}']
    /// <summary>The level, or nil when the bytes are not a level (no magic number); the caller frees it</summary>
    function TryRead(const AName: string; const ABytes: TBytes): TRadixLevelData;
  end;

  /// <summary>
  ///   The corrections that one version of the game needs: the first on the level of Radix, before the
  ///   Doom map is built, the second on the Doom map (it finds the map and the level it comes from)
  /// </summary>
  IRadixLevelFix = interface
    ['{C41D8A63-5E2F-4B97-A130-8D6E92F07B15}']
    procedure FixRadix(const ALevel: TRadixLevelData);
    procedure FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
  end;

  /// <summary>Chooses the corrections of a level by its name and its checksum</summary>
  IRadixLevelFixSelector = interface
    ['{3F9A7D15-6C80-42B4-8E51-A07B3D29C6E8}']
    /// <summary>Never nil: a level that is not of a known version gets corrections that do nothing</summary>
    function Select(const AName: string; ACrc: Cardinal): IRadixLevelFix;
  end;

implementation

end.
