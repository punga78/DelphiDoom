{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the cvar system of the Quake III console               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.CVarSystem;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.CVar,
  DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.CVarSystem, DelphiDoom.Tests.Console.Q3.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestQ3CVarSystem = class(TObject)
  private
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FCVars: IQ3CVarSystem;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeCreareSvCheatsInSolaLettura;
    [Test]
    procedure DovrebbeTrovareUnaVariabileSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeSostituireUnNomeNonValidoConBadname;
    [Test]
    procedure DovrebbeTenereIlValoreSeLaVariabileEsisteEUnireIFlag;
    [Test]
    procedure DovrebbeFarDiventareValoreDiReimpostazioneQuelloDelCodice;
    [Test]
    procedure DovrebbeRifiutareUnaModificaNonForzataDiUnaVariabileInSolaLettura;
    [Test]
    procedure DovrebbeTenereInSospesoLaModificaDiUnaVariabileLatch;
    [Test]
    procedure DovrebbeProteggereLeVariabiliCheatSoloSeSvCheatsEZero;
    [Test]
    procedure DovrebbeProteggereLeCheatPrimaDiInit;
    [Test]
    procedure DovrebbeRiportareLeCheatAlValoreSicuro;
    [Test]
    procedure DovrebbeScrivereUnNumeroComeInteroOComeDecimale;
    [Test]
    procedure DovrebbeScrivereUnNumeroEnormeComeDecimale;
    [Test]
    procedure DovrebbeRiportareAlValoreDiReimpostazione;
    [Test]
    procedure DovrebbeGettareLeVariabiliCreateDallUtenteNelRestart;
    [Test]
    procedure DovrebbeSegnareVuotoLoSlotDiUnaVariabileTolta;
    [Test]
    procedure DovrebbeLeggereValoriStringaEInteri;
    [Test]
    procedure DovrebbeTroncareIlValoreNelBuffer;
    [Test]
    procedure DovrebbeScrivereLeVariabiliDaArchiviare;
    [Test]
    procedure DovrebbeTroncareUnaRigaTroppoLungaDaScrivere;
    [Test]
    procedure DovrebbeCostruireLeInfoString;
    [Test]
    procedure DovrebbeRifiutareLeInfoStringSenzaScrittore;
    [Test]
    procedure DovrebbeRegistrareEAggiornareUnaCopia;
    [Test]
    procedure DovrebbeRifiutareUnaManiglia;
    [Test]
    procedure DovrebbeRifiutareUnValoreTroppoLungoPerLaCopia;
    [Test]
    procedure DovrebbeRifiutareLaMillesimaventicinquesimaVariabile;
    [Test]
    procedure DovrebbeTenereIFlagModificati;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

implementation

procedure TTestQ3CVarSystem.Setup;
begin
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FCVars := TQ3CVarSystem.Create(FLogIntf, TFakeQ3InfoWriter.Create(FLogIntf));
  FCVars.Init;
end;

procedure TTestQ3CVarSystem.DovrebbeCreareSvCheatsInSolaLettura;
var
  LVar: TQ3CVar;
begin
  LVar := FCVars.Find('SV_CHEATS');
  Assert.IsNotNull(LVar);
  Assert.AreEqual(Q3_CVAR_ROM or Q3_CVAR_SYSTEMINFO, LVar.Flags);
  Assert.AreEqual(1, LVar.IntegerValue);
end;

procedure TTestQ3CVarSystem.DovrebbeTrovareUnaVariabileSenzaDistinguereLeMaiuscole;
begin
  FCVars.Get('Name', 'x', 0);
  Assert.IsNotNull(FCVars.Find('nAME'));
  Assert.IsNull(FCVars.Find('other'));
end;

procedure TTestQ3CVarSystem.DovrebbeSostituireUnNomeNonValidoConBadname;
var
  LVar: TQ3CVar;
begin
  LVar := FCVars.Get('bad;name', 'x', 0);
  Assert.AreEqual('BADNAME', string(LVar.Name));
  Assert.AreEqual('invalid cvar name string: bad;name'#10, FLog.TakePrinted);
  Assert.AreEqual('BADNAME', string(FCVars.Get('a"b', 'y', 0).Name));
  Assert.AreEqual('BADNAME', string(FCVars.Get('a\b', 'y', 0).Name));
end;

procedure TTestQ3CVarSystem.DovrebbeTenereIlValoreSeLaVariabileEsisteEUnireIFlag;
var
  LVar: TQ3CVar;
begin
  FCVars.Get('a', 'one', 0);
  LVar := FCVars.Get('a', 'two', Q3_CVAR_ARCHIVE);
  Assert.AreEqual('one', string(LVar.StringValue));
  Assert.AreEqual(Q3_CVAR_ARCHIVE, LVar.Flags);
  Assert.AreEqual('Warning: cvar "a" given initial values: "one" and "two"'#10, FLog.TakeDeveloper);
end;

procedure TTestQ3CVarSystem.DovrebbeFarDiventareValoreDiReimpostazioneQuelloDelCodice;
var
  LVar: TQ3CVar;
begin
  FCVars.Set2('u', 'typed', False);
  LVar := FCVars.Find('u');
  Assert.AreEqual(Q3_CVAR_USER_CREATED, LVar.Flags);
  FCVars.ModifiedFlags := 0;
  FCVars.Get('u', 'code', Q3_CVAR_ARCHIVE);
  Assert.AreEqual(Q3_CVAR_ARCHIVE, LVar.Flags);
  Assert.AreEqual('code', string(LVar.ResetString));
  Assert.AreEqual('typed', string(LVar.StringValue));
  Assert.AreEqual(Q3_CVAR_ARCHIVE, FCVars.ModifiedFlags);
end;

procedure TTestQ3CVarSystem.DovrebbeRifiutareUnaModificaNonForzataDiUnaVariabileInSolaLettura;
begin
  FCVars.Get('r', 'a', Q3_CVAR_ROM);
  FCVars.Set2('r', 'b', False);
  Assert.AreEqual('r is read only.'#10, FLog.TakePrinted);
  Assert.AreEqual('a', string(FCVars.VariableString('r')));
  FCVars.Get('i', 'a', Q3_CVAR_INIT);
  FCVars.Set2('i', 'b', False);
  Assert.AreEqual('i is write protected.'#10, FLog.TakePrinted);
  FCVars.SetValueText('r', 'forced');
  Assert.AreEqual('forced', string(FCVars.VariableString('r')));
end;

procedure TTestQ3CVarSystem.DovrebbeTenereInSospesoLaModificaDiUnaVariabileLatch;
var
  LVar: TQ3CVar;
begin
  LVar := FCVars.Get('l', 'a', Q3_CVAR_LATCH);
  FCVars.SetLatched('l', 'b');
  Assert.AreEqual('l will be changed upon restarting.'#10, FLog.TakePrinted);
  Assert.AreEqual('a', string(LVar.StringValue));
  Assert.IsTrue(LVar.HasLatched);
  FCVars.SetLatched('l', 'b');
  Assert.AreEqual('', FLog.TakePrinted);
  FCVars.Get('l', 'a', Q3_CVAR_LATCH);
  Assert.AreEqual('b', string(LVar.StringValue));
  Assert.IsFalse(LVar.HasLatched);
end;

procedure TTestQ3CVarSystem.DovrebbeProteggereLeVariabiliCheatSoloSeSvCheatsEZero;
begin
  FCVars.Get('c', 'a', Q3_CVAR_CHEAT);
  FCVars.Set2('c', 'b', False);
  Assert.AreEqual('b', string(FCVars.VariableString('c')));
  FCVars.SetValueText('sv_cheats', '0');
  FCVars.Set2('c', 'x', False);
  Assert.AreEqual('c is cheat protected.'#10, FLog.TakePrinted);
  Assert.AreEqual('b', string(FCVars.VariableString('c')));
end;

procedure TTestQ3CVarSystem.DovrebbeProteggereLeCheatPrimaDiInit;
var
  LCVars: IQ3CVarSystem;
begin
  LCVars := TQ3CVarSystem.Create;
  LCVars.Get('c', 'a', Q3_CVAR_CHEAT);
  LCVars.Set2('c', 'b', False);
  Assert.AreEqual('a', string(LCVars.VariableString('c')));
end;

procedure TTestQ3CVarSystem.DovrebbeRiportareLeCheatAlValoreSicuro;
begin
  FCVars.Get('c', 'safe', Q3_CVAR_CHEAT or Q3_CVAR_LATCH);
  FCVars.SetValueText('c', 'cheated');
  FCVars.SetLatched('c', 'latched');
  FCVars.SetCheatState;
  Assert.AreEqual('safe', string(FCVars.VariableString('c')));
  Assert.IsFalse(FCVars.Find('c').HasLatched);
end;

procedure TTestQ3CVarSystem.DovrebbeScrivereUnNumeroComeInteroOComeDecimale;
begin
  FCVars.SetNumber('n', 5);
  Assert.AreEqual('5', string(FCVars.VariableString('n')));
  FCVars.SetNumber('n', -3);
  Assert.AreEqual('-3', string(FCVars.VariableString('n')));
  FCVars.SetNumber('n', 2.5);
  Assert.AreEqual('2.500000', string(FCVars.VariableString('n')));
  Assert.AreEqual(2, FCVars.VariableIntegerValue('n'));
  Assert.AreEqual(Single(2.5), FCVars.VariableValue('n'));
end;

procedure TTestQ3CVarSystem.DovrebbeScrivereUnNumeroEnormeComeDecimale;
begin
  FCVars.SetNumber('n', 4294967296.0);
  Assert.AreEqual('4294967296.000000', string(FCVars.VariableString('n')));
end;

procedure TTestQ3CVarSystem.DovrebbeRiportareAlValoreDiReimpostazione;
begin
  FCVars.Get('a', 'one', 0);
  FCVars.SetValueText('a', 'two');
  FCVars.Reset('a');
  Assert.AreEqual('one', string(FCVars.VariableString('a')));
  FCVars.Reset('missing');
  Assert.IsNull(FCVars.Find('missing'));
end;

procedure TTestQ3CVarSystem.DovrebbeGettareLeVariabiliCreateDallUtenteNelRestart;
begin
  FCVars.Set2('user', 'x', False);
  FCVars.Get('code', 'a', 0);
  FCVars.SetValueText('code', 'b');
  FCVars.Get('keep', 'k', Q3_CVAR_NORESTART);
  FCVars.SetValueText('keep', 'changed');
  FCVars.Restart;
  Assert.IsNull(FCVars.Find('user'));
  Assert.AreEqual('a', string(FCVars.VariableString('code')));
  Assert.AreEqual('changed', string(FCVars.VariableString('keep')));
  Assert.AreEqual('1', string(FCVars.VariableString('sv_cheats')));
end;

procedure TTestQ3CVarSystem.DovrebbeSegnareVuotoLoSlotDiUnaVariabileTolta;
var
  LVm: TQ3VmCvar;
  LCount: Integer;
begin
  FCVars.Set2('user', 'x', False);
  FCVars.Register(LVm, 'user', 'x', Q3_CVAR_USER_CREATED);
  LCount := FCVars.IndexCount;
  FCVars.Restart;
  Assert.AreEqual(LCount, FCVars.IndexCount);
  Assert.AreEqual<Integer>(1, Length(FCVars.Variables));
  FCVars.SetValueText('zzz', 'y');
  FCVars.Update(LVm);
  Assert.AreEqual('x', string(LVm.StringValue));
end;

procedure TTestQ3CVarSystem.DovrebbeLeggereValoriStringaEInteri;
begin
  FCVars.Get('f', '12.5abc', 0);
  Assert.AreEqual(Single(12.5), FCVars.VariableValue('f'));
  Assert.AreEqual(12, FCVars.VariableIntegerValue('f'));
  Assert.AreEqual('12.5abc', string(FCVars.VariableString('f')));
  Assert.AreEqual(Single(0), FCVars.VariableValue('missing'));
  Assert.AreEqual(0, FCVars.VariableIntegerValue('missing'));
  Assert.AreEqual('', string(FCVars.VariableString('missing')));
end;

procedure TTestQ3CVarSystem.DovrebbeTroncareIlValoreNelBuffer;
begin
  FCVars.Get('a', 'abcdef', 0);
  Assert.AreEqual('abc', string(FCVars.VariableStringBuffer('a', 4)));
  Assert.AreEqual('', string(FCVars.VariableStringBuffer('missing', 4)));
end;

procedure TTestQ3CVarSystem.DovrebbeScrivereLeVariabiliDaArchiviare;
begin
  FCVars.Get('arch', 'v', Q3_CVAR_ARCHIVE);
  FCVars.Get('plain', 'p', 0);
  FCVars.Get('cl_cdkey', 'secret', Q3_CVAR_ARCHIVE);
  FCVars.Get('lat', 'x', Q3_CVAR_ARCHIVE or Q3_CVAR_LATCH);
  FCVars.SetLatched('lat', 'later');
  Assert.AreEqual('seta lat "later"'#10'seta arch "v"'#10, string(FCVars.WriteVariables));
end;

procedure TTestQ3CVarSystem.DovrebbeTroncareUnaRigaTroppoLungaDaScrivere;
var
  LText: string;
begin
  FCVars.Get('big', AnsiString(StringOfChar('x', 1100)), Q3_CVAR_ARCHIVE);
  FLog.TakePrinted;
  LText := string(FCVars.WriteVariables);
  Assert.AreEqual(1023, Length(LText));
  Assert.Contains(FLog.TakePrinted, 'Com_sprintf: overflow of 1112 in 1024');
end;

procedure TTestQ3CVarSystem.DovrebbeCostruireLeInfoString;
begin
  FCVars.Get('name', 'Player', Q3_CVAR_USERINFO);
  FCVars.Get('rate', '25000', Q3_CVAR_USERINFO);
  // the variables go through the list newest first, and each pair is put in front
  Assert.AreEqual('\name\Player\rate\25000', string(FCVars.InfoString(Q3_CVAR_USERINFO)));
  Assert.AreEqual('\sv_cheats\1', string(FCVars.InfoStringBig(Q3_CVAR_SYSTEMINFO)));
  Assert.AreEqual('\na', string(FCVars.InfoStringBuffer(Q3_CVAR_USERINFO, 4)));
end;

procedure TTestQ3CVarSystem.DovrebbeRifiutareLeInfoStringSenzaScrittore;
var
  LCVars: IQ3CVarSystem;
begin
  LCVars := TQ3CVarSystem.Create;
  Assert.WillRaise(
    procedure
    begin
      LCVars.InfoString(Q3_CVAR_USERINFO);
    end, EQ3ConsoleException);
end;

procedure TTestQ3CVarSystem.DovrebbeRegistrareEAggiornareUnaCopia;
var
  LVm: TQ3VmCvar;
begin
  FCVars.Register(LVm, 'r', '2.5', 0);
  Assert.AreEqual('2.5', string(LVm.StringValue));
  Assert.AreEqual(Single(2.5), LVm.Value);
  Assert.AreEqual(2, LVm.IntegerValue);
  Assert.AreEqual(1, LVm.ModificationCount);
  FCVars.SetValueText('r', '7');
  FCVars.Update(LVm);
  Assert.AreEqual(7, LVm.IntegerValue);
  Assert.AreEqual(2, LVm.ModificationCount);
  FCVars.Update(LVm);
  Assert.AreEqual(2, LVm.ModificationCount);
end;

procedure TTestQ3CVarSystem.DovrebbeRifiutareUnaManiglia;
var
  LVm: TQ3VmCvar;
begin
  LVm.Handle := 999;
  Assert.WillRaise(
    procedure
    begin
      FCVars.Update(LVm);
    end, EQ3ConsoleException);
  LVm.Handle := -1;
  Assert.WillRaise(
    procedure
    begin
      FCVars.Update(LVm);
    end, EQ3ConsoleException);
end;

procedure TTestQ3CVarSystem.DovrebbeRifiutareUnValoreTroppoLungoPerLaCopia;
var
  LVm: TQ3VmCvar;
begin
  FCVars.Register(LVm, 'r', 'a', 0);
  FCVars.SetValueText('r', AnsiString(StringOfChar('x', 256)));
  Assert.WillRaise(
    procedure
    begin
      FCVars.Update(LVm);
    end, EQ3ConsoleException);
end;

procedure TTestQ3CVarSystem.DovrebbeRifiutareLaMillesimaventicinquesimaVariabile;
var
  LIndex: Integer;
begin
  for LIndex := FCVars.IndexCount to Q3_MAX_CVARS - 1 do
    FCVars.Get(AnsiString('v' + IntToStr(LIndex)), '', 0);
  Assert.WillRaise(
    procedure
    begin
      FCVars.Get('one_more', '', 0);
    end, EQ3ConsoleException);
end;

procedure TTestQ3CVarSystem.DovrebbeTenereIFlagModificati;
begin
  FCVars.Get('u', 'a', Q3_CVAR_USERINFO);
  FCVars.ModifiedFlags := 0;
  FCVars.SetValueText('u', 'b');
  Assert.AreEqual(Q3_CVAR_USERINFO, FCVars.ModifiedFlags);
end;

procedure TTestQ3CVarSystem.DovrebbeFunzionareSenzaLog;
var
  LCVars: IQ3CVarSystem;
begin
  LCVars := TQ3CVarSystem.Create;
  LCVars.Get('bad;', 'x', 0);
  LCVars.Get('r', 'a', Q3_CVAR_ROM);
  LCVars.Set2('r', 'b', False);
  LCVars.Get('r', 'c', 0);
  LCVars.Get('w', 'a', 0);
  LCVars.Get('w', 'b', 0);
  LCVars.Reset('w');
  Assert.AreEqual('a', string(LCVars.VariableString('r')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CVarSystem);

end.
