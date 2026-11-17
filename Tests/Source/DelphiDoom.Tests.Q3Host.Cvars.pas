{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the cvar and command       }
{  system calls of qagame, cgame and ui on the Quake III console of             }
{  Framework\Console (equal to cvar.c and cmd.c: Tests.Console)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Cvars;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Qvm.Intf, DelphiDoom.Console.Q3.Factory, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.Intf;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3CvarSyscalls = class
  strict private
    FConsole: TQ3Console;
    FHosts: array[TQ3Module] of IQ3SyscallHost;
    FMachines: array[TQ3Module] of IQvmMachine;
    function Call(AModule: TQ3Module; const AValues: array of Integer): Integer;
    procedure Put(AModule: TQ3Module; AAddress: Integer; const AText: AnsiString);
    function Get(AModule: TQ3Module; AAddress: Integer): AnsiString;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaRegistrazioneDovrebbeScrivereIlVmCvarComeIlC;
    [Test]
    procedure LAggiornamentoDovrebbeScrivereSoloSeLaVariabileEcambiata;
    [Test]
    procedure UnVmCvarNulloDovrebbeSoloCreareLaVariabile;
    [Test]
    procedure ImpostareEdLeggereUnaVariabileDovrebbeDareIValoriDelC;
    [Test]
    procedure UnValoreNulloDovrebbeRimettereLaStringaDiReset;
    [Test]
    procedure IlBufferDiUnaVariabileCheNonCeDovrebbeEssereVuoto;
    [Test]
    procedure IlBufferPiuPiccoloDelTestoDovrebbeTroncareEPadare;
    [Test]
    procedure UnBufferDiLunghezzaZeroDovrebbeEssereUnErrore;
    [Test]
    procedure GliArgomentiDovrebberoVenireDalComandoCorrente;
    [Test]
    procedure IlTestoDaEseguireDovrebbeEntrareNelBufferDeiComandi;
    [Test]
    procedure UnTempoDiEsecuzioneNonValidoDovrebbeEssereUnErrore;
    [Test]
    procedure IlComandoDiCgameDovrebbeEssereAggiuntoERimosso;
    [Test]
    procedure LeChiamateDiUiSuiValoriDovrebberoUsareLeVariabili;
    [Test]
    procedure OgniModuloDovrebbeAvereSoloLeSueChiamate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Factory, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.CVar, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Factory, DelphiDoom.Tests.Qvm.Programs, DelphiDoom.Tests.Qvm.Support,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services;

const
  NAME_ADDRESS = 1000;
  DEFAULT_ADDRESS = 1100;
  VMCVAR_ADDRESS = 2000;
  BUFFER_ADDRESS = 3000;

procedure TTestQ3CvarSyscalls.Setup;
var
  LModule: TQ3Module;
  LServices: TQ3HostServices;
  LText: Integer;
begin
  FConsole := TQ3Console.Create;
  FConsole.Init;
  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    FHosts[LModule] := TQ3HostFactory.CreateHostWithServices(LModule, TQ3RecordingConsole.Create(nil),
      TQ3FixedTime.Create(0), LServices);
    FMachines[LModule] := TQvmFactory.CreateMachine('cvar', TQvmPrograms.AnySystemCall(LText), FHosts[LModule]);
  end;
end;

procedure TTestQ3CvarSyscalls.TearDown;
var
  LModule: TQ3Module;
begin
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    FMachines[LModule] := nil;
    FHosts[LModule] := nil;
  end;
  FConsole.Free;
end;

function TTestQ3CvarSyscalls.Call(AModule: TQ3Module; const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHosts[AModule], FMachines[AModule], AValues);
end;

procedure TTestQ3CvarSyscalls.Put(AModule: TQ3Module; AAddress: Integer; const AText: AnsiString);
begin
  FMachines[AModule].Memory.WriteString(AAddress, AText, Length(AText) + 1);
end;

function TTestQ3CvarSyscalls.Get(AModule: TQ3Module; AAddress: Integer): AnsiString;
begin
  Result := FMachines[AModule].Memory.ReadString(AAddress);
end;

procedure TTestQ3CvarSyscalls.LaRegistrazioneDovrebbeScrivereIlVmCvarComeIlC;
var
  LModule: TQ3Module;
  LNumber: array[TQ3Module] of Integer;
  LMemory: IQvmMemory;
  LCVar: TQ3CVar;
  LCVarName: AnsiString;
begin
  LNumber[TQ3Module.Game] := G_CVAR_REGISTER;
  LNumber[TQ3Module.CGame] := CG_CVAR_REGISTER;
  LNumber[TQ3Module.Ui] := UI_CVAR_REGISTER;
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    LMemory := FMachines[LModule].Memory;
    LCVarName := AnsiString('g_test') + AnsiChar(Ord('0') + Ord(LModule));
    Put(LModule, NAME_ADDRESS, LCVarName);
    Put(LModule, DEFAULT_ADDRESS, '12.5');
    LMemory.Fill(VMCVAR_ADDRESS, $77, 280);
    Assert.AreEqual(0, Call(LModule, [LNumber[LModule], VMCVAR_ADDRESS, NAME_ADDRESS, DEFAULT_ADDRESS, 0]));
    LCVar := FConsole.CVars.Find(LCVarName);
    Assert.IsNotNull(LCVar);
    // vmCvar_t: handle, modificationCount, value, integer, string[256]
    Assert.AreEqual(LCVar.ModificationCount, LMemory.ReadInt32(VMCVAR_ADDRESS + 4));
    Assert.AreEqual(TQ3TestCalls.Bits(12.5), LMemory.ReadInt32(VMCVAR_ADDRESS + 8));
    Assert.AreEqual(12, LMemory.ReadInt32(VMCVAR_ADDRESS + 12));
    Assert.AreEqual('12.5', string(Get(LModule, VMCVAR_ADDRESS + 16)));
    // the string is padded with zeroes up to its 256 bytes
    Assert.AreEqual(0, Integer(LMemory.ReadByte(VMCVAR_ADDRESS + 16 + 255)));
    Assert.AreEqual($77, Integer(LMemory.ReadByte(VMCVAR_ADDRESS + 272)));
  end;
end;

procedure TTestQ3CvarSyscalls.LAggiornamentoDovrebbeScrivereSoloSeLaVariabileEcambiata;
var
  LMemory: IQvmMemory;
begin
  LMemory := FMachines[TQ3Module.Game].Memory;
  Put(TQ3Module.Game, NAME_ADDRESS, 'g_up');
  Put(TQ3Module.Game, DEFAULT_ADDRESS, '1');
  Call(TQ3Module.Game, [G_CVAR_REGISTER, VMCVAR_ADDRESS, NAME_ADDRESS, DEFAULT_ADDRESS, 0]);
  // nothing changed: the bytes of the module stay
  LMemory.WriteByte(VMCVAR_ADDRESS + 16, Ord('Z'));
  Call(TQ3Module.Game, [G_CVAR_UPDATE, VMCVAR_ADDRESS]);
  Assert.AreEqual(Integer(Ord('Z')), Integer(LMemory.ReadByte(VMCVAR_ADDRESS + 16)));
  // changed: everything is written again
  FConsole.CVars.SetValueText('g_up', '7');
  Call(TQ3Module.Game, [G_CVAR_UPDATE, VMCVAR_ADDRESS]);
  Assert.AreEqual('7', string(Get(TQ3Module.Game, VMCVAR_ADDRESS + 16)));
  Assert.AreEqual(7, LMemory.ReadInt32(VMCVAR_ADDRESS + 12));
  Assert.AreEqual(TQ3TestCalls.Bits(7), LMemory.ReadInt32(VMCVAR_ADDRESS + 8));
  Assert.AreEqual(FConsole.CVars.Find('g_up').ModificationCount, LMemory.ReadInt32(VMCVAR_ADDRESS + 4));
  // a handle that is not a variable is the Com_Error of the C
  LMemory.WriteInt32(VMCVAR_ADDRESS, 100000);
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call(TQ3Module.Game, [G_CVAR_UPDATE, VMCVAR_ADDRESS]);
    end, EQ3ConsoleException));
