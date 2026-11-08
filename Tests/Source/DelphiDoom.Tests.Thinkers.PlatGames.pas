{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the rules of the platforms of each game                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlatGames;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersPlatGames = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlNomeDiOgniGioco;
    [Test]
    procedure DovrebbeTrovareIlGiocoDalNomeSenzaMaiuscole;
    [Test]
    procedure DovrebbeDareFalsoPerUnGiocoSenzaPiattaformeClassiche;
    [Test]
    procedure DovrebbeDareLeRegoleDiDoom;
    [Test]
    procedure DovrebbeDareLeRegoleDiHeretic;
    [Test]
    procedure DovrebbeDareLeRegoleDiStrife;
  end;

implementation

uses
  DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Thinkers.Platform.Games;

{ TTestThinkersPlatGames }

procedure TTestThinkersPlatGames.DovrebbeDareIlNomeDiOgniGioco;
begin
  Assert.AreEqual('DOOM', TPlatGames.NameOf(TPlatGame.Doom));
  Assert.AreEqual('HERETIC', TPlatGames.NameOf(TPlatGame.Heretic));
  Assert.AreEqual('STRIFE', TPlatGames.NameOf(TPlatGame.Strife));
end;

procedure TTestThinkersPlatGames.DovrebbeTrovareIlGiocoDalNomeSenzaMaiuscole;
var
  LGame: TPlatGame;
begin
  Assert.IsTrue(TPlatGames.TryFromName('heretic', LGame));
  Assert.IsTrue(LGame = TPlatGame.Heretic);
  Assert.IsTrue(TPlatGames.TryFromName('Strife', LGame));
  Assert.IsTrue(LGame = TPlatGame.Strife);
  Assert.IsTrue(TPlatGames.TryFromName('DOOM', LGame));
  Assert.IsTrue(LGame = TPlatGame.Doom);
end;

procedure TTestThinkersPlatGames.DovrebbeDareFalsoPerUnGiocoSenzaPiattaformeClassiche;
var
  LGame: TPlatGame;
begin
  Assert.IsFalse(TPlatGames.TryFromName('HEXEN', LGame));
  Assert.IsFalse(TPlatGames.TryFromName('', LGame));
end;

procedure TTestThinkersPlatGames.DovrebbeDareLeRegoleDiDoom;
var
  LProfile: TPlatProfile;
begin
  LProfile := TPlatGames.ProfileOf(TPlatGame.Doom);
  Assert.IsTrue(LProfile.HasToggle);
  Assert.IsTrue(LProfile.ToggleReversesOnWake);
  Assert.IsTrue(LProfile.LowStartsAtFloor);
  Assert.IsTrue(LProfile.RemovalAtBottomNeedsModernEngine);
  Assert.IsTrue(TPlatKind.GenericLift in LProfile.RemovedAtTop);
  Assert.IsFalse(TPlatKind.SlowDownWaitUpStay in LProfile.RemovedAtTop);
  Assert.IsTrue(LProfile.MoveSoundWhileLowering = []);
end;

procedure TTestThinkersPlatGames.DovrebbeDareLeRegoleDiHeretic;
var
  LProfile: TPlatProfile;
begin
  LProfile := TPlatGames.ProfileOf(TPlatGame.Heretic);
  Assert.IsFalse(LProfile.HasToggle);
  Assert.IsFalse(LProfile.LowStartsAtFloor);
  Assert.IsTrue(LProfile.RemovedAtBottom = []);
  Assert.IsFalse(TPlatKind.GenericLift in LProfile.RemovedAtTop);
end;

procedure TTestThinkersPlatGames.DovrebbeDareLeRegoleDiStrife;
var
  LProfile: TPlatProfile;
begin
  LProfile := TPlatGames.ProfileOf(TPlatGame.Strife);
  Assert.IsTrue(LProfile.HasToggle);
  Assert.IsFalse(LProfile.ToggleReversesOnWake);
  Assert.IsFalse(LProfile.RemovalAtBottomNeedsModernEngine);
  Assert.IsTrue(TPlatKind.UpWaitDownStay in LProfile.RemovedAtBottom);
  Assert.IsTrue(TPlatKind.SlowDownWaitUpStay in LProfile.MoveSoundWhileLowering);
  Assert.IsTrue(TPlatKind.SlowDownWaitUpStay in LProfile.MoveSoundWhileRising);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersPlatGames);

end.
