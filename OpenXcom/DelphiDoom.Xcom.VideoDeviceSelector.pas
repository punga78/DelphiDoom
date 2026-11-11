{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the choice of the display (GDI or OpenGL)               }
{  What Screen::resetDisplay did with SDL_OPENGL: the display follows           }
{  Options::useOpenGL each time the mode is set, and goes back to the plain     }
{  one when the OpenGL one cannot be made                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.VideoDeviceSelector;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.Xcom.VideoDevice.Types;

type
  /// <summary>
  ///   The display the game sees: one of two displays made by the factories it is given, chosen at every SetMode by
  ///   the filter the screen gave before it. The plain display is the default; the OpenGL one is made when the
  ///   filter asks for it, and when its SetMode raises EXcomVideoDeviceException the reason goes to the log and the
  ///   plain display takes its place (DisplayFilter then says that OpenGL is not in use). A display is released
  ///   before the other is made, because they share the window
  /// </summary>
  TXcomVideoDeviceSelector = class(TInterfacedObject, IXcomVideoDevice, IXcomWindowStyle, IXcomFilteredDisplay)
  strict private
    FPlainFactory: TXcomVideoDeviceFactory;
    FOpenGlFactory: TXcomVideoDeviceFactory;
    FLog: IXcomLog;
    FDevice: IXcomVideoDevice;
    FDeviceIsOpenGl: Boolean;
    FFilter: TXcomDisplayFilter;
    FHasStyle: Boolean;
    FBorderless: Boolean;
    FResizable: Boolean;
    FHasTitle: Boolean;
    FTitle: string;
    procedure Use(AOpenGl: Boolean);
  public
    /// <param name="APlainFactory">Makes the display that always works (GDI)</param>
    /// <param name="AOpenGlFactory">Makes the OpenGL display; nil when the program has none</param>
    /// <param name="ALog">Where the reason of a fallback goes; nil for nowhere</param>
    constructor Create(const APlainFactory, AOpenGlFactory: TXcomVideoDeviceFactory; const ALog: IXcomLog = nil);
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    procedure SetDisplayFilter(const AFilter: TXcomDisplayFilter);
    function DisplayFilter: TXcomDisplayFilter;
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
    /// <summary>The display in use is the OpenGL one</summary>
    property IsOpenGl: Boolean read FDeviceIsOpenGl;
  end;

implementation

const
  SLogWarning = 'WARN';
  SOpenGlFallback = 'OpenGL display not available, using GDI: %s';

constructor TXcomVideoDeviceSelector.Create(const APlainFactory, AOpenGlFactory: TXcomVideoDeviceFactory;
  const ALog: IXcomLog);
begin
  inherited Create;
  if not Assigned(APlainFactory) then
    raise EArgumentNilException.Create('APlainFactory');
  FPlainFactory := APlainFactory;
  FOpenGlFactory := AOpenGlFactory;
  FLog := ALog;
end;

procedure TXcomVideoDeviceSelector.Use(AOpenGl: Boolean);
var
  LStyle: IXcomWindowStyle;
  LFiltered: IXcomFilteredDisplay;
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
  if FHasStyle and Supports(FDevice, IXcomWindowStyle, LStyle) then
    LStyle.SetWindowStyle(FBorderless, FResizable);
  if Supports(FDevice, IXcomFilteredDisplay, LFiltered) then
    LFiltered.SetDisplayFilter(FFilter);
end;

procedure TXcomVideoDeviceSelector.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
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
    on E: EXcomVideoDeviceException do
    begin
      if not FDeviceIsOpenGl then
        raise;
      if Assigned(FLog) then
        FLog.Write(SLogWarning, Format(SOpenGlFallback, [E.Message]));
      AWidth := LWidth;
      AHeight := LHeight;
      Use(False);
      FDevice.SetMode(AWidth, AHeight, AFullscreen);
    end;
  end;
end;

procedure TXcomVideoDeviceSelector.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TXcomColors);
begin
  if Assigned(FDevice) then
    FDevice.Present(APixels, AWidth, AHeight, APalette);
end;

procedure TXcomVideoDeviceSelector.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
  FHasTitle := True;
  if Assigned(FDevice) then
    FDevice.SetTitle(ATitle);
end;

procedure TXcomVideoDeviceSelector.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FBorderless := ABorderless;
  FResizable := AResizable;
  FHasStyle := True;
end;

procedure TXcomVideoDeviceSelector.SetDisplayFilter(const AFilter: TXcomDisplayFilter);
begin
  FFilter := AFilter;
end;

function TXcomVideoDeviceSelector.DisplayFilter: TXcomDisplayFilter;
var
  LFiltered: IXcomFilteredDisplay;
begin
  if FDeviceIsOpenGl and Supports(FDevice, IXcomFilteredDisplay, LFiltered) then
    Result := LFiltered.DisplayFilter
  else
  begin
    Result := FFilter;
    Result.UseOpenGL := FDeviceIsOpenGl;
    if not FDeviceIsOpenGl then
      Result.Shader := '';
  end;
end;

function TXcomVideoDeviceSelector.PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TXcomColors; ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
var
  LFiltered: IXcomFilteredDisplay;
begin
  Result := FDeviceIsOpenGl and Supports(FDevice, IXcomFilteredDisplay, LFiltered) and
    LFiltered.PresentUnscaled(APixels, AWidth, AHeight, APalette, ADisplayWidth, ADisplayHeight, ABands);
end;

end.