end;

procedure TTestQ3CvarSyscalls.UnVmCvarNulloDovrebbeSoloCreareLaVariabile;
begin
  Put(TQ3Module.CGame, NAME_ADDRESS, 'cg_made');
  Put(TQ3Module.CGame, DEFAULT_ADDRESS, '3');
  Assert.AreEqual(0, Call(TQ3Module.CGame, [CG_CVAR_REGISTER, 0, NAME_ADDRESS, DEFAULT_ADDRESS, 0]));
  Assert.AreEqual(3, FConsole.CVars.VariableIntegerValue('cg_made'));
end;

procedure TTestQ3CvarSyscalls.ImpostareEdLeggereUnaVariabileDovrebbeDareIValoriDelC;
begin
  Put(TQ3Module.Game, NAME_ADDRESS, 'g_set');
  Put(TQ3Module.Game, DEFAULT_ADDRESS, '-5.75');
  // Cvar_Set creates the variable (forced) with the value
  Call(TQ3Module.Game, [G_CVAR_SET, NAME_ADDRESS, DEFAULT_ADDRESS]);
  Assert.AreEqual(-5, Call(TQ3Module.Game, [G_CVAR_VARIABLE_INTEGER_VALUE, NAME_ADDRESS]));
  Assert.AreEqual('-5.75', string(FConsole.CVars.VariableString('g_set')));
  // a variable that is not there is 0
  Put(TQ3Module.Game, NAME_ADDRESS, 'g_none');
  Assert.AreEqual(0, Call(TQ3Module.Game, [G_CVAR_VARIABLE_INTEGER_VALUE, NAME_ADDRESS]));
  // ui: the value as the bits of a float
  Put(TQ3Module.Ui, NAME_ADDRESS, 'ui_f');
  Put(TQ3Module.Ui, DEFAULT_ADDRESS, '2.5');
  Call(TQ3Module.Ui, [UI_CVAR_SET, NAME_ADDRESS, DEFAULT_ADDRESS]);
  Assert.AreEqual(TQ3TestCalls.Bits(2.5), Call(TQ3Module.Ui, [UI_CVAR_VARIABLEVALUE, NAME_ADDRESS]));
