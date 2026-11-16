{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the picture that the EGA card shows, with its     }
{  colors                                                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ScreenPicture;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

type
  /// <summary>The 16 colors of a picture as red, green and blue (8 bits each), three bytes a color</summary>
  TKeenScreenColors = array[0..15] of Cardinal;

  /// <summary>
  ///   What a monitor shows of the video memory, for a program that draws it in a window: the 320x200 pixels from
  ///   the start address and the pel panning of the video manager (as TKeenDisplayCapture gives them, but from a
  ///   copy of the four planes: a picture for each tic of the game must be quick) and the colors that the palette
  ///   registers give to the 16 numbers of a pixel, which is how the game fades
  /// </summary>
  TKeenScreenPicture = class
  public
    /// <summary>The picture of the screen: a byte (0..15) for each pixel, rows from the top</summary>
    class function Capture(const AVideo: IKeenVideo): TKeenChunkyImage; static;
    /// <summary>The color of each number of a pixel with the registers of a fader, as $00RRGGBB</summary>
    class function Colors(const ARegisters: TKeenPaletteRegisters): TKeenScreenColors; static;
  end;

implementation

uses
  DelphiDoom.Keen.Fader;

{ TKeenScreenPicture }

class function TKeenScreenPicture.Capture(const AVideo: IKeenVideo): TKeenChunkyImage;
var
  LPlanes: array[0..KEEN_EGA_PLANES - 1] of TBytes;
  LPlane: Integer;
  LX: Integer;
  LY: Integer;
  LRowStart: Integer;
  LByte: Integer;
  LBit: Integer;
  LShift: Integer;
  LPosition: Integer;
  LPixel: Integer;
  LPan: Integer;
  LLineWidth: Integer;
  LStart: Integer;
begin
  if not Assigned(AVideo) then
    raise EArgumentNilException.Create('AVideo');
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    LPlanes[LPlane] := AVideo.Memory.PlaneBytes(LPlane);
  LPan := AVideo.PelPan;
  LLineWidth := AVideo.LineWidth;
  LStart := AVideo.CrtcStart;
  Result.Width := KEEN_DISPLAY_WIDTH;
  Result.Height := KEEN_DISPLAY_HEIGHT;
  SetLength(Result.Pixels, KEEN_DISPLAY_WIDTH * KEEN_DISPLAY_HEIGHT);
  LPixel := 0;
  for LY := 0 to KEEN_DISPLAY_HEIGHT - 1 do
  begin
    LRowStart := LStart + LY * LLineWidth;
    for LX := 0 to KEEN_DISPLAY_WIDTH - 1 do
    begin
      LPosition := LX + LPan;
      LByte := (LRowStart + (LPosition shr 3)) and (KEEN_EGA_PLANE_BYTES - 1);
      LBit := $80 shr (LPosition and 7);
      LShift := 0;
      if (LPlanes[0][LByte] and LBit) <> 0 then
        LShift := 1;
      if (LPlanes[1][LByte] and LBit) <> 0 then
        LShift := LShift or 2;
      if (LPlanes[2][LByte] and LBit) <> 0 then
        LShift := LShift or 4;
      if (LPlanes[3][LByte] and LBit) <> 0 then
        LShift := LShift or 8;
      Result.Pixels[LPixel] := Byte(LShift);
      Inc(LPixel);
    end;
  end;
end;

class function TKeenScreenPicture.Colors(const ARegisters: TKeenPaletteRegisters): TKeenScreenColors;
var
  LIndex: Integer;
begin
  for LIndex := Low(Result) to High(Result) do
    Result[LIndex] := TKeenFader.RegisterColor(ARegisters[LIndex]);
end;

end.
