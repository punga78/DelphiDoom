{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the scenario of the reachability     }
{  golden                                                                      }
{                                                                              }
{  The twin of Tools\Verifica\122\reach\reachgen.c: the reachabilities of the  }
{  file are thrown away and calculated again, and the lines are the same as    }
{  those of the C tool. The BSP of the game is replaced by the twins of the    }
{  C tool: the contents and the trace come from the AAS (TTwinBspWorld), the   }
{  entities and the bounds of the models from the .bsp file (TTwinBspModels).  }
{  What is proven is the logic of be_aas_reach.c.                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Reach.Scenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types;

type
  /// <summary>The models and the entities of a .bsp file: the lumps 7 and 0, the bounds are spread by one unit (cm_load.c)</summary>
  TTwinBspModels = class(TInterfacedObject, IAasBspModels)
  strict private
    FEntityText: AnsiString;
    FMins, FMaxs: TArray<TVec3>;
  public
    constructor Create(const ABsp: TBytes);
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
    function ModelCount: Integer;
  end;

  /// <summary>Runs the scenario on one AAS file with its BSP and writes the lines of the C tool</summary>
  TAasReachScenario = class
  strict private
    FOutput: TStrings;
    FFull: Boolean;
    FGrapple: Boolean;
  public
    /// <summary>AFull: every reachability (else a hash per area and the lines of the first area of each travel type)</summary>
    constructor Create(const AOutput: TStrings; const AFull, AGrapple: Boolean);
    procedure Run(const AName: string; const AAas, ABsp: TBytes);
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Factory, DelphiDoom.Aas.Links,
  DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Move.Movement, DelphiDoom.Aas.Move.Settings, DelphiDoom.Aas.Reach.Types,
  DelphiDoom.Aas.Reach.Intf,
  DelphiDoom.Aas.Reach.Factory, DelphiDoom.Aas.Reach.Format, DelphiDoom.Tests.Aas.Support,
  DelphiDoom.Tests.Aas.Move.Scenario;

type
  /// <summary>The import of the C tool: the percentage lines (they begin with a carriage return) are only counted and hashed</summary>
  TReachImport = class(TInterfacedObject, IBotImport)
  strict private
    FOutput: TStrings;
    FPercentCount: Cardinal;
    FPercentHash: Cardinal;
  public
    constructor Create(const AOutput: TStrings);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
    procedure ResetPercent;
    property PercentCount: Cardinal read FPercentCount;
    property PercentHash: Cardinal read FPercentHash;
  end;

  /// <summary>The library variables of the tool: the defaults of the physics, grapplereach as given</summary>
  TReachLibVars = class(TInterfacedObject, IBotLibVars)
  strict private
    FGrapple: Boolean;
    FDefaults: IBotLibVars;
  public
    constructor Create(const AGrapple: Boolean);
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

{ TReachImport }

constructor TReachImport.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
  ResetPercent;
end;

procedure TReachImport.ResetPercent;
begin
  FPercentCount := 0;
  FPercentHash := 2166136261;
end;

procedure TReachImport.Print(const ALevel: Integer; const AMessage: AnsiString);
var
  LIndex: Integer;
begin
  if (Length(AMessage) > 0) and (AMessage[1] = #13) then
  begin
    Inc(FPercentCount);
    for LIndex := 1 to Length(AMessage) do
      FPercentHash := (FPercentHash xor Byte(AMessage[LIndex])) * 16777619;
    Exit;
  end;
  FOutput.Add(Format('P%d|%s', [ALevel, Escaped(string(AMessage))]));
end;

procedure TReachImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TReachImport.Time: Single;
begin
  Result := 0;
end;

procedure TReachImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

{ TReachLibVars }

constructor TReachLibVars.Create(const AGrapple: Boolean);
begin
  inherited Create;
  FGrapple := AGrapple;
  FDefaults := TDefaultLibVars.Create;
end;

function TReachLibVars.GetValue(const AName: AnsiString): Single;
begin
  Result := 0;
  if (AName = 'grapplereach') and FGrapple then
    Result := 1;
end;

function TReachLibVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := FDefaults.GetValueOrCreate(AName, ADefault);
end;

function TReachLibVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := ADefault;
end;

{ TTwinBspModels }

constructor TTwinBspModels.Create(const ABsp: TBytes);
var
  LOffset, LLength, LCount, LIndex, LAxis: Integer;
  LValue: Single;
begin
  inherited Create;
  if Length(ABsp) < 8 + 17 * 8 then
    Exit;
  Move(ABsp[8], LOffset, 4);
  Move(ABsp[12], LLength, 4);
  SetLength(FEntityText, LLength);
  if LLength > 0 then
    Move(ABsp[LOffset], FEntityText[1], LLength);
  Move(ABsp[8 + 7 * 8], LOffset, 4);
  Move(ABsp[8 + 7 * 8 + 4], LLength, 4);
  LCount := LLength div 40;
  if LCount > 1024 then
    LCount := 1024;
  SetLength(FMins, LCount);
  SetLength(FMaxs, LCount);
  for LIndex := 0 to LCount - 1 do
    for LAxis := 0 to 2 do
    begin
      Move(ABsp[LOffset + LIndex * 40 + LAxis * 4], LValue, 4);
      FMins[LIndex][LAxis] := LValue - 1;
      Move(ABsp[LOffset + LIndex * 40 + 12 + LAxis * 4], LValue, 4);
      FMaxs[LIndex][LAxis] := LValue + 1;
    end;
end;

function TTwinBspModels.EntityData: AnsiString;
begin
  Result := FEntityText;
end;

function TTwinBspModels.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
  AContentMask: Integer): TAasBspTrace;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Fraction := 1;
  Result.EndPos := AEnd;
  Result.EntityNum := -1;
end;

function TTwinBspModels.InPVS(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := True;
end;

procedure TTwinBspModels.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs,
  AOrigin: TVec3);
begin
  FillChar(AMins, SizeOf(AMins), 0);
  FillChar(AMaxs, SizeOf(AMaxs), 0);
  FillChar(AOrigin, SizeOf(AOrigin), 0);
  // a model that is not in the file has empty bounds
  if (AModelNum >= 0) and (AModelNum < Length(FMins)) then
  begin
    AMins := FMins[AModelNum];
    AMaxs := FMaxs[AModelNum];
  end;
end;

function TTwinBspModels.ModelCount: Integer;
begin
  Result := Length(FMins);
end;

{ TAasReachScenario }

constructor TAasReachScenario.Create(const AOutput: TStrings; const AFull, AGrapple: Boolean);
begin
  inherited Create;
  FOutput := AOutput;
  FFull := AFull;
  FGrapple := AGrapple;
end;

procedure TAasReachScenario.Run(const AName: string; const AAas, ABsp: TBytes);
var
  LHeader: TAasFileHeader;
  LImport: TReachImport;
  LImportIntf: IBotImport;
  LFile: IAasFile;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LWorld: IAasBspWorld;
  LLibVars: IBotLibVars;
  LMovement: IAasMovement;
  LModelsObject: TTwinBspModels;
  LModels: IAasBspModels;
  LEntities: IAasBspEntities;
  LLinks: TAasEntityLinks;
  LInit: IAasReachInitializer;
  LEditor: IAasReachabilityEditor;
  LSettings: TArray<TAasAreaSettings>;
  LSeen: array[0..MAX_TRAVELTYPES - 1] of Boolean;
  LIndex, LK, LAreas, LCalls, LType: Integer;
  LCounters: TAasReachCounters;
  LHash: Cardinal;
  LNewType: Boolean;
  LReach: TAasReachability;
  LLine: string;

  function Mix(const AHash, AValue: Cardinal): Cardinal;
  var
    LByte: Integer;
  begin
    Result := AHash;
    for LByte := 0 to 3 do
      Result := (Result xor ((AValue shr (8 * LByte)) and 255)) * 16777619;
  end;

  function ReachLine(const AArea, AIndex: Integer; const AReach: TAasReachability): string;
  begin
    Result := Format('R %d %d %d %d %d S #%s #%s #%s E #%s #%s #%s %d %d', [AArea, AIndex, AReach.AreaNum,
      AReach.FaceNum, AReach.EdgeNum, Hex(Bits(AReach.StartPoint[0])), Hex(Bits(AReach.StartPoint[1])),
      Hex(Bits(AReach.StartPoint[2])), Hex(Bits(AReach.EndPoint[0])), Hex(Bits(AReach.EndPoint[1])),
      Hex(Bits(AReach.EndPoint[2])), AReach.TravelType, Integer(AReach.TravelTime)]);
  end;

begin
  FOutput.Add('FILE ' + AName);
  Move(AAas[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  LImport := TReachImport.Create(FOutput);
  LImportIntf := LImport;
  LFile := TAasFactory.CreateReader(LImportIntf, nil, nil).ParseBytes(AAas, 'maps/reach.aas', LHeader.BspChecksum);
  FOutput.Add('LOAD 0');
  LAreas := Length(LFile.Areas);
  FOutput.Add(Format('AAS %d %d', [LAreas, Length(LFile.Reachability)]));
  FOutput.Add(Format('GEO %d %d %d %d', [Length(LFile.Faces), Length(LFile.Edges), Length(LFile.Vertexes),
    Length(LFile.FaceIndex)]));
  if LAreas < 3 then
    Exit;
  LModelsObject := TTwinBspModels.Create(ABsp);
  LModels := LModelsObject;
  LEntities := TAasReachFactory.CreateEntities(LImportIntf, LModels);
  FOutput.Add(Format('BSP %d %d', [LEntities.Count - 1, LModelsObject.ModelCount]));
  // the reachabilities of the file are thrown away
  Supports(LFile, IAasReachabilityEditor, LEditor);
  LEditor.ReplaceReachability(nil);
  LSettings := LFile.AreaSettings;
  for LIndex := 0 to LAreas - 1 do
  begin
    LSettings[LIndex].NumReachableAreas := 0;
    LSettings[LIndex].FirstReachableArea := 0;
  end;
  LSampler := TAasFactory.CreateSampler(LFile, LImportIntf, True);
  LTracer := TAasFactory.CreateTracer(LFile, LImportIntf);
  LWorld := TTwinBspWorld.Create(LFile, LSampler, LTracer);
  LLibVars := TReachLibVars.Create(FGrapple);
  LMovement := TAasMovement.Create(LFile, LSampler, LTracer, TAasFactory.CreateFaceTester(LFile, LImportIntf), LWorld,
    LImportIntf, TAasMoveSettingsReader.Read(LLibVars));
  LLinks := TAasEntityLinks.Create(LFile, LImportIntf, AAS_DEFAULT_MAX_LINKS, True);
  try
    LInit := TAasReachFactory.CreateInitializer(LFile, LSampler, LTracer, TAasFactory.CreateFaceTester(LFile, LImportIntf),
      LMovement, LWorld, LModels, LEntities, LLinks, LImportIntf, LLibVars);
    LImport.ResetPercent;
    LInit.InitReachability;
    LCalls := 0;
    while LInit.ContinueInitReachability(0) do
      Inc(LCalls);
    FOutput.Add(Format('CALLS %d', [LCalls]));
    FOutput.Add(Format('PCT %u %u', [LImport.PercentCount, LImport.PercentHash]));
    LCounters := LInit.Counters;
    FOutput.Add(Format('CT %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d', [LCounters.Swim,
      LCounters.EqualFloor, LCounters.Step, LCounters.Walk, LCounters.Barrier, LCounters.WaterJump,
      LCounters.WalkOffLedge, LCounters.Jump, LCounters.Ladder, LCounters.Teleport, LCounters.Elevator,
      LCounters.FuncBob, LCounters.Grapple, LCounters.DoubleJump, LCounters.RampJump, LCounters.StrafeJump,
      LCounters.RocketJump, LCounters.BfgJump, LCounters.JumpPad]));
    FOutput.Add(Format('RS %d %d', [Length(LFile.Reachability), LInit.NumReachabilityAreas]));
    FillChar(LSeen, SizeOf(LSeen), 0);
    LSettings := LFile.AreaSettings;
    for LIndex := 0 to LAreas - 1 do
    begin
      LHash := 2166136261;
      LNewType := False;
      for LK := 0 to LSettings[LIndex].NumReachableAreas - 1 do
      begin
        LReach := LFile.Reachability[LSettings[LIndex].FirstReachableArea + LK];
        LType := LReach.TravelType and TRAVELTYPE_MASK;
        LHash := Mix(LHash, Cardinal(LReach.AreaNum));
        LHash := Mix(LHash, Cardinal(LReach.FaceNum));
        LHash := Mix(LHash, Cardinal(LReach.EdgeNum));
        LHash := Mix(LHash, Bits(LReach.StartPoint[0]));
        LHash := Mix(LHash, Bits(LReach.StartPoint[1]));
        LHash := Mix(LHash, Bits(LReach.StartPoint[2]));
        LHash := Mix(LHash, Bits(LReach.EndPoint[0]));
        LHash := Mix(LHash, Bits(LReach.EndPoint[1]));
        LHash := Mix(LHash, Bits(LReach.EndPoint[2]));
        LHash := Mix(LHash, Cardinal(LReach.TravelType));
        LHash := Mix(LHash, LReach.TravelTime);
        if (LType >= 0) and (LType < MAX_TRAVELTYPES) and not LSeen[LType] then
        begin
          LSeen[LType] := True;
          LNewType := True;
        end;
      end;
      LLine := Format('A %d %d %d %u', [LIndex, LSettings[LIndex].NumReachableAreas, LSettings[LIndex].AreaFlags, LHash]);
      FOutput.Add(LLine);
      if FFull or LNewType then
        for LK := 0 to LSettings[LIndex].NumReachableAreas - 1 do
          FOutput.Add(ReachLine(LIndex, LK, LFile.Reachability[LSettings[LIndex].FirstReachableArea + LK]));
    end;
  finally
    LInit := nil;
    LLinks.Free;
  end;
end;

end.
