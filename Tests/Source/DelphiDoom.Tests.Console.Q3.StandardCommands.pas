{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands of cmd.c of the Quake III console         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.StandardCommands;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.CommandArguments,
  DelphiDoom.Console.Q3.CommandSystem, DelphiDoom.Console.Q3.CommandBuffer,
  DelphiDoom.Console.Q3.StandardCommands, DelphiDoom.Tests.Console.Q3.Fakes;

type
  TFakeCVarReader = class(TInterfacedObject, IQ3CVarReader)
  public
    Text: AnsiString;
    function VariableValue(const AName: AnsiString): Single;
    function VariableIntegerValue(const AName: AnsiString): Integer;
    function VariableString(const AName: AnsiString): AnsiString;
    function VariableStringBuffer(const AName: AnsiString; ASize: Integer): AnsiString;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3StandardCommands = class(TObject)
  private
    FArguments: IQ3CommandArguments;
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FFiles: TFakeQ3Files;
    FFilesIntf: IQ3FileSystem;
    FReader: TFakeCVarReader;
    FReaderIntf: IQ3CVarReader;
    FRegistry: IQ3CommandRegistry;
    FBuffer: IQ3CommandBuffer;
    FCommands: TQ3StandardCommands;
    procedure Run(const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareArgomentiNil;
    [Test]
    procedure DovrebbeRegistrareICinqueComandi;
    [Test]
    procedure DovrebbeElencareIComandiConUnaMaschera;
    [Test]
    procedure DovrebbeEseguireUnFileAggiungendoLEstensione;
    [Test]
    procedure DovrebbeDireCheNonRiesceAEseguireUnFileMancante;
    [Test]
    procedure DovrebbeDareLUsoDiExecConUnNumeroSbagliatoDiArgomenti;
    [Test]
    procedure DovrebbeTagliareIlNomeDelFileESegnalareLOverflow;
    [Test]
    procedure DovrebbeInserireIlValoreDiUnaVariabileConVstr;
    [Test]
    procedure DovrebbeDareLUsoDiVstr;
    [Test]
    procedure DovrebbeScrivereGliArgomentiConEcho;
    [Test]
    procedure DovrebbeImpostareIlWaitDelBuffer;
    [Test]
    procedure DovrebbeFunzionareSenzaLogFileEVariabili;
  end;

implementation

function TFakeCVarReader.VariableValue(const AName: AnsiString): Single;
begin
  Result := 0;
end;

function TFakeCVarReader.VariableIntegerValue(const AName: AnsiString): Integer;
begin
  Result := 0;
end;

function TFakeCVarReader.VariableString(const AName: AnsiString): AnsiString;
begin
  Result := Text;
end;

function TFakeCVarReader.VariableStringBuffer(const AName: AnsiString; ASize: Integer): AnsiString;
begin
  Result := Copy(Text, 1, ASize - 1);
end;

procedure TTestQ3StandardCommands.Setup;
begin
  FArguments := TQ3CommandArguments.Create;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FFiles := TFakeQ3Files.Create;
  FFilesIntf := FFiles;
  FReader := TFakeCVarReader.Create;
  FReaderIntf := FReader;
  FRegistry := TQ3CommandSystem.Create(FArguments, FLogIntf);
  FBuffer := TQ3CommandBuffer.Create(FRegistry, FLogIntf);
  FCommands := TQ3StandardCommands.Create(FRegistry, FBuffer, FArguments, FReaderIntf, FLogIntf, FFilesIntf);
  FCommands.Init;
end;

procedure TTestQ3StandardCommands.TearDown;
begin
  FCommands.Free;
end;

procedure TTestQ3StandardCommands.Run(const AText: AnsiString);
begin
  FRegistry.ExecuteString(AText);
end;

procedure TTestQ3StandardCommands.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3StandardCommands.Create(nil, FBuffer, FArguments);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3StandardCommands.Create(FRegistry, nil, FArguments);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3StandardCommands.Create(FRegistry, FBuffer, nil);
    end, EArgumentNilException);
end;

procedure TTestQ3StandardCommands.DovrebbeRegistrareICinqueComandi;
begin
  Assert.AreEqual<Integer>(5, Length(FRegistry.CommandNames));
end;

procedure TTestQ3StandardCommands.DovrebbeElencareIComandiConUnaMaschera;
begin
  Run('cmdlist e*');
  Assert.AreEqual('echo'#10'exec'#10'2 commands'#10, FLog.TakePrinted);
  Run('cmdlist');
  Assert.Contains(FLog.TakePrinted, '5 commands');
end;

procedure TTestQ3StandardCommands.DovrebbeEseguireUnFileAggiungendoLEstensione;
begin
  FFiles.AddFile('config.cfg', 'echo hi');
  Run('exec config');
  Assert.AreEqual('execing config'#10, FLog.TakePrinted);
  Assert.AreEqual('echo hi'#10, string(FBuffer.Pending));
  Run('exec config.cfg');
  Assert.AreEqual('execing config.cfg'#10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeDireCheNonRiesceAEseguireUnFileMancante;
begin
  Run('exec nofile');
  Assert.AreEqual('couldn''t exec nofile'#10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeDareLUsoDiExecConUnNumeroSbagliatoDiArgomenti;
begin
  Run('exec');
  Assert.AreEqual('exec <filename> : execute a script file'#10, FLog.TakePrinted);
  Run('exec a b');
  Assert.AreEqual('exec <filename> : execute a script file'#10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeTagliareIlNomeDelFileESegnalareLOverflow;
var
  LName: string;
begin
  LName := StringOfChar('a', 70);
  Run(AnsiString('exec ' + LName));
  Assert.AreEqual('Com_sprintf: overflow of 67 in 64'#10'couldn''t exec ' + LName + #10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeInserireIlValoreDiUnaVariabileConVstr;
begin
  FReader.Text := 'echo from var';
  Run('vstr myvar');
  // vstr adds a line feed and the insertion adds another one, as in the original
  Assert.AreEqual('echo from var'#10#10, string(FBuffer.Pending));
end;

procedure TTestQ3StandardCommands.DovrebbeDareLUsoDiVstr;
begin
  Run('vstr');
  Assert.AreEqual('vstr <variablename> : execute a variable command'#10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeScrivereGliArgomentiConEcho;
begin
  Run('echo a "b c"');
  Assert.AreEqual('a b c '#10, FLog.TakePrinted);
end;

procedure TTestQ3StandardCommands.DovrebbeImpostareIlWaitDelBuffer;
begin
  Run('wait');
  Assert.AreEqual(1, FBuffer.Wait);
  Run('wait 5');
  Assert.AreEqual(5, FBuffer.Wait);
  Run('wait 1 2');
  Assert.AreEqual(1, FBuffer.Wait);
end;

procedure TTestQ3StandardCommands.DovrebbeFunzionareSenzaLogFileEVariabili;
var
  LCommands: TQ3StandardCommands;
begin
  LCommands := TQ3StandardCommands.Create(FRegistry, FBuffer, FArguments);
  try
    FArguments.Tokenize('exec x');
    LCommands.Exec;
    FArguments.Tokenize('vstr x');
    LCommands.Vstr;
    FArguments.Tokenize('echo x');
    LCommands.Echo;
    FArguments.Tokenize('cmdlist');
    LCommands.List;
    Assert.AreEqual(''#10#10, string(FBuffer.Pending));
  finally
    LCommands.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3StandardCommands);

end.
