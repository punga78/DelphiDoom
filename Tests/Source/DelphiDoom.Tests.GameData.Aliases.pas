{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGameAliases                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameData.Aliases;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('gamedata')]
  TTestGameDataAliases = class(TObject)
  public
    [Test]
    [TestCase('Doom', 'Doom')]
    [TestCase('Heretic', 'Heretic')]
    [TestCase('Hexen', 'Hexen')]
    [TestCase('Strife', 'Strife')]
    procedure DovrebbeLasciareIQuattroGiochiDelMotoreComeSono(const AGame: string);
    [Test]
    procedure DovrebbeDareIlProfiloDiDoomAlleRegoleCheCoincidonoPerSpeed;
    [Test]
    procedure DovrebbeLasciareSpeedSenzaProfiloDellIwad;
    [Test]
    procedure DovrebbeRiconoscereSpeedSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeLasciareUnNomeSconosciutoCosiCheLaLibreriaDiaErrore;
    [Test]
    procedure DovrebbeDireCheSoloSpeedEUnAlias;
    [Test]
    procedure DovrebbeDareIlProfiloDiDoomATuttiIFormatiEAlleRegolePerRadix;
    [Test]
    procedure DovrebbeLasciareRadixConIlProprioProfiloIwad;
  end;

implementation

uses
  DelphiDoom.GameData.Aliases;

{ TTestGameDataAliases }

procedure TTestGameDataAliases.DovrebbeLasciareIQuattroGiochiDelMotoreComeSono(const AGame: string);
var
  LArea: TGameProfileArea;
begin
  for LArea := Low(TGameProfileArea) to High(TGameProfileArea) do
    Assert.AreEqual(AGame, TGameAliases.ProfileOf(AGame, LArea));
end;

procedure TTestGameDataAliases.DovrebbeDareIlProfiloDiDoomAlleRegoleCheCoincidonoPerSpeed;
begin
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.Lights));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.Platforms));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.Doors));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.Udmf));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.Dehacked));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.ActorDef));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Speed', TGameProfileArea.TableExport));
end;

procedure TTestGameDataAliases.DovrebbeLasciareSpeedSenzaProfiloDellIwad;
begin
  Assert.AreEqual('Speed', TGameAliases.ProfileOf('Speed', TGameProfileArea.Iwad));
end;

procedure TTestGameDataAliases.DovrebbeRiconoscereSpeedSenzaDistinguereLeMaiuscole;
begin
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('SPEED', TGameProfileArea.Doors));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('speed', TGameProfileArea.Doors));
end;

procedure TTestGameDataAliases.DovrebbeLasciareUnNomeSconosciutoCosiCheLaLibreriaDiaErrore;
begin
  Assert.AreEqual('Quake', TGameAliases.ProfileOf('Quake', TGameProfileArea.Doors));
  Assert.AreEqual('', TGameAliases.ProfileOf('', TGameProfileArea.Lights));
end;

procedure TTestGameDataAliases.DovrebbeDireCheSoloSpeedEUnAlias;
begin
  Assert.IsTrue(TGameAliases.IsAlias('Speed'));
  Assert.IsFalse(TGameAliases.IsAlias('Doom'));
  Assert.IsFalse(TGameAliases.IsAlias('Hexen'));
  Assert.IsFalse(TGameAliases.IsAlias(''));
  Assert.IsTrue(TGameAliases.IsAlias('radix'));
end;

procedure TTestGameDataAliases.DovrebbeDareIlProfiloDiDoomATuttiIFormatiEAlleRegolePerRadix;
begin
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.Lights));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.Platforms));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('RADIX', TGameProfileArea.Doors));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.Dehacked));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.ActorDef));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.TableExport));
  Assert.AreEqual('Doom', TGameAliases.ProfileOf('Radix', TGameProfileArea.Udmf));
end;

procedure TTestGameDataAliases.DovrebbeLasciareRadixConIlProprioProfiloIwad;
begin
  Assert.AreEqual('Radix', TGameAliases.ProfileOf('Radix', TGameProfileArea.Iwad));
end;

end.

