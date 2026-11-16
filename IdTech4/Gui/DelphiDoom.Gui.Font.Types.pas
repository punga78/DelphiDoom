{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - font types (glyphInfo_t)                          }
{                                                                              }
{  Port of glyphInfo_t and fontInfo_t of q_shared.h (Quake III Arena, id       }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Font.Types;

interface

const
  /// <summary>GLYPHS_PER_FONT: the glyphs of codes 0 to 255</summary>
  GUI_GLYPHS_PER_FONT = 256;
  /// <summary>Bytes of one glyph in a .dat file (twelve 4 byte values and the shader name of 32 bytes)</summary>
  GUI_GLYPH_FILE_SIZE = 80;
  /// <summary>MAX_QPATH: bytes of the font name in a .dat file</summary>
  GUI_FONT_NAME_SIZE = 64;
  /// <summary>sizeof(fontInfo_t): the only length RE_RegisterFont accepts for a .dat file (the glyphs alone are 20480)</summary>
  GUI_FONT_FILE_SIZE = GUI_GLYPHS_PER_FONT * GUI_GLYPH_FILE_SIZE + 4 + GUI_FONT_NAME_SIZE;
  /// <summary>MAX_FONTS of tr_font.c</summary>
  GUI_MAX_FONTS = 6;

type
  /// <summary>
  ///   glyphInfo_t: the size and the place in the font image of one character. Packed, no pointers: the same
  ///   80 bytes as the original on disk.
  /// </summary>
  TGuiGlyph = packed record
    Height: Integer;
    Top: Integer;
    Bottom: Integer;
    Pitch: Integer;
    XSkip: Integer;
    ImageWidth: Integer;
    ImageHeight: Integer;
    S: Single;
    T: Single;
    S2: Single;
    T2: Single;
    /// <summary>The handle of the shader with the glyph (qhandle_t)</summary>
    Glyph: Integer;
    ShaderName: array[0..31] of AnsiChar;
  end;

implementation

end.
