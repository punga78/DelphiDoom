{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - how a result is counted            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Scenarios;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Tests.Voxel.Fingerprint;

type
  /// <summary>
  ///   The way a result goes in a fingerprint. The temporary harness that made the golden files
  ///   from the old code and the tests of the library both count with these functions, so the
  ///   two sides cannot differ in the way they count.
  /// </summary>
  TVoxelScenarios = class
  public
    /// <summary>The side and every cell in the order of x, y, z</summary>
    class procedure AddCube(const AFingerprint: TFingerprint; const ASide: Integer;
      const ACells: TArray<Cardinal>); static;
    /// <summary>The three sizes, the three pivots and every cell in the order of x, y, z</summary>
    class procedure AddGrid(const AFingerprint: TFingerprint; const ASizeX, ASizeY, ASizeZ: Integer;
      const APivotX, APivotY, APivotZ: Integer; const ACells: TArray<Cardinal>); static;
    class procedure AddQuads(const AFingerprint: TFingerprint; const AQuads: TArray<TVoxelQuad>); static;
    class procedure AddBytes(const AFingerprint: TFingerprint; const ABytes: TBytes); static;
    class procedure AddLines(const AFingerprint: TFingerprint; const ALines: TStrings); static;
  end;

implementation

{ TVoxelScenarios }

class procedure TVoxelScenarios.AddCube(const AFingerprint: TFingerprint; const ASide: Integer;
  const ACells: TArray<Cardinal>);
var
  LIndex: Integer;
begin
  AFingerprint.AddInteger(ASide);
  for LIndex := 0 to ASide * ASide * ASide - 1 do
    AFingerprint.AddCardinal(ACells[LIndex]);
end;

class procedure TVoxelScenarios.AddGrid(const AFingerprint: TFingerprint; const ASizeX, ASizeY,
  ASizeZ: Integer; const APivotX, APivotY, APivotZ: Integer; const ACells: TArray<Cardinal>);
var
  LIndex: Integer;
begin
  AFingerprint.AddInteger(ASizeX);
  AFingerprint.AddInteger(ASizeY);
  AFingerprint.AddInteger(ASizeZ);
  AFingerprint.AddInteger(APivotX);
  AFingerprint.AddInteger(APivotY);
  AFingerprint.AddInteger(APivotZ);
  for LIndex := 0 to ASizeX * ASizeY * ASizeZ - 1 do
    AFingerprint.AddCardinal(ACells[LIndex]);
end;

class procedure TVoxelScenarios.AddQuads(const AFingerprint: TFingerprint;
  const AQuads: TArray<TVoxelQuad>);
var
  LIndex, LCorner: Integer;
begin
  AFingerprint.AddInteger(Length(AQuads));
  for LIndex := 0 to High(AQuads) do
  begin
    AFingerprint.AddCardinal(AQuads[LIndex].Color);
    for LCorner := 0 to 3 do
    begin
      AFingerprint.AddInteger(AQuads[LIndex].Vertexes[LCorner].X);
      AFingerprint.AddInteger(AQuads[LIndex].Vertexes[LCorner].Y);
      AFingerprint.AddInteger(AQuads[LIndex].Vertexes[LCorner].Z);
    end;
  end;
end;

class procedure TVoxelScenarios.AddBytes(const AFingerprint: TFingerprint; const ABytes: TBytes);
var
  LIndex: Integer;
begin
  AFingerprint.AddInteger(Length(ABytes));
  for LIndex := 0 to High(ABytes) do
    AFingerprint.AddInteger(ABytes[LIndex]);
end;

class procedure TVoxelScenarios.AddLines(const AFingerprint: TFingerprint; const ALines: TStrings);
var
  LIndex: Integer;
begin
  AFingerprint.AddInteger(ALines.Count);
  for LIndex := 0 to ALines.Count - 1 do
    AFingerprint.AddText(ALines[LIndex]);
end;

end.
