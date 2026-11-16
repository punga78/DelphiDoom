{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the host of the change of the video mode (software)    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Engine.Video.ModeHost;

interface

uses
  System.SysUtils,
  DelphiDoom.Video.Intf,
  DelphiDoom.Video.ModeChanger.Intf,
  DelphiDoom.Engine.Video.FramePresenter.Intf;

type
  /// <summary>
  ///   What the sequences of DelphiDoom.Video.ModeChanger need from the engine (software video): the window of the
  ///   game (i_mainwindow), the sizes of the window and of the screen (doomdef), the display modes and the resolution
  ///   of the desktop (given by the composition root). The routines of the window that i_video had are here
  /// </summary>
  TEngineVideoModeHost = class(TInterfacedObject, IVideoModeHost)
  strict private
    FModes: IDisplayModeCatalog;
    FResolution: IEngineDisplayResolution;
    FFixStallHack: TFunc<Boolean>;
    FAltTabDisabled: Boolean;
    FDpi: Integer;
  public
    /// <summary>
    ///   AModes, AResolution and AFixStallHack (it tells, at the time of the call, whether the memory stall hack is
    ///   on: a setting that the user can change) are required: EArgumentNilException when nil
    /// </summary>
    constructor Create(const AModes: IDisplayModeCatalog; const AResolution: IEngineDisplayResolution;
      const AFixStallHack: TFunc<Boolean>);
    function GetWindowWidth: Integer;
    function GetWindowHeight: Integer;
    procedure SetWindowSize(const AWidth, AHeight: Integer);
    function GetScreenWidth: Integer;
    function GetScreenHeight: Integer;
    procedure FindWindowSize(const AMode: Integer);
    procedure AdjustWindowMode;
    procedure RestoreWindowPosition(const AMode: Integer);
    procedure DisableAltTab;
    procedure EnableAltTab;
    function ChangeResolution(const AWidth, AHeight: Integer): Boolean;
    procedure RestoreResolution;
    function ApplyMemoryStallHack: Boolean;
    procedure ReinitializeScreens;
    procedure RefreshDpi;
    procedure Warn(const AMessage: string);
    procedure Print(const AMessage: string);
    /// <summary>The DPI of the window, as RefreshDpi saw it last</summary>
    property Dpi: Integer read FDpi;
  end;

implementation

uses
  Windows,
  d_delphi,
  doomdef,
  i_system,
  i_main,
  i_mainwindow,
  v_video,
  DelphiDoom.Video.Types;

const
  SNilModes = 'The display modes of the video mode host are nil';
  SNilResolution = 'The resolution of the video mode host is nil';
  SNilStallHack = 'The memory stall hack setting of the video mode host is nil';

{ TEngineVideoModeHost }

constructor TEngineVideoModeHost.Create(const AModes: IDisplayModeCatalog;
  const AResolution: IEngineDisplayResolution; const AFixStallHack: TFunc<Boolean>);
begin
  inherited Create;
  if not Assigned(AModes) then
    raise EArgumentNilException.Create(SNilModes);
  if not Assigned(AResolution) then
    raise EArgumentNilException.Create(SNilResolution);
  if not Assigned(AFixStallHack) then
    raise EArgumentNilException.Create(SNilStallHack);
  FModes := AModes;
  FResolution := AResolution;
  FFixStallHack := AFixStallHack;
end;

function TEngineVideoModeHost.GetWindowWidth: Integer;
begin
  Result := WINDOWWIDTH;
end;

function TEngineVideoModeHost.GetWindowHeight: Integer;
begin
  Result := WINDOWHEIGHT;
end;

procedure TEngineVideoModeHost.SetWindowSize(const AWidth, AHeight: Integer);
begin
  WINDOWWIDTH := AWidth;
  WINDOWHEIGHT := AHeight;
end;

function TEngineVideoModeHost.GetScreenWidth: Integer;
begin
  Result := SCREENWIDTH;
end;

function TEngineVideoModeHost.GetScreenHeight: Integer;
begin
  Result := SCREENHEIGHT;
end;

// The window of a mode: the exact or nearest mode of the catalog, else the screen
procedure TEngineVideoModeHost.FindWindowSize(const AMode: Integer);
var
  LWidth: Integer;
  LHeight: Integer;
begin
  if AMode = FULLSCREEN_SHARED then
  begin
    WINDOWWIDTH := NATIVEWIDTH;
    WINDOWHEIGHT := NATIVEHEIGHT;
    Exit;
  end;

  if FModes.FindWindowSize(SCREENWIDTH, SCREENHEIGHT, LWidth, LHeight) then
  begin
    WINDOWWIDTH := LWidth;
    WINDOWHEIGHT := LHeight;
    Exit;
  end;

  WINDOWWIDTH := GetSystemMetrics(SM_CXSCREEN);
  WINDOWHEIGHT := GetSystemMetrics(SM_CYSCREEN);
end;

procedure TEngineVideoModeHost.AdjustWindowMode;
begin
  I_VideoServices.SizeLimiter.Limit(WINDOWWIDTH, WINDOWHEIGHT);
end;

procedure TEngineVideoModeHost.RestoreWindowPosition(const AMode: Integer);
var
  LDeltaWidth: Integer;
  LDeltaHeight: Integer;
begin
  if AMode = FULLSCREEN_OFF then
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, Longint(WINDOW_STYLE_W));
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, WINDOWWIDTH, WINDOWHEIGHT, SWP_SHOWWINDOW);
    I_GetWindowClientOffset(LDeltaWidth, LDeltaHeight);
    SetWindowPos(hMainWnd, HWND_TOP, windowxpos, windowypos, WINDOWWIDTH + LDeltaWidth,
      WINDOWHEIGHT + LDeltaHeight, SWP_SHOWWINDOW);
  end
  else
  begin
    SetWindowLong(hMainWnd, GWL_STYLE, WINDOW_STYLE_FS);
    SetWindowPos(hMainWnd, HWND_TOP, 0, 0, WINDOWWIDTH, WINDOWHEIGHT, SWP_SHOWWINDOW);
  end;
