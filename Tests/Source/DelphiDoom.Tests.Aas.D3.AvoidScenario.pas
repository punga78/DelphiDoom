{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 obstacle avoidance - the scenario of the    }
{  golden                                                                      }
{                                                                              }
{  The twin of Tools\Verifica\109\avoid_driver.cpp: every line that the real   }
{  AI_pathing.cpp prints is printed here with the same text.                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.AvoidScenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Aas.D3.Avoid.Types, DelphiDoom.Aas.D3.Avoid.Intf, DelphiDoom.Aas.D3.Avoid.PathNode;

type
  /// <summary>
  ///   The game of the scenario: the walker, and the entities around it with the kinds of the C++ driver. It makes
  ///   the choices that idAI::GetObstacles makes on the entities (actors that are not the walker, the one to ignore,
  ///   dead or moving the same way, and moveables)
  /// </summary>
  TScenarioBody = class(TInterfacedObject, IAvoidBody)
  strict private
    type
      TModel = record
        Kind: Integer;
        Model: TAvoidClipModel;
      end;
  strict private
    FBounds: TGeoBounds;
    FAbsBounds: TGeoBounds;
    FOrigin: TGeoVec3;
    FVelocity: TGeoVec3;
    FModels: TList<TModel>;
  public
    constructor Create(const AStart, AVelocity: TGeoVec3);
    destructor Destroy; override;
    /// <summary>Kinds: 0 moveable, 1 alive actor, 2 dead actor, 3 something else, 7 an alive actor like 1, 4 actor moving along +x, 5 the entity to ignore, 6 the walker</summary>
    procedure AddModel(const AKind: Integer; const AModel: TAvoidClipModel);
    function GetBounds: TGeoBounds;
    function GetAbsBounds: TGeoBounds;
    function GetGravityNormal: TGeoVec3;
    function GetOrigin: TGeoVec3;
    function GetLinearVelocity: TGeoVec3;
    function ObstaclesTouchingBounds(const ABounds: TGeoBounds): TArray<TAvoidClipModel>;
  end;

  /// <summary>Runs the scenario on the .aas files of Tests\Data\AasD3 and writes what the C++ driver writes</summary>
  TD3AvoidScenarioRunner = class
  strict private
    FOutput: TStrings;
    FSeed: Cardinal;
    function Rnd: Cardinal;
    procedure Emit(const ALine: string);
    procedure DumpTree(const ANode: TAvoidPathNode; const ADepth: Integer; const AWithDist: Boolean);
    procedure ScenarioA(const ANavigatorIntf: IInterface; const ACount: Integer);
    procedure ScenarioB(const ACount: Integer);
    procedure ScenarioC(const ACount: Integer);
    procedure RunCase(const AName: string; const ACrc: Cardinal);
  public
    constructor Create(const AOutput: TStrings);
    /// <summary>Runs the cases listed in the text (name and CRC, one per line, # for a comment)</summary>
    procedure Run(const ACases: TStrings);
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Mat3, DelphiDoom.Aas.D3.Intf,
  DelphiDoom.Aas.D3.Factory, DelphiDoom.Aas.D3.Avoid.Obstacle, DelphiDoom.Aas.D3.Avoid.ObstacleSet,
  DelphiDoom.Aas.D3.Avoid.PathTree, DelphiDoom.Aas.D3.Avoid.PathOptimizer, DelphiDoom.Aas.D3.Avoid.PathFinder,
  DelphiDoom.Aas.D3.Avoid.Ballistics, DelphiDoom.Tests.Aas.D3.Support;

const
  MILLI: Single = 0.001;
  AXC: array[0..3] of Single = (1.0, 0.8, 0.0, -0.6);
  AXS: array[0..3] of Single = (0.0, 0.6, 1.0, 0.8);

type
  TScenarioLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

function Bits3(const ATag: string; const AValue: TGeoVec3): string;
begin
  Result := ' ' + ATag + ' ' + D3VectorBits(AValue);
end;

function Bits2Vec(const ATag: string; const AValue: TIdVec2): string;
begin
  Result := ' ' + ATag + ' ' + D3Bits(AValue.X) + ' ' + D3Bits(AValue.Y);
end;

function BoolInt(const AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

{ TScenarioLog }

constructor TScenarioLog.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioLog.Printf(const AMessage: string);
begin
  FOutput.Add('P: ' + AMessage + '\n');
end;

procedure TScenarioLog.Warning(const AMessage: string);
begin
  FOutput.Add('W: ' + AMessage);
end;

{ TScenarioBody }

constructor TScenarioBody.Create(const AStart, AVelocity: TGeoVec3);
begin
  inherited Create;
  FModels := TList<TModel>.Create;
  FBounds := TGeoBounds.Make(TGeoVec3.Make(-16, -16, 0), TGeoVec3.Make(16, 16, 72));
  FOrigin := AStart;
  FAbsBounds := TGeoBounds.Make(
    TGeoVec3.Make(AStart.X + FBounds.Mins.X, AStart.Y + FBounds.Mins.Y, AStart.Z + FBounds.Mins.Z),
    TGeoVec3.Make(AStart.X + FBounds.Maxs.X, AStart.Y + FBounds.Maxs.Y, AStart.Z + FBounds.Maxs.Z));
  FVelocity := AVelocity;
end;

destructor TScenarioBody.Destroy;
begin
  FModels.Free;
  inherited Destroy;
end;

procedure TScenarioBody.AddModel(const AKind: Integer; const AModel: TAvoidClipModel);
var
  LModel: TModel;
begin
  LModel.Kind := AKind;
  LModel.Model := AModel;
  FModels.Add(LModel);
end;

function TScenarioBody.GetBounds: TGeoBounds;
begin
  Result := FBounds;
end;

function TScenarioBody.GetAbsBounds: TGeoBounds;
begin
  Result := FAbsBounds;
end;

function TScenarioBody.GetGravityNormal: TGeoVec3;
begin
  Result := TGeoVec3.Make(0, 0, -1);
end;

function TScenarioBody.GetOrigin: TGeoVec3;
begin
  Result := FOrigin;
end;

function TScenarioBody.GetLinearVelocity: TGeoVec3;
begin
  Result := FVelocity;
end;

function TScenarioBody.ObstaclesTouchingBounds(const ABounds: TGeoBounds): TArray<TAvoidClipModel>;
var
  LModel: TModel;
  LList: TList<TAvoidClipModel>;
  LSkip: Boolean;
  LV1, LV2: Single;
begin
  LList := TList<TAvoidClipModel>.Create;
  try
    for LModel in FModels do
    begin
      if not LModel.Model.AbsBounds.IntersectsBounds(ABounds) then
        Continue;
      case LModel.Kind of
        0:
          LSkip := False;
        1, 2, 4, 5, 6, 7:
          begin
            // the walker itself, the entity to ignore and the dead
            LSkip := (LModel.Kind = 6) or (LModel.Kind = 5) or (LModel.Kind = 2);
            // the actor that moves along +x, when the walker moves as well and in about the same direction
            if (not LSkip) and (LModel.Kind = 4) then
            begin
              LV1 := 50.0 * 50.0;
              LV2 := FVelocity.X * FVelocity.X + FVelocity.Y * FVelocity.Y + FVelocity.Z * FVelocity.Z;
              if (LV1 > 100.0) and (LV2 > 100.0) and (50.0 * FVelocity.X > 0.0) then
                LSkip := True;
            end;
          end;
      else
        LSkip := True;
      end;
      if not LSkip then
        LList.Add(LModel.Model);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

{ TD3AvoidScenarioRunner }

constructor TD3AvoidScenarioRunner.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

function TD3AvoidScenarioRunner.Rnd: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

procedure TD3AvoidScenarioRunner.Emit(const ALine: string);
begin
  FOutput.Add(ALine);
end;

procedure TD3AvoidScenarioRunner.DumpTree(const ANode: TAvoidPathNode; const ADepth: Integer; const AWithDist: Boolean);
var
  LLine: string;
begin
  if not Assigned(ANode) then
    Exit;
  LLine := Format('TN %d %d', [ADepth, ANode.Dir]) + Bits2Vec('P', ANode.Pos) + Bits2Vec('D', ANode.Delta) +
    Format(' %d %d %d', [ANode.Obstacle, ANode.EdgeNum, ANode.NumNodes]);
  if AWithDist then
    LLine := LLine + ' ' + D3Bits(ANode.Dist);
  Emit(LLine);
  DumpTree(ANode.Children[0], ADepth + 1, AWithDist);
  DumpTree(ANode.Children[1], ADepth + 1, AWithDist);
end;

procedure TD3AvoidScenarioRunner.ScenarioA(const ANavigatorIntf: IInterface; const ACount: Integer);
var
  LFinder: TAvoidPathFinder;
  LBody: TScenarioBody;
  LBodyIntf: IAvoidBody;
  LPath: TAvoidPath;
  LStart, LSeek, LVelocity, LPoint, LOrigin, LDelta: TGeoVec3;
  LK, LI, LN, LA, LKind, LAx: Integer;
  LX, LY, LT, LOX, LOY, LHX, LHY, LHZ, LR: Single;
  LModel: TAvoidClipModel;
  LOk: Boolean;
begin
  LFinder := TAvoidPathFinder.Create(ANavigatorIntf as IAasNavigator, TScenarioLog.Create(FOutput));
  try
    for LK := 0 to ACount - 1 do
    begin
      LX := 16.0 + Single(Rnd mod 3840) * 0.125;
      LY := 16.0 + Single(Rnd mod 1280) * 0.125;
      LStart := TGeoVec3.Make(LX, LY, 1.0);
      LX := 16.0 + Single(Rnd mod 3840) * 0.125;
      LY := 16.0 + Single(Rnd mod 1280) * 0.125;
      LSeek := TGeoVec3.Make(LX, LY, 1.0);
      LA := Rnd mod 3;
      if LA = 0 then
        LVelocity := TGeoVec3.Make(0, 0, 0)
      else if LA = 1 then
        LVelocity := TGeoVec3.Make(60, 0, 0)
      else
        LVelocity := TGeoVec3.Make(-60, 0, 0);
      LBody := TScenarioBody.Create(LStart, LVelocity);
      LBodyIntf := LBody;
      LN := Rnd mod 8;
      for LI := 0 to LN - 1 do
      begin
        LKind := Rnd mod 8;
        LAx := Rnd mod 4;
        LT := Single(Rnd mod 1001) * MILLI;
        LDelta.X := LSeek.X - LStart.X;
        LDelta.Y := LSeek.Y - LStart.Y;
        LDelta.Z := LSeek.Z - LStart.Z;
        LDelta.X := LDelta.X * LT;
        LDelta.Y := LDelta.Y * LT;
        LDelta.Z := LDelta.Z * LT;
        LPoint.X := LStart.X + LDelta.X;
        LPoint.Y := LStart.Y + LDelta.Y;
        LPoint.Z := LStart.Z + LDelta.Z;
        LOX := LPoint.X + Single(Integer(Rnd mod 641) - 320) * 0.125;
        LOY := LPoint.Y + Single(Integer(Rnd mod 641) - 320) * 0.125;
        LOrigin := TGeoVec3.Make(LOX, LOY, 0.0);
        LHX := 8.0 + Single(Rnd mod 129) * 0.125;
        LHY := 8.0 + Single(Rnd mod 129) * 0.125;
        LHZ := 16.0 + Single(Rnd mod 65);
        if LHX > LHY then
          LR := LHX
        else
          LR := LHY;
        LR := LR * 1.5;
        LModel.EntityId := 100 + LI;
        if LKind = 5 then
          LModel.EntityId := 2;
        LModel.Bounds := TGeoBounds.Make(TGeoVec3.Make(-LHX, -LHY, 0), TGeoVec3.Make(LHX, LHY, LHZ));
        LModel.Origin := LOrigin;
        LModel.AbsBounds := TGeoBounds.Make(TGeoVec3.Make(LOrigin.X - LR, LOrigin.Y - LR, 0.0),
          TGeoVec3.Make(LOrigin.X + LR, LOrigin.Y + LR, LHZ));
        LModel.Axis := TGeoMat3.Make(AXC[LAx], AXS[LAx], 0.0, -AXS[LAx], AXC[LAx], 0.0, 0.0, 0.0, 1.0);
        LBody.AddModel(LKind, LModel);
      end;
      LOk := LFinder.FindPathAroundObstacles(LBodyIntf, LStart, LSeek, LPath);
      Emit(Format('FP %d %d %d', [LK, BoolInt(LOk), LN]) + Bits3('S', LPath.SeekPos) +
        Format(' %d', [LPath.FirstObstacle]) + Bits3('O', LPath.StartPosOutsideObstacles) +
        Format(' %d', [LPath.StartPosObstacle]) + Bits3('G', LPath.SeekPosOutsideObstacles) +
        Format(' %d', [LPath.SeekPosObstacle]));
      LBodyIntf := nil;
    end;
  finally
    LFinder.Free;
  end;
end;

procedure TD3AvoidScenarioRunner.ScenarioB(const ACount: Integer);
var
  LK, LI, LJ, LN, LAx, LInside, LObstacle, LEdge, LBlockObstacle, LBlockEdge: Integer;
  LSet: TAvoidObstacleSet;
  LTree: TAvoidPathTree;
  LOptimizer: TAvoidPathOptimizer;
  LObs: TAvoidObstacle;
  LClipBounds: TGeoBounds;
  LExpMins, LExpMaxs, LStart, LSeek, LS2, LG2, LOut, LPos: TIdVec2;
  LSX, LSY, LGX, LGY, LCX, LCY, LHX, LHY, LDX, LDY, LScale: Single;
  LLX, LLY: array[0..3] of Single;
  LPath: TAvoidPath;
  LSeekPos: TGeoVec3;
  LOk, LBlocked: Boolean;
begin
  LSet := TAvoidObstacleSet.Create(TScenarioLog.Create(FOutput));
  try
    for LK := 0 to ACount - 1 do
    begin
      LN := 1 + Integer(Rnd mod 6);
      LClipBounds := TGeoBounds.Make(TGeoVec3.Make(0, 0, -100), TGeoVec3.Make(520, 200, 100));
      LExpMins := TIdVec2.Create(-17.0, -17.0);
      LExpMaxs := TIdVec2.Create(17.0, 17.0);
      LSX := 16.0 + Single(Rnd mod 3840) * 0.125;
      LSY := 16.0 + Single(Rnd mod 1280) * 0.125;
      LStart := TIdVec2.Create(LSX, LSY);
      LGX := 16.0 + Single(Rnd mod 3840) * 0.125;
      LGY := 16.0 + Single(Rnd mod 1280) * 0.125;
      LSeek := TIdVec2.Create(LGX, LGY);
      LSet.Clear;
      for LI := 0 to LN - 1 do
      begin
        LAx := Rnd mod 4;
        LCX := 16.0 + Single(Rnd mod 3840) * 0.125;
        LCY := 16.0 + Single(Rnd mod 1280) * 0.125;
        LHX := 8.0 + Single(Rnd mod 129) * 0.125;
        LHY := 8.0 + Single(Rnd mod 129) * 0.125;
        LLX[0] := -LHX; LLX[1] := LHX; LLX[2] := LHX; LLX[3] := -LHX;
        LLY[0] := -LHY; LLY[1] := -LHY; LLY[2] := LHY; LLY[3] := LHY;
        LObs := LSet.Add;
        LObs.Winding.Clear;
        for LJ := 0 to 3 do
          LObs.Winding.AddPoint(TIdVec2.Create(LCX + AXC[LAx] * LLX[LJ] - AXS[LAx] * LLY[LJ],
            LCY + AXS[LAx] * LLX[LJ] + AXC[LAx] * LLY[LJ]));
        LObs.Winding.ExpandForAxialBox(LExpMins, LExpMaxs);
        LObs.UpdateBounds;
        LObs.EntityId := AVOID_NO_ENTITY;
        if (LI and 1) <> 0 then
          LObs.EntityId := 100 + LI;
      end;
      Emit(Format('OB %d %d', [LK, LN]) + Bits2Vec('S', LStart) + Bits2Vec('G', LSeek));
      // the point inside an obstacle and the way out
      LInside := LSet.PointInsideObstacle(LStart);
      LOut := LStart;
      LSet.GetPointOutsideObstacles(LOut, LObstacle, LEdge);
      Emit(Format('PI %d %d', [LK, LInside]) + Bits2Vec('O', LOut) + Format(' %d %d', [LObstacle, LEdge]));
      LOut := LSeek;
      LSet.GetPointOutsideObstacles(LOut, LObstacle, LEdge);
      Emit(Format('PO %d', [LK]) + Bits2Vec('O', LOut) + Format(' %d %d', [LObstacle, LEdge]));
      // the first obstacle that blocks the movement
      LScale := 0;
      LBlockObstacle := -9;
      LBlockEdge := -9;
      LBlocked := LSet.GetFirstBlockingObstacle(-1, LStart, LSeek - LStart, LScale, LBlockObstacle, LBlockEdge);
      Emit(Format('BL %d %d %s %d %d', [LK, BoolInt(LBlocked), D3Bits(LScale), LBlockObstacle, LBlockEdge]));
      // the path tree
      LTree := TAvoidPathTree.Create(LSet);
      LOptimizer := TAvoidPathOptimizer.Create(LSet);
      try
        LPath.FirstObstacle := AVOID_NO_ENTITY;
        LS2 := LStart;
        LG2 := LSeek;
        LTree.Build(LClipBounds, LS2, LG2, LPath);
        Emit(Format('BT %d %d %d', [LK, LPath.FirstObstacle, LTree.AllocCount]));
        DumpTree(LTree.Root, 0, False);
        LTree.Prune(LG2);
        Emit(Format('PT %d %d', [LK, LTree.AllocCount]));
        DumpTree(LTree.Root, 0, True);
        LDX := Single(Integer(Rnd mod 21) - 10);
        LDY := Single(Integer(Rnd mod 21) - 10);
        LSeekPos := TGeoVec3.Make(0, 0, 0);
        LOk := LOptimizer.FindOptimalPath(LTree.Root, 5.0, TGeoVec3.Make(LDX, LDY, 0.0), LSeekPos);
        Emit(Format('FO %d %d', [LK, BoolInt(LOk)]) + Bits3('S', LSeekPos));
        LTree.FreeTree;
        Emit(Format('FT %d %d', [LK, LTree.AllocCount]));
      finally
        LOptimizer.Free;
        LTree.Free;
      end;
    end;
  finally
    LSet.Free;
  end;
end;

procedure TD3AvoidScenarioRunner.ScenarioC(const ACount: Integer);
var
  LK, LN, LI: Integer;
  LS0, LS1, LS2, LE0, LE1, LE2, LSpeed, LGravity, LZVel: Single;
  LBallistics: array[0..1] of TAvoidBallistic;
  LLine: string;
begin
  for LK := 0 to ACount - 1 do
  begin
    LS0 := Single(Rnd mod 400) * 0.25;
    LS1 := Single(Rnd mod 400) * 0.25;
    LS2 := Single(Rnd mod 200) * 0.25;
    LE0 := Single(Rnd mod 400) * 0.25;
    LE1 := Single(Rnd mod 400) * 0.25;
    LE2 := Single(Rnd mod 200) * 0.25;
    LSpeed := 100.0 + Single(Rnd mod 1500);
    LGravity := 100.0 + Single(Rnd mod 900);
    LZVel := Single(Rnd mod 700) - 300.0;
    FillChar(LBallistics, SizeOf(LBallistics), 0);
    LN := TAvoidBallistics.Solve(TGeoVec3.Make(LS0, LS1, LS2), TGeoVec3.Make(LE0, LE1, LE2), LSpeed, LGravity,
      LBallistics);
    LLine := Format('BA %d %d', [LK, LN]);
    for LI := 0 to LN - 1 do
      LLine := LLine + ' ' + D3Bits(LBallistics[LI].Angle) + ' ' + D3Bits(LBallistics[LI].Time);
    LLine := LLine + ' ' + D3Bits(TAvoidBallistics.HeightForTrajectory(TGeoVec3.Make(LS0, LS1, LS2), LZVel, LGravity));
    Emit(LLine);
  end;
end;

procedure TD3AvoidScenarioRunner.RunCase(const AName: string; const ACrc: Cardinal);
var
  LNavigator: IAasMapNavigator;
begin
  Emit('CASE ' + AName);
  LNavigator := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile(AName, ACrc), True,
    TScenarioLog.Create(FOutput));
  Emit('INIT 1');
  FSeed := 2463534242;
  ScenarioA(LNavigator, 150);
  Emit('NODES 0');
  ScenarioB(120);
  ScenarioC(60);
end;

procedure TD3AvoidScenarioRunner.Run(const ACases: TStrings);
var
  LIndex, LSpace: Integer;
  LLine: string;
begin
  for LIndex := 0 to ACases.Count - 1 do
  begin
    LLine := Trim(ACases[LIndex]);
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    LSpace := Pos(' ', LLine);
    RunCase(Copy(LLine, 1, LSpace - 1), StrToUInt(Trim(Copy(LLine, LSpace + 1, MaxInt))));
  end;
end;

end.
