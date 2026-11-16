{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the colors of the players of Heretic           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.PlayerTranslations.Heretic;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   R_InitTranslationTables of Heretic. The original tests (i >= 255) and (i <= 240), which
  ///   is never true, so its three tables change nothing: the intended ramps (yellow 114, red 145,
  ///   blue 190 from the color 225) are not applied. Kept as it is: the library gives the same
  ///   three identity tables. 3 tables
  /// </summary>
  THereticPlayerTranslations = class(TInterfacedObject, IPlayerTranslations)
  public
    function TableCount: Integer;
    function Build: TBytes;
  end;

implementation

{ THereticPlayerTranslations }

function THereticPlayerTranslations.TableCount: Integer;
begin
  Result := 3;
end;

function THereticPlayerTranslations.Build: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, TableCount * COLORMAP_ROW_SIZE);
  for LIndex := 0 to COLORMAP_ROW_SIZE - 1 do
  begin
    // the original condition (i >= 255) and (i <= 240) is always false
    Result[LIndex] := Byte(LIndex);
    Result[LIndex + 256] := Byte(LIndex);
    Result[LIndex + 512] := Byte(LIndex);
  end;
end;

end.
