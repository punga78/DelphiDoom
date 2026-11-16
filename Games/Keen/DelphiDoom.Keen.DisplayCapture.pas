{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - what the EGA shows                                }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.DisplayCapture;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The picture of the screen of 320x200 pixels as the card makes it from the video memory: the start
  ///   address (VW_SetScreen), the width of a row of the virtual screen and the pel panning, which moves the
  ///   picture left by 0 to 7 pixels
  /// </summary>
  TKeenDisplayCapture = class
  public
    /// <summary>The 320x200 image with the EGA colors 0..15</summary>
    class function Capture(const AMemory: IKeenEgaMemory; AStart, APelPan,
      ALineWidth: Integer): TKeenChunkyImage; static;
    /// <summary>The picture of the screen that a video manager shows (its last VW_SetScreen)</summary>
    class function CaptureVideo(const AVideo: IKeenVideo): TKeenChunkyImage; static;
  end;

implementation

{ TKeenDisplayCapture }

class function TKeenDisplayCapture.Capture(const AMemory: IKeenEgaMemory; AStart, APelPan,
  ALineWidth: Integer): TKeenChunkyImage;
var
  LX: Integer;
  LY: Integer;
  LPlane: Integer;
  LByte: Integer;
  LBit: Integer;
  LColor: Byte;
  LRowStart: Integer;
begin
  if not Assigned(AMemory) then
    raise EArgumentNilException.Create('AMemory');
  Result.Width := KEEN_DISPLAY_WIDTH;
  Result.Height := KEEN_DISPLAY_HEIGHT;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  for LY := 0 to Result.Height - 1 do
  begin
    LRowStart := AStart + LY * ALineWidth;
    for LX := 0 to Result.Width - 1 do
    begin
      LByte := LRowStart + (LX + APelPan) div 8;
      LBit := 7 - ((LX + APelPan) and 7);
      LColor := 0;
      for LPlane := 0 to KEEN_EGA_PLANES - 1 do
        LColor := Byte(LColor or (((AMemory.ReadByte(LPlane, LByte) shr LBit) and 1) shl LPlane));
      Result.Pixels[LY * Result.Width + LX] := LColor;
    end;
  end;
end;

class function TKeenDisplayCapture.CaptureVideo(const AVideo: IKeenVideo): TKeenChunkyImage;
begin
  if not Assigned(AVideo) then
    raise EArgumentNilException.Create('AVideo');
  Result := Capture(AVideo.Memory, AVideo.CrtcStart, AVideo.PelPan, AVideo.LineWidth);
end;

end.
