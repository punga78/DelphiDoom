{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed - the pictures and the keys on the game host library       }
{  What DirectDraw (i_video.pas) and the window procedure of i_main.pas did     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HostWindow;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGreedFramePresenter and IGreedInput on the window of Libs\GameHost: the pictures go to its display, which
  ///   stretches them AScale times, and the keys come from its key state: arrows or W, S to walk, left and right
  ///   arrows or Q, E to turn, A, D to step aside, Shift to run, Escape to quit
  /// </summary>
  TGreedHostWindow = class(TInterfacedObject, IGreedFramePresenter, IGreedInput)
  strict private
    FDevice: IGameHostVideoDevice;
    FKeys: IGameHostKeyState;
    FPump: TGameHostPump;
    function KeyDown(AFirst: Integer; ASecond: Integer): Boolean;
    class function PaletteOf(const AColors: TGreedColors): TGameHostPalette; static;
  public
    /// <summary>Sets the mode of the display: the client area is AScale times the picture of AWidth x AHeight</summary>
    /// <param name="ADevice">The display in the window of the game</param>
    /// <param name="AKeys">The keys that the window says are down</param>
    /// <param name="APump">Reads the messages of the window</param>
    constructor Create(const ADevice: IGameHostVideoDevice; const AKeys: IGameHostKeyState;
      const APump: TGameHostPump; const ATitle: string; AWidth, AHeight, AScale: Integer);
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

implementation

constructor TGreedHostWindow.Create(const ADevice: IGameHostVideoDevice; const AKeys: IGameHostKeyState;
  const APump: TGameHostPump; const ATitle: string; AWidth, AHeight, AScale: Integer);
var
  LWidth: Integer;
  LHeight: Integer;
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  if not Assigned(APump) then
    raise EArgumentNilException.Create('APump');
  if (AWidth < 1) or (AHeight < 1) or (AScale < 1) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AWidth, AHeight, 'window']);
  FDevice := ADevice;
  FKeys := AKeys;
  FPump := APump;
  LWidth := AWidth * AScale;
  LHeight := AHeight * AScale;
  FDevice.SetTitle(ATitle);
  FDevice.SetMode(LWidth, LHeight, False);
end;

class function TGreedHostWindow.PaletteOf(const AColors: TGreedColors): TGameHostPalette;
var
  LIndex: Integer;
begin
  // $00RRGGBB
  for LIndex := Low(Result) to High(Result) do
  begin
    Result[LIndex].Red := Byte(AColors[LIndex] shr 16);
    Result[LIndex].Green := Byte(AColors[LIndex] shr 8);
    Result[LIndex].Blue := Byte(AColors[LIndex]);
  end;
end;

procedure TGreedHostWindow.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
begin
  if (AFrame.Width < 1) or (AFrame.Height < 1) or (Length(AFrame.Pixels) < AFrame.Width * AFrame.Height) then
    Exit;
  FDevice.Present(AFrame.Pixels, AFrame.Width, AFrame.Height, PaletteOf(AColors));
end;

function TGreedHostWindow.Pump: Boolean;
begin
  Result := FPump();
end;

function TGreedHostWindow.KeyDown(AFirst: Integer; ASecond: Integer): Boolean;
begin
  Result := FKeys.IsDown(AFirst) or ((ASecond >= 0) and FKeys.IsDown(ASecond));
end;

function TGreedHostWindow.IsDown(AKey: TGreedKey): Boolean;
begin
  case AKey of
    gkForward: Result := KeyDown(VK_UP, Ord('W'));
    gkBackward: Result := KeyDown(VK_DOWN, Ord('S'));
    gkTurnLeft: Result := KeyDown(VK_LEFT, Ord('Q'));
    gkTurnRight: Result := KeyDown(VK_RIGHT, Ord('E'));
    gkStrafeLeft: Result := KeyDown(Ord('A'), -1);
    gkStrafeRight: Result := KeyDown(Ord('D'), -1);
    gkRun: Result := KeyDown(VK_SHIFT, -1);
    gkQuit: Result := KeyDown(VK_ESCAPE, -1);
  else
    Result := False;
  end;
end;

end.