end;

procedure TTestQ3CvarSyscalls.UnValoreNulloDovrebbeRimettereLaStringaDiReset;
begin
  FConsole.CVars.Get('g_reset', '5', 0);
  FConsole.CVars.SetValueText('g_reset', '9');
  Put(TQ3Module.Game, NAME_ADDRESS, 'g_reset');
  // Cvar_Set( name, NULL )
  Call(TQ3Module.Game, [G_CVAR_SET, NAME_ADDRESS, 0]);
  Assert.AreEqual('5', string(FConsole.CVars.VariableString('g_reset')));
  // a variable that is not there stays missing
  Put(TQ3Module.Game, NAME_ADDRESS, 'g_nothere');
  Call(TQ3Module.Game, [G_CVAR_SET, NAME_ADDRESS, 0]);
  Assert.IsNull(FConsole.CVars.Find('g_nothere'));
end;

procedure TTestQ3CvarSyscalls.IlBufferDiUnaVariabileCheNonCeDovrebbeEssereVuoto;
begin
  Put(TQ3Module.CGame, NAME_ADDRESS, 'nothing');
  FMachines[TQ3Module.CGame].Memory.Fill(BUFFER_ADDRESS, $55, 8);
  Call(TQ3Module.CGame, [CG_CVAR_VARIABLESTRINGBUFFER, NAME_ADDRESS, BUFFER_ADDRESS, 8]);
  // only the first byte is written, as *buffer = 0
  Assert.AreEqual(0, Integer(FMachines[TQ3Module.CGame].Memory.ReadByte(BUFFER_ADDRESS)));
  Assert.AreEqual($55, Integer(FMachines[TQ3Module.CGame].Memory.ReadByte(BUFFER_ADDRESS + 1)));
