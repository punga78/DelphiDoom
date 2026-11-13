{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the format of a font .dat file                    }
{                                                                              }
{  Port of the file branch of RE_RegisterFont, readInt and readFloat of        }
{  tr_font.c (Quake III Arena, id Software, GPL v2 or later). Only the format  }
{  is here: the FreeType code that makes the files is not ported. Based on the }
{  Quake III Arena GPL Source Code (id Software).                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.FontReader;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Font;

type
  /// <summary>Reads a fontImage_N.dat: little endian, byte by byte, 20548 bytes</summary>
  TGuiFontReader = class
  public
    /// <summary>
    ///   Fills AFont from the bytes of a file (glyph handles as stored in the file, glyph scale, and the name
    ///   that the file holds). Raises EGuiFontException if the length is not sizeof(fontInfo_t).
    /// </summary>
    class procedure Read(const ABytes: TBytes; const AFont: TGuiFont); static;
  end;

implementation

uses
  DelphiDoom.Gui.Types, DelphiDoom.Gui.Font.Types;

type
  // readInt and readFloat share an offset in the original (static fdOffset)
  TFontCursor = record
    Bytes: TBytes;
    Offset: Integer;
    function ReadInt: Integer;
    function ReadFloat: Single;
  end;

function TFontCursor.ReadInt: Integer;
begin
  Result := Integer(Cardinal(Bytes[Offset]) or (Cardinal(Bytes[Offset + 1]) shl 8) or
    (Cardinal(Bytes[Offset + 2]) shl 16) or (Cardinal(Bytes[Offset + 3]) shl 24));
  Inc(Offset, 4);
end;

function TFontCursor.ReadFloat: Single;
var
  LBits: Integer;
begin
  LBits := ReadInt;
  Move(LBits, Result, SizeOf(Single));
end;

class procedure TGuiFontReader.Read(const ABytes: TBytes; const AFont: TGuiFont);
var
  LCursor: TFontCursor;
  LIndex: Integer;
  LGlyph: TGuiGlyph;
  LName: AnsiString;
  LLength: Integer;
begin
  if Length(ABytes) <> GUI_FONT_FILE_SIZE then
    raise EGuiFontException.CreateFmt('font file of %d bytes, %d expected', [Length(ABytes), GUI_FONT_FILE_SIZE]);
  LCursor.Bytes := ABytes;
  LCursor.Offset := 0;
  for LIndex := 0 to GUI_GLYPHS_PER_FONT - 1 do
  begin
    LGlyph.Height := LCursor.ReadInt;
    LGlyph.Top := LCursor.ReadInt;
    LGlyph.Bottom := LCursor.ReadInt;
    LGlyph.Pitch := LCursor.ReadInt;
    LGlyph.XSkip := LCursor.ReadInt;
    LGlyph.ImageWidth := LCursor.ReadInt;
    LGlyph.ImageHeight := LCursor.ReadInt;
    LGlyph.S := LCursor.ReadFloat;
    LGlyph.T := LCursor.ReadFloat;
    LGlyph.S2 := LCursor.ReadFloat;
    LGlyph.T2 := LCursor.ReadFloat;
    LGlyph.Glyph := LCursor.ReadInt;
    Move(ABytes[LCursor.Offset], LGlyph.ShaderName[0], SizeOf(LGlyph.ShaderName));
    Inc(LCursor.Offset, SizeOf(LGlyph.ShaderName));
    AFont.Glyphs[LIndex] := LGlyph;
  end;
  AFont.GlyphScale := LCursor.ReadFloat;
  LLength := 0;
  while (LLength < GUI_FONT_NAME_SIZE) and (ABytes[LCursor.Offset + LLength] <> 0) do
    Inc(LLength);
  SetString(LName, PAnsiChar(@ABytes[LCursor.Offset]), LLength);
  AFont.Name := LName;
end;

end.
