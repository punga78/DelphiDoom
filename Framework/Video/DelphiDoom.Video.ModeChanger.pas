{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the change of the video mode                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.ModeChanger;

interface

uses
  DelphiDoom.Video.ModeChanger.Intf;

type
  /// <summary>
  ///   The sequences of the software video that choose the full screen mode and the window (the cold part of
  ///   I_InitGraphics and of I_ChangeFullScreen). It decides, the host does: no window, no desktop, no global here
  /// </summary>
  TVideoModeChanger = class(TInterfacedObject, IVideoModeChanger)
  strict private
    FHost: IVideoModeHost;
    FResolutionChanged: Boolean;
    procedure WarnFailedChange(const AFullScreen: Boolean);
  public
    /// <summary>AHost is required: EArgumentNilException when nil</summary>
    constructor Create(const AHost: IVideoModeHost);
    procedure Initialize(var AFullScreen: Integer);
    procedure ChangeFullScreen(const ANewMode: Integer; var AFullScreen: Integer);
    procedure Release;
    function GetResolutionChanged: Boolean;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Video.StandardResolutions,
  DelphiDoom.Video.Types;

const
  SNilHost = 'The host of the change of the video mode is nil';
  SFailedFullScreen = 'SetDisplayMode(): Failed to fullscreen %dx%dx%d, trying window mode...'#13#10;
  SWindowMode = 'Window Mode %dx%d'#13#10;
  SCannotFullScreen = 'I_ChangeFullScreen(): Can not change to fullscreen mode'#13#10;
  SCannotWindow = 'I_ChangeFullScreen(): Can not change to window mode'#13#10;
  // the frame is always 32 bits
  FRAME_BITS = 32;

{ TVideoModeChanger }

constructor TVideoModeChanger.Create(const AHost: IVideoModeHost);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create(SNilHost);
  FHost := AHost;
end;

function TVideoModeChanger.GetResolutionChanged: Boolean;
begin
  Result := FResolutionChanged;
end;

procedure TVideoModeChanger.Initialize(var AFullScreen: Integer);
begin
  AFullScreen := AFullScreen mod NUMFULLSCREEN_MODES;

  if AFullScreen = FULLSCREEN_EXCLUSIVE then
  begin
    FHost.FindWindowSize(AFullScreen);

    // Set the video mode to WindowWidth x WindowHeight x 32
    if FHost.ChangeResolution(FHost.WindowWidth, FHost.WindowHeight) then
    begin
      FResolutionChanged := True;
      FHost.RestoreWindowPosition(AFullScreen);
      FHost.DisableAltTab;
    end
    else
    begin
      // Fullscreen mode failed, trying window mode
      AFullScreen := FULLSCREEN_SHARED;

      FHost.AdjustWindowMode;
      FHost.RestoreWindowPosition(AFullScreen);

      FHost.Warn(Format(SFailedFullScreen, [FHost.WindowWidth, FHost.WindowHeight, FRAME_BITS]));
      FHost.Print(Format(SWindowMode, [FHost.ScreenWidth, FHost.ScreenHeight]));
    end;
  end
  else
  begin
    FHost.FindWindowSize(AFullScreen);
    FHost.AdjustWindowMode;
    FHost.RestoreWindowPosition(AFullScreen);
  end;

  if FHost.ApplyMemoryStallHack then
    FHost.ReinitializeScreens;
  FHost.RefreshDpi;
end;

procedure TVideoModeChanger.WarnFailedChange(const AFullScreen: Boolean);
begin
  if AFullScreen then
    FHost.Warn(SCannotFullScreen)
  else
    FHost.Warn(SCannotWindow);
end;

procedure TVideoModeChanger.ChangeFullScreen(const ANewMode: Integer; var AFullScreen: Integer);
var
  LChanged: Boolean;
  LWidth: Integer;
  LHeight: Integer;
begin
  FHost.SetWindowSize(FHost.ScreenWidth, FHost.ScreenHeight);

  FHost.FindWindowSize(ANewMode);
  FHost.AdjustWindowMode;
  FHost.RestoreWindowPosition(ANewMode);

  if ANewMode = FULLSCREEN_EXCLUSIVE then
    LChanged := FHost.ChangeResolution(FHost.WindowWidth, FHost.WindowHeight)
  else
  begin
    // the desktop resolution is the native one
    FHost.RestoreResolution;
    FResolutionChanged := False;
    LChanged := True;
  end;

  if not LChanged then
  begin
    // Determine a standard screen resolution, starting from the smallest one
    LWidth := TVideoStandardResolutions.WidthOf(TVideoStandardResolutions.Count - 1);
    LHeight := TVideoStandardResolutions.HeightOf(TVideoStandardResolutions.Count - 1);
    TVideoStandardResolutions.Choose(LWidth, LHeight);
    FHost.SetWindowSize(LWidth, LHeight);

    if not FHost.ChangeResolution(LWidth, LHeight) then
    begin
      WarnFailedChange(AFullScreen <> FULLSCREEN_OFF);
      Exit;
    end;
  end;

  if ANewMode = FULLSCREEN_EXCLUSIVE then
  begin
    FResolutionChanged := True;
    // the system may have moved the window when the resolution changed
    FHost.RestoreWindowPosition(ANewMode);
  end;

  AFullScreen := ANewMode;

  FHost.RefreshDpi;
end;

procedure TVideoModeChanger.Release;
begin
  // the screen goes back to the resolution of the desktop
  if FResolutionChanged then
    FHost.RestoreResolution;
  FResolutionChanged := False;
  FHost.EnableAltTab;
end;

end.
