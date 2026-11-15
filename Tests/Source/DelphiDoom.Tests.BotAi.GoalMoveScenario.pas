{******************************************************************************}
{                                                                              }
{  DelphiDoom: test support of the bot AI library - the scenario of the        }
{  parity test of goals, movement, elementary actions and genetic selection    }
{  (the commands of Tools\Verifica\123\ai\aigen.c)                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.GoalMoveScenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Entity.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Goal.Intf,
  DelphiDoom.BotAi.Random.MsvcRand, DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.World.AasWorld, DelphiDoom.BotAi.Ea.Types,
  DelphiDoom.BotAi.Ea.Actions, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Goal.System, DelphiDoom.BotAi.Gen.Intf, DelphiDoom.Tests.BotAi.Support;

type
  /// <summary>A solid box of the world twin (the command "solid")</summary>
  TTwinSolid = record
    Entity: Integer;
    Mins: TVec3;
    Maxs: TVec3;
  end;

  /// <summary>
  ///   The BSP of the game as the C tool has it: the trace is the trace of the box of a standing client through the AAS
  ///   plus the solid boxes of the scenario; the contents of a point are those of its AAS area
  /// </summary>
  TTwinBsp = class(TInterfacedObject, IAasBspWorld)
  strict private
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FSolids: TArray<TTwinSolid>;
  public
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer);
    procedure AddSolid(const ASolid: TTwinSolid);
    procedure ClearSolids;
    function PointContents(const APoint: TVec3): Integer;
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
  end;

  /// <summary>The model table, the entity text and the entity trace of the C tool</summary>
  TTwinModels = class(TInterfacedObject, IAasBspModels)
  strict private
    FText: AnsiString;
    FMins: array[0..31] of TVec3;
    FMaxs: array[0..31] of TVec3;
    FOrigins: array[0..31] of TVec3;
  public
    procedure SetModel(const AIndex: Integer; const AMins, AMaxs, AOrigin: TVec3);
    property Text: AnsiString read FText write FText;
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

  /// <summary>The entity table of the scenario (the command "entity")</summary>
  TTwinEntities = class(TInterfacedObject, IBotEntitySource)
  strict private
    FInfo: array[0..63] of TAasEntityInfo;
  public
    procedure SetEntity(const AIndex: Integer; const AInfo: TAasEntityInfo);
    procedure Clear;
    function EntityType(const AEntity: Integer): Integer;
    function EntityModelIndex(const AEntity: Integer): Integer;
    function EntityModelNum(const AEntity: Integer): Integer;
    function EntityInfo(const AEntity: Integer): TAasEntityInfo;
    function NextEntity(const AEntity: Integer): Integer;
    function OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
  end;

  /// <summary>AAS_BestReachableArea as the C tool has it: the area of the point if it has reachabilities</summary>
  TTwinBestReachable = class(TInterfacedObject, IAasBestReachable)
  strict private
    FSampler: IAasSampler;
    FAreas: IAasAreaQuery;
  public
    constructor Create(const ASampler: IAasSampler; const AAreas: IAasAreaQuery);
    function BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
    function BestReachableLinkArea(const ALinkHead: Integer): Integer;
    function BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
  end;

  /// <summary>
  ///   Runs the lines of a scenario on the Delphi classes and writes what the C tool writes: the line of the command
  ///   (">" and the text), then its results and what the library prints, logs and sends, in the order it does.
  ///   The floats are written as their bits.
  /// </summary>
  TGoalMoveScenario = class
  strict private
    FOutput: TStringList;
    FImport: TFakeBotImport;
    FImportRef: IInterface;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FRandom: TBotMsvcRandom;
    FRandomRef: IInterface;
    FFolder: string;
    FFiles: IBotFileSource;
    FWeights: IBotWeightCache;
    FDeveloper: Boolean;
    FTime: Single;
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FRouter: IAasRouter;
    FMovement: IAasMovement;
    FAreas: IAasAreaQuery;
    FBestReachable: IAasBestReachable;
    FBspEntities: IAasBspEntities;
    FBspObject: TTwinBsp;
    FBsp: IAasBspWorld;
    FModelsObject: TTwinModels;
    FModels: IAasBspModels;
    FEntitiesObject: TTwinEntities;
    FEntities: IBotEntitySource;
    FWorldObject: TBotAasWorld;
    FWorld: IBotAasWorld;
    FActions: TBotElementaryActions;
    FActionsRef: IInterface;
    FGoalObject: TBotGoalSystem;
    FGoal: IBotGoalSystem;
    FMove: IBotMoveSystem;
    FGenetics: IBotGenetics;
    FArgs: TArray<AnsiString>;
    procedure Flush;
    procedure Emit(const ALine: string);
    function Arg(const AIndex: Integer): AnsiString;
    function Num(const AIndex: Integer): Integer;
    function FloatArg(const AIndex: Integer): Single;
    function VectorArg(const AIndex: Integer): TVec3;
    function GoalArg(const AIndex: Integer): TBotGoal;
    function Inventory(const AFirst: Integer): TArray<Integer>;
    class function Bits(const AValue: Single): string; static;
    class function VectorText(const ATag: string; const AValue: TVec3): string; static;
    class function FloatText(const ATag: string; const AValue: Single): string; static;
    function GoalText(const ATag: string; const AGoal: TBotGoal): string;
    function InputText(const ATag: string; const AInput: TBotInput): string;
    function ResultText(const ATag: string; const AResult: TBotMoveResult): string;
    procedure EnsureSystems;
    procedure SetMap;
    procedure LoadAas(const AName: string);
    procedure PrintTop(const AHandle: Integer);
    procedure RunSimulation(const AHandle, AClient, ATics: Integer; const AThinkTime: Single; var AOrigin: TVec3;
      const ATravelFlags: Integer; const AGoal: TBotGoal);
    procedure Execute(const ALine: AnsiString);
  public
    constructor Create(const AFolder: string);
    destructor Destroy; override;
    /// <summary>Runs every line of the scenario; the output is in <c>Output</c></summary>
    procedure Run(const AScenario: TStrings);
    property Output: TStringList read FOutput;
  end;

