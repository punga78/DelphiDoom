{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TAnimator (idAnimator) (DUnitX)                        }
{                                                                              }
{  The numbers are worked out from the text of Anim_Blend.cpp; the poses are   }
{  compared with the functions of idMD5Anim and of the skeleton that already   }
{  have their parity with the C++ (Tests\Data\Models\md5).                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Animator;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.MathCore.Float.Quat, DelphiDoom.MathCore.Float.Conversions, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Md5.Types, DelphiDoom.Models.Md5.JointQuat, DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types, DelphiDoom.Models.Anim.Intf, DelphiDoom.Models.Anim.Blend.Types,
  DelphiDoom.Models.Anim.Blend, DelphiDoom.Models.Anim.Animator, DelphiDoom.Tests.Models.AnimatorSupport;

type
  [TestFixture]
  [Category('models')]
  TTestAnimator = class(TObject)
  strict private
    FWorld: TAnimatorWorld;
    FAnimator: TAnimator;
    FEntity: TFakeAnimatorEntity;
    FEntityIntf: IAnimatorEntity;
    function IdleFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
    procedure AssertJoints(const AExpected: TArray<TMd5JointMat>);
    procedure AssertVec(const AExpected, AActual: TIdVec3; const ATolerance: Single = 0.0);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireConLaPoseDiDefault;
    [Test]
    procedure DovrebbeSvuotarsiSenzaModello;
    [Test]
    procedure DovrebbeRifiutareUnCanaleFuoriIntervallo;
    [Test]
    procedure DovrebbeCreareIlFrameDallaPoseDellAnim;
    [Test]
    procedure DovrebbeNonRifareIlFrameNelloStessoTempo;
    [Test]
    procedure DovrebbeNonCreareIlFrameQuandoNonSiAnimaPiu;
    [Test]
    procedure DovrebbeSaltareIlFrameInCinematica;
    [Test]
    procedure DovrebbeMescolareUnCanaleSullaPosaDiDefault;
    [Test]
    procedure DovrebbeSpingereLeAnimInCanale;
    [Test]
    procedure DovrebbeSincronizzareICanali;
    [Test]
    procedure DovrebbeAvvisareLEntity;
    [Test]
    procedure DovrebbeServireLeAnimEFermarsi;
    [Test]
    procedure DovrebbeModificareIGiunti;
    [Test]
    procedure DovrebbeModificareLaRotazioneDeiGiunti;
    [Test]
    procedure DovrebbeToglierePerGiuntoEPerTutti;
    [Test]
    procedure DovrebbeDareOrigineSpostamentoEBounds;
    [Test]
    procedure DovrebbeDareLeBoundsDelFrameSenzaAnim;
    [Test]
    procedure DovrebbeDareLeTrasformazioniDeiGiunti;
    [Test]
    procedure DovrebbeDareGiuntiECanali;
    [Test]
    procedure DovrebbeDareLeProprietaDelleAnim;
    [Test]
    procedure DovrebbeUsareLaPoseDellaFiguraArticolata;
    [Test]
    procedure DovrebbeDireSeIlFrameCambia;
    [Test]
    procedure DovrebbeMescolareLeRotazioniDelloSpostamento;
    [Test]
    procedure DovrebbeFermareTutteLeAnim;
  end;

implementation

const
  OFFSET_TIME = 20;

{ TTestAnimator }

procedure TTestAnimator.Setup;
begin
  FWorld := TAnimatorWorld.Create;
  FAnimator := FWorld.NewAnimator;
  FEntity := TFakeAnimatorEntity.Create;
  FEntityIntf := FEntity;
end;

procedure TTestAnimator.TearDown;
begin
  FAnimator.SetEntity(nil);
  FAnimator.Free;
  FEntityIntf := nil;
  FWorld.Free;
end;

function TTestAnimator.IdleFrame(const ATime, ACycle: Integer): TArray<TMd5JointQuat>;
begin
  Result := FWorld.Idle.GetInterpolatedFrame(FWorld.Idle.ConvertTimeToFrame(ATime, ACycle), nil);
end;

procedure TTestAnimator.AssertJoints(const AExpected: TArray<TMd5JointMat>);
var
  LJoint, LItem: Integer;
begin
  Assert.AreEqual<Integer>(Length(AExpected), FAnimator.NumJoints);
  for LJoint := 0 to High(AExpected) do
    for LItem := 0 to 11 do
      Assert.AreEqual(AExpected[LJoint].M[LItem], FAnimator.Joints[LJoint].M[LItem], 0.0,
        Format('joint %d item %d', [LJoint, LItem]));
end;

procedure TTestAnimator.AssertVec(const AExpected, AActual: TIdVec3; const ATolerance: Single);
begin
  Assert.AreEqual(AExpected.X, AActual.X, ATolerance, 'x');
  Assert.AreEqual(AExpected.Y, AActual.Y, ATolerance, 'y');
  Assert.AreEqual(AExpected.Z, AActual.Z, ATolerance, 'z');
end;

procedure TTestAnimator.DovrebbePartireConLaPoseDiDefault;
var
  LBounds: TGeoBounds;
  LJoints: TArray<TMd5JointMat>;
begin
  Assert.AreEqual<Integer>(2, FAnimator.NumJoints);
  LJoints := FWorld.ModelDef.SetupJoints(False, LBounds);
  AssertJoints(LJoints);
  Assert.AreEqual<Integer>(4, FAnimator.NumAnims);
  Assert.IsNotNull(FAnimator.ModelDef);
  Assert.IsTrue(FAnimator.HasAnim('idle'));
  Assert.IsFalse(FAnimator.HasAnim('unknown'));
  Assert.AreEqual<Integer>(1, FAnimator.GetAnim('idle1', nil));
  Assert.AreEqual('idle1', string(FAnimator.GetAnim(1).FullName));
  Assert.AreEqual<Integer>(2, Length(FAnimator.GetJointList('origin arm')));
  Assert.IsFalse(FAnimator.RemoveOrigin);
  FAnimator.SetRemoveOriginOffset(True);
  Assert.IsTrue(FAnimator.RemoveOrigin);
end;

procedure TTestAnimator.DovrebbeSvuotarsiSenzaModello;
var
  LBounds: TGeoBounds;
  LPos: TIdVec3;
begin
  Assert.IsFalse(FAnimator.SetModelDef(nil));
  Assert.AreEqual<Integer>(0, FAnimator.NumJoints);
  Assert.AreEqual<Integer>(0, FAnimator.NumAnims);
  Assert.IsNull(FAnimator.ModelDef);
  Assert.IsNull(FAnimator.GetAnim(1));
  Assert.AreEqual<Integer>(0, FAnimator.GetAnim('idle1', nil));
  Assert.IsFalse(FAnimator.HasAnim('idle'));
  Assert.AreEqual<Integer>(0, Length(FAnimator.GetJointList('origin')));
  Assert.IsFalse(FAnimator.CreateFrame(0, True));
  Assert.IsFalse(FAnimator.GetBounds(0, LBounds));
  Assert.IsFalse(FAnimator.IsAnimating(0));
  Assert.IsFalse(FAnimator.FrameHasChanged(0));
  FAnimator.GetOrigin(0, LPos);
  Assert.AreEqual(0.0, LPos.Length, 0.0);
  Assert.AreEqual<Integer>(MD5_INVALID_JOINT, FAnimator.GetJointHandle('arm'));
  Assert.AreEqual('', string(FAnimator.GetJointName(0)));
  Assert.AreEqual<Integer>(MD5_INVALID_JOINT, FAnimator.GetFirstChild(0));
  Assert.WillRaise(
    procedure
    begin
      FAnimator.GetChannelForJoint(0);
    end, EAnimException);
  // nothing happens
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.SetJointPos(0, jmLocal, LPos);
  FAnimator.InitAfPose;
  FAnimator.FinishAfPose(1, LBounds, 0);
  Assert.AreEqual<Integer>(0, FAnimator.NumFrames(1));
  Assert.AreEqual('', string(FAnimator.AnimName(1)));
  Assert.AreEqual('', string(FAnimator.AnimFullName(1)));
  Assert.AreEqual<Integer>(0, FAnimator.AnimLength(1));
  Assert.AreEqual<Integer>(0, FAnimator.NumSyncedAnims(1));
  Assert.AreEqual(0.0, FAnimator.TotalMovementDelta(1).Length, 0.0);
  Assert.IsFalse(FAnimator.GetAnimFlags(1).AnimTurn);
end;

procedure TTestAnimator.DovrebbeRifiutareUnCanaleFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      FAnimator.CurrentAnim(5);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.Clear(-1, 0, 0);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.PlayAnim(5, 1, 0, 0);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.CycleAnim(-1, 1, 0, 0);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.SetFrame(9, 1, 1, 0, 0);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.SyncAnimChannels(0, 9, 0, 0);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      FAnimator.ChannelAnim(0, 3);
    end, EAnimException);
