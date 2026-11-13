{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idTech 4 cvars (variable, system, commands)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.CVar;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.Variable,
  DelphiDoom.Console.CVar.Intf, DelphiDoom.Console.CVar.System, DelphiDoom.Console.IdTech4.Factory,
  DelphiDoom.Tests.Console.IdTech4.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestCVar = class(TObject)
  private
    FLog: TFakeIdLog;
    FLogIntf: IIdLibLog;
    FSession: TFakeSession;
    FSessionIntf: IConsoleSession;
    FCVars: ICVarSystem;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNormalizzareUnBooleano;
    [Test]
    procedure DovrebbeTroncareUnIntero;
    [Test]
    procedure DovrebbeLimitareUnInteroAlIntervallo;
    [Test]
    procedure DovrebbeLimitareUnRealeAlIntervallo;
    [Test]
    procedure DovrebbeIgnorareUnIntervalloCapovolto;
    [Test]
    procedure DovrebbeScegliereTraLeStringheAmmesse;
    [Test]
    procedure DovrebbeLeggereUnaStringaLungaComeZero;
    [Test]
    procedure DovrebbeRifiutareLaScritturaDiUnaVariabileDiSolaLettura;
    [Test]
    procedure DovrebbeRifiutareLaScritturaDiUnaVariabileInit;
    [Test]
    procedure DovrebbeForzareLaScritturaDiUnaVariabileDiSolaLettura;
    [Test]
    procedure DovrebbeNonModificareSeIlValoreESoloDiMaiuscole;
    [Test]
    procedure DovrebbeAccendereIlModificatoELeFlagDelSistema;
    [Test]
    procedure DovrebbeTornareAlValoreDiReset;
    [Test]
    procedure DovrebbeTrattareUnaVariabileCometruccoDiDefault;
    [Test]
    procedure DovrebbeTogliereLaFlagCheatSeLaVariabileEArchiviata;
    [Test]
    procedure DovrebbeRifiutareUnaVariabileCheatInMultiplayer;
    [Test]
    procedure DovrebbeRifiutareUnaVariabileSincronizzataSuUnClient;
    [Test]
    procedure DovrebbeAccettareUnValoreDalServer;
    [Test]
    procedure DovrebbeUnireDueDichiarazioniDellaStessaVariabile;
    [Test]
    procedure DovrebbeAvvisareDiDichiarazioniDiverse;
    [Test]
    procedure DovrebbeAvvisareDiDueValoriIniziali;
    [Test]
    procedure DovrebbeTrovareUnaVariabileSenzaMaiuscole;
    [Test]
    procedure DovrebbeCrearePerNomeEAggiungereLeFlag;
    [Test]
    procedure DovrebbeLeggereIValoriPerNome;
    [Test]
    procedure DovrebbeSvuotareConShutdown;
    [Test]
    procedure DovrebbeRipartireConRestart;
    [Test]
    procedure DovrebbeDareUnCompletamentoBooleanoAlleVariabiliBooleane;
    [Test]
    procedure DovrebbeScrivereLeVariabiliConUnaFlag;
    [Test]
    procedure DovrebbeCopiareLeVariabiliInUnDizionario;
    [Test]
    procedure DovrebbeSpezzareUnaDescrizioneInUnaColonna;
    [Test]
    procedure DovrebbeLasciareUnaDescrizioneCortaIntera;
    [Test]
    procedure DovrebbeSpezzareSuUnACapoDellaDescrizione;
    [Test]
    procedure DovrebbeUsareLeFlagDelleVariabiliNellElenco;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CVar.Lister, DelphiDoom.Scanner.IdDict;

procedure TTestCVar.Setup;
begin
  FLog := TFakeIdLog.Create;
  FLogIntf := FLog;
  FSession := TFakeSession.Create;
  FSessionIntf := FSession;
  FCVars := TCVarSystem.Create(FLogIntf, FSessionIntf);
  FCVars.Init;
end;

procedure TTestCVar.TearDown;
begin
  FCVars := nil;
  FSessionIntf := nil;
  FLogIntf := nil;
end;

procedure TTestCVar.DovrebbeNormalizzareUnBooleano;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('b', '1', CVAR_BOOL, ''));
  LVariable.SetString('7');
  Assert.AreEqual('1', string(LVariable.GetString));
  Assert.IsTrue(LVariable.GetBool);
  Assert.AreEqual(1.0, LVariable.GetFloat, 0.0);
  LVariable.SetString('zero');
  Assert.AreEqual('0', string(LVariable.GetString));
  Assert.IsFalse(LVariable.GetBool);
end;