implementation

uses
  System.Math, System.IOUtils, DelphiDoom.Aas.Factory, DelphiDoom.Aas.Move.Movement, DelphiDoom.Aas.Move.Settings,
  DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Bsp.Entities, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Types,
  DelphiDoom.BotAi.Weight.Factory, DelphiDoom.BotAi.Gen.Selector, DelphiDoom.BotAi.Move.Factory,
  DelphiDoom.BotAi.Goal.Context, DelphiDoom.BotAi.Goal.LevelItems;

const
  /// <summary>The checksum of the world (library variable sv_mapChecksum): the header says so</summary>
  MAX_SOLIDS = 16;
  /// <summary>ET_MOVER of bg_public.h</summary>
  ET_MOVER = 4;
  CONTENTS_SOLID_TWIN = 1;

{ TTwinBsp }

constructor TTwinBsp.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer);
begin
  inherited Create;
  FFile := AFile;
  FSampler := ASampler;
  FTracer := ATracer;
end;

procedure TTwinBsp.AddSolid(const ASolid: TTwinSolid);
begin
  SetLength(FSolids, Length(FSolids) + 1);
  FSolids[High(FSolids)] := ASolid;
end;

procedure TTwinBsp.ClearSolids;
begin
  FSolids := nil;
end;

function TTwinBsp.PointContents(const APoint: TVec3): Integer;
var
  LAreaNum: Integer;
begin
  Result := 0;
  LAreaNum := FSampler.PointAreaNum(APoint);
  if LAreaNum <> 0 then
  begin
    if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_WATER) <> 0 then
      Result := Result or BSP_CONTENTS_WATER;
    if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_LAVA) <> 0 then
      Result := Result or BSP_CONTENTS_LAVA;
    if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_SLIME) <> 0 then
      Result := Result or BSP_CONTENTS_SLIME;
  end;
end;

function TTwinBsp.Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
  AContentMask: Integer): TAasBspTrace;
var
  LTrace: TAasTrace;
  LIndex: Integer;
  LAxis: Integer;
  LMin: TVec3;
  LMax: TVec3;
  LTMin: Single;
  LTMax: Single;
  LDelta: Single;
  LT1: Single;
  LT2: Single;
  LTemp: Single;
  LMiss: Boolean;
  LInside: Boolean;
  LBoxMin: Single;
  LBoxMax: Single;
  LStep: Single;
begin
  LTrace := FTracer.TraceClientBBox(AStart, AEnd, PRESENCE_NORMAL, -1);
  FillChar(Result, SizeOf(Result), 0);
  Result.StartSolid := LTrace.StartSolid;
  Result.Fraction := LTrace.Fraction;
  Result.EndPos := LTrace.EndPos;
  if (LTrace.Fraction < 1) or LTrace.StartSolid then
    Result.EntityNum := ENTITYNUM_WORLD
  else
    Result.EntityNum := ENTITYNUM_NONE;
  for LIndex := 0 to High(FSolids) do
  begin
    if FSolids[LIndex].Entity = APassEnt then
      Continue;
    for LAxis := 0 to 2 do
    begin
      LBoxMax := 0;
      LBoxMin := 0;
      if Assigned(AMaxs) then
        LBoxMax := AMaxs^[LAxis];
      if Assigned(AMins) then
        LBoxMin := AMins^[LAxis];
      LMin[LAxis] := FSolids[LIndex].Mins[LAxis] - LBoxMax;
      LMax[LAxis] := FSolids[LIndex].Maxs[LAxis] - LBoxMin;
    end;
    LTMin := 0;
    LTMax := 1;
    LMiss := False;
    LInside := True;
    for LAxis := 0 to 2 do
    begin
      LDelta := AEnd[LAxis] - AStart[LAxis];
      if (AStart[LAxis] < LMin[LAxis]) or (AStart[LAxis] > LMax[LAxis]) then
        LInside := False;
      if LDelta = 0 then
      begin
        if (AStart[LAxis] < LMin[LAxis]) or (AStart[LAxis] > LMax[LAxis]) then
        begin
          LMiss := True;
          Break;
        end;
      end
      else
      begin
        LT1 := LMin[LAxis] - AStart[LAxis];
        LT1 := LT1 / LDelta;
        LT2 := LMax[LAxis] - AStart[LAxis];
        LT2 := LT2 / LDelta;
        if LT1 > LT2 then
        begin
          LTemp := LT1;
          LT1 := LT2;
          LT2 := LTemp;
        end;
        if LT1 > LTMin then
          LTMin := LT1;
        if LT2 < LTMax then
          LTMax := LT2;
        if LTMin > LTMax then
        begin
          LMiss := True;
          Break;
        end;
      end;
    end;
    if LMiss then
      Continue;
    if LInside then
    begin
      Result.StartSolid := True;
      Result.AllSolid := False;
      Result.Fraction := 0;
      Result.EndPos := AStart;
      Result.EntityNum := FSolids[LIndex].Entity;
      Continue;
    end;
    if LTMin < Result.Fraction then
    begin
      Result.Fraction := LTMin;
      for LAxis := 0 to 2 do
      begin
        LStep := AEnd[LAxis] - AStart[LAxis];
        LStep := LStep * LTMin;
        Result.EndPos[LAxis] := AStart[LAxis] + LStep;
      end;
      Result.EntityNum := FSolids[LIndex].Entity;
    end;
  end;
