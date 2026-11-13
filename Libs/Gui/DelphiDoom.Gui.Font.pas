{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - a font (fontInfo_t)                               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software), GPL v2 or later.}
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Font;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Font.Types;

type
  /// <summary>fontInfo_t: 256 glyphs, a scale and a name</summary>
  TGuiFont = class
  strict private
    FGlyphs: array[0..GUI_GLYPHS_PER_FONT - 1] of TGuiGlyph;
    FGlyphScale: Single;
    FName: AnsiString;
    function GetGlyph(const AIndex: Integer): TGuiGlyph;
    procedure SetGlyph(const AIndex: Integer; const AGlyph: TGuiGlyph);
  public
    /// <summary>A font of zeros</summary>
    constructor Create;
    /// <summary>Copies another font (Com_Memcpy of a fontInfo_t)</summary>
    procedure Assign(const ASource: TGuiFont);
    /// <summary>The shader name of a glyph as text: up to the first zero or 32 characters</summary>
    function ShaderName(const AIndex: Integer): AnsiString;
    property Glyphs[const AIndex: Integer]: TGuiGlyph read GetGlyph write SetGlyph;
    property GlyphScale: Single read FGlyphScale write FGlyphScale;
    property Name: AnsiString read FName write FName;
  end;

implementation

constructor TGuiFont.Create;
begin
  inherited Create;
  FillChar(FGlyphs, SizeOf(FGlyphs), 0);
end;

procedure TGuiFont.Assign(const ASource: TGuiFont);
begin
  FGlyphs := ASource.FGlyphs;
  FGlyphScale := ASource.FGlyphScale;
  FName := ASource.FName;
end;

function TGuiFont.GetGlyph(const AIndex: Integer): TGuiGlyph;
begin
  Result := FGlyphs[AIndex];
end;

procedure TGuiFont.SetGlyph(const AIndex: Integer; const AGlyph: TGuiGlyph);
begin
  FGlyphs[AIndex] := AGlyph;
end;

function TGuiFont.ShaderName(const AIndex: Integer): AnsiString;
var
  LLength: Integer;
begin
  LLength := 0;
  while (LLength < Length(FGlyphs[AIndex].ShaderName)) and (FGlyphs[AIndex].ShaderName[LLength] <> #0) do
    Inc(LLength);
  SetString(Result, PAnsiChar(@FGlyphs[AIndex].ShaderName[0]), LLength);
end;

end.