procedure TTestCVar.DovrebbeTroncareUnIntero;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('i', '5', CVAR_INTEGER, ''));
  LVariable.SetString('-3.7');
  Assert.AreEqual(-3, LVariable.GetInteger);
  Assert.AreEqual('-3', string(LVariable.GetString));
  LVariable.SetString('007');
  Assert.AreEqual('7', string(LVariable.GetString), 'the text of an integer is rewritten (defect of the original kept)');
  LVariable.SetString('.5');
  Assert.AreEqual('.5', string(LVariable.GetString), 'a dot at the start is the one case that keeps the text');
  Assert.AreEqual(0, LVariable.GetInteger);
end;

procedure TTestCVar.DovrebbeLimitareUnInteroAlIntervallo;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('i', '5', CVAR_INTEGER, '', 0, 10));
  LVariable.SetString('11');
  Assert.AreEqual(10, LVariable.GetInteger);
  LVariable.SetString('-4');
  Assert.AreEqual(0, LVariable.GetInteger);
  Assert.AreEqual('0', string(LVariable.GetString));
end;

procedure TTestCVar.DovrebbeLimitareUnRealeAlIntervallo;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('f', '0.5', CVAR_FLOAT, '', -1, 1));
  LVariable.SetString('1.5');
  Assert.AreEqual(1.0, LVariable.GetFloat, 0.0);
  Assert.AreEqual('1', string(LVariable.GetString));
  LVariable.SetFloat(-9);
  Assert.AreEqual(-1.0, LVariable.GetFloat, 0.0);
  LVariable.SetString('0.25');
  Assert.AreEqual(0.25, LVariable.GetFloat, 0.0);
  Assert.AreEqual(0, LVariable.GetInteger);
end;

procedure TTestCVar.DovrebbeIgnorareUnIntervalloCapovolto;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('i', '5', CVAR_INTEGER, '', 10, -10));
  LVariable.SetString('500');
  Assert.AreEqual(500, LVariable.GetInteger);
end;

procedure TTestCVar.DovrebbeScegliereTraLeStringheAmmesse;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('e', 'beta', 0, '', ['alpha', 'beta', 'gamma']));
  Assert.AreEqual(1, LVariable.GetInteger);
  LVariable.SetString('GAMMA');
  Assert.AreEqual('gamma', string(LVariable.GetString));
  Assert.AreEqual(2, LVariable.GetInteger);
  LVariable.SetString('delta');
  Assert.AreEqual('alpha', string(LVariable.GetString), 'an unknown string is the first one');
end;

procedure TTestCVar.DovrebbeLeggereUnaStringaLungaComeZero;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('s', '5', 0, ''));
  Assert.AreEqual(5, LVariable.GetInteger);
  LVariable.SetString(AnsiString(StringOfChar('7', 40)));
  Assert.AreEqual(0, LVariable.GetInteger);
  Assert.AreEqual(0.0, LVariable.GetFloat, 0.0);
end;

procedure TTestCVar.DovrebbeRifiutareLaScritturaDiUnaVariabileDiSolaLettura;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('r', 'a', CVAR_ROM, ''));
  LVariable.SetValue('b', False, False);
  Assert.AreEqual('a', string(LVariable.GetString));
  Assert.AreEqual('r is read only.'#10, FLog.Text);
end;

procedure TTestCVar.DovrebbeRifiutareLaScritturaDiUnaVariabileInit;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('r', 'a', CVAR_INIT, ''));
  LVariable.SetValue('b', False, False);
  Assert.AreEqual('a', string(LVariable.GetString));
  Assert.AreEqual('r is write protected.'#10, FLog.Text);
end;

procedure TTestCVar.DovrebbeForzareLaScritturaDiUnaVariabileDiSolaLettura;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('r', 'a', CVAR_ROM, ''));
  LVariable.SetString('b');
  Assert.AreEqual('b', string(LVariable.GetString));
  Assert.AreEqual('', FLog.Text);
end;

procedure TTestCVar.DovrebbeNonModificareSeIlValoreESoloDiMaiuscole;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('s', 'abc', 0, ''));
  LVariable.ClearModified;
  LVariable.SetString('ABC');
  Assert.AreEqual('abc', string(LVariable.GetString));
  Assert.IsFalse(LVariable.IsModified);
end;

