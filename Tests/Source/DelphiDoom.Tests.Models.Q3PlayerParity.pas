{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - parity of the Quake III player }
{  models with the functions of cgame and renderer (golden)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3PlayerParity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>The configuration of a file as the driver of Tools\Verifica\126 parsed it</summary>
  TParityConfig = record
    Config: IQ3AnimationConfig;
    Ok: Boolean;
    Messages: TArray<string>;
  end;

  /// <summary>
  ///   Every line of q3player.golden.txt is "kind inputs | outputs": the outputs of the original
  ///   functions (floats as #bits) are recomputed from the inputs and compared. The tolerance of
  ///   a float is 4 ULP or 1e-6 absolute (the C code is SSE one float operation at a time, Win32
  ///   keeps the Delphi expressions in the x87 registers, sin and cos come from two libraries).
  /// </summary>
  [TestFixture]
  [Category('Models')]
  TTestQ3PlayerParity = class
  strict private
    FLines: TStringList;
    FConfigs: TDictionary<string, TParityConfig>;
    FModel: IMd3Model;
    FConfigName: string;
    FConfig: IQ3AnimationConfig;
    FPlayer: TQ3PlayerEntity;
    FRunner: IQ3LerpFrameRunner;
    FAnimator: IQ3PlayerAnimator;
    FAngles: IQ3PlayerAngles;
    FLerper: IQ3TagLerper;
    FPositioner: IQ3TagPositioner;
    FMaxUlp: Integer;
    FCompared: Integer;
    function GetConfig(const AName: string): TParityConfig;
    function FloatToken(const AValue: Single): string;
    function ParseFloat(const AToken: string): Single;
    function BoolToken(const AValue: Boolean): string;
    function AxisTokens(const AAxis: TQ3Axis): string;
    function LerpTokens(const AFrame: TQ3LerpFrame): string;
    function VectorFrom(const ATokens: TArray<string>; const AIndex: Integer): TQ3Orientation;
    procedure CheckLine(const ALine, AActual: string);
    function RunCfg(const AKey: string; const AParts: TArray<string>): string;
    function RunTimeline(const AParts: TArray<string>): string;
    function RunStep(const AParts: TArray<string>): string;
    function RunTag(const AParts: TArray<string>): string;
    function RunPos(const AParts: TArray<string>): string;
    function RunLine(const ALine: string): string;
    function OrientationTokens(const AOrientation: TQ3Orientation): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseAnimazioniDelFileCfg;
    [Test]
    procedure DovrebbeDareGliStessiAvvisiDelFileCfg;
    [Test]
    procedure DovrebbeDareLeStesseCorsieDiAnimazioneNelTempo;
    [Test]
    procedure DovrebbeDareGliStessiAngoliENelleStesseCorsie;
    [Test]
    procedure DovrebbeDareLeStessePosizioniDeiTag;
    [Test]
    procedure DovrebbeDareLeStesseUnioniSuiTag;
    [Test]
    procedure DovrebbeDareLeStesseCorsieConHasteEDirezioneErrata;
  end;

implementation

uses
  System.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Q3Player.Factory,
  DelphiDoom.Tests.Models.Q3PlayerSupport;

function TTestQ3PlayerParity.FloatToken(const AValue: Single): string;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, 4);
  Result := '#' + LowerCase(IntToHex(LBits, 8));
end;

function TTestQ3PlayerParity.ParseFloat(const AToken: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AToken, 2, 8)));
  Move(LBits, Result, 4);
end;

function TTestQ3PlayerParity.BoolToken(const AValue: Boolean): string;
begin
  Result := IntToStr(Ord(AValue));
end;

function TTestQ3PlayerParity.AxisTokens(const AAxis: TQ3Axis): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to 2 do
    Result := Result + ' ' + FloatToken(AAxis[LIndex].X) + ' ' + FloatToken(AAxis[LIndex].Y) + ' ' +
      FloatToken(AAxis[LIndex].Z);
end;

function TTestQ3PlayerParity.OrientationTokens(const AOrientation: TQ3Orientation): string;
begin
  Result := FloatToken(AOrientation.Origin.X) + ' ' + FloatToken(AOrientation.Origin.Y) + ' ' +
    FloatToken(AOrientation.Origin.Z) + AxisTokens(AOrientation.Axis);
end;

