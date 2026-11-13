{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib list containers - the scenarios of the       }
{  golden                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Containers.ListCases;

{$Q-}
{$R-}

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The same series of operations as the C++ harness (Tools\Verifica\98\containers\main.cpp) that wrote
  ///   lists.golden.txt with the real idList, idStaticList and idHashTable
  /// </summary>
  TIdLibListCases = class
  public
    class procedure List(const ALines: TStrings); static;
    class procedure StaticList(const ALines: TStrings); static;
    class procedure HashTable(const ALines: TStrings); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Containers.List, DelphiDoom.IdLib.Containers.StaticList,
  DelphiDoom.IdLib.Containers.HashTable;

var
  GState: Cardinal;

function Rnd: Integer;
begin
  GState := GState * 1664525 + 1013904223;
  Result := Integer(GState shr 16);
end;

function B(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

procedure DumpList(const ALines: TStrings; const AName: string; const AList: TIdList<Integer>);
var
  LText: string;
  LIndex: Integer;
begin
  LText := Format('  %s %d/%d/%d [', [AName, AList.Num, AList.NumAllocated, AList.GetGranularity]);
  for LIndex := 0 to AList.Num - 1 do
  begin
    if LIndex > 0 then
      LText := LText + ' ';
    LText := LText + IntToStr(AList[LIndex]);
  end;
  ALines.Add(LText + ']');
end;

class procedure TIdLibListCases.List(const ALines: TStrings);
const
  GRANULARITIES: array[0..5] of Integer = (1, 2, 3, 5, 8, 16);
var
  LVariant, LStep, LOp, LValue, LResult, LIndex, LNumber, LGranularity, LFirst, LLast: Integer;
  LResize: Boolean;
  A, Bl: TIdList<Integer>;
begin
  ALines.Add('== list');
  for LVariant := 0 to 5 do
  begin
    A := TIdList<Integer>.Create(GRANULARITIES[LVariant]);
    Bl := TIdList<Integer>.Create(GRANULARITIES[LVariant]);
    try
      GState := Cardinal(Int64($1234567) + Int64(LVariant) * 7919);
      ALines.Add(Format('variant %d granularity %d', [LVariant, GRANULARITIES[LVariant]]));
      for LStep := 0 to 299 do
      begin
        LOp := Rnd mod 22;
        LValue := Rnd mod 12;
        LResult := 0;
        case LOp of
          0: LResult := A.Append(LValue);
          1:
            begin
              LIndex := Rnd mod (A.Num + 5) - 2;
              LResult := A.Insert(LValue, LIndex);
            end;
          2:
            begin
              LIndex := Rnd mod (A.Num + 3) - 1;
              LResult := B(A.RemoveIndex(LIndex));
            end;
          3: LResult := B(A.Remove(LValue));
          4: LResult := A.AddUnique(LValue);
          5: LResult := A.FindIndex(LValue);
          6:
            begin
              LNumber := Rnd mod 20;
              LResize := (Rnd and 1) <> 0;
              A.SetNum(LNumber, LResize);
            end;
          7: A.Resize(Rnd mod 20);
          8:
            begin
              LNumber := Rnd mod 20;
              LGranularity := 1 + Rnd mod 6;
              A.Resize(LNumber, LGranularity);
            end;
          9: A.Condense;
          10: A.SetGranularity(1 + Rnd mod 7);
          11: A.AssureSize(Rnd mod 20);
          12: A.AssureSize(Rnd mod 20, LValue);
          13:
            begin
              LIndex := A.Num;
              A[A.Alloc] := LValue;
              LResult := LIndex;
            end;
          14: LResult := A.Append(Bl);
          15: A.Swap(Bl);
          16: A.Sort;
          17:
            begin
              LFirst := Rnd mod 8 - 1;
              LLast := Rnd mod 20;
              A.SortSubSection(LFirst, LLast);
            end;
          18: A.Clear;
          19: A.Assign(Bl);
          20:
            begin
              Bl.Append(LValue);
              Bl.Append(Rnd mod 12);
            end;
          21: Bl.Insert(LValue, Rnd mod 4);
        end;
        ALines.Add(Format('step %d op %d v %d ret %d', [LStep, LOp, LValue, LResult]));
        DumpList(ALines, 'A', A);
        DumpList(ALines, 'B', Bl);
      end;
    finally
      Bl.Free;
      A.Free;
    end;
  end;
end;

procedure DumpStatic(const ALines: TStrings; const AName: string; const AList: TIdStaticList<Integer>);
var
  LText: string;
  LIndex: Integer;
begin
  LText := Format('  %s %d/%d [', [AName, AList.Num, AList.Max]);
  for LIndex := 0 to AList.Num - 1 do
  begin
    if LIndex > 0 then
      LText := LText + ' ';
    LText := LText + IntToStr(AList[LIndex]);
  end;
  ALines.Add(LText + ']');
end;

class procedure TIdLibListCases.StaticList(const ALines: TStrings);
var
  LVariant, LStep, LOp, LValue, LResult, LIndex: Integer;
  A, Bl: TIdStaticList<Integer>;
begin
  ALines.Add('== staticlist');
  for LVariant := 0 to 3 do
  begin
    A := TIdStaticList<Integer>.Create(8);
    Bl := TIdStaticList<Integer>.Create(8);
    try
      GState := Cardinal(Int64($ABCDEF) + Int64(LVariant) * 104729);
      ALines.Add(Format('variant %d', [LVariant]));
      for LStep := 0 to 299 do
      begin
        LOp := Rnd mod 14;
        LValue := Rnd mod 12;
        LResult := 0;
        case LOp of
          0: LResult := A.Append(LValue);
          1:
            begin
              LIndex := Rnd mod (A.Num + 5) - 2;
              if LIndex < 0 then
                LIndex := 0;
              LResult := A.Insert(LValue, LIndex);
            end;
          2:
            begin
              LIndex := Rnd mod (A.Num + 3) - 1;
              LResult := B(A.RemoveIndex(LIndex));
            end;
          3: LResult := B(A.Remove(LValue));
          4: LResult := A.AddUnique(LValue);
          5: LResult := A.FindIndex(LValue);
          6: A.SetNum(Rnd mod 9);
          7:
            begin
              LIndex := A.Alloc;
              if LIndex >= 0 then
              begin
                A[LIndex] := LValue;
                LResult := A.Num - 1;
              end
              else
                LResult := -1;
            end;
          8: LResult := A.Append(Bl);
          9: A.Swap(Bl);
          10: A.Clear;
          11: A.Assign(Bl);
          12:
            begin
              Bl.Append(LValue);
              Bl.Append(Rnd mod 12);
            end;
          13: Bl.Insert(LValue, Rnd mod 3);
        end;
        ALines.Add(Format('step %d op %d v %d ret %d', [LStep, LOp, LValue, LResult]));
        DumpStatic(ALines, 'A', A);
        DumpStatic(ALines, 'B', Bl);
      end;
    finally
      Bl.Free;
      A.Free;
    end;
  end;
end;

const
  KEY_POOL: array[0..23] of AnsiString = (
    'a', 'A', 'b', 'foo', 'Foo', 'FOO', 'bar', 'Bar', 'baz', 'x1', 'x2', 'x3', 'x10', 'key', 'Key', 'zz',
    '', 'ab', 'ba', 'Ab', 'aB', 'mm', 'MM', 'q');

procedure DumpTable(const ALines: TStrings; const AName: string; const ATable: TIdHashTable<Integer>);
var
  LText: string;
  LIndex, LValue: Integer;
begin
  LText := Format('  %s num %d [', [AName, ATable.Num]);
  for LIndex := 0 to ATable.Num - 1 do
  begin
    if LIndex > 0 then
      LText := LText + ' ';
    if ATable.GetIndex(LIndex, LValue) then
      LText := LText + IntToStr(LValue)
    else
      LText := LText + '-1';
  end;
  ALines.Add(LText + ']');
end;

class procedure TIdLibListCases.HashTable(const ALines: TStrings);
const
  SIZES: array[0..3] of Integer = (1, 4, 16, 256);
var
  LVariant, LStep, LOp, LKey, LResult, LValue: Integer;
  LTable, LCopy: TIdHashTable<Integer>;
begin
  ALines.Add('== hashtable');
  for LVariant := 0 to 3 do
  begin
    LTable := TIdHashTable<Integer>.Create(SIZES[LVariant]);
    try
      GState := Cardinal(Int64($600DF00D) + Int64(LVariant) * 15485863);
      ALines.Add(Format('variant %d size %d', [LVariant, SIZES[LVariant]]));
      for LStep := 0 to 299 do
      begin
        LOp := Rnd mod 8;
        LKey := Rnd mod 24;
        LResult := 0;
        case LOp of
          0, 1, 2: LTable.Put(KEY_POOL[LKey], LStep);
          3:
            if LTable.Get(KEY_POOL[LKey], LValue) then
              LResult := LValue
            else
              LResult := -1;
          4: LResult := B(LTable.Remove(KEY_POOL[LKey]));
          5:
            if LTable.GetIndex(Rnd mod (LTable.Num + 2), LValue) then
              LResult := LValue
            else
              LResult := -1;
          6:
            if Rnd mod 8 = 0 then
              LTable.Clear;
          7:
            begin
              LCopy := TIdHashTable<Integer>.Create(LTable.GetTableSize);
              try
                LCopy.Assign(LTable);
                DumpTable(ALines, 'COPY', LCopy);
              finally
                LCopy.Free;
              end;
            end;
        end;
        ALines.Add(Format('step %d op %d key %d ret %d', [LStep, LOp, LKey, LResult]));
        DumpTable(ALines, 'T', LTable);
      end;
    finally
      LTable.Free;
    end;
  end;
end;

end.