procedure TTestCVar.DovrebbeAccendereIlModificatoELeFlagDelSistema;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('s', 'abc', CVAR_GAME, ''));
  FCVars.ClearModifiedFlags(CVAR_ALL);
  LVariable.ClearModified;
  Assert.AreEqual(0, FCVars.GetModifiedFlags);
  LVariable.SetString('x');
  Assert.IsTrue(LVariable.IsModified);
  Assert.IsTrue((FCVars.GetModifiedFlags and CVAR_GAME) <> 0);
  FCVars.ClearModifiedFlags(CVAR_GAME);
  Assert.AreEqual(0, FCVars.GetModifiedFlags and CVAR_GAME);
  FCVars.SetModifiedFlags(CVAR_SOUND);
  Assert.AreEqual(CVAR_SOUND, FCVars.GetModifiedFlags and CVAR_SOUND);
end;

procedure TTestCVar.DovrebbeTornareAlValoreDiReset;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('s', 'abc', CVAR_ROM, ''));
  LVariable.SetString('x');
  LVariable.Reset;
  Assert.AreEqual('abc', string(LVariable.GetString));
  LVariable.SetString('y');
  LVariable.SetToResetValue(False, False);
  Assert.AreEqual('y', string(LVariable.GetString), 'not forced: the variable is read only');
  LVariable.SetToResetValue(True, False);
  Assert.AreEqual('abc', string(LVariable.GetString));
end;

procedure TTestCVar.DovrebbeTrattareUnaVariabileCometruccoDiDefault;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('c', '1', 0, ''));
  Assert.IsTrue((LVariable.Flags and CVAR_CHEAT) <> 0, 'cheat unless it is one of the safe kinds');
  Assert.IsTrue((LVariable.Flags and CVAR_STATIC) <> 0);
  Assert.IsTrue(LVariable.IsModified);
end;

procedure TTestCVar.DovrebbeTogliereLaFlagCheatSeLaVariabileEArchiviata;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('c', '1', 0, ''));
  LVariable.AddFlags(CVAR_ARCHIVE);
  LVariable.UpdateCheat;
  Assert.IsTrue((LVariable.Flags and CVAR_CHEAT) = 0);
end;

