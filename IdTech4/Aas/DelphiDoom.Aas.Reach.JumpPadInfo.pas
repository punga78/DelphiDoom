{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the push of a trigger_push (jump pad)             }
{                                                                              }
{  Port of AAS_GetJumpPadInfo of be_aas_reach.c. Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.JumpPadInfo;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Reach.Part;

type
  /// <summary>Where a jump pad starts, the box of its brush and the velocity it gives</summary>
  TAasReachJumpPadInfo = class(TAasReachPart)
  public
    /// <summary>
    ///   AAS_GetJumpPadInfo: the entity must be a trigger_push; False (with a message) if its target does not exist or the
    ///   time of the flight is zero. A target above the pad gives a time that is NaN, which the original does not catch
    /// </summary>
    function GetInfo(const AEntity: Integer; out AAreaStart, AAbsMins, AAbsMaxs, AVelocity: TVec3): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Bsp.CNumbers,
  DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Vectors;

const
  CHalf: Double = 0.5;
  COnePointOneFloat: Single = 1.10000002384185791015625;
  CEighth: Single = 0.125;

{ TAasReachJumpPadInfo }

function TAasReachJumpPadInfo.GetInfo(const AEntity: Integer; out AAreaStart, AAbsMins, AAbsMaxs,
  AVelocity: TVec3): Boolean;
var
  LSpeed, LHeight, LGravity, LTime, LDistance, LForward: Single;
  LModel, LTarget, LTargetName: AnsiString;
  LModelNum, LEnt2: Integer;
  LOrigin, LAngles, LTestStart, LEnt2Origin, LModelOrigin: TVec3;
  LTrace: TAasTrace;
  LQuotient, LRoot: Double;
begin
  Context.Entities.FloatForKey(AEntity, 'speed', LSpeed);
  if LSpeed = 0 then
    LSpeed := 1000;
  LAngles[0] := 0;
  LAngles[1] := 0;
  LAngles[2] := 0;
  // the mins, maxs and origin of the model
  Context.Entities.ValueForKey(AEntity, 'model', LModel);
  if LModel <> '' then
    LModelNum := TAasCNumbers.AtoI(Copy(LModel, 2, MaxInt))
  else
    LModelNum := 0;
  Context.Models.ModelMinsMaxsOrigin(LModelNum, LAngles, AAbsMins, AAbsMaxs, LModelOrigin);
  TAasReachVectors.Add(LModelOrigin, AAbsMins, AAbsMins);
  TAasReachVectors.Add(LModelOrigin, AAbsMaxs, AAbsMaxs);
  TAasReachVectors.Add(AAbsMins, AAbsMaxs, LOrigin);
  TAasReachVectors.Scale(LOrigin, 0.5, LOrigin);
  // the start area
  LTestStart := LOrigin;
  LTestStart[2] := LTestStart[2] + 64;
  LTrace := Context.Tracer.TraceClientBBox(LTestStart, LOrigin, PRESENCE_CROUCH, -1);
  if LTrace.StartSolid then
  begin
    TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'trigger_push start solid'#10);
    AAreaStart := LOrigin;
  end
  else
    AAreaStart := LTrace.EndPos;
  // 0.125 is exact: the float sum is the double sum
  AAreaStart[2] := AAreaStart[2] + CEighth;
  // the target entity
  Context.Entities.ValueForKey(AEntity, 'target', LTarget);
  LEnt2 := Context.Entities.NextEntity(0);
  while LEnt2 <> 0 do
  begin
    if Context.Entities.ValueForKey(LEnt2, 'targetname', LTargetName) and (LTargetName = LTarget) then
      Break;
    LEnt2 := Context.Entities.NextEntity(LEnt2);
  end;
  if LEnt2 = 0 then
  begin
    TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'trigger_push without target entity ' + string(LTarget) + #10);
    Exit(False);
  end;
  Context.Entities.VectorForKey(LEnt2, 'origin', LEnt2Origin);
  LHeight := LEnt2Origin[2] - LOrigin[2];
  LGravity := Context.Settings.PhysGravity;
  // time = sqrt(height / (0.5 * gravity)): the quotient is a double, the root too
  LQuotient := CHalf * LGravity;
  LQuotient := LHeight / LQuotient;
  LRoot := Sqrt(LQuotient);
  LTime := LRoot;
  if LTime = 0 then
  begin
    TAasPrinter.Print(Context.Import, PRT_MESSAGE, 'trigger_push without time'#10);
    Exit(False);
  end;
  // the push velocity
  TAasVectorMath.Subtract(LEnt2Origin, LOrigin, AVelocity);
  LDistance := TAasVectorMath.Normalize(AVelocity);
  LForward := LDistance / LTime;
  // FIXME of the original: why multiply by 1.1
  LForward := LForward * COnePointOneFloat;
  TAasReachVectors.Scale(AVelocity, LForward, AVelocity);
  AVelocity[2] := LTime * LGravity;
  Result := True;
end;

end.
