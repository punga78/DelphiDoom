{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types of the "articulatedFigure"          }
{  declaration                                                                 }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.h, DeclAF.cpp. Copyright (C) 1999-2011 id Software LLC,    }
{  a ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software). }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.Decl.Types, DelphiDoom.Decl.Material.Types;

const
  /// <summary>idDeclAF_Constraint::LIMIT_NONE: no limit (an enum value of -1 in the original)</summary>
  AF_LIMIT_NONE = -1;
  /// <summary>idDeclAF_Constraint::LIMIT_CONE</summary>
  AF_LIMIT_CONE = 0;
  /// <summary>idDeclAF_Constraint::LIMIT_PYRAMID</summary>
  AF_LIMIT_PYRAMID = 1;

type
  /// <summary>A problem found while using an articulated figure declaration</summary>
  EDeclArticulatedFigureException = class(EDeclException);

  /// <summary>declAFConstraintType_t</summary>
  TAfConstraintType = (actInvalid, actFixed, actBallAndSocketJoint, actUniversalJoint, actHinge, actSlider, actSpring);

  /// <summary>declAFJointMod_t: what a body changes of its joint</summary>
  TAfJointMod = (ajmAxis, ajmOrigin, ajmBoth);

  /// <summary>
  ///   The shape of a body: the values and the order of <c>TRM_*</c> of idTraceModel, so that a caller turns it into
  ///   a <c>TTraceModelKind</c> of <c>Libs\Geometry</c> by its ordinal (the declaration itself does not build any model)
  /// </summary>
  TAfBodyModel = (abmInvalid, abmBox, abmOctahedron, abmDodecahedron, abmCylinder, abmCone, abmBone);

  /// <summary>The ways a vector is given in the text (idAFVector::VEC_*)</summary>
  TAfVectorKind = (avkCoords, avkJoint, avkBoneCenter, avkBoneDir);

  /// <summary>
  ///   idAFVector: coordinates or a place computed from joints at <c>Finish</c>. <c>Vec</c> is the value (the
  ///   coordinates until <c>Finish</c> gets the joints); <c>Negate</c> flips it.
  /// </summary>
  TAfVector = record
    Kind: TAfVectorKind;
    Joint1: AnsiString;
    Joint2: AnsiString;
    Vec: TIdVec3;
    Negate: Boolean;
    /// <summary>idAFVector::idAFVector: coordinates, zero, not negated</summary>
    class function Create: TAfVector; static;
    /// <summary>Coordinates (the <c>v.ToVec3().Set(...)</c> of the defaults)</summary>
    class function FromCoords(const AX, AY, AZ: Single): TAfVector; static;
  end;

  /// <summary>The data of idDeclAF that is not a list: the defaults of the bodies, the masks and the model it is for</summary>
  TAfSettings = record
    /// <summary>The editor has changed the declaration and not saved it</summary>
    Modified: Boolean;
    Model: AnsiString;
    Skin: AnsiString;
    DefaultLinearFriction: Single;
    DefaultAngularFriction: Single;
    DefaultContactFriction: Single;
    DefaultConstraintFriction: Single;
    TotalMass: Single;
    SuspendVelocity: TIdVec2;
    SuspendAcceleration: TIdVec2;
    NoMoveTime: Single;
    NoMoveTranslation: Single;
    NoMoveRotation: Single;
    MinMoveTime: Single;
    MaxMoveTime: Single;
    Contents: Integer;
    ClipMask: Integer;
    SelfCollision: Boolean;
    /// <summary>
    ///   What idDeclAF::FreeData sets: the numbers, the flags and the masks. Like the original it does not clear
    ///   <c>Model</c> and <c>Skin</c>.
    /// </summary>
    procedure ResetNumbers;
  end;

  /// <summary>idDeclAF_Body: a rigid body of the figure</summary>
  TAfBody = record
    Name: AnsiString;
    JointName: AnsiString;
    JointMod: TAfJointMod;
    ModelType: TAfBodyModel;
    V1: TAfVector;
    V2: TAfVector;
    NumSides: Integer;
    Width: Single;
    Density: Single;
    Origin: TAfVector;
    Angles: TIdAngles;
    Contents: Integer;
    ClipMask: Integer;
    SelfCollision: Boolean;
    InertiaScale: TIdMat3;
    LinearFriction: Single;
    AngularFriction: Single;
    ContactFriction: Single;
    ContainedJoints: AnsiString;
    FrictionDirection: TAfVector;
    ContactMotorDirection: TAfVector;
    /// <summary>
    ///   idDeclAF_Body::SetDefault: a box of 20 units named "noname" on the joint "origin", with the friction,
    ///   contents, clip mask and self collision of the settings. <c>Width</c> is not set by the original (it is memory
    ///   that was not initialised): here it is zero.
    /// </summary>
    procedure SetDefault(const ASettings: TAfSettings);
  end;

  /// <summary>idDeclAF_Constraint: a joint between two bodies (or a body and the "world")</summary>
  TAfConstraint = record
    Name: AnsiString;
    Body1: AnsiString;
    Body2: AnsiString;
    ConstraintType: TAfConstraintType;
    Friction: Single;
    Stretch: Single;
    Compress: Single;
    Damping: Single;
    RestLength: Single;
    MinLength: Single;
    MaxLength: Single;
    Anchor: TAfVector;
    Anchor2: TAfVector;
    Shaft: array[0..1] of TAfVector;
    Axis: TAfVector;
    /// <summary><c>AF_LIMIT_NONE</c>, <c>AF_LIMIT_CONE</c> or <c>AF_LIMIT_PYRAMID</c></summary>
    Limit: Integer;
    LimitAxis: TAfVector;
    LimitAngles: array[0..2] of Single;
    /// <summary>
    ///   idDeclAF_Constraint::SetDefault: a universal joint named "noname" between the first body of the figure (or
    ///   "world") and "world". The spring values (<c>Stretch</c> ... <c>MaxLength</c>) are not set by the original:
    ///   here they are zero.
    /// </summary>
    procedure SetDefault(const ASettings: TAfSettings; const ABodies: TArray<TAfBody>);
  end;

