{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the "States" panel                                }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.StateCatalog;

interface

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.StateTables;

type
  /// <summary>
  ///   The states of a game: a tree with one line for each state (and under it its fields), and
  ///   the list of the fields of the state that is selected or that the selected field points to
  /// </summary>
  TIdeStateCatalog = class
  strict private
    FTables: TIdeStateTables;
  public
    constructor Create;
    destructor Destroy; override;
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
    /// <summary>The states whose name has the filter inside (without regard to the case)</summary>
    function BuildOutline(const AFilter: string): TIdeOutline;
    /// <summary>
    ///   The fields for the line that is selected in the tree: a state, or the field "Next Frame"
    ///   (which shows the state it points to). Any other line gives no row
    /// </summary>
    function RowsFor(const ASelectedText: string): TArray<TIdeRow>;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Text,
  DelphiDoom.Ide.FieldFormatter;

{ TIdeStateCatalog }

constructor TIdeStateCatalog.Create;
begin
  inherited Create;
  FTables := TIdeStateTables.Create;
end;

destructor TIdeStateCatalog.Destroy;
begin
  FTables.Free;
  inherited Destroy;
end;

function TIdeStateCatalog.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
begin
  Result := FTables.Load(ALibrary, AGame);
end;

function TIdeStateCatalog.BuildOutline(const AFilter: string): TIdeOutline;
var
  LFilter, LName, LValue: string;
  LIndex, LField: Integer;
  LNode: TIdeOutlineNode;
  LFields: TStrings;
begin
  Result := TIdeOutline.Create;
  LFilter := LowerCase(Trim(AFilter));
  for LIndex := 0 to FTables.StateCount - 1 do
  begin
    if (LFilter <> '') and (Pos(LFilter, LowerCase(FTables.StateKey(LIndex))) = 0) then
      Continue;
    LNode := Result.AddRoot(FTables.StateKey(LIndex));
    LFields := FTables.FieldsOf(LIndex);
    for LField := 0 to LFields.Count - 1 do
    begin
      TIdeText.SplitPair(LFields[LField], ':', LName, LValue);
      LNode.AddChild(LName + ': ' + TIdeFieldFormatter.ForTree(LName, LValue,
        FTables.SpriteNames, FTables.StateNames));
    end;
  end;
end;

function TIdeStateCatalog.RowsFor(const ASelectedText: string): TArray<TIdeRow>;
var
  LName, LValue: string;
  LNumber, LField: Integer;
  LFields: TStrings;
  LFieldName, LFieldValue: string;
begin
  Result := nil;
  TIdeText.SplitPair(ASelectedText, ':', LName, LValue);
  if not ((LName = 'Next Frame') or ((LValue = '') and (FTables.StateNames.IndexOf(LName) >= 0))) then
    Exit;
  LNumber := StrToIntDef(LValue, -1);
  if (LNumber < 0) or (LNumber > FTables.StateCount) then
  begin
    if LValue = '' then
      LNumber := FTables.StateNames.IndexOf(LName)
    else
      LNumber := FTables.StateNames.IndexOf(LValue);
  end;
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
