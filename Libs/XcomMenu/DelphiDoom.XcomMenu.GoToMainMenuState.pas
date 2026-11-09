{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - GoToMainMenuState of OpenXcom (the state     }
{  that sets the scale and opens the main menu)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.GoToMainMenuState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State;

type
  /// <summary>Resets the scale of the picture to the one of the geoscape and replaces itself with the main menu</summary>
  TXcomGoToMainMenuState = class(TXcomState)
  strict private
    FVersionText: string;
  public
    constructor Create(AHost: TXcomStateHost; const AVersionText: string);
    procedure Init; override;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomMenu.MainMenuState;

constructor TXcomGoToMainMenuState.Create(AHost: TXcomStateHost; const AVersionText: string);
begin
  inherited Create(AHost);
  FVersionText := AVersionText;
end;

procedure TXcomGoToMainMenuState.Init;
begin
  TXcomScreen.UpdateScale(Host.Options, Host.Options.GeoscapeScale, Host.Options.BaseXGeoscape,
    Host.Options.BaseYGeoscape, True);
  Host.Screen.ResetDisplay(False);
  Host.SetState(TXcomMainMenuState.Create(Host, FVersionText));
end;

end.
