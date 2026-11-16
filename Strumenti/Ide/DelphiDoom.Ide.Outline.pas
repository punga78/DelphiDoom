{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - a tree of lines for the library panels            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Outline;

interface

uses
  System.Generics.Collections;

type
  /// <summary>One line of an outline and the lines under it</summary>
  TIdeOutlineNode = class
  strict private
    FText: string;
    FChildren: TObjectList<TIdeOutlineNode>;
  public
    constructor Create(const AText: string);
    destructor Destroy; override;
    function AddChild(const AText: string): TIdeOutlineNode;
    property Text: string read FText;
    property Children: TObjectList<TIdeOutlineNode> read FChildren;
  end;

  /// <summary>
  ///   What a tree panel (classes, sprites, states, mobjinfo) shows: the models build it, the
  ///   panel copies it into its tree view
  /// </summary>
  TIdeOutline = class
  strict private
    FRoots: TObjectList<TIdeOutlineNode>;
  public
    constructor Create;
    destructor Destroy; override;
    function AddRoot(const AText: string): TIdeOutlineNode;
    /// <summary>
    ///   Puts the first level in the order a Windows tree view gives it (the case does not count),
    ///   and leaves the lines under each of them where they are. Lines that compare equal keep
    ///   their order
    /// </summary>
    procedure SortRoots;
    /// <summary>The lines, two spaces of indent for each level, in the order of the tree</summary>
    function ToLines: TArray<string>;
    property Roots: TObjectList<TIdeOutlineNode> read FRoots;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults,
  Winapi.Windows;

{ TIdeOutlineNode }

constructor TIdeOutlineNode.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FChildren := TObjectList<TIdeOutlineNode>.Create(True);
end;

destructor TIdeOutlineNode.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TIdeOutlineNode.AddChild(const AText: string): TIdeOutlineNode;
begin
  Result := TIdeOutlineNode.Create(AText);
  FChildren.Add(Result);
end;

{ TIdeOutline }

constructor TIdeOutline.Create;
begin
  inherited Create;
  FRoots := TObjectList<TIdeOutlineNode>.Create(True);
end;

destructor TIdeOutline.Destroy;
begin
  FRoots.Free;
  inherited Destroy;
end;

function TIdeOutline.AddRoot(const AText: string): TIdeOutlineNode;
begin
  Result := TIdeOutlineNode.Create(AText);
  FRoots.Add(Result);
end;

procedure TIdeOutline.SortRoots;
var
  LIndexes: TArray<Integer>;
  LSorted: TObjectList<TIdeOutlineNode>;
  LIndex: Integer;
begin
  SetLength(LIndexes, FRoots.Count);
  for LIndex := 0 to High(LIndexes) do
    LIndexes[LIndex] := LIndex;
  TArray.Sort<Integer>(LIndexes, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      Result := lstrcmpi(PChar(FRoots[ALeft].Text), PChar(FRoots[ARight].Text));
      if Result = 0 then
        Result := ALeft - ARight;
    end));
  FRoots.OwnsObjects := False;
  LSorted := TObjectList<TIdeOutlineNode>.Create(False);
  try
    for LIndex in LIndexes do
      LSorted.Add(FRoots[LIndex]);
    FRoots.Clear;
    FRoots.AddRange(LSorted);
    FRoots.OwnsObjects := True;
  finally
    LSorted.Free;
  end;
end;

function TIdeOutline.ToLines: TArray<string>;
var
  LLines: TList<string>;

  procedure AddNode(const ANode: TIdeOutlineNode; const ALevel: Integer);
  var
    LChild: TIdeOutlineNode;
  begin
    LLines.Add(StringOfChar(' ', ALevel * 2) + ANode.Text);
    for LChild in ANode.Children do
      AddNode(LChild, ALevel + 1);
  end;

var
  LRoot: TIdeOutlineNode;
begin
  LLines := TList<string>.Create;
  try
    for LRoot in FRoots do
      AddNode(LRoot, 0);
    Result := LLines.ToArray;
  finally
    LLines.Free;
  end;
end;

end.
