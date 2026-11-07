{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the terrain lists of the four games       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.TerrainTables;

interface

uses
  DelphiDoom.Definitions.Types;

type
  /// <summary>The lists that were compiled in p_terrain.pas of each game (without the END entry)</summary>
  TTerrainTables = class
  public
    class function ForGame(AGame: TDefGame): TArray<TDefTerrainEntry>; static;
    /// <summary>
    ///   The terrain of a flat of the game (the case does not matter), Solid if the flat is
    ///   not in the list: the same answer of TTerrainTable over ForGame, without making the
    ///   table (the engine calls it for every flat it loads)
    /// </summary>
    class function KindForName(AGame: TDefGame; const AFlatName: string): TDefTerrainKind; static;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

const
  DOOM_TERRAINS: array[0..22] of TDefTerrainEntry = (
    (Name: 'FWATER1'; Kind: TDefTerrainKind.Water),
    (Name: 'FWATER2'; Kind: TDefTerrainKind.Water),
    (Name: 'FWATER3'; Kind: TDefTerrainKind.Water),
    (Name: 'FWATER4'; Kind: TDefTerrainKind.Water),
    (Name: 'LAVA1'; Kind: TDefTerrainKind.Lava),
    (Name: 'LAVA2'; Kind: TDefTerrainKind.Lava),
    (Name: 'LAVA3'; Kind: TDefTerrainKind.Lava),
    (Name: 'LAVA4'; Kind: TDefTerrainKind.Lava),
    (Name: 'SLIME01'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME02'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME03'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME04'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME05'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME06'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME07'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME08'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME09'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME10'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME11'; Kind: TDefTerrainKind.Sludge),
    (Name: 'SLIME12'; Kind: TDefTerrainKind.Sludge),
    (Name: 'NUKAGE1'; Kind: TDefTerrainKind.Nukage),
    (Name: 'NUKAGE2'; Kind: TDefTerrainKind.Nukage),
    (Name: 'NUKAGE3'; Kind: TDefTerrainKind.Nukage)
  );

  HERETIC_TERRAINS: array[0..4] of TDefTerrainEntry = (
    (Name: 'FLTWAWA1'; Kind: TDefTerrainKind.Water),
    (Name: 'FLTFLWW1'; Kind: TDefTerrainKind.Water),
    (Name: 'FLTLAVA1'; Kind: TDefTerrainKind.Lava),
    (Name: 'FLATHUH1'; Kind: TDefTerrainKind.Lava),
    (Name: 'FLTSLUD1'; Kind: TDefTerrainKind.Sludge)
  );

  HEXEN_TERRAINS: array[0..3] of TDefTerrainEntry = (
    (Name: 'X_005'; Kind: TDefTerrainKind.Water),
    (Name: 'X_001'; Kind: TDefTerrainKind.Lava),
    (Name: 'X_009'; Kind: TDefTerrainKind.Sludge),
    (Name: 'F_033'; Kind: TDefTerrainKind.Ice)
  );

  STRIFE_TERRAINS: array[0..11] of TDefTerrainEntry = (
    (Name: 'F_WATR03'; Kind: TDefTerrainKind.Water),
    (Name: 'F_WATR02'; Kind: TDefTerrainKind.Water),
    (Name: 'F_WATR01'; Kind: TDefTerrainKind.Water),
    (Name: 'F_VWATR3'; Kind: TDefTerrainKind.Water),
    (Name: 'F_VWATR2'; Kind: TDefTerrainKind.Water),
    (Name: 'P_VWATR1'; Kind: TDefTerrainKind.Water),
    (Name: 'F_HWATR3'; Kind: TDefTerrainKind.Water),
    (Name: 'F_HWATR2'; Kind: TDefTerrainKind.Water),
    (Name: 'F_HWATR1'; Kind: TDefTerrainKind.Water),
    (Name: 'F_PWATR3'; Kind: TDefTerrainKind.Sludge),
    (Name: 'F_PWATR2'; Kind: TDefTerrainKind.Sludge),
    (Name: 'F_PWATR1'; Kind: TDefTerrainKind.Sludge)
  );

function CopyEntries(const AEntries: array of TDefTerrainEntry): TArray<TDefTerrainEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AEntries));
  for LIndex := 0 to High(AEntries) do
    Result[LIndex] := AEntries[LIndex];
end;

{ TTerrainTables }

class function TTerrainTables.ForGame(AGame: TDefGame): TArray<TDefTerrainEntry>;
begin
  case AGame of
    TDefGame.Doom: Result := CopyEntries(DOOM_TERRAINS);
    TDefGame.Heretic: Result := CopyEntries(HERETIC_TERRAINS);
    TDefGame.Hexen: Result := CopyEntries(HEXEN_TERRAINS);
  else
    Result := CopyEntries(STRIFE_TERRAINS);
  end;
end;

function FindKind(const AEntries: array of TDefTerrainEntry;
  const AUpperName: string): TDefTerrainKind;
var
  LIndex: Integer;
begin
  // the first one that matches wins, as in TTerrainTable
  for LIndex := 0 to High(AEntries) do
    if AEntries[LIndex].Name = AUpperName then
      Exit(AEntries[LIndex].Kind);
  Result := TDefTerrainKind.Solid;
end;

class function TTerrainTables.KindForName(AGame: TDefGame;
  const AFlatName: string): TDefTerrainKind;
var
  LUpper: string;
begin
  LUpper := TScannerStrings.UpperAscii(AFlatName);
  case AGame of
    TDefGame.Doom: Result := FindKind(DOOM_TERRAINS, LUpper);
    TDefGame.Heretic: Result := FindKind(HERETIC_TERRAINS, LUpper);
    TDefGame.Hexen: Result := FindKind(HEXEN_TERRAINS, LUpper);
  else
    Result := FindKind(STRIFE_TERRAINS, LUpper);
  end;
end;

end.
