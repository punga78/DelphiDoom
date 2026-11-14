{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the scenario of the movement golden  }
{                                                                              }
{  The twin of the part "move" of Tools\Verifica\122\route\routegen.c.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Move.Scenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf;

type
  /// <summary>The world of the bots that the C tool has: the contents of a point are those of its area</summary>
  TTwinBspWorld = class(TInterfacedObject, IAasBspWorld)
  strict private
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
  public
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer);
    function PointContents(const APoint: TVec3): Integer;
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
  end;

  /// <summary>The library variables: the default of every variable, as LibVarValue of the C tool (atof)</summary>
  TDefaultLibVars = class(TInterfacedObject, IBotLibVars)
  public
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

  /// <summary>Runs the scenario on one AAS file and writes the lines of the C tool</summary>
  TAasMoveScenario = class
  strict private
    FOutput: TStrings;
    FSeed: Cardinal;
    FFile: IAasFile;
    FMovement: IAasMovement;
    FTracerForTrace: IAasTracer;
    function Rnd: Cardinal;
    function RF(const ARange: Integer): Single;
    function Vector(const ATag: string; const AValue: TVec3): string;
    function TraceLine(const ATag: string; const ATrace: TAasTrace): string;
    function MoveLine(const ATag: string; const AMove: TAasClientMove): string;
    procedure Pure;
    procedure WorldFunctions(const ASampler: IAasSampler);
    procedure Predictions;
  public
    constructor Create(const AOutput: TStrings);
    procedure Run(const AName: string; const ABytes: TBytes);
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Factory, DelphiDoom.Aas.VectorMath,
  DelphiDoom.Aas.Move.Movement, DelphiDoom.Aas.Move.Settings, DelphiDoom.Tests.Aas.Support;

type
  TScenarioImport = class(TInterfacedObject, IBotImport)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

constructor TScenarioImport.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FOutput.Add(Format('P%d|%s', [ALevel, Escaped(string(AMessage))]));
end;

procedure TScenarioImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TScenarioImport.Time: Single;
begin
  Result := 0;
end;

procedure TScenarioImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

{ TTwinBspWorld }

constructor TTwinBspWorld.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer);
begin
  inherited Create;
  FFile := AFile;
  FSampler := ASampler;
  FTracer := ATracer;
end;

function TTwinBspWorld.PointContents(const APoint: TVec3): Integer;
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

function TTwinBspWorld.Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
  AContentMask: Integer): TAasBspTrace;
var
  LTrace: TAasTrace;
begin
  LTrace := FTracer.TraceClientBBox(AStart, AEnd, PRESENCE_NORMAL, -1);
  FillChar(Result, SizeOf(Result), 0);
  Result.StartSolid := LTrace.StartSolid;
  Result.Fraction := LTrace.Fraction;
  Result.EndPos := LTrace.EndPos;
end;

{ TDefaultLibVars }

function TDefaultLibVars.GetValue(const AName: AnsiString): Single;
begin
  Result := 0;
end;

function TDefaultLibVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
var
  LDouble: Double;
begin
  // atof gives a double, the float is made from it
  LDouble := StrToFloat(string(ADefault), TFormatSettings.Invariant);
  Result := LDouble;
end;

function TDefaultLibVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := ADefault;
end;

{ TAasMoveScenario }

constructor TAasMoveScenario.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

function TAasMoveScenario.Rnd: Cardinal;
begin
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TAasMoveScenario.RF(const ARange: Integer): Single;
var
  LInteger: Integer;
begin
  LInteger := Integer(Rnd mod Cardinal(2 * ARange * 8 + 1)) - ARange * 8;
  Result := LInteger / 8.0;
end;

function TAasMoveScenario.Vector(const ATag: string; const AValue: TVec3): string;
begin
  Result := Format(' %s #%s #%s #%s', [ATag, Hex(Bits(AValue[0])), Hex(Bits(AValue[1])), Hex(Bits(AValue[2]))]);
end;

function TAasMoveScenario.TraceLine(const ATag: string; const ATrace: TAasTrace): string;
begin
  Result := Format('%s %d #%s', [ATag, Ord(ATrace.StartSolid), Hex(Bits(ATrace.Fraction))]) +
    Vector('E', ATrace.EndPos) + Format(' %d %d %d %d', [ATrace.Ent, ATrace.LastArea, ATrace.Area, ATrace.PlaneNum]);
