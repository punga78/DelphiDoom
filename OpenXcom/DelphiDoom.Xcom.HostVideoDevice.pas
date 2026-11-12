{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the display of the game on a display of the game host   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostVideoDevice;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.TrueColor.Intf,
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.TrueColor.Intf;

type
  /// <summary>
  ///   IXcomVideoDevice, and the optional interfaces of a window that the screen asks for, on a display of
  ///   Libs\GameHost (the window with GDI or OpenGL): the same calls with the types of the game turned into the
  ///   neutral ones. What the display of the host does not have is ignored (a display that does not scale never
  ///   presents an unscaled picture and says that OpenGL is not in use; one that shows no pictures of colors
  ///   refuses the frames in true color, and the screen presents the 8 bit picture)
  /// </summary>
  TXcomHostVideoDevice = class(TInterfacedObject, IXcomVideoDevice, IXcomWindowStyle, IXcomWindowPlacement,
    IXcomFilteredDisplay, IXcomTrueColorDisplay)
  strict private
    FDevice: IGameHostVideoDevice;
    FFilter: TXcomDisplayFilter;
    class function PaletteOf(const APalette: TXcomColors): TGameHostPalette; static;
    class function ToHost(const AFilter: TXcomDisplayFilter): TGameHostDisplayFilter; static;
    class function FromHost(const AFilter: TGameHostDisplayFilter): TXcomDisplayFilter; static;
  public
    constructor Create(const ADevice: IGameHostVideoDevice);
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    procedure SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
    procedure SetDisplayFilter(const AFilter: TXcomDisplayFilter);
    function DisplayFilter: TXcomDisplayFilter;
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
    function PresentTrueColor(const APixels: TXcomTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

implementation

constructor TXcomHostVideoDevice.Create(const ADevice: IGameHostVideoDevice);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  FDevice := ADevice;
end;

class function TXcomHostVideoDevice.PaletteOf(const APalette: TXcomColors): TGameHostPalette;
var
  LIndex: Integer;
begin
  for LIndex := Low(Result) to High(Result) do
  begin
    Result[LIndex].Red := APalette[LIndex].Red;
    Result[LIndex].Green := APalette[LIndex].Green;
    Result[LIndex].Blue := APalette[LIndex].Blue;
  end;
end;

class function TXcomHostVideoDevice.ToHost(const AFilter: TXcomDisplayFilter): TGameHostDisplayFilter;
begin
  Result.UseOpenGL := AFilter.UseOpenGL;
  Result.Shader := AFilter.Shader;
  Result.Smoothing := AFilter.Smoothing;
  Result.VSync := AFilter.VSync;
end;

class function TXcomHostVideoDevice.FromHost(const AFilter: TGameHostDisplayFilter): TXcomDisplayFilter;
begin
  Result.UseOpenGL := AFilter.UseOpenGL;
  Result.Shader := AFilter.Shader;
  Result.Smoothing := AFilter.Smoothing;
  Result.VSync := AFilter.VSync;
end;

procedure TXcomHostVideoDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  FDevice.SetMode(AWidth, AHeight, AFullscreen);
end;

procedure TXcomHostVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TXcomColors);
begin
  FDevice.Present(APixels, AWidth, AHeight, PaletteOf(APalette));
end;

procedure TXcomHostVideoDevice.SetTitle(const ATitle: string);
begin
  FDevice.SetTitle(ATitle);
end;

procedure TXcomHostVideoDevice.SetWindowStyle(ABorderless, AResizable: Boolean);
var
  LStyle: IGameHostWindowStyle;
begin
  if Supports(FDevice, IGameHostWindowStyle, LStyle) then
    LStyle.SetWindowStyle(ABorderless, AResizable);
end;

procedure TXcomHostVideoDevice.SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
var
  LPlacement: IGameHostWindowPlacement;
begin
  if Supports(FDevice, IGameHostWindowPlacement, LPlacement) then
    LPlacement.SetWindowPlacement(AFixed, AX, AY, ACentered);
end;

procedure TXcomHostVideoDevice.SetDisplayFilter(const AFilter: TXcomDisplayFilter);
var
  LFiltered: IGameHostFilteredDisplay;
begin
  FFilter := AFilter;
  if Supports(FDevice, IGameHostFilteredDisplay, LFiltered) then
    LFiltered.SetDisplayFilter(ToHost(AFilter));
end;

function TXcomHostVideoDevice.DisplayFilter: TXcomDisplayFilter;
var
  LFiltered: IGameHostFilteredDisplay;
begin
  if Supports(FDevice, IGameHostFilteredDisplay, LFiltered) then
    Result := FromHost(LFiltered.DisplayFilter)
  else
  begin
    Result := FFilter;
    Result.UseOpenGL := False;
    Result.Shader := '';
  end;
end;

function TXcomHostVideoDevice.PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TXcomColors; ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
var
  LFiltered: IGameHostFilteredDisplay;
  LBands: TGameHostBlackBands;
begin
  Result := Supports(FDevice, IGameHostFilteredDisplay, LFiltered);
  if not Result then
    Exit;
  LBands.Left := ABands.Left;
  LBands.Right := ABands.Right;
  LBands.Top := ABands.Top;
  LBands.Bottom := ABands.Bottom;
  Result := LFiltered.PresentUnscaled(APixels, AWidth, AHeight, PaletteOf(APalette), ADisplayWidth,
    ADisplayHeight, LBands);
end;

function TXcomHostVideoDevice.PresentTrueColor(const APixels: TXcomTrueColorPixels; AWidth,
  AHeight: Integer): Boolean;
var
  LTrueColor: IGameHostTrueColorDisplay;
begin
  // the two types are the same array of colors: nothing is copied
  Result := Supports(FDevice, IGameHostTrueColorDisplay, LTrueColor) and
    LTrueColor.PresentTrueColor(APixels, AWidth, AHeight);
end;

end.
