{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of Keen32 - the profile of the loop of the window          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.LoopProfile;

interface

uses
  System.SysUtils, System.StrUtils, DUnitX.TestFramework, DelphiDoom.Keen.LoopProfile, DelphiDoom.Clock.Intf,
  DelphiDoom.Clock.ManualClock;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenLoopProfile = class(TObject)
  strict private
    FManual: TManualClock;
    FClock: IClock;
    FProfile: TKeenLoopProfile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSommareITempiDiOgniParte;
    [Test]
    procedure DovrebbeContareLeVolteDiOgniParte;
    [Test]
    procedure DovrebbeTenerePresenteLaPiuLungaEQuelleOltreCinqMillisecondi;
    [Test]
    procedure DovrebbeContareITicAlSecondo;
    [Test]
    procedure DovrebbeDireLaVelocitaDelGioco;
    [Test]
    procedure DovrebbeContareLaVelocitaDopoIlSegno;
    [Test]
    procedure IlSegnoDovrebbeValereUnaSolaVolta;
    [Test]
    procedure DovrebbeRifiutareUnOrologioNil;
  end;

implementation

procedure TTestKeenLoopProfile.Setup;
begin
  FManual := TManualClock.Create;
  FClock := FManual;
  FProfile := TKeenLoopProfile.Create(FClock);
end;

procedure TTestKeenLoopProfile.TearDown;
begin
  FProfile.Free;
  FClock := nil;
  FManual := nil;
end;

procedure TTestKeenLoopProfile.DovrebbeSommareITempiDiOgniParte;
begin
  FProfile.Enter(klsSleep);
  FManual.Advance(3);
  FProfile.Leave;
  FProfile.Enter(klsSleep);
  FManual.Advance(2);
  FProfile.Leave;
  FProfile.Enter(klsPicture);
  FManual.Advance(1);
  FProfile.Leave;
  Assert.AreEqual<Int64>(5, Round(FProfile.Seconds(klsSleep) * 1000));
  Assert.AreEqual<Int64>(1, Round(FProfile.Seconds(klsPicture) * 1000));
  Assert.AreEqual<Int64>(0, Round(FProfile.Seconds(klsMessages) * 1000));
end;

procedure TTestKeenLoopProfile.DovrebbeContareLeVolteDiOgniParte;
begin
  FProfile.Enter(klsAudio);
  FProfile.Leave;
  FProfile.Enter(klsAudio);
  FProfile.Leave;
  FProfile.Enter(klsMessages);
  FProfile.Leave;
  Assert.AreEqual(2, FProfile.Count(klsAudio));
  Assert.AreEqual(1, FProfile.Count(klsMessages));
  Assert.AreEqual(0, FProfile.Count(klsSleep));
end;

procedure TTestKeenLoopProfile.DovrebbeTenerePresenteLaPiuLungaEQuelleOltreCinqMillisecondi;
var
  LSummary: string;
begin
  FProfile.Enter(klsSleep);
  FManual.Advance(2);
  FProfile.Leave;
  FProfile.Enter(klsSleep);
  FManual.Advance(16);
  FProfile.Leave;
  LSummary := FProfile.Summary(70, 0);
  Assert.IsTrue(ContainsText(LSummary, 'sleep 2 calls'), LSummary);
  Assert.IsTrue(ContainsText(LSummary, 'longest 16.0 ms, 1 over 5 ms'), LSummary);
end;

procedure TTestKeenLoopProfile.DovrebbeContareITicAlSecondo;
begin
  FManual.Advance(2000);
  Assert.AreEqual(140, FProfile.Tics(70));
  Assert.AreEqual(2.0, FProfile.Elapsed, 0.0001);
end;

procedure TTestKeenLoopProfile.DovrebbeDireLaVelocitaDelGioco;
var
  LSummary: string;
begin
  FManual.Advance(2000);
  LSummary := FProfile.Summary(70, 70);
  Assert.IsTrue(StartsText('speed: 70.0 tics/s, 35.0 refreshes/s, 0.0 pictures/s', LSummary), LSummary);
  // nothing was measured in a part: the whole time is the game
  Assert.IsTrue(ContainsText(LSummary, 'game 2.000 s'), LSummary);
end;

procedure TTestKeenLoopProfile.DovrebbeContareLaVelocitaDopoIlSegno;
var
  LSummary: string;
begin
  FManual.Advance(3000);
  FProfile.Mark(100);
  FManual.Advance(2000);
  LSummary := FProfile.Summary(70, 170);
  Assert.IsTrue(ContainsText(LSummary, 'steady 35.0 refreshes/s (after 3.0 s)'), LSummary);
end;

procedure TTestKeenLoopProfile.IlSegnoDovrebbeValereUnaSolaVolta;
begin
  Assert.IsFalse(FProfile.IsMarked);
  FManual.Advance(1000);
  FProfile.Mark(10);
  FManual.Advance(1000);
  FProfile.Mark(999);
  Assert.IsTrue(FProfile.IsMarked);
  Assert.IsTrue(ContainsText(FProfile.Summary(70, 20), 'steady 10.0 refreshes/s (after 1.0 s)'));
end;

procedure TTestKeenLoopProfile.DovrebbeRifiutareUnOrologioNil;
var
  LNone: IClock;
begin
  LNone := nil;
  Assert.WillRaise(
    procedure
    begin
      TKeenLoopProfile.Create(LNone).Free;
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenLoopProfile);

end.
