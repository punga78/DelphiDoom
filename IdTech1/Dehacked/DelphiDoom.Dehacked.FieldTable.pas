{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the fields of a block                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FieldTable;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Types;

type
  /// <summary>
  ///   The fields that a block of a game has, in the order of the old tables (the order is the
  ///   index that the engine knows them by). An alias is a field with the index of another one
  /// </summary>
  TDehackedFieldTable = class
  private
    FFields: TArray<TDehackedFieldDef>;
    FIndex: TDictionary<string, Integer>;
  public
    /// <summary>A field with a negative Canonical gets its own index there</summary>
    constructor Create(const AFields: TArray<TDehackedFieldDef>);
    destructor Destroy; override;
    /// <summary>The position of a name (upper case); -1 if the game has no such field</summary>
    function IndexOf(const AName: string): Integer;
    function Count: Integer;
    function Field(AIndex: Integer): TDehackedFieldDef;
  end;

implementation

{ TDehackedFieldTable }

constructor TDehackedFieldTable.Create(const AFields: TArray<TDehackedFieldDef>);
var
  LIndex: Integer;
begin
  inherited Create;
  FFields := Copy(AFields);
  FIndex := TDictionary<string, Integer>.Create;
  for LIndex := 0 to High(FFields) do
  begin
    if FFields[LIndex].Canonical < 0 then
      FFields[LIndex].Canonical := LIndex;
    // as in the old lists, the first of two equal names wins
    if not FIndex.ContainsKey(FFields[LIndex].Name) then
      FIndex.Add(FFields[LIndex].Name, LIndex);
  end;
end;

destructor TDehackedFieldTable.Destroy;
begin
  FIndex.Free;
  inherited Destroy;
end;

function TDehackedFieldTable.IndexOf(const AName: string): Integer;
begin
  if not FIndex.TryGetValue(AName, Result) then
    Result := -1;
end;

function TDehackedFieldTable.Count: Integer;
begin
  Result := Length(FFields);
end;

function TDehackedFieldTable.Field(AIndex: Integer): TDehackedFieldDef;
begin
  Result := FFields[AIndex];
end;

end.
