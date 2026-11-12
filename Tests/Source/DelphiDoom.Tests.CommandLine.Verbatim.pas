{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - TVerbatimCommandLine        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Verbatim;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineVerbatim = class(TObject)
  public
    [Test]
    procedure DovrebbeConservareLeMaiuscoleDegliArgomenti;
    [Test]
    procedure DovrebbeTrovareUnParametroSenzaGuardareLeMaiuscole;
    [Test]
    procedure NonDovrebbeMaiRispondereIlNomeDelProgramma;
    [Test]
    procedure DovrebbeDareZeroSeIlParametroManca;
    [Test]
    procedure DovrebbeVincereLaPrimaOccorrenza;
    [Test]
    procedure IValoriDopoDovrebberoFermarsiAlParametroSeguente;
    [Test]
    procedure IValoriDopoDovrebberoEssereVuotiSeIlParametroManca;
    [Test]
    procedure IlTestoDovrebbeEssereGliArgomentiComeScritti;
    [Test]
    procedure DovrebbeSollevareSeLaPosizioneNonEsiste;
    [Test]
    procedure NonDovrebbeCambiareSeIlChiamanteCambiaIlSuoArray;
    [Test]
    procedure LaRigaDelProcessoDovrebbeAvereIlProgrammaInPosizioneZero;
    [Test]
    procedure LaRigaDelMotoreDovrebbeRestareInMaiuscolo;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types, DelphiDoom.CommandLine.Factory, DelphiDoom.CommandLine.ProgramFactory;

procedure TTestCommandLineVerbatim.DovrebbeConservareLeMaiuscoleDegliArgomenti;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['Xcom32.exe', '-Version', 'Parity MiXed 1.0', '-script',
    'until:MainMenuState,5000']);
  Assert.AreEqual(5, LLine.Count);
  Assert.AreEqual('Xcom32.exe', LLine[0], False);
  Assert.AreEqual('-Version', LLine[1], False);
  Assert.AreEqual('Parity MiXed 1.0', LLine[2], False);
  Assert.AreEqual('until:MainMenuState,5000', LLine[4], False);
end;

procedure TTestCommandLineVerbatim.DovrebbeTrovareUnParametroSenzaGuardareLeMaiuscole;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-Data', 'C:\Giochi', '-SHOT', 'a.png']);
  Assert.AreEqual(1, LLine.IndexOf('-data'));
  Assert.AreEqual(3, LLine.IndexOf('-shot'));
  Assert.IsTrue(LLine.Has('-DATA'));
end;

procedure TTestCommandLineVerbatim.NonDovrebbeMaiRispondereIlNomeDelProgramma;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['-list', 'x']);
  Assert.AreEqual(0, LLine.IndexOf('-list'));
  Assert.IsFalse(LLine.Has('-list'));
end;

procedure TTestCommandLineVerbatim.DovrebbeDareZeroSeIlParametroManca;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-a']);
  Assert.AreEqual(0, LLine.IndexOf('-b'));
  Assert.AreEqual(0, TProgramCommandLineFactory.CreateCommandLine(nil).IndexOf('-b'));
  Assert.AreEqual(0, TProgramCommandLineFactory.CreateCommandLine(nil).Count);
end;

procedure TTestCommandLineVerbatim.DovrebbeVincereLaPrimaOccorrenza;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-data', 'a', '-DATA', 'b']);
  Assert.AreEqual(1, LLine.IndexOf('-Data'));
end;

procedure TTestCommandLineVerbatim.IValoriDopoDovrebberoFermarsiAlParametroSeguente;
var
  LLine: ICommandLine;
  LValues: TArray<string>;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-file', 'Uno.wad', 'Due.WAD', '-warp', '1']);
  LValues := LLine.ValuesAfter('-FILE');
  Assert.AreEqual(2, Integer(Length(LValues)));
  Assert.AreEqual('Uno.wad', LValues[0], False);
  Assert.AreEqual('Due.WAD', LValues[1], False);
  LValues := LLine.ValuesAfter('-warp');
  Assert.AreEqual(1, Integer(Length(LValues)));
  Assert.AreEqual('1', LValues[0], False);
end;

procedure TTestCommandLineVerbatim.IValoriDopoDovrebberoEssereVuotiSeIlParametroManca;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-a', '-b']);
  Assert.AreEqual(0, Integer(Length(LLine.ValuesAfter('-c'))));
  Assert.AreEqual(0, Integer(Length(LLine.ValuesAfter('-a'))));
  Assert.AreEqual(0, Integer(Length(LLine.ValuesAfter('-b'))));
end;

procedure TTestCommandLineVerbatim.IlTestoDovrebbeEssereGliArgomentiComeScritti;
begin
  Assert.AreEqual('-Map 3 File.Png',
    TProgramCommandLineFactory.CreateCommandLine(['Keen32', '-Map', '3', 'File.Png']).Text, False);
  Assert.AreEqual('', TProgramCommandLineFactory.CreateCommandLine(['Keen32']).Text, False);
end;

procedure TTestCommandLineVerbatim.DovrebbeSollevareSeLaPosizioneNonEsiste;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateCommandLine(['p', '-a']);
  Assert.WillRaise(
    procedure
    begin
      LLine[2];
    end, ECommandLineException);
  Assert.WillRaise(
    procedure
    begin
      LLine[-1];
    end, ECommandLineException);
end;

procedure TTestCommandLineVerbatim.NonDovrebbeCambiareSeIlChiamanteCambiaIlSuoArray;
var
  LItems: TArray<string>;
  LLine: ICommandLine;
begin
  LItems := ['p', '-first'];
  LLine := TProgramCommandLineFactory.CreateCommandLine(LItems);
  LItems[1] := '-second';
  Assert.AreEqual('-first', LLine[1], False);
end;

procedure TTestCommandLineVerbatim.LaRigaDelProcessoDovrebbeAvereIlProgrammaInPosizioneZero;
var
  LLine: ICommandLine;
begin
  LLine := TProgramCommandLineFactory.CreateProcessCommandLine;
  Assert.AreEqual(ParamCount + 1, LLine.Count);
  Assert.AreEqual(ParamStr(0), LLine[0], False);
end;

procedure TTestCommandLineVerbatim.LaRigaDelMotoreDovrebbeRestareInMaiuscolo;
begin
  // the engine of Doom depends on it: the new class must not have changed the old one
  Assert.AreEqual('E1m1.Wad'.ToUpper,
    TCommandLineFactory.CreateCommandLine(['doom32.exe', '-file', 'E1m1.Wad'])[2], False);
end;

end.
