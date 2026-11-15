{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TAnimBlend (idAnimBlend) (DUnitX)                      }
{                                                                              }
{  The numbers are worked out from the text of Anim_Blend.cpp: the times and   }
{  the weights by hand, the poses by the functions of idMD5Anim that already   }
{  have their parity with the C++ (Tests\Data\Models\md5).                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.AnimBlend;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Vec3, DelphiDoom.Models.Md5.Types, DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.JointQuat, DelphiDoom.Models.Anim.Types, DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.Blend.Types, DelphiDoom.Models.Anim.Blend, DelphiDoom.Models.Anim.ModelDef,
  DelphiDoom.Tests.Models.AnimatorSupport;

type
  [TestFixture]
  [Category('models')]
  TTestAnimBlend = class(TObject)
  strict private
    FWorld: TAnimatorWorld;
    function IdleFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
    function ShortFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
    procedure AssertSamePose(const AExpected, AActual: TArray<TMd5JointQuat>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereIValoriDiPartenza;
    [Test]
    procedure DovrebbeDareIlPesoNelTempoDiMiscela;
    [Test]
    procedure DovrebbeFissareLaFineQuandoIlPesoVaAZero;
    [Test]
    procedure DovrebbeSuonareUnaVoltaFinoAllaFine;
    [Test]
    procedure DovrebbeCiclareSenzaFine;
    [Test]
    procedure DovrebbeIniziareACasoConRandomCycleStart;
    [Test]
    procedure DovrebbeLimitareIlFotogrammoDiSetFrame;
    [Test]
    procedure DovrebbeNonFareNullaSenzaDefinizioneOAnimInesistente;
    [Test]
    procedure DovrebbeAvvisareSeIGiuntiNonCorrispondono;
    [Test]
    procedure DovrebbeCalcolareIlTempoDellAnim;
    [Test]
    procedure DovrebbeCambiareIlNumeroDiCicliEIlRitmo;
    [Test]
    procedure DovrebbeDireSeIlFotogrammoCambia;
    [Test]
    procedure DovrebbeDireSeHaFinito;
    [Test]
    procedure DovrebbeDareIlNumeroDelFotogramma;
    [Test]
    procedure DovrebbeChiamareICommandiDeiFotogrammi;
    [Test]
    procedure DovrebbeNonChiamareICommandiQuandoNonDeve;
    [Test]
    procedure DovrebbeMescolareLaPoseDiUnAnimSullaPosaIntera;
    [Test]
    procedure DovrebbeMescolareDueAnimConIPesi;
    [Test]
    procedure DovrebbeTogliereLOrigineDellaRadice;
    [Test]
    procedure DovrebbeMescolareLeAnimSincronizzate;
    [Test]
    procedure DovrebbeUsareUnSoloFotogrammoDiSetFrame;
    [Test]
    procedure DovrebbeNonMescolareUnAnimFinitaOSenzaPeso;
    [Test]
    procedure DovrebbeSostituireIlPesoConLOverride;
    [Test]
    procedure DovrebbeMescolareLOrigine;
    [Test]
    procedure DovrebbeMescolareLoSpostamento;
    [Test]
    procedure DovrebbeMescolareLaRotazioneDelloSpostamento;
    [Test]
    procedure DovrebbeAggiungereLeBounds;
    [Test]
    procedure DovrebbeDareNomiELunghezze;
    [Test]
    procedure DovrebbeImpostarePesiDelleAnimSincronizzate;
  end;

implementation

const
  START = 1000;

{ TTestAnimBlend }

procedure TTestAnimBlend.Setup;
begin
  FWorld := TAnimatorWorld.Create;
end;

procedure TTestAnimBlend.TearDown;
begin
  FWorld.Free;
end;

function TTestAnimBlend.IdleFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
begin
  Result := FWorld.Idle.GetInterpolatedFrame(FWorld.Idle.ConvertTimeToFrame(ATime, ACycle), nil);
end;

function TTestAnimBlend.ShortFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
begin
  Result := FWorld.Short.GetInterpolatedFrame(FWorld.Short.ConvertTimeToFrame(ATime, ACycle), nil);
end;

procedure TTestAnimBlend.AssertSamePose(const AExpected, AActual: TArray<TMd5JointQuat>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), Length(AActual));
  for LIndex := 0 to High(AExpected) do
  begin
    Assert.AreEqual(AExpected[LIndex].T.X, AActual[LIndex].T.X, 0.0, 'tx ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].T.Y, AActual[LIndex].T.Y, 0.0, 'ty ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].T.Z, AActual[LIndex].T.Z, 0.0, 'tz ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].Q.X, AActual[LIndex].Q.X, 0.0, 'qx ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].Q.Y, AActual[LIndex].Q.Y, 0.0, 'qy ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].Q.Z, AActual[LIndex].Q.Z, 0.0, 'qz ' + IntToStr(LIndex));
    Assert.AreEqual(AExpected[LIndex].Q.W, AActual[LIndex].Q.W, 0.0, 'qw ' + IntToStr(LIndex));
  end;
