{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - the ink of a widget that draws text:    }
{  what it leaves to the screen around its blit so that the text is shown at    }
{  the resolution of the display (issue 184)                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.WidgetInk;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Ink.Types,
  DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomUi.TextInk;

type
  /// <summary>
  ///   A widget that is copied on the screen with text in it (a text, a button, a list, an edit box) keeps one:
  ///   when it draws itself it starts again (Reset) and adds the characters of its texts (Add); when it is copied
  ///   on the screen it brackets the copy with BeginLayer and EndLayer. Nothing is kept, and nothing happens,
  ///   when no text has a font with characters at the resolution of the display
  /// </summary>
  TXcomWidgetInk = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FScale: Integer;
    FBuffer: TXcomInkBuffer;
    FUnder: TBytes;
    FLayers: IXcomInkLayers;
    FHasInk: Boolean;
  public
    /// <summary>
    ///   The widget is drawn again: its size in pixels of the game and the scale its fonts have now (0: none), so
    ///   that the owner can tell when the display changed (Scale)
    /// </summary>
    procedure Reset(AWidth, AHeight, AScale: Integer);
    /// <summary>The characters of a text (nil: nothing) that is at (AX, AY) in the widget and has this size</summary>
    procedure Add(AInk: TXcomTextInk; AX, AY, AWidth, AHeight: Integer);
    /// <summary>
    ///   The pixels of the widget without its text (a button: its face), that show where the text of the picture
    ///   is taken away; a copy is kept only when the widget can have ink
    /// </summary>
    procedure SetUnder(const APixels: TBytes);
    property Scale: Integer read FScale;
    property HasInk: Boolean read FHasInk;
    /// <summary>Before the copy on ATarget at (AX, AY); false: no ink, or not on the screen (no EndLayer then)</summary>
    function BeginLayer(ATarget: TXcomSurface; AX, AY: Integer): Boolean;
    procedure EndLayer(ATarget: TXcomSurface);
  end;

implementation

procedure TXcomWidgetInk.Reset(AWidth, AHeight, AScale: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FScale := AScale;
  FBuffer := Default(TXcomInkBuffer);
  FUnder := nil;
  FLayers := nil;
  FHasInk := False;
end;

procedure TXcomWidgetInk.Add(AInk: TXcomTextInk; AX, AY, AWidth, AHeight: Integer);
begin
  if (not Assigned(AInk)) or (AInk.Count = 0) or (AInk.Scale <> FScale) or (FScale < 2) then
    Exit;
  if not FHasInk then
  begin
    FBuffer := TXcomInkBuffer.Make(FWidth, FHeight, FScale);
    FLayers := AInk.Layers;
    FHasInk := True;
  end;
  AInk.PaintTo(FBuffer, AX, AY, AWidth, AHeight);
end;

procedure TXcomWidgetInk.SetUnder(const APixels: TBytes);
begin
  FUnder := nil;
  if (FScale >= 2) and (Length(APixels) = FWidth * FHeight) then
    FUnder := Copy(APixels);
end;

function TXcomWidgetInk.BeginLayer(ATarget: TXcomSurface; AX, AY: Integer): Boolean;
begin
  Result := FHasInk and Assigned(FLayers) and FLayers.BeginInk(ATarget, AX, AY, FWidth, FHeight);
end;

procedure TXcomWidgetInk.EndLayer(ATarget: TXcomSurface);
begin
  FLayers.EndInk(ATarget, FBuffer, FUnder);
end;

end.