end;

procedure TTestAnimator.DovrebbeCreareIlFrameDallaPoseDellAnim;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, False));
  AssertJoints(FWorld.Absolute(IdleFrame(OFFSET_TIME, -1)));
end;

procedure TTestAnimator.DovrebbeNonRifareIlFrameNelloStessoTempo;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, False));
  Assert.IsFalse(FAnimator.CreateFrame(OFFSET_TIME, False));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME + 5, False));
  // r_showSkel forces it
  FAnimator.ShowSkeleton := 1;
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME + 5, False));
end;

procedure TTestAnimator.DovrebbeNonCreareIlFrameQuandoNonSiAnimaPiu;
begin
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(10, False));
  // the play ended at 83
  Assert.IsFalse(FAnimator.IsAnimating(100));
  Assert.IsFalse(FAnimator.CreateFrame(100, False));
  // once the animator has been told it stopped it makes one more frame
  FAnimator.ServiceAnims(10, 100);
  Assert.IsTrue(FAnimator.CreateFrame(100, False));
end;

procedure TTestAnimator.DovrebbeSaltareIlFrameInCinematica;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.SkipCinematic := True;
  Assert.IsFalse(FAnimator.CreateFrame(OFFSET_TIME, True));
  FAnimator.SkipCinematic := False;
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
end;

