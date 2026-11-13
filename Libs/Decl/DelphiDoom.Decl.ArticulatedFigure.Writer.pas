{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - writing the "articulatedFigure"           }
{  declaration                                                                 }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idAFVector::Write and ToString, WriteBody,            }
{  WriteConstraint and its kinds, WriteSettings, RebuildTextSource).           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>
  ///   Writes the text the figure editor of Doom 3 writes (what <c>RebuildTextSource</c> puts in the declaration). A number
  ///   is written as <c>idFile::WriteFloatString</c> writes <c>%f</c>: ten decimals, the trailing zeros and the point cut,
  ///   with a point whatever the locale. A body of an unknown model writes no <c>model</c> line.
  /// </summary>
  TAfWriter = class sealed
  strict private
    class function Fixed(const AValue: Single; const ADecimals: Integer): string; static;
    class function Plain(const AValue: Single): AnsiString; static;
    class function WriteVector(const AVector: TAfVector): AnsiString; static;
    class function WriteBody(const ABody: TAfBody): AnsiString; static;
    class function WriteConstraint(const AConstraint: TAfConstraint; out AText: AnsiString): Boolean; static;
    class function WriteSettings(const ASettings: TAfSettings): AnsiString; static;
  public
    /// <summary>
    ///   idDeclAF::RebuildTextSource: the comment of the editor, <c>articulatedFigure name {</c>, the settings, the
    ///   bodies and the constraints. False (and <c>AText</c> empty) when a constraint has no kind.
    /// </summary>
    class function RebuildText(const AName: AnsiString; const ASettings: TAfSettings; const ABodies: TArray<TAfBody>;
      const AConstraints: TArray<TAfConstraint>; out AText: AnsiString): Boolean; static;
    /// <summary>idAFVector::ToString: the text of a vector with <c>APrecision</c> decimals for the coordinates</summary>
    class function VectorToString(const AVector: TAfVector; const APrecision: Integer = 8): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Angles,
  DelphiDoom.Decl.ArticulatedFigure.Contents;

var
  GInvariant: TFormatSettings;

function Q(const AText: AnsiString): AnsiString; inline;
begin
  Result := '"' + AText + '"';
end;

{ TAfWriter }

// "%.*f" of C: the minus sign is there whenever the sign bit is set, also for a negative zero and for a number
// that rounds to zero ("-0.000"); the Format of Delphi drops it
class function TAfWriter.Fixed(const AValue: Single; const ADecimals: Integer): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := Format('%.*f', [ADecimals, Double(AValue)], GInvariant);
  if ((PCardinal(@LValue)^ and $80000000) <> 0) and not Result.StartsWith('-') then
    Result := '-' + Result;
end;

class function TAfWriter.Plain(const AValue: Single): AnsiString;
var
  LText: string;
begin
  LText := Fixed(AValue, 10);
  while (LText <> '') and (LText[Length(LText)] = '0') do
    Delete(LText, Length(LText), 1);
  while (LText <> '') and (LText[Length(LText)] = '.') do
    Delete(LText, Length(LText), 1);
  Result := AnsiString(LText);
end;

class function TAfWriter.WriteVector(const AVector: TAfVector): AnsiString;
begin
  Result := '';
  if AVector.Negate then
    Result := '-';
  case AVector.Kind of
    avkCoords:
      Result := Result + '( ' + Plain(AVector.Vec.X) + ', ' + Plain(AVector.Vec.Y) + ', ' + Plain(AVector.Vec.Z) + ' )';
    avkJoint:
      Result := Result + 'joint( ' + Q(AVector.Joint1) + ' )';
    avkBoneCenter:
      Result := Result + 'bonecenter( ' + Q(AVector.Joint1) + ', ' + Q(AVector.Joint2) + ' )';
    avkBoneDir:
      Result := Result + 'bonedir( ' + Q(AVector.Joint1) + ', ' + Q(AVector.Joint2) + ' )';
  end;
