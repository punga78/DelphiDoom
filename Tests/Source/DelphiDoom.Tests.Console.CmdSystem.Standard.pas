{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands of the idTech 4 command system, of the    }
{  completions and of the composition                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CmdSystem.Standard;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.IdTech4.Factory, DelphiDoom.Tests.Console.IdTech4.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestCmdStandard = class(TObject)
  private
    FLog: TFakeIdLog;
    FLogIntf: IIdLibLog;
    FFiles: TFakeIdFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FLister: TFakeFileLister;
    FListerIntf: ICmdFileLister;
    FConsole: TIdTech4Console;
    function Complete(const ACommand: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRegistrareLeUndiciComandiEIlLoroElenco;
    [Test]
    procedure DovrebbeEseguireUnFileDiComandi;
    [Test]
    procedure DovrebbeDareIlUsoDiExecSenzaOConTroppiArgomenti;
    [Test]
    procedure DovrebbeDireCheNonRiesceAEseguireUnFileAssente;
    [Test]
    procedure DovrebbeDireCheNonRiesceSenzaFileSystem;
    [Test]
    procedure DovrebbeMettereIlTestoDiUnaVariabileInCodaConVstr;
    [Test]
    procedure DovrebbeDareIlUsoDiVstr;
    [Test]
    procedure DovrebbeStampareGliArgomentiConEchoEParse;
    [Test]
    procedure DovrebbeFermareIlBufferConWaitEUnNumero;
    [Test]
    procedure DovrebbeElencareICmdPerGruppoEMaschera;
    [Test]
    procedure DovrebbeCompletareIlNomeDiUnFileDiConfigurazione;
    [Test]
    procedure DovrebbeNonElencareDiNuovoSeIlTestoNonCambia;
    [Test]
    procedure DovrebbeElencareLeCartelleEIFile;
    [Test]
    procedure DovrebbeCompletareConLeStringheEIntervalli;
    [Test]
    procedure DovrebbeFunzionareSenzaCollaboratori;
    [Test]
    procedure DovrebbeSostituireUnaVariabileNellaRiga;
  end;

implementation

uses
  DelphiDoom.Console.CmdSystem.Completions, DelphiDoom.Console.CmdSystem.FolderCompletion,
  DelphiDoom.IdLib.Text.CmdArgs;

procedure TTestCmdStandard.Setup;
begin
  FLog := TFakeIdLog.Create;
  FLogIntf := FLog;
  FFiles := TFakeIdFileSystem.Create;
  FFilesIntf := FFiles;
  FLister := TFakeFileLister.Create;
  FListerIntf := FLister;
  FConsole := TIdTech4Console.Create(FLogIntf, nil, FFilesIntf, FListerIntf);
  FConsole.Init;
end;

procedure TTestCmdStandard.TearDown;
begin
  FConsole.Free;
  FListerIntf := nil;
  FFilesIntf := nil;
  FLogIntf := nil;
end;

function TTestCmdStandard.Complete(const ACommand: string): string;
var
  LResult: string;
begin
  LResult := '';
  FConsole.Commands.ArgCompletion(AnsiString(ACommand),
    procedure(const AText: AnsiString)
    begin
      LResult := LResult + string(AText) + '|';
    end);
  Result := LResult;
end;

procedure TTestCmdStandard.DovrebbeRegistrareLeUndiciComandiEIlLoroElenco;
var
  LNames: string;
  LInfo: TCmdInfo;
begin
  Assert.AreEqual<Integer>(20, Length(FConsole.Commands.Commands), '11 of the command system and 9 of the cvars');
  for LInfo in FConsole.Commands.Commands do
    LNames := LNames + string(LInfo.Name) + ' ';
  Assert.IsTrue(LNames.StartsWith('cvar_restart listCvars reset'), LNames);
  Assert.IsTrue(LNames.EndsWith('listSystemCmds listCmds '), LNames);
end;

procedure TTestCmdStandard.DovrebbeEseguireUnFileDiComandi;
begin
  FFiles.AddFile('one.cfg', 'set a 1'#10'set b 2');
  FConsole.Buffer.BufferCommandText(ceNow, 'exec one');
  Assert.AreEqual('execing one'#10, FLog.Text);
  FConsole.Buffer.ExecuteCommandBuffer;
  Assert.AreEqual('1', string(FConsole.CVars.Find('a').GetString));
  Assert.AreEqual('2', string(FConsole.CVars.Find('b').GetString));
end;

procedure TTestCmdStandard.DovrebbeDareIlUsoDiExecSenzaOConTroppiArgomenti;
begin
  FConsole.Buffer.BufferCommandText(ceNow, 'exec');
  FConsole.Buffer.BufferCommandText(ceNow, 'exec a b');
  Assert.AreEqual('exec <filename> : execute a script file'#10'exec <filename> : execute a script file'#10, FLog.Text);
end;

procedure TTestCmdStandard.DovrebbeDireCheNonRiesceAEseguireUnFileAssente;
begin
  FConsole.Buffer.BufferCommandText(ceNow, 'exec missing');
  Assert.AreEqual('couldn''t exec missing'#10, FLog.Text);
end;

procedure TTestCmdStandard.DovrebbeDireCheNonRiesceSenzaFileSystem;
var
  LConsole: TIdTech4Console;
begin
  LConsole := TIdTech4Console.Create(FLogIntf);
  try
    LConsole.Init;
    LConsole.Buffer.BufferCommandText(ceNow, 'exec any');
    Assert.AreEqual('couldn''t exec any'#10, FLog.Text);
  finally
    LConsole.Free;
  end;
end;

procedure TTestCmdStandard.DovrebbeMettereIlTestoDiUnaVariabileInCodaConVstr;
begin
  FConsole.CVars.SetCVarString('script', 'set made yes');
  FConsole.Buffer.BufferCommandText(ceNow, 'vstr script');
  Assert.IsNull(FConsole.CVars.Find('made'), 'it is queued, not run');
  FConsole.Buffer.ExecuteCommandBuffer;
  Assert.AreEqual('yes', string(FConsole.CVars.Find('made').GetString));
end;

procedure TTestCmdStandard.DovrebbeDareIlUsoDiVstr;
begin
  FConsole.Buffer.BufferCommandText(ceNow, 'vstr');
  Assert.AreEqual('vstr <variablename> : execute a variable command'#10, FLog.Text);
end;

procedure TTestCmdStandard.DovrebbeStampareGliArgomentiConEchoEParse;
begin
  FConsole.Buffer.BufferCommandText(ceNow, 'echo a "b c"');
  FConsole.Buffer.BufferCommandText(ceNow, 'parse x "y z"');
  Assert.AreEqual('a b c '#10'0: parse'#10'1: x'#10'2: y z'#10, FLog.Text);
end;

procedure TTestCmdStandard.DovrebbeFermareIlBufferConWaitEUnNumero;
begin
  FConsole.Buffer.BufferCommandText(ceAppend, 'wait 2'#10'set a 1'#10);
  FConsole.Buffer.ExecuteCommandBuffer;
  Assert.IsNull(FConsole.CVars.Find('a'));
  FConsole.Buffer.ExecuteCommandBuffer;
  Assert.IsNull(FConsole.CVars.Find('a'));
  FConsole.Buffer.ExecuteCommandBuffer;
  Assert.IsNotNull(FConsole.CVars.Find('a'));
end;

procedure TTestCmdStandard.DovrebbeElencareICmdPerGruppoEMaschera;
begin
  FConsole.Commands.AddCommand('rendcmd', nil, CMD_FL_RENDERER, 'a renderer command');
  FConsole.Buffer.BufferCommandText(ceNow, 'listRendererCmds');
  Assert.AreEqual('  rendcmd               a renderer command'#10'1 commands'#10, FLog.Text);
  FLog.Clear;
  FConsole.Buffer.BufferCommandText(ceNow, 'listSystemCmds ec*');
  Assert.AreEqual('  echo                  prints text'#10'1 commands'#10, FLog.Text);
end;

procedure TTestCmdStandard.DovrebbeCompletareIlNomeDiUnFileDiConfigurazione;
begin
  FLister.AddName('/autoexec.cfg');
  FLister.AddName('/other.cfg');
  FLister.AddName('/readme.txt');
  Assert.AreEqual('exec autoexec.cfg|exec other.cfg|', Complete('exec x'));
end;

procedure TTestCmdStandard.DovrebbeNonElencareDiNuovoSeIlTestoNonCambia;
begin
  FLister.AddName('/a.cfg');
  Complete('exec x');
  Assert.AreEqual(2, FLister.Calls, 'one call for the folders and one for the .cfg files');
  Complete('exec x');
  Assert.AreEqual(2, FLister.Calls);
  Complete('EXEC X');
  Assert.AreEqual(2, FLister.Calls, 'not case sensitive');
  Complete('exec y');
  Assert.AreEqual(4, FLister.Calls);
end;

procedure TTestCmdStandard.DovrebbeElencareLeCartelleEIFile;
var
  LCompletion: TCmdFolderCompletion;
  LArgs: TIdCmdArgs;
  LTexts: string;
begin
  FLister.AddName('maps/e1/one.map');
  FLister.AddName('maps/e1/two.map');
  FLister.AddName('maps/start.map');
  LCompletion := TCmdFolderCompletion.Create(FListerIntf);
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString('map ', False);
    LCompletion.Complete(LArgs, procedure(const AText: AnsiString)
      begin
        LTexts := LTexts + string(AText) + '|';
      end, 'maps/', True, ['.map']);
  finally
    LArgs.Free;
    LCompletion.Free;
  end;
  Assert.AreEqual('map e1/|map start.map|', LTexts);
end;

procedure TTestCmdStandard.DovrebbeCompletareConLeStringheEIntervalli;
var
  LCompletions: TCmdCompletions;
  LArgs: TIdCmdArgs;
  LTexts: string;
  LCallback: TCmdCompletionCallback;
begin
  LCallback := procedure(const AText: AnsiString)
    begin
      LTexts := LTexts + string(AText) + '|';
    end;
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString('name', False);
    LCompletions := TCmdCompletions.Create(['red', 'green']);
    try
      LCompletions.CompleteString(LArgs, LCallback);
    finally
      LCompletions.Free;
    end;
    LCompletions := TCmdCompletions.Create(-1, 1);
    try
      LCompletions.CompleteInteger(LArgs, LCallback);
    finally
      LCompletions.Free;
    end;
  finally
    LArgs.Free;
  end;
  Assert.AreEqual('name red|name green|name -1|name 0|name 1|', LTexts);
end;

procedure TTestCmdStandard.DovrebbeFunzionareSenzaCollaboratori;
var
  LConsole: TIdTech4Console;
begin
  LConsole := TIdTech4Console.Create;
  try
    LConsole.Init;
    LConsole.Buffer.BufferCommandText(ceNow, 'set a 1');
    LConsole.Buffer.BufferCommandText(ceNow, 'echo silent');
    LConsole.Buffer.BufferCommandText(ceNow, 'unknown');
    LConsole.Buffer.BufferCommandText(ceNow, 'exec x');
    LConsole.Buffer.BufferCommandText(ceNow, 'listCmds');
    LConsole.Buffer.BufferCommandText(ceNow, 'toggle');
    LConsole.Buffer.BufferCommandText(ceNow, 'toggle missing');
    LConsole.Buffer.BufferCommandText(ceNow, 'reset');
    LConsole.Buffer.BufferCommandText(ceNow, 'a');
    LConsole.Commands.AddCommand('x', nil, 0, '');
    LConsole.Commands.AddCommand('x', nil, 0, '');
    LConsole.Shutdown;
    Assert.AreEqual<Integer>(0, Length(LConsole.Commands.Commands));
  finally
    LConsole.Free;
  end;
end;

procedure TTestCmdStandard.DovrebbeSostituireUnaVariabileNellaRiga;
begin
  FConsole.CVars.SetCVarString('who', 'world');
  FConsole.Buffer.BufferCommandText(ceNow, 'echo hello $who $nobody');
  Assert.AreEqual('hello world  '#10, FLog.Text, 'an unknown variable is empty ("<unknown>" only without the cvar system)');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCmdStandard);

end.
