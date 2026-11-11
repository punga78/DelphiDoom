{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - what the displays that draw in the window share         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.WindowDevice;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.Xcom.Win.Window;

type
  /// <summary>
  ///   IXcomVideoDevice on the window of the game: the mode, the title and the style go to the window, the picture
  ///   is shown by the class that derives from this one (GDI or OpenGL). The window is not owned and outlives the
  ///   device
  /// </summary>
  TXcomWinWindowDevice = class abstract(TInterfacedObject, IXcomVideoDevice, IXcomWindowStyle)
  strict private
    FWindow: TXcomWinWindow;
  strict protected
    property Window: TXcomWinWindow read FWindow;
  public
    constructor Create(AWindow: TXcomWinWindow);
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean); virtual;
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors); virtual; abstract;
    procedure SetTitle(const ATitle: string);
    /// <summary>IXcomWindowStyle: taken at the next SetMode</summary>
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
  end;

implementation

constructor TXcomWinWindowDevice.Create(AWindow: TXcomWinWindow);
begin
  inherited Create;
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create('AWindow');
  FWindow := AWindow;
end;

procedure TXcomWinWindowDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  FWindow.SetMode(AWidth, AHeight, AFullscreen);
end;

procedure TXcomWinWindowDevice.SetTitle(const ATitle: string);
begin
  FWindow.SetTitle(ATitle);
end;

procedure TXcomWinWindowDevice.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FWindow.SetStyle(ABorderless, AResizable);
end;

end.
