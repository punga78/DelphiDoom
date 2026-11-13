{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the resolution of the screen through the display        }
{  settings of Windows (the exclusive full screen mode)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Video.DisplaySettings;

interface

uses
  DelphiDoom.Engine.Video.FramePresenter.Intf;

type
  /// <summary>
  ///   IEngineDisplayResolution on ChangeDisplaySettings: the change lasts for the life of the process (CDS_FULLSCREEN)
  ///   and Windows takes it back by itself if the game ends without calling Restore
  /// </summary>
  TEngineDisplaySettingsResolution = class(TInterfacedObject, IEngineDisplayResolution)
  public
    function Change(AWidth, AHeight: Integer): Boolean;
    procedure Restore;
  end;

implementation

uses
  Winapi.Windows;

const
  BITS_PER_PIXEL = 32;

{ TEngineDisplaySettingsResolution }

function TEngineDisplaySettingsResolution.Change(AWidth, AHeight: Integer): Boolean;
var
  LMode: TDeviceMode;
begin
  FillChar(LMode, SizeOf(LMode), 0);
  LMode.dmSize := SizeOf(LMode);
  LMode.dmPelsWidth := AWidth;
  LMode.dmPelsHeight := AHeight;
  LMode.dmBitsPerPel := BITS_PER_PIXEL;
  LMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
  Result := ChangeDisplaySettings(LMode, CDS_FULLSCREEN) = DISP_CHANGE_SUCCESSFUL;
end;

procedure TEngineDisplaySettingsResolution.Restore;
begin
  ChangeDisplaySettings(PDeviceMode(nil)^, 0);
end;

end.