procedure TTestAnimator.DovrebbeMescolareUnCanaleSullaPosaDiDefault;
var
  LExpected: TArray<TMd5JointQuat>;
begin
  // the joint 1 is on the legs, the joint 0 stays on "all"
  FWorld.ModelDefObject.SetChannelJoints(ANIMCHANNEL_ALL, [0]);
  FWorld.ModelDefObject.SetChannelJoints(ANIMCHANNEL_LEGS, [1]);
  FWorld.ModelDefObject.SetJointChannel(1, ANIMCHANNEL_LEGS);
  FAnimator.CycleAnim(ANIMCHANNEL_LEGS, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, False));
  LExpected := Copy(FWorld.Model.DefaultPose);
  LExpected[1] := IdleFrame(OFFSET_TIME, -1)[1];
  AssertJoints(FWorld.Absolute(LExpected));
  Assert.AreEqual<Integer>(ANIMCHANNEL_LEGS, FAnimator.GetChannelForJoint(1));
  // the eyelids blend over the previous ones
  FWorld.ModelDefObject.SetChannelJoints(ANIMCHANNEL_EYELIDS, [1]);
  FWorld.ModelDefObject.SetChannelJoints(ANIMCHANNEL_LEGS, []);
  FAnimator.Clear(ANIMCHANNEL_LEGS, OFFSET_TIME, 0);
  FAnimator.CycleAnim(ANIMCHANNEL_EYELIDS, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME + 1, False));
  LExpected := Copy(FWorld.Model.DefaultPose);
  LExpected[1] := IdleFrame(OFFSET_TIME + 1, -1)[1];
  AssertJoints(FWorld.Absolute(LExpected));
end;