function TTestQ3PlayerParity.LerpTokens(const AFrame: TQ3LerpFrame): string;
begin
  Result := Format('%d %d %d %d %d %d %s', [AFrame.AnimationNumber, AFrame.FrameTime, AFrame.OldFrameTime,
    AFrame.AnimationTime, AFrame.Frame, AFrame.OldFrame, FloatToken(AFrame.BackLerp)]);
end;

// the line is checked token by token: integers and words as they are, floats within the tolerance
procedure TTestQ3PlayerParity.CheckLine(const ALine, AActual: string);
var
  LExpected, LActual: TArray<string>;
  LIndex: Integer;
  LLeft, LRight: Single;
  LUlp: Int64;
  LLeftBits, LRightBits: Integer;
begin
  LExpected := ALine.Split([' ']);
  LActual := AActual.Split([' ']);
  Assert.AreEqual<Integer>(Length(LExpected), Length(LActual), 'The number of values: ' + ALine);
  for LIndex := 0 to High(LExpected) do
  begin
    if (Length(LExpected[LIndex]) = 9) and (LExpected[LIndex][1] = '#') and (LActual[LIndex][1] = '#') then
    begin
      LLeft := ParseFloat(LExpected[LIndex]);
      LRight := ParseFloat(LActual[LIndex]);
      if LExpected[LIndex] = LActual[LIndex] then
        Continue;
      if IsNan(LLeft) and IsNan(LRight) then
        Continue;
      Move(LLeft, LLeftBits, 4);
      Move(LRight, LRightBits, 4);
      // the bits as numbers that grow with the value
      if LLeftBits < 0 then
        LLeftBits := Integer($80000000) - LLeftBits;
      if LRightBits < 0 then
        LRightBits := Integer($80000000) - LRightBits;
      LUlp := Abs(Int64(LLeftBits) - Int64(LRightBits));
      if (LUlp > FMaxUlp) and (Abs(LLeft) >= 0.1) then
        FMaxUlp := Integer(LUlp);
      Inc(FCompared);
      Assert.IsTrue((LUlp <= 4) or (Abs(Double(LLeft) - Double(LRight)) <= 1e-6),
        Format('Value %d: expected %g (%s), got %g (%s) in: %s',
          [LIndex, Double(LLeft), LExpected[LIndex], Double(LRight), LActual[LIndex], ALine]));
    end
    else
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex], Format('Value %d in: %s', [LIndex, ALine]));
  end;
end;

function TTestQ3PlayerParity.GetConfig(const AName: string): TParityConfig;
var
  LLog: TFakeQ3Log;
  LLogIntf: IInterface;
  LLoader: IQ3AnimationLoader;
  LMessages: TList<string>;
  LIndex: Integer;
begin
  if FConfigs.TryGetValue(AName, Result) then
    Exit;
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  LMessages := TList<string>.Create;
  try
    LLoader := TQ3PlayerFactory.CreateLoader(TFileQ3TextSource.Create, LLog);
    Result.Ok := False;
    try
      Result.Config := LLoader.Load(AName);
      Result.Ok := True;
    except
      on E: EQ3AnimationMissingException do
        Result.Config := nil;
      on E: EQ3PlayerException do
      begin
        Result.Config := nil;
        LLog.Warning(E.Message);
      end;
    end;
    for LIndex := 0 to LLog.Warnings.Count - 1 do
      LMessages.Add(LLog.Warnings[LIndex]);
    Result.Messages := LMessages.ToArray;
  finally
    LMessages.Free;
  end;
  FConfigs.Add(AName, Result);
end;

function TTestQ3PlayerParity.RunCfg(const AKey: string; const AParts: TArray<string>): string;
var
  LEntry: TParityConfig;
  LAnimation: TQ3Animation;
  LHeadOffset: TIdVec3;
