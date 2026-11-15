{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the maker of the scenes                           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_scenes.c (wsc_createScene and the          }
{  descriptors of the scenes), (c) 2019 Alejandro Coto Gutierrez, zlib License }
{  (see Libs\War\LICENSE-war1.txt). This is an altered version, not the        }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneFactory;

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.War.Level.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Ui.SceneBase;

type
  /// <summary>
  ///   Makes the scenes with the services it was given. It is not counted by reference: the scenes it makes hold it (the
  ///   scene that starts another scene), it holds the services, and the owner (the factory of the library) frees it. The
  ///   download scene (the network) is not ported
  /// </summary>
  TWarSceneFactory = class(TSingletonImplementation, IWarSceneFactory)
  strict private
    FServices: TWarSceneServices;
  public
    constructor Create(const AServices: TWarSceneServices);
    function CreateBlizzard: IWarScene;
    function CreateMainMenu: IWarScene;
    function CreateBriefing(ARace: TWarRace; AMapType: Integer): IWarScene;
  end;

implementation

uses
  DelphiDoom.War.Ui.SceneBlizzard, DelphiDoom.War.Ui.SceneMainMenu, DelphiDoom.War.Ui.SceneBriefing;

{ TWarSceneFactory }

constructor TWarSceneFactory.Create(const AServices: TWarSceneServices);
begin
  inherited Create;
  FServices := AServices;
  // the scenes that start scenes ask this factory
  FServices.Scenes := Self;
end;

function TWarSceneFactory.CreateBlizzard: IWarScene;
begin
  Result := TWarSceneBlizzard.Create(FServices);
end;

function TWarSceneFactory.CreateMainMenu: IWarScene;
begin
  Result := TWarSceneMainMenu.Create(FServices);
end;

function TWarSceneFactory.CreateBriefing(ARace: TWarRace; AMapType: Integer): IWarScene;
begin
  Result := TWarSceneBriefing.Create(FServices, ARace, AMapType);
end;

end.