procedure TTestAnimator.DovrebbeSpingereLeAnimInCanale;
begin
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  // the second anim pushes the first one, which fades out: it ends 40 ms after the time of the push
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 2, 50, 40);
  Assert.AreEqual<Integer>(2, FAnimator.CurrentAnim(ANIMCHANNEL_ALL)^.GetAnimNum);
  Assert.AreEqual<Integer>(1, FAnimator.ChannelAnim(ANIMCHANNEL_ALL, 1)^.GetAnimNum);
  Assert.AreEqual<Integer>(90, FAnimator.ChannelAnim(ANIMCHANNEL_ALL, 1)^.GetEndTime);
  Assert.AreEqual<Integer>(0, FAnimator.ChannelAnim(ANIMCHANNEL_ALL, 2)^.GetAnimNum);
  // a push of an anim that has just started does not move the others
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 3, 50, 40);
  Assert.AreEqual<Integer>(3, FAnimator.CurrentAnim(ANIMCHANNEL_ALL)^.GetAnimNum);
  Assert.AreEqual<Integer>(1, FAnimator.ChannelAnim(ANIMCHANNEL_ALL, 1)^.GetAnimNum);
  // an anim that does not exist changes nothing
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 99, 80, 40);
  Assert.AreEqual<Integer>(3, FAnimator.CurrentAnim(ANIMCHANNEL_ALL)^.GetAnimNum);
  FAnimator.SetFrame(ANIMCHANNEL_TORSO, 1, 2, 80, 0);
  Assert.AreEqual<Integer>(2, FAnimator.CurrentAnim(ANIMCHANNEL_TORSO)^.Frame);
end;

procedure TTestAnimator.DovrebbeSincronizzareICanali;
var
  LTorso, LLegs: PAnimBlend;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_TORSO, 1, 100, 0);
  FAnimator.SyncAnimChannels(ANIMCHANNEL_LEGS, ANIMCHANNEL_TORSO, 110, 30);
  LTorso := FAnimator.CurrentAnim(ANIMCHANNEL_TORSO);
  LLegs := FAnimator.CurrentAnim(ANIMCHANNEL_LEGS);
  Assert.AreEqual<Integer>(1, LLegs^.GetAnimNum);
  Assert.AreEqual<Integer>(LTorso^.GetStartTime, LLegs^.GetStartTime);
  Assert.AreEqual(LTorso^.GetFinalWeight, LLegs^.GetFinalWeight, 0.0);
  // the frame commands of the copy are disabled
  Assert.IsFalse(LLegs^.AllowFrameCommands);
  Assert.IsTrue(LTorso^.AllowFrameCommands);
  // the same again does not push
  FAnimator.SyncAnimChannels(ANIMCHANNEL_LEGS, ANIMCHANNEL_TORSO, 120, 30);
  Assert.AreEqual<Integer>(0, FAnimator.ChannelAnim(ANIMCHANNEL_LEGS, 1)^.GetAnimNum);
end;

procedure TTestAnimator.DovrebbeAvvisareLEntity;
begin
  FAnimator.SetEntity(FEntityIntf);
  Assert.IsTrue(FAnimator.GetEntity = FEntityIntf);
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.CycleAnim(ANIMCHANNEL_TORSO, 1, 0, 0);
  FAnimator.SetFrame(ANIMCHANNEL_LEGS, 1, 1, 0, 0);
  FAnimator.SyncAnimChannels(ANIMCHANNEL_HEAD, ANIMCHANNEL_TORSO, 0, 0);
  FAnimator.SetJointPos(1, jmLocal, TIdVec3.Create(1, 2, 3));
  FAnimator.SetJointAxis(1, jmLocal, TIdMat3.Identity);
  Assert.AreEqual('active:4 active:4 active:4 active:4 active:4 active:4', FEntity.Joined);
  FEntity.Events.Clear;
  // a new model stops the animation of the entity
  FAnimator.SetModelDef(nil);
  Assert.AreEqual('inactive:4', FEntity.Joined);
end;

procedure TTestAnimator.DovrebbeServireLeAnimEFermarsi;
var
  LCommand: TAnimFrameCommand;
