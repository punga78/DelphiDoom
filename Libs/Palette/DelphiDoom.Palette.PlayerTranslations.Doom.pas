{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the colors of the players of Doom              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.PlayerTranslations.Doom;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   R_InitTranslationTables of Doom: the 16 green colors ($70..$7F) of the marine become
  ///   gray ($60), brown ($40) or red ($20); everything else stays. 3 tables
  /// </summary>
  TDoomPlayerTranslations = class(TInterfacedObject, IPlayerTranslations)
  public
    function TableCount: Integer;
    function Build: TBytes;
  end;

implementation

{ TDoomPlayerTranslations }

function TDoomPlayerTranslations.TableCount: Integer;
begin
  Result := 3;
end;

function TDoomPlayerTranslations.Build: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, TableCount * COLORMAP_ROW_SIZE);
  for LIndex := 0 to COLORMAP_ROW_SIZE - 1 do
    if (LIndex >= $70) and (LIndex <= $7F) then
    begin
      Result[LIndex] := Byte($60 + (LIndex and $F));
      Result[LIndex + 256] := Byte($40 + (LIndex and $F));
      Result[LIndex + 512] := Byte($20 + (LIndex and $F));
    end
    else
    begin
      Result[LIndex] := Byte(LIndex);
      Result[LIndex + 256] := Byte(LIndex);
      Result[LIndex + 512] := Byte(LIndex);
    end;
end;

end.
