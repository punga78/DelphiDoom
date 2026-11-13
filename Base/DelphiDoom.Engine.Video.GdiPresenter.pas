{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the frame of the software renderer in the window with   }
{  GDI (the step of Libs\GameHost), instead of the blit of DirectDraw           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Video.GdiPresenter;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Types,
  DelphiDoom.Engine.Video.FramePresenter.Intf;

type
  /// <summary>
  ///   IEngineFramePresenter on GDI. The window is the one of the engine, read each time (it is created after the
  ///   composition): the device context is taken and given back for each frame
  /// </summary>
  TEngineGdiFramePresenter = class(TInterfacedObject, IEngineFramePresenter)
  strict private
    FWindow: TFunc<THandle>;
  public
    /// <param name="AWindow">Gives the window of the game; 0 when there is none yet</param>
    constructor Create(const AWindow: TFunc<THandle>);
    procedure Present(AFrame: Pointer; AWidth, AHeight: Integer; const ADestination: TRect; ATimes: Integer);
  end;

implementation

uses
  DelphiDoom.GameHost.Win.GdiBlitter;

{ TEngineGdiFramePresenter }

constructor TEngineGdiFramePresenter.Create(const AWindow: TFunc<THandle>);
begin
  inherited Create;
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create('AWindow');
  FWindow := AWindow;
end;

procedure TEngineGdiFramePresenter.Present(AFrame: Pointer; AWidth, AHeight: Integer; const ADestination: TRect;
  ATimes: Integer);
var
  LWindow: HWND;
  LDevice: HDC;
  LIndex: Integer;
begin
  LWindow := FWindow();
  if LWindow = 0 then
    Exit;
  LDevice := GetDC(LWindow);
  if LDevice = 0 then
    Exit;
  try
    for LIndex := 1 to ATimes do
      TGameHostWinGdiBlitter.Draw(LDevice, AFrame, AWidth, AHeight, ADestination);
  finally
    ReleaseDC(LWindow, LDevice);
  end;
end;

end.
