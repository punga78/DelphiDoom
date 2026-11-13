{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing the settings of an .aas file         }
{                                                                              }
{  Port of idAASSettings::WriteToFile (AASFile.cpp), Doom 3 GPL Source Code.   }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.SettingsWriter;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Aas.Settings;

type
  /// <summary>
  ///   Writes the block that follows "settings": the boxes, the flags, the physics and the fixed
  ///   travel times, in the order of the original (<c>noOptimize</c> is not written)
  /// </summary>
  TAasSettingsWriter = class
  strict private
    class procedure AddVector(const AOutput: TMapTextWriter; const AValue: TGeoVec3); static;
    class procedure AddFlag(const AOutput: TMapTextWriter; const AName: AnsiString; const AValue: Boolean); static;
    class procedure AddFloatLine(const AOutput: TMapTextWriter; const AName: AnsiString; const AValue: Single); static;
    class procedure AddIntegerLine(const AOutput: TMapTextWriter; const AName: AnsiString;
      const AValue: Integer); static;
  public
    class procedure Write(const AOutput: TMapTextWriter; const ASettings: TAasSettings); static;
  end;

implementation

{ TAasSettingsWriter }

class procedure TAasSettingsWriter.AddVector(const AOutput: TMapTextWriter; const AValue: TGeoVec3);
begin
  AOutput.Add('(');
  AOutput.AddFloat(AValue.X);
  AOutput.Add(' ');
  AOutput.AddFloat(AValue.Y);
  AOutput.Add(' ');
  AOutput.AddFloat(AValue.Z);
  AOutput.Add(')');
end;

class procedure TAasSettingsWriter.AddFlag(const AOutput: TMapTextWriter; const AName: AnsiString;
  const AValue: Boolean);
begin
  AddIntegerLine(AOutput, AName, Ord(AValue));
end;

class procedure TAasSettingsWriter.AddFloatLine(const AOutput: TMapTextWriter; const AName: AnsiString;
  const AValue: Single);
begin
  AOutput.Add(#9 + AName + ' = ');
  AOutput.AddFloat(AValue);
  AOutput.Add(#10);
end;

class procedure TAasSettingsWriter.AddIntegerLine(const AOutput: TMapTextWriter; const AName: AnsiString;
  const AValue: Integer);
begin
  AOutput.Add(#9 + AName + ' = ');
  AOutput.AddInteger(AValue);
  AOutput.Add(#10);
end;

class procedure TAasSettingsWriter.Write(const AOutput: TMapTextWriter; const ASettings: TAasSettings);
var
  LIndex: Integer;
begin
  AOutput.Add('{'#10);
  AOutput.Add(#9'bboxes'#10#9'{'#10);
  for LIndex := 0 to ASettings.NumBoundingBoxes - 1 do
  begin
    AOutput.Add(#9#9);
    AddVector(AOutput, ASettings.BoundingBoxes[LIndex].Mins);
    AOutput.Add('-');
    AddVector(AOutput, ASettings.BoundingBoxes[LIndex].Maxs);
    AOutput.Add(#10);
  end;
  AOutput.Add(#9'}'#10);
  AddFlag(AOutput, 'usePatches', ASettings.UsePatches);
  AddFlag(AOutput, 'writeBrushMap', ASettings.WriteBrushMap);
  AddFlag(AOutput, 'playerFlood', ASettings.PlayerFlood);
  AddFlag(AOutput, 'allowSwimReachabilities', ASettings.AllowSwimReachabilities);
  AddFlag(AOutput, 'allowFlyReachabilities', ASettings.AllowFlyReachabilities);
  AOutput.Add(#9'fileExtension = "' + ASettings.FileExtension + '"'#10);
  AOutput.Add(#9'gravity = ');
  AddVector(AOutput, ASettings.Gravity);
  AOutput.Add(#10);
  AddFloatLine(AOutput, 'maxStepHeight', ASettings.MaxStepHeight);
  AddFloatLine(AOutput, 'maxBarrierHeight', ASettings.MaxBarrierHeight);
  AddFloatLine(AOutput, 'maxWaterJumpHeight', ASettings.MaxWaterJumpHeight);
  AddFloatLine(AOutput, 'maxFallHeight', ASettings.MaxFallHeight);
  AddFloatLine(AOutput, 'minFloorCos', ASettings.MinFloorCos);
  AddIntegerLine(AOutput, 'tt_barrierJump', ASettings.BarrierJumpTime);
  AddIntegerLine(AOutput, 'tt_startCrouching', ASettings.StartCrouchingTime);
  AddIntegerLine(AOutput, 'tt_waterJump', ASettings.WaterJumpTime);
  AddIntegerLine(AOutput, 'tt_startWalkOffLedge', ASettings.StartWalkOffLedgeTime);
  AOutput.Add('}'#10);
end;

end.
