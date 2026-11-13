{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the particle and fx declarations - parity with the     }
{  real C++                                                                    }
{                                                                              }
{  Runs Tests\Data\Decl\effects.input.txt with TDeclParticle, TDeclFx and      }
{  TDeclTable and compares the output with effects.golden.txt, which is what   }
{  the real DeclParticle.cpp, DeclFX.cpp and DeclTable.cpp of Doom 3 printed   }
{  for the same file (see Tests\Data\Decl\README.md).                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.EffectsGolden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Decl.Intf,
  DelphiDoom.Tests.Decl.EffectsSupport;

type
  /// <summary>
  ///   The interpreter of the cases: the same operations and output lines as the driver of the C++ harness
  ///   (<c>@decl</c>, <c>@op gen</c>, <c>save</c>, <c>print</c>, <c>list</c>, <c>custom</c>)
  /// </summary>
  TEffectsGoldenRunner = class
  strict private
    FLines: TStringList;
    FLog: IInterface;
    FFinder: TFakeDeclFinder;
    FFinderIntf: IDeclFinder;
    FObjects: TDictionary<string, IDecl>;
    FObjectTypes: TDictionary<string, string>;
    procedure Emit(const ALine: string);
    class function Bits(const AValue: Single): string; static;
    class function BitsList(const AValues: array of Single): string; static;
    class function Words(const AText: string): TArray<string>; static;
    procedure DropIntegrateMessages(const AFromLine: Integer; out AFound: Boolean);
    procedure FlushDeclaration(const AType, AName, AText: string);
    procedure DumpParticle(const ADecl: IDecl);
    procedure DumpFx(const ADecl: IDecl);
    procedure DumpTable(const ADecl: IDecl; const AName: string);
    procedure OperationGen(const AWords: TArray<string>);
    procedure OperationCustom;
    procedure Execute(const AOperation: string);
    procedure StartCase;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs every case of the text and returns the output lines</summary>
    function RunAll(const AInput: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclEffectsGolden = class
  strict private
    function DataFolder: string;
    /// <summary>
    ///   Two lines are the same if everything but the floats is, and the floats (the 8 hex digits of their bits) differ
    ///   by at most <c>FLOAT_TOLERANCE</c> of the larger of 1 and their size: the C++ of the reference was built for the
    ///   x87 (extended intermediates), the port keeps each step in a Single
    /// </summary>
    function LinesMatch(const AExpected, AActual: string): Boolean;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroDeclParticleEDeclFx;
  end;

implementation

uses
  System.Math, System.RegularExpressions, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Random,
  DelphiDoom.MathCore.Float.Angles, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Conversions,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Table,
  DelphiDoom.Decl.Particle, DelphiDoom.Decl.Particle.Types, DelphiDoom.Decl.Particle.Intf,
  DelphiDoom.Decl.Particle.Generator, DelphiDoom.Decl.Fx, DelphiDoom.Decl.Fx.Types, DelphiDoom.Decl.Fx.Intf,
  DelphiDoom.Tests.Scanner.IdFakes;

{ TEffectsGoldenRunner }

constructor TEffectsGoldenRunner.Create;
begin
  inherited Create;
  FObjects := TDictionary<string, IDecl>.Create;
  FObjectTypes := TDictionary<string, string>.Create;
end;

destructor TEffectsGoldenRunner.Destroy;
begin
  FObjectTypes.Free;
  FObjects.Free;
  inherited Destroy;
end;

procedure TEffectsGoldenRunner.Emit(const ALine: string);
begin
  FLines.Add(ALine);
end;

class function TEffectsGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

class function TEffectsGoldenRunner.BitsList(const AValues: array of Single): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + Bits(AValues[LIndex]);
  end;
end;

class function TEffectsGoldenRunner.Words(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(AText);
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := LList[LIndex];
  finally
    LList.Free;
  end;
end;

// The C++ harness counts the messages of idParticleParm::Integrate instead of writing them (the original
// writes one per sample, the port one per pass); here they are taken out of the output
procedure TEffectsGoldenRunner.DropIntegrateMessages(const AFromLine: Integer; out AFound: Boolean);
var
  LIndex: Integer;
begin
  AFound := False;
  for LIndex := FLines.Count - 1 downto AFromLine do
    if Pos('idParticleParm::Integrate', FLines[LIndex]) > 0 then
    begin
      AFound := True;
      FLines.Delete(LIndex);
    end;
end;

procedure TEffectsGoldenRunner.StartCase;
begin
  FObjects.Clear;
  FObjectTypes.Clear;
  FFinder.Clear;
end;

procedure TEffectsGoldenRunner.DumpTable(const ADecl: IDecl; const AName: string);
var
  LTable: IDeclTable;
  LIndex: Integer;
  LLine: string;
begin
  Supports(ADecl, IDeclTable, LTable);
  LLine := 'table ' + AName;
  for LIndex := 0 to 8 do
    LLine := LLine + ' ' + Bits(LTable.TableLookup(LIndex / 8.0));
  Emit(LLine);
end;

procedure TEffectsGoldenRunner.DumpParticle(const ADecl: IDecl);
var
  LParticle: IDeclParticle;
  LStage: TParticleStage;
  LIndex: Integer;

  function BoundsText(const ABounds: TGeoBounds): string;
  begin
    Result := BitsList([ABounds.Mins.X, ABounds.Mins.Y, ABounds.Mins.Z]) + ',' +
      BitsList([ABounds.Maxs.X, ABounds.Maxs.Y, ABounds.Maxs.Z]);
  end;

  function ParmText(const AParm: TParticleParm): string;
  var
    LDecl: IDecl;
  begin
    if Assigned(AParm.Table) then
    begin
      Supports(AParm.Table, IDecl, LDecl);
      Result := 'table:' + string(LDecl.GetName);
    end
    else
      Result := Bits(AParm.FromValue) + ',' + Bits(AParm.ToValue);
  end;

  function Flag(const AValue: Boolean): string;
  begin
    Result := IntToStr(Ord(AValue));
  end;

var
  LMaterialName: string;
  LSkipBounds: Boolean;
begin
  Supports(ADecl, IDeclParticle, LParticle);
  Emit(Format('particle %s depth=%s stages=%d', [string(ADecl.GetName), Bits(LParticle.GetDepthHack),
    LParticle.GetNumStages]));
  // the bounds of an orbit path read an uninitialised variable in the original: they are not compared
  LSkipBounds := Copy(string(ADecl.GetName), 1, 5) = 'orbit';
  if not LSkipBounds then
    Emit(' bounds=' + BoundsText(LParticle.GetBounds));
  for LIndex := 0 to LParticle.GetNumStages - 1 do
  begin
    LStage := LParticle.GetStage(LIndex);
    if Assigned(LStage.Material) then
      LMaterialName := string(LStage.Material.GetName)
    else
      LMaterialName := '(null)';
    Emit(Format('stage %d mat=%s cnt=%d cyc=%s cms=%d bunch=%s life=%s toff=%s dead=%s',
      [LIndex, LMaterialName, LStage.TotalParticles, Bits(LStage.Cycles), LStage.CycleMsec,
      Bits(LStage.SpawnBunching), Bits(LStage.ParticleLife), Bits(LStage.TimeOffset), Bits(LStage.DeadTime)]));
    Emit(Format(' dist=%d p=%s dir=%d p=%s speed=%s grav=%s wg=%s rd=%s ec=%s',
      [Ord(LStage.DistributionType), BitsList(LStage.DistributionParms), Ord(LStage.DirectionType),
      BitsList(LStage.DirectionParms), ParmText(LStage.Speed), Bits(LStage.Gravity), Flag(LStage.WorldGravity),
      Flag(LStage.RandomDistribution), Flag(LStage.EntityColor)]));
    Emit(Format(' path=%d p=%s off=%s anim=%d rate=%s angle=%s rot=%s ori=%d p=%s',
      [Ord(LStage.CustomPathType), BitsList(LStage.CustomPathParms),
      BitsList([LStage.Offset.X, LStage.Offset.Y, LStage.Offset.Z]), LStage.AnimationFrames,
      Bits(LStage.AnimationRate), Bits(LStage.InitialAngle), ParmText(LStage.RotationSpeed),
      Ord(LStage.Orientation), BitsList(LStage.OrientationParms)]));
    Emit(Format(' size=%s aspect=%s color=%s fcolor=%s fin=%s fout=%s fidx=%s hid=%s bexp=%s',
      [ParmText(LStage.Size), ParmText(LStage.Aspect),
      BitsList([LStage.Color.X, LStage.Color.Y, LStage.Color.Z, LStage.Color.W]),
      BitsList([LStage.FadeColor.X, LStage.FadeColor.Y, LStage.FadeColor.Z, LStage.FadeColor.W]),
      Bits(LStage.FadeInFraction), Bits(LStage.FadeOutFraction), Bits(LStage.FadeIndexFraction),
      Flag(LStage.Hidden), Bits(LStage.BoundsExpansion)]));
    if not LSkipBounds then
      Emit(' sbounds=' + BoundsText(LStage.Bounds));
  end;
end;

procedure TEffectsGoldenRunner.DumpFx(const ADecl: IDecl);
var
  LFx: IDeclFx;
  LAction: TFxAction;
  LIndex: Integer;

  function Flag(const AValue: Boolean): string;
  begin
    Result := IntToStr(Ord(AValue));
  end;

begin
  Supports(ADecl, IDeclFx, LFx);
  Emit(Format('fx %s joint=[%s] events=%d', [string(ADecl.GetName), TFakeIdLibLog.Escape(LFx.GetJoint),
    LFx.GetNumEvents]));
  for LIndex := 0 to LFx.GetNumEvents - 1 do
  begin
    LAction := LFx.GetEvent(LIndex);
    Emit(Format('event %d type=%d sib=%d data=[%s] name=[%s] fire=[%s]', [LIndex, LAction.ActionType,
      LAction.Sibling, TFakeIdLibLog.Escape(LAction.Data), TFakeIdLibLog.Escape(LAction.Name),
      TFakeIdLibLog.Escape(LAction.Fire)]));
    Emit(' f=' + BitsList([LAction.Delay, LAction.Duration, LAction.Restart, LAction.Size, LAction.FadeInTime,
      LAction.FadeOutTime, LAction.ShakeTime, LAction.ShakeAmplitude, LAction.ShakeDistance, LAction.ShakeImpulse,
      LAction.LightRadius, LAction.Rotate, LAction.Random1, LAction.Random2]));
    Emit(' v=' + BitsList([LAction.LightColor.X, LAction.LightColor.Y, LAction.LightColor.Z]) + ',' +
      BitsList([LAction.Offset.X, LAction.Offset.Y, LAction.Offset.Z]) + ',' +
      BitsList([LAction.Axis.Rows[0].X, LAction.Axis.Rows[0].Y, LAction.Axis.Rows[0].Z,
      LAction.Axis.Rows[1].X, LAction.Axis.Rows[1].Y, LAction.Axis.Rows[1].Z,
      LAction.Axis.Rows[2].X, LAction.Axis.Rows[2].Y, LAction.Axis.Rows[2].Z]));
    Emit(' b=' + Flag(LAction.SoundStarted) + Flag(LAction.ShakeFalloff) + Flag(LAction.ShakeIgnoreMaster) +
      Flag(LAction.BindParticles) + Flag(LAction.ExplicitAxis) + Flag(LAction.NoShadows) +
      Flag(LAction.ParticleTrackVelocity) + Flag(LAction.TrackOrigin));
  end;
end;

procedure TEffectsGoldenRunner.FlushDeclaration(const AType, AName, AText: string);
var
  LDecl: TDecl;
  LParsed: Boolean;
  LMark: Integer;
  LIntegrate: Boolean;
  LTypeNumber: Integer;
  LLog: IIdLibLog;
begin
  Emit(Format('> decl %s %s', [AType, AName]));
  LLog := FLog as IIdLibLog;
  if AType = 'table' then
  begin
    LDecl := TDeclTable.Create;
    LTypeNumber := DECL_TABLE;
  end
  else if AType = 'particle' then
  begin
    LDecl := TDeclParticle.Create(
      function(const ALog: IIdLibLog): IParticleGenerator
      begin
        Result := TParticleGenerator.Create(ALog);
      end);
    LTypeNumber := DECL_PARTICLE;
  end
  else
  begin
    LDecl := TDeclFx.Create;
    LTypeNumber := DECL_FX;
  end;
  // the declaration is held by an interface from here: the base it is given refers to it without counting
  FObjects.AddOrSetValue(AName, LDecl);
  TFakeDeclMaker.Attach(LDecl, LTypeNumber, AnsiString(AName), FFinderIntf, LLog);
  LMark := FLines.Count;
  LParsed := LDecl.Parse(AnsiString(AText));
  DropIntegrateMessages(LMark, LIntegrate);
  Emit(Format('ret=%d integrate=%d', [Ord(LParsed), Ord(LIntegrate)]));
  FObjectTypes.AddOrSetValue(AName, AType);
  FFinder.Add(LTypeNumber, AnsiString(AName), LDecl);
  if AType = 'table' then
    DumpTable(LDecl, AName)
  else if AType = 'particle' then
    DumpParticle(LDecl)
  else
    DumpFx(LDecl);
end;

procedure TEffectsGoldenRunner.OperationGen(const AWords: TArray<string>);
var
  LDecl: IDecl;
  LParticle: IDeclParticle;
  LStage: TParticleStage;
  LGenerator: IParticleGenerator;
  LValues: TDictionary<string, string>;
  LGen, LGen2: TParticleGen;
  LVerts: TArray<TParticleVertex>;
  LOrigin: TIdVec3;
  LCount, LStageIndex, LIndex, LEqual: Integer;
  LRandomSeed: Integer;
  LNumbers: array[0..3] of Single;
  LFormat: TFormatSettings;

  procedure ReadNumbers(const AText: string; var ANumbers: array of Single);
  var
    LParts: TArray<string>;
    LPart: Integer;
  begin
    for LPart := 0 to High(ANumbers) do
      ANumbers[LPart] := 0;
    LParts := AText.Split([',']);
    for LPart := 0 to Min(High(LParts), High(ANumbers)) do
      ANumbers[LPart] := Single(StrToFloat(LParts[LPart], LFormat));
  end;

  function AnglesMatrix(const AText: string): TIdMat3;
  var
    LAngles: array[0..2] of Single;
  begin
    ReadNumbers(AText, LAngles);
    Result := TIdRotationConversions.AnglesToMat(TIdAngles.Create(LAngles[0], LAngles[1], LAngles[2]));
  end;

  function ValueOr(const AName: string; const ADefault: string): string;
  begin
    if not LValues.TryGetValue(AName, Result) then
      Result := ADefault;
  end;

  function Number(const AName: string): Single;
  begin
    Result := Single(StrToFloat(ValueOr(AName, '0'), LFormat));
  end;

var
  LSeedValue: Integer;
begin
  LFormat := TFormatSettings.Invariant;
  LValues := TDictionary<string, string>.Create;
  try
    for LIndex := 2 to High(AWords) do
    begin
      LEqual := Pos('=', AWords[LIndex]);
      if LEqual > 0 then
        LValues.AddOrSetValue(Copy(AWords[LIndex], 1, LEqual - 1), Copy(AWords[LIndex], LEqual + 1, MaxInt));
    end;
    FObjects.TryGetValue(AWords[1], LDecl);
    Supports(LDecl, IDeclParticle, LParticle);
    LStageIndex := StrToInt(ValueOr('stage', '0'));
    LStage := LParticle.GetStage(LStageIndex);
    LGenerator := TParticleGenerator.Create(FLog as IIdLibLog);

    LSeedValue := StrToInt(ValueOr('seed', '0'));
    LRandomSeed := LSeedValue;
    LGen := TParticleGen.Create(TIdRandom.Create(LRandomSeed));
    if LValues.ContainsKey('eaxis') then
      LGen.Entity.Axis := AnglesMatrix(LValues['eaxis']);
    if LValues.ContainsKey('vaxis') then
      LGen.View.ViewAxis := AnglesMatrix(LValues['vaxis']);
    if LValues.ContainsKey('eparm') then
    begin
      ReadNumbers(LValues['eparm'], LNumbers);
      for LIndex := 0 to 3 do
        LGen.Entity.ShaderParms[LIndex] := LNumbers[LIndex];
    end;
    LGen.Index := StrToInt(ValueOr('index', '0'));
    LGen.Frac := Number('frac');
    LGen.Age := Number('age');
    if LValues.ContainsKey('gorigin') then
    begin
      ReadNumbers(LValues['gorigin'], LNumbers);
      LGen.Origin.SetValues(LNumbers[0], LNumbers[1], LNumbers[2]);
    end;
    if LValues.ContainsKey('gaxis') then
      LGen.Axis := AnglesMatrix(LValues['gaxis']);

    Emit(Format('gen %s stage=%d quads=%d', [AWords[1], LStageIndex, LGenerator.NumQuadsPerParticle(LStage)]));
    LGen2 := LGen;
    LOrigin.Zero;
    LGenerator.ParticleOrigin(LStage, LGen2, LOrigin);
    Emit(Format(' origin=%s seed=%d', [BitsList([LOrigin.X, LOrigin.Y, LOrigin.Z]), LGen2.Random.GetSeed]));
    if AWords[0] = 'origin' then
      Exit;
    SetLength(LVerts, 64);
    LCount := LGenerator.CreateParticle(LStage, LGen, LVerts);
    Emit(Format(' n=%d seed=%d aff=%s', [LCount, LGen.Random.GetSeed, Bits(LGen.AnimationFrameFrac)]));
    for LIndex := 0 to LCount - 1 do
      Emit(Format(' v%d xyz=%s st=%s,%s col=%d,%d,%d,%d', [LIndex,
        BitsList([LVerts[LIndex].Xyz.X, LVerts[LIndex].Xyz.Y, LVerts[LIndex].Xyz.Z]), Bits(LVerts[LIndex].St[0]),
        Bits(LVerts[LIndex].St[1]), LVerts[LIndex].Color[0], LVerts[LIndex].Color[1], LVerts[LIndex].Color[2],
        LVerts[LIndex].Color[3]]));
  finally
    LValues.Free;
  end;
end;

procedure TEffectsGoldenRunner.OperationCustom;
const
  NAMES: array[0..6] of AnsiString = ('standard', 'helix', 'flies', 'orbit', 'drip', 'bogus', 'HELIX');
var
  LStage: TParticleStage;
  LIndex: Integer;
begin
  LStage := TParticleStage.Create;
  for LIndex := 0 to High(NAMES) do
  begin
    LStage.SetCustomPathType(NAMES[LIndex]);
    Emit(Format('custom %s -> %d name=%s desc=%s parms=%d', [string(NAMES[LIndex]), Ord(LStage.CustomPathType),
      string(LStage.GetCustomPathName), string(LStage.GetCustomPathDesc), LStage.NumCustomPathParms]));
  end;
end;

procedure TEffectsGoldenRunner.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LDecl: IDecl;
  LParticle: IDeclParticleWriter;
begin
  LWords := Words(AOperation);
  Emit('> ' + string.Join(' ', LWords));
  if (LWords[0] = 'gen') or (LWords[0] = 'origin') then
    OperationGen(LWords)
  else if LWords[0] = 'custom' then
    OperationCustom
  else if LWords[0] = 'save' then
  begin
    FObjects.TryGetValue(LWords[1], LDecl);
    Supports(LDecl, IDeclParticleWriter, LParticle);
    LDecl.SetText('');
    LParticle.Save;
    Emit(Format('saved replaced=%d text=%s', [1, TFakeIdLibLog.Escape(LDecl.GetText)]));
  end
  else if LWords[0] = 'print' then
  begin
    FObjects.TryGetValue(LWords[1], LDecl);
    LDecl.Print;
  end
  else if LWords[0] = 'list' then
  begin
    FObjects.TryGetValue(LWords[1], LDecl);
    LDecl.List;
  end;
end;

function TEffectsGoldenRunner.RunAll(const AInput: TStrings): TStringList;
var
  LLine, LType, LName, LText: string;
  LInDecl: Boolean;
  LParts: TArray<string>;
  LLog: TFakeIdLibLog;
  LMark: Integer;
  LIgnored: Boolean;

  procedure Flush;
  begin
    if LInDecl then
      FlushDeclaration(LType, LName, LText);
    LInDecl := False;
  end;

begin
  Result := TStringList.Create;
  FLines := Result;
  LLog := TFakeIdLibLog.Create(Result);
  FLog := LLog;
  FFinderIntf := TFakeDeclFinder.Create(Result, LLog);
  FFinder := TFakeDeclFinder(FFinderIntf as TObject);
  LInDecl := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        Flush;
        StartCase;
        Emit('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        Flush
      else if LLine.StartsWith('@decl ') then
      begin
        Flush;
        LParts := Words(Copy(LLine, 7, MaxInt));
        LType := LParts[0];
        LName := LParts[1];
        LText := LType + ' ' + LName + #10;
        LInDecl := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        Flush;
        LMark := Result.Count;
        Execute(Copy(LLine, 5, MaxInt));
        DropIntegrateMessages(LMark, LIgnored);
      end
      else if LInDecl then
        LText := LText + LLine + #10;
    end;
    Flush;
  finally
    // the declarations refer to the finder: let them go first
    FObjects.Clear;
    FFinder.Clear;
    FFinderIntf := nil;
    FFinder := nil;
    FLog := nil;
    FLines := nil;
  end;
end;

{ TTestDeclEffectsGolden }

function TTestDeclEffectsGolden.LinesMatch(const AExpected, AActual: string): Boolean;
const
  FLOAT_TOLERANCE = 2E-6;
var
  LExpectedHex, LActualHex: TMatchCollection;
  LIndex: Integer;
  LExpected, LActual: Single;
  LBitsExpected, LBitsActual: Cardinal;
  LSize: Double;
begin
  if AExpected = AActual then
    Exit(True);
  if TRegEx.Replace(AExpected, '\b[0-9A-F]{8}\b', '#') <> TRegEx.Replace(AActual, '\b[0-9A-F]{8}\b', '#') then
    Exit(False);
  LExpectedHex := TRegEx.Matches(AExpected, '\b[0-9A-F]{8}\b');
  LActualHex := TRegEx.Matches(AActual, '\b[0-9A-F]{8}\b');
  if LExpectedHex.Count <> LActualHex.Count then
    Exit(False);
  for LIndex := 0 to LExpectedHex.Count - 1 do
  begin
    LBitsExpected := Cardinal(StrToInt64('$' + LExpectedHex[LIndex].Value));
    LBitsActual := Cardinal(StrToInt64('$' + LActualHex[LIndex].Value));
    LExpected := PSingle(@LBitsExpected)^;
    LActual := PSingle(@LBitsActual)^;
    LSize := Max(1.0, Max(Abs(LExpected), Abs(LActual)));
    if Abs(Double(LExpected) - Double(LActual)) > FLOAT_TOLERANCE * LSize then
      Exit(False);
  end;
  Result := True;
end;

function TTestDeclEffectsGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Decl\');
end;

procedure TTestDeclEffectsGolden.DovrebbeDareLeStesseRisposteDelVeroDeclParticleEDeclFx;
var
  LInput, LGolden, LActual: TStringList;
  LRunner: TEffectsGoldenRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TEffectsGoldenRunner.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'effects.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'effects.golden.txt', TEncoding.ANSI);
    LActual := LRunner.RunAll(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or not LinesMatch(LGolden[LIndex], LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.effects.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclEffectsGolden);

end.