begin
  // the parts: cfg name | ...; anim name index | ...; cfgmsg name index | ...
  LEntry := GetConfig(AParts[1]);
  if AKey = 'cfg' then
  begin
    if not LEntry.Ok then
      Exit('fail');
    LHeadOffset := LEntry.Config.HeadOffset;
    Exit(Format('ok %d %d %d %d %s %s %s', [Ord(LEntry.Config.Footsteps), Ord(LEntry.Config.Gender),
      Ord(LEntry.Config.FixedLegs), Ord(LEntry.Config.FixedTorso), FloatToken(LHeadOffset.X),
      FloatToken(LHeadOffset.Y), FloatToken(LHeadOffset.Z)]));
  end;
  if AKey = 'anim' then
  begin
    LAnimation := LEntry.Config.Animations[StrToInt(AParts[2])];
    Exit(Format('%d %d %d %d %d %d %d', [LAnimation.FirstFrame, LAnimation.NumFrames, LAnimation.LoopFrames,
      LAnimation.FrameLerp, LAnimation.InitialLerp, Ord(LAnimation.Reversed), Ord(LAnimation.Flipflop)]));
  end;
  Result := LEntry.Messages[StrToInt(AParts[2])];
end;

function TTestQ3PlayerParity.RunTimeline(const AParts: TArray<string>): string;
var
  LEntry: TParityConfig;
begin
  // timeline name seed: a new player on a configuration, as CG_ResetPlayerEntity makes it
  LEntry := GetConfig(AParts[1]);
  if not LEntry.Ok then
    Exit('cfgfail');
  FConfigName := AParts[1];
  FConfig := LEntry.Config;
  FRunner := TQ3PlayerFactory.CreateLerpFrameRunner(FConfig);
  FAnimator := TQ3PlayerFactory.CreateAnimator(FConfig);
  FAngles := TQ3PlayerFactory.CreateAngles(FConfig);
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FRunner.Clear(FPlayer.Legs, Q3_LEGS_IDLE, 1000);
  FRunner.Clear(FPlayer.Torso, Q3_TORSO_STAND, 1000);
  FPlayer.Torso.YawAngle := 90;
  FPlayer.Legs.YawAngle := 90;
  Result := LerpTokens(FPlayer.Legs) + ' ' + LerpTokens(FPlayer.Torso);
end;

function TTestQ3PlayerParity.RunStep(const AParts: TArray<string>): string;
var
  LInput: TQ3PlayerAngleInput;
  LFrames: TQ3PlayerFrames;
  LLegs, LTorso, LHead: TQ3Axis;
  LPowerups, LEFlags: Integer;
begin
  // step time dt legsAnim torsoAnim powerups eflags #angles2yaw #lerp(3) #velocity(3) painTime painDir | ...
  LInput.Time := StrToInt(AParts[1]);
  LInput.FrameTime := StrToInt(AParts[2]);
  LInput.LegsAnim := StrToInt(AParts[3]);
  LInput.TorsoAnim := StrToInt(AParts[4]);
  LPowerups := StrToInt(AParts[5]);
  LEFlags := StrToInt(AParts[6]);
  LInput.Dead := (LEFlags and 1) <> 0;
  LInput.MovementDirection := ParseFloat(AParts[7]);
  LInput.LerpAngles := TIdVec3.Create(ParseFloat(AParts[8]), ParseFloat(AParts[9]), ParseFloat(AParts[10]));
  LInput.Velocity := TIdVec3.Create(ParseFloat(AParts[11]), ParseFloat(AParts[12]), ParseFloat(AParts[13]));
  FPlayer.PainTime := StrToInt(AParts[14]);
  FPlayer.PainDirection := StrToInt(AParts[15]);
  try
    FAngles.Compute(LInput, FPlayer, LLegs, LTorso, LHead);
    FAnimator.Animate(FPlayer, LInput.Time, LInput.LegsAnim, LInput.TorsoAnim, LPowerups <> 0, LFrames);
  except
    on E: EQ3PlayerException do
      Exit('error ' + E.Message);
  end;
  Result := Copy(AxisTokens(LLegs), 2, MaxInt) + AxisTokens(LTorso) + AxisTokens(LHead) +
    Format(' %d %d %s %d %d %s', [LFrames.LegsOld, LFrames.Legs, FloatToken(LFrames.LegsBackLerp),
      LFrames.TorsoOld, LFrames.Torso, FloatToken(LFrames.TorsoBackLerp)]) +
    Format(' %s %s %s %s %s %s', [FloatToken(FPlayer.Torso.YawAngle), BoolToken(FPlayer.Torso.Yawing),
      FloatToken(FPlayer.Torso.PitchAngle), BoolToken(FPlayer.Torso.Pitching),
      FloatToken(FPlayer.Legs.YawAngle), BoolToken(FPlayer.Legs.Yawing)]) +
    ' ' + LerpTokens(FPlayer.Legs) + ' ' + LerpTokens(FPlayer.Torso);
