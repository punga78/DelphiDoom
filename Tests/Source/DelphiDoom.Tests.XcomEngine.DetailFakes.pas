{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom engine library - the fakes of the tests of     }
{  the text at the resolution of the display (a display that says its scale,    }
{  a font detail made of full rectangles, ink layers that keep what they get)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.DetailFakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.FontDetail.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>IXcomDetailLayers that only says a scale</summary>
  TFakeDetailDisplay = class(TInterfacedObject, IXcomDetailLayers)
  public
    ScaleValue: Integer;
    constructor Create(AScale: Integer);
    function DetailScale: Integer;
    procedure BeginLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
    procedure EndLayer(ABase, ADetail: TXcomSurface);
  end;

  /// <summary>What a widget left with one BeginInk and EndInk</summary>
  TFakeInkLayer = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
    Ended: Boolean;
    Ink: TXcomInkBuffer;
    Under: TBytes;
  end;

  /// <summary>IXcomInkLayers that accepts the ink left on one surface (Base) and keeps it</summary>
  TFakeInkLayers = class(TInterfacedObject, IXcomInkLayers)
  public
    Base: TXcomSurface;
    Layers: TList<TFakeInkLayer>;
    /// <summary>How many times BeginInk was asked, accepted or not</summary>
    Asked: Integer;
    constructor Create;
    destructor Destroy; override;
    function BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
    procedure EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
    function Last: TFakeInkLayer;
  end;

  /// <summary>
  ///   IXcomFontDetail of the tests: every character of the font is its picture times the scale, each pixel fully
  ///   covered, at the corner of the cell (so the ink is exactly where the text of the game is); the codes in
  ///   Missing have none
  /// </summary>
  TFakeFontDetail = class(TInterfacedObject, IXcomFontDetail)
  strict private
    FFont: TXcomFont;
    FLayers: IXcomInkLayers;
  public
    ScaleValue: Integer;
    Missing: TList<Cardinal>;
    Asked: Integer;
    /// <param name="AFont">Not owned</param>
    constructor Create(AFont: TXcomFont; const ALayers: IXcomInkLayers; AScale: Integer);
    destructor Destroy; override;
    function Scale: Integer;
    function TryGetGlyph(ACode: Cardinal; out AGlyph: TXcomDetailGlyph): Boolean;
    function Layers: IXcomInkLayers;
  end;

implementation

{ TFakeDetailDisplay }

constructor TFakeDetailDisplay.Create(AScale: Integer);
begin
  inherited Create;
  ScaleValue := AScale;
end;

function TFakeDetailDisplay.DetailScale: Integer;
begin
  Result := ScaleValue;
end;

procedure TFakeDetailDisplay.BeginLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
begin
  // the tests of the text leave no layer of indexes
end;

procedure TFakeDetailDisplay.EndLayer(ABase, ADetail: TXcomSurface);
begin
  // as BeginLayer
end;

{ TFakeInkLayers }

constructor TFakeInkLayers.Create;
begin
  inherited Create;
  Layers := TList<TFakeInkLayer>.Create;
end;

destructor TFakeInkLayers.Destroy;
begin
  Layers.Free;
  inherited Destroy;
end;

function TFakeInkLayers.BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
var
  LLayer: TFakeInkLayer;
begin
  Inc(Asked);
  Result := Assigned(Base) and (ABase = Base);
  if not Result then
    Exit;
  LLayer := Default(TFakeInkLayer);
  LLayer.X := AX;
  LLayer.Y := AY;
  LLayer.Width := AWidth;
  LLayer.Height := AHeight;
  Layers.Add(LLayer);
end;

procedure TFakeInkLayers.EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
var
  LLayer: TFakeInkLayer;
begin
  LLayer := Layers.Last;
  LLayer.Ended := True;
  LLayer.Ink := AInk;
  LLayer.Under := AUnder;
  Layers[Layers.Count - 1] := LLayer;
end;

function TFakeInkLayers.Last: TFakeInkLayer;
begin
  Result := Layers.Last;
end;

{ TFakeFontDetail }

constructor TFakeFontDetail.Create(AFont: TXcomFont; const ALayers: IXcomInkLayers; AScale: Integer);
begin
  inherited Create;
  FFont := AFont;
  FLayers := ALayers;
  ScaleValue := AScale;
  Missing := TList<Cardinal>.Create;
end;

destructor TFakeFontDetail.Destroy;
begin
  Missing.Free;
  inherited Destroy;
end;

function TFakeFontDetail.Scale: Integer;
begin
  Result := ScaleValue;
end;

function TFakeFontDetail.Layers: IXcomInkLayers;
begin
  Result := FLayers;
end;

function TFakeFontDetail.TryGetGlyph(ACode: Cardinal; out AGlyph: TXcomDetailGlyph): Boolean;
var
  LChar: TXcomFontChar;
  LX: Integer;
  LY: Integer;
begin
  Inc(Asked);
  AGlyph := Default(TXcomDetailGlyph);
  if Missing.Contains(ACode) or not FFont.TryGetChar(ACode, LChar) then
    Exit(False);
  AGlyph.Width := LChar.Rect.W * ScaleValue;
  AGlyph.Height := LChar.Rect.H * ScaleValue;
  SetLength(AGlyph.Body, AGlyph.Width * AGlyph.Height);
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
      if FFont.ImageSurface(LChar.ImageIndex).GetPixel(LChar.Rect.X + LX div ScaleValue,
        LChar.Rect.Y + LY div ScaleValue) <> 0 then
        AGlyph.Body[LY * AGlyph.Width + LX] := 255;
  Result := True;
end;

end.
