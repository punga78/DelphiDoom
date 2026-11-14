{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - little worlds with ladders           }
{                                                                              }
{  The maps of OpenArena have no ladder: these worlds are made from the row of }
{  boxes of TAasSample (a box of 64 units per area) for the reachabilities     }
{  that the maps do not reach (be_aas_reach.c, AAS_Reachability_Ladder). The    }
{  files are written by the test WriteWorlds when DELPHIDOOM_WRITE_WORLDS      }
{  names a folder, and the C tool of Tools\Verifica\122\reach calculates them  }
{  to make the goldens (Make-Golden.ps1 -Worlds).                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Reach.Worlds;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Variants: 1 two boxes one on the other with a ladder face in each (the wall at y = 0) and a horizontal shared edge;
  ///   2 as 1 and the wall of the upper box is a ground face too; 3 a row of boxes with a ladder face in the second and
  ///   the third (the shared edge is vertical)
  /// </summary>
  TAasReachWorlds = class sealed
  public
    class function Count: Integer; static;
    /// <summary>The file (version 4, nothing is scrambled)</summary>
    class function Bytes(const AVariant: Integer): TBytes; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Tests.Aas.Sample;

{ TAasReachWorlds }

class function TAasReachWorlds.Count: Integer;
begin
  Result := 3;
end;

class function TAasReachWorlds.Bytes(const AVariant: Integer): TBytes;
var
  LData: TAasFileData;
  LIndex, LAreaCount: Integer;
  LSwap: Boolean;
  LTemp: Single;
  LType: Integer;

  procedure SwapXZ(var AVector: TVec3);
  begin
    LTemp := AVector[0];
    AVector[0] := AVector[2];
    AVector[2] := LTemp;
  end;

  // the wall of the area at y = 0: faces 1 .. areas + 1 are the faces between the boxes, then four per area
  function WallFace(const AArea: Integer): Integer;
  begin
    Result := LAreaCount + 1 + (AArea - 1) * 4 + 1;
  end;

begin
  LData := TAasSample.Content(0);
  LAreaCount := TAasSample.AreaCount(0);
  LSwap := AVariant in [1, 2];
  if LSwap then
  begin
    for LIndex := 0 to High(LData.Vertexes) do
      SwapXZ(LData.Vertexes[LIndex]);
    for LIndex := 0 to High(LData.Planes) do
    begin
      SwapXZ(LData.Planes[LIndex].Normal);
      LType := LData.Planes[LIndex].PlaneType;
      if LType = 0 then
        LData.Planes[LIndex].PlaneType := 2
      else if LType = 2 then
        LData.Planes[LIndex].PlaneType := 0;
    end;
    for LIndex := 0 to High(LData.Areas) do
    begin
      SwapXZ(LData.Areas[LIndex].Mins);
      SwapXZ(LData.Areas[LIndex].Maxs);
      SwapXZ(LData.Areas[LIndex].Center);
    end;
  end;
  case AVariant of
    1, 2:
      begin
        for LIndex := 1 to 2 do
          LData.AreaSettings[LIndex].AreaFlags := AREA_LADDER;
        LData.Faces[WallFace(1)].FaceFlags := FACE_SOLID or FACE_LADDER;
        LData.Faces[WallFace(2)].FaceFlags := FACE_SOLID or FACE_LADDER;
        if AVariant = 2 then
        begin
          // the wall of the upper box is a ground face too and its plane is seen from the other side: the two planes are
          // not the same, so the reachability is the ladder end and the walk off the ledge
          LData.Faces[WallFace(2)].FaceFlags := FACE_SOLID or FACE_LADDER or FACE_GROUND;
          LData.FaceIndex[LData.Areas[2].FirstFace + 2] := -WallFace(2);
        end;
      end;
    3:
      begin
        for LIndex := 2 to 3 do
          LData.AreaSettings[LIndex].AreaFlags := AREA_LADDER;
        LData.Faces[WallFace(2)].FaceFlags := FACE_SOLID or FACE_LADDER;
        LData.Faces[WallFace(3)].FaceFlags := FACE_SOLID or FACE_LADDER;
      end;
  end;
  // the reachabilities of the sample are not wanted: the calculation makes them
  Result := TAasSample.Layout(LData, AAS_VERSION_OLD, 0);
end;

end.
