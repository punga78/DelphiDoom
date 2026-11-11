{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - CutsceneState of OpenXcom (chooses the       }
{  video or the slideshow of a cutscene)                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.CutsceneState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMenu.CutsceneCatalog.Intf;

const
  /// <summary>CutsceneState::WIN_GAME and LOSE_GAME</summary>
  XCOM_CUTSCENE_WIN_GAME = 'winGame';
  XCOM_CUTSCENE_LOSE_GAME = 'loseGame';
  XCOM_CUTSCENE_INTRO = 'intro';
  /// <summary>Options::preferredVideo: VIDEO_FMV and VIDEO_SLIDE</summary>
  XCOM_VIDEO_FMV = 0;
  XCOM_VIDEO_SLIDE = 1;

type
  /// <summary>
  ///   The first time it comes to the front it takes itself off the stack and puts there the player of the
  ///   cutscene: the video when its first file exists (and there is no slideshow, or the options prefer videos),
  ///   otherwise the slideshow. For the cutscenes of the end of the game (winGame, loseGame) it first calls
  ///   AGameEnd, that replaces every state with what follows the cutscene (the statistics of the game, or the
  ///   main menu): the menu library does not know those screens. Without catalog it asks the data of the host
  /// </summary>
  TXcomCutsceneState = class(TXcomState)
  strict private
    FCutsceneId: string;
    FCatalog: IXcomCutsceneCatalog;
    FGameEnd: TProc;
  public
    constructor Create(AHost: TXcomStateHost; const ACutsceneId: string; const ACatalog: IXcomCutsceneCatalog = nil;
      const AGameEnd: TProc = nil);
    procedure Init; override;
    /// <summary>
    ///   CutsceneState::initDisplay: the picture becomes 320 x 200 and keeps its proportions; gives back whether
    ///   it was letterboxed before
    /// </summary>
    class function InitDisplay(AHost: TXcomStateHost): Boolean; static;
    /// <summary>CutsceneState::resetDisplay: back to the scale of the geoscape</summary>
    class procedure ResetDisplay(AHost: TXcomStateHost; AWasLetterboxed: Boolean); static;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomMod.RuleVideo, DelphiDoom.XcomMenu.RulesCutsceneCatalog,
  DelphiDoom.XcomMenu.SlideshowState, DelphiDoom.XcomMenu.VideoState;

constructor TXcomCutsceneState.Create(AHost: TXcomStateHost; const ACutsceneId: string;
  const ACatalog: IXcomCutsceneCatalog; const AGameEnd: TProc);
begin
  inherited Create(AHost);
  FCutsceneId := ACutsceneId;
  FCatalog := ACatalog;
  FGameEnd := AGameEnd;
end;

procedure TXcomCutsceneState.Init;
var
  LRule: TXcomRuleVideo;
  LVideo: Boolean;
  LSlide: Boolean;
  LCatalog: IXcomCutsceneCatalog;
  LGameEnd: TProc;
begin
  inherited Init;
  // the fields are copied: the state is on its way out from here on
  LCatalog := FCatalog;
  LGameEnd := FGameEnd;
  // pop self off stack and replace with actual player state
  Host.PopState;
  if ((FCutsceneId = XCOM_CUTSCENE_WIN_GAME) or (FCutsceneId = XCOM_CUTSCENE_LOSE_GAME)) and Assigned(LGameEnd) then
    LGameEnd();
  if LCatalog = nil then
    LCatalog := TXcomRulesCutsceneCatalog.FromHost(Host);
  if LCatalog = nil then
    Exit;
  LRule := LCatalog.FindCutscene(FCutsceneId);
  if LRule = nil then
    Exit;
  LVideo := (Length(LRule.Videos) > 0) and LCatalog.FileExists(LRule.Videos[0]);
  LSlide := (Length(LRule.Slides) > 0) and LCatalog.FileExists(LRule.Slides[0].ImagePath);
  if LVideo and ((not LSlide) or (Host.Options.PreferredVideo = XCOM_VIDEO_FMV)) then
    Host.PushState(TXcomVideoState.Create(Host, LCatalog, LRule.Videos, LRule.AudioTracks, LRule.UseUfoAudioSequence))
  else if LSlide and ((not LVideo) or (Host.Options.PreferredVideo = XCOM_VIDEO_SLIDE)) then
    Host.PushState(TXcomSlideshowState.Create(Host, LCatalog, LRule.SlideshowHeader, LRule.Slides));
  // otherwise the cutscene definition is empty: nothing plays
end;

class function TXcomCutsceneState.InitDisplay(AHost: TXcomStateHost): Boolean;
begin
  Result := AHost.Options.KeepAspectRatio;
  AHost.Options.KeepAspectRatio := True;
  AHost.Options.BaseXResolution := XCOM_ORIGINAL_WIDTH;
  AHost.Options.BaseYResolution := XCOM_ORIGINAL_HEIGHT;
  AHost.Screen.ResetDisplay(False);
end;

class procedure TXcomCutsceneState.ResetDisplay(AHost: TXcomStateHost; AWasLetterboxed: Boolean);
begin
  AHost.Options.KeepAspectRatio := AWasLetterboxed;
  TXcomScreen.UpdateScale(AHost.Options, AHost.Options.GeoscapeScale, AHost.Options.BaseXGeoscape,
    AHost.Options.BaseYGeoscape, True);
  AHost.Screen.ResetDisplay(False);
end;

end.
