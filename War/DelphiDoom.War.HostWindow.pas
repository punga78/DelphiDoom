{******************************************************************************}
{                                                                              }
{  Warcraft32: the picture of the game in a window of Libs\GameHost            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.HostWindow;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.TrueColor.Intf,
  DelphiDoom.War.App.Intf;

type
  /// <summary>
  ///   IWarFramePresenter on the display of a window: the picture of colors goes to IGameHostTrueColorDisplay, which
  ///   stretches it to the size of the window (the GDI display does). The title of the window says what the program
  ///   wants to say to the player
  /// </summary>
  TWarHostWindow = class(TInterfacedObject, IWarFramePresenter)
  strict private
    FDevice: IGameHostVideoDevice;
    FTrueColor: IGameHostTrueColorDisplay;
    FTitle: string;
  public
    /// <summary>
    ///   The window is AWidth x AHeight pixels (the picture times the scale); EGameHostException if the display cannot
    ///   show pictures of colors
    /// </summary>
    constructor Create(const ADevice: IGameHostVideoDevice; const ATitle: string; AWidth, AHeight: Integer);
    procedure Present(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
    procedure SetStatus(const AText: string);
  end;

implementation

resourcestring
  SWarHostNoTrueColor = 'The display of the window cannot show pictures of colors';

{ TWarHostWindow }

constructor TWarHostWindow.Create(const ADevice: IGameHostVideoDevice; const ATitle: string; AWidth, AHeight: Integer);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  FDevice := ADevice;
  if not Supports(FDevice, IGameHostTrueColorDisplay, FTrueColor) then
    raise EGameHostException.Create(SWarHostNoTrueColor);
  FTitle := ATitle;
  FDevice.SetTitle(FTitle);
  FDevice.SetMode(AWidth, AHeight, False);
end;

procedure TWarHostWindow.Present(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
begin
  FTrueColor.PresentTrueColor(APixels, AWidth, AHeight);
end;

procedure TWarHostWindow.SetStatus(const AText: string);
begin
  if AText = '' then
    FDevice.SetTitle(FTitle)
  else
    FDevice.SetTitle(FTitle + ' - ' + AText);
end;

end.
