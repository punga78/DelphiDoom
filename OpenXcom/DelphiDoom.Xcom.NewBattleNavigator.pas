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
  ///   TXcomMissionRequest has no terrain, depth, alien technology nor base: the terrain is asked through a
  ///   texture of the globe that has it (so it is not always the one chosen), depth and technology are the ones
  ///   the generator works out, and a base defense cannot be launched (an error window says so). The host is not
  ///   owned
  /// </summary>
  TXcomNewBattleNavigator = class(TInterfacedObject, IXcomNewBattleOpener, IXcomNewBattleNavigator)
  strict private
    FHost: TXcomStateHost;
    FLauncher: IXcomMissionLauncher;
    function TextureFor(const ATerrain: string): Integer;
  public
    constructor Create(AHost: TXcomStateHost; const ALauncher: IXcomMissionLauncher);
    procedure OpenNewBattle;
    procedure EquipCraft(ABase: TXcomBase);
    procedure Launch(const AChoice: TXcomNewBattleChoice);
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Texture,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.CraftInfoState, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMenu.NewBattleState,
  DelphiDoom.XcomMenu.DiskNewBattleStore;

const
  SNoBaseDefense = 'The mission generator cannot start a base defense yet.';
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

function TXcomNewBattleNavigator.TextureFor(const ATerrain: string): Integer;
var
  LRuleset: TXcomRuleset;
  LId: Integer;
  LTexture: TXcomTexture;
  LCriteria: TXcomTerrainCriteria;
  LHas, LOnly: Boolean;
begin
  Result := NO_TEXTURE;
  LRuleset := TXcomStrategy.Ruleset(FHost);
  for LId in LRuleset.Globe.TextureIds do
  begin
    LTexture := LRuleset.Globe.GetTexture(LId);
    if LTexture = nil then
      Continue;
    LHas := False;
    LOnly := True;
    for LCriteria in LTexture.Terrain do
      if LCriteria.Name = ATerrain then
        LHas := True
      else
        LOnly := False;
    // a texture with only this terrain always gives it; otherwise the first one that can
    if LHas and LOnly then
      Exit(LId);
    if LHas and (Result = NO_TEXTURE) then
      Result := LId;
  end;
end;

procedure TXcomNewBattleNavigator.Launch(const AChoice: TXcomNewBattleChoice);
var
  LRequest: TXcomMissionRequest;
begin
  if (AChoice.Craft = nil) or (FLauncher = nil) then
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
  LRequest.WorldTexture := TextureFor(AChoice.Terrain);
  LRequest.WorldShade := AChoice.Darkness;
  FLauncher.BeginMission(LRequest);
end;

end.
