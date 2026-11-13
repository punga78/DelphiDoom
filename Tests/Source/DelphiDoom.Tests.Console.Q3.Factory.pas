{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the composition of the Quake III console               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.Factory, DelphiDoom.Tests.Console.Q3.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestQ3Factory = class(TObject)
  public
    [Test]
    procedure DovrebbeRegistrareITredicicomandiConInit;
    [Test]
    procedure DovrebbeFarEseguireUnaRigaCheNonEUnComandoComeVariabile;
    [Test]
    procedure DovrebbeEseguireUnFileDiComandi;
    [Test]
    procedure DovrebbeInoltrareLeRigheSconosciute;
    [Test]
    procedure DovrebbeFunzionareSenzaNullaDiOpzionale;
  end;

implementation

procedure TTestQ3Factory.DovrebbeRegistrareITredicicomandiConInit;
var
  LConsole: TQ3Console;
begin
  LConsole := TQ3Console.Create;
  try
    LConsole.Init;
    Assert.AreEqual<Integer>(13, Length(LConsole.Commands.CommandNames));
    Assert.IsNotNull(LConsole.CVars.Find('sv_cheats'));
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3Factory.DovrebbeFarEseguireUnaRigaCheNonEUnComandoComeVariabile;
var
  LLog: TFakeQ3Log;
  LLogIntf: IQ3ConsoleLog;
  LConsole: TQ3Console;
begin
  LLog := TFakeQ3Log.Create;
  LLogIntf := LLog;
  LConsole := TQ3Console.Create(LLogIntf);
  try
    LConsole.Init;
    LConsole.Buffer.AddText('set rate 25000;rate;vstr missing' + #10);
    LConsole.Buffer.Execute;
    Assert.AreEqual('25000', string(LConsole.CVars.VariableString('rate')));
    Assert.Contains(LLog.TakePrinted, '"rate" is:"25000^7" default:"25000^7"');
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3Factory.DovrebbeEseguireUnFileDiComandi;
var
  LFiles: TFakeQ3Files;
  LFilesIntf: IQ3FileSystem;
  LConsole: TQ3Console;
begin
  LFiles := TFakeQ3Files.Create;
  LFilesIntf := LFiles;
  LFiles.AddFile('autoexec.cfg', 'set a 1'#10'seta b 2'#10);
  LConsole := TQ3Console.Create(nil, LFilesIntf);
  try
    LConsole.Init;
    LConsole.Buffer.ExecuteText(qeAppend, 'exec autoexec');
    LConsole.Buffer.Execute;
    Assert.AreEqual('1', string(LConsole.CVars.VariableString('a')));
    Assert.AreEqual('2', string(LConsole.CVars.VariableString('b')));
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3Factory.DovrebbeInoltrareLeRigheSconosciute;
var
  LUnhandled: TFakeQ3Unhandled;
  LUnhandledIntf: IQ3UnhandledCommands;
  LConsole: TQ3Console;
begin
  LUnhandled := TFakeQ3Unhandled.Create(nil);
  LUnhandledIntf := LUnhandled;
  LConsole := TQ3Console.Create(nil, nil, LUnhandledIntf);
  try
    LConsole.Init;
    LConsole.Commands.ExecuteString('say hello');
    Assert.AreEqual<Integer>(1, Length(LUnhandled.Lines));
  finally
    LConsole.Free;
  end;
end;

procedure TTestQ3Factory.DovrebbeFunzionareSenzaNullaDiOpzionale;
var
  LConsole: TQ3Console;
begin
  LConsole := TQ3Console.Create;
  try
    LConsole.Commands.ExecuteString('anything');
    Assert.AreEqual<Integer>(0, Length(LConsole.Commands.CommandNames));
    Assert.IsNotNull(LConsole.Arguments);
  finally
    LConsole.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Factory);

end.
