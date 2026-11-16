{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the states of a game as the panels read them      }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.StateTables;

interface

uses
  System.Classes,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   The tables of states, sprite names and state names that the "States", "Mobjinfo" and
  ///   "Sprites" panels all read from the csv of the compiler library. Every state has its
  ///   fields as lines "Field: value" and the key of the state is its name (or "State #name")
  /// </summary>
  TIdeStateTables = class
  strict private
    FStates: TStringList;
    FSpriteNames: TStringList;
    FStateNames: TStringList;
    procedure ClearStates;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Reads the tables of a game. A game the library does not have (or with no state) leaves
    ///   the tables as they were and the answer is false
    /// </summary>
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
    /// <summary>The lines "Field: value" of the state at a place in the table, or nil</summary>
    function FieldsOf(const AIndex: Integer): TStrings;
    function StateKey(const AIndex: Integer): string;
    function StateCount: Integer;
    property SpriteNames: TStringList read FSpriteNames;
    property StateNames: TStringList read FStateNames;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Csv;

{ TIdeStateTables }

constructor TIdeStateTables.Create;
begin
  inherited Create;
  FStates := TStringList.Create;
  FSpriteNames := TStringList.Create;
  FStateNames := TStringList.Create;
end;

destructor TIdeStateTables.Destroy;
begin
  FStateNames.Free;
  FSpriteNames.Free;
  ClearStates;
  FStates.Free;
  inherited Destroy;
end;

procedure TIdeStateTables.ClearStates;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FStates.Count - 1 do
    FStates.Objects[LIndex].Free;
  FStates.Clear;
end;

function TIdeStateTables.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LStates, LSprites: TArray<string>;
  LHeader, LCells, LNames, LSpriteCells: TArray<string>;
  LFields: TStringList;
  LIndex, LColumn: Integer;
begin
  Result := False;
  if not ALibrary.TryGetLines(ldStatesCsv, AGame, LStates) then
    Exit;
  if Length(LStates) = 0 then
    Exit;
  Result := True;

  ClearStates;
  LHeader := TIdeCsv.ParseLine(LStates[0]);
  for LIndex := 1 to High(LStates) do
  begin
    LCells := TIdeCsv.ParseLine(LStates[LIndex]);
    if Length(LCells) = Length(LHeader) then
    begin
      LFields := TStringList.Create;
      for LColumn := 0 to High(LCells) do
        LFields.Add(LHeader[LColumn] + ': ' + LCells[LColumn]);
      FStates.AddObject(LCells[0], LFields);
    end;
  end;

  FSpriteNames.Clear;
  if ALibrary.TryGetLines(ldSpritesCsv, AGame, LSprites) and (Length(LSprites) > 0) then
  begin
    LHeader := TIdeCsv.ParseLine(LSprites[0]);
    for LIndex := 1 to High(LSprites) do
    begin
      LSpriteCells := TIdeCsv.ParseLine(LSprites[LIndex]);
      if (Length(LSpriteCells) = Length(LHeader)) and (Length(LSpriteCells) = 2) then
        FSpriteNames.Add(LSpriteCells[1]);
    end;
  end;

  FStateNames.Clear;
  LNames := TIdeCsv.Column(LStates, 'Name');
  for LIndex := 0 to High(LNames) do
    FStateNames.Add(LNames[LIndex]);
end;

function TIdeStateTables.FieldsOf(const AIndex: Integer): TStrings;
begin
  if (AIndex >= 0) and (AIndex < FStates.Count) then
    Result := FStates.Objects[AIndex] as TStringList
  else
    Result := nil;
end;

function TIdeStateTables.StateKey(const AIndex: Integer): string;
begin
  Result := FStates[AIndex];
end;

function TIdeStateTables.StateCount: Integer;
begin
  Result := FStates.Count;
end;

end.