begin
  LCommand.CommandType := fcJump;
  LCommand.Text := '';
  LCommand.HasText := False;
  LCommand.Index := 0;
  FWorld.ModelDef.GetAnimByIndex(1).AddFrameCommand(1, LCommand);
  FAnimator.SetEntity(FEntityIntf);
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FEntity.Events.Clear;
  FAnimator.ServiceAnims(0, 50);
  Assert.AreEqual(Format('cmd:idle1:1:%d', [Ord(fcJump)]), FEntity.Joined);
  FEntity.Events.Clear;
  // the anim is over: the entity stops animating and updates its visuals once more
  FAnimator.ServiceAnims(50, 100);
  Assert.AreEqual('inactive:4 active:8', FEntity.Joined);
  // the animator is not left with commands to run
  Assert.IsFalse(FAnimator.IsAnimating(100));
end;

procedure TTestAnimator.DovrebbeModificareIGiunti;
var
  LExpected: TArray<TMd5JointMat>;
  LPos: TIdVec3;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.CreateFrame(OFFSET_TIME, True);
  LExpected := Copy(FAnimator.Joints);
  // the position of joint 1 in the model space
  FAnimator.SetJointPos(1, jmWorldOverride, TIdVec3.Create(5, 6, 7));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, False));
  AssertVec(TIdVec3.Create(5, 6, 7), FAnimator.Joints[1].ToVec3);
  AssertVec(LExpected[0].ToVec3, FAnimator.Joints[0].ToVec3);
  // a joint mod of the root moves it, in its own space
  FAnimator.SetJointPos(0, jmLocal, TIdVec3.Create(1, 0, 0));
  FAnimator.CreateFrame(OFFSET_TIME, True);
  LPos := LExpected[0].ToVec3;
  LPos.X := LPos.X + 1;
  AssertVec(LPos, FAnimator.Joints[0].ToVec3);
  FAnimator.SetJointPos(0, jmWorldOverride, TIdVec3.Create(9, 9, 9));
  FAnimator.CreateFrame(OFFSET_TIME, True);
  AssertVec(TIdVec3.Create(9, 9, 9), FAnimator.Joints[0].ToVec3);
  FAnimator.SetJointPos(0, jmLocalOverride, TIdVec3.Create(8, 8, 8));
  FAnimator.CreateFrame(OFFSET_TIME, True);
  AssertVec(TIdVec3.Create(8, 8, 8), FAnimator.Joints[0].ToVec3);
  // the other modes for a child
  FAnimator.SetJointPos(1, jmLocal, TIdVec3.Create(1, 0, 0));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  FAnimator.SetJointPos(1, jmLocalOverride, TIdVec3.Create(1, 0, 0));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  FAnimator.SetJointPos(1, jmWorld, TIdVec3.Create(1, 0, 0));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  FAnimator.SetJointPos(1, jmNone, TIdVec3.Create(1, 0, 0));
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  // a joint that does not exist is ignored
  FAnimator.SetJointPos(7, jmLocal, LPos);
  FAnimator.SetJointPos(-1, jmLocal, LPos);
end;

procedure TTestAnimator.DovrebbeModificareLaRotazioneDeiGiunti;
var
  LMatrix: TIdMat3;
  LRotation: TIdMat3;
  LMode: TAnimJointModTransform;
begin
  // a rotation of 90 degrees around z
  LMatrix := TIdMat3.Create(0, 1, 0, -1, 0, 0, 0, 0, 1);
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.SetJointAxis(1, jmWorldOverride, LMatrix);
  Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  LRotation := FAnimator.Joints[1].ToMat3;
  Assert.IsTrue(LRotation = LMatrix);
  FAnimator.SetJointAxis(0, jmWorldOverride, LMatrix);
  FAnimator.CreateFrame(OFFSET_TIME, True);
  Assert.IsTrue(FAnimator.Joints[0].ToMat3 = LMatrix);
  for LMode := Low(TAnimJointModTransform) to High(TAnimJointModTransform) do
  begin
    FAnimator.SetJointAxis(0, LMode, LMatrix);
    FAnimator.SetJointAxis(1, LMode, LMatrix);
    Assert.IsTrue(FAnimator.CreateFrame(OFFSET_TIME, True));
  end;
  // a local override of the root takes the matrix as it is
  FAnimator.SetJointAxis(0, jmLocalOverride, LMatrix);
  FAnimator.CreateFrame(OFFSET_TIME, True);
  Assert.IsTrue(FAnimator.Joints[0].ToMat3 = LMatrix);