end;

procedure TTestAnimBlend.DovrebbeAvereIValoriDiPartenza;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  Assert.AreEqual<Integer>(1, LBlend.GetCycleCount);
  Assert.AreEqual(1.0, LBlend.GetPlaybackRate, 0.0);
  Assert.AreEqual(0.0, LBlend.GetWeight(5), 0.0);
  Assert.AreEqual(0.0, LBlend.GetFinalWeight, 0.0);
  Assert.IsTrue(LBlend.AllowMove);
  Assert.IsTrue(LBlend.AllowFrameCommands);
  Assert.IsNull(LBlend.Anim);
  Assert.AreEqual('', string(LBlend.AnimName));
  Assert.AreEqual('', string(LBlend.AnimFullName));
  Assert.AreEqual<Integer>(0, LBlend.NumFrames);
  Assert.AreEqual<Integer>(0, LBlend.Length);
  Assert.AreEqual<Integer>(0, LBlend.NumSyncedAnims);
  Assert.AreEqual<Integer>(0, LBlend.GetStartTime);
  Assert.AreEqual<Integer>(0, LBlend.GetEndTime);
  Assert.AreEqual<Integer>(0, LBlend.PlayLength);
  Assert.AreEqual<Integer>(0, LBlend.AnimTime(100));
  Assert.AreEqual<Integer>(1, LBlend.GetFrameNumber(100));
  Assert.IsFalse(LBlend.SetSyncedAnimWeight(0, 1.0));
  Assert.IsFalse(LBlend.FrameHasChanged(0));
end;