end;

function TTestQ3PlayerParity.VectorFrom(const ATokens: TArray<string>; const AIndex: Integer): TQ3Orientation;
var
  LAxis: Integer;
begin
  Result.Origin := TIdVec3.Create(ParseFloat(ATokens[AIndex]), ParseFloat(ATokens[AIndex + 1]),
    ParseFloat(ATokens[AIndex + 2]));
  for LAxis := 0 to 2 do
    Result.Axis[LAxis] := TIdVec3.Create(ParseFloat(ATokens[AIndex + 3 + LAxis * 3]),
      ParseFloat(ATokens[AIndex + 4 + LAxis * 3]), ParseFloat(ATokens[AIndex + 5 + LAxis * 3]));
end;

function TTestQ3PlayerParity.RunTag(const AParts: TArray<string>): string;
var
  LTag: TQ3Orientation;
  LOk: Boolean;
begin
  // tag name start end #fraction
  LOk := FLerper.LerpTag(FModel, StrToInt(AParts[2]), StrToInt(AParts[3]), ParseFloat(AParts[4]),
    AnsiString(AParts[1]), LTag);
  Result := IntToStr(Ord(LOk)) + ' ' + OrientationTokens(LTag);
end;

function TTestQ3PlayerParity.RunPos(const AParts: TArray<string>): string;
var
  LParent, LEntity: TQ3Entity;
  LOrientation: TQ3Orientation;
begin
  // pos rotated oldframe frame #backlerp name #origin(3) #axis(9) #entityaxis(9)
  FillChar(LParent, SizeOf(LParent), 0);
  FillChar(LEntity, SizeOf(LEntity), 0);
  LParent.OldFrame := StrToInt(AParts[2]);
  LParent.Frame := StrToInt(AParts[3]);
  LParent.BackLerp := ParseFloat(AParts[4]);
  LOrientation := VectorFrom(AParts, 6);
  LParent.Origin := LOrientation.Origin;
  LParent.Axis := LOrientation.Axis;
  LEntity.BackLerp := 0.375;
  if AParts[1] = '1' then
  begin
    LEntity.Axis[0] := TIdVec3.Create(ParseFloat(AParts[18]), ParseFloat(AParts[19]), ParseFloat(AParts[20]));
    LEntity.Axis[1] := TIdVec3.Create(ParseFloat(AParts[21]), ParseFloat(AParts[22]), ParseFloat(AParts[23]));
    LEntity.Axis[2] := TIdVec3.Create(ParseFloat(AParts[24]), ParseFloat(AParts[25]), ParseFloat(AParts[26]));
    FPositioner.PositionRotatedEntityOnTag(LEntity, LParent, FModel, AnsiString(AParts[5]));
  end
  else
    FPositioner.PositionEntityOnTag(LEntity, LParent, FModel, AnsiString(AParts[5]));
  LOrientation.Origin := LEntity.Origin;
  LOrientation.Axis := LEntity.Axis;
  Result := OrientationTokens(LOrientation) + ' ' + FloatToken(LEntity.BackLerp);
end;

// the line as the driver wrote it; the part after " | " is what the classes have to give
function TTestQ3PlayerParity.RunLine(const ALine: string): string;
var
  LParts: TArray<string>;
  LInputs: string;
begin
  LInputs := Copy(ALine, 1, Pos(' | ', ALine) - 1);
  LParts := LInputs.Split([' ']);
  if (LParts[0] = 'cfg') or (LParts[0] = 'anim') or (LParts[0] = 'cfgmsg') then
    Result := RunCfg(LParts[0], LParts)
  else if LParts[0] = 'timeline' then
    Result := RunTimeline(LParts)
  else if LParts[0] = 'step' then
    Result := RunStep(LParts)
  else if LParts[0] = 'tag' then
    Result := RunTag(LParts)
  else
    Result := RunPos(LParts);
end;

procedure TTestQ3PlayerParity.Setup;
begin
  FLines := TStringList.Create;
  FConfigs := TDictionary<string, TParityConfig>.Create;
  FLines.Text := TEncoding.ANSI.GetString(Q3DataFile('q3player.golden.txt'));
  FModel := ReadMd3(Q3DataFile('tags.md3'));
  FLerper := TQ3PlayerFactory.CreateTagLerper;
  FPositioner := TQ3PlayerFactory.CreateTagPositioner;
  FMaxUlp := 0;
  FCompared := 0;
