{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idTech 4 command system (list, buffer, execution)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CmdSystem;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.CmdSystem.System,
  DelphiDoom.Tests.Console.IdTech4.Fakes;

type
  /// <summary>Commands for the tests: they write "name:argument,argument" in a list</summary>
  TCmdProbe = class
  public
    Calls: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure First(const AArgs: TIdCmdArgs);
    procedure Second(const AArgs: TIdCmdArgs);
    procedure CompleteTwo(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
  end;

  [TestFixture]
  [Category('console')]
  TTestCmdSystem = class(TObject)
  private
    FLog: TFakeIdLog;
    FLogIntf: IIdLibLog;
    FSession: TFakeSession;
    FSessionIntf: IConsoleSession;
    FSystem: TCmdSystem;
    FCommands: ICmdCommands;
    FBuffer: ICmdBuffer;
    FProbe: TCmdProbe;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEseguireUnComandoSubito;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNelNomeDelComando;
    [Test]
    procedure DovrebbeDireComandoSconosciuto;
    [Test]
    procedure DovrebbeIgnorareUnaRigaSenzaParole;
    [Test]
    procedure DovrebbeAvvisareDiUnNomeGiaDefinitoConUnaFunzioneDiversa;
    [Test]
    procedure DovrebbeTacereSeLaFunzioneEGiaQuellaDelNome;
    [Test]
    procedure DovrebbeTenereLaPrimaFunzioneDiUnNomeDoppio;
    [Test]
    procedure DovrebbeConfrontareIlNomeInRegistrazioneConLeMaiuscole;
    [Test]
    procedure DovrebbePortareInTestaIlComandoUsato;
    [Test]
    procedure DovrebbeRimuovereUnComando;
    [Test]
    procedure DovrebbeRimuovereIComandiConUnaFlag;
    [Test]
    procedure DovrebbeDareITuttiINomiAlCompletamento;
    [Test]
    procedure DovrebbeCompletareGliArgomentiDelPrimoComandoCheNeHa;
    [Test]
    procedure DovrebbeNonCompletareUnComandoSenzaCompletamento;
    [Test]
    procedure DovrebbeEseguireLeRigheDelBufferInOrdine;
    [Test]
    procedure DovrebbeSpezzareSuPuntoEVirgolaEACapo;
    [Test]
    procedure DovrebbeNonSpezzareSuPuntoEVirgolaTraVirgolette;
    [Test]
    procedure DovrebbeSpezzareSuACapoAncheTraVirgolette;
    [Test]
    procedure DovrebbeInserireInTestaConUnACapo;
    [Test]
    procedure DovrebbeFermareIlBufferConWait;
    [Test]
    procedure DovrebbeSegnalareIlSovraccaricoDelBuffer;
    [Test]
    procedure DovrebbeSegnalareIlSovraccaricoDellInserimento;
    [Test]
    procedure DovrebbeTroncareIlTestoAlPrimoNul;
    [Test]
    procedure DovrebbeConservareGliArgomentiTokenizzati;
    [Test]
    procedure DovrebbeEseguireSubitoGliArgomenti;
    [Test]
    procedure DovrebbeRifiutareGliArgomentiInInserimento;
    [Test]
    procedure DovrebbeRicordareIlComandoDopoIlRicaricamento;
    [Test]
    procedure DovrebbeDareFalsoSenzaComandoDopoIlRicaricamento;
    [Test]
    procedure DovrebbeRifiutareUnComandoCheatInMultiplayer;
    [Test]
    procedure DovrebbeLasciareUnComandoNormaleInMultiplayer;
    [Test]
    procedure DovrebbeSvuotareTuttoConShutdown;
    [Test]
    procedure DovrebbeUsareLoStesso_net_allowCheatsPerIComandiCheat;
  end;

implementation

uses
  DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.System, DelphiDoom.Console.CVar.Intf;

{ TCmdProbe }

constructor TCmdProbe.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
end;

destructor TCmdProbe.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

procedure TCmdProbe.First(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
  LText: string;
begin
  LText := 'first';
  for LIndex := 1 to AArgs.Argc - 1 do
    LText := LText + ':' + string(AArgs.Argv(LIndex));
  Calls.Add(LText);
end;

procedure TCmdProbe.Second(const AArgs: TIdCmdArgs);
begin
  Calls.Add('second');
end;

procedure TCmdProbe.CompleteTwo(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
begin
  ACallback(AArgs.Argv(0) + ' one');
  ACallback(AArgs.Argv(0) + ' two');
end;

{ TTestCmdSystem }

procedure TTestCmdSystem.Setup;
begin
  FLog := TFakeIdLog.Create;
  FLogIntf := FLog;
  FSession := TFakeSession.Create;
  FSessionIntf := FSession;
  FSystem := TCmdSystem.Create(FLogIntf, FSessionIntf);
  FCommands := FSystem;
  FBuffer := FSystem;
  FProbe := TCmdProbe.Create;
end;

procedure TTestCmdSystem.TearDown;
begin
  FBuffer := nil;
  FCommands := nil;
  FSystem := nil;
  FProbe.Free;
  FSessionIntf := nil;
  FLogIntf := nil;
end;

procedure TTestCmdSystem.DovrebbeEseguireUnComandoSubito;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, 'd');
  FBuffer.BufferCommandText(ceNow, 'probe a "b c"');
  Assert.AreEqual('first:a:b c', FProbe.Calls[0]);
end;

procedure TTestCmdSystem.DovrebbeIgnorareLeMaiuscoleNelNomeDelComando;
begin
  FCommands.AddCommand('Probe', FProbe.First, 0, 'd');
  FBuffer.BufferCommandText(ceNow, 'PROBE');
  Assert.AreEqual(1, FProbe.Calls.Count);
end;

procedure TTestCmdSystem.DovrebbeDireComandoSconosciuto;
begin
  FBuffer.BufferCommandText(ceNow, 'nothing here');
  Assert.AreEqual('Unknown command ''nothing''' + #10, FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeIgnorareUnaRigaSenzaParole;
begin
  FBuffer.BufferCommandText(ceNow, '   ');
  Assert.AreEqual('', FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeAvvisareDiUnNomeGiaDefinitoConUnaFunzioneDiversa;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, 'd');
  FCommands.AddCommand('probe', FProbe.Second, 0, 'd');
  Assert.AreEqual('idCmdSystemLocal::AddCommand: probe already defined' + #10, FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeTacereSeLaFunzioneEGiaQuellaDelNome;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, 'd');
  FCommands.AddCommand('probe', FProbe.First, CMD_FL_GAME, 'other');
  Assert.AreEqual('', FLog.Text);
  Assert.AreEqual('d', string(FCommands.Commands[0].Description));
end;

procedure TTestCmdSystem.DovrebbeTenereLaPrimaFunzioneDiUnNomeDoppio;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, 'd');
  FCommands.AddCommand('probe', FProbe.Second, 0, 'd');
  FBuffer.BufferCommandText(ceNow, 'probe');
  Assert.AreEqual('first', FProbe.Calls[0]);
end;

procedure TTestCmdSystem.DovrebbeConfrontareIlNomeInRegistrazioneConLeMaiuscole;
begin
  // "Probe" and "probe" are two commands (AddCommand compares with Cmp), the execution finds the first
  FCommands.AddCommand('probe', FProbe.First, 0, 'd');
  FCommands.AddCommand('Probe', FProbe.Second, 0, 'd');
  Assert.AreEqual<Integer>(2, Length(FCommands.Commands));
  FBuffer.BufferCommandText(ceNow, 'probe');
  Assert.AreEqual('second', FProbe.Calls[0], 'the last added is the first of the list');
end;

procedure TTestCmdSystem.DovrebbePortareInTestaIlComandoUsato;
begin
  FCommands.AddCommand('a', FProbe.First, 0, '');
  FCommands.AddCommand('b', FProbe.First, 0, '');
  FCommands.AddCommand('c', FProbe.First, 0, '');
  Assert.AreEqual('c', string(FCommands.Commands[0].Name));
  FBuffer.BufferCommandText(ceNow, 'a');
  Assert.AreEqual('a', string(FCommands.Commands[0].Name));
  Assert.AreEqual('c', string(FCommands.Commands[1].Name));
  Assert.AreEqual('b', string(FCommands.Commands[2].Name));
end;

procedure TTestCmdSystem.DovrebbeRimuovereUnComando;
begin
  FCommands.AddCommand('a', FProbe.First, 0, '');
  FCommands.AddCommand('b', FProbe.First, 0, '');
  FCommands.RemoveCommand('a');
  FCommands.RemoveCommand('missing');
  Assert.AreEqual<Integer>(1, Length(FCommands.Commands));
  Assert.AreEqual('b', string(FCommands.Commands[0].Name));
end;

procedure TTestCmdSystem.DovrebbeRimuovereIComandiConUnaFlag;
begin
  FCommands.AddCommand('a', FProbe.First, CMD_FL_GAME, '');
  FCommands.AddCommand('b', FProbe.First, CMD_FL_SOUND, '');
  FCommands.AddCommand('c', FProbe.First, CMD_FL_GAME or CMD_FL_TOOL, '');
  FCommands.RemoveFlaggedCommands(CMD_FL_GAME);
  Assert.AreEqual<Integer>(1, Length(FCommands.Commands));
  Assert.AreEqual('b', string(FCommands.Commands[0].Name));
end;

procedure TTestCmdSystem.DovrebbeDareITuttiINomiAlCompletamento;
var
  LNames: string;
begin
  FCommands.AddCommand('a', FProbe.First, 0, '');
  FCommands.AddCommand('b', FProbe.First, 0, '');
  LNames := '';
  FCommands.CommandCompletion(
    procedure(const AText: AnsiString)
    begin
      LNames := LNames + string(AText) + ' ';
    end);
  Assert.AreEqual('b a ', LNames);
end;

procedure TTestCmdSystem.DovrebbeCompletareGliArgomentiDelPrimoComandoCheNeHa;
var
  LTexts: string;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FCommands.AddCommand('probe2', FProbe.First, 0, '', FProbe.CompleteTwo);
  FCommands.ArgCompletion('PROBE2 x',
    procedure(const AText: AnsiString)
    begin
      LTexts := LTexts + string(AText) + '|';
    end);
  Assert.AreEqual('PROBE2 one|PROBE2 two|', LTexts);
end;

procedure TTestCmdSystem.DovrebbeNonCompletareUnComandoSenzaCompletamento;
var
  LCalls: Integer;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  LCalls := 0;
  FCommands.ArgCompletion('probe x',
    procedure(const AText: AnsiString)
    begin
      Inc(LCalls);
    end);
  Assert.AreEqual(0, LCalls);
end;

procedure TTestCmdSystem.DovrebbeEseguireLeRigheDelBufferInOrdine;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe 1'#10'probe 2'#10);
  FBuffer.BufferCommandText(ceAppend, 'probe 3');
  Assert.AreEqual(0, FProbe.Calls.Count, 'nothing runs before ExecuteCommandBuffer');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(3, FProbe.Calls.Count);
  Assert.AreEqual('first:3', FProbe.Calls[2]);
end;

procedure TTestCmdSystem.DovrebbeSpezzareSuPuntoEVirgolaEACapo;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe 1;probe 2'#13'probe 3'#10'probe 4');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(4, FProbe.Calls.Count);
end;

procedure TTestCmdSystem.DovrebbeNonSpezzareSuPuntoEVirgolaTraVirgolette;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe "a;b" c;probe d');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(2, FProbe.Calls.Count);
  Assert.AreEqual('first:a;b:c', FProbe.Calls[0]);
  Assert.AreEqual('first:d', FProbe.Calls[1]);
end;

procedure TTestCmdSystem.DovrebbeSpezzareSuACapoAncheTraVirgolette;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe "a'#10'b"');
  FBuffer.ExecuteCommandBuffer;
  // two lines: probe "a (the lexer has no end of string) and b" (an unknown command)
  Assert.AreEqual(1, FProbe.Calls.Count);
  Assert.IsTrue(FLog.Text.StartsWith('Unknown command'), FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeInserireInTestaConUnACapo;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe tail');
  FBuffer.BufferCommandText(ceInsert, 'probe head');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual('first:head', FProbe.Calls[0]);
  Assert.AreEqual('first:tail', FProbe.Calls[1]);
end;

procedure TTestCmdSystem.DovrebbeFermareIlBufferConWait;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe 1'#10'probe 2');
  FBuffer.SetWait(1);
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(0, FProbe.Calls.Count, 'the frame is skipped');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(2, FProbe.Calls.Count, 'the next frame runs all');
end;

procedure TTestCmdSystem.DovrebbeSegnalareIlSovraccaricoDelBuffer;
begin
  FBuffer.BufferCommandText(ceAppend, AnsiString(StringOfChar('x', CMD_MAX_BUFFER - 1)));
  Assert.AreEqual('', FLog.Text);
  FBuffer.BufferCommandText(ceAppend, 'y');
  Assert.AreEqual('idCmdSystemLocal::AppendText: buffer overflow'#10, FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeSegnalareIlSovraccaricoDellInserimento;
begin
  FBuffer.BufferCommandText(ceAppend, AnsiString(StringOfChar('x', CMD_MAX_BUFFER - 1)));
  FBuffer.BufferCommandText(ceInsert, 'y');
  Assert.AreEqual('idCmdSystemLocal::InsertText: buffer overflow'#10, FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeTroncareIlTestoAlPrimoNul;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe a'#0'probe b');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(1, FProbe.Calls.Count);
  Assert.AreEqual('first:a', FProbe.Calls[0]);
end;

procedure TTestCmdSystem.DovrebbeConservareGliArgomentiTokenizzati;
var
  LArgs: TIdCmdArgs;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString('probe "x;y" z', False);
    FBuffer.BufferCommandArgs(ceAppend, LArgs);
    // the original keeps a copy: the arguments can change after
    LArgs.TokenizeString('probe changed', False);
  finally
    LArgs.Free;
  end;
  FBuffer.BufferCommandText(ceAppend, 'probe after');
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual('first:x;y:z', FProbe.Calls[0]);
  Assert.AreEqual('first:after', FProbe.Calls[1]);
end;

procedure TTestCmdSystem.DovrebbeEseguireSubitoGliArgomenti;
var
  LArgs: TIdCmdArgs;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString('probe now', False);
    FBuffer.BufferCommandArgs(ceNow, LArgs);
  finally
    LArgs.Free;
  end;
  Assert.AreEqual('first:now', FProbe.Calls[0]);
end;

procedure TTestCmdSystem.DovrebbeRifiutareGliArgomentiInInserimento;
var
  LArgs: TIdCmdArgs;
  LRaised: Boolean;
begin
  LArgs := TIdCmdArgs.Create;
  try
    LRaised := False;
    try
      FBuffer.BufferCommandArgs(ceInsert, LArgs);
    except
      on ECmdSystemException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LArgs.Free;
  end;
end;

procedure TTestCmdSystem.DovrebbeRicordareIlComandoDopoIlRicaricamento;
var
  LArgs: TIdCmdArgs;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FCommands.AddCommand('reloadEngine', FProbe.Second, 0, '');
  LArgs := TIdCmdArgs.Create;
  try
    LArgs.TokenizeString('probe after reload', False);
    FBuffer.SetupReloadEngine(LArgs);
  finally
    LArgs.Free;
  end;
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual('second', FProbe.Calls[0], 'reloadEngine runs first');
  Assert.IsTrue(FBuffer.PostReloadEngine);
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual('first:after:reload', FProbe.Calls[1]);
  Assert.IsFalse(FBuffer.PostReloadEngine, 'it is used once');
end;

procedure TTestCmdSystem.DovrebbeDareFalsoSenzaComandoDopoIlRicaricamento;
begin
  Assert.IsFalse(FBuffer.PostReloadEngine);
end;

procedure TTestCmdSystem.DovrebbeRifiutareUnComandoCheatInMultiplayer;
begin
  FCommands.AddCommand('cheater', FProbe.First, CMD_FL_CHEAT, '');
  FCommands.AddCommand('tooler', FProbe.First, CMD_FL_TOOL, '');
  FSession.Multiplayer := True;
  FBuffer.BufferCommandText(ceNow, 'cheater');
  FBuffer.BufferCommandText(ceNow, 'tooler');
  Assert.AreEqual(0, FProbe.Calls.Count);
  Assert.AreEqual('Command ''cheater'' not valid in multiplayer mode.'#10'Command ''tooler'' not valid in multiplayer mode.'#10,
    FLog.Text);
end;

procedure TTestCmdSystem.DovrebbeLasciareUnComandoNormaleInMultiplayer;
begin
  FCommands.AddCommand('plain', FProbe.First, CMD_FL_GAME, '');
  FSession.Multiplayer := True;
  FBuffer.BufferCommandText(ceNow, 'plain');
  Assert.AreEqual(1, FProbe.Calls.Count);
end;

procedure TTestCmdSystem.DovrebbeSvuotareTuttoConShutdown;
begin
  FCommands.AddCommand('probe', FProbe.First, 0, '');
  FBuffer.BufferCommandText(ceAppend, 'probe 1');
  FSystem.Shutdown;
  FBuffer.ExecuteCommandBuffer;
  Assert.AreEqual(0, FProbe.Calls.Count);
  Assert.AreEqual<Integer>(0, Length(FCommands.Commands));
end;

procedure TTestCmdSystem.DovrebbeUsareLoStesso_net_allowCheatsPerIComandiCheat;
var
  LCVars: ICVarSystem;
  LSystem: ICmdCommands;
  LBuffer: ICmdBuffer;
  LCmd: TCmdSystem;
begin
  LCVars := TCVarSystem.Create(FLogIntf, FSessionIntf);
  LCmd := TCmdSystem.Create(FLogIntf, FSessionIntf, LCVars as ICVarCommand, LCVars as ICVarReader);
  LSystem := LCmd;
  LBuffer := LCmd;
  LSystem.AddCommand('cheater', FProbe.First, CMD_FL_CHEAT, '');
  FSession.Multiplayer := True;
  LBuffer.BufferCommandText(ceNow, 'cheater');
  Assert.AreEqual(0, FProbe.Calls.Count);
  LCVars.SetCVarBool('net_allowCheats', True);
  LBuffer.BufferCommandText(ceNow, 'cheater');
  Assert.AreEqual(1, FProbe.Calls.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCmdSystem);

end.
