{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiDoomFontLoader, idRenderSystemLocal::         }
{  RegisterFont                                                                }
{                                                                              }
{  Port of the part of renderer\tr_font.cpp (id Software, GPL v3) that reads   }
{  the three fontImage_N.dat files of a font (12, 24 and 48 points); the       }
{  FreeType path that makes the .dat files (BUILD_FREETYPE) is not ported.     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Font.DoomLoader;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.Font.DoomEx;

type
  /// <summary>Reads the .dat files of a font and finds the material of each glyph</summary>
  TGuiDoomFontLoader = class
  public
    /// <summary>
    ///   RegisterFont: <c>AFontName</c> is the folder of the font (<c>fonts/english/bank</c>). False if a size
    ///   is not there or does not have the length of a fontInfo_t, with a warning; the sizes read before stay
    ///   in the font, as in the original. The shader name of a glyph in the file starts 6 characters
    ///   later than in Quake III (the original skips what the embedded fonts keep there).
    /// </summary>
    class function RegisterFont(const AFileSystem: IIdLibFileSystem; const AMaterials: IGuiMaterialLookup;
      const ALog: IIdLibLog; const AFontName: AnsiString; const AFont: TGuiDoomFontEx): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Gui.Font, DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.Font.Doom,
  DelphiDoom.Gui.FontReader, DelphiDoom.Gui.Types;

const
  // GLYPH_START and GLYPH_END of RenderSystem.h
  GLYPH_START = 0;
  GLYPH_END = 255;
  FONT_POINT_SIZES: array[0..2] of Integer = (12, 24, 48);
  SHADER_NAME_SKIP = 6;

procedure Warn(const ALog: IIdLibLog; const AText: string);
begin
  if Assigned(ALog) then
    ALog.Warning(AText);
end;

class function TGuiDoomFontLoader.RegisterFont(const AFileSystem: IIdLibFileSystem; const AMaterials: IGuiMaterialLookup;
  const ALog: IIdLibLog; const AFontName: AnsiString; const AFont: TGuiDoomFontEx): Boolean;
var
  LCount: Integer;
  LPointSize: Integer;
  LName: AnsiString;
  LOut: TGuiDoomFont;
  LFile: TIdLibFileData;
  LGlyph: TGuiGlyph;
  LIndex: Integer;
  LMaxWidth: Integer;
  LMaxHeight: Integer;
  LShader: AnsiString;
  LMaterial: IGuiMaterial;
begin
  Result := False;
  for LCount := 0 to 2 do
  begin
    LPointSize := FONT_POINT_SIZES[LCount];
    LName := AnsiString(Format('%s/fontImage_%d.dat', [string(AFontName), LPointSize]));
    case LCount of
      0: LOut := AFont.FontSmall;
      1: LOut := AFont.FontMedium;
    else
      LOut := AFont.FontLarge;
    end;
    // idStr::Copynz( outFont->name, name, sizeof( outFont->name ) )
    LOut.Info.Name := Copy(LName, 1, GUI_FONT_NAME_SIZE - 1);
    if (not AFileSystem.TryReadFile(LName, False, LFile)) or (Length(LFile.Data) <> GUI_FONT_FILE_SIZE) then
    begin
      Warn(ALog, Format('RegisterFont: couldn''t find font: ''%s''', [string(LName)]));
      Exit;
    end;
    TGuiFontReader.Read(LFile.Data, LOut.Info);
    for LIndex := 0 to GUI_GLYPHS_PER_FONT - 1 do
    begin
      // memcpy( shaderName, &file[offset + 6], 32 - 6 ) into a font of zeros
      LGlyph := LOut.Info.Glyphs[LIndex];
      FillChar(LGlyph.ShaderName, SizeOf(LGlyph.ShaderName), 0);
      Move(LFile.Data[LIndex * GUI_GLYPH_FILE_SIZE + GUI_GLYPH_FILE_SIZE - 32 + SHADER_NAME_SKIP], LGlyph.ShaderName[0],
        32 - SHADER_NAME_SKIP);
      LGlyph.Glyph := 0;
      LOut.Info.Glyphs[LIndex] := LGlyph;
    end;
    LMaxWidth := 0;
    LMaxHeight := 0;
    for LIndex := GLYPH_START to GLYPH_END - 1 do
    begin
      LShader := LOut.Info.ShaderName(LIndex);
      LMaterial := AMaterials.FindMaterial(AFontName + '/' + LShader);
      LOut.Materials[LIndex] := LMaterial;
      if Assigned(LMaterial) then
        LMaterial.SetGuiSort;
      LGlyph := LOut.Info.Glyphs[LIndex];
      if LMaxHeight < LGlyph.Height then
        LMaxHeight := LGlyph.Height;
      if LMaxWidth < LGlyph.XSkip then
        LMaxWidth := LGlyph.XSkip;
    end;
    case LCount of
      0:
        begin
          AFont.MaxWidthSmall := LMaxWidth;
          AFont.MaxHeightSmall := LMaxHeight;
        end;
      1:
        begin
          AFont.MaxWidthMedium := LMaxWidth;
          AFont.MaxHeightMedium := LMaxHeight;
        end;
    else
      AFont.MaxWidthLarge := LMaxWidth;
      AFont.MaxHeightLarge := LMaxHeight;
    end;
  end;
  Result := True;
end;

end.
