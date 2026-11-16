{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the picture and of the input    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): what DirectDraw (i_video)   }
{  and the keyboard (i_main) did, behind interfaces                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Frame.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.World.Intf;

type
  /// <summary>
  ///   A picture of the game as the original makes it: 8 bit pixels (an index in the palette), a row after the
  ///   other from the top (the renderbuffer). The window turns it into colors and shows it
  /// </summary>
  TGreedFrame = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
    /// <summary>A frame of this size, all index 0</summary>
    class function Make(AWidth, AHeight: Integer): TGreedFrame; static;
  end;

  /// <summary>The 256 colors of the palette as $00RRGGBB (the palette of the game after the converter)</summary>
  TGreedColors = array[0..255] of Cardinal;

  /// <summary>The keys that the game reads</summary>
  TGreedKey = (gkForward, gkBackward, gkTurnLeft, gkTurnRight, gkStrafeLeft, gkStrafeRight, gkRun, gkQuit);

  /// <summary>Where the pictures go: a window (DirectDraw in the original)</summary>
  IGreedFramePresenter = interface
    ['{C6A21E58-94D3-4F07-B1A8-5E3D07F9C2B4}']
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
  end;

  /// <summary>What the player presses</summary>
  IGreedInput = interface
    ['{1B8D4F63-E7A0-4C95-8D32-A06F95E1B7C8}']
    /// <summary>Takes the events of the system; False when the user wants to close the program</summary>
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

  /// <summary>Draws the level seen by the player into a frame (RF_RenderView in the original)</summary>
  IGreedFrameRenderer = interface
    ['{F2540C97-3AE1-4B6D-9E83-D17B0A5C6E29}']
    procedure Render(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; var AFrame: TGreedFrame);
  end;

implementation

{ TGreedFrame }

class function TGreedFrame.Make(AWidth, AHeight: Integer): TGreedFrame;
begin
  if (AWidth < 1) or (AHeight < 1) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AWidth, AHeight, 'frame']);
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, AWidth * AHeight);
end;

end.