end;

procedure TTestAnimator.DovrebbeToglierePerGiuntoEPerTutti;
begin
  // only joint mods, no anim: the frame is made from the default pose
  FAnimator.SetJointPos(1, jmWorldOverride, TIdVec3.Create(5, 6, 7));
  Assert.IsTrue(FAnimator.CreateFrame(0, True));
  FAnimator.ClearJoint(0);
  Assert.IsTrue(FAnimator.CreateFrame(0, True));
  FAnimator.ClearJoint(1);
  // no anim and no joint mod: nothing to do
  Assert.IsFalse(FAnimator.CreateFrame(0, True));
  FAnimator.SetJointPos(1, jmLocal, TIdVec3.Create(1, 1, 1));
  FAnimator.SetJointPos(0, jmLocal, TIdVec3.Create(1, 1, 1));
  FAnimator.ClearAllJoints;
  Assert.IsFalse(FAnimator.CreateFrame(0, True));
  FAnimator.ClearAllJoints;
  FAnimator.ClearJoint(-1);
end;

procedure TTestAnimator.DovrebbeDareOrigineSpostamentoEBounds;
var
  LPos, LFrom, LTo, LDelta: TIdVec3;
  LBounds, LExpected: TGeoBounds;
  LRotation: TIdMat3;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.GetOrigin(OFFSET_TIME, LPos);
  AssertVec(FWorld.Idle.GetOrigin(OFFSET_TIME, -1), LPos);
  // the origin is removed: it is not added
  FAnimator.SetRemoveOriginOffset(True);
  FAnimator.GetOrigin(OFFSET_TIME, LPos);
  Assert.AreEqual(0.0, LPos.Length, 0.0);
  FAnimator.SetRemoveOriginOffset(False);
  FAnimator.GetDelta(10, 60, LDelta);
  LFrom := FWorld.Idle.GetOrigin(10, -1);
  LTo := FWorld.Idle.GetOrigin(60, -1);
  AssertVec(LTo - LFrom, LDelta);
  FAnimator.GetDelta(10, 10, LDelta);
  Assert.AreEqual(0.0, LDelta.Length, 0.0);
  Assert.IsFalse(FAnimator.GetDeltaRotation(10, 60, LRotation));
  Assert.IsTrue(LRotation = TIdMat3.Identity);
  Assert.IsFalse(FAnimator.GetDeltaRotation(10, 10, LRotation));
  Assert.IsTrue(FAnimator.GetBounds(OFFSET_TIME, LBounds));
  LExpected := FWorld.Idle.GetBounds(OFFSET_TIME, -1);
  LFrom := FWorld.Idle.GetOrigin(OFFSET_TIME, -1);
  LExpected.TranslateSelf(TGeoVec3.Make(LFrom.X, LFrom.Y, LFrom.Z));
  Assert.AreEqual(LExpected.Mins.X, LBounds.Mins.X, 0.0);
  Assert.AreEqual(LExpected.Maxs.Y, LBounds.Maxs.Y, 0.0);
  // the bounds are kept as the frame bounds, with a warning if they are too big
  FAnimator.DebugBounds := True;
  FAnimator.GetBounds(OFFSET_TIME, LBounds);
  Assert.AreEqual<Integer>(0, FWorld.Log.Count);
end;

procedure TTestAnimator.DovrebbeDareLeBoundsDelFrameSenzaAnim;
var
  LBounds, LModelBounds: TGeoBounds;
  LJoints: TArray<TMd5JointMat>;
