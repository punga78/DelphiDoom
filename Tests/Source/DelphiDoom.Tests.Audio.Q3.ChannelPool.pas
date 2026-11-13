{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the channels of the Quake III sound                    }
{                                                                              }
{  The choice of the channel of S_StartSound (the oldest sound is taken when   }
{  all 96 are busy) and S_ScanChannelStarts.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.ChannelPool;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Audio.Q3.Rig;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3ChannelPool = class
  strict private
    FRig: TQ3TestRig;
    function Start(AEntity, AChannel, ASfx: Integer; AOrigin: Boolean = False): Integer;
    procedure FillWithDifferentEntities;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIPostiDaQuelloInFondoInSu;
    [Test]
    procedure DovrebbeImpostareLeCaratteristicheDelCanale;
    [Test]
    procedure DovrebbeSeguireLEntitaSenzaOrigine;
    [Test]
    procedure DovrebbeScartareUnDoppioAvvioEntroCinquantaMillisecondi;
    [Test]
    procedure DovrebbeAmmettereCinqueVociDelloStessoSuonoPerEntita;
    [Test]
    procedure DovrebbeAmmettereNoveVociDelloStessoSuonoPerIlListener;
    [Test]
    procedure DovrebbeRiprendereIlCanalePiuVecchio;
    [Test]
    procedure DovrebbePreferireIlCanalePiuVecchioDellaStessaEntita;
    [Test]
    procedure DovrebbeRisparmiareLAnnunciatore;
    [Test]
    procedure DovrebbeRiprendereIlPiuVecchioDiTuttiSeSonoTuttiDelListener;
    [Test]
    procedure DovrebbeScartareIlSuonoSeNessunCanaleEPiuVecchio;
    [Test]
    procedure DovrebbeFarIniziareIlSuonoAlProssimoMix;
    [Test]
    procedure DovrebbeLiberareIlCanaleDiUnSuonoFinito;
    [Test]
    procedure DovrebbeRipartireDaCapoDopoIlReset;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Sfx;

{ TTestQ3ChannelPool }

procedure TTestQ3ChannelPool.Setup;
begin
  FRig := TQ3TestRig.Create;
  FRig.Sound.Respatialize(0, Vec3(0, 0, 0), IdentityAxis, 0);
end;

procedure TTestQ3ChannelPool.TearDown;
begin
  FRig.Free;
end;

function TTestQ3ChannelPool.Start(AEntity, AChannel, ASfx: Integer; AOrigin: Boolean): Integer;
var
  LOrigin: TQ3Vec3;
  LSfx: TQ3Sfx;
begin
  LSfx := FRig.Sound.Registry.SfxOf(ASfx);
  LOrigin := Vec3(10, 20, 30);
  if AOrigin then
    Result := FRig.Sound.Pool.StartSound(@LOrigin, AEntity, AChannel, LSfx)
  else
    Result := FRig.Sound.Pool.StartSound(nil, AEntity, AChannel, LSfx);
end;

procedure TTestQ3ChannelPool.FillWithDifferentEntities;
var
  LIndex: Integer;
begin
  FRig.AddConstant('a', 1000, 5000);
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
  begin
    FRig.Clock.Milliseconds := 1000 + LIndex * 100;
    Assert.AreEqual(95 - LIndex, Start(LIndex + 1, Q3_CHAN_AUTO, 0));
  end;
end;

procedure TTestQ3ChannelPool.DovrebbeDareIPostiDaQuelloInFondoInSu;
begin
  FRig.AddConstant('a', 1000, 5000);
  FRig.AddConstant('b', 1000, 5000);
  Assert.AreEqual(95, Start(1, Q3_CHAN_AUTO, 0));
  Assert.AreEqual(94, Start(2, Q3_CHAN_AUTO, 1));
  Assert.AreEqual(93, Start(3, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeImpostareLeCaratteristicheDelCanale;
var
  LChannel: TQ3Channel;
begin
  FRig.AddConstant('a', 1000, 5000);
  FRig.Clock.Milliseconds := 777;
  Start(7, Q3_CHAN_WEAPON, 0, True);
  LChannel := FRig.Sound.State.Channels[95];
  Assert.AreEqual(7, LChannel.EntityNumber);
  Assert.AreEqual(Q3_CHAN_WEAPON, LChannel.EntityChannel);
  Assert.AreEqual(777, LChannel.AllocTime);
  Assert.AreEqual(Q3_START_SAMPLE_IMMEDIATE, LChannel.StartSample);
  Assert.AreEqual(127, LChannel.MasterVolume);
  Assert.AreEqual(127, LChannel.LeftVolume);
  Assert.AreEqual(127, LChannel.RightVolume);
  Assert.IsTrue(LChannel.FixedOrigin);
  Assert.IsFalse(LChannel.Doppler);
  Assert.AreEqual<Single>(20, LChannel.Origin[1]);
  Assert.AreEqual(777, FRig.Sound.Registry.SfxOf(0).LastTimeUsed);
end;

procedure TTestQ3ChannelPool.DovrebbeSeguireLEntitaSenzaOrigine;
begin
  FRig.AddConstant('a', 1000, 5000);
  Start(7, Q3_CHAN_AUTO, 0, True);
  Start(8, Q3_CHAN_AUTO, 0, False);
  Assert.IsTrue(FRig.Sound.State.Channels[95].FixedOrigin);
  Assert.IsFalse(FRig.Sound.State.Channels[94].FixedOrigin);
end;

procedure TTestQ3ChannelPool.DovrebbeScartareUnDoppioAvvioEntroCinquantaMillisecondi;
begin
  FRig.AddConstant('a', 1000, 5000);
  FRig.Clock.Milliseconds := 1000;
  Assert.AreEqual(95, Start(5, Q3_CHAN_AUTO, 0));
  FRig.Clock.Milliseconds := 1049;
  Assert.AreEqual(-1, Start(5, Q3_CHAN_AUTO, 0));
  FRig.Clock.Milliseconds := 1050;
  Assert.AreEqual(94, Start(5, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeAmmettereCinqueVociDelloStessoSuonoPerEntita;
var
  LIndex: Integer;
begin
  FRig.AddConstant('a', 1000, 5000);
  for LIndex := 0 to 4 do
  begin
    FRig.Clock.Milliseconds := 1000 + LIndex * 60;
    Assert.AreNotEqual(-1, Start(5, Q3_CHAN_AUTO, 0), 'start ' + LIndex.ToString);
  end;
  FRig.Clock.Milliseconds := 2000;
  Assert.AreEqual(-1, Start(5, Q3_CHAN_AUTO, 0));
  // another entity is not limited by it
  Assert.AreNotEqual(-1, Start(6, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeAmmettereNoveVociDelloStessoSuonoPerIlListener;
var
  LIndex: Integer;
begin
  FRig.AddConstant('a', 1000, 5000);
  for LIndex := 0 to 8 do
  begin
    FRig.Clock.Milliseconds := 1000 + LIndex * 60;
    Assert.AreNotEqual(-1, Start(0, Q3_CHAN_LOCAL, 0), 'start ' + LIndex.ToString);
  end;
  FRig.Clock.Milliseconds := 2000;
  Assert.AreEqual(-1, Start(0, Q3_CHAN_LOCAL, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeRiprendereIlCanalePiuVecchio;
begin
  FillWithDifferentEntities;
  FRig.Clock.Milliseconds := 20000;
  Assert.AreEqual(95, Start(200, Q3_CHAN_AUTO, 0));
  Assert.AreEqual(20000, FRig.Sound.State.Channels[95].AllocTime);
  Assert.AreEqual(200, FRig.Sound.State.Channels[95].EntityNumber);
  Assert.AreEqual(94, Start(201, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbePreferireIlCanalePiuVecchioDellaStessaEntita;
begin
  FillWithDifferentEntities;
  FRig.Clock.Milliseconds := 20000;
  // the sound of entity 50 is on channel 95 - 49
  Assert.AreEqual(46, Start(50, Q3_CHAN_VOICE, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeRisparmiareLAnnunciatore;
var
  LIndex: Integer;
begin
  FRig.AddConstant('a', 1000, 5000);
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
  begin
    FRig.Clock.Milliseconds := 1000 + LIndex * 100;
    if LIndex = 0 then
      Start(LIndex + 1, Q3_CHAN_ANNOUNCER, 0)
    else
      Start(LIndex + 1, Q3_CHAN_AUTO, 0);
  end;
  FRig.Clock.Milliseconds := 20000;
  // the oldest is the announcer: the next one goes
  Assert.AreEqual(94, Start(200, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeRiprendereIlPiuVecchioDiTuttiSeSonoTuttiDelListener;
var
  LIndex: Integer;
begin
  // 12 sounds, 8 voices each for the listener: 96 channels
  for LIndex := 0 to 11 do
    FRig.AddConstant('s' + LIndex.ToString, 1000, 5000);
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
  begin
    FRig.Clock.Milliseconds := 1000 + LIndex * 100;
    Assert.AreEqual(95 - LIndex, Start(0, Q3_CHAN_LOCAL, LIndex mod 12), 'start ' + LIndex.ToString);
  end;
  FRig.Clock.Milliseconds := 20000;
  Assert.AreEqual(95, Start(5, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeScartareIlSuonoSeNessunCanaleEPiuVecchio;
var
  LIndex: Integer;
begin
  FRig.AddConstant('a', 1000, 5000);
  FRig.Clock.Milliseconds := 5000;
  for LIndex := 0 to Q3_MAX_CHANNELS - 1 do
    Start(LIndex + 1, Q3_CHAN_AUTO, 0);
  Assert.AreEqual(-1, Start(500, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeFarIniziareIlSuonoAlProssimoMix;
begin
  FRig.AddConstant('a', 1000, 5000);
  Start(3, Q3_CHAN_AUTO, 0);
  FRig.Sound.State.PaintedTime := 4321;
  Assert.IsTrue(FRig.Sound.Pool.ScanChannelStarts);
  Assert.AreEqual(4321, FRig.Sound.State.Channels[95].StartSample);
  Assert.IsFalse(FRig.Sound.Pool.ScanChannelStarts);
  Assert.IsNotNull(FRig.Sound.State.Channels[95].Sfx);
end;

procedure TTestQ3ChannelPool.DovrebbeLiberareIlCanaleDiUnSuonoFinito;
begin
  FRig.AddConstant('a', 1000, 5000);
  Start(3, Q3_CHAN_AUTO, 0);
  FRig.Sound.State.PaintedTime := 100;
  FRig.Sound.Pool.ScanChannelStarts;
  // 100 + 5000 samples: not finished at 5099, finished at 5100
  FRig.Sound.State.PaintedTime := 5099;
  FRig.Sound.Pool.ScanChannelStarts;
  Assert.IsNotNull(FRig.Sound.State.Channels[95].Sfx);
  FRig.Sound.State.PaintedTime := 5100;
  FRig.Sound.Pool.ScanChannelStarts;
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  // the channel just freed is the first to be given again
  FRig.Clock.Milliseconds := 100;
  Assert.AreEqual(95, Start(9, Q3_CHAN_AUTO, 0));
end;

procedure TTestQ3ChannelPool.DovrebbeRipartireDaCapoDopoIlReset;
begin
  FRig.AddConstant('a', 1000, 5000);
  Start(3, Q3_CHAN_AUTO, 0);
  Start(4, Q3_CHAN_AUTO, 0);
  FRig.Sound.Pool.Reset;
  Assert.IsNull(FRig.Sound.State.Channels[95].Sfx);
  Assert.AreEqual(95, Start(5, Q3_CHAN_AUTO, 0));
end;

end.
