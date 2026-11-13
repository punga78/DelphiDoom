{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - finishing the "articulatedFigure"         }
{  declaration                                                                 }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.cpp (idAFVector::Finish, idDeclAF::Finish). Copyright (C)  }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL }
{  Source Code (id Software).                                                  }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Finisher;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.ArticulatedFigure.Types, DelphiDoom.Decl.ArticulatedFigure.Intf;

type
  /// <summary>
  ///   Gives the vectors that name joints their values once the model is known. Like the original it flips the sign
  ///   of a negated vector <b>every</b> time it runs, coordinates included: a second <c>Finish</c> undoes the first.
  /// </summary>
  TAfFinisher = class sealed
  strict private
    class procedure FinishVector(var AVector: TAfVector; const AName: AnsiString; const AResolver: IAfJointResolver;
      const ALog: IIdLibLog); static;
  public
    /// <summary>
    ///   idDeclAF::Finish: the vectors of every body (<c>V1</c>, <c>V2</c>, origin and the two directions) and of every
    ///   constraint (anchors, shafts, axis, limit axis). <c>AName</c> is the name of the figure for the warnings.
    /// </summary>
    class procedure Finish(const AName: AnsiString; var ABodies: TArray<TAfBody>;
      var AConstraints: TArray<TAfConstraint>; const AResolver: IAfJointResolver; const ALog: IIdLibLog); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3;

{ TAfFinisher }

class procedure TAfFinisher.FinishVector(var AVector: TAfVector; const AName: AnsiString;
  const AResolver: IAfJointResolver; const ALog: IIdLibLog);
var
  LAxis: TIdMat3;
  LStart, LEnd: TIdVec3;

  procedure Warn(const AJoint, AFunction: AnsiString);
  begin
    if Assigned(ALog) then
      ALog.Warning(Format('invalid joint %s in %s() in ''%s''', [string(AJoint), string(AFunction), string(AName)]));
  end;

  procedure GetJoint(const AJoint, AFunction: AnsiString; out APoint: TIdVec3);
  begin
    if not AResolver.GetJointTransform(AJoint, APoint, LAxis) then
    begin
      Warn(AJoint, AFunction);
      APoint.Zero;
    end;
  end;

begin
  case AVector.Kind of
    avkCoords:
      ;
    avkJoint:
      GetJoint(AVector.Joint1, 'joint', AVector.Vec);
    avkBoneCenter:
      begin
        GetJoint(AVector.Joint1, 'bonecenter', LStart);
        GetJoint(AVector.Joint2, 'bonecenter', LEnd);
        AVector.Vec := (LStart + LEnd) * 0.5;
      end;
    avkBoneDir:
      begin
        GetJoint(AVector.Joint1, 'bonedir', LStart);
        GetJoint(AVector.Joint2, 'bonedir', LEnd);
        AVector.Vec := LEnd - LStart;
      end;
  else
    AVector.Vec.Zero;
  end;

  if AVector.Negate then
    AVector.Vec := -AVector.Vec;
end;

class procedure TAfFinisher.Finish(const AName: AnsiString; var ABodies: TArray<TAfBody>;
  var AConstraints: TArray<TAfConstraint>; const AResolver: IAfJointResolver; const ALog: IIdLibLog);
var
  LIndex: Integer;
begin
  if not Assigned(AResolver) then
    raise EDeclArticulatedFigureException.Create('finishing a figure needs the joints of its model');
  for LIndex := 0 to High(ABodies) do
  begin
    FinishVector(ABodies[LIndex].V1, AName, AResolver, ALog);
    FinishVector(ABodies[LIndex].V2, AName, AResolver, ALog);
    FinishVector(ABodies[LIndex].Origin, AName, AResolver, ALog);
    FinishVector(ABodies[LIndex].FrictionDirection, AName, AResolver, ALog);
    FinishVector(ABodies[LIndex].ContactMotorDirection, AName, AResolver, ALog);
  end;
  for LIndex := 0 to High(AConstraints) do
  begin
    FinishVector(AConstraints[LIndex].Anchor, AName, AResolver, ALog);
    FinishVector(AConstraints[LIndex].Anchor2, AName, AResolver, ALog);
    FinishVector(AConstraints[LIndex].Shaft[0], AName, AResolver, ALog);
    FinishVector(AConstraints[LIndex].Shaft[1], AName, AResolver, ALog);
    FinishVector(AConstraints[LIndex].Axis, AName, AResolver, ALog);
    FinishVector(AConstraints[LIndex].LimitAxis, AName, AResolver, ALog);
  end;
end;

end.
