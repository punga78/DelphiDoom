{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the queue of the items that respawn                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.RespawnQueue;

// The generator of the random scenarios wraps
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.RespawnQueue;

type
  /// <summary>A spawn point of the tests: two fields, as the ones the rules of Strife swap</summary>
  TTestSpawn = record
    X: Smallint;
    Kind: Word;
    Options: Smallint;
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersRespawnQueue = class
  strict private
    FQueue: TRespawnQueue<TTestSpawn>;
    function Spawn(const AKind: Word): TTestSpawn;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotaDopoLaCreazione;
    [Test]
    procedure DovrebbeDareGliElementiNellOrdineDiInserimento;
    [Test]
    procedure DovrebbeSvuotarsiConClear;
    [Test]
    procedure DovrebbePerdereIlPiuVecchioQuandoESPiena;
    [Test]
    procedure DovrebbeNonMuovereLaTestaFinoACommit;
    [Test]
    procedure DovrebbeSollevareEccezioneSeVuotaPerOldest;
    [Test]
    procedure DovrebbeSollevareEccezioneSeVuotaPerOldestTime;
    [Test]
    procedure DovrebbeSollevareEccezioneSeVuotaPerDropOldest;
    [Test]
    procedure DovrebbeFareIlGiroDegliIndiciSenzaPerdereElementi;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuScenariCasuali;
  end;

implementation

{ TTestThinkersRespawnQueue }

function TTestThinkersRespawnQueue.Spawn(const AKind: Word): TTestSpawn;
begin
  Result.X := Smallint(AKind);
  Result.Kind := AKind;
  Result.Options := 7;
end;

procedure TTestThinkersRespawnQueue.Setup;
begin
  FQueue := TRespawnQueue<TTestSpawn>.Create;
end;

procedure TTestThinkersRespawnQueue.TearDown;
begin
  FQueue.Free;
end;

procedure TTestThinkersRespawnQueue.DovrebbeEssereVuotaDopoLaCreazione;
begin
  Assert.IsTrue(FQueue.IsEmpty);
  Assert.AreEqual(0, FQueue.Head);
  Assert.AreEqual(0, FQueue.Tail);
end;

procedure TTestThinkersRespawnQueue.DovrebbeDareGliElementiNellOrdineDiInserimento;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
    FQueue.Add(Spawn(LIndex), LIndex * 10);
  for LIndex := 1 to 5 do
  begin
    Assert.IsFalse(FQueue.IsEmpty);
    Assert.AreEqual(LIndex, Integer(FQueue.Oldest.Kind));
    Assert.AreEqual(LIndex * 10, FQueue.OldestTime);
    FQueue.DropOldest;
  end;
  Assert.IsTrue(FQueue.IsEmpty);
end;

procedure TTestThinkersRespawnQueue.DovrebbeSvuotarsiConClear;
begin
  FQueue.Add(Spawn(1), 1);
  FQueue.Clear;
  Assert.IsTrue(FQueue.IsEmpty);
  Assert.AreEqual(0, FQueue.Head);
  Assert.AreEqual(0, FQueue.Tail);
end;

procedure TTestThinkersRespawnQueue.DovrebbePerdereIlPiuVecchioQuandoESPiena;
var
  LIndex: Integer;
begin
  // the ring holds one item less than its slots: the 128th item pushes the first out
  for LIndex := 1 to RESPAWN_QUEUE_SIZE do
    FQueue.Add(Spawn(LIndex), LIndex);
  Assert.AreEqual(1, FQueue.Tail);
  Assert.AreEqual(0, FQueue.Head);
  Assert.AreEqual(2, Integer(FQueue.Oldest.Kind));
end;

procedure TTestThinkersRespawnQueue.DovrebbeNonMuovereLaTestaFinoACommit;
var
  LSlot: TRespawnQueue<TTestSpawn>.PSlot;
begin
  LSlot := FQueue.Reserve(Spawn(9), 90);
  Assert.AreEqual(0, FQueue.Head);
  Assert.IsTrue(FQueue.IsEmpty);
  LSlot.Options := 3;
  FQueue.Commit;
  Assert.AreEqual(1, FQueue.Head);
  Assert.AreEqual(3, Integer(FQueue.Oldest.Options));
end;

procedure TTestThinkersRespawnQueue.DovrebbeSollevareEccezioneSeVuotaPerOldest;
begin
  Assert.WillRaise(
    procedure
    begin
      FQueue.Oldest;
    end, EInvalidOpException);
end;

procedure TTestThinkersRespawnQueue.DovrebbeSollevareEccezioneSeVuotaPerOldestTime;
begin
  Assert.WillRaise(
    procedure
    begin
      FQueue.OldestTime;
    end, EInvalidOpException);
end;

procedure TTestThinkersRespawnQueue.DovrebbeSollevareEccezioneSeVuotaPerDropOldest;
begin
  Assert.WillRaise(
    procedure
    begin
      FQueue.DropOldest;
    end, EInvalidOpException);
end;

procedure TTestThinkersRespawnQueue.DovrebbeFareIlGiroDegliIndiciSenzaPerdereElementi;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 1000 do
  begin
    FQueue.Add(Spawn(LIndex and $FFF), LIndex);
    Assert.AreEqual(LIndex and $FFF, Integer(FQueue.Oldest.Kind));
    FQueue.DropOldest;
  end;
  Assert.IsTrue(FQueue.IsEmpty);
end;

procedure TTestThinkersRespawnQueue.DovrebbeEssereUgualeAlVecchioCodiceSuScenariCasuali;
var
  LSeed: Cardinal;
  LStep: Integer;
  LOldHead: Integer;
  LOldTail: Integer;
  LOldSpawns: array[0..RESPAWN_QUEUE_SIZE - 1] of TTestSpawn;
  LOldTimes: array[0..RESPAWN_QUEUE_SIZE - 1] of Integer;
  LAdd: Boolean;
begin
  // the old code of p_mobj (iquehead, iquetail, itemrespawnque, itemrespawntime) as it was
  LSeed := 12345;
  LOldHead := 0;
  LOldTail := 0;
  for LStep := 1 to 20000 do
  begin
    LSeed := LSeed * 1664525 + 1013904223;
    LAdd := ((LSeed shr 16) and 3) <> 0;
    if LAdd then
    begin
      LOldSpawns[LOldHead] := Spawn(LStep and $FFFF);
      LOldTimes[LOldHead] := LStep;
      LOldHead := (LOldHead + 1) and (RESPAWN_QUEUE_SIZE - 1);
      if LOldHead = LOldTail then
        LOldTail := (LOldTail + 1) and (RESPAWN_QUEUE_SIZE - 1);
      FQueue.Add(Spawn(LStep and $FFFF), LStep);
    end
    else
    begin
      Assert.AreEqual(LOldHead = LOldTail, FQueue.IsEmpty);
      if LOldHead <> LOldTail then
      begin
        Assert.AreEqual(LOldTimes[LOldTail], FQueue.OldestTime);
        Assert.AreEqual(Integer(LOldSpawns[LOldTail].Kind), Integer(FQueue.Oldest.Kind));
        LOldTail := (LOldTail + 1) and (RESPAWN_QUEUE_SIZE - 1);
        FQueue.DropOldest;
      end;
    end;
    Assert.AreEqual(LOldHead, FQueue.Head);
    Assert.AreEqual(LOldTail, FQueue.Tail);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersRespawnQueue);

end.