end;

function TAasMoveScenario.MoveLine(const ATag: string; const AMove: TAasClientMove): string;
begin
  Result := ATag + Vector('P', AMove.EndPos) + Vector('V', AMove.Velocity) +
    Format(' %d %d %d %d #%s %d', [AMove.EndArea, AMove.PresenceType, AMove.StopEvent, AMove.EndContents,
    Hex(Bits(AMove.Time)), AMove.Frames]) +
    Format(' TR %d #%s', [Ord(AMove.Trace.StartSolid), Hex(Bits(AMove.Trace.Fraction))]) +
    Vector('TE', AMove.Trace.EndPos) + Format(' %d %d %d %d', [AMove.Trace.Ent, AMove.Trace.LastArea,
    AMove.Trace.Area, AMove.Trace.PlaneNum]);
end;

procedure TAasMoveScenario.Pure;
var
  LIndex, LResult: Integer;
  LV, LW, LU, LS, LE, LMins, LMaxs: TVec3;
  LWishSpeed, LAccel, LFrameTime, LFriction, LZVel, LVel: Single;
  LStopSpeed: Single;
  LTrace: TAasTrace;
  LAngles, LDir: TVec3;
  LPresence: Integer;
begin
  LStopSpeed := 100;
  for LIndex := 0 to 39 do
  begin
    LV[0] := RF(40);
    LV[1] := RF(40);
    LV[2] := RF(40);
    LW[0] := RF(2);
    LW[1] := RF(2);
    LW[2] := RF(2);
    TAasVectorMath.Normalize(LW);
    LWishSpeed := Rnd mod 64;
    LWishSpeed := LWishSpeed * 8;
    LAccel := Rnd mod 20;
    LAccel := LAccel + 1;
    LFrameTime := 0.0500000007450580596923828125;
    LFrameTime := LFrameTime * (1 + Rnd mod 4);
    TAasMovement.Accelerate(LV, LFrameTime, LW, LWishSpeed, LAccel);
    FOutput.Add(Format('AC %d', [LIndex]) + Vector('V', LV));
    LFriction := Rnd mod 10 + 1;
    LU[0] := RF(40);
    LU[1] := RF(40);
    LU[2] := RF(40);
    TAasMovement.ApplyFriction(LU, LFriction, LStopSpeed, LFrameTime);
    FOutput.Add(Format('FR %d', [LIndex]) + Vector('V', LU));
  end;
  for LIndex := 0 to 39 do
  begin
    LVel := -1;
    LZVel := 270 + RF(40);
    LS[0] := RF(100);
    LS[1] := RF(100);
    LS[2] := RF(100);
    LE[0] := RF(100);
    LE[1] := RF(100);
    LE[2] := RF(100);
    LResult := Ord(FMovement.HorizontalVelocityForJump(LZVel, LS, LE, LVel));
    FOutput.Add(Format('HV %d %d #%s', [LIndex, LResult, Hex(Bits(LVel))]));
  end;
  for LIndex := 0 to 39 do
  begin
    FillChar(LTrace, SizeOf(LTrace), 0);
    LS[0] := RF(100);
    LS[1] := RF(100);
    LS[2] := RF(100);
    LE[0] := RF(100);
    LE[1] := RF(100);
    LE[2] := RF(100);
    LMins[0] := RF(60);
    LMins[1] := RF(60);
    LMins[2] := RF(60);
    LMaxs[0] := LMins[0] + (Rnd mod 64 + 1);
    LMaxs[1] := LMins[1] + (Rnd mod 64 + 1);
    LMaxs[2] := LMins[2] + (Rnd mod 64 + 1);
    if (Rnd and 1) <> 0 then
      LPresence := PRESENCE_NORMAL
    else
      LPresence := PRESENCE_CROUCH;
    LResult := Ord(FMovement.ClipToBBox(LTrace, LS, LE, LPresence, LMins, LMaxs));
    FOutput.Add(Format('CB %d %d', [LIndex, LResult]) + TraceLine(' T', LTrace));
  end;
  for LIndex := 0 to 7 do
  begin
    if LIndex = 0 then
    begin
      LAngles[0] := 0;
      LAngles[1] := -1;
      LAngles[2] := 0;
    end
    else if LIndex = 1 then
    begin
      LAngles[0] := 0;
      LAngles[1] := -2;
      LAngles[2] := 0;
    end
    else
    begin
      LAngles[0] := RF(180);
      LAngles[1] := RF(180);
      LAngles[2] := RF(180);
    end;
    FMovement.SetMovedir(LAngles, LDir);
    FOutput.Add(Format('MD %d', [LIndex]) + Vector('D', LDir));
  end;
