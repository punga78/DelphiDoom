{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the scene of the briefing of a mission            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_scene_briefing.c, (c) 2019 Alejandro Coto  }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered  }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneBriefing;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.SceneBase, DelphiDoom.War.Ui.Animation;

type
  /// <summary>
  ///   The briefing: the picture of the race, its animations, the text of the mission that scrolls up at 10 units a
  ///   second and the spoken briefing. It ends when the time of the mission is over or the player clicks, presses Enter or
  ///   Space; the map comes after a pause of one second. Its update is its own: the animations, no cheat panel
  /// </summary>
  TWarSceneBriefing = class(TWarSceneBase)
  strict private
    FRace: TWarRace;
    FMapType: Integer;
    FEndRealTime: Double;
    FScrollY: Single;
    FBriefingText: AnsiString;
    function MakeAnimation(const AName: AnsiString; AResource: Integer; AFrameDelay: Single; AOffsetX,
      AOffsetY: Single; ALoopDelay: Single): TWarUiAnimation;
    procedure EnterHumans(const AData: TWarCampaignMapData);
    procedure EnterOrcs(const AData: TWarCampaignMapData);
  strict protected
    procedure DoEnter; override;
    procedure DoUpdate; override;
    procedure DoRender; override;
    procedure DoRenderOverlay; override;
  public
    /// <summary>The race (humans or orcs) and the campaign map the briefing is of, as wg_setNextScene's caller sets them</summary>
    constructor Create(const AServices: TWarSceneServices; ARace: TWarRace; AMapType: Integer);
    function GetSceneType: TWarSceneType; override;
    property ScrollY: Single read FScrollY;
    property EndRealTime: Double read FEndRealTime;
  end;

implementation

{ TWarSceneBriefing }

constructor TWarSceneBriefing.Create(const AServices: TWarSceneServices; ARace: TWarRace; AMapType: Integer);
begin
  inherited Create(AServices);
  FRace := ARace;
  FMapType := AMapType;
end;

function TWarSceneBriefing.GetSceneType: TWarSceneType;
begin
  Result := wstBriefing;
end;

function TWarSceneBriefing.MakeAnimation(const AName: AnsiString; AResource: Integer; AFrameDelay, AOffsetX,
  AOffsetY, ALoopDelay: Single): TWarUiAnimation;
begin
  Result := TWarUiAnimation.Create(AName, Services.Sprites.CreateSprite(AResource), AFrameDelay, True);
  Result.OffsetX := AOffsetX;
  Result.OffsetY := AOffsetY;
  Result.LoopDelay := ALoopDelay;
end;

procedure TWarSceneBriefing.EnterHumans(const AData: TWarCampaignMapData);
var
  LAnimation: TWarUiAnimation;
begin
  FEndRealTime := Services.Host.RealTime + AData.BriefingDuration;
  FScrollY := 160;
  FBriefingText := AData.BriefingText;
  LAnimation := MakeAnimation('anim1', 428, 0.2, 83, 37, 2.0);
  LAnimation.AddFramesRange(0, 4);
  LAnimation.AddFramesRange(4, 0);
  Animations.Add(LAnimation);
  LAnimation := MakeAnimation('anim2', 429, 0.2, 207, 29, 2.0);
  LAnimation.AddFramesRange(0, 20);
  Animations.Add(LAnimation);
  LAnimation := MakeAnimation('anim3', 430, 0.1, 21, 17, 0);
  LAnimation.AddFramesRange(0, 20);
  Animations.Add(LAnimation);
  LAnimation := MakeAnimation('anim4', 431, 0.1, 275, 21, 0);
  LAnimation.AddFramesRange(0, 20);
  Animations.Add(LAnimation);
  if (not Services.Host.IsDemo) and Assigned(Services.Audio) then
    Services.Audio.Play(AData.BriefingAudioId, False);
end;

procedure TWarSceneBriefing.EnterOrcs(const AData: TWarCampaignMapData);
var
  LAnimation: TWarUiAnimation;
begin
  FEndRealTime := Services.Host.RealTime + AData.BriefingDuration;
  FScrollY := 160;
  FBriefingText := AData.BriefingText;
  LAnimation := MakeAnimation('anim1', 426, 0.2, 18, 67, 2.0);
  LAnimation.AddFramesRange(0, 4);
  LAnimation.AddFramesRange(4, 0);
  Animations.Add(LAnimation);
  LAnimation := MakeAnimation('anim2', 427, 0.2, 202, 52, 2.0);
  LAnimation.AddFramesRange(0, 4);
  LAnimation.AddFramesRange(4, 0);
  Animations.Add(LAnimation);
  if not Services.Host.IsDemo then
  begin
    LAnimation := MakeAnimation('anim3', 425, 0.1, 140, 66, 0);
    LAnimation.AddFramesRange(0, 30);
    Animations.Add(LAnimation);
    if Assigned(Services.Audio) then
      Services.Audio.Play(AData.BriefingAudioId, False);
  end;
end;

procedure TWarSceneBriefing.DoEnter;
var
  LData: TWarCampaignMapData;
begin
  LData := Services.Campaigns.GetData(FMapType);
  case FRace of
    wraHumans: EnterHumans(LData);
    wraOrcs: EnterOrcs(LData);
  end;
  // another race: "Not allowed briefing scenes for race" is only logged, the scene stays empty
end;

procedure TWarSceneBriefing.DoUpdate;
var
  LStep: Single;
begin
  LStep := 10 * Services.Host.RealDeltaTime;
  FScrollY := FScrollY - LStep;
  Animations.Update(True, Services.Host.RealDeltaTime, Services.Host.GlobalSpeed, 0);
  if (Services.Host.RealTime >= FEndRealTime) or Services.Input.IsButtonJustPressed(wmbLeft)
    or Services.Input.IsKeyJustPressed(wkEnter) or Services.Input.IsKeyJustPressed(wkSpace) then
    Services.Host.SetNextCampaignMap(FMapType, 1.0);
end;

procedure TWarSceneBriefing.DoRender;
var
  LImage: TWarUiImageArgs;
begin
  // the picture goes first so that it is behind the animations
  LImage := TWarUiImageArgs.Default;
  if FRace = wraHumans then
    LImage.SpriteRef := 421
  else
    LImage.SpriteRef := 422;
  Services.Imui.Image('imgBackground', LImage);
end;

procedure TWarSceneBriefing.DoRenderOverlay;
var
  LText: TWarUiTextArgs;
begin
  LText := TWarUiTextArgs.Default;
  LText.PositionX := 20;
  LText.PositionY := FScrollY;
  LText.FontIndex := 1;
  LText.FontColor.R := 255;
  LText.FontColor.G := 215;
  LText.FontColor.B := 138;
  LText.FontColor.A := 255;
  LText.Multiline := True;
  LText.BoundingsX := Services.Host.OriginalWidth - 40;
  LText.BoundingsY := 200;
  LText.Wrapping := wtwChar;
  LText.LineHeight := 150;
  LText.Text := FBriefingText;
  Services.Imui.Text('txtBriefing', LText);
end;

end.
