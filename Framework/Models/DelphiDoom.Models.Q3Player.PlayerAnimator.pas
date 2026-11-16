{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the two levels of  }
{  animation of a player                                                       }
{                                                                              }
{  Port of CG_PlayerAnimation of cgame\cg_players.c. Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.PlayerAnimator;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   Runs the legs and the torso of a player: the legs turn on the spot (LEGS_TURN) while the
  ///   legs are idle and still swinging to the direction of the view; the haste power-up makes
  ///   both go 1.5 times faster.
  /// </summary>
  TQ3PlayerAnimator = class(TInterfacedObject, IQ3PlayerAnimator)
  strict private
    FRunner: IQ3LerpFrameRunner;
    FNoPlayerAnimations: Boolean;
  public
    /// <summary>ANoPlayerAnimations is cg_noPlayerAnims: every frame is 0</summary>
    constructor Create(const ARunner: IQ3LerpFrameRunner; const ANoPlayerAnimations: Boolean = False);
    procedure Animate(var APlayer: TQ3PlayerEntity; const ATime, ALegsAnim, ATorsoAnim: Integer;
      const AHaste: Boolean; out AFrames: TQ3PlayerFrames);
  end;

implementation

constructor TQ3PlayerAnimator.Create(const ARunner: IQ3LerpFrameRunner; const ANoPlayerAnimations: Boolean);
begin
  inherited Create;
  FRunner := ARunner;
  FNoPlayerAnimations := ANoPlayerAnimations;
end;

procedure TQ3PlayerAnimator.Animate(var APlayer: TQ3PlayerEntity; const ATime, ALegsAnim, ATorsoAnim: Integer;
  const AHaste: Boolean; out AFrames: TQ3PlayerFrames);
var
  LSpeedScale: Single;
begin
  FillChar(AFrames, SizeOf(AFrames), 0);
  if FNoPlayerAnimations then
    Exit;

  if AHaste then
    LSpeedScale := 1.5
  else
    LSpeedScale := 1;

  // do the shuffle turn frames locally
  if APlayer.Legs.Yawing and ((ALegsAnim and not Q3_ANIM_TOGGLEBIT) = Q3_LEGS_IDLE) then
    FRunner.Run(APlayer.Legs, Q3_LEGS_TURN, LSpeedScale, ATime)
  else
    FRunner.Run(APlayer.Legs, ALegsAnim, LSpeedScale, ATime);

  AFrames.LegsOld := APlayer.Legs.OldFrame;
  AFrames.Legs := APlayer.Legs.Frame;
  AFrames.LegsBackLerp := APlayer.Legs.BackLerp;

  FRunner.Run(APlayer.Torso, ATorsoAnim, LSpeedScale, ATime);

  AFrames.TorsoOld := APlayer.Torso.OldFrame;
  AFrames.Torso := APlayer.Torso.Frame;
  AFrames.TorsoBackLerp := APlayer.Torso.BackLerp;
end;

end.