procedure TTestCVar.DovrebbeRifiutareUnaVariabileCheatInMultiplayer;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('c', '1', 0, ''));
  FSession.Multiplayer := True;
  LVariable.SetValue('2', False, False);
  Assert.AreEqual('1', string(LVariable.GetString));
  Assert.AreEqual('c cannot be changed in multiplayer.'#10, FLog.Text);
  FCVars.SetCVarBool('net_allowCheats', True);
  LVariable.SetValue('2', False, False);
  Assert.AreEqual('2', string(LVariable.GetString));
end;

procedure TTestCVar.DovrebbeRifiutareUnaVariabileSincronizzataSuUnClient;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('n', '1', CVAR_NETWORKSYNC, ''));
  FSession.Multiplayer := True;
  FSession.ClientActive := True;
  LVariable.SetValue('2', False, False);
  Assert.AreEqual('1', string(LVariable.GetString));
  Assert.AreEqual('n is a synced over the network and cannot be changed on a multiplayer client.'#10, FLog.Text);
end;

procedure TTestCVar.DovrebbeAccettareUnValoreDalServer;
var
  LVariable: TCVar;
begin
  LVariable := FCVars.Register(TCVarDefinition.Create('n', '1', CVAR_NETWORKSYNC, ''));
  FSession.Multiplayer := True;
  FSession.ClientActive := True;
  LVariable.ServerSetString('9');
  Assert.AreEqual('9', string(LVariable.GetString));
end;

procedure TTestCVar.DovrebbeUnireDueDichiarazioniDellaStessaVariabile;
var
  LFirst, LSecond: TCVar;
begin
  LFirst := FCVars.Register(TCVarDefinition.Create('v', '1', CVAR_INTEGER, 'one'));
  LSecond := FCVars.Register(TCVarDefinition.Create('v', '1', CVAR_INTEGER or CVAR_ARCHIVE, 'two'));
  Assert.IsTrue(LFirst = LSecond, 'the same variable');
  Assert.AreEqual(1, FCVars.Count);
  Assert.AreEqual('two', string(LFirst.Description));
  Assert.IsTrue((LFirst.Flags and CVAR_ARCHIVE) <> 0);
  Assert.AreEqual(0, FLog.Entries.Count);
end;

procedure TTestCVar.DovrebbeAvvisareDiDichiarazioniDiverse;
begin
  FCVars.Register(TCVarDefinition.Create('v', '1', CVAR_INTEGER, '', 0, 5));
  FCVars.Register(TCVarDefinition.Create('v', '2', CVAR_FLOAT, '', 0, 9));
  Assert.AreEqual(3, FLog.Entries.Count);
  Assert.AreEqual('W: CVar ''v'' declared multiple times with different initial value', FLog.Entries[0]);
  Assert.AreEqual('W: CVar ''v'' declared multiple times with different type', FLog.Entries[1]);
  Assert.AreEqual('W: CVar ''v'' declared multiple times with different minimum/maximum', FLog.Entries[2]);
end;

procedure TTestCVar.DovrebbeAvvisareDiDueValoriIniziali;
var
  LVariable: TCVar;
begin
  // a variable made by the user has the value as its reset value; a declaration then replaces it
  // without a warning, and a second declaration with another value warns
  FCVars.SetCVarString('u', 'first');
  LVariable := FCVars.Register(TCVarDefinition.Create('u', 'second', 0, ''));
  Assert.AreEqual('first', string(LVariable.GetString));
  Assert.AreEqual('second', string(LVariable.ResetString));
  Assert.AreEqual(0, FLog.Entries.Count);
  FCVars.Register(TCVarDefinition.Create('u', 'third', 0, ''));
  Assert.IsTrue(FLog.Entries.Count > 0);
end;

procedure TTestCVar.DovrebbeTrovareUnaVariabileSenzaMaiuscole;
begin
  FCVars.Register(TCVarDefinition.Create('MixedName', '1', 0, ''));
  Assert.IsNotNull(FCVars.Find('mixedname'));
  Assert.IsNotNull(FCVars.Find('MIXEDNAME'));
  Assert.IsNull(FCVars.Find('other'));
end;

procedure TTestCVar.DovrebbeCrearePerNomeEAggiungereLeFlag;
begin
  FCVars.SetCVarString('made', 'x', CVAR_ARCHIVE);
  Assert.IsTrue((FCVars.Find('made').Flags and CVAR_ARCHIVE) <> 0);
  Assert.IsTrue((FCVars.Find('made').Flags and CVAR_STATIC) = 0);
  FCVars.SetCVarInteger('made', 12, CVAR_GAME);
  Assert.AreEqual('12', string(FCVars.Find('made').GetString));
  Assert.IsTrue((FCVars.Find('made').Flags and CVAR_GAME) <> 0);
  FCVars.SetCVarFloat('made', 0.5);
  Assert.AreEqual('0.5', string(FCVars.Find('made').GetString));
  FCVars.SetCVarBool('made', True);
  Assert.AreEqual('1', string(FCVars.Find('made').GetString));
  FCVars.SetCVarBool('made', False);
  Assert.AreEqual('0', string(FCVars.Find('made').GetString));
end;

procedure TTestCVar.DovrebbeLeggereIValoriPerNome;
var
  LReader: ICVarReader;
begin
  LReader := FCVars as ICVarReader;
  FCVars.Register(TCVarDefinition.Create('f', '2.5', CVAR_FLOAT, ''));
  Assert.AreEqual('2.5', string(LReader.GetCVarString('F')));
  Assert.AreEqual(2, LReader.GetCVarInteger('f'));
  Assert.AreEqual(2.5, LReader.GetCVarFloat('f'), 0.0);
  Assert.IsTrue(LReader.GetCVarBool('f'));
  Assert.AreEqual('', string(LReader.GetCVarString('none')));
  Assert.AreEqual(0, LReader.GetCVarInteger('none'));
  Assert.AreEqual(0.0, LReader.GetCVarFloat('none'), 0.0);
  Assert.IsFalse(LReader.GetCVarBool('none'));
end;

procedure TTestCVar.DovrebbeSvuotareConShutdown;
begin
  Assert.IsTrue(FCVars.IsInitialized);
  FCVars.Register(TCVarDefinition.Create('a', '1', 0, ''));
  FCVars.Shutdown;
  Assert.IsFalse(FCVars.IsInitialized);
  Assert.AreEqual(0, FCVars.Count);
  Assert.IsNull(FCVars.Find('a'));
end;

procedure TTestCVar.DovrebbeRipartireConRestart;
begin
  FCVars.Register(TCVarDefinition.Create('keep', 'k', 0, ''));
  FCVars.Register(TCVarDefinition.Create('rom', 'r', CVAR_ROM, ''));
  FCVars.Register(TCVarDefinition.Create('init', 'i', CVAR_INIT, ''));
  FCVars.Find('keep').SetString('changed');
  FCVars.Find('rom').SetString('changed');
  FCVars.SetCVarString('user', 'u');
  FCVars.Restart;
  Assert.AreEqual('k', string(FCVars.Find('keep').GetString));
  Assert.AreEqual('changed', string(FCVars.Find('rom').GetString), 'read only values are not touched');
  Assert.IsNull(FCVars.Find('user'), 'a variable the user made is removed');
  Assert.AreEqual(3, FCVars.Count);
end;

procedure TTestCVar.DovrebbeDareUnCompletamentoBooleanoAlleVariabiliBooleane;
var
  LTexts: string;
begin
  FCVars.Register(TCVarDefinition.Create('flag', '0', CVAR_BOOL, ''));
  FCVars.ArgCompletion('flag',
    procedure(const AText: AnsiString)
    begin
      LTexts := LTexts + string(AText) + '|';
    end);
  Assert.AreEqual('flag 0|flag 1|', LTexts);
  FCVars.RemoveFlaggedAutoCompletion(CVAR_BOOL);
  LTexts := '';
  FCVars.ArgCompletion('flag',
    procedure(const AText: AnsiString)
    begin
      LTexts := LTexts + string(AText);
    end);
  Assert.AreEqual('', LTexts);
end;

procedure TTestCVar.DovrebbeScrivereLeVariabiliConUnaFlag;
begin
  FCVars.Register(TCVarDefinition.Create('a', '1', CVAR_ARCHIVE, ''));
  FCVars.Register(TCVarDefinition.Create('b', '2', 0, ''));
  FCVars.Register(TCVarDefinition.Create('c', 'x y', CVAR_ARCHIVE, ''));
  Assert.AreEqual('seta a "1"'#10'seta c "x y"'#10, string(FCVars.WriteFlaggedVariables(CVAR_ARCHIVE, 'seta')));
  Assert.AreEqual('', string(FCVars.WriteFlaggedVariables(CVAR_TOOL, 'seta')));
end;

procedure TTestCVar.DovrebbeCopiareLeVariabiliInUnDizionario;
var
  LDict, LOther: TIdDict;
begin
  FCVars.Register(TCVarDefinition.Create('a', '1', CVAR_ARCHIVE, ''));
  FCVars.Register(TCVarDefinition.Create('b', '2', 0, ''));
  LDict := FCVars.MoveCVarsToDict(CVAR_ARCHIVE);
  Assert.AreEqual(1, LDict.GetNumKeyVals);
  Assert.AreEqual('1', string(LDict.GetString('a')));
  LOther := FCVars.MoveCVarsToDict(CVAR_ALL);
  Assert.AreEqual(2, LOther.GetNumKeyVals, 'the dictionary is the same, emptied');
  LOther := TIdDict.Create;
  try
    LOther.SetValue('A', '9');
    LOther.SetValue('missing', '1');
    FCVars.SetCVarsFromDict(LOther);
  finally
    LOther.Free;
  end;
  Assert.AreEqual('9', string(FCVars.Find('a').GetString));
  Assert.IsNull(FCVars.Find('missing'));
end;

procedure TTestCVar.DovrebbeSpezzareUnaDescrizioneInUnaColonna;
begin
  Assert.AreEqual('one two'#10'  three four',
    string(TCVarLister.CreateColumn('one two three four', 10, #10'  ')));
end;

procedure TTestCVar.DovrebbeLasciareUnaDescrizioneCortaIntera;
begin
  Assert.AreEqual('short text', string(TCVarLister.CreateColumn('short text', 44, #10'  ')));
  Assert.AreEqual('', string(TCVarLister.CreateColumn('', 44, #10'  ')));
end;

procedure TTestCVar.DovrebbeSpezzareSuUnACapoDellaDescrizione;
begin
  Assert.AreEqual('first'#10'   second', string(TCVarLister.CreateColumn('first'#10'second', 44, #10'   ')));
end;

procedure TTestCVar.DovrebbeUsareLeFlagDelleVariabiliNellElenco;
var
  LConsole: TIdTech4Console;
  LArgs: TIdCmdArgs;
begin
  LConsole := TIdTech4Console.Create(FLogIntf);
  try
    LConsole.Init;
    LConsole.CVars.Register(TCVarDefinition.Create('shown', '1', CVAR_GAME, ''));
    LConsole.CVars.Register(TCVarDefinition.Create('other', '2', CVAR_SOUND, ''));
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString('listCvars sh*', False);
      with TCVarLister.Create(LConsole.CVars, FLogIntf) do
      try
        ListByFlags(LArgs, CVAR_GAME);
      finally
        Free;
      end;
    finally
      LArgs.Free;
    end;
    Assert.IsTrue(FLog.Text.Contains('shown'));
    Assert.IsFalse(FLog.Text.Contains('other'));
    Assert.IsTrue(FLog.Text.Contains('1 cvars listed'));
  finally
    LConsole.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCVar);

end.
