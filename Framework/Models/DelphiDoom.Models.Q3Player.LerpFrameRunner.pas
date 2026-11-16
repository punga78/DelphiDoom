{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, one level of       }
{  animation in time                                                           }
{                                                                              }
{  Port of CG_SetLerpFrameAnimation, CG_RunLerpFrame and CG_ClearLerpFrame of  }
{  cgame\cg_players.c. The time (cg.time) is an argument: no clock here. Based }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.LerpFrameRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   Moves a TQ3LerpFrame through the animations of a configuration: when the time passes
  ///   FrameTime the frame becomes the old frame and the next one is computed (looping, reversed,
  ///   or stuck at the end); BackLerp says where the time is between the two.
  /// </summary>
  TQ3LerpFrameRunner = class(TInterfacedObject, IQ3LerpFrameRunner)
  strict private
    FConfig: IQ3AnimationConfig;
    FAnimationsEnabled: Boolean;
  public
    /// <summary>
    ///   AAnimationsEnabled is cg_animSpeed (0 turns the animations off: all frames 0, a debugging tool of the original)
    /// </summary>
    constructor Create(const AConfig: IQ3AnimationConfig; const AAnimationsEnabled: Boolean = True);
    /// <summary>CG_SetLerpFrameAnimation; ANewAnimation may include Q3_ANIM_TOGGLEBIT</summary>
    procedure SetAnimation(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer);
    /// <summary>CG_ClearLerpFrame: starts the animation at its first frame, at ATime</summary>
    procedure Clear(var AFrame: TQ3LerpFrame; const AAnimationNumber, ATime: Integer);
    /// <summary>CG_RunLerpFrame</summary>
    procedure Run(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer; const ASpeedScale: Single;
      const ATime: Integer);
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.FloatMath;

constructor TQ3LerpFrameRunner.Create(const AConfig: IQ3AnimationConfig; const AAnimationsEnabled: Boolean);
begin
  inherited Create;
  FConfig := AConfig;
  FAnimationsEnabled := AAnimationsEnabled;
end;

procedure TQ3LerpFrameRunner.SetAnimation(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer);
var
  LAnimationIndex: Integer;
begin
  AFrame.AnimationNumber := ANewAnimation;
  LAnimationIndex := ANewAnimation and not Q3_ANIM_TOGGLEBIT;
  if (LAnimationIndex < 0) or (LAnimationIndex >= Q3_MAX_TOTAL_ANIMATIONS) then
    raise EQ3PlayerException.CreateAtLine(Format(SQ3BadAnimationNumber, [LAnimationIndex]), 0);
  AFrame.HasAnimation := True;
  AFrame.AnimationIndex := LAnimationIndex;
  AFrame.AnimationTime := AFrame.FrameTime + FConfig.Animations[LAnimationIndex].InitialLerp;
end;

procedure TQ3LerpFrameRunner.Clear(var AFrame: TQ3LerpFrame; const AAnimationNumber, ATime: Integer);
begin
  AFrame.FrameTime := ATime;
  AFrame.OldFrameTime := ATime;
  SetAnimation(AFrame, AAnimationNumber);
  AFrame.Frame := FConfig.Animations[AFrame.AnimationIndex].FirstFrame;
  AFrame.OldFrame := AFrame.Frame;
end;

procedure TQ3LerpFrameRunner.Run(var AFrame: TQ3LerpFrame; const ANewAnimation: Integer;
  const ASpeedScale: Single; const ATime: Integer);
var
  LAnimation: TQ3Animation;
  LFrameNumber, LNumFrames: Integer;
  LScaled, LElapsed, LSpan: Single;
  LRatio: Single;
begin
  // debugging tool to get no animations
  if not FAnimationsEnabled then
  begin
    AFrame.OldFrame := 0;
    AFrame.Frame := 0;
    AFrame.BackLerp := 0;
    Exit;
  end;

  // see if the animation sequence is switching
  if (ANewAnimation <> AFrame.AnimationNumber) or not AFrame.HasAnimation then
    SetAnimation(AFrame, ANewAnimation);

  // if we have passed the current frame, move it to oldFrame and calculate a new frame
  if ATime >= AFrame.FrameTime then
  begin
    AFrame.OldFrame := AFrame.Frame;
    AFrame.OldFrameTime := AFrame.FrameTime;

    // get the next frame based on the animation
    LAnimation := FConfig.Animations[AFrame.AnimationIndex];
    if LAnimation.FrameLerp = 0 then
      Exit; // shouldn't happen
    if ATime < AFrame.AnimationTime then
      AFrame.FrameTime := AFrame.AnimationTime // initial lerp
    else
      AFrame.FrameTime := AFrame.OldFrameTime + LAnimation.FrameLerp;
    LFrameNumber := (AFrame.FrameTime - AFrame.AnimationTime) div LAnimation.FrameLerp;
    // f *= speedScale: the int is a float for the product and is truncated back
    LScaled := LFrameNumber;
    LScaled := LScaled * ASpeedScale;
    LFrameNumber := TQ3FloatMath.ToInt(Double(LScaled));

    LNumFrames := LAnimation.NumFrames;
    if LAnimation.Flipflop then
      LNumFrames := LNumFrames * 2;
    if LFrameNumber >= LNumFrames then
    begin
      LFrameNumber := LFrameNumber - LNumFrames;
      if LAnimation.LoopFrames <> 0 then
      begin
        LFrameNumber := LFrameNumber mod LAnimation.LoopFrames;
        LFrameNumber := LFrameNumber + LAnimation.NumFrames - LAnimation.LoopFrames;
      end
      else
      begin
        LFrameNumber := LNumFrames - 1;
        // the animation is stuck at the end, so it can immediately transition to another sequence
        AFrame.FrameTime := ATime;
      end;
    end;
    if LAnimation.Reversed then
      AFrame.Frame := LAnimation.FirstFrame + LAnimation.NumFrames - 1 - LFrameNumber
    else if LAnimation.Flipflop and (LFrameNumber >= LAnimation.NumFrames) then
      AFrame.Frame := LAnimation.FirstFrame + LAnimation.NumFrames - 1 - (LFrameNumber mod LAnimation.NumFrames)
    else
      AFrame.Frame := LAnimation.FirstFrame + LFrameNumber;
    if ATime > AFrame.FrameTime then
      AFrame.FrameTime := ATime;
  end;

  if AFrame.FrameTime > ATime + 200 then
    AFrame.FrameTime := ATime;

  if AFrame.OldFrameTime > ATime then
    AFrame.OldFrameTime := ATime;
  // calculate current lerp value
  if AFrame.FrameTime = AFrame.OldFrameTime then
    AFrame.BackLerp := 0
  else
  begin
    // 1.0 - (float)(time - oldFrameTime) / (frameTime - oldFrameTime): a float division, the
    // subtraction in double, the result stored in a float
    LElapsed := ATime - AFrame.OldFrameTime;
    LSpan := AFrame.FrameTime - AFrame.OldFrameTime;
    LRatio := LElapsed / LSpan;
    AFrame.BackLerp := Single(1.0 - Double(LRatio));
  end;
end;

end.