end;

{ TTwinModels }

procedure TTwinModels.SetModel(const AIndex: Integer; const AMins, AMaxs, AOrigin: TVec3);
begin
  if (AIndex < 0) or (AIndex > High(FMins)) then
    raise Exception.CreateFmt('The scenario has no model %d', [AIndex]);
  FMins[AIndex] := AMins;
  FMaxs[AIndex] := AMaxs;
  FOrigins[AIndex] := AOrigin;
end;

function TTwinModels.EntityData: AnsiString;
begin
  Result := FText;
end;

function TTwinModels.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
  AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
end;

function TTwinModels.InPVS(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := True;
end;

procedure TTwinModels.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs,
  AOrigin: TVec3);
begin
  if (AModelNum < 0) or (AModelNum > High(FMins)) then
  begin
    AMins := Default(TVec3);
    AMaxs := Default(TVec3);
    AOrigin := Default(TVec3);
    Exit;
  end;
  AMins := FMins[AModelNum];
  AMaxs := FMaxs[AModelNum];
  AOrigin := FOrigins[AModelNum];
end;

{ TTwinEntities }

procedure TTwinEntities.SetEntity(const AIndex: Integer; const AInfo: TAasEntityInfo);
begin
  if (AIndex < 0) or (AIndex > High(FInfo)) then
    raise Exception.CreateFmt('The scenario has no entity %d', [AIndex]);
  FInfo[AIndex] := AInfo;
end;

procedure TTwinEntities.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FInfo) do
    FInfo[LIndex] := Default(TAasEntityInfo);
end;

function TTwinEntities.EntityType(const AEntity: Integer): Integer;
begin
  if (AEntity < 0) or (AEntity > High(FInfo)) then
    Exit(0);
  Result := FInfo[AEntity].EntityType;
end;

function TTwinEntities.EntityModelIndex(const AEntity: Integer): Integer;
begin
  if (AEntity < 0) or (AEntity > High(FInfo)) then
    Exit(0);
  Result := FInfo[AEntity].ModelIndex;
end;

function TTwinEntities.EntityModelNum(const AEntity: Integer): Integer;
begin
  Result := EntityModelIndex(AEntity);
end;

function TTwinEntities.EntityInfo(const AEntity: Integer): TAasEntityInfo;
begin
  if (AEntity < 0) or (AEntity > High(FInfo)) then
    Exit(Default(TAasEntityInfo));
  Result := FInfo[AEntity];
end;

function TTwinEntities.NextEntity(const AEntity: Integer): Integer;
var
  LEntity: Integer;
begin
  LEntity := AEntity;
  if LEntity < 0 then
    LEntity := -1;
  Inc(LEntity);
  while LEntity <= High(FInfo) do
  begin
    if FInfo[LEntity].Valid then
      Exit(LEntity);
    Inc(LEntity);
  end;
  Result := 0;
end;

function TTwinEntities.OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
var
  LIndex: Integer;
begin
  AOrigin := Default(TVec3);
  for LIndex := 0 to High(FInfo) do
  begin
    if (FInfo[LIndex].EntityType = ET_MOVER) and (FInfo[LIndex].ModelIndex = AModelNum) then
    begin
      AOrigin := FInfo[LIndex].Origin;
      Exit(True);
    end;
  end;
  Result := False;
end;

{ TTwinBestReachable }

constructor TTwinBestReachable.Create(const ASampler: IAasSampler; const AAreas: IAasAreaQuery);
begin
  inherited Create;
  FSampler := ASampler;
  FAreas := AAreas;
end;

function TTwinBestReachable.BestReachableArea(const AOrigin, AMins, AMaxs: TVec3; var AGoalOrigin: TVec3): Integer;
var
  LAreaNum: Integer;
begin
  LAreaNum := FSampler.PointAreaNum(AOrigin);
  AGoalOrigin := AOrigin;
  if (LAreaNum <> 0) and (FAreas.AreaReachability(LAreaNum) <> 0) then
    Exit(LAreaNum);
  Result := 0;
end;

function TTwinBestReachable.BestReachableLinkArea(const ALinkHead: Integer): Integer;
begin
  Result := 0;
end;

function TTwinBestReachable.BestReachableFromJumpPadArea(const AOrigin, AMins, AMaxs: TVec3): Integer;
begin
  Result := 0;
end;

{ TGoalMoveScenario }

constructor TGoalMoveScenario.Create(const AFolder: string);
begin
  inherited Create;
  FOutput := TStringList.Create;
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FRandom := TBotMsvcRandom.Create(1);
  FRandomRef := FRandom;
  FFolder := AFolder;
  FFiles := TFolderBotFiles.Create(AFolder);
  FWeights := TBotWeightFactory.CreateWeightCache(FImport, FFiles, FLibVars);
  FEntitiesObject := TTwinEntities.Create;
  FEntities := FEntitiesObject;
  FModelsObject := TTwinModels.Create;
  FModels := FModelsObject;
  FGenetics := TBotGeneticSelector.Create(FImport, FRandom);
end;

destructor TGoalMoveScenario.Destroy;
begin
  FGenetics := nil;
  FMove := nil;
  FGoal := nil;
  FGoalObject := nil;
  FActionsRef := nil;
  FWorld := nil;
  FWeights := nil;
  FFiles := nil;
  FOutput.Free;
  inherited Destroy;
end;

procedure TGoalMoveScenario.Flush;
var
  LLine: string;
begin
  for LLine in FImport.Lines do
    FOutput.Add(LLine);
  FImport.Lines.Clear;
end;

procedure TGoalMoveScenario.Emit(const ALine: string);
begin
  // what the library printed before comes first
  Flush;
  FOutput.Add(ALine);
