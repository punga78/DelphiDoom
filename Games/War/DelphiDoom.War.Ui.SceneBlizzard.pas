{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the scene of the Blizzard logo                    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_scene_blizzard.c, (c) 2019 Alejandro Coto  }
{  Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneBlizzard;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.SceneBase;

type
  /// <summary>
  ///   The logo, three seconds from the enter, then the main menu with a pause of 0.3 seconds. It has an update of its
  ///   own: no cheat panel, no animations
  /// </summary>
  TWarSceneBlizzard = class(TWarSceneBase)
  strict private
    FEndRealTime: Double;
  strict protected
    procedure DoEnter; override;
    procedure DoUpdate; override;
    procedure DoRender; override;
  public
    function GetSceneType: TWarSceneType; override;
  end;

implementation

{ TWarSceneBlizzard }

function TWarSceneBlizzard.GetSceneType: TWarSceneType;
begin
  Result := wstBlizzard;
end;

procedure TWarSceneBlizzard.DoEnter;
begin
  FEndRealTime := Services.Host.RealTime + 3.0;
  if Assigned(Services.Audio) then
    Services.Audio.Play(WAR_AUDIO_LOGO, True);
end;

procedure TWarSceneBlizzard.DoUpdate;
begin
  if Services.Host.RealTime >= FEndRealTime then
  begin
    // the introduction is the port's own (a game with animations that is asked to play it); the original goes to the menu
    if Services.IntroductionAfterLogo and Assigned(Services.Cinematics) then
      Services.Host.SetNextScene(Services.Scenes.CreateIntroduction, 0.3)
    else
      Services.Host.SetNextScene(Services.Scenes.CreateMainMenu, 0.3);
  end;
end;

procedure TWarSceneBlizzard.DoRender;
var
  LImage: TWarUiImageArgs;
begin
  LImage := TWarUiImageArgs.Default;
  LImage.SpriteRef := 216;
  Services.Imui.Image('imgBackground', LImage);
end;

end.
