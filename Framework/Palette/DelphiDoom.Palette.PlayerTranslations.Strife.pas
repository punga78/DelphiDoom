{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the colors of the players of Strife            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.PlayerTranslations.Strife;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   R_InitTranslationTables of Strife (villsa's tables with the fixes of haleyjd): 7 tables.
  ///   The values that go under 0 wrap around the byte, as the original assignments do
  /// </summary>
  TStrifePlayerTranslations = class(TInterfacedObject, IPlayerTranslations)
  strict private
    class procedure SetAll(var ATables: TBytes; AIndex: Integer; const AValues: array of Integer); static;
  public
    function TableCount: Integer;
    function Build: TBytes;
  end;

implementation

{ TStrifePlayerTranslations }

class procedure TStrifePlayerTranslations.SetAll(var ATables: TBytes; AIndex: Integer;
  const AValues: array of Integer);
var
  LTable: Integer;
begin
  for LTable := 0 to High(AValues) do
    ATables[AIndex + LTable * COLORMAP_ROW_SIZE] := Byte(AValues[LTable]);
end;

function TStrifePlayerTranslations.TableCount: Integer;
begin
  Result := 7;
end;

function TStrifePlayerTranslations.Build: TBytes;
var
  LIndex: Integer;
  LLow: Integer;
  LFirst: Integer;
  LSecond: Integer;
begin
  SetLength(Result, TableCount * COLORMAP_ROW_SIZE);
  for LIndex := 0 to COLORMAP_ROW_SIZE - 1 do
  begin
    LLow := LIndex and $0F;
    // the two running colors of the original (they start at $FA and $E0 and grow with the index)
    LFirst := ($FA + LIndex) and $FF;
    LSecond := ($E0 + LIndex) and $FF;
    if (LIndex >= $80) and (LIndex <= $8F) then
      SetAll(Result, LIndex, [LLow + 64, LLow - 80, LLow + 16, LLow + 48, LLow + 80, LLow + 96, LLow - 112])
    else if (LIndex >= $50) and (LIndex <= $5F) then
      SetAll(Result, LIndex, [LIndex, LIndex, LIndex, LIndex, LLow + $80, LLow + 16, LLow + 64])
    else if (LIndex >= $D0) and (LIndex <= $DF) then
      SetAll(Result, LIndex, [LIndex, LIndex, LIndex, LIndex, LLow - 80, LLow + 48, LLow + 16])
    else if (LIndex >= $C0) and (LIndex <= $CF) then
    begin
      SetAll(Result, LIndex, [LIndex, LIndex, LIndex, LIndex, LLow - 96, LLow + 32, LLow]);
      // haleyjd 20110213: missing code
      if LLow = 0 then
        Result[LIndex + 6 * COLORMAP_ROW_SIZE] := 1;
    end
    else if (LIndex >= $F7) and (LIndex <= $FB) then
      SetAll(Result, LIndex, [LFirst, LIndex, LIndex, LIndex, LIndex, LIndex, LIndex])
    else if (LIndex >= $F1) and (LIndex <= $F6) then
      SetAll(Result, LIndex, [LLow - 33, LIndex, LIndex, LIndex, LIndex, LIndex, LIndex])
    else if (LIndex >= $20) and (LIndex <= $3F) then
      SetAll(Result, LIndex, [LSecond, LSecond, LLow - 48, LLow - 48, LSecond, LSecond, LSecond])
    else
      SetAll(Result, LIndex, [LIndex, LIndex, LIndex, LIndex, LIndex, LIndex, LIndex]);
  end;
end;

end.
