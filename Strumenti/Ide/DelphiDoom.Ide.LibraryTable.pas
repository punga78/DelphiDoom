{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - a list of the compiler library                    }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.LibraryTable;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.RowSorter;

type
  /// <summary>An entry of a library list</summary>
  TIdeLibraryTableItem = record
    /// <summary>The first cell, the one the filter looks at</summary>
    Name: string;
    /// <summary>The other cells</summary>
    Values: TArray<string>;
    /// <summary>The text of the line under the list when the entry is selected</summary>
    Declaration: string;
  end;

  /// <summary>
  ///   The base of the lists of the library panels (constants, variables, types, functions of
  ///   the units, functions of the actor definitions): the entries, the filter by name and the
  ///   sort by a column. A descendant reads the entries of a game
  /// </summary>
  TIdeLibraryTable = class
  strict private
    FItems: TList<TIdeLibraryTableItem>;
    FCompare: TIdeColumnCompare;
  protected
    procedure Clear;
    procedure Add(const AName: string; const AValues: TArray<string>; const ADeclaration: string);
  public
    constructor Create(const ACompare: TIdeColumnCompare);
    destructor Destroy; override;
    /// <summary>
    ///   Reads the entries of a game. If the library has nothing for that game the entries stay as
    ///   they were and the answer is false
    /// </summary>
    function Load(const ALibrary: IIdeGameLibrary; const AGame: string): Boolean; virtual; abstract;
    /// <summary>
    ///   The entries whose name has the filter inside (without regard to the case; spaces around
    ///   the filter do not count), sorted by a column (0 is the name)
    /// </summary>
    function Rows(const AFilter: string; const ASortColumn: Integer): TArray<TIdeRow>;
    function Declaration(const ATag: Integer): string;
    function NameOf(const ATag: Integer): string;
    function Count: Integer;
  end;

implementation

uses
  System.SysUtils;

{ TIdeLibraryTable }

constructor TIdeLibraryTable.Create(const ACompare: TIdeColumnCompare);
begin
  inherited Create;
  FCompare := ACompare;
  FItems := TList<TIdeLibraryTableItem>.Create;
end;

destructor TIdeLibraryTable.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TIdeLibraryTable.Clear;
begin
  FItems.Clear;
end;

procedure TIdeLibraryTable.Add(const AName: string; const AValues: TArray<string>;
  const ADeclaration: string);
var
  LItem: TIdeLibraryTableItem;
begin
  LItem.Name := AName;
  LItem.Values := AValues;
  LItem.Declaration := ADeclaration;
  FItems.Add(LItem);
end;

function TIdeLibraryTable.Rows(const AFilter: string; const ASortColumn: Integer): TArray<TIdeRow>;
var
  LRows: TList<TIdeRow>;
  LRow: TIdeRow;
  LFilter: string;
  LIndex: Integer;
begin
  LFilter := LowerCase(Trim(AFilter));
  LRows := TList<TIdeRow>.Create;
  try
    for LIndex := 0 to FItems.Count - 1 do
      if (LFilter = '') or (Pos(LFilter, LowerCase(FItems[LIndex].Name)) > 0) then
      begin
        LRow.Caption := FItems[LIndex].Name;
        LRow.Values := FItems[LIndex].Values;
        LRow.Tag := LIndex;
        LRows.Add(LRow);
      end;
    Result := LRows.ToArray;
  finally
    LRows.Free;
  end;
  TIdeRowSorter.Sort(Result, ASortColumn, FCompare);
end;

function TIdeLibraryTable.Declaration(const ATag: Integer): string;
begin
  Result := FItems[ATag].Declaration;
end;

function TIdeLibraryTable.NameOf(const ATag: Integer): string;
begin
  Result := FItems[ATag].Name;
end;

function TIdeLibraryTable.Count: Integer;
begin
  Result := FItems.Count;
end;

end.