end;

class function TAfWriter.VectorToString(const AVector: TAfVector; const APrecision: Integer): AnsiString;
begin
  Result := '';
  case AVector.Kind of
    avkCoords:
      Result := AnsiString('( ' + Fixed(AVector.Vec.X, APrecision) + ', ' + Fixed(AVector.Vec.Y, APrecision) + ', ' +
        Fixed(AVector.Vec.Z, APrecision) + ' )');
    avkJoint:
      Result := 'joint( ' + Q(AVector.Joint1) + ' )';
    avkBoneCenter:
      Result := 'bonecenter( ' + Q(AVector.Joint1) + ', ' + Q(AVector.Joint2) + ' )';
    avkBoneDir:
      Result := 'bonedir( ' + Q(AVector.Joint1) + ', ' + Q(AVector.Joint2) + ' )';
  end;
  if AVector.Negate then
    Result := '-' + Result;
end;

class function TAfWriter.WriteBody(const ABody: TAfBody): AnsiString;
var
  LIndex: Integer;
  LRow: Integer;
  LShape: AnsiString;
begin
  Result := #10'body ' + Q(ABody.Name) + ' {'#10;
  Result := Result + #9'joint ' + Q(ABody.JointName) + #10;
  Result := Result + #9'mod ' + TAfContents.JointModToString(ABody.JointMod) + #10;
  case ABody.ModelType of
    abmBox: LShape := 'box';
    abmOctahedron: LShape := 'octahedron';
    abmDodecahedron: LShape := 'dodecahedron';
    abmCylinder: LShape := 'cylinder';
    abmCone: LShape := 'cone';
    abmBone: LShape := 'bone';
  else
    LShape := '';
  end;
  if LShape <> '' then
  begin
    Result := Result + #9'model ' + LShape + '( ' + WriteVector(ABody.V1) + ', ' + WriteVector(ABody.V2);
    case ABody.ModelType of
      abmCylinder, abmCone: Result := Result + ', ' + AnsiString(IntToStr(ABody.NumSides));
      abmBone: Result := Result + ', ' + Plain(ABody.Width);
    end;
    Result := Result + ' )'#10;
  end;
  Result := Result + #9'origin ' + WriteVector(ABody.Origin) + #10;
  if ABody.Angles <> TIdAngles.Create(0, 0, 0) then
    Result := Result + #9'angles ( ' + Plain(ABody.Angles.Pitch) + ', ' + Plain(ABody.Angles.Yaw) + ', ' +
      Plain(ABody.Angles.Roll) + ' )'#10;
  Result := Result + #9'density ' + Plain(ABody.Density) + #10;
  if ABody.InertiaScale <> TIdMat3.Identity then
  begin
    Result := Result + #9'inertiaScale (';
    for LRow := 0 to 2 do
      for LIndex := 0 to 2 do
      begin
        if (LRow > 0) or (LIndex > 0) then
          Result := Result + ' ';
        Result := Result + Plain(ABody.InertiaScale.Rows[LRow].Items[LIndex]);
      end;
    Result := Result + ')'#10;
  end;
  if ABody.LinearFriction <> -1 then
    Result := Result + #9'friction ' + Plain(ABody.LinearFriction) + ', ' + Plain(ABody.AngularFriction) + ', ' +
      Plain(ABody.ContactFriction) + #10;
  Result := Result + #9'contents ' + TAfContents.ContentsToString(ABody.Contents) + #10;
  Result := Result + #9'clipMask ' + TAfContents.ContentsToString(ABody.ClipMask) + #10;
  Result := Result + #9'selfCollision ' + AnsiString(IntToStr(Ord(ABody.SelfCollision))) + #10;
  if ABody.FrictionDirection.Vec <> TIdVec3.Create(0, 0, 0) then
    Result := Result + #9'frictionDirection ' + WriteVector(ABody.FrictionDirection) + #10;
  if ABody.ContactMotorDirection.Vec <> TIdVec3.Create(0, 0, 0) then
    Result := Result + #9'contactMotorDirection ' + WriteVector(ABody.ContactMotorDirection) + #10;
  Result := Result + #9'containedJoints ' + Q(ABody.ContainedJoints) + #10;
  Result := Result + '}'#10;