implementation

{ TAfVector }

class function TAfVector.Create: TAfVector;
begin
  Result.Kind := avkCoords;
  Result.Joint1 := '';
  Result.Joint2 := '';
  Result.Vec.Zero;
  Result.Negate := False;
end;

class function TAfVector.FromCoords(const AX, AY, AZ: Single): TAfVector;
begin
  Result := Create;
  Result.Vec.SetValues(AX, AY, AZ);
end;

{ TAfSettings }

procedure TAfSettings.ResetNumbers;
begin
  Modified := False;
  DefaultLinearFriction := 0.01;
  DefaultAngularFriction := 0.01;
  DefaultContactFriction := 0.8;
  DefaultConstraintFriction := 0.5;
  TotalMass := -1;
  SuspendVelocity.SetValues(20.0, 30.0);
  SuspendAcceleration.SetValues(40.0, 60.0);
  NoMoveTime := 1.0;
  NoMoveTranslation := 10.0;
  NoMoveRotation := 10.0;
  MinMoveTime := -1.0;
  MaxMoveTime := -1.0;
  SelfCollision := True;
  Contents := CONTENTS_CORPSE;
  ClipMask := CONTENTS_SOLID or CONTENTS_CORPSE;
end;

{ TAfBody }

procedure TAfBody.SetDefault(const ASettings: TAfSettings);
begin
  Self := Default(TAfBody);
  Name := 'noname';
  ModelType := abmBox;
  V1 := TAfVector.FromCoords(-10.0, -10.0, -10.0);
  V2 := TAfVector.FromCoords(10.0, 10.0, 10.0);
  NumSides := 3;
  Origin := TAfVector.Create;
  Angles.Zero;
  Density := 0.2;
  InertiaScale := TIdMat3.Identity;
  LinearFriction := ASettings.DefaultLinearFriction;
  AngularFriction := ASettings.DefaultAngularFriction;
  ContactFriction := ASettings.DefaultContactFriction;
  Contents := ASettings.Contents;
  ClipMask := ASettings.ClipMask;
  SelfCollision := ASettings.SelfCollision;
  FrictionDirection := TAfVector.Create;
  ContactMotorDirection := TAfVector.Create;
  JointName := 'origin';
  JointMod := ajmAxis;
  ContainedJoints := '*origin';
end;

{ TAfConstraint }

procedure TAfConstraint.SetDefault(const ASettings: TAfSettings; const ABodies: TArray<TAfBody>);
begin
  Self := Default(TAfConstraint);
  Name := 'noname';
  ConstraintType := actUniversalJoint;
  if Length(ABodies) > 0 then
    Body1 := ABodies[0].Name
  else
    Body1 := 'world';
  Body2 := 'world';
  Friction := ASettings.DefaultConstraintFriction;
  Anchor := TAfVector.Create;
  Anchor2 := TAfVector.Create;
  Axis := TAfVector.FromCoords(1.0, 0.0, 0.0);
  Shaft[0] := TAfVector.FromCoords(0.0, 0.0, -1.0);
  Shaft[1] := TAfVector.FromCoords(0.0, 0.0, 1.0);
  Limit := AF_LIMIT_NONE;
  LimitAngles[0] := 0.0;
  LimitAngles[1] := 0.0;
  LimitAngles[2] := 0.0;
  LimitAxis := TAfVector.FromCoords(0.0, 0.0, -1.0);
end;

end.
