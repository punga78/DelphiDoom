{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the names of the actions                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Actions.Names;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Actions.Names;

type
  [TestFixture]
  [Category('actions')]
  TTestActionsNames = class(TObject)
  public
    [Test]
    [TestCase('semplice', 'A_Look(),A_Look')]
    [TestCase('con spazio', 'A_Chase (x: integer),A_Chase')]
    [TestCase('con punto e virgola', 'A_Fall;,A_Fall')]
    [TestCase('con parentesi quadra', 'A_Foo[x],A_Foo')]
    [TestCase('con due punti', 'A_Foo:x,A_Foo')]
    procedure DovrebbeTagliareLaDichiarazioneAlPrimoSeparatore(const ADeclaration, AExpected: string);
    [Test]
    procedure DovrebbeDareLaDichiarazioneIntegraSeNonCeSeparatore;
    [Test]
    procedure DovrebbeTogliereGliSpaziAlTaglio;
    [Test]
    procedure DovrebbeDareStringaVuotaPerUnaDichiarazioneVuota;
    [Test]
    procedure DovrebbeTogliereILPrefissoInQualsiasiMaiuscola;
    [Test]
    procedure DovrebbeTogliereSoloUnPrefisso;
    [Test]
    procedure DovrebbeLasciareUnNomeSenzaPrefisso;
    [Test]
    procedure DovrebbeLasciareUnNomeTroppoCorto;
    [Test]
    procedure DovrebbeNormalizzareInMaiuscolo;
    [Test]
    procedure DovrebbeMettereInMaiuscoloSoloLeLettereAscii;
  end;

implementation

{ TTestActionsNames }

procedure TTestActionsNames.DovrebbeTagliareLaDichiarazioneAlPrimoSeparatore(const ADeclaration, AExpected: string);
begin
  Assert.AreEqual(AExpected, TActionNames.FromDeclaration(ADeclaration));
end;

procedure TTestActionsNames.DovrebbeDareLaDichiarazioneIntegraSeNonCeSeparatore;
begin
  Assert.AreEqual('NULL', TActionNames.FromDeclaration('NULL'));
end;

procedure TTestActionsNames.DovrebbeTogliereGliSpaziAlTaglio;
begin
  Assert.AreEqual('A_Look', TActionNames.FromDeclaration('A_Look  ()'));
  Assert.AreEqual('', TActionNames.FromDeclaration(' ()'));
end;

procedure TTestActionsNames.DovrebbeDareStringaVuotaPerUnaDichiarazioneVuota;
begin
  Assert.AreEqual('', TActionNames.FromDeclaration(''));
end;

procedure TTestActionsNames.DovrebbeTogliereILPrefissoInQualsiasiMaiuscola;
begin
  Assert.AreEqual('Look', TActionNames.StripPrefix('A_Look'));
  Assert.AreEqual('Look', TActionNames.StripPrefix('a_Look'));
end;

procedure TTestActionsNames.DovrebbeTogliereSoloUnPrefisso;
begin
  Assert.AreEqual('A_Look', TActionNames.StripPrefix('A_A_Look'));
end;

procedure TTestActionsNames.DovrebbeLasciareUnNomeSenzaPrefisso;
begin
  Assert.AreEqual('Look', TActionNames.StripPrefix('Look'));
  Assert.AreEqual('AX_Look', TActionNames.StripPrefix('AX_Look'));
end;

procedure TTestActionsNames.DovrebbeLasciareUnNomeTroppoCorto;
begin
  Assert.AreEqual('A', TActionNames.StripPrefix('A'));
  Assert.AreEqual('', TActionNames.StripPrefix('A_'));
  Assert.AreEqual('', TActionNames.StripPrefix(''));
end;

procedure TTestActionsNames.DovrebbeNormalizzareInMaiuscolo;
begin
  Assert.AreEqual('LOOK', TActionNames.Normalize('a_look'));
  Assert.AreEqual('LOOK', TActionNames.Normalize('LOOK'));
end;

procedure TTestActionsNames.DovrebbeMettereInMaiuscoloSoloLeLettereAscii;
begin
  Assert.AreEqual('ABC_123' + #$E0, TActionNames.UpperAscii('abc_123' + #$E0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestActionsNames);

end.
