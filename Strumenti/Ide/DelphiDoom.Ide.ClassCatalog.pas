{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the "Classes" panel                               }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ClassCatalog;

interface

uses
  System.Classes,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Outline;

type
  /// <summary>
  ///   The classes a script can use: a tree with one line for each class and its declarations
  ///   under it (inherit, constructors, destructor, functions, procedures, properties, the rest)
  /// </summary>
  TIdeClassCatalog = class
  strict private
    FClasses: TStringList;
    procedure ClearClasses;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A game with no class leaves the catalog as it was and the answer is false</summary>
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
    function BuildOutline(const AFilter: string): TIdeOutline;
    /// <summary>The order of the declarations of a class: a negative number if the left line goes first</summary>
    class function CompareDeclarations(const ALeft, ARight: string): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults,
  DelphiDoom.Ide.Types;

function DeclarationRank(const ALowerLine: string): Integer;
begin
  if Pos('inherit', ALowerLine) = 1 then
    Result := 1
  else if Pos('constructor', ALowerLine) = 1 then
    Result := 2
  else if Pos('destructor', ALowerLine) = 1 then
    Result := 3
  else if Pos('function', ALowerLine) = 1 then
    Result := 4
  else if Pos('procedure', ALowerLine) = 1 then
    Result := 5
  else if Pos('property', ALowerLine) = 1 then
    Result := 6
  else
    Result := 7;
end;

{ TIdeClassCatalog }

constructor TIdeClassCatalog.Create;
begin
  inherited Create;
  FClasses := TStringList.Create;
end;

destructor TIdeClassCatalog.Destroy;
begin
  ClearClasses;
  FClasses.Free;
  inherited Destroy;
end;

procedure TIdeClassCatalog.ClearClasses;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FClasses.Count - 1 do
    FClasses.Objects[LIndex].Free;
  FClasses.Clear;
end;

class function TIdeClassCatalog.CompareDeclarations(const ALeft, ARight: string): Integer;
var
  LLeft, LRight: string;
begin
  LLeft := LowerCase(ALeft);
  LRight := LowerCase(ARight);
  Result := DeclarationRank(LLeft) - DeclarationRank(LRight);
  if Result = 0 then
  begin
    if LLeft < LRight then
      Result := -1
    else if LLeft > LRight then
      Result := 1;
  end;
end;

function TIdeClassCatalog.Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean;
var
  LLines: TArray<string>;
  LLine, LName, LRest: string;
  LSeparator: Integer;
  LParsed, LUnique: TStringList;
  LIndex: Integer;
begin
  Result := ALibrary.TryGetLines(ldClasses, AGame, LLines);
  if not Result then
    Exit;
  ClearClasses;
  LParsed := TStringList.Create;
  try
    for LLine in LLines do
    begin
      // "Name=declaration|declaration|...": the name is what comes before the first "="
      LSeparator := Pos('=', LLine);
      if LSeparator = 0 then
      begin
        LName := LLine;
        LRest := '';
      end
      else
      begin
        LName := Copy(LLine, 1, LSeparator - 1);
        LRest := Copy(LLine, LSeparator + 1, MaxInt);
      end;
      LParsed.Text := StringReplace(LRest, '|', #13#10, [rfReplaceAll]);
      LUnique := TStringList.Create;
      for LIndex := 0 to LParsed.Count - 1 do
        if LUnique.IndexOf(LParsed[LIndex]) < 0 then
          LUnique.Add(LParsed[LIndex]);
      FClasses.AddObject(LName, LUnique);
    end;
  finally
    LParsed.Free;
  end;
end;

function TIdeClassCatalog.BuildOutline(const AFilter: string): TIdeOutline;
var
  LFilter: string;
  LIndex, LDeclaration: Integer;
  LNode: TIdeOutlineNode;
  LSorted: TList<string>;
  LLine: string;
begin
  Result := TIdeOutline.Create;
  LFilter := LowerCase(Trim(AFilter));
  for LIndex := 0 to FClasses.Count - 1 do
  begin
    if (LFilter <> '') and (Pos(LFilter, LowerCase(FClasses[LIndex])) = 0) then
      Continue;
    LNode := Result.AddRoot(FClasses[LIndex]);
    LSorted := TList<string>.Create;
    try
      for LDeclaration := 0 to (FClasses.Objects[LIndex] as TStringList).Count - 1 do
        LSorted.Add((FClasses.Objects[LIndex] as TStringList)[LDeclaration]);
      LSorted.Sort(TComparer<string>.Construct(
        function(const ALeft, ARight: string): Integer
        begin
          Result := CompareDeclarations(ALeft, ARight);
        end));
      for LLine in LSorted do
        LNode.AddChild(LLine);
    finally
      LSorted.Free;
    end;
  end;
  Result.SortRoots;
end;

end.