end;

procedure TTestQ3CvarSyscalls.IlBufferPiuPiccoloDelTestoDovrebbeTroncareEPadare;
var
  LMemory: IQvmMemory;
begin
  FConsole.CVars.SetValueText('longer', 'abcdefghij');
  Put(TQ3Module.Ui, NAME_ADDRESS, 'longer');
  LMemory := FMachines[TQ3Module.Ui].Memory;
  LMemory.Fill(BUFFER_ADDRESS, $55, 20);
  Call(TQ3Module.Ui, [UI_CVAR_VARIABLESTRINGBUFFER, NAME_ADDRESS, BUFFER_ADDRESS, 5]);
  // Q_strncpyz: 4 characters and the zero
  Assert.AreEqual('abcd', string(Get(TQ3Module.Ui, BUFFER_ADDRESS)));
  Assert.AreEqual($55, Integer(LMemory.ReadByte(BUFFER_ADDRESS + 5)));
  // a size that fits: all of it, with the zero
  Call(TQ3Module.Ui, [UI_CVAR_VARIABLESTRINGBUFFER, NAME_ADDRESS, BUFFER_ADDRESS, 11]);
  Assert.AreEqual('abcdefghij', string(Get(TQ3Module.Ui, BUFFER_ADDRESS)));
end;

procedure TTestQ3CvarSyscalls.UnBufferDiLunghezzaZeroDovrebbeEssereUnErrore;
begin
  FConsole.CVars.SetValueText('zero', 'x');
  Put(TQ3Module.Game, NAME_ADDRESS, 'zero');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call(TQ3Module.Game, [G_CVAR_VARIABLE_STRING_BUFFER, NAME_ADDRESS, BUFFER_ADDRESS, 0]);
    end, EQ3ModuleErrorException));
end;

