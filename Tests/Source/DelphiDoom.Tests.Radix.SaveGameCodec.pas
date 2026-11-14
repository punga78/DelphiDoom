{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixSaveGameCodec and of the state that              }
{  TRadixTriggerLogic gives to a saved game                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.SaveGameCodec;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.SaveGame.Types,
  DelphiDoom.Radix.SaveGame.Codec, DelphiDoom.Radix.TriggerLogic;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixSaveGameCodec = class(TObject)
  strict private
    function SampleState: TRadixSaveState;
    procedure AssertDecodeRaises(const ABytes: TBytes; const AExpectedPart: string);
  public
    [Test]
    procedure IRecordDelFileDovrebberoAvereLaDimensioneFissata;
    [Test]
    procedure DovrebbeRidareLoStatoDopoAndataERitorno;
    [Test]
    procedure DovrebbeScrivereMagiaEVersioneInTesta;
    [Test]
    procedure UnoStatoVuotoDovrebbeEssereLaSolaIntestazione;
    [Test]
    procedure DovrebbeRifiutareGiocatoriEPartiDiLivelloInNumeroDiverso;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaMagia;
    [Test]
    procedure DovrebbeRifiutareUnAltraVersione;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncatoOConBytesInPiu;
    [Test]
    procedure DovrebbeRifiutareUnConteggioNegativo;
    [Test]
    procedure LeImpronteDovrebberoCambiareSoloNellaParteCambiata;
    [Test]
    procedure LaLogicaDovrebbeRidareIlSuoStatoDopoUnRipristino;
    [Test]
    procedure LaLogicaDovrebbeRifiutareLoStatoDiUnAltroLivello;
  end;

implementation

{ TTestRadixSaveGameCodec }

function TTestRadixSaveGameCodec.SampleState: TRadixSaveState;
var
  LIndex: Integer;
begin
  Result := Default(TRadixSaveState);
  Result.Episode := 1;
  Result.Map := 3;
  Result.NamedLevel := 5;
  Result.RandomIndexes[0] := 11;
  Result.RandomIndexes[1] := 222;
  Result.RandomIndexes[2] := 33;
  Result.RandomIndexes[3] := 44;
  SetLength(Result.Players, 2);
  SetLength(Result.LevelPlayers, 2);
  SetLength(Result.LastTriggers, 2);
  Result.Players[0].Energy := 77;
  Result.Players[0].EnergyReserve := 3;
  Result.Players[0].Threat := 1;
  Result.Players[0].PlasmaBombDown := 1;
  Result.Players[0].ThrustMomZ := -65536;
  for LIndex := 0 to RADIX_SAVE_POWERUPS - 1 do
    Result.Players[0].Powers[LIndex] := 100 + LIndex;
  Result.Players[0].PlasmaBombs := 4;
  Result.Players[0].NeutronCannonLevel := 2;
  Result.Players[0].WeaponFlags := $80000001;
  for LIndex := 0 to RADIX_SAVE_WEAPONS - 1 do
    Result.Players[0].LastFire[LIndex] := 1000 + LIndex;
  Result.Players[1].Energy := 100;
  Result.LevelPlayers[0].HasBody := 1;
  Result.LevelPlayers[0].SecondaryObjective := 1;
  for LIndex := 0 to RADIX_SAVE_MESSAGES - 1 do
    Result.LevelPlayers[0].MessageTime[LIndex] := 35 * LIndex;
  Result.LevelPlayers[0].TranspoTargetAngle := $C0000000;
  Result.LevelPlayers[0].TranspoTics := 12;
  Result.LastTriggers[0] := 7;
  Result.LastTriggers[1] := -1;
  SetLength(Result.Actions, 3);
  Result.Actions[1].Enabled := 1;
  Result.Actions[1].ActionType := 13;
  Result.Actions[1].Suspend := 1;
  Result.Actions[1].Params[0] := -5;
  Result.Actions[1].Params[RADIX_MAX_ACTION_PARAMS - 1] := 321;
  SetLength(Result.Triggers, 2);
  Result.Triggers[1].Suspended := 1;
  Result.Triggers[1].NumActions := 1;
  Result.Triggers[1].Actions[0].ActionId := 1;
  Result.Triggers[1].Actions[RADIX_MAX_TRIGGER_ACTIONS - 1].Trigger := 9;
  SetLength(Result.Walls, 4);
  Result.Walls[2].Flags := $8000400;
  Result.Walls[2].HitPoints := 50;
  Result.Walls[2].Trigger := 35;
  SetLength(Result.Shots, 1);
  Result.Shots[0].Key := 4000000000;
  Result.Shots[0].X := -1000 * 65536;
  Result.Shots[0].MomY := 56 * 65536;
end;

procedure TTestRadixSaveGameCodec.AssertDecodeRaises(const ABytes: TBytes; const AExpectedPart: string);
begin
  try
    TRadixSaveGameCodec.Decode(ABytes);
  except
    on E: ERadixException do
    begin
      Assert.Contains(E.Message, AExpectedPart);
      Exit;
    end;
  end;
  Assert.Fail('nessuna ERadixException: ' + AExpectedPart);
end;

procedure TTestRadixSaveGameCodec.IRecordDelFileDovrebberoAvereLaDimensioneFissata;
begin
  // the same in a program of 32 and of 64 bits: packed, no pointers
  Assert.AreEqual<Integer>(60, SizeOf(TRadixSaveHeader));
  Assert.AreEqual<Integer>(116, SizeOf(TRadixSavePlayer));
  Assert.AreEqual<Integer>(96, SizeOf(TRadixSaveLevelPlayer));
  Assert.AreEqual<Integer>(12, SizeOf(TRadixSaveWall));
  Assert.AreEqual<Integer>(28, SizeOf(TRadixSaveShot));
  Assert.AreEqual<Integer>(168, SizeOf(TRadixLevelAction));
  Assert.AreEqual<Integer>(1834, SizeOf(TRadixLevelTrigger));
end;

procedure TTestRadixSaveGameCodec.DovrebbeRidareLoStatoDopoAndataERitorno;
var
  LState, LBack: TRadixSaveState;
  LBytes: TBytes;
begin
  LState := SampleState;
  LBytes := TRadixSaveGameCodec.Encode(LState);
  Assert.AreEqual<Integer>(60 + 2 * (116 + 96 + 4) + 3 * 168 + 2 * 1834 + 4 * 12 + 28, Length(LBytes));
  LBack := TRadixSaveGameCodec.Decode(LBytes);
  Assert.AreEqual(11, LBack.RandomIndexes[0]);
  Assert.AreEqual(222, LBack.RandomIndexes[1]);
  Assert.AreEqual(33, LBack.RandomIndexes[2]);
  Assert.AreEqual(44, LBack.RandomIndexes[3]);
  Assert.AreEqual(1, LBack.Episode);
  Assert.AreEqual(3, LBack.Map);
  Assert.AreEqual(5, LBack.NamedLevel);
  Assert.AreEqual<Integer>(2, Length(LBack.Players));
  Assert.IsTrue(CompareMem(@LState.Players[0], @LBack.Players[0], 2 * SizeOf(TRadixSavePlayer)));
  Assert.IsTrue(CompareMem(@LState.LevelPlayers[0], @LBack.LevelPlayers[0], 2 * SizeOf(TRadixSaveLevelPlayer)));
  Assert.AreEqual(7, LBack.LastTriggers[0]);
  Assert.AreEqual(-1, LBack.LastTriggers[1]);
  Assert.AreEqual<Integer>(3, Length(LBack.Actions));
  Assert.IsTrue(CompareMem(@LState.Actions[0], @LBack.Actions[0], 3 * SizeOf(TRadixLevelAction)));
  Assert.AreEqual<Integer>(2, Length(LBack.Triggers));
  Assert.IsTrue(CompareMem(@LState.Triggers[0], @LBack.Triggers[0], 2 * SizeOf(TRadixLevelTrigger)));
  Assert.AreEqual<Integer>(4, Length(LBack.Walls));
  Assert.AreEqual(50, LBack.Walls[2].HitPoints);
  Assert.AreEqual(35, LBack.Walls[2].Trigger);
  Assert.AreEqual<Integer>(1, Length(LBack.Shots));
  Assert.AreEqual<Cardinal>(4000000000, LBack.Shots[0].Key);
  Assert.AreEqual(56 * 65536, LBack.Shots[0].MomY);
  // the bytes of what was read are the ones that were written
  Assert.IsTrue(CompareMem(@LBytes[0], @TRadixSaveGameCodec.Encode(LBack)[0], Length(LBytes)));
end;

procedure TTestRadixSaveGameCodec.DovrebbeScrivereMagiaEVersioneInTesta;
var
  LBytes: TBytes;
begin
  LBytes := TRadixSaveGameCodec.Encode(SampleState);
  Assert.AreEqual('RADIXSAV', TEncoding.ANSI.GetString(LBytes, 0, 8));
  Assert.AreEqual<Byte>(RADIX_SAVE_VERSION, LBytes[8]);
  Assert.AreEqual<Byte>(0, LBytes[9]);
end;

procedure TTestRadixSaveGameCodec.UnoStatoVuotoDovrebbeEssereLaSolaIntestazione;
var
  LBytes: TBytes;
  LBack: TRadixSaveState;
begin
  LBytes := TRadixSaveGameCodec.Encode(Default(TRadixSaveState));
  Assert.AreEqual<Integer>(SizeOf(TRadixSaveHeader), Length(LBytes));
  LBack := TRadixSaveGameCodec.Decode(LBytes);
  Assert.AreEqual<Integer>(0, Length(LBack.Players));
  Assert.AreEqual<Integer>(0, Length(LBack.Actions));
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareGiocatoriEPartiDiLivelloInNumeroDiverso;
var
  LState: TRadixSaveState;
begin
  LState := SampleState;
  SetLength(LState.LastTriggers, 1);
  Assert.WillRaise(
    procedure
    begin
      TRadixSaveGameCodec.Encode(LState);
    end, ERadixException);
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareUnFileTroppoCorto;
begin
  AssertDecodeRaises(nil, 'the header alone');
  AssertDecodeRaises(TBytes.Create(Ord('R'), Ord('A'), Ord('D')), 'the header alone');
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareUnFileSenzaMagia;
var
  LBytes: TBytes;
begin
  LBytes := TRadixSaveGameCodec.Encode(SampleState);
  LBytes[0] := Ord('X');
  AssertDecodeRaises(LBytes, 'RADIXSAV');
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareUnAltraVersione;
var
  LBytes: TBytes;
begin
  LBytes := TRadixSaveGameCodec.Encode(SampleState);
  LBytes[8] := RADIX_SAVE_VERSION + 1;
  AssertDecodeRaises(LBytes, 'version 2');
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareUnFileTroncatoOConBytesInPiu;
var
  LBytes: TBytes;
begin
  LBytes := TRadixSaveGameCodec.Encode(SampleState);
  AssertDecodeRaises(Copy(LBytes, 0, Length(LBytes) - 1), 'its header says');
  AssertDecodeRaises(LBytes + [0], 'its header says');
end;

procedure TTestRadixSaveGameCodec.DovrebbeRifiutareUnConteggioNegativo;
var
  LBytes: TBytes;
  LHeader: TRadixSaveHeader;
begin
  LBytes := TRadixSaveGameCodec.Encode(Default(TRadixSaveState));
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  LHeader.Walls := -1;
  Move(LHeader, LBytes[0], SizeOf(LHeader));
  AssertDecodeRaises(LBytes, 'negative count');
end;

procedure TTestRadixSaveGameCodec.LeImpronteDovrebberoCambiareSoloNellaParteCambiata;
var
  LState: TRadixSaveState;
  LBefore, LAfter: TRadixSaveFingerprints;
begin
  LState := SampleState;
  LBefore := TRadixSaveGameCodec.Fingerprints(LState);
  LAfter := TRadixSaveGameCodec.Fingerprints(TRadixSaveGameCodec.Decode(TRadixSaveGameCodec.Encode(LState)));
  Assert.AreEqual<Cardinal>(LBefore.Players, LAfter.Players);
  Assert.AreEqual<Cardinal>(LBefore.Actions, LAfter.Actions);
  Assert.AreEqual<Cardinal>(LBefore.Triggers, LAfter.Triggers);

  LState.Walls[2].HitPoints := 49;
  LAfter := TRadixSaveGameCodec.Fingerprints(LState);
  Assert.AreNotEqual<Cardinal>(LBefore.Walls, LAfter.Walls);
  Assert.AreEqual<Cardinal>(LBefore.Players, LAfter.Players);
  Assert.AreEqual<Cardinal>(LBefore.LevelPlayers, LAfter.LevelPlayers);
  Assert.AreEqual<Cardinal>(LBefore.Actions, LAfter.Actions);
  Assert.AreEqual<Cardinal>(LBefore.Triggers, LAfter.Triggers);
  Assert.AreEqual<Cardinal>(LBefore.Shots, LAfter.Shots);

  LState.LastTriggers[1] := 2;
  Assert.AreNotEqual<Cardinal>(LBefore.LevelPlayers, TRadixSaveGameCodec.Fingerprints(LState).LevelPlayers);
end;

procedure TTestRadixSaveGameCodec.LaLogicaDovrebbeRidareIlSuoStatoDopoUnRipristino;
var
  LState: TRadixSaveState;
  LLogic, LOther: TRadixTriggerLogic;
  LActions: TArray<TRadixLevelAction>;
  LTriggers: TArray<TRadixLevelTrigger>;
  LLast: TArray<Integer>;
begin
  LState := SampleState;
  LLogic := TRadixTriggerLogic.Create(LState.Actions, LState.Triggers, 2);
  LOther := TRadixTriggerLogic.Create(LState.Actions, LState.Triggers, 2);
  try
    // the level is played: an action is suspended, a trigger is deactivated
    LLogic.SuspendAction(0);
    LLogic.DeactivateTrigger(0);
    LLogic.Action(2).Params[3] := 99;
    LLogic.CopyState(LActions, LTriggers, LLast);
    // the copy is not the state itself
    LLogic.Action(2).Params[3] := 1;
    Assert.AreEqual<Integer>(99, LActions[2].Params[3]);

    // a level that has just been loaded takes the state of the saved game
    Assert.IsFalse(LOther.IsTriggerSuspended(0));
    LOther.RestoreState(LActions, LTriggers, LLast);
    Assert.IsTrue(LOther.IsTriggerSuspended(0));
    Assert.IsFalse(LOther.IsActionRunnable(0));
    Assert.AreEqual<Integer>(99, LOther.Action(2).Params[3]);
    Assert.AreEqual(LLogic.LastTrigger(0), LOther.LastTrigger(0));
  finally
    LOther.Free;
    LLogic.Free;
  end;
end;

procedure TTestRadixSaveGameCodec.LaLogicaDovrebbeRifiutareLoStatoDiUnAltroLivello;
var
  LState: TRadixSaveState;
  LLogic: TRadixTriggerLogic;
begin
  LState := SampleState;
  LLogic := TRadixTriggerLogic.Create(LState.Actions, LState.Triggers, 2);
  try
    Assert.WillRaise(
      procedure
      begin
        LLogic.RestoreState(Copy(LState.Actions, 0, 2), LState.Triggers, LState.LastTriggers);
      end, ERadixException);
    Assert.WillRaise(
      procedure
      begin
        LLogic.RestoreState(LState.Actions, LState.Triggers, [1, 2, 3]);
      end, ERadixException);
    // nothing changed
    Assert.AreEqual(3, LLogic.ActionCount);
    Assert.IsTrue(LLogic.IsTriggerSuspended(1));
  finally
    LLogic.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixSaveGameCodec);

end.
