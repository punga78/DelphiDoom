{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the comparison of two logs                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.LogComparer;

interface

uses
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   Finds the first line where two parity logs differ (state, frame or detail logs). The lines that
  ///   start with # are comments and do not count (but are counted in the line number). For a line of the
  ///   state (T) it says which hashes or numbers differ, for a line of a frame (F) which of full, view and
  ///   hud, for a line of detail (D) the category, the index and the field
  /// </summary>
  TParityLogComparer = class
  strict private
    class function NextLine(const ALines: TArray<string>; var AIndex: Integer): Boolean; static;
    class function TicOf(const ALine: string): Integer; static;
    class function Differing(const AExpected, AActual: string): string; static;
  public
    /// <summary>AExpected: the golden log; AActual: the log of the run</summary>
    class function Compare(const AExpected, AActual: TArray<string>): TParityDifference; static;
  end;

implementation

uses
  System.StrUtils,
  System.SysUtils;

const
  SEndOfLog = '(end of the log)';
  FRAME_NAMES: array[0..2] of string = ('full', 'view', 'hud');

{ TParityLogComparer }

class function TParityLogComparer.NextLine(const ALines: TArray<string>; var AIndex: Integer): Boolean;
begin
  while (AIndex <= High(ALines)) and ((ALines[AIndex] = '') or (ALines[AIndex][1] = '#')) do
    Inc(AIndex);
  Result := AIndex <= High(ALines);
end;

class function TParityLogComparer.TicOf(const ALine: string): Integer;
var
  LParts: TArray<string>;
begin
  LParts := ALine.Split([' ']);
  if (Length(LParts) < 2) or not TryStrToInt(LParts[1], Result) then
    Result := -1;
end;

class function TParityLogComparer.Differing(const AExpected, AActual: string): string;
var
  LExpected: TArray<string>;
  LActual: TArray<string>;
  LIndex: Integer;
  LKey: string;
  LNames: TArray<string>;
begin
  Result := '';
  LExpected := AExpected.Split([' ']);
  LActual := AActual.Split([' ']);
  if (Length(LExpected) < 2) or (Length(LActual) < 2) or (LExpected[0] <> LActual[0]) then
    Exit('line kind');
  if LExpected[0] = 'D' then
  begin
    if Length(LExpected) >= 6 then
      Exit(LExpected[2] + ' ' + LExpected[3] + ' ' + LExpected[4]);
    Exit('detail');
  end;
  if LExpected[0] = 'F' then
  begin
    for LIndex := 0 to High(FRAME_NAMES) do
      if (Length(LExpected) > LIndex + 2) and (Length(LActual) > LIndex + 2) and
        (LExpected[LIndex + 2] <> LActual[LIndex + 2]) then
        Result := Result + IfThen(Result = '', '', ',') + FRAME_NAMES[LIndex];
    Exit;
  end;
  // T lines: the total (after the tic), then name=value pairs
  if (Length(LExpected) > 2) and (Length(LActual) > 2) and (LExpected[2] <> LActual[2]) then
    Result := 'total';
  for LIndex := 3 to High(LExpected) do
  begin
    LNames := LExpected[LIndex].Split(['=']);
    LKey := LNames[0];
    if (LIndex > High(LActual)) or (LActual[LIndex] <> LExpected[LIndex]) then
      Result := Result + IfThen(Result = '', '', ',') + LKey;
  end;
  if Length(LActual) <> Length(LExpected) then
    Result := Result + IfThen(Result = '', '', ',') + 'number of fields';
end;

class function TParityLogComparer.Compare(const AExpected, AActual: TArray<string>): TParityDifference;
var
  LExpectedIndex: Integer;
  LActualIndex: Integer;
  LHasExpected: Boolean;
  LHasActual: Boolean;
begin
  Result := Default(TParityDifference);
  Result.Tic := -1;
  LExpectedIndex := 0;
  LActualIndex := 0;
  repeat
    LHasExpected := NextLine(AExpected, LExpectedIndex);
    LHasActual := NextLine(AActual, LActualIndex);
    if not LHasExpected and not LHasActual then
      Exit;
    if LHasExpected and LHasActual then
    begin
      if AExpected[LExpectedIndex] <> AActual[LActualIndex] then
      begin
        Result.Found := True;
        Result.LineNumber := LExpectedIndex + 1;
        Result.Tic := TicOf(AExpected[LExpectedIndex]);
        Result.Expected := AExpected[LExpectedIndex];
        Result.Actual := AActual[LActualIndex];
        Result.Differing := Differing(Result.Expected, Result.Actual);
        Exit;
      end;
    end
    else
    begin
      Result.Found := True;
      if LHasExpected then
      begin
        Result.LineNumber := LExpectedIndex + 1;
        Result.Tic := TicOf(AExpected[LExpectedIndex]);
        Result.Expected := AExpected[LExpectedIndex];
        Result.Actual := SEndOfLog;
      end
      else
      begin
        Result.LineNumber := LActualIndex + 1;
        Result.Tic := TicOf(AActual[LActualIndex]);
        Result.Expected := SEndOfLog;
        Result.Actual := AActual[LActualIndex];
      end;
      Result.Differing := 'length of the log';
      Exit;
    end;
    Inc(LExpectedIndex);
    Inc(LActualIndex);
  until False;
end;

end.
