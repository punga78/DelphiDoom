{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the scene of the animations of the game           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SceneCinematics;

interface

uses
  System.SysUtils, DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.War.Graphics.Types, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.SceneBase;

const
  /// <summary>
  ///   The introduction of the game, in order: the cave (once), the cave at the gate (loops until a key), the gate that opens
  ///   (with its sound), the title (with "Welcome to the World of Warcraft"). The order is a decision of the port: the
  ///   original has the button "Replay introduction" and no code behind it, and the animations say only their names
  /// </summary>
  WAR_INTRODUCTION_ANIMATIONS: array[0..3] of string = ('CAVE1', 'CAVE2', 'CAVE3', 'TITLE');

type
  /// <summary>
  ///   Plays animations one after the other through the director of the services and then goes on to the main menu. A key
  ///   (not Shift, Ctrl or Alt) or a click skips the animation that is playing; Esc skips the rest of them too. An animation
  ///   that the game has not got (a file that is not there) is passed over. The time of an animation is the real time of
  ///   the game (the scene reads no clock), so a game played again from a saved one shows the same frames. It is the port's
  ///   own scene: it has no cheat panel and no animations of the interface
  /// </summary>
  TWarSceneCinematics = class(TWarSceneBase)
  strict private
    FNames: TArray<string>;
    FNextIndex: Integer;
    FScene: IFlicScene;
    FStartRealTime: Double;
    FImage: TWarImage;
    FDone: Boolean;
    procedure OpenNext;
    procedure Finish;
    function SkipRequested(out ASkipAll: Boolean): Boolean;
    procedure TakeImage(const AFrame: TFlicSceneFrame);
  strict protected
    procedure DoEnter; override;
    procedure DoUpdate; override;
    procedure DoRender; override;
  public
    /// <param name="ANames">The animations, in order</param>
    constructor Create(const AServices: TWarSceneServices; const ANames: array of string);
    function GetSceneType: TWarSceneType; override;
    /// <summary>The scene has gone on to the main menu (or has nothing to play)</summary>
    property Done: Boolean read FDone;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types, DelphiDoom.Flic.Types, DelphiDoom.War.Types, DelphiDoom.War.Level.Types,
  DelphiDoom.War.Render.Types, DelphiDoom.War.Ui.Intf;

{ TWarSceneCinematics }

constructor TWarSceneCinematics.Create(const AServices: TWarSceneServices; const ANames: array of string);
var
  LIndex: Integer;
begin
  inherited Create(AServices);
  SetLength(FNames, Length(ANames));
  for LIndex := 0 to High(ANames) do
    FNames[LIndex] := ANames[LIndex];
end;

function TWarSceneCinematics.GetSceneType: TWarSceneType;
begin
  Result := wstCinematics;
end;

procedure TWarSceneCinematics.OpenNext;
begin
  FScene := nil;
  FImage := Default(TWarImage);
  while (not Assigned(FScene)) and (FNextIndex < Length(FNames)) do
  begin
    try
      // the race only matters to the animations whose sound is an event of the game (the endings): none of these
      FScene := Services.Cinematics.TryOpen(FNames[FNextIndex], wraNeutral);
    except
      // a file that is there and is not an animation is passed over like one that is not there: a broken file of the
      // animations must not stop the game that is going to the menu
      on ECinematicException do
        FScene := nil;
      on EFlicFormatException do
        FScene := nil;
    end;
    Inc(FNextIndex);
  end;
  FStartRealTime := Services.Host.RealTime;
end;

procedure TWarSceneCinematics.Finish;
begin
  FDone := True;
  FScene := nil;
  Services.Host.SetNextScene(Services.Scenes.CreateMainMenu, 0.3);
end;

procedure TWarSceneCinematics.DoEnter;
begin
  FNextIndex := 0;
  FDone := False;
  if Assigned(Services.Audio) then
    Services.Audio.StopMusic;
  OpenNext;
end;

function TWarSceneCinematics.SkipRequested(out ASkipAll: Boolean): Boolean;
var
  LKey: TWarKey;
begin
  ASkipAll := Services.Input.IsKeyJustPressed(wkEsc);
  Result := ASkipAll or Services.Input.IsButtonJustPressed(wmbLeft) or Services.Input.IsButtonJustPressed(wmbRight);
  for LKey := Succ(wkNone) to High(TWarKey) do
    if not (LKey in [wkShift, wkCtrl, wkAlt]) then
      if Services.Input.IsKeyJustPressed(LKey) then
        Result := True;
end;

procedure TWarSceneCinematics.TakeImage(const AFrame: TFlicSceneFrame);
var
  LCount: Integer;
begin
  if (AFrame.Image.Width <= 0) or (AFrame.Image.Height <= 0) then
    Exit;
  if (not AFrame.FrameChanged) and (FImage.Width = AFrame.Image.Width) then
    Exit;
  // the pixels are $AABBGGRR words: in memory R, G, B, A, as the canvas has them
  LCount := AFrame.Image.Width * AFrame.Image.Height;
  FImage.Width := Word(AFrame.Image.Width);
  FImage.Height := Word(AFrame.Image.Height);
  SetLength(FImage.Pixels, LCount * WAR_PIXEL_SIZE);
  Move(AFrame.Image.Pixels[0], FImage.Pixels[0], LCount * WAR_PIXEL_SIZE);
end;

procedure TWarSceneCinematics.DoUpdate;
var
  LFrame: TFlicSceneFrame;
  LSkipAll: Boolean;
  LSkip: Boolean;
begin
  if FDone then
    Exit;
  if not Assigned(FScene) then
  begin
    Finish;
    Exit;
  end;
  LSkip := SkipRequested(LSkipAll);
  LFrame := FScene.Update(Round((Services.Host.RealTime - FStartRealTime) * 1000), LSkip);
  TakeImage(LFrame);
  if LFrame.State in [fssEnded, fssSkipped] then
  begin
    if LSkipAll then
      FNextIndex := Length(FNames);
    OpenNext;
    if not Assigned(FScene) then
      Finish;
  end;
end;

procedure TWarSceneCinematics.DoRender;
var
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  if (FImage.Width = 0) or (FImage.Height = 0) then
    Exit;
  LSource.X := 0;
  LSource.Y := 0;
  LSource.Width := FImage.Width;
  LSource.Height := FImage.Height;
  LDestination.X := 0;
  LDestination.Y := 0;
  LDestination.Width := Services.Canvas.Blitter.Width;
  LDestination.Height := Services.Canvas.Blitter.Height;
  // the picture of an animation fills the screen (320 x 200 in the files that we have: one pixel to one)
  Services.Canvas.Transform.SubImageOf(FImage, LSource, LDestination, 1, 1);
end;

end.
