{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the start of a game                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.StartArbiter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Types, DelphiDoom.Net.Intf,
  DelphiDoom.Tests.Net.Fakes, DelphiDoom.Tests.Net.TicSync;

type
  [TestFixture]
  [Category('net')]
  TTestNetStartArbiter = class(TObject)
  private
    FNet: TFakeNetwork;
    FA: TNodeRig;
    FB: TNodeRig;
    FAbort: TFakeAbortCheck;
    FAbortIntf: INetAbortCheck;
    function MakeInfo(AVersion: Byte): TNetSetupInfo;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestKeyPlayerSendsTheSetupUntilTheOthersAnswer;
    [Test]
    procedure TestSetupPacketIsTheOldSetupPacket;
    [Test]
    procedure TestOtherPlayersReceiveTheSettingsOfTheKeyPlayer;
    [Test]
    procedure TestListenerIgnoresGamePacketsBeforeTheSetup;
    [Test]
    procedure TestDifferentVersionCannotPlay;
    [Test]
    procedure TestWaitCanBeAborted;
    [Test]
    procedure TestAbortCheckIsAskedAtEveryTurn;
  end;

  [TestFixture]
  [Category('net')]
  TTestNetSetupInfo = class(TObject)
  public
    [Test]
    procedure TestSettingsAreBitsOfRetransmitFrom;
    [Test]
    procedure TestMapAndEpisodeShareOneByte;
    [Test]
    procedure TestPacketRoundTrip;
    [Test]
    procedure TestSkillAndDeathmatchDoNotOverlap;
    [Test]
    procedure TestEpisodeCanBeAbsent;
  end;

implementation

uses
  DelphiDoom.Net.Factory;

{ TTestNetStartArbiter }

procedure TTestNetStartArbiter.Setup;
begin
  FNet := TFakeNetwork.Create;
  FA := TNodeRig.Create(FNet, 0, [1], 0, 1, 0);
  FB := TNodeRig.Create(FNet, 1, [0], 1, 1, 0);
  FAbort := TFakeAbortCheck.Create;
  FAbort.MaxChecks := 20;
  FAbortIntf := FAbort;
end;

procedure TTestNetStartArbiter.TearDown;
begin
  FAbortIntf := nil;
  FB.Free;
  FA.Free;
  FNet.Free;
end;

function TTestNetStartArbiter.MakeInfo(AVersion: Byte): TNetSetupInfo;
begin
  Result := Default(TNetSetupInfo);
  Result.EngineVersion := AVersion;
  Result.Skill := 4;
  Result.Deathmatch := 2;
  Result.NoMonsters := True;
  Result.Respawn := False;
  Result.MapByte := TNetSetupInfo.PackMap(3, 5);
  Result.Flags := 5;
end;

procedure TTestNetStartArbiter.TestKeyPlayerSendsTheSetupUntilTheOthersAnswer;
var
  LArbiter: INetStartArbiter;
  LReceived: TNetSetupInfo;
  LGotSetup: Boolean;
  LResult: TNetSetupInfo;
begin
  LGotSetup := False;
  FAbort.OnCheck :=
    procedure
    var
      LPacket: TNetPacket;
      LNode: Integer;
    begin
      // the other computer: it takes the setup and starts to play, which is its answer
      while FB.Port.TryReceivePacket(LPacket, LNode) do
        if LPacket.IsSetup then
        begin
          LReceived := TNetSetupInfo.FromPacket(LPacket);
          LGotSetup := True;
        end;
      if LGotSetup then
      begin
        FB.Clock.Tics := FB.Clock.Tics + 1;
        FB.Sync.NetUpdate;
      end;
    end;
  LArbiter := TNetFactory.CreateStartArbiter(FA.Port, FAbortIntf, 2, 0);
  LResult := LArbiter.Arbitrate(MakeInfo(207));
  Assert.IsTrue(LGotSetup);
  Assert.AreEqual(2, FAbort.Checks, 'un giro per spedire, uno per la risposta');
  Assert.AreEqual(Byte(207), LReceived.EngineVersion);
  Assert.AreEqual(Byte(4), LReceived.Skill);
  Assert.AreEqual(Byte(2), LReceived.Deathmatch);
  Assert.IsTrue(LReceived.NoMonsters);
  Assert.IsFalse(LReceived.Respawn);
  Assert.AreEqual(Byte(197), LReceived.MapByte);
  Assert.AreEqual(LongWord(5), LReceived.Flags);
  Assert.AreEqual(Byte(4), LResult.Skill, 'il giocatore chiave tiene le sue impostazioni');
end;

procedure TTestNetStartArbiter.TestSetupPacketIsTheOldSetupPacket;
var
  LArbiter: INetStartArbiter;
  LPacket: TNetPacket;
begin
  FAbort.MaxChecks := 2;
  LArbiter := TNetFactory.CreateStartArbiter(FA.Port, FAbortIntf, 2, 0);
  Assert.WillRaise(
    procedure
    begin
      LArbiter.Arbitrate(MakeInfo(207));
    end, ENetException);
  Assert.AreEqual(1, FNet.Sent.Count, 'un pacchetto per il nodo 1; quello per il nodo 0 rimbalza');
  Assert.AreEqual(ndsOk, FB.Codec.Decode(FNet.Sent[0].Data, LPacket));
  Assert.IsTrue(LPacket.IsSetup);
  Assert.AreEqual(Byte(207), LPacket.Player, 'la versione del motore');
  // skill | deathmatch shl 6 | $20 no monsters
  Assert.AreEqual(Byte($A4), LPacket.RetransmitFrom);
  Assert.AreEqual(Byte($C5), LPacket.StartTic, 'episodio * 64 + mappa');
  Assert.AreEqual(Byte(0), LPacket.NumTics);
  Assert.AreEqual(LongWord(5), LPacket.Flags);
end;

procedure TTestNetStartArbiter.TestOtherPlayersReceiveTheSettingsOfTheKeyPlayer;
var
  LArbiter: INetStartArbiter;
  LInfo: TNetSetupInfo;
  LDone: Boolean;
begin
  LDone := False;
  FAbort.OnCheck :=
    procedure
    var
      LPacket: TNetPacket;
    begin
      if not LDone then
      begin
        LDone := True;
        LPacket := MakeInfo(207).ToPacket;
        FA.Port.SendPacket(1, LPacket, NCMD_SETUP);
      end;
    end;
  LArbiter := TNetFactory.CreateStartArbiter(FB.Port, FAbortIntf, 2, 1);
  LInfo := LArbiter.Arbitrate(MakeInfo(207));
  Assert.AreEqual(Byte(4), LInfo.Skill);
  Assert.AreEqual(Byte(2), LInfo.Deathmatch);
  Assert.IsTrue(LInfo.NoMonsters);
  Assert.AreEqual(3, TNetSetupInfo.UnpackEpisode(LInfo.MapByte));
  Assert.AreEqual(5, TNetSetupInfo.UnpackMap(LInfo.MapByte));
  Assert.AreEqual(LongWord(5), LInfo.Flags);
end;

procedure TTestNetStartArbiter.TestListenerIgnoresGamePacketsBeforeTheSetup;
var
  LArbiter: INetStartArbiter;
  LStep: Integer;
  LInfo: TNetSetupInfo;
begin
  LStep := 0;
  FAbort.OnCheck :=
    procedure
    var
      LPacket: TNetPacket;
    begin
      Inc(LStep);
      LPacket := Default(TNetPacket);
      if LStep = 1 then
        FA.Port.SendPacket(1, LPacket, 0)
      else if LStep = 2 then
      begin
        LPacket := MakeInfo(207).ToPacket;
        FA.Port.SendPacket(1, LPacket, NCMD_SETUP);
      end;
    end;
  LArbiter := TNetFactory.CreateStartArbiter(FB.Port, FAbortIntf, 2, 1);
  LInfo := LArbiter.Arbitrate(MakeInfo(207));
  Assert.AreEqual(Byte(4), LInfo.Skill);
  Assert.AreEqual(2, FAbort.Checks);
end;

procedure TTestNetStartArbiter.TestDifferentVersionCannotPlay;
var
  LArbiter: INetStartArbiter;
  LDone: Boolean;
begin
  LDone := False;
  FAbort.OnCheck :=
    procedure
    var
      LPacket: TNetPacket;
    begin
      if not LDone then
      begin
        LDone := True;
        LPacket := MakeInfo(206).ToPacket;
        FA.Port.SendPacket(1, LPacket, NCMD_SETUP);
      end;
    end;
  LArbiter := TNetFactory.CreateStartArbiter(FB.Port, FAbortIntf, 2, 1);
  Assert.WillRaise(
    procedure
    begin
      LArbiter.Arbitrate(MakeInfo(207));
    end, ENetVersionMismatchException);
end;

procedure TTestNetStartArbiter.TestWaitCanBeAborted;
var
  LArbiter: INetStartArbiter;
begin
  FAbort.MaxChecks := 3;
  LArbiter := TNetFactory.CreateStartArbiter(FA.Port, FAbortIntf, 2, 0);
  Assert.WillRaise(
    procedure
    begin
      LArbiter.Arbitrate(MakeInfo(207));
    end, ENetException, 'nessuno risponde');
  Assert.AreEqual(3, FAbort.Checks);
end;

procedure TTestNetStartArbiter.TestAbortCheckIsAskedAtEveryTurn;
var
  LArbiter: INetStartArbiter;
begin
  FAbort.MaxChecks := 7;
  LArbiter := TNetFactory.CreateStartArbiter(FB.Port, FAbortIntf, 2, 1);
  Assert.WillRaise(
    procedure
    begin
      LArbiter.Arbitrate(MakeInfo(207));
    end, ENetException);
  Assert.AreEqual(7, FAbort.Checks);
end;

{ TTestNetSetupInfo }

procedure TTestNetSetupInfo.TestSettingsAreBitsOfRetransmitFrom;
var
  LInfo: TNetSetupInfo;
  LPacket: TNetPacket;
begin
  LInfo := Default(TNetSetupInfo);
  LInfo.Skill := 3;
  LInfo.Deathmatch := 1;
  LInfo.NoMonsters := True;
  LInfo.Respawn := True;
  LPacket := LInfo.ToPacket;
  Assert.AreEqual(Byte(3 or $40 or $20 or $10), LPacket.RetransmitFrom);
  LInfo.NoMonsters := False;
  LInfo.Respawn := False;
  LInfo.Deathmatch := 0;
  Assert.AreEqual(Byte(3), LInfo.ToPacket.RetransmitFrom);
end;

procedure TTestNetSetupInfo.TestMapAndEpisodeShareOneByte;
begin
  Assert.AreEqual(Byte(197), TNetSetupInfo.PackMap(3, 5));
  Assert.AreEqual(Byte(1 * 64 + 1), TNetSetupInfo.PackMap(1, 1));
  Assert.AreEqual(3, TNetSetupInfo.UnpackEpisode(197));
  Assert.AreEqual(5, TNetSetupInfo.UnpackMap(197));
  Assert.AreEqual(9, TNetSetupInfo.UnpackMap(TNetSetupInfo.PackMap(2, 9)));
end;

procedure TTestNetSetupInfo.TestPacketRoundTrip;
var
  LInfo: TNetSetupInfo;
  LBack: TNetSetupInfo;
begin
  LInfo := Default(TNetSetupInfo);
  LInfo.EngineVersion := 207;
  LInfo.Skill := 2;
  LInfo.Deathmatch := 3;
  LInfo.Respawn := True;
  LInfo.MapByte := 12;
  LInfo.Flags := 15;
  LBack := TNetSetupInfo.FromPacket(LInfo.ToPacket);
  Assert.AreEqual(Byte(207), LBack.EngineVersion);
  Assert.AreEqual(Byte(2), LBack.Skill);
  Assert.AreEqual(Byte(3), LBack.Deathmatch);
  Assert.IsTrue(LBack.Respawn);
  Assert.IsFalse(LBack.NoMonsters);
  Assert.AreEqual(Byte(12), LBack.MapByte);
  Assert.AreEqual(LongWord(15), LBack.Flags);
end;

procedure TTestNetSetupInfo.TestSkillAndDeathmatchDoNotOverlap;
var
  LInfo: TNetSetupInfo;
begin
  LInfo := Default(TNetSetupInfo);
  LInfo.Skill := 4;
  Assert.AreEqual(Byte(4), TNetSetupInfo.FromPacket(LInfo.ToPacket).Skill);
  Assert.AreEqual(Byte(0), TNetSetupInfo.FromPacket(LInfo.ToPacket).Deathmatch);
end;

procedure TTestNetSetupInfo.TestEpisodeCanBeAbsent;
var
  LInfo: TNetSetupInfo;
begin
  // Strife has no episodes: the whole byte is the map
  LInfo := Default(TNetSetupInfo);
  LInfo.MapByte := 200;
  Assert.AreEqual(Byte(200), TNetSetupInfo.FromPacket(LInfo.ToPacket).MapByte);
end;

end.
