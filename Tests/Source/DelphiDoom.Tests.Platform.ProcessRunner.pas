{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - a program in the background     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.ProcessRunner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Platform.Intf;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformProcessRunner = class(TObject)
  private
    FRunner: IProcessRunner;
    function Capture(const ACommand: string; out AText: string): Boolean;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareLUscitaDelProgramma;
    [Test]
    procedure DovrebbeDareAnchePiuDiUnBlocco;
    [Test]
    procedure DovrebbeDareLUscitaDiErrore;
    [Test]
    procedure DovrebbeDareVeroAncheSeIlProgrammaFinisceConUnErrore;
    [Test]
    procedure DovrebbeDareFalsoSeIlProgrammaNonPartela;
    [Test]
    procedure DovrebbeAccettareUnaUscitaNil;
    [Test]
    procedure DovrebbeNonTrattareIlPercentoComeFormato;
    [Test]
    procedure DovrebbeNonModificareLaRigaDiComando;
  end;

implementation

uses
  DelphiDoom.Platform.Factory;

{ TTestPlatformProcessRunner }

procedure TTestPlatformProcessRunner.Setup;
begin
  FRunner := TPlatformFactory.CreateProcessRunner;
end;

function TTestPlatformProcessRunner.Capture(const ACommand: string; out AText: string): Boolean;
var
  LText: string;
begin
  LText := '';
  Result := FRunner.Run(ACommand,
    procedure(const AChunk: AnsiString)
    begin
      LText := LText + string(AChunk);
    end);
  AText := LText;
end;

procedure TTestPlatformProcessRunner.DovrebbeDareLUscitaDelProgramma;
var
  LText: string;
begin
  Assert.IsTrue(Capture('cmd.exe /c echo ciao mondo', LText));
  Assert.IsTrue(Pos('ciao mondo', LText) > 0);
end;

procedure TTestPlatformProcessRunner.DovrebbeDareAnchePiuDiUnBlocco;
var
  LText: string;
begin
  // 400 righe: piu di 1024 byte, cioe piu di una lettura del buffer
  Assert.IsTrue(Capture('cmd.exe /c for /l %i in (1,1,400) do @echo riga numero %i', LText));
  Assert.IsTrue(Length(LText) > 1024);
  Assert.IsTrue(Pos('riga numero 400', LText) > 0);
end;

procedure TTestPlatformProcessRunner.DovrebbeDareLUscitaDiErrore;
var
  LText: string;
begin
  Assert.IsTrue(Capture('cmd.exe /c echo errore 1>&2', LText));
  Assert.IsTrue(Pos('errore', LText) > 0);
end;

procedure TTestPlatformProcessRunner.DovrebbeDareVeroAncheSeIlProgrammaFinisceConUnErrore;
var
  LText: string;
begin
  Assert.IsTrue(Capture('cmd.exe /c exit 3', LText));
end;

procedure TTestPlatformProcessRunner.DovrebbeDareFalsoSeIlProgrammaNonPartela;
var
  LText: string;
begin
  Assert.IsFalse(Capture('C:\non\esiste\mai.exe', LText));
  Assert.AreEqual('', LText);
end;

procedure TTestPlatformProcessRunner.DovrebbeAccettareUnaUscitaNil;
begin
  Assert.IsTrue(FRunner.Run('cmd.exe /c echo muto', nil));
end;

procedure TTestPlatformProcessRunner.DovrebbeNonTrattareIlPercentoComeFormato;
var
  LText: string;
begin
  Assert.IsTrue(Capture('cmd.exe /c echo 100%% %s %d', LText));
  Assert.IsTrue(Pos('%s', LText) > 0);
end;

procedure TTestPlatformProcessRunner.DovrebbeNonModificareLaRigaDiComando;
var
  LCommand: string;
  LText: string;
begin
  LCommand := 'cmd.exe /c echo x';
  Capture(LCommand, LText);
  Assert.AreEqual('cmd.exe /c echo x', LCommand);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformProcessRunner);

end.