end;

class function TAfWriter.WriteConstraint(const AConstraint: TAfConstraint; out AText: AnsiString): Boolean;
var
  LKeyword: AnsiString;

  function Pyramid: AnsiString;
  begin
    Result := Plain(AConstraint.LimitAngles[0]) + ', ' + Plain(AConstraint.LimitAngles[1]) + ', ' +
      Plain(AConstraint.LimitAngles[2]);
  end;

begin
  Result := True;
  case AConstraint.ConstraintType of
    actFixed: LKeyword := 'fixed';
    actBallAndSocketJoint: LKeyword := 'ballAndSocketJoint';
    actUniversalJoint: LKeyword := 'universalJoint';
    actHinge: LKeyword := 'hinge';
    actSlider: LKeyword := 'slider';
    actSpring: LKeyword := 'spring';
  else
    AText := '';
    Exit(False);
  end;
  AText := #10 + LKeyword + ' ' + Q(AConstraint.Name) + ' {'#10;
  AText := AText + #9'body1 ' + Q(AConstraint.Body1) + #10;
  AText := AText + #9'body2 ' + Q(AConstraint.Body2) + #10;
  case AConstraint.ConstraintType of
    actBallAndSocketJoint:
      begin
        AText := AText + #9'anchor ' + WriteVector(AConstraint.Anchor) + #10;
        AText := AText + #9'friction ' + Plain(AConstraint.Friction) + #10;
        if AConstraint.Limit = AF_LIMIT_CONE then
          AText := AText + #9'coneLimit ' + WriteVector(AConstraint.LimitAxis) + ', ' +
            Plain(AConstraint.LimitAngles[0]) + ', ' + WriteVector(AConstraint.Shaft[0]) + #10
        else if AConstraint.Limit = AF_LIMIT_PYRAMID then
          AText := AText + #9'pyramidLimit ' + WriteVector(AConstraint.LimitAxis) + ', ' + Pyramid + ', ' +
            WriteVector(AConstraint.Shaft[0]) + #10;
      end;
    actUniversalJoint:
      begin
        AText := AText + #9'anchor ' + WriteVector(AConstraint.Anchor) + #10;
        AText := AText + #9'shafts ' + WriteVector(AConstraint.Shaft[0]) + ', ' + WriteVector(AConstraint.Shaft[1]) + #10;
        AText := AText + #9'friction ' + Plain(AConstraint.Friction) + #10;
        if AConstraint.Limit = AF_LIMIT_CONE then
          AText := AText + #9'coneLimit ' + WriteVector(AConstraint.LimitAxis) + ', ' +
            Plain(AConstraint.LimitAngles[0]) + #10
        else if AConstraint.Limit = AF_LIMIT_PYRAMID then
          AText := AText + #9'pyramidLimit ' + WriteVector(AConstraint.LimitAxis) + ', ' + Pyramid + #10;
      end;
    actHinge:
      begin
        AText := AText + #9'anchor ' + WriteVector(AConstraint.Anchor) + #10;
        AText := AText + #9'axis ' + WriteVector(AConstraint.Axis) + #10;
        AText := AText + #9'friction ' + Plain(AConstraint.Friction) + #10;
        if AConstraint.Limit = AF_LIMIT_CONE then
          AText := AText + #9'limit ' + Pyramid + #10;
      end;
    actSlider:
      begin
        AText := AText + #9'axis ' + WriteVector(AConstraint.Axis) + #10;
        AText := AText + #9'friction ' + Plain(AConstraint.Friction) + #10;
      end;
    actSpring:
      begin
        AText := AText + #9'anchor1 ' + WriteVector(AConstraint.Anchor) + #10;
        AText := AText + #9'anchor2 ' + WriteVector(AConstraint.Anchor2) + #10;
        AText := AText + #9'friction ' + Plain(AConstraint.Friction) + #10;
        AText := AText + #9'stretch ' + Plain(AConstraint.Stretch) + #10;
        AText := AText + #9'compress ' + Plain(AConstraint.Compress) + #10;
        AText := AText + #9'damping ' + Plain(AConstraint.Damping) + #10;
        AText := AText + #9'restLength ' + Plain(AConstraint.RestLength) + #10;
        AText := AText + #9'minLength ' + Plain(AConstraint.MinLength) + #10;
        AText := AText + #9'maxLength ' + Plain(AConstraint.MaxLength) + #10;
      end;
  end;
  AText := AText + '}'#10;
