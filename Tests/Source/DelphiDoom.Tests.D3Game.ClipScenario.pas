{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the scenario runner of the   }
{  clip harness (idClip, idClipModel, idEntity::TouchTriggers): the commands   }
{  and the lines of Tools\Verifica\255\harness_clip.cpp, run on the Delphi     }
{  classes                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.ClipScenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Collision.Types, DelphiDoom.D3Game.ClipModel, DelphiDoom.D3Game.Entity, DelphiDoom.Tests.D3Game.WorldRig,
  DelphiDoom.Tests.D3Game.ClipRig;

type
  /// <summary>
  ///   Runs the commands of a scenario of the clip harness (see the header of <c>harness_clip.cpp</c>) on a game with a
  ///   clip and writes the same lines to the trace of the fake world of the rig. The clip models that a physics took
  ///   are owned by the physics; the others by the runner.
  /// </summary>
  TD3ClipScenarioRunner = class
  strict private
    FWorld: TD3ClipWorld;
    FRig: TD3WorldRig;
    FWords: TArray<string>;
    FModels: TDictionary<Integer, TD3ClipModel>;
    FOwned: TObjectList<TD3ClipModel>;
    procedure Line(const AText: string);
    function Bits(const AValue: Single): string;
    function VectorBits(const AValue: TGeoVec3): string;
    function MatrixBits(const AValue: TGeoMat3): string;
    function Num(const AIndex: Integer): Single;
    function Int(const AIndex: Integer): Integer;
    function Vec(const AIndex: Integer): TGeoVec3;
    function Axis(const AIndex: Integer): TGeoMat3;
    function Pass(const AIndex: Integer): TObject;
    function Model(const AIndex: Integer): TD3ClipModel;
    function EntityOf(const ANumber: Integer): TD3Entity;
    procedure PrintTrace(const AReturn: Integer; const ATrace: TCollisionTrace);
    procedure RunCommand(const ACommand: string);
  public
    constructor Create(const AWorld: TD3ClipWorld; const ARig: TD3WorldRig);
    destructor Destroy; override;
    procedure Run(const ALines: TStrings);
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Angles,
  DelphiDoom.MathCore.Float.Conversions, DelphiDoom.MathCore.Float.Rotation, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.Clip, DelphiDoom.D3Game.ClipConvert,
  DelphiDoom.D3Game.Types, DelphiDoom.D3Game.Local;

constructor TD3ClipScenarioRunner.Create(const AWorld: TD3ClipWorld; const ARig: TD3WorldRig);
begin
  inherited Create;
  FWorld := AWorld;
  FRig := ARig;
  FModels := TDictionary<Integer, TD3ClipModel>.Create;
  FOwned := TObjectList<TD3ClipModel>.Create(True);
  FWorld.PrintTo(FRig.World.Trace);
  FRig.World.AddDef('clip_plain', ['spawnclass', 'idRecorder']);
  FRig.World.AddDef('clip_touch', ['spawnclass', 'idTouchRecorder']);
end;

destructor TD3ClipScenarioRunner.Destroy;
begin
  FOwned.Free;
  FModels.Free;
  inherited Destroy;
end;

procedure TD3ClipScenarioRunner.Line(const AText: string);
begin
  FRig.World.Line(AText);
end;

function TD3ClipScenarioRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

function TD3ClipScenarioRunner.VectorBits(const AValue: TGeoVec3): string;
begin
  Result := ' ' + Bits(AValue.X) + ' ' + Bits(AValue.Y) + ' ' + Bits(AValue.Z);
end;

function TD3ClipScenarioRunner.MatrixBits(const AValue: TGeoMat3): string;
begin
  Result := VectorBits(AValue.Rows[0]) + VectorBits(AValue.Rows[1]) + VectorBits(AValue.Rows[2]);
end;

function TD3ClipScenarioRunner.Num(const AIndex: Integer): Single;
var
  LDouble: Double;
begin
  // atof gives a double, the harness makes it a float
  LDouble := StrToFloat(FWords[AIndex], TFormatSettings.Invariant);
  Result := LDouble;
end;

function TD3ClipScenarioRunner.Int(const AIndex: Integer): Integer;
begin
  Result := StrToInt(FWords[AIndex]);
end;

function TD3ClipScenarioRunner.Vec(const AIndex: Integer): TGeoVec3;
begin
  Result := TGeoVec3.Make(Num(AIndex), Num(AIndex + 1), Num(AIndex + 2));
end;

function TD3ClipScenarioRunner.Axis(const AIndex: Integer): TGeoMat3;
begin
  Result := TD3ClipConvert.ToGeo(TIdRotationConversions.AnglesToMat(
    TIdAngles.Create(Num(AIndex), Num(AIndex + 1), Num(AIndex + 2))));
end;

function TD3ClipScenarioRunner.EntityOf(const ANumber: Integer): TD3Entity;
begin
  Result := FRig.Game.Entities[ANumber];
end;

function TD3ClipScenarioRunner.Pass(const AIndex: Integer): TObject;
begin
  if FWords[AIndex] = '-' then
    Result := nil
  else
    Result := EntityOf(Int(AIndex));
end;

function TD3ClipScenarioRunner.Model(const AIndex: Integer): TD3ClipModel;
begin
  if FWords[AIndex] = '-' then
    Result := nil
  else
    Result := FModels[Int(AIndex)];
end;

procedure TD3ClipScenarioRunner.PrintTrace(const AReturn: Integer; const ATrace: TCollisionTrace);
var
  LText: string;
  LFeature: Integer;
begin
  LText := Format('TRACE %d %s%s%s', [AReturn, Bits(ATrace.Fraction), VectorBits(ATrace.EndPos),
    MatrixBits(ATrace.EndAxis)]);
  if ATrace.Fraction < 1.0 then
  begin
    LText := LText + Format(' type=%d', [Ord(ATrace.C.ContactType)]) + VectorBits(ATrace.C.Point) +
      VectorBits(ATrace.C.Normal) + ' ' + Bits(ATrace.C.Dist);
    if ATrace.C.ContactType = ctTrmVertex then
      LFeature := 0
    else
      LFeature := ATrace.C.ModelFeature;
    LText := LText + Format(' contents=%d modelFeature=%d trmFeature=%d', [ATrace.C.Contents, LFeature,
      ATrace.C.TrmFeature]);
  end;
  LText := LText + Format(' entityNum=%d', [ATrace.C.EntityNum]);
  // the id of a trace that hit nothing is not written (the harness: the C++ leaves it uninitialised)
  if ATrace.Fraction < 1.0 then
    LText := LText + Format(' id=%d', [ATrace.C.Id]);
  Line(LText);
end;

procedure TD3ClipScenarioRunner.RunCommand(const ACommand: string);
var
  LEntity: TD3Entity;
  LModel: TD3ClipModel;
  LTrm: TTraceModel;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
  LReturn: Boolean;
  LBounds: TGeoBounds;
  LModels: TList<TD3ClipModel>;
  LEntities: TList<TObject>;
  LIndex: Integer;
  LText: string;
  LNumber: Integer;
  LClip: TD3Clip;
  LOrigin: TIdVec3;
begin
  LClip := FWorld.Clip;
  if ACommand = 'init' then
  begin
    LClip.Init;
    Exit;
  end;
  if ACommand = 'ent' then
  begin
    LNumber := Int(1);
    // the fake world writes the calls of the game to the script (SetEntity): the harness has no such lines
    FRig.World.Quiet := True;
    try
      if (Length(FWords) > 2) and (FWords[2] = 'touch') then
        LEntity := FRig.Spawn(['classname', 'clip_touch', 'name', AnsiString('ent' + IntToStr(LNumber)),
          'spawn_entnum', AnsiString(IntToStr(LNumber))])
      else
        LEntity := FRig.Spawn(['classname', 'clip_plain', 'name', AnsiString('ent' + IntToStr(LNumber)),
          'spawn_entnum', AnsiString(IntToStr(LNumber))]);
    finally
      FRig.World.Quiet := False;
    end;
    Assert(Assigned(LEntity) and (LEntity.EntityNumber = LNumber));
    Exit;
  end;
  if (ACommand = 'box') or (ACommand = 'cyl') or (ACommand = 'bone') then
  begin
    LTrm := TTraceModel.Create;
    try
      if ACommand = 'box' then
        LTrm.SetupBox(TGeoBounds.Make(Vec(5), Vec(8)))
      else if ACommand = 'cyl' then
        LTrm.SetupCylinder(TGeoBounds.Make(Vec(5), Vec(8)), Int(11))
      else
        LTrm.SetupBone(Num(5), Num(6));
      LModel := TD3ClipModel.Create(FWorld.Manager, LTrm);
    finally
      LTrm.Free;
    end;
    LModel.Entity := EntityOf(Int(2));
    LModel.Id := Int(3);
    LModel.Contents := Int(4);
    FModels.AddOrSetValue(Int(1), LModel);
    FOwned.Add(LModel);
    Exit;
  end;
  if ACommand = 'physclip' then
  begin
    LModel := FModels[Int(2)];
    // the physics owns the model from now on
    FOwned.Extract(LModel);
    EntityOf(Int(1)).GetPhysics.SetClipModel(LModel);
    Exit;
  end;
  if ACommand = 'physorigin' then
  begin
    LEntity := EntityOf(Int(1));
    LOrigin := TD3ClipConvert.ToId(Vec(2));
    LEntity.GetPhysics.SetOrigin(LOrigin);
    LEntity.GetPhysics.SetAxis(TD3ClipConvert.ToId(Axis(5)));
    Exit;
  end;
  if ACommand = 'owner' then
  begin
    if Int(2) < 0 then
      FModels[Int(1)].Owner := nil
    else
      FModels[Int(1)].Owner := EntityOf(Int(2));
    Exit;
  end;
  if ACommand = 'link' then
  begin
    LModel := FModels[Int(1)];
    LClip.Link(LModel, LModel.Entity, LModel.Id, Vec(2), Axis(5));
    Line(Format('LINK %d linked=%d%s%s axis%s', [Int(1), Ord(LModel.IsLinked), VectorBits(LModel.AbsBounds.Mins),
      VectorBits(LModel.AbsBounds.Maxs), MatrixBits(LModel.Axis)]));
    Exit;
  end;
  if ACommand = 'unlink' then
  begin
    FModels[Int(1)].Unlink;
    Exit;
  end;
  if ACommand = 'enable' then
  begin
    FModels[Int(1)].Enable;
    Exit;
  end;
  if ACommand = 'disable' then
  begin
    FModels[Int(1)].Disable;
    Exit;
  end;
  if ACommand = 'contents' then
  begin
    FModels[Int(1)].Contents := Int(2);
    Exit;
  end;
  if (ACommand = 'trans') or (ACommand = 'transents') then
  begin
    LTrace := Default(TCollisionTrace);
    LReturn := False;
    if ACommand = 'trans' then
      LReturn := LClip.Translation(LTrace, Vec(2), Vec(5), Model(1), Axis(8), Int(11), Pass(12))
    else
      LClip.TranslationEntities(LTrace, Vec(2), Vec(5), Model(1), Axis(8), Int(11), Pass(12));
    PrintTrace(Ord(LReturn), LTrace);
    Exit;
  end;
  if ACommand = 'rot' then
  begin
    LTrace := Default(TCollisionTrace);
    LRotation := TIdRotation.Create(TD3ClipConvert.ToId(Vec(2)), TD3ClipConvert.ToId(Vec(5)), Num(8));
    LReturn := LClip.Rotation(LTrace, Vec(2), LRotation, Model(1), Axis(9), Int(12), Pass(13));
    PrintTrace(Ord(LReturn), LTrace);
    Exit;
  end;
  if ACommand = 'motion' then
  begin
    LTrace := Default(TCollisionTrace);
    LRotation := TIdRotation.Create(TD3ClipConvert.ToId(Vec(2)), TD3ClipConvert.ToId(Vec(8)), Num(11));
    LReturn := LClip.Motion(LTrace, Vec(2), Vec(5), LRotation, Model(1), Axis(12), Int(15), Pass(16));
    PrintTrace(Ord(LReturn), LTrace);
    Exit;
  end;
  if ACommand = 'contentsat' then
  begin
    Line('CONTENTS ' + IntToStr(LClip.Contents(Vec(2), Model(1), Axis(5), Int(8), Pass(9))));
    Exit;
  end;
  if ACommand = 'tracepoint' then
  begin
    LTrace := Default(TCollisionTrace);
    LReturn := LClip.TracePoint(LTrace, Vec(1), Vec(4), Int(7), Pass(8));
    PrintTrace(Ord(LReturn), LTrace);
    Exit;
  end;
  if ACommand = 'tracebounds' then
  begin
    LTrace := Default(TCollisionTrace);
    LReturn := LClip.TraceBounds(LTrace, Vec(1), Vec(4), TGeoBounds.Make(Vec(7), Vec(10)), Int(13), Pass(14));
    PrintTrace(Ord(LReturn), LTrace);
    Exit;
  end;
  if ACommand = 'touching' then
  begin
    LModels := TList<TD3ClipModel>.Create;
    try
      LBounds := TGeoBounds.Make(Vec(1), Vec(4));
      LClip.ClipModelsTouchingBounds(LBounds, Int(7), LModels, D3_MAX_GENTITIES);
      LText := 'TOUCHING ' + IntToStr(LModels.Count);
      for LIndex := 0 to LModels.Count - 1 do
        LText := LText + Format(' %d:%d', [TD3Entity(LModels[LIndex].Entity).EntityNumber, LModels[LIndex].Id]);
      Line(LText);
    finally
      LModels.Free;
    end;
    Exit;
  end;
  if ACommand = 'entities' then
  begin
    LEntities := TList<TObject>.Create;
    try
      LBounds := TGeoBounds.Make(Vec(1), Vec(4));
      LClip.EntitiesTouchingBounds(LBounds, Int(7), LEntities, D3_MAX_GENTITIES);
      LText := 'ENTITIES ' + IntToStr(LEntities.Count);
      for LIndex := 0 to LEntities.Count - 1 do
        LText := LText + ' ' + IntToStr(TD3Entity(LEntities[LIndex]).EntityNumber);
      Line(LText);
    finally
      LEntities.Free;
    end;
    Exit;
  end;
  if ACommand = 'touchtriggers' then
  begin
    LReturn := EntityOf(Int(1)).TouchTriggers;
    Line(Format('TOUCHTRIGGERS %d ret=%d', [Int(1), Ord(LReturn)]));
    Exit;
  end;
  Line('UNKNOWN ' + ACommand);
end;

procedure TD3ClipScenarioRunner.Run(const ALines: TStrings);
var
  LIndex: Integer;
  LLine: string;
begin
  for LIndex := 0 to ALines.Count - 1 do
  begin
    LLine := Trim(ALines[LIndex]);
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    Line('CMD ' + LLine);
    FWords := LLine.Split([' '], TStringSplitOptions.ExcludeEmpty);
    RunCommand(FWords[0]);
  end;
end;

end.
