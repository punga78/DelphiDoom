{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the DOS terminal font (Font::loadTerminal) }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.TerminalFont;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types;

type
  /// <summary>The Codepage 437 font of the start screen: a monospace font of 9 x 16 cells from a 1 bit bitmap</summary>
  TXcomTerminalFont = class
  public
    /// <summary>Font::loadTerminal: the caller owns the font</summary>
    class function Create: TXcomFont; static;
    /// <summary>The two colors of the font (the first 2 colors of its palette, used as the palette of the start screen)</summary>
    class function Colors: TArray<TXcomColor>; static;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.DosFontData;

const
  TERMINAL_CHARS = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';

class function TXcomTerminalFont.Colors: TArray<TXcomColor>;
begin
  SetLength(Result, 2);
  Result[0].Red := 0;
  Result[0].Green := 0;
  Result[0].Blue := 0;
  Result[0].Alpha := 0;
  Result[1].Red := 185;
  Result[1].Green := 185;
  Result[1].Blue := 185;
  Result[1].Alpha := 255;
end;

class function TXcomTerminalFont.Create: TXcomFont;
var
  LWidth: Integer;
  LHeight: Integer;
  LStride: Integer;
  LOffset: Integer;
  LSurface: TXcomSurface;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
begin
  LWidth := DOSFONT_BYTES[18] or (DOSFONT_BYTES[19] shl 8);
  LHeight := DOSFONT_BYTES[22] or (DOSFONT_BYTES[23] shl 8);
  LOffset := DOSFONT_BYTES[10] or (DOSFONT_BYTES[11] shl 8);
  // a 1 bit BMP: rows from the bottom, each padded to 4 bytes
  LStride := ((LWidth + 31) div 32) * 4;
  LSurface := TXcomSurface.Create(LWidth, LHeight);
  try
    LSurface.SetColors(Colors);
    for LY := 0 to LHeight - 1 do
    begin
      LRow := LOffset + (LHeight - 1 - LY) * LStride;
      for LX := 0 to LWidth - 1 do
        if (DOSFONT_BYTES[LRow + LX div 8] and ($80 shr (LX mod 8))) <> 0 then
          LSurface.SetPixel(LX, LY, 1);
    end;
    Result := TXcomFont.Create;
    try
      Result.Monospace := True;
      Result.AddImage(9, 16, 0, LSurface);
    except
      LSurface.Free;
      raise;
    end;
  except
    raise;
  end;
  Result.Init(0, TXcomFont.CodePoints(TERMINAL_CHARS));
end;

end.
