{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the "Mobjinfo" panel                              }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.MobjinfoCatalog;

interface

uses
  System.Classes,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.StateTables;

type
  /// <summary>
  ///   The actors (mobjinfo) of a game: a tree with one line for each actor and its fields under
  ///   it, in the order the panel always had (inheritance and id first, then the name, the
  ///   frames, the flags, the sounds, the rest), and the list of the fields of the state that
  ///   a "Frame" field points to
  /// </summary>
  TIdeMobjinfoCatalog = class
  strict private
    FActors: TStringList;
    FTables: TIdeStateTables;
    procedure ClearActors;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A game with no actor leaves the catalog as it was and the answer is false</summary>
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
    function BuildOutline(const AFilter: string): TIdeOutline;
    /// <summary>The fields of the state for a "... Frame: state" line of the tree, or nothing</summary>
    function RowsFor(const ASelectedText: string): TArray<TIdeRow>;
    /// <summary>The order of the fields of an actor: a negative number if the left line goes first</summary>
    class function CompareFields(const ALeft, ARight: string): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiDoom.Ide.Csv,
  DelphiDoom.Ide.Text,
  DelphiDoom.Ide.FieldFormatter;

function FieldRank(const ALowerLine: string): Integer;
begin
  if Pos('inheritsfrom', ALowerLine) = 1 then
    Result := 10
  else if Pos('id #:', ALowerLine) = 1 then
    Result := 11
  else if Pos('id:', ALowerLine) = 1 then
    Result := 12
  else if Pos('name', ALowerLine) = 1 then
    Result := 20
  else if Pos('frame', ALowerLine) >= 1 then
    Result := 30
  else if Pos('bits:', ALowerLine) >= 1 then
    Result := 31
  else if Pos('bits2:', ALowerLine) >= 1 then
    Result := 32
  else if Pos('flags_ex:', ALowerLine) >= 1 then
    Result := 33
  else if Pos('flags2_ex:', ALowerLine) >= 1 then
    Result := 34
  else if Pos('flags3_ex:', ALowerLine) >= 1 then
    Result := 35
  else if Pos('flags4_ex:', ALowerLine) >= 1 then
    Result := 36
  else if Pos('flags5_ex:', ALowerLine) >= 1 then
    Result := 37
  else if Pos('flags6_ex:', ALowerLine) >= 1 then
    Result := 38
  else if Pos('sound', ALowerLine) >= 1 then
    Result := 40
  else
    Result := 50;
end;

{ TIdeMobjinfoCatalog }

constructor TIdeMobjinfoCatalog.Create;
begin
  inherited Create;
  FActors := TStringList.Create;
  FTables := TIdeStateTables.Create;
end;

destructor TIdeMobjinfoCatalog.Destroy;
begin
  FTables.Free;
  ClearActors;
  FActors.Free;
  inherited Destroy;
end;

procedure TIdeMobjinfoCatalog.ClearActors;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FActors.Count - 1 do
    FActors.Objects[LIndex].Free;
  FActors.Clear;
end;

class function TIdeMobjinfoCatalog.CompareFields(const ALeft, ARight: string): Integer;
var
  LLeft, LRight: string;
begin
  LLeft := LowerCase(ALeft);
  LRight := LowerCase(ARight);
  Result := FieldRank(LLeft) - FieldRank(LRight);
  if Result = 0 then
  begin
    if LLeft < LRight then
      Result := -1
    else if LLeft > LRight then
      Result := 1;
  end;
end;

function TIdeMobjinfoCatalog.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LLines: TArray<string>;
  LHeader, LCells: TArray<string>;
  LFields: TStringList;
  LIndex, LColumn: Integer;
begin
  Result := False;
  if not ALibrary.TryGetLines(ldMobjinfoCsv, AGame, LLines) then
    Exit;
  if Length(LLines) = 0 then
    Exit;
  Result := True;

  ClearActors;
  LHeader := TIdeCsv.ParseLine(LLines[0]);
  for LIndex := 1 to High(LLines) do
  begin
    LCells := TIdeCsv.ParseLine(LLines[LIndex]);
    if (Length(LCells) = Length(LHeader)) and (Length(LCells) >= 2) then
    begin
      LFields := TStringList.Create;
      for LColumn := 0 to High(LCells) do
        LFields.Add(LHeader[LColumn] + ': ' + TIdeCsv.ExpandFracUnit(LCells[LColumn]));
      FActors.AddObject(LCells[1], LFields);
    end;
  end;
  FTables.Load(ALibrary, AGame);
end;

function TIdeMobjinfoCatalog.BuildOutline(const AFilter: string): TIdeOutline;
var
  LFilter, LName, LValue: string;
  LIndex, LField, LStateNumber: Integer;
  LNode: TIdeOutlineNode;
  LSorted: TList<string>;
  LLine: string;
begin
  Result := TIdeOutline.Create;
  LFilter := LowerCase(Trim(AFilter));
  for LIndex := 0 to FActors.Count - 1 do
  begin
    if (LFilter <> '') and (Pos(LFilter, LowerCase(FActors[LIndex])) = 0) then
      Continue;
    LNode := Result.AddRoot(FActors[LIndex]);
    LSorted := TList<string>.Create;
    try
      for LField := 0 to (FActors.Objects[LIndex] as TStringList).Count - 1 do
        LSorted.Add((FActors.Objects[LIndex] as TStringList)[LField]);
      LSorted.Sort(TComparer<string>.Construct(
        function(const ALeft, ARight: string): Integer
        begin
          Result := CompareFields(ALeft, ARight);
        end));
      for LLine in LSorted do
      begin
        TIdeText.SplitPair(LLine, ':', LName, LValue);
        if Pos(' FRAME:', UpperCase(LName + ':')) > 0 then
        begin
          LStateNumber := StrToIntDef(Trim(LValue), -1);
          if (LStateNumber >= 0) and (LStateNumber < FTables.StateNames.Count - 1) then
            LNode.AddChild(LName + ': ' + FTables.StateNames[LStateNumber])
          else
            LNode.AddChild(LLine);
        end
        else
          LNode.AddChild(LLine);
      end;
    finally
      LSorted.Free;
    end;
  end;
  Result.SortRoots;
end;

function TIdeMobjinfoCatalog.RowsFor(const ASelectedText: string): TArray<TIdeRow>;
var
  LName, LValue, LFieldName, LFieldValue: string;
  LNumber, LField: Integer;
  LFields: TStrings;
begin
  Result := nil;
  TIdeText.SplitPair(ASelectedText, ':', LName, LValue);
  if Pos(' FRAME:', UpperCase(LName + ':')) = 0 then
    Exit;
  LNumber := StrToIntDef(LValue, -1);
  if (LNumber < 0) or (LNumber >= FTables.StateCount) then
    LNumber := FTables.StateNames.IndexOf(LValue);
  LFields := FTables.FieldsOf(LNumber);
  if LFields = nil then
    Exit;
  SetLength(Result, LFields.Count);
  for LField := 0 to LFields.Count - 1 do
  begin
    TIdeText.SplitPair(LFields[LField], ':', LFieldName, LFieldValue);
    Result[LField].Caption := LFieldName;
    Result[LField].Values := TArray<string>.Create(TIdeFieldFormatter.ForList(LFieldName,
      LFieldValue, FTables.SpriteNames, FTables.StateNames));
    Result[LField].Tag := LField;
  end;
end;

end.
