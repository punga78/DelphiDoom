{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - PALETTES.DAT and BACKPALS.DAT            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.PaletteReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   Palette::loadDat: the colors are three bytes in a row on a scale of 0 to 63, that the game multiplies
  ///   by 4 (a value over 63 wraps in the byte, as the C++ does). The alpha is 255 for the colors that were read,
  ///   0 for the ones the file did not have, and 0 for the color 0
  /// </summary>
  TXcomPaletteReader = class(TInterfacedObject, IXcomPaletteReader)
  public
    function Read(const ABytes: TBytes; ACount, AOffset: Integer): TXcomPalette;
    function OffsetOf(AIndex: Integer): Integer;
  end;

implementation

{ TXcomPaletteReader }

function TXcomPaletteReader.OffsetOf(AIndex: Integer): Integer;
begin
  Result := AIndex * XCOM_PALETTE_STRIDE;
end;

function TXcomPaletteReader.Read(const ABytes: TBytes; ACount, AOffset: Integer): TXcomPalette;
var
  LIndex: Integer;
  LPosition: Integer;
begin
  Result := TXcomPalette.Create(ACount);
  if AOffset < 0 then
    raise EXcomException.CreateFmt(SXcomOffsetInvalid, [AOffset]);
  LPosition := AOffset;
  LIndex := 0;
  while (LIndex < ACount) and (LPosition + 3 <= Length(ABytes)) do
  begin
    Result.Colors[LIndex].Red := (ABytes[LPosition] * 4) and $FF;
    Result.Colors[LIndex].Green := (ABytes[LPosition + 1] * 4) and $FF;
    Result.Colors[LIndex].Blue := (ABytes[LPosition + 2] * 4) and $FF;
    Result.Colors[LIndex].Alpha := 255;
    Inc(LPosition, 3);
    Inc(LIndex);
  end;
  if ACount > 0 then
    Result.Colors[0].Alpha := 0;
end;

end.
