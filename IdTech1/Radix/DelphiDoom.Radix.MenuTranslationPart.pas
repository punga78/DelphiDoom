{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixMenuTranslationPart                       }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateMenuTranslation of radix_xlat_wad.pas                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.MenuTranslationPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context;

type
  /// <summary>TRN_MENU: the identity table with the colors 208..223 sent to 128..143</summary>
  TRadixMenuTranslationPart = class(TInterfacedObject, IRadixPart)
  public
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

{ TRadixMenuTranslationPart }

procedure TRadixMenuTranslationPart.Build(const AContext: TRadixTranslationContext);
var
  LTable: TBytes;
  LIndex: Integer;
begin
  SetLength(LTable, 256);
  for LIndex := 0 to 255 do
    LTable[LIndex] := LIndex;
  for LIndex := 0 to 15 do
    LTable[208 + LIndex] := 128 + LIndex;
  AContext.Wad.AddLump('TRN_MENU', LTable);
end;

end.
