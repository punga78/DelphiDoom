{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - sorting the rows of the library lists             }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.RowSorter;

interface

uses
  DelphiDoom.Ide.Types;

type
  /// <summary>How the cells of a column are compared</summary>
  TIdeColumnCompare = (ccText, ccNumbers);

  /// <summary>
  ///   Sorts the rows of a list by one column, as the library lists did when the header was
  ///   clicked: rows that are equal keep their order
  /// </summary>
  TIdeRowSorter = class
  public
    /// <summary>
    ///   Column 0 is the caption, the others are the values. With ccText every column is compared
    ///   as text (without regard to the case). With ccNumbers the value columns are
    ///   compared as numbers when both cells are numbers; a number is greater than a text
    /// </summary>
    class procedure Sort(var ARows: TArray<TIdeRow>; const AColumn: Integer;
      const ACompare: TIdeColumnCompare); static;
    class function CompareCells(const ALeft, ARight: string; const ACompare: TIdeColumnCompare;
      const AIsCaption: Boolean): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.Generics.Defaults;

{ TIdeRowSorter }

class function TIdeRowSorter.CompareCells(const ALeft, ARight: string;
  const ACompare: TIdeColumnCompare; const AIsCaption: Boolean): Integer;
var
  LLeftNumber, LRightNumber: Double;
  LLeftCode, LRightCode: Integer;
begin
  if AIsCaption or (ACompare = ccText) then
    Exit(AnsiCompareText(ALeft, ARight));
  Val(ALeft, LLeftNumber, LLeftCode);
  Val(ARight, LRightNumber, LRightCode);
  if (LLeftCode = 0) and (LRightCode = 0) then
  begin
    if LLeftNumber < LRightNumber then
      Result := -1
    else if LLeftNumber > LRightNumber then
      Result := 1
    else
      Result := 0;
    Exit;
  end;
  if (LLeftCode = 0) or (LRightCode = 0) then
  begin
    if LLeftCode = 0 then
      Result := 1
    else
      Result := -1;
    Exit;
  end;
  Result := AnsiCompareText(ALeft, ARight);
end;

class procedure TIdeRowSorter.Sort(var ARows: TArray<TIdeRow>; const AColumn: Integer;
  const ACompare: TIdeColumnCompare);
var
  LIndexes: TArray<Integer>;
  LSorted: TArray<TIdeRow>;
  LRows: TArray<TIdeRow>;
  LIndex: Integer;
begin
  LRows := ARows;
  SetLength(LIndexes, Length(LRows));
  for LIndex := 0 to High(LIndexes) do
    LIndexes[LIndex] := LIndex;
  TArray.Sort<Integer>(LIndexes, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    var
      LLeftCell, LRightCell: string;
    begin
      if AColumn = 0 then
      begin
        LLeftCell := LRows[ALeft].Caption;
        LRightCell := LRows[ARight].Caption;
      end
      else
      begin
        LLeftCell := LRows[ALeft].Values[AColumn - 1];
        LRightCell := LRows[ARight].Values[AColumn - 1];
      end;
      Result := CompareCells(LLeftCell, LRightCell, ACompare, AColumn = 0);
      if Result = 0 then
        Result := ALeft - ARight;
    end));
  SetLength(LSorted, Length(LRows));
  for LIndex := 0 to High(LIndexes) do
    LSorted[LIndex] := LRows[LIndexes[LIndex]];
  ARows := LSorted;
end;

end.