begin
  LJoints := FWorld.ModelDef.SetupJoints(False, LModelBounds);
  Assert.AreEqual(2, Length(LJoints));
  Assert.IsTrue(FAnimator.GetBounds(0, LBounds));
  Assert.AreEqual(LModelBounds.Mins.X, LBounds.Mins.X, 0.0);
  Assert.AreEqual(LModelBounds.Maxs.Z, LBounds.Maxs.Z, 0.0);
end;

procedure TTestAnimator.DovrebbeDareLeTrasformazioniDeiGiunti;
var
  LOffset: TIdVec3;
  LAxis: TIdMat3;
  LRelative: TArray<TMd5JointQuat>;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.GetJointTransform(1, OFFSET_TIME, LOffset, LAxis));
  AssertVec(FAnimator.Joints[1].ToVec3, LOffset);
  Assert.IsFalse(FAnimator.GetJointTransform(2, OFFSET_TIME, LOffset, LAxis));
  Assert.IsFalse(FAnimator.GetJointTransform(-1, OFFSET_TIME, LOffset, LAxis));
  // the local transform of a child is its pose relative to the parent
  LRelative := IdleFrame(OFFSET_TIME, -1);
  Assert.IsTrue(FAnimator.GetJointLocalTransform(1, OFFSET_TIME, LOffset, LAxis));
  AssertVec(LRelative[1].T, LOffset, 0.001);
  // the root has the world transform
  Assert.IsTrue(FAnimator.GetJointLocalTransform(0, OFFSET_TIME, LOffset, LAxis));
  AssertVec(FAnimator.Joints[0].ToVec3, LOffset);
  Assert.IsFalse(FAnimator.GetJointLocalTransform(5, OFFSET_TIME, LOffset, LAxis));
end;

procedure TTestAnimator.DovrebbeDareGiuntiECanali;
begin
  Assert.AreEqual<Integer>(0, FAnimator.GetJointHandle('origin'));
  Assert.AreEqual<Integer>(1, FAnimator.GetJointHandle('arm'));
  Assert.AreEqual<Integer>(MD5_INVALID_JOINT, FAnimator.GetJointHandle('leg'));
  Assert.AreEqual('arm', string(FAnimator.GetJointName(1)));
  Assert.AreEqual<Integer>(1, FAnimator.GetFirstChild(0));
  // a joint with no children is its own first child
  Assert.AreEqual<Integer>(1, FAnimator.GetFirstChild(1));
  Assert.AreEqual<Integer>(1, FAnimator.GetFirstChild('origin'));
  Assert.AreEqual<Integer>(ANIMCHANNEL_ALL, FAnimator.GetChannelForJoint(1));
  Assert.WillRaise(
    procedure
    begin
      FAnimator.GetChannelForJoint(7);
    end, EAnimException);
end;

procedure TTestAnimator.DovrebbeDareLeProprietaDelleAnim;
var
  LFlags: TAnimFlags;
begin
  Assert.AreEqual<Integer>(3, FAnimator.NumFrames(1));
  Assert.AreEqual<Integer>(2, FAnimator.NumFrames(2));
  Assert.AreEqual('idle', string(FAnimator.AnimName(1)));
  Assert.AreEqual('short1', string(FAnimator.AnimFullName(2)));
  Assert.AreEqual<Integer>(84, FAnimator.AnimLength(1));
  Assert.AreEqual<Integer>(2, FAnimator.NumSyncedAnims(3));
  AssertVec(FWorld.Idle.TotalMovementDelta, FAnimator.TotalMovementDelta(1));
  LFlags := FAnimator.GetAnimFlags(1);
  Assert.IsFalse(LFlags.RandomCycleStart);
  Assert.AreEqual<Integer>(0, FAnimator.NumFrames(9));
  Assert.AreEqual(0.0, FAnimator.TotalMovementDelta(9).Length, 0.0);
end;

procedure TTestAnimator.DovrebbeUsareLaPoseDellaFiguraArticolata;
var
  LBounds: TGeoBounds;
