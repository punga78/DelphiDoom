{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - TCommandLineCursor          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Cursor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineCursor = class(TObject)
  private
    function Make(const AArguments: TArray<string>): ICommandLineCursor;
  public
    [Test]
    procedure DovrebbePartireDopoIlNomeDelProgramma;
    [Test]
    procedure DovrebbeDareFalsoSeNonCiSonoArgomenti;
    [Test]
    procedure IlNomeDovrebbeEssereInMinuscoloEIlValoreComeScritto;
    [Test]
    procedure DovrebbeLeggereUnParametroRipetuto;
    [Test]
    procedure DovrebbeLeggerePiuValoriDiUnParametro;
    [Test]
    procedure IRimanentiDovrebberoScendereAZero;
    [Test]
    procedure DovrebbeSollevareSeIlValoreManca;
    [Test]
    procedure DovrebbeLeggereUnNumeroIntero;
    [Test]
    procedure DovrebbeSollevareSeIlNumeroNonLoE;
    [Test]
    procedure DovrebbeSollevareSenzaRigaDiComando;
    [Test]
    procedure DovrebbeLeggereAncheLaRigaInMaiuscoloDelMotore;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types, DelphiDoom.CommandLine.Factory, DelphiDoom.CommandLine.ProgramFactory;

function TTestCommandLineCursor.Make(const AArguments: TArray<string>): ICommandLineCursor;
begin
  Result := TProgramCommandLineFactory.CreateCursor(TProgramCommandLineFactory.CreateCommandLine(AArguments));
end;

procedure TTestCommandLineCursor.DovrebbePartireDopoIlNomeDelProgramma;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['-program', '-list']);
  Assert.IsTrue(LCursor.Next(LName));
  Assert.AreEqual('-list', LName);
  Assert.IsFalse(LCursor.Next(LName));
  Assert.AreEqual('', LName);
end;

procedure TTestCommandLineCursor.DovrebbeDareFalsoSeNonCiSonoArgomenti;
var
  LName: string;
begin
  Assert.IsFalse(Make(['p']).Next(LName));
  Assert.IsFalse(Make(nil).Next(LName));
  Assert.AreEqual(0, Make(nil).Remaining);
end;

procedure TTestCommandLineCursor.IlNomeDovrebbeEssereInMinuscoloEIlValoreComeScritto;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-VERSION', 'Parity MiXed 1.0']);
  Assert.IsTrue(LCursor.Next(LName));
  Assert.AreEqual('-version', LName, False);
  Assert.AreEqual('Parity MiXed 1.0', LCursor.Value, False);
end;

procedure TTestCommandLineCursor.DovrebbeLeggereUnParametroRipetuto;
var
  LCursor: ICommandLineCursor;
  LName: string;
  LFolders: TArray<string>;
begin
  LCursor := Make(['p', '-data', 'Uno', '-list', '-Data', 'Due']);
  while LCursor.Next(LName) do
    if LName = '-data' then
      LFolders := LFolders + [LCursor.Value];
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual('Uno', LFolders[0], False);
  Assert.AreEqual('Due', LFolders[1], False);
end;

procedure TTestCommandLineCursor.DovrebbeLeggerePiuValoriDiUnParametro;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-view', '2', '3', '-png', 'a.png']);
  Assert.IsTrue(LCursor.Next(LName));
  Assert.IsTrue(LCursor.Remaining >= 2);
  Assert.AreEqual(2, LCursor.IntegerValue);
  Assert.AreEqual(3, LCursor.IntegerValue);
  Assert.IsTrue(LCursor.Next(LName));
  Assert.AreEqual('-png', LName);
end;

procedure TTestCommandLineCursor.IRimanentiDovrebberoScendereAZero;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-map', '4']);
  Assert.AreEqual(2, LCursor.Remaining);
  LCursor.Next(LName);
  Assert.AreEqual(1, LCursor.Remaining);
  LCursor.Value;
  Assert.AreEqual(0, LCursor.Remaining);
  LCursor.Next(LName);
  Assert.AreEqual(0, LCursor.Remaining);
end;

procedure TTestCommandLineCursor.DovrebbeSollevareSeIlValoreManca;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-Data']);
  LCursor.Next(LName);
  Assert.WillRaiseWithMessage(
    procedure
    begin
      LCursor.Value;
    end, ECommandLineException, '-data needs a value');
end;

procedure TTestCommandLineCursor.DovrebbeLeggereUnNumeroIntero;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-ticks', '-140']);
  LCursor.Next(LName);
  Assert.AreEqual(-140, LCursor.IntegerValue);
end;

procedure TTestCommandLineCursor.DovrebbeSollevareSeIlNumeroNonLoE;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  LCursor := Make(['p', '-map', 'tre']);
  LCursor.Next(LName);
  Assert.WillRaise(
    procedure
    begin
      LCursor.IntegerValue;
    end, ECommandLineException);
end;

procedure TTestCommandLineCursor.DovrebbeSollevareSenzaRigaDiComando;
begin
  Assert.WillRaise(
    procedure
    begin
      TProgramCommandLineFactory.CreateCursor(nil);
    end, EArgumentNilException);
end;

procedure TTestCommandLineCursor.DovrebbeLeggereAncheLaRigaInMaiuscoloDelMotore;
var
  LCursor: ICommandLineCursor;
  LName: string;
begin
  // the cursor works on any ICommandLine: with the one of the engine the values come upper case
  LCursor := TProgramCommandLineFactory.CreateCursor(
    TCommandLineFactory.CreateCommandLine(['doom32', '-File', 'a.wad']));
  Assert.IsTrue(LCursor.Next(LName));
  Assert.AreEqual('-file', LName, False);
  Assert.AreEqual('A.WAD', LCursor.Value, False);
end;

end.