end;

procedure TAasMoveScenario.WorldFunctions(const ASampler: IAasSampler);
var
  LIndex, LArea, LResult, N: Integer;
  LOrg, LMins, LMaxs, LRunStart: TVec3;
  LReach: TAasReachability;
begin
  N := Length(FFile.Areas);
  for LIndex := 0 to 39 do
  begin
    LArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOrg := FFile.Areas[LArea].Center;
    FOutput.Add(Format('WO %d %d %d %d %d', [LIndex, LArea, Ord(FMovement.Swimming(LOrg)),
      Ord(FMovement.OnGround(LOrg, PRESENCE_NORMAL, -1)), Ord(FMovement.AgainstLadder(LOrg))]));
  end;
  for LIndex := 0 to 9 do
  begin
    LArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOrg := FFile.Areas[LArea].Center;
    LMins[0] := -15;
    LMins[1] := -15;
    LMins[2] := -24;
    LMaxs[0] := 15;
    LMaxs[1] := 15;
    LMaxs[2] := 32;
    LResult := Ord(FMovement.DropToFloor(LOrg, LMins, LMaxs));
    FOutput.Add(Format('DF %d %d %d', [LIndex, LArea, LResult]) + Vector('O', LOrg) +
      Format(' #%s #%s', [Hex(Bits(FMovement.RocketJumpZVelocity(LOrg))), Hex(Bits(FMovement.BFGJumpZVelocity(LOrg)))]));
  end;
  for LIndex := 0 to 9 do
  begin
    if Length(FFile.Reachability) > 0 then
      LResult := Integer(Rnd mod Cardinal(Length(FFile.Reachability)))
    else
      LResult := 0;
    LReach := FFile.Reachability[LResult];
    FMovement.JumpReachRunStart(LReach, LRunStart);
    FOutput.Add(Format('JR %d %d', [LIndex, LResult]) + Vector('R', LRunStart));
  end;
end;

procedure TAasMoveScenario.Predictions;
const
  EVENTS: array[0..7] of Integer = (SE_NONE, SE_HITGROUND, SE_LEAVEGROUND or SE_GAP,
    SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA, SE_HITGROUNDDAMAGE,
    SE_ENTERAREA or SE_TOUCHJUMPPAD or SE_TOUCHTELEPORTER or SE_TOUCHCLUSTERPORTAL, SE_HITGROUNDAREA,
    SE_HITGROUND or SE_HITGROUNDDAMAGE or SE_LEAVEGROUND);
  CMDZ: array[0..3] of Single = (0, 224, -400, 10);
var
  LIndex, LArea, LB, LPresence, LCmdFrames, LMaxFrames, LStopEvent, LStopArea, LCode, N: Integer;
  LOnGround: Boolean;
  LOrg, LVel, LCmd, LMins, LMaxs, LC: TVec3;
  LFrameTime: Single;
  LMove: TAasClientMove;
  LTraceTb: TAasTrace;
