{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - what the displays in the window share       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.WindowDevice;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Win.Window;

type
  /// <summary>
  ///   IGameHostVideoDevice on the window of the game: the mode, the title and the style go to the window, the picture
  ///   is shown by the class that derives from this one (GDI or OpenGL). The window is not owned and outlives the
  ///   device
  /// </summary>
  TGameHostWinWindowDevice = class abstract(TInterfacedObject, IGameHostVideoDevice, IGameHostWindowStyle,
    IGameHostWindowPlacement)
  strict private
    FWindow: TGameHostWinWindow;
  strict protected
    property Window: TGameHostWinWindow read FWindow;
  public
    constructor Create(AWindow: TGameHostWinWindow);
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean); virtual;
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette); virtual; abstract;
    procedure SetTitle(const ATitle: string);
    /// <summary>IGameHostWindowStyle: taken at the next SetMode</summary>
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    /// <summary>IGameHostWindowPlacement: taken at the next SetMode</summary>
    procedure SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
  end;

implementation

constructor TGameHostWinWindowDevice.Create(AWindow: TGameHostWinWindow);
begin
  inherited Create;
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create('AWindow');
  FWindow := AWindow;
end;

procedure TGameHostWinWindowDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  FWindow.SetMode(AWidth, AHeight, AFullscreen);
end;

procedure TGameHostWinWindowDevice.SetTitle(const ATitle: string);
begin
  FWindow.SetTitle(ATitle);
end;

procedure TGameHostWinWindowDevice.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FWindow.SetStyle(ABorderless, AResizable);
end;

procedure TGameHostWinWindowDevice.SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
begin
  FWindow.SetPlacement(AFixed, AX, AY, ACentered);
end;

end.
