{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - a motion: a translation followed by a       }
{  rotation of a trace model against one model                                 }
{                                                                              }
{  Port of the part of idClip::Motion (game\physics\Clip.cpp) that works on    }
{  the world model: the choice between pure rotation, pure translation and     }
{  both, the rotation about the position that the translation reached, and     }
{  the combination of the two traces. The list of the clip models of the       }
{  entities that the original also tests is the caller's: call it for each     }
{  model and keep the nearest. Doom 3 GPL Source Code. Copyright (C)           }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software). This unit is derived from the Doom 3 GPL     }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3 or (at your option) any later version, with the          }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Motion;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.MathCore.Float.Rotation, DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf;

type
  /// <summary>Moves a trace model by a translation and a rotation (idClip::Motion on one collision model)</summary>
  TCollisionMotion = class sealed
  public
    /// <summary>
    ///   The trace model (nil: a point) goes from AStart to AEnd and then turns by ARotation (whose
    ///   origin is AStart in the original; here the rotation is moved to the position that the
    ///   translation reached). Returns True if it hit something. A translation over more than
    ///   CM_MAX_TRACE_DIST is reported as a hit at fraction 0 (TestHugeTranslation). The fraction of the
    ///   result is the larger of the two fractions, as in the original
    /// </summary>
    class function Motion(const AManager: ICollisionModelManager; var AResults: TCollisionTrace;
      const AStart, AEnd: TGeoVec3; const ARotation: TIdRotation; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
      AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3;
      const AModelAxis: TGeoMat3): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.GeometryAdapter;

class function TCollisionMotion.Motion(const AManager: ICollisionModelManager; var AResults: TCollisionTrace;
  const AStart, AEnd: TGeoVec3; const ARotation: TIdRotation; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
  AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Boolean;
var
  LTranslation: TCollisionTrace;
  LRotational: TCollisionTrace;
  LEndRotation: TIdRotation;
  LMoved: Boolean;
  LHasRotation: Boolean;
  LVector: TGeoVec3;
  LDelta: TGeoVec3;
begin
  // TestHugeTranslation: the fraction is too inaccurate to describe translations over huge distances
  LDelta := AEnd - AStart;
  if LDelta.LengthSqr > CM_MAX_TRACE_DIST * CM_MAX_TRACE_DIST then
  begin
    AResults := Default(TCollisionTrace);
    AResults.Fraction := 0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;
    AResults.C.Normal := TGeoVec3.Origin;
    AResults.C.Material := nil;
    AResults.C.Point := AStart;
    Exit(True);
  end;

  LVector := TIdGeometryAdapter.ToGeo(ARotation.Vector);
  LHasRotation := (ARotation.Angle <> 0) and not LVector.Compare(TGeoVec3.Origin);
  LMoved := not AStart.Compare(AEnd);
  if LHasRotation then
  begin
    // if no translation: pure rotation
    if not LMoved then
    begin
      AManager.Rotation(AResults, AStart, ARotation, ATrm, ATrmAxis, AContentMask, AModel, AModelOrigin, AModelAxis);
      Exit(AResults.Fraction < 1);
    end;
  end
  else if LMoved then
  begin
    // pure translation
    AManager.Translation(AResults, AStart, AEnd, ATrm, ATrmAxis, AContentMask, AModel, AModelOrigin, AModelAxis);
    Exit(AResults.Fraction < 1);
  end
  else
  begin
    // no motion
    AResults := Default(TCollisionTrace);
    AResults.Fraction := 1;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;
    Exit(False);
  end;

  // translational collision
  AManager.Translation(LTranslation, AStart, AEnd, ATrm, ATrmAxis, AContentMask, AModel, AModelOrigin, AModelAxis);

  // rotational collision about the position the translation reached
  LEndRotation := ARotation;
  LEndRotation.SetOrigin(TIdGeometryAdapter.ToId(LTranslation.EndPos));
  AManager.Rotation(LRotational, LTranslation.EndPos, LEndRotation, ATrm, ATrmAxis, AContentMask, AModel,
    AModelOrigin, AModelAxis);

  if LRotational.Fraction < 1 then
    AResults := LRotational
  else
  begin
    AResults := LTranslation;
    AResults.EndAxis := LRotational.EndAxis;
  end;

  if LTranslation.Fraction > LRotational.Fraction then
    AResults.Fraction := LTranslation.Fraction
  else
    AResults.Fraction := LRotational.Fraction;

  Result := (LTranslation.Fraction < 1) or (LRotational.Fraction < 1);
end;

end.
