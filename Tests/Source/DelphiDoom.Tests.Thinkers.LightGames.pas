{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of what each game has for its lights                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightGames;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightGames = class(TObject)
  public
    [Test]
    procedure DovrebbeRiconoscereIQuattroGiochiSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareFalsoPerUnGiocoSconosciuto;
    [Test]
    procedure DovrebbeDareIlNomeDiOgniGioco;
    [Test]
    procedure DovrebbeDareISpecialDiDoomEStrife;
    [Test]
    procedure DovrebbeDareISpecialDiHeretic;
    [Test]
    procedure DovrebbeDareISpecialDiHexen;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Games;

{ TTestThinkersLightGames }

procedure TTestThinkersLightGames.DovrebbeRiconoscereIQuattroGiochiSenzaDistinguereLeMaiuscole;
var
  LGame: TLightGame;
begin
  Assert.IsTrue(TLightGames.TryFromName('Doom', LGame));
  Assert.AreEqual(Ord(TLightGame.Doom), Ord(LGame));
  Assert.IsTrue(TLightGames.TryFromName('HERETIC', LGame));
  Assert.AreEqual(Ord(TLightGame.Heretic), Ord(LGame));
  Assert.IsTrue(TLightGames.TryFromName('hexen', LGame));
  Assert.AreEqual(Ord(TLightGame.Hexen), Ord(LGame));
  Assert.IsTrue(TLightGames.TryFromName('Strife', LGame));
  Assert.AreEqual(Ord(TLightGame.Strife), Ord(LGame));
end;

procedure TTestThinkersLightGames.DovrebbeDareFalsoPerUnGiocoSconosciuto;
var
  LGame: TLightGame;
begin
  Assert.IsFalse(TLightGames.TryFromName('Quake', LGame));
end;

procedure TTestThinkersLightGames.DovrebbeDareIlNomeDiOgniGioco;
begin
  Assert.AreEqual('DOOM', TLightGames.NameOf(TLightGame.Doom));
  Assert.AreEqual('HERETIC', TLightGames.NameOf(TLightGame.Heretic));
  Assert.AreEqual('HEXEN', TLightGames.NameOf(TLightGame.Hexen));
  Assert.AreEqual('STRIFE', TLightGames.NameOf(TLightGame.Strife));
end;

procedure TTestThinkersLightGames.DovrebbeDareISpecialDiDoomEStrife;
var
  LProfile: TLightSequenceProfile;
begin
  LProfile := TLightGames.SequenceProfile(TLightGame.Doom);
  Assert.AreEqual(22, LProfile.SequenceStart);
  Assert.AreEqual(23, LProfile.Sequence);
  Assert.AreEqual(24, LProfile.SequenceAlt);
  Assert.AreEqual(31, LProfile.PhaseMask);
  LProfile := TLightGames.SequenceProfile(TLightGame.Strife);
  Assert.AreEqual(22, LProfile.SequenceStart);
  Assert.AreEqual(31, LProfile.PhaseMask);
end;

procedure TTestThinkersLightGames.DovrebbeDareISpecialDiHeretic;
var
  LProfile: TLightSequenceProfile;
begin
  LProfile := TLightGames.SequenceProfile(TLightGame.Heretic);
  Assert.AreEqual(52, LProfile.SequenceStart);
  Assert.AreEqual(53, LProfile.Sequence);
  Assert.AreEqual(54, LProfile.SequenceAlt);
  Assert.AreEqual($FFFF, LProfile.PhaseMask);
end;

procedure TTestThinkersLightGames.DovrebbeDareISpecialDiHexen;
var
  LProfile: TLightSequenceProfile;
begin
  LProfile := TLightGames.SequenceProfile(TLightGame.Hexen);
  Assert.AreEqual(2, LProfile.SequenceStart);
  Assert.AreEqual(3, LProfile.Sequence);
  Assert.AreEqual(4, LProfile.SequenceAlt);
  Assert.AreEqual($FFFF, LProfile.PhaseMask);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightGames);

end.