end;

function TGoalMoveScenario.Arg(const AIndex: Integer): AnsiString;
begin
  if AIndex < Length(FArgs) then
    Result := FArgs[AIndex]
  else
    Result := '';
end;

function TGoalMoveScenario.Num(const AIndex: Integer): Integer;
var
  LText: string;
  LIndex: Integer;
  LNegative: Boolean;
  LValue: Int64;
  LHex: Boolean;
  LDigit: Integer;
begin
  // strtol with base 0: the digits at the start of the text, a leading 0x is hexadecimal, anything else is 0
  LText := Trim(string(Arg(AIndex)));
  LIndex := 1;
  LNegative := False;
  if (LIndex <= Length(LText)) and ((LText[LIndex] = '-') or (LText[LIndex] = '+')) then
  begin
    LNegative := LText[LIndex] = '-';
    Inc(LIndex);
  end;
  LHex := (LIndex + 1 <= Length(LText)) and (LText[LIndex] = '0') and ((LText[LIndex + 1] = 'x') or
    (LText[LIndex + 1] = 'X'));
  if LHex then
    Inc(LIndex, 2);
  LValue := 0;
  while LIndex <= Length(LText) do
  begin
    if (LText[LIndex] >= '0') and (LText[LIndex] <= '9') then
      LDigit := Ord(LText[LIndex]) - Ord('0')
    else if LHex and (LText[LIndex] >= 'a') and (LText[LIndex] <= 'f') then
      LDigit := Ord(LText[LIndex]) - Ord('a') + 10
    else if LHex and (LText[LIndex] >= 'A') and (LText[LIndex] <= 'F') then
      LDigit := Ord(LText[LIndex]) - Ord('A') + 10
    else
      Break;
    if LHex then
      LValue := LValue * 16 + LDigit
    else
      LValue := LValue * 10 + LDigit;
    Inc(LIndex);
  end;
  if LNegative then
    LValue := -LValue;
  Result := Integer(LValue);
end;

function TGoalMoveScenario.FloatArg(const AIndex: Integer): Single;
var
  LText: string;
  LDouble: Double;
begin
  LText := Trim(string(Arg(AIndex)));
  if LText = '' then
    Exit(0);
  // atof gives a double, which is then converted to a float
  LDouble := StrToFloat(LText, TFormatSettings.Invariant);
  Result := LDouble;
end;

function TGoalMoveScenario.VectorArg(const AIndex: Integer): TVec3;
begin
  Result[0] := FloatArg(AIndex);
  Result[1] := FloatArg(AIndex + 1);
  Result[2] := FloatArg(AIndex + 2);
end;

function TGoalMoveScenario.GoalArg(const AIndex: Integer): TBotGoal;
begin
  Result := Default(TBotGoal);
  Result.Origin := VectorArg(AIndex);
  Result.AreaNum := Num(AIndex + 3);
  Result.EntityNum := Num(AIndex + 4);
  Result.Number := Num(AIndex + 5);
  Result.Flags := Num(AIndex + 6);
  Result.Mins[0] := -15;
  Result.Mins[1] := -15;
  Result.Mins[2] := -15;
  Result.Maxs[0] := 15;
  Result.Maxs[1] := 15;
  Result.Maxs[2] := 15;
end;

function TGoalMoveScenario.Inventory(const AFirst: Integer): TArray<Integer>;
var
  LIndex: Integer;
begin
  // 1024 integers, the rest zero
  SetLength(Result, 1024);
  for LIndex := AFirst to High(FArgs) do
  begin
    if LIndex - AFirst < 1024 then
      Result[LIndex - AFirst] := Num(LIndex);
  end;
end;

class function TGoalMoveScenario.Bits(const AValue: Single): string;
begin
  Result := '#' + LowerCase(Format('%.8x', [PCardinal(@AValue)^]));
end;

class function TGoalMoveScenario.VectorText(const ATag: string; const AValue: TVec3): string;
begin
  Result := ' ' + ATag + ' ' + Bits(AValue[0]) + ' ' + Bits(AValue[1]) + ' ' + Bits(AValue[2]);
end;

class function TGoalMoveScenario.FloatText(const ATag: string; const AValue: Single): string;
begin
  Result := ' ' + ATag + ' ' + Bits(AValue);
end;

function TGoalMoveScenario.GoalText(const ATag: string; const AGoal: TBotGoal): string;
begin
  Result := ATag + VectorText('O', AGoal.Origin) + ' A ' + IntToStr(AGoal.AreaNum) + VectorText('N', AGoal.Mins) +
    VectorText('X', AGoal.Maxs) + Format(' E %d NUM %d F %d I %d', [AGoal.EntityNum, AGoal.Number, AGoal.Flags,
    AGoal.ItemInfo]);
end;

function TGoalMoveScenario.InputText(const ATag: string; const AInput: TBotInput): string;
begin
  Result := ATag + FloatText('T', AInput.ThinkTime) + VectorText('D', AInput.Dir) + FloatText('S', AInput.Speed) +
    VectorText('V', AInput.ViewAngles) + Format(' A %d W %d', [AInput.ActionFlags, AInput.Weapon]);
end;

function TGoalMoveScenario.ResultText(const ATag: string; const AResult: TBotMoveResult): string;
begin
  Result := Format('%s F %d T %d B %d BE %d TT %d FL %d W %d', [ATag, Ord(AResult.Failure), AResult.ResultType,
    Ord(AResult.Blocked), AResult.BlockEntity, AResult.TravelType, AResult.Flags, AResult.Weapon]) +
    VectorText('D', AResult.MoveDir) + VectorText('V', AResult.IdealViewAngles);
end;

