{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the scenario of Tools\Verifica\122   }
{                                                                              }
{  Does with the classes of the library what aasgen.c does with the real       }
{  be_aas_file.c and be_aas_sample.c: same files, same points (xorshift32),    }
{  same lines. The comparison with aas.golden.txt is exact.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.ScenarioRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Types;

type
  /// <summary>Produces the lines of the golden file</summary>
  TAasScenarioRunner = class
  strict private
    FOutput: TStrings;
    FRandom: Cardinal;
    function NextRandom: Cardinal;
    function RandomInt(const ALimit: Integer): Integer;
    function RandomPoint(const AAreas: Integer): TVec3;
    function VecText(const ATag: string; const AValue: TVec3): string;
    procedure RunCase(const AVariant, AMutation: Integer);
    procedure Sample(const AFile: IAasFile; const AImport: IBotImport);
  public
    constructor Create(const AOutput: TStrings);
    procedure Run;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.Aas.Factory, DelphiDoom.Aas.BoxMath,
  DelphiDoom.Tests.Aas.Sample, DelphiDoom.Tests.Aas.Support;

const
  GROUND_EPSILON: Single = 0.01;

{ TAasScenarioRunner }

constructor TAasScenarioRunner.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

function TAasScenarioRunner.NextRandom: Cardinal;
begin
  FRandom := FRandom xor (FRandom shl 13);
  FRandom := FRandom xor (FRandom shr 17);
  FRandom := FRandom xor (FRandom shl 5);
  Result := FRandom;
end;

function TAasScenarioRunner.RandomInt(const ALimit: Integer): Integer;
begin
  Result := Integer(NextRandom mod Cardinal(ALimit));
end;

function TAasScenarioRunner.RandomPoint(const AAreas: Integer): TVec3;
var
  LX, LY, LZ: Integer;
begin
  LX := RandomInt((AAreas * 64 + 128) * 8) - 512;
  LY := RandomInt(1024) - 256;
  LZ := RandomInt(1024) - 256;
  Result[0] := LX / 8;
  Result[1] := LY / 8;
  Result[2] := LZ / 8;
end;

function TAasScenarioRunner.VecText(const ATag: string; const AValue: TVec3): string;
begin
  Result := ' ' + ATag + Hex(Bits(AValue[0])) + ' ' + Hex(Bits(AValue[1])) + ' ' + Hex(Bits(AValue[2]));
end;

procedure TAasScenarioRunner.Run;
begin
  FOutput.Add('sizes header 124 bbox 32 vertex 12 plane 20 edge 8 face 24 area 48 settings 28 reach 44 node 12 ' +
    'portal 20 cluster 16');
  RunCase(0, 0);
  RunCase(1, 0);
  RunCase(2, 0);
  RunCase(3, 0);
  RunCase(0, 1);
  RunCase(0, 2);
  RunCase(0, 3);
  RunCase(0, 4);
end;

procedure TAasScenarioRunner.RunCase(const AVariant, AMutation: Integer);
const
  FILE_NAME = 'maps/sample.aas';
var
  LBytes: TBytes;
  LImport: IBotImport;
  LReader: IAasReader;
  LFile: IAasFile;
  LCode, LIndex: Integer;
  LChecksum, LLine: string;
  LNameToLoad: AnsiString;
  LVersion: Integer;
begin
  LBytes := TAasSample.Bytes(AVariant);
  if AMutation = 1 then
    LBytes[0] := LBytes[0] xor 1;
  if AMutation = 2 then
  begin
    LVersion := 6;
    Move(LVersion, LBytes[4], 4);
  end;
  LChecksum := IntToStr(SAMPLE_CHECKSUM);
  if AMutation = 3 then
    LChecksum := IntToStr(SAMPLE_CHECKSUM + 1);
  FOutput.Add(Format('case %d %d size %d crc %s', [AVariant, AMutation, Length(LBytes),
    Hex(TCrc32.Calculate(LBytes[0], Length(LBytes)))]));
  LImport := TFakeImport.Create(FOutput);
  LReader := TAasFactory.CreateReader(LImport, TFakeFiles.Create(FILE_NAME, LBytes),
    TFakeLibVars.Create(AnsiString(LChecksum)));
  LNameToLoad := FILE_NAME;
  if AMutation = 4 then
    LNameToLoad := 'maps/other.aas';
  LCode := LReader.Load(LNameToLoad, LFile);
  FOutput.Add('result ' + IntToStr(LCode));
  if LCode <> 0 then
    Exit;
  FOutput.Add('hdr ' + IntToStr(LFile.BspChecksum));
  FOutput.Add(Format('counts %d %d %d %d %d %d %d %d %d %d %d %d %d %d', [Length(LFile.BBoxes),
    Length(LFile.Vertexes), Length(LFile.Planes), Length(LFile.Edges), Length(LFile.EdgeIndex), Length(LFile.Faces),
    Length(LFile.FaceIndex), Length(LFile.Areas), Length(LFile.AreaSettings), Length(LFile.Reachability),
    Length(LFile.Nodes), Length(LFile.Portals), Length(LFile.PortalIndex), Length(LFile.Clusters)]));
  LLine := 'crcs';
  for LIndex := 0 to AAS_LUMPS - 1 do
  begin
    // the C prints 0 for an empty lump
    if Length(LFile.LumpBytes(LIndex)) = 0 then
      LLine := LLine + ' 00000000'
    else
      LLine := LLine + ' ' + Hex(TCrc32.Calculate(LFile.LumpBytes(LIndex)[0], Length(LFile.LumpBytes(LIndex))));
  end;
  FOutput.Add(LLine);
  Sample(LFile, LImport);
end;

procedure TAasScenarioRunner.Sample(const AFile: IAasFile; const AImport: IBotImport);
const
  PRESENCES: array[0..1] of Integer = (PRESENCE_NORMAL, PRESENCE_CROUCH);
var
  LImport: IBotImport;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LFaceTester: IAasFaceTester;
  LBoxAreas: IAasBoxAreas;
  LQuery: IAasAreaQuery;
  LAreas, LIndex, LK, LArea, LPresence, LCluster, LCount, LFace, LPlane, LReach, LEndFace: Integer;
  LPoint, LOther, LMins, LMaxs, LNormal: TVec3;
  LInfo: TAasAreaInfo;
  LTrace: TAasTrace;
  LAreaList: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LLine: string;
  LDist: Single;
  LSolid: Integer;

  function Flag(const AValue: Boolean): Integer;
  begin
    if AValue then
      Result := 1
    else
      Result := 0;
  end;

begin
  LImport := AImport;
  LSampler := TAasFactory.CreateSampler(AFile, LImport, True);
  LTracer := TAasFactory.CreateTracer(AFile, LImport);
  LFaceTester := TAasFactory.CreateFaceTester(AFile, LImport);
  LBoxAreas := TAasFactory.CreateBoxAreas(AFile, LImport);
  LQuery := TAasFactory.CreateAreaQuery(AFile, LImport);
  LAreas := Length(AFile.Areas) - 1;
  FRandom := 2463534242;

  for LIndex := 0 to 119 do
  begin
    LPoint := RandomPoint(LAreas);
    LArea := LSampler.PointAreaNum(LPoint);
    LPresence := LSampler.PointPresenceType(LPoint);
    if LArea > 0 then
      LCluster := LQuery.AreaCluster(LArea)
    else
      LCluster := 0;
    LLine := 'pt ' + IntToStr(LIndex) + VecText('p', LPoint) +
      Format(' area %d presence %d cluster %d', [LArea, LPresence, LCluster]);
    if (LArea > 0) and (AFile.AreaSettings[LArea].Cluster < 0) then
      LLine := LLine + ' reach P'
    else
      LLine := LLine + ' reach ' + IntToStr(LSampler.PointReachabilityAreaIndex(LPoint));
    if LArea > 0 then
    begin
      LCount := LQuery.AreaInfo(LArea, LInfo);
      LLine := LLine + Format(' info %d %d %d %d %d', [LCount, LInfo.Contents, LInfo.Flags, LInfo.PresenceType,
        LInfo.Cluster]) + VecText('a', LInfo.Mins) + VecText('b', LInfo.Maxs) + VecText('c', LInfo.Center);
    end;
    FOutput.Add(LLine);
  end;

  for LIndex := 0 to 79 do
  begin
    LPoint := RandomPoint(LAreas);
    LOther := RandomPoint(LAreas);
    LCount := LTracer.TraceAreas(LPoint, LOther, 16, LAreaList, LPoints);
    LLine := 'ta ' + IntToStr(LIndex) + VecText('s', LPoint) + VecText('e', LOther) + ' n ' + IntToStr(LCount);
    for LK := 0 to LCount - 1 do
      LLine := LLine + ' ' + IntToStr(LAreaList[LK]) + VecText('', LPoints[LK]);
    FOutput.Add(LLine);
    LCount := LTracer.TraceAreas(LPoint, LOther, 2, LAreaList, LPoints);
    LLine := Format('ta2 %d n %d', [LIndex, LCount]);
    if LCount > 0 then
      LLine := LLine + ' ' + IntToStr(LAreaList[0])
    else
      LLine := LLine + ' 0';
    if LCount > 1 then
      LLine := LLine + ' ' + IntToStr(LAreaList[1])
    else
      LLine := LLine + ' 0';
    FOutput.Add(LLine);
    for LK := 0 to 1 do
    begin
      LTrace := LTracer.TraceClientBBox(LPoint, LOther, PRESENCES[LK], -1);
      LEndFace := LFaceTester.TraceEndFace(LTrace);
      LSolid := Flag(LTrace.StartSolid);
      FOutput.Add(Format('tb %d %d solid %d fraction %s', [LIndex, PRESENCES[LK], LSolid,
        Hex(Bits(LTrace.Fraction))]) + VecText('end', LTrace.EndPos) +
        Format(' ent %d area %d last %d plane %d endface %d', [LTrace.Ent, LTrace.Area, LTrace.LastArea,
        LTrace.PlaneNum, LEndFace]));
    end;
  end;

  for LIndex := 0 to 59 do
  begin
    LFace := 1 + RandomInt(Length(AFile.Faces) - 1);
    LPoint := RandomPoint(LAreas);
    LLine := Format('face %d f %d', [LIndex, LFace]) + VecText('p', LPoint);
    LLine := LLine + Format(' pif %d pif0 %d inf %d', [Flag(LFaceTester.PointInsideFace(LFace, LPoint, GROUND_EPSILON)),
      Flag(LFaceTester.PointInsideFace(LFace, LPoint, 0)),
      Flag(LFaceTester.InsideFace(LFace, AFile.Planes[AFile.Faces[LFace].PlaneNum].Normal, LPoint,
        GROUND_EPSILON))]);
    LFaceTester.FacePlane(LFace, LNormal, LDist);
    LLine := LLine + VecText('n', LNormal) + ' d ' + Hex(Bits(LDist));
    LArea := 1 + RandomInt(LAreas);
    LLine := LLine + Format(' ground %d %d', [LArea, LFaceTester.AreaGroundFace(LArea, LPoint)]);
    FOutput.Add(LLine);
  end;

  for LIndex := 0 to 59 do
  begin
    LPlane := RandomInt(Length(AFile.Planes));
    LMins := RandomPoint(LAreas);
    LMaxs[0] := LMins[0] + RandomInt(320) / 8;
    LMaxs[1] := LMins[1] + RandomInt(320) / 8;
    LMaxs[2] := LMins[2] + RandomInt(320) / 8;
    LLine := 'box ' + IntToStr(LIndex) + VecText('m', LMins) + VecText('x', LMaxs);
    LAreaList := LBoxAreas.BBoxAreas(LMins, LMaxs, 8);
    LLine := LLine + ' n8 ' + IntToStr(Length(LAreaList));
    for LK := 0 to High(LAreaList) do
      LLine := LLine + ' ' + IntToStr(LAreaList[LK]);
    LAreaList := LBoxAreas.BBoxAreas(LMins, LMaxs, 2);
    LLine := LLine + ' n2 ' + IntToStr(Length(LAreaList));
    for LK := 0 to High(LAreaList) do
      LLine := LLine + ' ' + IntToStr(LAreaList[LK]);
    LLine := LLine + Format(' plane %d side2 %d side %d', [LPlane,
      TAasBoxMath.BoxOnPlaneSide2(LMins, LMaxs, AFile.Planes[LPlane]),
      TAasBoxMath.BoxOnPlaneSide(LMins, LMaxs, AFile.Planes[LPlane])]);
    TAasBoxMath.PresenceTypeBoundingBox(LImport, PRESENCES[LIndex and 1], LMins, LMaxs);
    LLine := LLine + ' od0 ' + Hex(Bits(TAasBoxMath.BoxOriginDistanceFromPlane(AFile.Planes[LPlane].Normal, LMins,
      LMaxs, 0))) + ' od1 ' + Hex(Bits(TAasBoxMath.BoxOriginDistanceFromPlane(AFile.Planes[LPlane].Normal, LMins,
      LMaxs, 1)));
    FOutput.Add(LLine);
  end;

  for LArea := 0 to LAreas + 2 do
  begin
    LPresence := LQuery.AreaPresenceType(LArea);
    LCluster := LQuery.AreaCluster(LArea);
    LReach := LQuery.AreaReachability(LArea);
    LLine := Format('area %d presence %d cluster %d reach %d', [LArea, LPresence, LCluster, LReach]);
    if LArea <= LAreas then
      LLine := LLine + Format(' grounded %d ladder %d liquid %d swim %d lava %d slime %d jumppad %d ' +
        'teleporter %d portal %d donotenter %d', [Flag(LQuery.AreaGrounded(LArea)), Flag(LQuery.AreaLadder(LArea)),
        Flag(LQuery.AreaLiquid(LArea)), Flag(LQuery.AreaLiquid(LArea)), Flag(LQuery.AreaLava(LArea)),
        Flag(LQuery.AreaSlime(LArea)), Flag(LQuery.AreaJumpPad(LArea)), Flag(LQuery.AreaTeleporter(LArea)),
        Flag(LQuery.AreaClusterPortal(LArea)), Flag(LQuery.AreaDoNotEnter(LArea))]);
    FOutput.Add(LLine);
  end;
  for LK := 2 to 4 do
  begin
    TAasBoxMath.PresenceTypeBoundingBox(LImport, LK, LMins, LMaxs);
    FOutput.Add('bbox ' + IntToStr(LK) + VecText('m', LMins) + VecText('x', LMaxs));
  end;
  FOutput.Add('reachabilityareas ' + IntToStr(LSampler.ReachabilityAreaCount));
end;

end.