begin
  N := Length(FFile.Areas);
  for LIndex := 0 to 119 do
  begin
    LArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOrg := FFile.Areas[LArea].Center;
    LVel[0] := RF(40);
    LVel[1] := RF(40);
    LVel[2] := RF(20);
    LCmd[0] := RF(50);
    LCmd[1] := RF(50);
    LCmd[2] := CMDZ[Rnd mod 4];
    LCmdFrames := Rnd mod 6;
    LMaxFrames := 5 + Integer(Rnd mod 20);
    case LIndex mod 3 of
      0: LFrameTime := 0;
      1: LFrameTime := 0.100000001490116119384765625;
    else
      LFrameTime := 0.0500000007450580596923828125;
    end;
    LStopEvent := EVENTS[Rnd mod 8];
    LStopArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOnGround := (Rnd and 1) <> 0;
    if (Rnd and 1) <> 0 then
      LPresence := PRESENCE_NORMAL
    else
      LPresence := PRESENCE_CROUCH;
    FOutput.Add(Format('PI %d', [LIndex]) + Vector('O', LOrg) + Vector('V', LVel) + Vector('C', LCmd) + Format(' %d %d %d %d #%s %d', [LCmdFrames, LMaxFrames, LPresence, Ord(LOnGround), Hex(Bits(LFrameTime)), LStopArea]));
    LCode := Ord(FMovement.PredictClientMovement(LMove, -1, LOrg, LPresence, LOnGround, LVel, LCmd, LCmdFrames,
      LMaxFrames, LFrameTime, LStopEvent, LStopArea, False));
    FOutput.Add(Format('PM %d %d %d %d', [LIndex, LArea, LCode, LStopEvent]) + MoveLine(' M', LMove));
  end;
  for LIndex := 0 to 11 do
  begin
    LArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LB := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOrg := FFile.Areas[LArea].Center;
    LC := FFile.Areas[LB].Center;
    LMins[0] := LC[0] - 20;
    LMins[1] := LC[1] - 20;
    LMins[2] := LC[2] - 20;
    LMaxs[0] := LC[0] + 20;
    LMaxs[1] := LC[1] + 20;
    LMaxs[2] := LC[2] + 20;
    LVel[0] := RF(40);
    LVel[1] := RF(40);
    LVel[2] := 0;
    LCmd[0] := RF(50);
    LCmd[1] := RF(50);
    LCmd[2] := 0;
    LCode := Ord(FMovement.ClientMovementHitBBox(LMove, -1, LOrg, PRESENCE_NORMAL, True, LVel, LCmd, 20, 30,
      0.100000001490116119384765625, LMins, LMaxs, False));
    FOutput.Add(Format('HB %d %d %d %d', [LIndex, LArea, LB, LCode]) + MoveLine(' M', LMove));
  end;
  for LIndex := 0 to 149 do
  begin
    LArea := 1 + Integer(Rnd mod Cardinal(N - 1));
    LOrg := FFile.Areas[LArea].Center;
    LOrg[0] := LOrg[0] + RF(8);
    LOrg[1] := LOrg[1] + RF(8);
    LOrg[2] := LOrg[2] + RF(8);
    LC[0] := LOrg[0] + RF(100);
    LC[1] := LOrg[1] + RF(100);
    LC[2] := LOrg[2] + RF(100);
    if (Rnd and 1) <> 0 then
      LPresence := PRESENCE_NORMAL
    else
      LPresence := PRESENCE_CROUCH;
    LTraceTb := FTracerForTrace.TraceClientBBox(LOrg, LC, LPresence, -1);
    FOutput.Add(Format('TB %d %d %d', [LIndex, LArea, LPresence]) + TraceLine(' T', LTraceTb));
  end;
end;

procedure TAasMoveScenario.Run(const AName: string; const ABytes: TBytes);
var
  LHeader: TAasFileHeader;
  LImport: IBotImport;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LWorld: IAasBspWorld;
  LLibVars: IBotLibVars;
  LMask: TArithmeticExceptionMask;
begin
  // the C code divides in IEEE arithmetic: the exceptions are masked, as in the engine
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
  FOutput.Add('FILE ' + AName);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  LImport := TScenarioImport.Create(FOutput);
  FFile := TAasFactory.CreateReader(LImport, nil, nil).ParseBytes(ABytes, 'maps/routing.aas', LHeader.BspChecksum);
  FOutput.Add('LOAD 0');
  LSampler := TAasFactory.CreateSampler(FFile, LImport, True);
  LTracer := TAasFactory.CreateTracer(FFile, LImport);
  FTracerForTrace := LTracer;
  LWorld := TTwinBspWorld.Create(FFile, LSampler, LTracer);
  LLibVars := TDefaultLibVars.Create;
  FMovement := TAasMovement.Create(FFile, LSampler, LTracer, TAasFactory.CreateFaceTester(FFile, LImport), LWorld,
    LImport, TAasMoveSettingsReader.Read(LLibVars));
  FOutput.Add(Format('AAS %d', [Length(FFile.Areas)]));
  if Length(FFile.Areas) < 3 then
    Exit;
  FSeed := 2463534242;
  Pure;
  WorldFunctions(LSampler);
  Predictions;
  FMovement := nil;
  finally
    SetExceptionMask(LMask);
  end;
end;

end.