begin
  LBounds := TGeoBounds.Make(TGeoVec3.Make(-1, -1, -1), TGeoVec3.Make(1, 1, 1));
  FAnimator.InitAfPose;
  FAnimator.SetAfPoseJointMod(0, afBoth, TIdMat3.Identity, TIdVec3.Create(5, 6, 7));
  FAnimator.SetAfPoseJointMod(1, afAxis, TIdMat3.Identity, TIdVec3.Create(0, 0, 0));
  // the same joint again does not add it twice
  FAnimator.SetAfPoseJointMod(1, afOrigin, TIdMat3.Identity, TIdVec3.Create(1, 2, 3));
  FAnimator.FinishAfPose(1, LBounds, 100);
  Assert.IsTrue(FAnimator.IsAnimating(100));
  Assert.IsFalse(FAnimator.IsAnimating(101));
  Assert.IsTrue(FAnimator.FrameHasChanged(50));
  Assert.IsTrue(FAnimator.CreateFrame(50, True));
  AssertVec(TIdVec3.Create(5, 6, 7), FAnimator.Joints[0].ToVec3);
  // the bounds of the pose are the bounds of the animator
  Assert.IsTrue(FAnimator.GetBounds(50, LBounds));
  Assert.AreEqual(-1.0, LBounds.Mins.X, 0.0);
  // the weight of the pose mixes it into the animations
  FAnimator.SetAfPoseBlendWeight(0.5);
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.CreateFrame(60, True));
  FAnimator.ClearAfPose;
  FAnimator.ClearAllAnims(60, 0);
  Assert.IsFalse(FAnimator.IsAnimating(50));
  // a pose of an anim that does not exist, or with another number of joints, is ignored
  FAnimator.FinishAfPose(9, LBounds, 0);
  FAnimator.FinishAfPose(0, LBounds, 0);
end;

procedure TTestAnimator.DovrebbeDireSeIlFrameCambia;
begin
  Assert.IsFalse(FAnimator.FrameHasChanged(0));
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.FrameHasChanged(5));
  FAnimator.PlayAnim(ANIMCHANNEL_ALL, 2, 0, 0);
  Assert.IsFalse(FAnimator.FrameHasChanged(100));
  // an update that was forced counts while the model animates
  FAnimator.ForceUpdate;
  Assert.IsFalse(FAnimator.FrameHasChanged(100));
  FAnimator.CycleAnim(ANIMCHANNEL_TORSO, 1, 0, 0);
  FAnimator.ForceUpdate;
  Assert.IsTrue(FAnimator.FrameHasChanged(100));
  FAnimator.ClearForceUpdate;
end;

procedure TTestAnimator.DovrebbeMescolareLeRotazioniDelloSpostamento;
var
  LRotation, LExpected: TIdMat3;
  LQuat: TIdQuat;
  LFlags: TAnimFlags;
  LAnim: IAnim;
begin
  LAnim := FWorld.ModelDef.GetAnimByIndex(1);
  LFlags := LAnim.Flags;
  LFlags.AnimTurn := True;
  LAnim.Flags := LFlags;
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  Assert.IsTrue(FAnimator.GetDeltaRotation(10, 60, LRotation));
  LQuat := FWorld.Idle.GetOriginRotation(10, -1).Inverse * FWorld.Idle.GetOriginRotation(60, -1);
  LExpected := TIdRotationConversions.QuatToMat(LQuat);
  Assert.IsTrue(LRotation = LExpected);
end;

procedure TTestAnimator.DovrebbeFermareTutteLeAnim;
begin
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  FAnimator.CycleAnim(ANIMCHANNEL_TORSO, 1, 0, 0);
  Assert.IsTrue(FAnimator.IsAnimating(100));
  FAnimator.ClearAllAnims(100, 0);
  Assert.IsFalse(FAnimator.IsAnimating(100));
  Assert.AreEqual<Integer>(0, FAnimator.CurrentAnim(ANIMCHANNEL_ALL)^.GetAnimNum);
  FAnimator.CycleAnim(ANIMCHANNEL_ALL, 1, 0, 0);
  // with a time the anims fade out
  FAnimator.ClearAllAnims(100, 50);
  Assert.IsTrue(FAnimator.IsAnimating(120));
  Assert.IsFalse(FAnimator.IsAnimating(150));
end;

end.
