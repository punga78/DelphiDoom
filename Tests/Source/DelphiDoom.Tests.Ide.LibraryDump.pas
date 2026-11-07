{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the dump of the library panels       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.LibraryDump;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Outline;

type
  /// <summary>
  ///   Does with the new catalogs what the old golden generator did with the frames of the panels,
  ///   in the same order, and writes the same sections (see Tests\Data\Ide\Library\*.frames.golden.txt):
  ///   the number of lines, the FNV-1a hash of all of them, the first and the last
  /// </summary>
  TLibraryDump = class
  public
    class function Fnv1a(const ARows: TStrings): string; static;
    class procedure AddSection(const ALines: TStrings; const ATitle: string; const ARows: TStrings); static;
    class function RowText(const ARow: TIdeRow): string; static;
    class procedure AddRows(const ALines: TStrings; const ATitle: string; const ARows: TArray<TIdeRow>); static;
    class procedure AddOutline(const ALines: TStrings; const ATitle: string; const AOutline: TIdeOutline); static;
    class function Run(const ALibrary: IIdeGameLibrary; const AGame: string): TStringList; static;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.Ide.NameValueTable,
  DelphiDoom.Ide.ActorDefFunctionTable,
  DelphiDoom.Ide.UnitFunctionTable,
  DelphiDoom.Ide.LibraryTable,
  DelphiDoom.Ide.ClassCatalog,
  DelphiDoom.Ide.SpriteCatalog,
  DelphiDoom.Ide.StateCatalog,
  DelphiDoom.Ide.MobjinfoCatalog;

type
  TNodeInfo = record
    Text: string;
    Level: Integer;
  end;

procedure Flatten(const ANode: TIdeOutlineNode; const ALevel: Integer; const AList: TList<TNodeInfo>);
var
  LInfo: TNodeInfo;
  LChild: TIdeOutlineNode;
begin
  LInfo.Text := ANode.Text;
  LInfo.Level := ALevel;
  AList.Add(LInfo);
  for LChild in ANode.Children do
    Flatten(LChild, ALevel + 1, AList);
end;

function FlatNodes(const AOutline: TIdeOutline): TArray<TNodeInfo>;
var
  LList: TList<TNodeInfo>;
  LRoot: TIdeOutlineNode;
begin
  LList := TList<TNodeInfo>.Create;
  try
    for LRoot in AOutline.Roots do
      Flatten(LRoot, 0, LList);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

{ TLibraryDump }

class function TLibraryDump.Fnv1a(const ARows: TStrings): string;
var
  LHash: UInt64;
  LBytes: TBytes;
  LIndex, LByte: Integer;
begin
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to ARows.Count - 1 do
  begin
    LBytes := TEncoding.UTF8.GetBytes(ARows[LIndex] + #10);
    for LByte := 0 to Length(LBytes) - 1 do
      LHash := (LHash xor LBytes[LByte]) * UInt64($100000001B3);
  end;
  Result := IntToHex(LHash, 16);
end;

class procedure TLibraryDump.AddSection(const ALines: TStrings; const ATitle: string; const ARows: TStrings);
begin
  ALines.Add('## ' + ATitle + ' count=' + IntToStr(ARows.Count) + ' fnv=' + Fnv1a(ARows));
  if ARows.Count > 0 then
  begin
    ALines.Add('   first: ' + ARows[0]);
    ALines.Add('   last: ' + ARows[ARows.Count - 1]);
  end;
end;

class function TLibraryDump.RowText(const ARow: TIdeRow): string;
var
  LValue: string;
begin
  Result := ARow.Caption;
  for LValue in ARow.Values do
    Result := Result + '|' + LValue;
end;

class procedure TLibraryDump.AddRows(const ALines: TStrings; const ATitle: string;
  const ARows: TArray<TIdeRow>);
var
  LRows: TStringList;
  LRow: TIdeRow;
begin
  LRows := TStringList.Create;
  try
    for LRow in ARows do
      LRows.Add(RowText(LRow));
    AddSection(ALines, ATitle, LRows);
  finally
    LRows.Free;
  end;
end;

class procedure TLibraryDump.AddOutline(const ALines: TStrings; const ATitle: string;
  const AOutline: TIdeOutline);
var
  LRows: TStringList;
  LLine: string;
begin
  LRows := TStringList.Create;
  try
    for LLine in AOutline.ToLines do
      LRows.Add(LLine);
    AddSection(ALines, ATitle, LRows);
  finally
    LRows.Free;
  end;
end;

class function TLibraryDump.Run(const ALibrary: IIdeGameLibrary; const AGame: string): TStringList;
var
  LTable: TIdeLibraryTable;
  LOutline: TIdeOutline;
  LNodes: TArray<TNodeInfo>;
  LIndex, LLimit: Integer;
  LSprites: TIdeSpriteCatalog;
  LStates: TIdeStateCatalog;
  LMobjinfo: TIdeMobjinfoCatalog;
  LClasses: TIdeClassCatalog;

  procedure DumpTable(const AKind: TIdeNameValueKind; const ATitle, AFilter: string;
    const AFilterTitle: string);
  begin
    LTable := TIdeNameValueTable.Create(AKind);
    try
      LTable.Load(ALibrary, AGame);
      AddRows(Result, ATitle, LTable.Rows('', 0));
      AddRows(Result, AFilterTitle, LTable.Rows(AFilter, 0));
      if AKind = nvConstants then
        AddRows(Result, 'constants sorted by value', LTable.Rows('', 1));
    finally
      LTable.Free;
    end;
  end;

begin
  Result := TStringList.Create;

  DumpTable(nvConstants, 'constants', 'MAX', 'constants filter MAX');
  DumpTable(nvVariables, 'variables', 'level', 'variables filter level');
  DumpTable(nvTypes, 'types', 'T', 'types filter T');

  LTable := TIdeUnitFunctionTable.Create;
  try
    LTable.Load(ALibrary, AGame);
    // the panel of the functions starts sorted by the unit (column 2)
    AddRows(Result, 'unitfunctions', LTable.Rows('', 2));
    AddRows(Result, 'unitfunctions filter get', LTable.Rows('get', 2));
    AddRows(Result, 'unitfunctions sorted by unit', LTable.Rows('get', 2));
  finally
    LTable.Free;
  end;

  LTable := TIdeActorDefFunctionTable.Create;
  try
    LTable.Load(ALibrary, AGame);
    AddRows(Result, 'actordef', LTable.Rows('', 0));
    AddRows(Result, 'actordef filter sound', LTable.Rows('sound', 0));
  finally
    LTable.Free;
  end;

  LClasses := TIdeClassCatalog.Create;
  try
    LClasses.Load(ALibrary, AGame);
    LOutline := LClasses.BuildOutline('');
    try
      AddOutline(Result, 'classes', LOutline);
    finally
      LOutline.Free;
    end;
    LOutline := LClasses.BuildOutline('T');
    try
      AddOutline(Result, 'classes filter T', LOutline);
    finally
      LOutline.Free;
    end;
  finally
    LClasses.Free;
  end;

  LSprites := TIdeSpriteCatalog.Create;
  try
    LSprites.Load(ALibrary, AGame);
    LOutline := LSprites.BuildOutline('');
    try
      AddOutline(Result, 'sprites', LOutline);
      LNodes := FlatNodes(LOutline);
      AddRows(Result, 'sprites list of first', LSprites.RowsFor(LNodes[0].Text, LNodes[0].Level));
      LLimit := Length(LNodes) - 1;
      if LLimit > 40 then
        LLimit := 40;
      for LIndex := 0 to LLimit do
        AddRows(Result, 'sprites list of ' + LNodes[LIndex].Text,
          LSprites.RowsFor(LNodes[LIndex].Text, LNodes[LIndex].Level));
    finally
      LOutline.Free;
    end;
    LOutline := LSprites.BuildOutline('SP');
    try
      AddOutline(Result, 'sprites filter SP', LOutline);
    finally
      LOutline.Free;
    end;
  finally
    LSprites.Free;
  end;

  LStates := TIdeStateCatalog.Create;
  try
    LStates.Load(ALibrary, AGame);
    LOutline := LStates.BuildOutline('');
    try
      AddOutline(Result, 'states', LOutline);
      LNodes := FlatNodes(LOutline);
      LLimit := Length(LNodes) - 1;
      if LLimit > 60 then
        LLimit := 60;
      for LIndex := 0 to LLimit do
        AddRows(Result, 'states list of ' + LNodes[LIndex].Text, LStates.RowsFor(LNodes[LIndex].Text));
    finally
      LOutline.Free;
    end;
    LOutline := LStates.BuildOutline('1');
    try
      AddOutline(Result, 'states filter 1', LOutline);
    finally
      LOutline.Free;
    end;
  finally
    LStates.Free;
  end;

  LMobjinfo := TIdeMobjinfoCatalog.Create;
  try
    LMobjinfo.Load(ALibrary, AGame);
    LOutline := LMobjinfo.BuildOutline('');
    try
      AddOutline(Result, 'mobjinfo', LOutline);
      LNodes := FlatNodes(LOutline);
      LLimit := Length(LNodes) - 1;
      if LLimit > 120 then
        LLimit := 120;
      for LIndex := 0 to LLimit do
        AddRows(Result, 'mobjinfo list of ' + LNodes[LIndex].Text, LMobjinfo.RowsFor(LNodes[LIndex].Text));
    finally
      LOutline.Free;
    end;
    LOutline := LMobjinfo.BuildOutline('ZOMBIE');
    try
      AddOutline(Result, 'mobjinfo filter ZOMBIE', LOutline);
    finally
      LOutline.Free;
    end;
  finally
    LMobjinfo.Free;
  end;
end;

end.
