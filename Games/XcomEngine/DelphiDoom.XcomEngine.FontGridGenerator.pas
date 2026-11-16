{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - writes the characters of a second source   }
{  as the pictures and the Font.dat of a mod of OpenXcom                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontGridGenerator;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Png.PaletteEncoder.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Intf, DelphiDoom.XcomSurface.FontOverlay.Intf,
  DelphiDoom.XcomEngine.FontRuleReader;

type
  /// <summary>
  ///   The way to other fonts that does not change the program, the one the mods of OpenXcom use: every font of
  ///   Font.dat is loaded, the overlay adds its pictures (the characters of a font of Windows) and each new
  ///   picture is saved as an indexed PNG in Language\ of a folder, with a Font.dat that lists the original
  ///   pictures first and the new ones after them. Loaded from that folder the fonts are the ones the overlay
  ///   makes in memory: the later pictures of a font replace the characters of the earlier ones, and the first
  ///   still gives the line height and the width of a space
  /// </summary>
  TXcomFontGridGenerator = class
  strict private
    FFiles: IXcomFileSystem;
    FLoader: IXcomSurfaceLoader;
    FOverlay: IXcomFontOverlay;
    FEncoder: IPngPaletteEncoder;
    class function Quoted(const AText: string): string; static;
    class function TextOf(const ACodes: TArray<Cardinal>): string; static;
    class procedure AddImage(ALines: TStrings; const AFile: string; AWidth, AHeight, ASpacing: Integer;
      const AChars: string); static;
    function Encode(const AImage: TXcomFontImage): TBytes;
  public
    const
      LANGUAGE_FOLDER = 'Language';
      FONT_FILE = 'Font.dat';
    /// <param name="ALoader">Reads the original pictures (Language\ of the data)</param>
    /// <param name="AOverlay">The second source of the characters</param>
    constructor Create(const AFiles: IXcomFileSystem; const ALoader: IXcomSurfaceLoader;
      const AOverlay: IXcomFontOverlay; const AEncoder: IPngPaletteEncoder);
    /// <summary>The name of the new picture number AImage of a font, counted from 0 (FONT_BIG_0.png)</summary>
    class function FileNameOf(const AFontId: string; AImage: Integer): string; static;
    /// <summary>
    ///   Writes AFolder\Language\Font.dat and the pictures, and gives how many pictures were written (0: the
    ///   overlay changed no font and the Font.dat is the original one written again)
    /// </summary>
    function Generate(const ARules: TArray<TXcomFontRule>; const AFolder: string): Integer;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Png.IndexedImage;

const
  // the grays of the pictures of OpenXcom: the indexes 1 to 5, from the brightest
  GRID_PALETTE: array[0..17] of Byte = (0, 0, 0, 255, 255, 255, 207, 207, 207, 159, 159, 159, 111, 111, 111, 63, 63, 63);

constructor TXcomFontGridGenerator.Create(const AFiles: IXcomFileSystem; const ALoader: IXcomSurfaceLoader;
  const AOverlay: IXcomFontOverlay; const AEncoder: IPngPaletteEncoder);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  if not Assigned(AOverlay) then
    raise EArgumentNilException.Create('AOverlay');
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  FFiles := AFiles;
  FLoader := ALoader;
  FOverlay := AOverlay;
  FEncoder := AEncoder;
end;

class function TXcomFontGridGenerator.FileNameOf(const AFontId: string; AImage: Integer): string;
begin
  Result := Format('%s_%d.png', [AFontId, AImage]);
end;

class function TXcomFontGridGenerator.Quoted(const AText: string): string;
var
  LChar: Char;
begin
  // a double quoted scalar of YAML: only the backslash, the quote and the line feed need an escape
  Result := '"';
  for LChar in AText do
    case LChar of
      '\':
        Result := Result + '\\';
      '"':
        Result := Result + '\"';
      #10:
        Result := Result + '\n';
    else
      Result := Result + LChar;
    end;
  Result := Result + '"';
end;

class function TXcomFontGridGenerator.TextOf(const ACodes: TArray<Cardinal>): string;
var
  LCode: Cardinal;
begin
  Result := '';
  for LCode in ACodes do
    if LCode > $FFFF then
      Result := Result + Char($D800 + (LCode - $10000) shr 10) + Char($DC00 + (LCode - $10000) and $3FF)
    else
      Result := Result + Char(LCode);
end;

class procedure TXcomFontGridGenerator.AddImage(ALines: TStrings; const AFile: string; AWidth, AHeight,
  ASpacing: Integer; const AChars: string);
begin
  ALines.Add('      - file: ' + AFile);
  ALines.Add(Format('        width: %d', [AWidth]));
  ALines.Add(Format('        height: %d', [AHeight]));
  ALines.Add(Format('        spacing: %d', [ASpacing]));
  ALines.Add('        chars: ' + Quoted(AChars));
end;

function TXcomFontGridGenerator.Encode(const AImage: TXcomFontImage): TBytes;
var
  LPalette: TBytes;
begin
  SetLength(LPalette, Length(GRID_PALETTE));
  Move(GRID_PALETTE[0], LPalette[0], Length(GRID_PALETTE));
  Result := FEncoder.Encode(TIndexedImage.Wrap(AImage.Surface.Width, AImage.Surface.Height, AImage.Surface.Pixels),
    LPalette, 0);
end;

function TXcomFontGridGenerator.Generate(const ARules: TArray<TXcomFontRule>; const AFolder: string): Integer;
var
  LLines: TStringList;
  LRule: TXcomFontRule;
  LDefinition: TXcomFontImageDefinition;
  LFont: TXcomFont;
  LOriginalCount: Integer;
  LIndex: Integer;
  LImage: TXcomFontImage;
  LFolder: string;
  LFile: string;
begin
  Result := 0;
  LFolder := TPath.Combine(AFolder, LANGUAGE_FOLDER);
  LLines := TStringList.Create;
  try
    LLines.Add('# made by Xcom32 -fontgrid: the original pictures first, then the characters of the fonts of Windows');
    LLines.Add('fonts:');
    for LRule in ARules do
    begin
      LLines.Add('  - id: ' + LRule.Id);
      LLines.Add(Format('    width: %d', [LRule.Width]));
      LLines.Add(Format('    height: %d', [LRule.Height]));
      LLines.Add(Format('    spacing: %d', [LRule.Spacing]));
      if LRule.Definition.Monospace then
        LLines.Add('    monospace: true');
      LLines.Add('    images:');
      for LDefinition in LRule.Definition.Images do
        AddImage(LLines, LDefinition.FileName, LDefinition.Width, LDefinition.Height, LDefinition.Spacing,
          LDefinition.Chars);
      LFont := TXcomFont.Create;
      try
        LFont.Load(LRule.Definition, FLoader);
        LOriginalCount := LFont.ImageCount;
        FOverlay.Apply(LRule.Id, LFont);
        for LIndex := LOriginalCount to LFont.ImageCount - 1 do
        begin
          LImage := LFont.Image(LIndex);
          LFile := FileNameOf(LRule.Id, LIndex - LOriginalCount);
          FFiles.WriteAll(TPath.Combine(LFolder, LFile), Encode(LImage));
          AddImage(LLines, LFile, LImage.Width, LImage.Height, LImage.Spacing, TextOf(LFont.CodesOfImage(LIndex)));
          Inc(Result);
        end;
      finally
        LFont.Free;
      end;
    end;
    FFiles.WriteAll(TPath.Combine(LFolder, FONT_FILE), TEncoding.UTF8.GetBytes(LLines.Text));
  finally
    LLines.Free;
  end;
end;

end.
