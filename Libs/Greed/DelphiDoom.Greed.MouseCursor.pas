{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the picture of the pointer of the menus          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): mcursor of d_ints.pas       }
{  (M_InitMouse) and I_DrawMouse of i_video.pas                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MouseCursor;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Mouse.Intf;

const
  /// <summary>The lump of the picture of the pointer</summary>
  GREED_LUMP_MOUSE_CURSOR = 'MCURSOR';
  /// <summary>The bytes of the lump before the 256 pixels (the header of a picture)</summary>
  GREED_MOUSE_CURSOR_HEADER_BYTES = 8;

type
  /// <summary>
  ///   The pointer of the menus: the 16 x 16 pixels of the lump MCURSOR (M_InitMouse reads 256 bytes after the 8
  ///   of the header) drawn over the picture that goes to the window, as I_DrawMouse does on the screen of
  ///   640 x 400 after the picture of the game was copied to it. The colors 0 and 255 are not drawn; a pixel of
  ///   the pointer is as large as a pixel of the screen of 320 x 200 (2 x 2 on a frame of 640 x 400), and what
  ///   falls outside the frame is cut. The frame keeps its indexes of the palette: the original writes the color
  ///   of the same index
  /// </summary>
  TGreedMouseCursor = class
  strict private
    FPixels: array[0..GREED_MOUSE_SIZE * GREED_MOUSE_SIZE - 1] of Byte;
  public
    /// <summary>EGreedDataException if the lump has less than 8 + 256 bytes</summary>
    constructor Create(const ALump: TBytes);
    /// <summary>
    ///   Draws the pointer with its top left corner at (APointerX, APointerY) of the screen of 320 x 200. Nothing
    ///   for a frame narrower than 320 pixels
    /// </summary>
    procedure Draw(var AFrame: TGreedFrame; APointerX, APointerY: Single);
  end;

implementation

const
  SCREEN_WIDTH = 320;
  TRANSPARENT_LOW = 0;
  TRANSPARENT_HIGH = 255;

{ TGreedMouseCursor }

constructor TGreedMouseCursor.Create(const ALump: TBytes);
begin
  inherited Create;
  if Length(ALump) < GREED_MOUSE_CURSOR_HEADER_BYTES + SizeOf(FPixels) then
    raise EGreedDataException.CreateFmt(SGreedImageTooShort, [GREED_LUMP_MOUSE_CURSOR, Length(ALump),
      GREED_MOUSE_CURSOR_HEADER_BYTES + SizeOf(FPixels)]);
  Move(ALump[GREED_MOUSE_CURSOR_HEADER_BYTES], FPixels, SizeOf(FPixels));
end;

procedure TGreedMouseCursor.Draw(var AFrame: TGreedFrame; APointerX, APointerY: Single);
var
  LScale: Integer;
  LBaseX: Integer;
  LBaseY: Integer;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LColor: Byte;
begin
  LScale := AFrame.Width div SCREEN_WIDTH;
  if (LScale < 1) or (Length(AFrame.Pixels) < AFrame.Width * AFrame.Height) then
    Exit;
  LBaseX := Round(LScale * APointerX);
  LBaseY := Round(LScale * APointerY);
  for LIndex := 0 to High(FPixels) do
  begin
    LColor := FPixels[LIndex];
    if (LColor = TRANSPARENT_LOW) or (LColor = TRANSPARENT_HIGH) then
      Continue;
    LX := LBaseX + LScale * (LIndex mod GREED_MOUSE_SIZE);
    LY := LBaseY + LScale * (LIndex div GREED_MOUSE_SIZE);
    for LRow := LY to LY + LScale - 1 do
      if (LRow >= 0) and (LRow < AFrame.Height) then
        for LColumn := LX to LX + LScale - 1 do
          if (LColumn >= 0) and (LColumn < AFrame.Width) then
            AFrame.Pixels[LRow * AFrame.Width + LColumn] := LColor;
  end;
end;

end.
