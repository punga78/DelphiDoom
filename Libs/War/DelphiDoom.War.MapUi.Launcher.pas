{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the maker of the maps of the game                 }
{                                                                              }
{  Port of war1 (acoto87/war1), wmap_createMap, (c) 2019 Alejandro Coto         }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Launcher;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf,
  DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Map.Intf, DelphiDoom.War.Sound.Intf,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.MapUi.Intf;

type
  /// <summary>
  ///   IWarMapLauncher of the game of the scenes: wmap_createMap, that is, the scene of the map of a level of the archive.
  ///   The map is made when the scene is entered (wmap_enterMap), not before. The game gives it the services it needs
  ///   (AttachServices) once they exist. The generator of random numbers is one for the whole game, the interface and the
  ///   model draw from it in the order of the original
  /// </summary>
  TWarMapLauncher = class(TInterfacedObject, IWarMapLauncher, IWarMapServicesTarget)
  strict private
    FLevels: IWarLevelLoader;
    FGraphics: IWarGraphics;
    FUnits: IWarUnitCatalog;
    FObjectives: IWarObjectives;
    FRandom: IWarRandom;
    FUnsignedDirections: Boolean;
    FServices: TWarSceneServices;
    FHasServices: Boolean;
  public
    constructor Create(const ALevels: IWarLevelLoader; const AGraphics: IWarGraphics; const AUnits: IWarUnitCatalog;
      const AObjectives: IWarObjectives; const ARandom: IWarRandom; AUnsignedDirections: Boolean);
    procedure AttachServices(const AServices: TWarSceneServices);
    function CreateCampaignMap(AMapType: Integer): IWarScene;
    function CreateCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer): IWarScene;
  end;

implementation

uses
  DelphiDoom.War.MapUi.Scene;

resourcestring
  SWarLauncherNoServices = 'The maker of the maps has not been given the services of the game';

{ TWarMapLauncher }

constructor TWarMapLauncher.Create(const ALevels: IWarLevelLoader; const AGraphics: IWarGraphics;
  const AUnits: IWarUnitCatalog; const AObjectives: IWarObjectives; const ARandom: IWarRandom;
  AUnsignedDirections: Boolean);
begin
  inherited Create;
  FLevels := ALevels;
  FGraphics := AGraphics;
  FUnits := AUnits;
  FObjectives := AObjectives;
  FRandom := ARandom;
  FUnsignedDirections := AUnsignedDirections;
end;

procedure TWarMapLauncher.AttachServices(const AServices: TWarSceneServices);
begin
  FServices := AServices;
  FHasServices := True;
end;

function TWarMapLauncher.CreateCampaignMap(AMapType: Integer): IWarScene;
var
  LSetup: TWarMapSceneSetup;
  LLevel: IWarLevel;
begin
  if not FHasServices then
    raise EWarException.Create(SWarLauncherNoServices);
  LLevel := FLevels.Load(AMapType);
  LSetup.Services := FServices;
  LSetup.Level := LLevel;
  LSetup.TilesetPixels := FGraphics.GetTileset(LLevel.Info.TilesetIndex).Pixels;
  LSetup.Units := FUnits;
  LSetup.Objectives := FObjectives;
  LSetup.Random := FRandom;
  LSetup.MapType := AMapType;
  LSetup.UnsignedDirections := FUnsignedDirections;
  Result := TWarMapScene.Create(LSetup);
end;

function TWarMapLauncher.CreateCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer): IWarScene;
begin
  raise EWarException.Create('The custom games are not ported yet');
end;

end.
