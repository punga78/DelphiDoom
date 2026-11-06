{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the terrain of the flats                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.TerrainTable;

interface

uses
  System.SysUtils, DelphiDoom.Definitions.Types, DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   P_TerrainTypeForName: the name of a flat in capitals is looked up in a list of the
  ///   game, the first one that matches wins. (There is no TERRAIN lump in the engine: the
  ///   list is compiled in)
  /// </summary>
  TTerrainTable = class(TInterfacedObject, IDefTerrainTable)
  private
    FEntries: TArray<TDefTerrainEntry>;
  public
    constructor Create(const AEntries: TArray<TDefTerrainEntry>);
    function KindForName(const AFlatName: string): TDefTerrainKind;
    function Count: Integer;
    function Entry(AIndex: Integer): TDefTerrainEntry;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TTerrainTable }

constructor TTerrainTable.Create(const AEntries: TArray<TDefTerrainEntry>);
begin
  inherited Create;
  FEntries := Copy(AEntries);
end;

function TTerrainTable.KindForName(const AFlatName: string): TDefTerrainKind;
var
  LUpper: string;
  LIndex: Integer;
begin
  LUpper := TScannerStrings.UpperAscii(AFlatName);
  for LIndex := 0 to High(FEntries) do
    if FEntries[LIndex].Name = LUpper then
      Exit(FEntries[LIndex].Kind);
  Result := TDefTerrainKind.Solid;
end;

function TTerrainTable.Count: Integer;
begin
  Result := Length(FEntries);
end;

function TTerrainTable.Entry(AIndex: Integer): TDefTerrainEntry;
begin
  Result := FEntries[AIndex];
end;

end.
