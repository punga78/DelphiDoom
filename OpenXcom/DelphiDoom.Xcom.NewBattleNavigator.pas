{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenXcom game - what the New Battle screen of the menu opens     }
{  (composition root side: it knows the screens of a craft and the launcher     }
{  of the missions)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.NewBattleNavigator;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.XcomMenu.NewBattle.Intf;

type
  /// <summary>
  ///   Opens the New Battle screen (IXcomNewBattleOpener) and does what it asks (IXcomNewBattleNavigator): the
  ///   Equip Craft button is CraftInfoState, OK goes to the launcher of the missions of the geoscape.
  ///   The terrain, the depth, the alien technology and the base of a base defense go to the launcher in the
  ///   request, as NewBattleState::btnOkClick gives them to the generator. The host is not owned
  /// </summary>
  TXcomNewBattleNavigator = class(TInterfacedObject, IXcomNewBattleOpener, IXcomNewBattleNavigator)
  strict private
    FHost: TXcomStateHost;
    FLauncher: IXcomMissionLauncher;
  public
    constructor Create(AHost: TXcomStateHost; const ALauncher: IXcomMissionLauncher);
    procedure OpenNewBattle;
    procedure EquipCraft(ABase: TXcomBase);
    procedure Launch(const AChoice: TXcomNewBattleChoice);
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomBasescape.CraftInfoState, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.NewBattleState,
  DelphiDoom.XcomMenu.DiskNewBattleStore;

const
  SNoBaseDefense = 'The mission has neither a craft nor a base, or the battle cannot be started.';
  NO_TEXTURE = -1;

constructor TXcomNewBattleNavigator.Create(AHost: TXcomStateHost; const ALauncher: IXcomMissionLauncher);
begin
  inherited Create;
  FHost := AHost;
  FLauncher := ALauncher;
end;

procedure TXcomNewBattleNavigator.OpenNewBattle;
begin
  FHost.PushState(TXcomNewBattleState.Create(FHost, Self,
    TXcomDiskNewBattleStore.Create(FHost.Options.MasterUserFolder)));
end;

procedure TXcomNewBattleNavigator.EquipCraft(ABase: TXcomBase);
begin
  FHost.PushState(TXcomCraftInfoState.Create(FHost, ABase, 0));
end;

procedure TXcomNewBattleNavigator.Launch(const AChoice: TXcomNewBattleChoice);
var
  LRequest: TXcomMissionRequest;
begin
  if ((AChoice.Craft = nil) and (AChoice.Base = nil)) or (FLauncher = nil) then
  begin
    FHost.PushState(TXcomErrorMessageState.ForOrigin(FHost, ooMenu, SNoBaseDefense,
      PXcomColors(FHost.Resources.GetPalette('PAL_GEOSCAPE'))));
    Exit;
  end;
  LRequest := Default(TXcomMissionRequest);
  LRequest.Craft := AChoice.Craft;
  LRequest.MissionType := AChoice.MissionType;
  LRequest.Ufo := AChoice.Ufo;
  LRequest.Site := AChoice.Site;
  LRequest.AlienBase := AChoice.AlienBase;
  LRequest.AlienRace := AChoice.AlienRace;
  LRequest.Base := AChoice.Base;
  LRequest.WorldTexture := NO_TEXTURE;
  LRequest.Terrain := AChoice.Terrain;
  LRequest.Depth := AChoice.Depth;
  LRequest.AlienItemLevel := AChoice.AlienItemLevel;
  LRequest.WorldShade := AChoice.Darkness;
  FLauncher.BeginMission(LRequest);
end;

end.