end;

procedure TTestQ3PlayerParity.TearDown;
begin
  FConfigs.Free;
  FLines.Free;
end;

procedure TTestQ3PlayerParity.DovrebbeDareLeStesseAnimazioniDelFileCfg;
var
  LLine, LExpected: string;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FLines do
    if LLine.StartsWith('cfg ') or LLine.StartsWith('anim ') then
    begin
      LExpected := Copy(LLine, Pos(' | ', LLine) + 3, MaxInt);
      CheckLine(LExpected, RunLine(LLine));
      Inc(LCount);
    end;
  // 7 files; 4 of them parse and have 37 animations
  Assert.IsTrue(LCount = 7 + 4 * 37, 'Lines checked: ' + IntToStr(LCount));
end;

procedure TTestQ3PlayerParity.DovrebbeDareGliStessiAvvisiDelFileCfg;
var
  LLine: string;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FLines do
    if LLine.StartsWith('cfgmsg ') then
    begin
      Assert.AreEqual(Copy(LLine, Pos(' | ', LLine) + 3, MaxInt), RunLine(LLine));
      Inc(LCount);
    end;
  Assert.IsTrue(LCount = 5, 'Messages checked: ' + IntToStr(LCount));
end;

procedure TTestQ3PlayerParity.DovrebbeDareLeStesseCorsieDiAnimazioneNelTempo;
var
  LLine: string;
  LSteps: Integer;
begin
  // the first three timelines (full.cfg, headeropts.cfg, noflags.cfg): no error, no haste-only lines
  LSteps := 0;
  for LLine in FLines do
  begin
    if LLine.StartsWith('timeline ') or LLine.StartsWith('step ') then
    begin
      if LLine.Contains(' error ') then
        Continue;
      CheckLine(Copy(LLine, Pos(' | ', LLine) + 3, MaxInt), RunLine(LLine));
      if LLine.StartsWith('step ') then
        Inc(LSteps);
    end;
  end;
  Assert.IsTrue(LSteps >= 160, 'Steps checked: ' + IntToStr(LSteps));
end;

procedure TTestQ3PlayerParity.DovrebbeDareGliStessiAngoliENelleStesseCorsie;
begin
  // the angles and the frames of a step are in the same line: this checks that the float
  // tolerance used was small (the ULP found is a number to look at when it grows)
  DovrebbeDareLeStesseCorsieDiAnimazioneNelTempo;
  Assert.IsTrue(FMaxUlp <= 16, 'The largest difference seen is ' + IntToStr(FMaxUlp) + ' ULP');
  Assert.IsTrue(FCompared >= 0);
end;

procedure TTestQ3PlayerParity.DovrebbeDareLeStessePosizioniDeiTag;
var
  LLine: string;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FLines do
    if LLine.StartsWith('tag ') then
    begin
      CheckLine(Copy(LLine, Pos(' | ', LLine) + 3, MaxInt), RunLine(LLine));
      Inc(LCount);
    end;
  Assert.AreEqual(100, LCount);
end;

procedure TTestQ3PlayerParity.DovrebbeDareLeStesseUnioniSuiTag;
var
  LLine: string;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FLines do
    if LLine.StartsWith('pos ') then
    begin
      CheckLine(Copy(LLine, Pos(' | ', LLine) + 3, MaxInt), RunLine(LLine));
      Inc(LCount);
    end;
  Assert.AreEqual(100, LCount);
end;

procedure TTestQ3PlayerParity.DovrebbeDareLeStesseCorsieConHasteEDirezioneErrata;
var
  LLine: string;
  LErrors: Integer;
begin
  // the two last timelines end with a step that the original stops with CG_Error
  LErrors := 0;
  for LLine in FLines do
  begin
    if LLine.StartsWith('timeline ') or LLine.StartsWith('step ') then
    begin
      CheckLine(Copy(LLine, Pos(' | ', LLine) + 3, MaxInt), RunLine(LLine));
      if LLine.Contains(' error ') then
        Inc(LErrors);
    end;
  end;
  Assert.AreEqual(2, LErrors);
end;

end.