end;

procedure TEngineVideoModeHost.DisableAltTab;
var
  LOld: Boolean;
begin
  if FAltTabDisabled then
    Exit;

  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if isLibrary then
      RegisterHotKey(0, $C000, MOD_ALT, VK_TAB)
    else
      RegisterHotKey(0, 0, MOD_ALT, VK_TAB)
  end
  else
    SystemParametersInfo(SPI_SCREENSAVERRUNNING, 1, @LOld, 0);

  FAltTabDisabled := True;
end;

procedure TEngineVideoModeHost.EnableAltTab;
var
  LOld: Boolean;
begin
  if FAltTabDisabled then
  begin
    if Win32Platform = VER_PLATFORM_WIN32_NT then
    begin
      if isLibrary then
        UnregisterHotKey(0, $C000)
      else
        UnregisterHotKey(0, 0)
    end
    else
      SystemParametersInfo(SPI_SCREENSAVERRUNNING, 0, @LOld, 0);

    FAltTabDisabled := False;
  end;
end;

function TEngineVideoModeHost.ChangeResolution(const AWidth, AHeight: Integer): Boolean;
begin
  Result := FResolution.Change(AWidth, AHeight);
end;

procedure TEngineVideoModeHost.RestoreResolution;
begin
  FResolution.Restore;
end;

// Memory stall can dramatically reduce performance in the inc operation of the esi register of value 4096 and the
// like: a screen of 1024 pixels is made 2 narrower (see IMemoryStallHack)
function TEngineVideoModeHost.ApplyMemoryStallHack: Boolean;
begin
  Result := I_VideoServices.StallHack.Apply(SCREENWIDTH, FFixStallHack());
end;

procedure TEngineVideoModeHost.ReinitializeScreens;
begin
  V_ReInit;
end;

procedure TEngineVideoModeHost.RefreshDpi;
begin
  FDpi := I_GetWindowDPI(hMainWnd);
end;

procedure TEngineVideoModeHost.Warn(const AMessage: string);
begin
  I_Warning(AMessage);
end;

procedure TEngineVideoModeHost.Print(const AMessage: string);
begin
  printf(AMessage);
end;

end.