procedure TTestQ3CvarSyscalls.GliArgomentiDovrebberoVenireDalComandoCorrente;
begin
  FConsole.Arguments.Tokenize('say "hello world" third');
  Assert.AreEqual(3, Call(TQ3Module.Game, [G_ARGC]));
  Assert.AreEqual(3, Call(TQ3Module.CGame, [CG_ARGC]));
  Assert.AreEqual(3, Call(TQ3Module.Ui, [UI_ARGC]));
  Call(TQ3Module.Game, [G_ARGV, 1, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('hello world', string(Get(TQ3Module.Game, BUFFER_ADDRESS)));
  // an argument that is not there is empty, one that does not fit is cut
  Call(TQ3Module.Ui, [UI_ARGV, 9, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('', string(Get(TQ3Module.Ui, BUFFER_ADDRESS)));
  Call(TQ3Module.Ui, [UI_ARGV, 1, BUFFER_ADDRESS, 6]);
  Assert.AreEqual('hello', string(Get(TQ3Module.Ui, BUFFER_ADDRESS)));
  // cgame also has the rest of the line: the tokens joined by a space (Cmd_Args, without the quotes)
  Call(TQ3Module.CGame, [CG_ARGS, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('hello world third',string(Get(TQ3Module.CGame, BUFFER_ADDRESS)));
end;

procedure TTestQ3CvarSyscalls.IlTestoDaEseguireDovrebbeEntrareNelBufferDeiComandi;
begin
  Put(TQ3Module.Game, NAME_ADDRESS, 'echo one');
  // EXEC_APPEND = 2
  Call(TQ3Module.Game, [G_SEND_CONSOLE_COMMAND, 2, NAME_ADDRESS]);
  Assert.AreEqual('echo one', string(FConsole.Buffer.Pending));
  // cgame always appends
  Put(TQ3Module.CGame, NAME_ADDRESS, 'echo two');
  Call(TQ3Module.CGame, [CG_SENDCONSOLECOMMAND, NAME_ADDRESS]);
  Assert.AreEqual('echo oneecho two', string(FConsole.Buffer.Pending));
  // ui: EXEC_INSERT = 1 goes in front, with a line feed
  Put(TQ3Module.Ui, NAME_ADDRESS, 'echo zero');
  Call(TQ3Module.Ui, [UI_CMD_EXECUTETEXT, 1, NAME_ADDRESS]);
  Assert.AreEqual('echo zero'#10'echo oneecho two', string(FConsole.Buffer.Pending));
end;

procedure TTestQ3CvarSyscalls.UnTempoDiEsecuzioneNonValidoDovrebbeEssereUnErrore;
begin
  Put(TQ3Module.Game, NAME_ADDRESS, 'echo x');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call(TQ3Module.Game, [G_SEND_CONSOLE_COMMAND, 3, NAME_ADDRESS]);
    end, EQ3HostException));
end;

procedure TTestQ3CvarSyscalls.IlComandoDiCgameDovrebbeEssereAggiuntoERimosso;
var
  LNames: TArray<AnsiString>;
  LName: AnsiString;
  LFound: Boolean;
begin
  Put(TQ3Module.CGame, NAME_ADDRESS, 'cg_command');
  Call(TQ3Module.CGame, [CG_ADDCOMMAND, NAME_ADDRESS]);
  LFound := False;
  LNames := FConsole.Commands.CommandNames;
  for LName in LNames do
    LFound := LFound or (LName = 'cg_command');
  Assert.IsTrue(LFound);
  Call(TQ3Module.CGame, [CG_REMOVECOMMAND, NAME_ADDRESS]);
  LFound := False;
  LNames := FConsole.Commands.CommandNames;
  for LName in LNames do
    LFound := LFound or (LName = 'cg_command');
  Assert.IsFalse(LFound);
end;

procedure TTestQ3CvarSyscalls.LeChiamateDiUiSuiValoriDovrebberoUsareLeVariabili;
begin
  Put(TQ3Module.Ui, NAME_ADDRESS, 'ui_made');
  Put(TQ3Module.Ui, DEFAULT_ADDRESS, '4');
  // UI_CVAR_CREATE: Cvar_Get, flags in the third argument (ARCHIVE = 1)
  Call(TQ3Module.Ui, [UI_CVAR_CREATE, NAME_ADDRESS, DEFAULT_ADDRESS, 1]);
  Assert.AreEqual(1, FConsole.CVars.Find('ui_made').Flags and 1);
  // UI_CVAR_SETVALUE: a float without a fraction is an integer
  Call(TQ3Module.Ui, [UI_CVAR_SETVALUE, NAME_ADDRESS, TQ3TestCalls.Bits(9)]);
  Assert.AreEqual('9', string(FConsole.CVars.VariableString('ui_made')));
  Call(TQ3Module.Ui, [UI_CVAR_RESET, NAME_ADDRESS]);
  Assert.AreEqual('4', string(FConsole.CVars.VariableString('ui_made')));
end;

procedure TTestQ3CvarSyscalls.OgniModuloDovrebbeAvereSoloLeSueChiamate;
begin
  // game has no CVAR_VARIABLEVALUE nor commands of the client; ui has no CG_ARGS
  Assert.IsTrue(FHosts[TQ3Module.Game].Registry.IsRegistered(G_SEND_CONSOLE_COMMAND));
  Assert.IsTrue(FHosts[TQ3Module.CGame].Registry.IsRegistered(CG_ADDCOMMAND));
  Assert.IsTrue(FHosts[TQ3Module.CGame].Registry.IsRegistered(CG_ARGS));
  Assert.IsTrue(FHosts[TQ3Module.Ui].Registry.IsRegistered(UI_CVAR_INFOSTRINGBUFFER));
  // 12 common calls + cvar/command calls of each module
  Assert.AreEqual(12 + 8,FHosts[TQ3Module.Game].Registry.RegisteredCount);
  Assert.AreEqual(12 + 10, FHosts[TQ3Module.CGame].Registry.RegisteredCount);
  Assert.AreEqual(12 + 12, FHosts[TQ3Module.Ui].Registry.RegisteredCount);
end;

end.
