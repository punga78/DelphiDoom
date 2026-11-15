{******************************************************************************}
{                                                                              }
{  DelphiDoom: test support of the bot AI library - the world of the goals     }
{  and of the movement                                                         }
{                                                                              }
{  A row of six boxes of 64 units (the recipe of Tests\Source\                 }
{  DelphiDoom.Tests.Aas.Sample.pas, variant 1) in one cluster, with the        }
{  reachabilities of every travel type. The file that is made from it          }
{  (Tests\Data\BotAi\botworld.aas) is read by the C tool and by the Delphi     }
{  classes: it is built once, here. No file of a game is used.                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.World;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  TBotTestWorld = class
  public
    /// <summary>The checksum of the BSP the world is made for (the library variable <c>sv_mapChecksum</c>)</summary>
    const
      Checksum = $12345678;
    /// <summary>The bytes of the .aas file</summary>
    class function Bytes: TBytes; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Tests.Aas.Sample;

type
  TLink = record
    Area: Integer;
    Target: Integer;
    TravelType: Integer;
    Time: Word;
    StartPoint: TVec3;
    EndPoint: TVec3;
    FaceNum: Integer;
    EdgeNum: Integer;
  end;

function Vec(const X, Y, Z: Single): TVec3;
begin
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
end;

function Link(const AArea, ATarget, ATravelType: Integer; const ATime: Word; const AStart, AEnd: TVec3;
  const AFaceNum: Integer = 0; const AEdgeNum: Integer = 0): TLink;
begin
  Result.Area := AArea;
  Result.Target := ATarget;
  Result.TravelType := ATravelType;
  Result.Time := ATime;
  Result.StartPoint := AStart;
  Result.EndPoint := AEnd;
  Result.FaceNum := AFaceNum;
  Result.EdgeNum := AEdgeNum;
end;

{ TBotTestWorld }

class function TBotTestWorld.Bytes: TBytes;
var
  LContent: TAasFileData;
  LLinks: TArray<TLink>;
  LReach: TList<TAasReachability>;
  LRecord: TAasReachability;
  LArea: Integer;
  LIndex: Integer;
  LSetting: TAasAreaSettings;
begin
  LContent := TAasSample.Content(1);
  // one cluster: the areas 1 to 6, no portal (the area 4 is an ordinary area)
  LLinks := [
    Link(1, 2, TRAVEL_WALK, 50, Vec(40, 32, 4), Vec(72, 32, 4)),
    Link(1, 3, TRAVEL_JUMPPAD, 45, Vec(32, 32, 4), Vec(150, 32, 60)),
    Link(1, 5, TRAVEL_ROCKETJUMP, 75, Vec(30, 32, 4), Vec(280, 32, 4)),
    Link(2, 1, TRAVEL_WATERJUMP, 60, Vec(90, 32, 4), Vec(60, 32, 16)),
    Link(2, 3, TRAVEL_SWIM, 70, Vec(100, 32, 4), Vec(140, 32, 4)),
    Link(2, 6, TRAVEL_GRAPPLEHOOK, 65, Vec(110, 32, 4), Vec(125, 32, 4)),
    Link(3, 2, TRAVEL_BARRIERJUMP, 80, Vec(150, 32, 4), Vec(120, 32, 16)),
    Link(3, 4, TRAVEL_JUMP, 90, Vec(170, 32, 4), Vec(205, 32, 4)),
    Link(3, 6, TRAVEL_BFGJUMP, 85, Vec(160, 32, 4), Vec(340, 32, 4)),
    Link(4, 3, TRAVEL_CROUCH, 40, Vec(200, 32, 4), Vec(170, 32, 4)),
    Link(4, 5, TRAVEL_LADDER, 100, Vec(240, 32, 4), Vec(270, 32, 30)),
    Link(4, 1, TRAVEL_WALK, 35, Vec(200, 32, 4), Vec(40, 32, 4)),
    Link(5, 4, TRAVEL_WALKOFFLEDGE, 55, Vec(270, 32, 4), Vec(240, 32, 0)),
    Link(5, 6, TRAVEL_ELEVATOR, 110, Vec(300, 32, 4), Vec(330, 32, 50), 1, 0),
    Link(6, 5, TRAVEL_FUNCBOB, 120, Vec(330, 32, 4), Vec(300, 32, 4), (1 shl 16) or 2, (340 shl 16) or 370),
    Link(6, 1, TRAVEL_TELEPORT, 30, Vec(350, 32, 4), Vec(32, 32, 4))];
  LReach := TList<TAasReachability>.Create;
  try
    LReach.Add(Default(TAasReachability));
    for LArea := 1 to 6 do
    begin
      LSetting := LContent.AreaSettings[LArea];
      LSetting.FirstReachableArea := LReach.Count;
      LSetting.NumReachableAreas := 0;
      // the cluster, the same for every area
      LSetting.Cluster := 1;
      LSetting.ClusterAreaNum := LArea;
      if LArea = 4 then
        LSetting.Contents := 0;
      // the area of the lava is no teleporter, the area that bots should not enter can be walked in
      if LArea = 6 then
      begin
        LSetting.Contents := AREACONTENTS_LAVA;
        LSetting.AreaFlags := AREA_GROUNDED;
      end;
      if LArea = 5 then
        LSetting.PresenceType := PRESENCE_NORMAL or PRESENCE_CROUCH;
      for LIndex := 0 to High(LLinks) do
      begin
        if LLinks[LIndex].Area <> LArea then
          Continue;
        LRecord := Default(TAasReachability);
        LRecord.AreaNum := LLinks[LIndex].Target;
        LRecord.FaceNum := LLinks[LIndex].FaceNum;
        LRecord.EdgeNum := LLinks[LIndex].EdgeNum;
        LRecord.StartPoint := LLinks[LIndex].StartPoint;
        LRecord.EndPoint := LLinks[LIndex].EndPoint;
        LRecord.TravelType := LLinks[LIndex].TravelType;
        LRecord.TravelTime := LLinks[LIndex].Time;
        LReach.Add(LRecord);
        Inc(LSetting.NumReachableAreas);
      end;
      LContent.AreaSettings[LArea] := LSetting;
    end;
    LContent.Reachability := LReach.ToArray;
  finally
    LReach.Free;
  end;
  SetLength(LContent.Portals, 1);
  LContent.Portals[0] := Default(TAasPortal);
  SetLength(LContent.PortalIndex, 1);
  LContent.PortalIndex[0] := 0;
  SetLength(LContent.Clusters, 2);
  LContent.Clusters[0] := Default(TAasCluster);
  LContent.Clusters[1] := Default(TAasCluster);
  LContent.Clusters[1].NumAreas := 7;
  LContent.Clusters[1].NumReachabilityAreas := 7;
  LContent.Clusters[1].NumPortals := 0;
  LContent.Clusters[1].FirstPortal := 0;
  Result := TAasSample.Layout(LContent, AAS_VERSION, 0);
end;

end.
