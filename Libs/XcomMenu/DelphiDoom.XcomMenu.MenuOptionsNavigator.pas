{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - the options screens that the main menu opens }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.MenuOptionsNavigator;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.OptionsNavigator.Intf;

type
  /// <summary>
  ///   IXcomOptionsNavigator of the options opened from the main menu: it makes the screens of the categories that
  ///   are ported (all seven), and going back means a new main menu. The geoscape and the battlescape are not ported, so the
  ///   other origins do nothing
  /// </summary>
  TXcomMenuOptionsNavigator = class(TInterfacedObject, IXcomOptionsNavigator)
  strict private
    FVersionText: string;
  public
    constructor Create(const AVersionText: string);
    function CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
      AHost: TXcomStateHost): TXcomState;
    procedure Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
  end;

implementation

uses
  DelphiDoom.XcomMenu.MainMenuState, DelphiDoom.XcomMenu.OptionsVideoState, DelphiDoom.XcomMenu.OptionsAudioState,
  DelphiDoom.XcomMenu.OptionsControlsState, DelphiDoom.XcomMenu.OptionsGeoscapeState,
  DelphiDoom.XcomMenu.OptionsBattlescapeState, DelphiDoom.XcomMenu.OptionsAdvancedState,
  DelphiDoom.XcomMenu.OptionsFoldersState;

constructor TXcomMenuOptionsNavigator.Create(const AVersionText: string);
begin
  inherited Create;
  FVersionText := AVersionText;
end;

function TXcomMenuOptionsNavigator.CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
  AHost: TXcomStateHost): TXcomState;
begin
  case ACategory of
    ocVideo:
      Result := TXcomOptionsVideoState.Create(AHost, AOrigin, Self);
    ocAudio:
      Result := TXcomOptionsAudioState.Create(AHost, AOrigin, Self);
    ocControls:
      Result := TXcomOptionsControlsState.Create(AHost, AOrigin, Self);
    ocGeoscape:
      Result := TXcomOptionsGeoscapeState.Create(AHost, AOrigin, Self);
    ocBattlescape:
      Result := TXcomOptionsBattlescapeState.Create(AHost, AOrigin, Self);
    ocAdvanced:
      Result := TXcomOptionsAdvancedState.Create(AHost, AOrigin, Self);
    ocFolders:
      Result := TXcomOptionsFoldersState.Create(AHost, AOrigin, Self);
  else
    Result := nil;
  end;
end;

procedure TXcomMenuOptionsNavigator.Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
begin
  if AOrigin = ooMenu then
    AHost.SetState(TXcomMainMenuState.Create(AHost, FVersionText));
end;

end.
