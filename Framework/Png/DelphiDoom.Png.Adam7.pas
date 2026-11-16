{******************************************************************************}
{                                                                              }
{  DelphiDoom: PNG - Adam7 interlacing passes                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Png.Adam7;

interface

type
  /// <summary>
  ///   The pixels of an image that one pass stores: the ones at column
  ///   ColumnStart + I * ColumnStep and row RowStart + J * RowStep, for I in
  ///   0..Width-1 and J in 0..Height-1. A pass with no pixels has Width or
  ///   Height 0 and has no data in the stream
  /// </summary>
  TPngPass = record
    ColumnStart: Integer;
    RowStart: Integer;
    ColumnStep: Integer;
    RowStep: Integer;
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   The passes of an image: seven for an interlaced one (Adam7), one that
  ///   covers the whole image otherwise
  /// </summary>
  TPngAdam7 = class sealed
  public
    class function PassCount(AInterlaced: Boolean): Integer; static;
    class function GetPass(AInterlaced: Boolean; AIndex, AWidth,
      AHeight: Integer): TPngPass; static;
  end;

implementation

const
  ADAM7_PASS_COUNT = 7;
  ADAM7_COLUMN_START: array[0..ADAM7_PASS_COUNT - 1] of Integer = (0, 4, 0, 2, 0, 1, 0);
  ADAM7_ROW_START: array[0..ADAM7_PASS_COUNT - 1] of Integer = (0, 0, 4, 0, 2, 0, 1);
  ADAM7_COLUMN_STEP: array[0..ADAM7_PASS_COUNT - 1] of Integer = (8, 8, 4, 4, 2, 2, 1);
  ADAM7_ROW_STEP: array[0..ADAM7_PASS_COUNT - 1] of Integer = (8, 8, 8, 4, 4, 2, 2);

{ TPngAdam7 }

class function TPngAdam7.PassCount(AInterlaced: Boolean): Integer;
begin
  if AInterlaced then
    Result := ADAM7_PASS_COUNT
  else
    Result := 1;
end;

class function TPngAdam7.GetPass(AInterlaced: Boolean; AIndex, AWidth,
  AHeight: Integer): TPngPass;
begin
  if not AInterlaced then
  begin
    Result.ColumnStart := 0;
    Result.RowStart := 0;
    Result.ColumnStep := 1;
    Result.RowStep := 1;
    Result.Width := AWidth;
    Result.Height := AHeight;
    Exit;
  end;

  Result.ColumnStart := ADAM7_COLUMN_START[AIndex];
  Result.RowStart := ADAM7_ROW_START[AIndex];
  Result.ColumnStep := ADAM7_COLUMN_STEP[AIndex];
  Result.RowStep := ADAM7_ROW_STEP[AIndex];

  if AWidth > Result.ColumnStart then
    Result.Width := (AWidth - Result.ColumnStart + Result.ColumnStep - 1) div
      Result.ColumnStep
  else
    Result.Width := 0;

  if AHeight > Result.RowStart then
    Result.Height := (AHeight - Result.RowStart + Result.RowStep - 1) div
      Result.RowStep
  else
    Result.Height := 0;
end;

end.
