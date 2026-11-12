{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - a rasterizer without the     }
{  system: every character is a rectangle the test decides                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.FakeRasterizer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf;

type
  /// <summary>
  ///   IXcomGlyphRasterizer of the tests: a character is a full rectangle of DefaultWidth by DefaultHeight at the
  ///   row DefaultTop, unless Define gave it its own; Remove takes a character away from the font
  /// </summary>
  TFakeGlyphRasterizer = class(TInterfacedObject, IXcomGlyphRasterizer)
  strict private
    FGlyphs: TDictionary<Cardinal, TXcomGlyphBitmap>;
    FRemoved: TList<Cardinal>;
  public
    DefaultWidth: Integer;
    DefaultHeight: Integer;
    DefaultTop: Integer;
    /// <summary>How many characters were drawn</summary>
    Rasterized: Integer;
    /// <summary>What Baseline answers</summary>
    BaselineRow: Integer;
    constructor Create(AWidth, AHeight, ATop: Integer);
    destructor Destroy; override;
    /// <summary>A full rectangle of one coverage</summary>
    procedure Define(ACode: Cardinal; AWidth, AHeight, ATop: Integer; ACoverage: Byte = 255);
    /// <summary>The rows as text: a digit is that many ninths of 255, anything else is 0</summary>
    procedure DefineRows(ACode: Cardinal; ATop: Integer; const ARows: array of string);
    procedure Remove(ACode: Cardinal);
    function HasGlyph(ACode: Cardinal): Boolean;
    function Rasterize(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
    function Baseline: Integer;
  end;

  /// <summary>
  ///   IXcomGlyphRasterizerFactory of the tests: gives the rasterizer it was given (the one of ByScale for a
  ///   scale that has one), or none with a reason
  /// </summary>
  TFakeGlyphRasterizerFactory = class(TInterfacedObject, IXcomGlyphRasterizerFactory)
  public
    Rasterizer: IXcomGlyphRasterizer;
    /// <summary>The rasterizer of a scale, by index; nil or missing: Rasterizer</summary>
    ByScale: TArray<IXcomGlyphRasterizer>;
    Reason: string;
    LastFace: TXcomFontFace;
    LastScale: Integer;
    Calls: Integer;
    function CreateRasterizer(const AFace: TXcomFontFace; AScale: Integer; out AReason: string): IXcomGlyphRasterizer;
  end;

implementation

{ TFakeGlyphRasterizer }

constructor TFakeGlyphRasterizer.Create(AWidth, AHeight, ATop: Integer);
begin
  inherited Create;
  FGlyphs := TDictionary<Cardinal, TXcomGlyphBitmap>.Create;
  FRemoved := TList<Cardinal>.Create;
  DefaultWidth := AWidth;
  DefaultHeight := AHeight;
  DefaultTop := ATop;
end;

destructor TFakeGlyphRasterizer.Destroy;
begin
  FGlyphs.Free;
  FRemoved.Free;
  inherited Destroy;
end;

procedure TFakeGlyphRasterizer.Define(ACode: Cardinal; AWidth, AHeight, ATop: Integer; ACoverage: Byte);
var
  LGlyph: TXcomGlyphBitmap;
  LIndex: Integer;
begin
  LGlyph := TXcomGlyphBitmap.Make(AWidth, AHeight, ATop);
  for LIndex := 0 to High(LGlyph.Pixels) do
    LGlyph.Pixels[LIndex] := ACoverage;
  FGlyphs.AddOrSetValue(ACode, LGlyph);
end;

procedure TFakeGlyphRasterizer.DefineRows(ACode: Cardinal; ATop: Integer; const ARows: array of string);
var
  LGlyph: TXcomGlyphBitmap;
  LX: Integer;
  LY: Integer;
  LChar: Char;
begin
  LGlyph := TXcomGlyphBitmap.Make(Length(ARows[0]), Length(ARows), ATop);
  for LY := 0 to High(ARows) do
    for LX := 0 to LGlyph.Width - 1 do
    begin
      LChar := ARows[LY][LX + 1];
      if (LChar >= '1') and (LChar <= '9') then
        LGlyph.Pixels[LY * LGlyph.Width + LX] := Byte((Ord(LChar) - Ord('0')) * 255 div 9);
    end;
  FGlyphs.AddOrSetValue(ACode, LGlyph);
end;

procedure TFakeGlyphRasterizer.Remove(ACode: Cardinal);
begin
  FRemoved.Add(ACode);
end;

function TFakeGlyphRasterizer.HasGlyph(ACode: Cardinal): Boolean;
begin
  Result := not FRemoved.Contains(ACode);
end;

function TFakeGlyphRasterizer.Rasterize(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
var
  LIndex: Integer;
begin
  Inc(Rasterized);
  if FGlyphs.TryGetValue(ACode, AGlyph) then
    Exit(AGlyph.Width > 0);
  AGlyph := TXcomGlyphBitmap.Make(DefaultWidth, DefaultHeight, DefaultTop);
  for LIndex := 0 to High(AGlyph.Pixels) do
    AGlyph.Pixels[LIndex] := 255;
  Result := True;
end;

function TFakeGlyphRasterizer.Baseline: Integer;
begin
  Result := BaselineRow;
end;

{ TFakeGlyphRasterizerFactory }

function TFakeGlyphRasterizerFactory.CreateRasterizer(const AFace: TXcomFontFace; AScale: Integer;
  out AReason: string): IXcomGlyphRasterizer;
begin
  Inc(Calls);
  LastFace := AFace;
  LastScale := AScale;
  AReason := Reason;
  Result := Rasterizer;
  if (AScale >= 0) and (AScale < Length(ByScale)) and Assigned(ByScale[AScale]) then
    Result := ByScale[AScale];
end;

end.
