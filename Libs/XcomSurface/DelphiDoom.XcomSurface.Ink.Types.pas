{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the types of the text drawn at the        }
{  resolution of the display (issue 184): a character with its coverage and a   }
{  buffer of ink that a composer of colors lays over the picture of the game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Ink.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   One value per pixel of the display: two inks, each a palette index and how much it covers the pixel. The
  ///   back ink (the outline of a character) is laid first, the front ink (its body) over it; the colors are the
  ///   ones the palette has when the frame is composed. From the top byte: front alpha, front index, back alpha,
  ///   back index. 0 is no ink
  /// </summary>
  TXcomInkPixel = Cardinal;

  TXcomInkPixels = TArray<TXcomInkPixel>;

  /// <summary>
  ///   A character drawn at the resolution of the display: the rectangle that has ink, where it goes in the cell
  ///   of the character (in pixels of the display, from the corner of the cell; it may start before it) and, for
  ///   every pixel, how much the body covers it and how much the outline does
  /// </summary>
  TXcomDetailGlyph = record
    Width: Integer;
    Height: Integer;
    Left: Integer;
    Top: Integer;
    /// <summary>The coverage of the body, 0 to 255</summary>
    Body: TBytes;
    /// <summary>The coverage of the outline, 0 to 255; empty when the font has no outline</summary>
    Outline: TBytes;
    /// <summary>The level of the game each pixel of the outline has (4 beside the body, 5 on its corners)</summary>
    OutlineLevel: TBytes;
  end;

  /// <summary>
  ///   The ink of a widget: Scale x Scale values for every pixel of the widget in the picture of the game, and
  ///   for every pixel of the game whether any of its values has ink (so who composes skips the rest)
  /// </summary>
  TXcomInkBuffer = record
    Scale: Integer;
    /// <summary>The size of the widget in pixels of the game</summary>
    Width: Integer;
    Height: Integer;
    /// <summary>Width * Scale values per row, Height * Scale rows</summary>
    Pixels: TXcomInkPixels;
    /// <summary>Width * Height: not 0 where the pixel of the game has ink</summary>
    Cells: TBytes;
    class function Make(AWidth, AHeight, AScale: Integer): TXcomInkBuffer; static;
    /// <summary>True when nothing was painted (or the buffer was never made)</summary>
    function IsEmpty: Boolean;
    /// <summary>Lays an ink over what the pixel has: of each of the two inks the one that covers more stays</summary>
    procedure Put(AX, AY: Integer; AValue: TXcomInkPixel);
    class function Pack(AFrontIndex, AFrontAlpha, ABackIndex, ABackAlpha: Byte): TXcomInkPixel; static; inline;
  end;

implementation

class function TXcomInkBuffer.Make(AWidth, AHeight, AScale: Integer): TXcomInkBuffer;
begin
  Result.Scale := AScale;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Pixels := nil;
  Result.Cells := nil;
  if (AWidth > 0) and (AHeight > 0) and (AScale > 0) then
  begin
    SetLength(Result.Pixels, AWidth * AScale * AHeight * AScale);
    SetLength(Result.Cells, AWidth * AHeight);
  end;
end;

function TXcomInkBuffer.IsEmpty: Boolean;
var
  LCell: Byte;
begin
  for LCell in Cells do
    if LCell <> 0 then
      Exit(False);
  Result := True;
end;

class function TXcomInkBuffer.Pack(AFrontIndex, AFrontAlpha, ABackIndex, ABackAlpha: Byte): TXcomInkPixel;
begin
  Result := (Cardinal(AFrontAlpha) shl 24) or (Cardinal(AFrontIndex) shl 16) or (Cardinal(ABackAlpha) shl 8) or
    ABackIndex;
end;

procedure TXcomInkBuffer.Put(AX, AY: Integer; AValue: TXcomInkPixel);
var
  LIndex: Integer;
  LOld: TXcomInkPixel;
  LNew: TXcomInkPixel;
begin
  if (AValue = 0) or (AX < 0) or (AY < 0) or (AX >= Width * Scale) or (AY >= Height * Scale) then
    Exit;
  LIndex := AY * Width * Scale + AX;
  LOld := Pixels[LIndex];
  if LOld = 0 then
    LNew := AValue
  else
  begin
    // the body of a character is never hidden by the outline of the next one: each ink keeps its strongest
    if (AValue shr 24) > (LOld shr 24) then
      LNew := AValue and $FFFF0000
    else
      LNew := LOld and $FFFF0000;
    if ((AValue shr 8) and $FF) > ((LOld shr 8) and $FF) then
      LNew := LNew or (AValue and $FFFF)
    else
      LNew := LNew or (LOld and $FFFF);
  end;
  Pixels[LIndex] := LNew;
  Cells[(AY div Scale) * Width + AX div Scale] := 1;
end;

end.
