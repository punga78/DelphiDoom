{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the                }
{  configuration of animation.cfg                                              }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the fields of   }
{  clientInfo_t that CG_ParseAnimationFile fills. Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.AnimationConfig;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>The result of parsing an animation.cfg: options and the table of animations</summary>
  TQ3AnimationConfig = class(TInterfacedObject, IQ3AnimationConfig)
  strict private
    FFootsteps: TQ3Footsteps;
    FGender: TQ3Gender;
    FFixedLegs: Boolean;
    FFixedTorso: Boolean;
    FHeadOffset: TIdVec3;
    FAnimations: array[0..Q3_MAX_TOTAL_ANIMATIONS - 1] of TQ3Animation;
    function GetFootsteps: TQ3Footsteps;
    function GetGender: TQ3Gender;
    function GetFixedLegs: Boolean;
    function GetFixedTorso: Boolean;
    function GetHeadOffset: TIdVec3;
    function GetAnimation(const AIndex: Integer): TQ3Animation;
  public
    /// <summary>The defaults of the parser: normal footsteps, male, no offset, no fixed parts, all animations zero</summary>
    constructor Create;
    procedure SetFootsteps(const AValue: TQ3Footsteps);
    procedure SetGender(const AValue: TQ3Gender);
    procedure SetFixedLegs(const AValue: Boolean);
    procedure SetFixedTorso(const AValue: Boolean);
    procedure SetHeadOffset(const AValue: TIdVec3);
    procedure SetAnimation(const AIndex: Integer; const AValue: TQ3Animation);
  end;

implementation

constructor TQ3AnimationConfig.Create;
begin
  inherited Create;
  FFootsteps := qfNormal;
  FGender := qgMale;
  FHeadOffset.Zero;
  FillChar(FAnimations, SizeOf(FAnimations), 0);
end;

function TQ3AnimationConfig.GetFootsteps: TQ3Footsteps;
begin
  Result := FFootsteps;
end;

function TQ3AnimationConfig.GetGender: TQ3Gender;
begin
  Result := FGender;
end;

function TQ3AnimationConfig.GetFixedLegs: Boolean;
begin
  Result := FFixedLegs;
end;

function TQ3AnimationConfig.GetFixedTorso: Boolean;
begin
  Result := FFixedTorso;
end;

function TQ3AnimationConfig.GetHeadOffset: TIdVec3;
begin
  Result := FHeadOffset;
end;

function TQ3AnimationConfig.GetAnimation(const AIndex: Integer): TQ3Animation;
begin
  if (AIndex < 0) or (AIndex >= Q3_MAX_TOTAL_ANIMATIONS) then
    raise EArgumentOutOfRangeException.CreateFmt(SQ3BadAnimationNumber, [AIndex]);
  Result := FAnimations[AIndex];
end;

procedure TQ3AnimationConfig.SetFootsteps(const AValue: TQ3Footsteps);
begin
  FFootsteps := AValue;
end;

procedure TQ3AnimationConfig.SetGender(const AValue: TQ3Gender);
begin
  FGender := AValue;
end;

procedure TQ3AnimationConfig.SetFixedLegs(const AValue: Boolean);
begin
  FFixedLegs := AValue;
end;

procedure TQ3AnimationConfig.SetFixedTorso(const AValue: Boolean);
begin
  FFixedTorso := AValue;
end;

procedure TQ3AnimationConfig.SetHeadOffset(const AValue: TIdVec3);
begin
  FHeadOffset := AValue;
end;

procedure TQ3AnimationConfig.SetAnimation(const AIndex: Integer; const AValue: TQ3Animation);
begin
  if (AIndex < 0) or (AIndex >= Q3_MAX_TOTAL_ANIMATIONS) then
    raise EArgumentOutOfRangeException.CreateFmt(SQ3BadAnimationNumber, [AIndex]);
  FAnimations[AIndex] := AValue;
end;

end.
