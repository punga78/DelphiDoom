{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the canvas the interface is drawn on              }
{                                                                              }
{  Port of war1 (acoto87/war1), what war_game.c (wg_renderGame) and            }
{  war_imui.c ask of SDL3 and of the fonts (context->renderer, fontSprites),   }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\              }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Canvas;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Blitter, DelphiDoom.War.Render.Transform, DelphiDoom.War.Font.Types,
  DelphiDoom.War.Font.Intf, DelphiDoom.War.Text.Types, DelphiDoom.War.Text.Intf, DelphiDoom.War.Text.Renderer,
  DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The picture (a RGBA canvas, 320 x 200 in the game), the stack of transforms, the two fonts (data and image)
  ///   and what draws a text with them. The fonts are drawn as the transform draws a sprite: no call through an
  ///   interface for each glyph
  /// </summary>
  TWarUiCanvas = class
  strict private
    FBlitter: TWarImageBlitter;
    FTransform: TWarRenderTransform;
    FTextRenderer: TWarTextRenderer;
    FMetrics: IWarFontMetrics;
    FFontImages: TArray<TWarImage>;
  public
    /// <summary>The images of the fonts are the ones of war1_font_1.png and war1_font_2.png (an empty image draws nothing)</summary>
    constructor Create(AWidth, AHeight: Integer; const AMetrics: IWarFontMetrics; const AFontImages: TArray<TWarImage>);
    destructor Destroy; override;
    /// <summary>SDL_SetRenderDrawColor(0, 0, 0, 255) and SDL_RenderClear</summary>
    procedure Clear;
    /// <summary>wr_init: the transform is back at the origin, scale 1, opaque</summary>
    procedure ResetTransform;
    /// <summary>getFontData; EWarException for a font that is not 0 or 1 (the original logged and read the image of a font that is not there)</summary>
    function FontData(AFontIndex: Integer): TWarFontData;
    /// <summary>wfont_renderSingleSpriteText or wfont_renderMultiSpriteText with the image of the font of the parameters</summary>
    procedure RenderText(const AText: AnsiString; AX, AY: Single; AFontIndex: Integer; const AParams: TWarFontParams;
      AMultiline: Boolean);
    /// <summary>Where the texts read the debug flag "font" (nil: off)</summary>
    procedure SetTextDebug(const ADebug: IWarTextDebug);
    property Transform: TWarRenderTransform read FTransform;
    property Blitter: TWarImageBlitter read FBlitter;
  end;

implementation

{ TWarUiCanvas }

constructor TWarUiCanvas.Create(AWidth, AHeight: Integer; const AMetrics: IWarFontMetrics;
  const AFontImages: TArray<TWarImage>);
begin
  inherited Create;
  FMetrics := AMetrics;
  FFontImages := AFontImages;
  FBlitter := TWarImageBlitter.Create(AWidth, AHeight);
  FTransform := TWarRenderTransform.Create(FBlitter);
  FTextRenderer := TWarTextRenderer.Create(FTransform);
end;

destructor TWarUiCanvas.Destroy;
begin
  FTextRenderer.Free;
  FTransform.Free;
  FBlitter.Free;
  inherited Destroy;
end;

procedure TWarUiCanvas.SetTextDebug(const ADebug: IWarTextDebug);
begin
  FTextRenderer.Debug := ADebug;
end;

procedure TWarUiCanvas.Clear;
var
  LBlack: TWarRgba;
begin
  LBlack.R := 0;
  LBlack.G := 0;
  LBlack.B := 0;
  LBlack.A := 255;
  FBlitter.Clear(LBlack);
end;

procedure TWarUiCanvas.ResetTransform;
begin
  FTransform.Reset;
end;

function TWarUiCanvas.FontData(AFontIndex: Integer): TWarFontData;
begin
  if not FMetrics.TryGetFont(AFontIndex, Result) then
    raise EWarException.CreateFmt(SWarUiFontIndex, [AFontIndex]);
end;

procedure TWarUiCanvas.RenderText(const AText: AnsiString; AX, AY: Single; AFontIndex: Integer;
  const AParams: TWarFontParams; AMultiline: Boolean);
begin
  if (AFontIndex < 0) or (AFontIndex >= Length(FFontImages)) then
    raise EWarException.CreateFmt(SWarUiFontIndex, [AFontIndex]);
  FTransform.SetTexture(FFontImages[AFontIndex]);
  try
    if AMultiline then
      FTextRenderer.RenderMulti(AText, AX, AY, AParams)
    else
      FTextRenderer.RenderSingle(AText, AX, AY, AParams);
  finally
    FTransform.ClearTexture;
  end;
end;

end.
