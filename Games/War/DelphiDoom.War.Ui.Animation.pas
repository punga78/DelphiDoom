{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - an animation of a sprite                          }
{                                                                              }
{  Port of war1 (acoto87/war1), war_animations.c (WarSpriteAnimation:          }
{  wanim_createAnimation, wanim_addAnimationFramesRange,                       }
{  wanim_getAnimationDuration, wanim_updateAnimation, wanim_resetAnimation)    }
{  and renderAnimation of war_entities.c, (c) 2019 Alejandro Coto Gutierrez,   }
{  zlib License (see Games\War\LICENSE-war1.txt). This is an altered version,  }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Animation;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Render.Transform, DelphiDoom.War.Ui.Intf;

type
  /// <summary>WarAnimationStatus</summary>
  TWarAnimationStatus = (wasNotStarted, wasRunning, wasFinished);

  /// <summary>
  ///   A sprite that shows its frames in the order of a list, one after the other, in FrameDelay * frames seconds, with
  ///   a pause of LoopDelay between two rounds if it loops. The time is in Single like the original
  /// </summary>
  TWarUiAnimation = class
  strict private
    FName: AnsiString;
    FSprite: IWarUiSprite;
    FFrames: TList<Integer>;
    FFrameDelay: Single;
    FLoop: Boolean;
    FLoopDelay: Single;
    FOffsetX: Single;
    FOffsetY: Single;
    FScaleX: Single;
    FScaleY: Single;
    FAnimTime: Single;
    FLoopTime: Single;
    FStatus: TWarAnimationStatus;
    function GetFrameCount: Integer;
  public
    constructor Create(const AName: AnsiString; const ASprite: IWarUiSprite; AFrameDelay: Single; ALoop: Boolean);
    destructor Destroy; override;
    /// <summary>wanim_addAnimationFrame</summary>
    procedure AddFrame(AFrameIndex: Integer);
    /// <summary>wanim_addAnimationFramesRange: from to to, both included, up or down</summary>
    procedure AddFramesRange(AFrom, ATo: Integer);
    /// <summary>wanim_getAnimationDuration: the delay of a frame times the frames</summary>
    function Duration: Single;
    /// <summary>wanim_resetAnimation</summary>
    procedure Reset;
    /// <summary>
    ///   wanim_updateAnimation (without the removal of a finished animation: the caller does it, it knows the list). In a
    ///   scene the time passes at the real delta times the global speed; in a map it is the delta of the game
    /// </summary>
    procedure Update(AInScene: Boolean; ARealDeltaTime, AGlobalSpeed, AGameDeltaTime: Single);
    /// <summary>
    ///   renderAnimation of one running animation: the frame of the time goes to the texture and is drawn at the offset, with
    ///   the scale (EWarException if a frame of the list is not in the sprite; the original asserts)
    /// </summary>
    procedure Render(const ATransform: TWarRenderTransform);
    property Name: AnsiString read FName;
    property Status: TWarAnimationStatus read FStatus;
    property LoopDelay: Single read FLoopDelay write FLoopDelay;
    property OffsetX: Single read FOffsetX write FOffsetX;
    property OffsetY: Single read FOffsetY write FOffsetY;
    property ScaleX: Single read FScaleX write FScaleX;
    property ScaleY: Single read FScaleY write FScaleY;
    property AnimTime: Single read FAnimTime;
    property LoopTime: Single read FLoopTime;
    property FrameCount: Integer read GetFrameCount;
  end;

implementation

uses
  DelphiDoom.War.Ui.Sprite;

{ TWarUiAnimation }

constructor TWarUiAnimation.Create(const AName: AnsiString; const ASprite: IWarUiSprite; AFrameDelay: Single;
  ALoop: Boolean);
begin
  inherited Create;
  FName := AName;
  FSprite := ASprite;
  FFrameDelay := AFrameDelay;
  FLoop := ALoop;
  FScaleX := 1;
  FScaleY := 1;
  FStatus := wasNotStarted;
  FFrames := TList<Integer>.Create;
end;

destructor TWarUiAnimation.Destroy;
begin
  FFrames.Free;
  inherited Destroy;
end;

function TWarUiAnimation.GetFrameCount: Integer;
begin
  Result := FFrames.Count;
end;

procedure TWarUiAnimation.AddFrame(AFrameIndex: Integer);
begin
  FFrames.Add(AFrameIndex);
end;

procedure TWarUiAnimation.AddFramesRange(AFrom, ATo: Integer);
var
  LIndex: Integer;
begin
  if AFrom < ATo then
    for LIndex := AFrom to ATo do
      AddFrame(LIndex)
  else
    for LIndex := AFrom downto ATo do
      AddFrame(LIndex);
end;

function TWarUiAnimation.Duration: Single;
begin
  Result := FFrameDelay * FFrames.Count;
end;

procedure TWarUiAnimation.Reset;
begin
  FAnimTime := 0;
  FLoopTime := 0;
  FStatus := wasNotStarted;
end;

procedure TWarUiAnimation.Update(AInScene: Boolean; ARealDeltaTime, AGlobalSpeed, AGameDeltaTime: Single);
var
  LStep: Single;
  LDelta: Single;
begin
  FStatus := wasRunning;
  if FLoopTime > 0 then
  begin
    if AInScene then
    begin
      LStep := ARealDeltaTime * AGlobalSpeed;
      FLoopTime := FLoopTime - LStep;
    end
    else
      FLoopTime := FLoopTime - AGameDeltaTime;
    Exit;
  end;
  LDelta := ARealDeltaTime / Duration;
  if AInScene then
    LDelta := LDelta * AGlobalSpeed
  else
    LDelta := AGameDeltaTime / Duration;
  FAnimTime := FAnimTime + LDelta;
  if FAnimTime >= 1 then
  begin
    FAnimTime := 1;
    FStatus := wasFinished;
    if FLoop then
    begin
      Reset;
      FLoopTime := FLoopDelay;
      FStatus := wasRunning;
    end;
  end;
end;

procedure TWarUiAnimation.Render(const ATransform: TWarRenderTransform);
var
  LScaled: Single;
  LFrameIndex: Integer;
begin
  if FStatus <> wasRunning then
    Exit;
  ATransform.Save;
  ATransform.Translate(FOffsetX, FOffsetY);
  ATransform.Scale(FScaleX, FScaleY);
  LScaled := FAnimTime * FFrames.Count;
  LFrameIndex := Trunc(LScaled);
  if LFrameIndex > FFrames.Count - 1 then
    LFrameIndex := FFrames.Count - 1;
  if LFrameIndex < 0 then
    LFrameIndex := 0;
  FSprite.UpdateImage(FFrames[LFrameIndex]);
  TWarUiSprite.Draw(ATransform, FSprite);
  ATransform.Restore;
end;

end.