procedure TTestAnimBlend.DovrebbeDareIlPesoNelTempoDiMiscela;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 100);
  // the blend starts one millisecond before and lasts 100
  Assert.AreEqual(0.0, LBlend.GetWeight(START - 1), 0.0);
  Assert.AreEqual(0.01, LBlend.GetWeight(START), 0.0000001);
  Assert.AreEqual(0.5, LBlend.GetWeight(START + 49), 0.0);
  Assert.AreEqual(1.0, LBlend.GetWeight(START + 99), 0.0);
  Assert.AreEqual(1.0, LBlend.GetWeight(START + 5000), 0.0);
  Assert.AreEqual(1.0, LBlend.GetFinalWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeFissareLaFineQuandoIlPesoVaAZero;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  LBlend.SetWeight(0.25, START + 10, 50);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  LBlend.SetWeight(0.0, START + 20, 50);
  Assert.AreEqual<Integer>(START + 70, LBlend.GetEndTime);
  Assert.AreEqual(0.0, LBlend.GetFinalWeight, 0.0);
  // Clear without time resets, with a time fades out
  LBlend.Clear(START + 30, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  LBlend.Clear(START + 30, 40);
  Assert.AreEqual<Integer>(1, LBlend.GetAnimNum);
  Assert.AreEqual<Integer>(START + 70, LBlend.GetEndTime);
end;

procedure TTestAnimBlend.DovrebbeSuonareUnaVoltaFinoAllaFine;
var
  LBlend: TAnimBlend;
  LLength: Integer;
begin
  LLength := FWorld.Idle.Length;
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  Assert.AreEqual<Integer>(1, LBlend.GetAnimNum);
  Assert.AreEqual<Integer>(START + LLength, LBlend.GetEndTime);
  Assert.AreEqual<Integer>(START, LBlend.GetStartTime);
  Assert.AreEqual<Integer>(LLength, LBlend.PlayLength);
  Assert.AreEqual<Integer>(1, LBlend.GetCycleCount);
  Assert.AreEqual('idle', string(LBlend.AnimName));
  Assert.AreEqual('idle1', string(LBlend.AnimFullName));
  Assert.AreEqual<Integer>(3, LBlend.NumFrames);
  Assert.AreEqual<Integer>(LLength, LBlend.Length);
  Assert.AreEqual<Integer>(1, LBlend.NumSyncedAnims);
  Assert.AreEqual(1.0, LBlend.AnimWeights[0], 0.0);
end;

procedure TTestAnimBlend.DovrebbeCiclareSenzaFine;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  Assert.AreEqual<Integer>(-1, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(START, LBlend.GetStartTime);
  Assert.AreEqual<Integer>(-1, LBlend.PlayLength);
  Assert.IsFalse(LBlend.IsDone(START + 1000000));
end;

procedure TTestAnimBlend.DovrebbeIniziareACasoConRandomCycleStart;
var
  LBlend: TAnimBlend;
  LFlags: TAnimFlags;
  LAnim: IAnim;
begin
  LAnim := FWorld.ModelDef.GetAnimByIndex(1);
  LFlags := LAnim.Flags;
  LFlags.RandomCycleStart := True;
  LAnim.Flags := LFlags;
  LBlend := FWorld.NewBlend(
    function: Single
    begin
      Result := 0.5;
    end);
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  // 1000 - 0.5 * 84 = 958, exact
  Assert.AreEqual<Integer>(958, LBlend.GetStartTime);
  // without a generator the start is the current time
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  Assert.AreEqual<Integer>(START, LBlend.GetStartTime);
end;

procedure TTestAnimBlend.DovrebbeLimitareIlFotogrammoDiSetFrame;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.SetFrame(FWorld.ModelDef, 1, 0, START, 0);
  Assert.AreEqual<Integer>(1, LBlend.Frame);
  LBlend.SetFrame(FWorld.ModelDef, 1, -5, START, 0);
  Assert.AreEqual<Integer>(1, LBlend.Frame);
  LBlend.SetFrame(FWorld.ModelDef, 1, 2, START, 0);
  Assert.AreEqual<Integer>(2, LBlend.Frame);
  LBlend.SetFrame(FWorld.ModelDef, 1, 99, START, 0);
  Assert.AreEqual<Integer>(3, LBlend.Frame);
  Assert.AreEqual<Integer>(-1, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  // a single frame blend is at the time of its frame
  Assert.AreEqual<Integer>(AnimFrameToMilliseconds(2), LBlend.AnimTime(START + 500));
  Assert.AreEqual<Integer>(3, LBlend.GetFrameNumber(START));
end;

procedure TTestAnimBlend.DovrebbeNonFareNullaSenzaDefinizioneOAnimInesistente;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(nil, 1, START, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  LBlend.PlayAnim(FWorld.ModelDef, 0, START, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  LBlend.CycleAnim(FWorld.ModelDef, 9, START, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  LBlend.SetFrame(FWorld.ModelDef, -1, 1, START, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  Assert.AreEqual<Integer>(0, FWorld.Log.Count);
end;

procedure TTestAnimBlend.DovrebbeAvvisareSeIGiuntiNonCorrispondono;
var
  LBlend: TAnimBlend;
  LDef: TModelDef;
  LDefIntf: IModelDef;
begin
  // a definition without a model has no joints, the anim has two
  LDef := TModelDef.Create('empty');
  LDefIntf := LDef;
  LDef.AddAnim(FWorld.ModelDef.GetAnimByIndex(1).Clone);
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(LDefIntf, 1, START, 0);
  Assert.AreEqual<Integer>(0, LBlend.GetAnimNum);
  Assert.AreEqual<Integer>(1, FWorld.Log.Count);
  Assert.IsTrue(Pos('has different # of joints than anim', FWorld.Log.Text) > 0);
  LBlend.CycleAnim(LDefIntf, 1, START, 0);
  LBlend.SetFrame(LDefIntf, 1, 1, START, 0);
  Assert.AreEqual<Integer>(3, FWorld.Log.Count);
end;

procedure TTestAnimBlend.DovrebbeCalcolareIlTempoDellAnim;
var
  LBlend: TAnimBlend;
  LLength: Integer;
begin
  LLength := FWorld.Idle.Length;
  // the length is rounded up: (2 * 1000 + 23) / 24 = 84
  Assert.AreEqual<Integer>(84, LLength);
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  // the time of a cycle wraps in the length
  Assert.AreEqual<Integer>(16, LBlend.AnimTime(100));
  Assert.AreEqual<Integer>(0, LBlend.AnimTime(84));
  // before the start the remainder is negative: the length is added
  LBlend.SetStartTime(100);
  Assert.AreEqual<Integer>(68, LBlend.AnimTime(0));
  // a different rate scales the time: (100 - 0) * 2 = 200, 200 mod 84 = 32
  LBlend.SetStartTime(0);
  LBlend.Rate := 2.0;
  Assert.AreEqual<Integer>(32, LBlend.AnimTime(100));
  // a play (cycle 1) does not wrap
  LBlend.PlayAnim(FWorld.ModelDef, 1, 0, 0);
  Assert.AreEqual<Integer>(100, LBlend.AnimTime(100));
  LBlend.TimeOffset := 7;
  Assert.AreEqual<Integer>(107, LBlend.AnimTime(100));
end;

procedure TTestAnimBlend.DovrebbeCambiareIlNumeroDiCicliEIlRitmo;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  LBlend.SetCycleCount(3);
  Assert.AreEqual<Integer>(3, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(START + 84 * 3, LBlend.GetEndTime);
  LBlend.SetCycleCount(0);
  Assert.AreEqual<Integer>(1, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(START + 84, LBlend.GetEndTime);
  LBlend.SetCycleCount(-4);
  Assert.AreEqual<Integer>(-1, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  // with a rate of 2 the end is half: 84 * 3 / 2 = 126
  LBlend.Rate := 2.0;
  LBlend.SetCycleCount(3);
  Assert.AreEqual<Integer>(START + 126, LBlend.GetEndTime);
  // with a rate of 5 it is cut: 84 / 5 = 16.8 -> 16 (the sum is made in float, then converted)
  LBlend.Rate := 5.0;
  LBlend.SetCycleCount(0);
  Assert.AreEqual<Integer>(START + 16, LBlend.GetEndTime);
  // a rate of 0 never ends
  LBlend.Rate := 0.0;
  LBlend.SetCycleCount(3);
  Assert.AreEqual<Integer>(-1, LBlend.GetEndTime);
  // without an anim the cycle is -1 and the end 0
  LBlend.Reset(FWorld.ModelDef);
  LBlend.SetCycleCount(5);
  Assert.AreEqual<Integer>(-1, LBlend.GetCycleCount);
  Assert.AreEqual<Integer>(0, LBlend.EndTime);
end;

procedure TTestAnimBlend.DovrebbeDireSeIlFotogrammoCambia;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  Assert.IsFalse(LBlend.FrameHasChanged(START));
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  Assert.IsTrue(LBlend.FrameHasChanged(START + 5));
  // a cycle with a blend that is still going
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 100);
  Assert.IsTrue(LBlend.FrameHasChanged(START + 5));
  // a play that is over does not change
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  Assert.IsFalse(LBlend.FrameHasChanged(START + 85));
  // a single frame changes only at the time it was set
  LBlend.SetFrame(FWorld.ModelDef, 1, 2, START, 0);
  Assert.IsTrue(LBlend.FrameHasChanged(START));
  Assert.IsFalse(LBlend.FrameHasChanged(START + 1));
  // a play changes at the first instant
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  Assert.IsTrue(LBlend.FrameHasChanged(START));
end;

procedure TTestAnimBlend.DovrebbeDireSeHaFinito;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  Assert.IsFalse(LBlend.IsDone(START + 83));
  Assert.IsTrue(LBlend.IsDone(START + 84));
  // a fade out is done when the time of the fade has passed
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  Assert.IsFalse(LBlend.IsDone(START + 1000));
  LBlend.SetWeight(0.0, START + 100, 50);
  Assert.IsFalse(LBlend.IsDone(START + 120));
  Assert.IsTrue(LBlend.IsDone(START + 149));
  // an empty blend is done
  LBlend.Reset(FWorld.ModelDef);
  Assert.IsTrue(LBlend.IsDone(START));
end;

procedure TTestAnimBlend.DovrebbeDareIlNumeroDelFotogramma;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  Assert.AreEqual<Integer>(1, LBlend.GetFrameNumber(0));
  // 50 ms at 24 fps is frame 1 (zero based): the number is 2
  Assert.AreEqual<Integer>(2, LBlend.GetFrameNumber(50));
  Assert.AreEqual<Integer>(1, LBlend.GetFrameNumber(90));
end;

procedure TTestAnimBlend.DovrebbeChiamareICommandiDeiFotogrammi;
var
  LBlend: TAnimBlend;
  LEntity: TFakeAnimatorEntity;
  LEntityIntf: IAnimatorEntity;
  LAnim: IAnim;
  LCommand: TAnimFrameCommand;
begin
  LAnim := FWorld.ModelDef.GetAnimByIndex(1);
  LCommand.CommandType := fcJump;
  LCommand.Text := '';
  LCommand.HasText := False;
  LCommand.Index := 0;
  LAnim.AddFrameCommand(0, LCommand);
  LCommand.CommandType := fcLeftFoot;
  LAnim.AddFrameCommand(1, LCommand);
  LCommand.CommandType := fcRightFoot;
  LAnim.AddFrameCommand(2, LCommand);
  LEntity := TFakeAnimatorEntity.Create;
  LEntityIntf := LEntity;
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, 0, 0);
  // the first call includes frame 0 ("make sure the first frame is called")
  LBlend.CallFrameCommands(LEntityIntf, 0, 50);
  Assert.AreEqual(Format('cmd:idle1:0:%d cmd:idle1:1:%d', [Ord(fcJump), Ord(fcLeftFoot)]), LEntity.Joined);
  // still on frame 1: nothing new
  LEntity.Events.Clear;
  LBlend.CallFrameCommands(LEntityIntf, 50, 83);
  Assert.AreEqual('', LEntity.Joined);
  // past the end the last frame is reached
  LBlend.CallFrameCommands(LEntityIntf, 83, 100);
  Assert.AreEqual(Format('cmd:idle1:2:%d', [Ord(fcRightFoot)]), LEntity.Joined);
end;

procedure TTestAnimBlend.DovrebbeNonChiamareICommandiQuandoNonDeve;
var
  LBlend: TAnimBlend;
  LEntity: TFakeAnimatorEntity;
  LEntityIntf: IAnimatorEntity;
  LAnim: IAnim;
  LCommand: TAnimFrameCommand;
begin
  LAnim := FWorld.ModelDef.GetAnimByIndex(1);
  LCommand.CommandType := fcJump;
  LCommand.Text := '';
  LCommand.HasText := False;
  LCommand.Index := 0;
  LAnim.AddFrameCommand(0, LCommand);
  LEntity := TFakeAnimatorEntity.Create;
  LEntityIntf := LEntity;
  LBlend := FWorld.NewBlend;
  // no anim
  LBlend.CallFrameCommands(LEntityIntf, 0, 50);
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  // no sink
  LBlend.CallFrameCommands(nil, 0, 50);
  // the time of the call is before the start of the anim
  LBlend.CallFrameCommands(LEntityIntf, -20, 0);
  // the commands are disabled
  LBlend.SetAllowFrameCommands(False);
  LBlend.CallFrameCommands(LEntityIntf, 0, 50);
  LBlend.SetAllowFrameCommands(True);
  // a single frame does not run them
  LBlend.SetFrame(FWorld.ModelDef, 1, 1, 0, 0);
  LBlend.CallFrameCommands(LEntityIntf, 0, 50);
  // the anim is over
  LBlend.PlayAnim(FWorld.ModelDef, 1, 0, 0);
  LBlend.CallFrameCommands(LEntityIntf, 90, 100);
  Assert.AreEqual('', LEntity.Joined);
  // an anim without commands
  LBlend.CycleAnim(FWorld.ModelDef, 2, 0, 0);
  LBlend.CallFrameCommands(LEntityIntf, 0, 50);
  Assert.AreEqual('', LEntity.Joined);
end;

procedure TTestAnimBlend.DovrebbeMescolareLaPoseDiUnAnimSullaPosaIntera;
var
  LBlend: TAnimBlend;
  LFrame: TArray<TMd5JointQuat>;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  Assert.IsTrue(LBlend.BlendAnim(START + 20, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  AssertSamePose(IdleFrame(20, 1), LFrame);
  Assert.AreEqual(1.0, LWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeMescolareDueAnimConIPesi;
var
  LFirst, LSecond: TAnimBlend;
  LFrame, LExpected: TArray<TMd5JointQuat>;
  LWeight, LLerp: Single;
begin
  LFirst := FWorld.NewBlend;
  LFirst.CycleAnim(FWorld.ModelDef, 1, START, 0);
  LSecond := FWorld.NewBlend;
  LSecond.CycleAnim(FWorld.ModelDef, 2, START, 100);
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  Assert.IsTrue(LFirst.BlendAnim(START + 49, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  // the second one has a weight of one half
  Assert.IsTrue(LSecond.BlendAnim(START + 49, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  Assert.AreEqual(1.5, LWeight, 0.0);
  LExpected := IdleFrame(49, -1);
  LLerp := Single(0.5) / Single(1.5);
  // the short anim is 42 ms long: its time wraps
  FWorld.Model.Skeleton.BlendJoints(LExpected, ShortFrame(49 mod FWorld.Short.Length, -1), LLerp, [0, 1]);
  AssertSamePose(LExpected, LFrame);
end;

procedure TTestAnimBlend.DovrebbeTogliereLOrigineDellaRadice;
var
  LBlend: TAnimBlend;
  LFrame: TArray<TMd5JointQuat>;
  LWeight, LFixed: Single;
  LFlags: TAnimFlags;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  Assert.IsTrue(LBlend.BlendAnim(START + 20, ANIMCHANNEL_ALL, LFrame, LWeight, True, False, False));
  Assert.AreEqual(0.0, LFrame[0].T.X, 0.0);
  Assert.AreEqual(0.0, LFrame[0].T.Y, 0.0);
  Assert.AreEqual(0.0, LFrame[0].T.Z, 0.0);
  Assert.AreEqual(IdleFrame(20, -1)[0].Q.Z, LFrame[0].Q.Z, 0.0);
  // with the movement not allowed the translation stays
  LBlend.SetAllowMovement(False);
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  LBlend.BlendAnim(START + 20, ANIMCHANNEL_ALL, LFrame, LWeight, True, False, False);
  Assert.AreEqual(IdleFrame(20, -1)[0].T.X, LFrame[0].T.X, 0.0);
  // with anim_turn the rotation of the root becomes the fixed one
  LFlags := FWorld.ModelDef.GetAnimByIndex(1).Flags;
  LFlags.AnimTurn := True;
  FWorld.ModelDef.GetAnimByIndex(1).Flags := LFlags;
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  LBlend.BlendAnim(START + 20, ANIMCHANNEL_ALL, LFrame, LWeight, True, False, False);
  LFixed := 0.70710677;
  Assert.AreEqual(-LFixed, LFrame[0].Q.X, 0.0);
  Assert.AreEqual(0.0, LFrame[0].Q.Y, 0.0);
  Assert.AreEqual(LFixed, LFrame[0].Q.W, 0.0);
end;

procedure TTestAnimBlend.DovrebbeMescolareLeAnimSincronizzate;
var
  LBlend: TAnimBlend;
  LFrame, LExpected: TArray<TMd5JointQuat>;
  LWeight, LLerp: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 3, START, 0);
  Assert.AreEqual<Integer>(2, LBlend.NumSyncedAnims);
  Assert.IsTrue(LBlend.SetSyncedAnimWeight(1, 0.5));
  Assert.IsFalse(LBlend.SetSyncedAnimWeight(-1, 0.5));
  Assert.IsFalse(LBlend.SetSyncedAnimWeight(9, 0.5));
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  Assert.IsTrue(LBlend.BlendAnim(START + 30, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  // the first anim has a weight of 1, the second one 0.5: the mix is 0.5 / 1.5 of the second
  LExpected := IdleFrame(30, -1);
  LLerp := Single(0.5) / Single(1.5);
  // the frame of the first md5anim is used for both (ConvertTimeToFrame of anim 0)
  FWorld.Model.Skeleton.BlendJoints(LExpected,
    FWorld.Short.GetInterpolatedFrame(FWorld.Idle.ConvertTimeToFrame(30, -1), nil), LLerp, [0, 1]);
  AssertSamePose(LExpected, LFrame);
end;

procedure TTestAnimBlend.DovrebbeUsareUnSoloFotogrammoDiSetFrame;
var
  LBlend: TAnimBlend;
  LFrame: TArray<TMd5JointQuat>;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.SetFrame(FWorld.ModelDef, 1, 2, START, 0);
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  Assert.IsTrue(LBlend.BlendAnim(START + 500, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  AssertSamePose(FWorld.Idle.GetSingleFrame(1, nil), LFrame);
end;

procedure TTestAnimBlend.DovrebbeNonMescolareUnAnimFinitaOSenzaPeso;
var
  LBlend: TAnimBlend;
  LFrame: TArray<TMd5JointQuat>;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LFrame := Copy(FWorld.Model.DefaultPose);
  LWeight := 0;
  // no anim
  Assert.IsFalse(LBlend.BlendAnim(START, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  // a play that is over, when something is already blended
  LBlend.PlayAnim(FWorld.ModelDef, 1, START, 0);
  LWeight := 0.5;
  Assert.IsFalse(LBlend.BlendAnim(START + 84, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  // a weight of 0, when something is already blended
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  LBlend.BlendStartValue := 0.0;
  LBlend.BlendEndValue := 0.0;
  LWeight := 0.5;
  Assert.IsFalse(LBlend.BlendAnim(START + 10, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
  Assert.AreEqual(0.5, LWeight, 0.0);
  // the anims of a synced anim that all have no weight
  LBlend.CycleAnim(FWorld.ModelDef, 3, START, 0);
  LBlend.AnimWeights[0] := 0.0;
  LWeight := 0;
  Assert.IsFalse(LBlend.BlendAnim(START + 10, ANIMCHANNEL_ALL, LFrame, LWeight, False, False, False));
end;

procedure TTestAnimBlend.DovrebbeSostituireIlPesoConLOverride;
var
  LBlend: TAnimBlend;
  LFrame: TArray<TMd5JointQuat>;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 100);
  LFrame := Copy(FWorld.Model.DefaultPose);
  // the anim weighs 0.5: with the override the previous blend weight becomes 1 - 0.5, and the blend is added to it
  LWeight := 1.0;
  Assert.IsTrue(LBlend.BlendAnim(START + 49, ANIMCHANNEL_ALL, LFrame, LWeight, False, True, False));
  Assert.AreEqual(1.0, LWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeMescolareLOrigine;
var
  LBlend, LOther: TAnimBlend;
  LPos, LExpected: TIdVec3;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, START, 0);
  LPos.Zero;
  LWeight := 0;
  LBlend.BlendOrigin(START + 20, LPos, LWeight, False);
  LExpected := FWorld.Idle.GetOrigin(20, -1);
  Assert.AreEqual(LExpected.X, LPos.X, 0.0);
  Assert.AreEqual(LExpected.Y, LPos.Y, 0.0);
  Assert.AreEqual(LExpected.Z, LPos.Z, 0.0);
  Assert.AreEqual(1.0, LWeight, 0.0);
  // with the origin removed (and the movement allowed) nothing is added
  LWeight := 0;
  LPos.Zero;
  LBlend.BlendOrigin(START + 20, LPos, LWeight, True);
  Assert.AreEqual(0.0, LWeight, 0.0);
  // a second anim is mixed by its weight
  LOther := FWorld.NewBlend;
  LOther.CycleAnim(FWorld.ModelDef, 2, START, 100);
  LWeight := 1.0;
  LPos := LExpected;
  LOther.BlendOrigin(START + 49, LPos, LWeight, False);
  Assert.AreEqual(1.5, LWeight, 0.0);
  // not for a single frame
  LOther.SetFrame(FWorld.ModelDef, 2, 1, START, 0);
  LWeight := 0;
  LOther.BlendOrigin(START + 49, LPos, LWeight, False);
  Assert.AreEqual(0.0, LWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeMescolareLoSpostamento;
var
  LBlend: TAnimBlend;
  LDelta, LFrom, LTo: TIdVec3;
  LWeight: Single;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  LDelta.Zero;
  LWeight := 0;
  LBlend.BlendDelta(10, 60, LDelta, LWeight);
  LFrom := FWorld.Idle.GetOrigin(10, -1);
  LTo := FWorld.Idle.GetOrigin(60, -1);
  Assert.AreEqual(LTo.X - LFrom.X, LDelta.X, 0.0);
  Assert.AreEqual(LTo.Y - LFrom.Y, LDelta.Y, 0.0);
  Assert.AreEqual(LTo.Z - LFrom.Z, LDelta.Z, 0.0);
  Assert.AreEqual(1.0, LWeight, 0.0);
  // when the time wraps the length is added to the end
  LWeight := 0;
  LBlend.BlendDelta(70, 100, LDelta, LWeight);
  LTo := FWorld.Idle.GetOrigin(100 mod 84 + 84, -1);
  LFrom := FWorld.Idle.GetOrigin(70, -1);
  Assert.AreEqual(LTo.X - LFrom.X, LDelta.X, 0.0);
  // without movement allowed nothing is added
  LBlend.SetAllowMovement(False);
  LWeight := 0;
  LBlend.BlendDelta(10, 60, LDelta, LWeight);
  Assert.AreEqual(0.0, LWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeMescolareLaRotazioneDelloSpostamento;
var
  LBlend: TAnimBlend;
  LDelta: TIdQuat;
  LWeight: Single;
  LFlags: TAnimFlags;
  LAnim: IAnim;
  LQuat1, LQuat2, LExpected: TIdQuat;
begin
  LAnim := FWorld.ModelDef.GetAnimByIndex(1);
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  LDelta.SetValues(0, 0, 0, 1);
  LWeight := 0;
  // without anim_turn there is no rotation
  LBlend.BlendDeltaRotation(10, 60, LDelta, LWeight);
  Assert.AreEqual(0.0, LWeight, 0.0);
  LFlags := LAnim.Flags;
  LFlags.AnimTurn := True;
  LAnim.Flags := LFlags;
  LBlend.BlendDeltaRotation(10, 60, LDelta, LWeight);
  Assert.AreEqual(1.0, LWeight, 0.0);
  LQuat1 := FWorld.Idle.GetOriginRotation(10, -1);
  LQuat2 := FWorld.Idle.GetOriginRotation(60, -1);
  LExpected := LQuat1.Inverse * LQuat2;
  Assert.AreEqual(LExpected.X, LDelta.X, 0.0);
  Assert.AreEqual(LExpected.Y, LDelta.Y, 0.0);
  Assert.AreEqual(LExpected.Z, LDelta.Z, 0.0);
  Assert.AreEqual(LExpected.W, LDelta.W, 0.0);
  // a second blend slerps from the first one by its share
  LWeight := 1.0;
  LBlend.BlendDeltaRotation(10, 60, LDelta, LWeight);
  Assert.AreEqual(2.0, LWeight, 0.0);
end;

procedure TTestAnimBlend.DovrebbeAggiungereLeBounds;
var
  LBlend: TAnimBlend;
  LBounds, LAnimBounds: TGeoBounds;
  LOrigin: TIdVec3;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 1, 0, 0);
  LBounds.Clear;
  Assert.IsTrue(LBlend.AddBounds(20, LBounds, False));
  LAnimBounds := FWorld.Idle.GetBounds(20, -1);
  LOrigin := FWorld.Idle.GetOrigin(20, -1);
  LAnimBounds.TranslateSelf(TGeoVec3.Make(LOrigin.X, LOrigin.Y, LOrigin.Z));
  Assert.AreEqual(LAnimBounds.Mins.X, LBounds.Mins.X, 0.0);
  Assert.AreEqual(LAnimBounds.Maxs.Z, LBounds.Maxs.Z, 0.0);
  // with the origin removed the bounds are not moved
  LBounds.Clear;
  Assert.IsTrue(LBlend.AddBounds(20, LBounds, True));
  LAnimBounds := FWorld.Idle.GetBounds(20, -1);
  Assert.AreEqual(LAnimBounds.Mins.X, LBounds.Mins.X, 0.0);
  // over
  LBlend.PlayAnim(FWorld.ModelDef, 1, 0, 0);
  Assert.IsFalse(LBlend.AddBounds(90, LBounds, True));
  // no weight
  LBlend.SetWeight(0.0, 0, 0);
  Assert.IsFalse(LBlend.AddBounds(10, LBounds, True));
  // no anim
  LBlend.Reset(FWorld.ModelDef);
  Assert.IsFalse(LBlend.AddBounds(10, LBounds, True));
end;

procedure TTestAnimBlend.DovrebbeDareNomiELunghezze;
var
  LBlend: TAnimBlend;
  LLength: Integer;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 2, START, 0);
  Assert.AreEqual('short', string(LBlend.AnimName));
  Assert.AreEqual<Integer>(2, LBlend.NumFrames);
  Assert.AreEqual<Integer>(FWorld.Short.Length, LBlend.Length);
  LLength := FWorld.Short.Length;
  Assert.AreEqual<Integer>(42, LLength);
  LBlend.SetPlaybackRate(START + 40, 2.0);
  Assert.AreEqual(2.0, LBlend.GetPlaybackRate, 0.0);
  // the offset keeps the time where it was: 40 - 40 * 2 = -40
  Assert.AreEqual<Integer>(-40, LBlend.TimeOffset);
  Assert.AreEqual<Integer>(40, LBlend.AnimTime(START + 40));
  // then it runs twice as fast: 20 ms later it is at 40 + 40 = 80, wrapped in the length
  Assert.AreEqual<Integer>(80 mod LLength, LBlend.AnimTime(START + 60));
  // the same rate changes nothing
  LBlend.SetPlaybackRate(START + 60, 2.0);
  Assert.AreEqual<Integer>(-40, LBlend.TimeOffset);
  // back to 1: the offset is the time minus the elapsed time
  LBlend.SetPlaybackRate(START + 60, 1.0);
  Assert.AreEqual<Integer>(80 mod LLength - 60, LBlend.TimeOffset);
end;

procedure TTestAnimBlend.DovrebbeImpostarePesiDelleAnimSincronizzate;
var
  LBlend: TAnimBlend;
begin
  LBlend := FWorld.NewBlend;
  LBlend.CycleAnim(FWorld.ModelDef, 3, START, 0);
  Assert.IsTrue(LBlend.SetSyncedAnimWeight(0, 0.25));
  Assert.AreEqual(0.25, LBlend.AnimWeights[0], 0.0);
  Assert.IsTrue(LBlend.SetSyncedAnimWeight(1, 0.75));
  Assert.AreEqual(0.75, LBlend.AnimWeights[1], 0.0);
end;

end.
