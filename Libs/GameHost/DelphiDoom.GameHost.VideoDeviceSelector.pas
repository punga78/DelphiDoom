{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the choice of the display (GDI or OpenGL)   }
{  What Screen::resetDisplay of OpenXcom did with SDL_OPENGL: the display      }
{  follows the filter each time the mode is set, and goes back to the plain    }
{  one when the OpenGL one cannot be made                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.VideoDeviceSelector;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf;

type
  /// <summary>
  ///   The display the game sees: one of two displays made by the factories it is given, chosen at every SetMode by
  ///   the filter the screen gave before it. The plain display is the default; the OpenGL one is made when the
  ///   filter asks for it, and when its SetMode raises EGameHostVideoDeviceException the reason goes to the log and
  ///   the plain display takes its place (DisplayFilter then says that OpenGL is not in use). A display is released
  ///   before the other is made, because they share the window
  /// </summary>
  TGameHostVideoDeviceSelector = class(TInterfacedObject, IGameHostVideoDevice, IGameHostWindowStyle,
    IGameHostWindowPlacement, IGameHostFilteredDisplay)
  strict private
    FPlainFactory: TGameHostVideoDeviceFactory;
    FOpenGlFactory: TGameHostVideoDeviceFactory;
    FLog: ILog;
    FDevice: IGameHostVideoDevice;
    FDeviceIsOpenGl: Boolean;
    FFilter: TGameHostDisplayFilter;
    FHasStyle: Boolean;
    FBorderless: Boolean;
    FResizable: Boolean;
    FHasPlacement: Boolean;
    FPlacementFixed: Boolean;
    FPlacementCentered: Boolean;
    FPlacementX: Integer;
    FPlacementY: Integer;
    FHasTitle: Boolean;
    FTitle: string;
    procedure Use(AOpenGl: Boolean);
  public
    /// <param name="APlainFactory">Makes the display that always works (GDI)</param>
    /// <param name="AOpenGlFactory">Makes the OpenGL display; nil when the program has none</param>
    /// <param name="ALog">Where the reason of a fallback goes; nil for nowhere</param>
    constructor Create(const APlainFactory, AOpenGlFactory: TGameHostVideoDeviceFactory; const ALog: ILog = nil);
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette);
    procedure SetTitle(const ATitle: string);
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    /// <summary>IGameHostWindowPlacement: kept and given to the display that takes the next mode</summary>
    procedure SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
    procedure SetDisplayFilter(const AFilter: TGameHostDisplayFilter);
    function DisplayFilter: TGameHostDisplayFilter;
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands): Boolean;
    /// <summary>The display in use is the OpenGL one</summary>
    property IsOpenGl: Boolean read FDeviceIsOpenGl;
  end;

implementation

const
  SOpenGlFallback = 'OpenGL display not available, using GDI: %s';

constructor TGameHostVideoDeviceSelector.Create(const APlainFactory, AOpenGlFactory: TGameHostVideoDeviceFactory;
  const ALog: ILog);
begin
  inherited Create;
  if not Assigned(APlainFactory) then
    raise EArgumentNilException.Create('APlainFactory');
  FPlainFactory := APlainFactory;
  FOpenGlFactory := AOpenGlFactory;
  FLog := ALog;
end;

procedure TGameHostVideoDeviceSelector.Use(AOpenGl: Boolean);
var
  LStyle: IGameHostWindowStyle;
  LPlacement: IGameHostWindowPlacement;
  LFiltered: IGameHostFilteredDisplay;
begin
  if (not Assigned(FDevice)) or (AOpenGl <> FDeviceIsOpenGl) then
  begin
    // the old display lets go of the window before the new one takes it
    FDevice := nil;
    if AOpenGl then
      FDevice := FOpenGlFactory()
    else
      FDevice := FPlainFactory();
    FDeviceIsOpenGl := AOpenGl;
    if FHasTitle then
      FDevice.SetTitle(FTitle);
  end;
  if FHasStyle and Supports(FDevice, IGameHostWindowStyle, LStyle) then
    LStyle.SetWindowStyle(FBorderless, FResizable);
  if FHasPlacement and Supports(FDevice, IGameHostWindowPlacement, LPlacement) then
    LPlacement.SetWindowPlacement(FPlacementFixed, FPlacementX, FPlacementY, FPlacementCentered);
  if Supports(FDevice, IGameHostFilteredDisplay, LFiltered) then
    LFiltered.SetDisplayFilter(FFilter);
end;

procedure TGameHostVideoDeviceSelector.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := AWidth;
  LHeight := AHeight;
  Use(FFilter.UseOpenGL and Assigned(FOpenGlFactory));
  try
    FDevice.SetMode(AWidth, AHeight, AFullscreen);
  except
    on E: EGameHostVideoDeviceException do
    begin
      if not FDeviceIsOpenGl then
        raise;
      if Assigned(FLog) then
        FLog.Warning(Format(SOpenGlFallback, [E.Message]));
      AWidth := LWidth;
      AHeight := LHeight;
      Use(False);
      FDevice.SetMode(AWidth, AHeight, AFullscreen);
    end;
  end;
end;

procedure TGameHostVideoDeviceSelector.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
begin
  if Assigned(FDevice) then
    FDevice.Present(APixels, AWidth, AHeight, APalette);
end;

procedure TGameHostVideoDeviceSelector.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
  FHasTitle := True;
  if Assigned(FDevice) then
    FDevice.SetTitle(ATitle);
end;

procedure TGameHostVideoDeviceSelector.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FBorderless := ABorderless;
  FResizable := AResizable;
  FHasStyle := True;
end;

procedure TGameHostVideoDeviceSelector.SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
begin
  FPlacementFixed := AFixed;
  FPlacementX := AX;
  FPlacementY := AY;
  FPlacementCentered := ACentered;
  FHasPlacement := True;
end;

procedure TGameHostVideoDeviceSelector.SetDisplayFilter(const AFilter: TGameHostDisplayFilter);
begin
  FFilter := AFilter;
end;

function TGameHostVideoDeviceSelector.DisplayFilter: TGameHostDisplayFilter;
var
  LFiltered: IGameHostFilteredDisplay;
begin
  if FDeviceIsOpenGl and Supports(FDevice, IGameHostFilteredDisplay, LFiltered) then
    Result := LFiltered.DisplayFilter
  else
  begin
    Result := FFilter;
    Result.UseOpenGL := FDeviceIsOpenGl;
    if not FDeviceIsOpenGl then
      Result.Shader := '';
  end;
end;

function TGameHostVideoDeviceSelector.PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette; ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands): Boolean;
var
  LFiltered: IGameHostFilteredDisplay;
begin
  Result := FDeviceIsOpenGl and Supports(FDevice, IGameHostFilteredDisplay, LFiltered) and
    LFiltered.PresentUnscaled(APixels, AWidth, AHeight, APalette, ADisplayWidth, ADisplayHeight, ABands);
end;

end.