procedure TGoalMoveScenario.SetMap;
begin
  if not Assigned(FWorldObject) then
    Exit;
  FWorldObject.SetMap(FAreas, FSampler, FTracer, FRouter, FMovement, FBestReachable, FBspEntities);
end;

procedure TGoalMoveScenario.LoadAas(const AName: string);
var
  LPath: string;
  LBytes: TBytes;
  LHeader: TAasFileHeader;
  LChecksum: Integer;
begin
  LPath := TPath.Combine(FFolder, AName);
  if not TFile.Exists(LPath) then
  begin
    Emit('FILE ' + AName + ' missing');
    Exit;
  end;
  LBytes := TFile.ReadAllBytes(LPath);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  LChecksum := LHeader.BspChecksum;
  FImport.Print(1, 'trying to load maps/bots.aas'#10);
  FFile := TAasFactory.CreateReader(FImport, nil, FLibVars).ParseBytes(LBytes, 'maps/bots.aas', LChecksum);
  Emit('LOAD 0');
  FSampler := TAasFactory.CreateSampler(FFile, FImport, True);
  FTracer := TAasFactory.CreateTracer(FFile, FImport);
  FAreas := TAasFactory.CreateAreaQuery(FFile, FImport);
  FBspObject := TTwinBsp.Create(FFile, FSampler, FTracer);
  FBsp := FBspObject;
  FMovement := TAasMovement.Create(FFile, FSampler, FTracer, TAasFactory.CreateFaceTester(FFile, FImport), FBsp,
    FImport, TAasMoveSettingsReader.Read(FLibVars));
  FRouter := TAasFactory.CreateRouter(FFile, FImport, FTracer, nil, FDeveloper);
  FBestReachable := TTwinBestReachable.Create(FSampler, FAreas);
  FWorldObject := TBotAasWorld.Create(FBsp, FModels, FEntities);
  FWorld := FWorldObject;
  FWorldObject.SetTime(FTime);
  SetMap;
  Emit(Format('AAS %d %d %d %d', [Length(FFile.Areas), Length(FFile.Clusters), Length(FFile.Portals),
    Length(FFile.Reachability)]));
end;

procedure TGoalMoveScenario.EnsureSystems;
begin
  if Assigned(FMove) then
    Exit;
  FMove := TBotMoveFactory.CreateMoveSystem(FImport, FLibVars, FWorld, FActions, FRandom, FDeveloper);
  FGoalObject := TBotGoalSystem.Create(FImport, FFiles, FLibVars, FWeights, FWorld, FMove.Locator, FRandom,
    FDeveloper);
  FGoal := FGoalObject;
end;

procedure TGoalMoveScenario.PrintTop(const AHandle: Integer);
var
  LGoal: TBotGoal;
  LResult: Boolean;
begin
  LResult := FGoal.GetTopGoal(AHandle, LGoal);
  Emit('TOP ' + IntToStr(Ord(LResult)));
  if LResult then
    Emit(GoalText(' G', LGoal));
end;

procedure TGoalMoveScenario.RunSimulation(const AHandle, AClient, ATics: Integer; const AThinkTime: Single;
  var AOrigin: TVec3; const ATravelFlags: Integer; const AGoal: TBotGoal);
var
  LVelocity: TVec3;
  LTarget: TVec3;
  LDelta: TVec3;
  LTic: Integer;
  LInit: TBotInitMove;
  LResult: TBotMoveResult;
  LInput: TBotInput;
  LTrace: TAasTrace;
  LStep: Single;
  LInverse: Single;
  LGoal: TBotGoal;
  LIndex: Integer;
begin
  LVelocity := Default(TVec3);
  LGoal := AGoal;
  for LTic := 0 to ATics - 1 do
  begin
    LInit := Default(TBotInitMove);
    LInit.Origin := AOrigin;
    LInit.Velocity := LVelocity;
    LInit.ViewOffset[2] := 24;
    LInit.EntityNum := 1;
    LInit.Client := AClient;
    LInit.ThinkTime := AThinkTime;
    LInit.PresenceType := PRESENCE_NORMAL;
    FMove.InitMoveState(AHandle, LInit);
    LResult := FMove.MoveToGoal(AHandle, @LGoal, ATravelFlags);
    LInput := FActions.GetInput(AClient, AThinkTime);
    Emit('TIC ' + IntToStr(LTic) + VectorText('O', AOrigin));
    Emit(ResultText(' R', LResult));
    Emit(InputText(' I', LInput));
    // the world of the simulation: the bot goes where it was told, as far as the AAS lets it
    LStep := LInput.Speed * AThinkTime;
    for LIndex := 0 to 2 do
      LDelta[LIndex] := LInput.Dir[LIndex] * LStep;
    for LIndex := 0 to 2 do
      LTarget[LIndex] := AOrigin[LIndex] + LDelta[LIndex];
    LTrace := FTracer.TraceClientBBox(AOrigin, LTarget, PRESENCE_NORMAL, -1);
    LInverse := 1 / AThinkTime;
    for LIndex := 0 to 2 do
    begin
      LStep := LTrace.EndPos[LIndex] - AOrigin[LIndex];
      LVelocity[LIndex] := LStep * LInverse;
    end;
    AOrigin := LTrace.EndPos;
    FActions.ResetInput(AClient);
  end;
end;

procedure TGoalMoveScenario.Execute(const ALine: AnsiString);
var
  LCommand: AnsiString;
  LHandle: Integer;
  LRanks: TArray<Single>;
  LIndex: Integer;
  LP1, LP2, LChild: Integer;
  LResult: Boolean;
  LGoal: TBotGoal;
  LGoal2: TBotGoal;
  LOrigin: TVec3;
  LInfo: TAasEntityInfo;
  LSolid: TTwinSolid;
  LInput: TBotInput;
  LInit: TBotInitMove;
  LTarget: TVec3;
  LMoveResult: TBotMoveResult;
  LCount: Integer;
  LItem: Integer;
  LLevelItem: PBotLevelItem;
  LCode: Integer;
  LText: string;
begin
  LCommand := Arg(0);
  LHandle := Num(1);
  if LCommand = 'libvar' then
    FLibVars.SetText(Arg(1), Arg(2))
  else if LCommand = 'developer' then
    FDeveloper := Num(1) <> 0
  else if LCommand = 'time' then
  begin
    FTime := FloatArg(1);
    if Assigned(FWorldObject) then
      FWorldObject.SetTime(FTime);
  end
  else if LCommand = 'srand' then
    FRandom.SetSeed(Cardinal(Num(1)))
  else if LCommand = 'loadaas' then
    LoadAas(string(Arg(1)))
  else if LCommand = 'entdata' then
  begin
    FModelsObject.Text := Arg(1);
    FBspEntities := TAasBspEntities.Create(FImport, Arg(1));
    SetMap;
  end
  else if LCommand = 'model' then
    FModelsObject.SetModel(Num(1), VectorArg(2), VectorArg(5), VectorArg(8))
  else if LCommand = 'solid' then
  begin
    LSolid.Entity := Num(1);
    LSolid.Mins := VectorArg(2);
    LSolid.Maxs := VectorArg(5);
    FBspObject.AddSolid(LSolid);
  end
  else if LCommand = 'clearsolids' then
    FBspObject.ClearSolids
  else if LCommand = 'entity' then
  begin
    LInfo := Default(TAasEntityInfo);
    LInfo.Valid := Num(2) <> 0;
    LInfo.EntityType := Num(3);
    LInfo.ModelIndex := Num(4);
    LInfo.Origin := VectorArg(5);
    LInfo.LastVisOrigin := VectorArg(8);
    LInfo.Weapon := Num(11);
    LInfo.LocalTime := FloatArg(12);
    LInfo.Number := Num(1);
    FEntitiesObject.SetEntity(Num(1), LInfo);
  end
  else if LCommand = 'entityclear' then
    FEntitiesObject.Clear
  else if LCommand = 'gen' then
  begin
    SetLength(LRanks, Length(FArgs) - 1);
    for LIndex := 0 to High(LRanks) do
      LRanks[LIndex] := FloatArg(LIndex + 1);
    LP1 := -9;
    LP2 := -9;
    LChild := -9;
    LResult := FGenetics.ParentsAndChildSelection(LRanks, LP1, LP2, LChild);
    Emit(Format('GEN %d %d %d %d', [Ord(LResult), LP1, LP2, LChild]));
  end
  else if LCommand = 'gensel' then
  begin
    SetLength(LRanks, Length(FArgs) - 1);
    for LIndex := 0 to High(LRanks) do
      LRanks[LIndex] := FloatArg(LIndex + 1);
    Emit('SEL ' + IntToStr(FGenetics.Selection(LRanks)));
  end
  else if LCommand = 'world' then
  begin
    EnsureSystems;
    LOrigin := VectorArg(1);
    Emit(Format('WO %d %d %d %d %d', [Ord(FMovement.OnGround(LOrigin, PRESENCE_NORMAL, -1)),
      Ord(FMovement.Swimming(LOrigin)), Ord(FMovement.AgainstLadder(LOrigin)), FSampler.PointAreaNum(LOrigin),
      FMove.Locator.FuzzyPointReachabilityArea(LOrigin)]));
  end
  else if LCommand = 'ttable' then
  begin
    for LIndex := 1 to Length(FFile.Areas) - 1 do
    begin
      LText := 'TT ' + IntToStr(LIndex);
      LOrigin := FFile.Areas[LIndex].Center;
      for LCount := 1 to Length(FFile.Areas) - 1 do
        LText := LText + ' ' + IntToStr(FRouter.AreaTravelTimeToGoalArea(LIndex, @LOrigin, LCount, Num(1)));
      Emit(LText);
    end;
  end
  else if LCommand = 'easetup' then
  begin
    FActions := TBotElementaryActions.Create(FImport, Num(1));
    FActionsRef := FActions;
    Emit('RC 0');
  end
  else if LCommand = 'eainput' then
    Emit(InputText('IN', FActions.GetInput(Num(1), FloatArg(2))))
  else if LCommand = 'eareset' then
    FActions.ResetInput(Num(1))
  else if LCommand = 'goalsetup' then
  begin
    EnsureSystems;
    Emit('RC ' + IntToStr(FGoal.Setup));
  end
  else if LCommand = 'goalinit' then
  begin
    EnsureSystems;
    FGoal.InitLevelItems;
  end
  else if LCommand = 'goalupdate' then
  begin
    EnsureSystems;
    FGoal.UpdateEntityItems;
  end
  else if LCommand = 'golist' then
  begin
    EnsureSystems;
    LItem := FGoalObject.Context.LevelItems.Head;
    while LItem <> TBotLevelItems.NoItem do
    begin
      LLevelItem := FGoalObject.Context.LevelItems.Item(LItem);
      Emit(Format('LI %d %d %d', [LLevelItem.Number, LLevelItem.ItemInfo, LLevelItem.Flags]) +
        FloatText('W', LLevelItem.Weight) + VectorText('O', LLevelItem.Origin) + ' GA ' +
        IntToStr(LLevelItem.GoalAreaNum) + VectorText('GO', LLevelItem.GoalOrigin) + ' E ' +
        IntToStr(LLevelItem.EntityNum) + FloatText('T', LLevelItem.Timeout));
      LItem := LLevelItem.Next;
    end;
    Emit('LIN ' + IntToStr(FGoalObject.Context.NumLevelItems));
  end
  else if LCommand = 'gsshutdown' then
  begin
    EnsureSystems;
    FGoal.Shutdown;
  end
  else if LCommand = 'gsalloc' then
  begin
    EnsureSystems;
    Emit('H ' + IntToStr(FGoal.AllocGoalState(Num(1))));
  end
  else if LCommand = 'gsfree' then
    FGoal.FreeGoalState(LHandle)
  else if LCommand = 'gsreset' then
    FGoal.ResetGoalState(LHandle)
  else if LCommand = 'gsweights' then
    Emit('RC ' + IntToStr(FGoal.LoadItemWeights(LHandle, Arg(2))))
  else if LCommand = 'gsfreeweights' then
    FGoal.FreeItemWeights(LHandle)
  else if LCommand = 'gsltg' then
  begin
    LResult := FGoal.ChooseLTGItem(LHandle, VectorArg(2), Inventory(6), Num(5));
    Emit('LTG ' + IntToStr(Ord(LResult)));
    PrintTop(LHandle);
  end
  else if LCommand = 'gsnbg' then
  begin
    LGoal := Default(TBotGoal);
    if Num(7) <> 0 then
      FGoal.GetTopGoal(LHandle, LGoal);
    if Num(7) <> 0 then
      LResult := FGoal.ChooseNBGItem(LHandle, VectorArg(2), Inventory(8), Num(5), @LGoal, FloatArg(6))
    else
      LResult := FGoal.ChooseNBGItem(LHandle, VectorArg(2), Inventory(8), Num(5), nil, FloatArg(6));
    Emit('NBG ' + IntToStr(Ord(LResult)));
    PrintTop(LHandle);
  end
  else if LCommand = 'gspush' then
  begin
    LGoal := GoalArg(2);
    LGoal.ItemInfo := Num(9);
    FGoal.PushGoal(LHandle, LGoal);
  end
  else if LCommand = 'gspop' then
    FGoal.PopGoal(LHandle)
  else if LCommand = 'gsempty' then
    FGoal.EmptyGoalStack(LHandle)
  else if LCommand = 'gstop' then
    PrintTop(LHandle)
  else if LCommand = 'gssecond' then
  begin
    LResult := FGoal.GetSecondGoal(LHandle, LGoal);
    Emit('SECOND ' + IntToStr(Ord(LResult)));
    if LResult then
      Emit(GoalText(' G', LGoal));
  end
  else if LCommand = 'gsdumpstack' then
    FGoal.DumpGoalStack(LHandle)
  else if LCommand = 'gsdumpavoid' then
    FGoal.DumpAvoidGoals(LHandle)
  else if LCommand = 'gsavoid' then
    Emit('AV' + FloatText('T', FGoal.AvoidGoalTime(LHandle, Num(2))))
  else if LCommand = 'gssetavoid' then
    FGoal.SetAvoidGoalTime(LHandle, Num(2), FloatArg(3))
  else if LCommand = 'gsremoveavoid' then
    FGoal.RemoveFromAvoidGoals(LHandle, Num(2))
  else if LCommand = 'gsresetavoid' then
    FGoal.ResetAvoidGoals(LHandle)
  else if LCommand = 'gsname' then
    Emit('NAME ' + EscapeBotText(FGoal.GoalName(LHandle, Num(2))))
  else if (LCommand = 'gstouch') or (LCommand = 'gsvis') then
  begin
    if not FGoal.GetTopGoal(LHandle, LGoal) then
    begin
      Emit('NOGOAL');
      Exit;
    end;
    if LCommand = 'gstouch' then
      Emit('TOUCH ' + IntToStr(Ord(FGoal.TouchingGoal(VectorArg(2), LGoal))))
    else
    begin
      LOrigin := Default(TVec3);
      Emit('VIS ' + IntToStr(Ord(FGoal.ItemGoalInVisButNotVisible(Num(2), VectorArg(3), LOrigin, LGoal))));
    end;
  end
  else if LCommand = 'gslevelgoal' then
  begin
    LGoal := Default(TBotGoal);
    LCode := FGoal.GetLevelItemGoal(LHandle, Arg(2), LGoal);
    Emit('LG ' + IntToStr(LCode));
    if LCode >= 0 then
      Emit(GoalText(' G', LGoal));
  end
  else if LCommand = 'gscamp' then
  begin
    LGoal := Default(TBotGoal);
    LCode := FGoal.GetNextCampSpotGoal(LHandle, LGoal);
    Emit('CAMP ' + IntToStr(LCode));
    if LCode <> 0 then
      Emit(GoalText(' G', LGoal));
  end
  else if LCommand = 'gsloc' then
  begin
    LGoal := Default(TBotGoal);
    LResult := FGoal.GetMapLocationGoal(Arg(1), LGoal);
    Emit('LOC ' + IntToStr(Ord(LResult)));
    if LResult then
      Emit(GoalText(' G', LGoal));
  end
  else if LCommand = 'gsbreed' then
    FGoal.InterbreedGoalFuzzyLogic(Num(1), Num(2), Num(3))
  else if LCommand = 'gsmutate' then
    FGoal.MutateGoalFuzzyLogic(LHandle, FloatArg(2))
  else if LCommand = 'mvsetup' then
  begin
    EnsureSystems;
    Emit('RC ' + IntToStr(FMove.Setup));
  end
  else if LCommand = 'mvalloc' then
  begin
    EnsureSystems;
    Emit('H ' + IntToStr(FMove.AllocMoveState));
  end
  else if LCommand = 'mvfree' then
    FMove.FreeMoveState(LHandle)
  else if LCommand = 'mvreset' then
    FMove.ResetMoveState(LHandle)
  else if LCommand = 'mvinit' then
  begin
    LInit := Default(TBotInitMove);
    LInit.Origin := VectorArg(2);
    LInit.Velocity := VectorArg(5);
    LInit.ViewOffset := VectorArg(8);
    LInit.EntityNum := Num(11);
    LInit.Client := Num(12);
    LInit.ThinkTime := FloatArg(13);
    LInit.PresenceType := Num(14);
    LInit.ViewAngles := VectorArg(15);
    LInit.OrMoveFlags := Num(18);
    FMove.InitMoveState(LHandle, LInit);
  end
  else if LCommand = 'mvavoidspot' then
    FMove.AddAvoidSpot(LHandle, VectorArg(2), FloatArg(5), Num(6))
  else if LCommand = 'mvresetavoid' then
    FMove.ResetAvoidReach(LHandle)
  else if LCommand = 'mvresetlast' then
    FMove.ResetLastAvoidReach(LHandle)
  else if LCommand = 'mvarea' then
  begin
    EnsureSystems;
    Emit('AREA ' + IntToStr(FMove.ReachabilityArea(VectorArg(1), Num(4))));
  end
  else if LCommand = 'mvfuzzy' then
  begin
    EnsureSystems;
    Emit('AREA ' + IntToStr(FMove.Locator.FuzzyPointReachabilityArea(VectorArg(1))));
  end
  else if LCommand = 'mvgoal' then
  begin
    if Arg(4) = 'null' then
      LMoveResult := FMove.MoveToGoal(LHandle, nil, Num(3))
    else
    begin
      LGoal := GoalArg(4);
      LMoveResult := FMove.MoveToGoal(LHandle, @LGoal, Num(3));
    end;
    Emit(ResultText('RES', LMoveResult));
    LInput := FActions.GetInput(Num(2), 0.1);
    Emit(InputText(' IN', LInput));
  end
  else if LCommand = 'mvdir' then
  begin
    LResult := FMove.MoveInDirection(LHandle, VectorArg(3), FloatArg(6), Num(7));
    Emit('DIR ' + IntToStr(Ord(LResult)));
    LInput := FActions.GetInput(Num(2), 0.1);
    Emit(InputText(' IN', LInput));
  end
  else if LCommand = 'mvview' then
  begin
    LGoal := GoalArg(4);
    LResult := FMove.MovementViewTarget(LHandle, @LGoal, Num(2), FloatArg(3), LTarget);
    LCount := Ord(LResult);
    Emit('VT ' + IntToStr(LCount) + VectorText('T', LTarget));
  end
  else if LCommand = 'mvpredict' then
  begin
    LGoal := GoalArg(6);
    LTarget := Default(TVec3);
    LResult := FMove.PredictVisiblePosition(VectorArg(1), Num(4), @LGoal, Num(5), LTarget);
    Emit('PV ' + IntToStr(Ord(LResult)) + VectorText('T', LTarget));
  end
  else if LCommand = 'mvsim' then
  begin
    LGoal2 := GoalArg(9);
    LOrigin := VectorArg(5);
    RunSimulation(LHandle, Num(2), Num(3), FloatArg(4), LOrigin, Num(8), LGoal2);
  end
  else
    Emit('unknown command ' + string(LCommand));
end;

procedure TGoalMoveScenario.Run(const AScenario: TStrings);
var
  LLine: string;
  LAnsi: AnsiString;
  LParts: TArray<AnsiString>;
  LMask: TArithmeticExceptionMask;
  LStart: Integer;
  LIndex: Integer;
  LRead: Integer;
  LText: AnsiString;
  LUnescaped: AnsiString;
  LHex: string;
begin
  // the C code divides in IEEE arithmetic: the exceptions are masked, as in the engine
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    for LLine in AScenario do
    begin
      LAnsi := AnsiString(LLine);
      if (LAnsi = '') or (LAnsi[1] = '#') then
        Continue;
      Emit('>' + LLine);
      // split at the bars, then unescape every argument as the C tool does
      LParts := nil;
      LStart := 1;
      for LIndex := 1 to Length(LAnsi) + 1 do
      begin
        if (LIndex > Length(LAnsi)) or (LAnsi[LIndex] = '|') then
        begin
          LText := Copy(LAnsi, LStart, LIndex - LStart);
          LUnescaped := '';
          LRead := 1;
          while LRead <= Length(LText) do
          begin
            if (LText[LRead] = '\') and (LRead < Length(LText)) then
            begin
              Inc(LRead);
              case LText[LRead] of
                't': LUnescaped := LUnescaped + #9;
                'n': LUnescaped := LUnescaped + #10;
                'r': LUnescaped := LUnescaped + #13;
                '\': LUnescaped := LUnescaped + '\';
                'x':
                  if LRead + 2 <= Length(LText) then
                  begin
                    LHex := string(Copy(LText, LRead + 1, 2));
                    LUnescaped := LUnescaped + AnsiChar(StrToInt('$' + LHex));
                    Inc(LRead, 2);
                  end
                  else
                    LUnescaped := LUnescaped + LText[LRead];
              else
                LUnescaped := LUnescaped + LText[LRead];
              end;
              Inc(LRead);
            end
            else
            begin
              LUnescaped := LUnescaped + LText[LRead];
              Inc(LRead);
            end;
          end;
          SetLength(LParts, Length(LParts) + 1);
          LParts[High(LParts)] := LUnescaped;
          LStart := LIndex + 1;
        end;
      end;
      FArgs := LParts;
      try
        Execute(LAnsi);
      except
        on E: Exception do
        begin
          // the line that failed is part of the message of the test
          raise Exception.Create('Scenario line "' + LLine + '": ' + E.ClassName + ': ' + E.Message);
        end;
      end;
    end;
    Flush;
  finally
    SetExceptionMask(LMask);
  end;
end;

end.