end;

class function TAfWriter.WriteSettings(const ASettings: TAfSettings): AnsiString;
begin
  Result := #10'settings {'#10;
  Result := Result + #9'model ' + Q(ASettings.Model) + #10;
  Result := Result + #9'skin ' + Q(ASettings.Skin) + #10;
  Result := Result + #9'friction ' + Plain(ASettings.DefaultLinearFriction) + ', ' +
    Plain(ASettings.DefaultAngularFriction) + ', ' + Plain(ASettings.DefaultContactFriction) + ', ' +
    Plain(ASettings.DefaultConstraintFriction) + #10;
  Result := Result + #9'suspendSpeed ' + Plain(ASettings.SuspendVelocity.X) + ', ' + Plain(ASettings.SuspendVelocity.Y) +
    ', ' + Plain(ASettings.SuspendAcceleration.X) + ', ' + Plain(ASettings.SuspendAcceleration.Y) + #10;
  Result := Result + #9'noMoveTime ' + Plain(ASettings.NoMoveTime) + #10;
  Result := Result + #9'noMoveTranslation ' + Plain(ASettings.NoMoveTranslation) + #10;
  Result := Result + #9'noMoveRotation ' + Plain(ASettings.NoMoveRotation) + #10;
  Result := Result + #9'minMoveTime ' + Plain(ASettings.MinMoveTime) + #10;
  Result := Result + #9'maxMoveTime ' + Plain(ASettings.MaxMoveTime) + #10;
  Result := Result + #9'totalMass ' + Plain(ASettings.TotalMass) + #10;
  Result := Result + #9'contents ' + TAfContents.ContentsToString(ASettings.Contents) + #10;
  Result := Result + #9'clipMask ' + TAfContents.ContentsToString(ASettings.ClipMask) + #10;
  Result := Result + #9'selfCollision ' + AnsiString(IntToStr(Ord(ASettings.SelfCollision))) + #10;
  Result := Result + '}'#10;
end;

class function TAfWriter.RebuildText(const AName: AnsiString; const ASettings: TAfSettings;
  const ABodies: TArray<TAfBody>; const AConstraints: TArray<TAfConstraint>; out AText: AnsiString): Boolean;
var
  LIndex: Integer;
  LPart: AnsiString;
begin
  AText := #10#10'/*'#10 +
    #9'Generated by the Articulated Figure Editor.'#10 +
    #9'Do not edit directly but launch the game and type ''editAFs'' on the console.'#10 +
    '*/'#10;
  AText := AText + #10'articulatedFigure ' + AName + ' {'#10;
  AText := AText + WriteSettings(ASettings);
  for LIndex := 0 to High(ABodies) do
    AText := AText + WriteBody(ABodies[LIndex]);
  for LIndex := 0 to High(AConstraints) do
  begin
    if not WriteConstraint(AConstraints[LIndex], LPart) then
    begin
      AText := '';
      Exit(False);
    end;
    AText := AText + LPart;
  end;
  AText := AText + #10'}';
  Result := True;
end;

initialization
  GInvariant := TFormatSettings.Invariant;

end.
