{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the commands of cvar.c of the Quake III console        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.CVarCommands;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.CommandArguments, DelphiDoom.Console.Q3.CommandSystem, DelphiDoom.Console.Q3.CVarSystem,
  DelphiDoom.Console.Q3.CVarCommands, DelphiDoom.Tests.Console.Q3.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestQ3CVarCommands = class(TObject)
  private
    FArguments: IQ3CommandArguments;
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FSystem: TQ3CommandSystem;
    FRegistry: IQ3CommandRegistry;
    FCVars: IQ3CVarSystem;
    FCommands: TQ3CVarCommands;
    procedure Run(const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareArgomentiNil;
    [Test]
    procedure DovrebbeRegistrareGliOttoComandi;
    [Test]
    procedure DovrebbeStampareUnaVariabileSenzaValore;
    [Test]
    procedure DovrebbeStampareIlValoreInSospeso;
    [Test]
    procedure DovrebbeImpostareUnaVariabileDalNome;
    [Test]
    procedure DovrebbeUnireGliArgomentiDiSet;
    [Test]
    procedure DovrebbeFermareLaSomma;
    [Test]
    procedure DovrebbeDareLUsoDiSet;
    [Test]
    procedure DovrebbeAggiungereIFlagConSetuSetsESeta;
    [Test]
    procedure DovrebbeDareLUsoDeiComandiConFlag;
    [Test]
    procedure DovrebbeAlternareUnaVariabile;
    [Test]
    procedure DovrebbeDareLUsoDiToggleEReset;
    [Test]
    procedure DovrebbeRiportareUnaVariabileAlValoreDiReimpostazione;
    [Test]
    procedure DovrebbeElencareLeVariabili;
    [Test]
    procedure DovrebbeContareTutteLeVariabiliAncheConUnaMaschera;
    [Test]
    procedure DovrebbeRiavviareLeVariabili;
    [Test]
    procedure DovrebbeDareFalsoPerUnaRigaCheNonEUnaVariabile;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

implementation

procedure TTestQ3CVarCommands.Setup;
begin
  FArguments := TQ3CommandArguments.Create;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FSystem := TQ3CommandSystem.Create(FArguments, FLogIntf);
  FRegistry := FSystem;
  FCVars := TQ3CVarSystem.Create(FLogIntf);
  FCVars.Init;
  FCommands := TQ3CVarCommands.Create(FRegistry, FCVars, FArguments, FLogIntf);
  FCommands.Init;
  FSystem.CVarHandler := FCommands;
end;

procedure TTestQ3CVarCommands.TearDown;
begin
  FSystem.CVarHandler := nil;
  FCommands.Free;
end;

procedure TTestQ3CVarCommands.Run(const AText: AnsiString);
begin
  FRegistry.ExecuteString(AText);
end;

procedure TTestQ3CVarCommands.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3CVarCommands.Create(nil, FCVars, FArguments);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3CVarCommands.Create(FRegistry, nil, FArguments);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TQ3CVarCommands.Create(FRegistry, FCVars, nil);
    end, EArgumentNilException);
end;

procedure TTestQ3CVarCommands.DovrebbeRegistrareGliOttoComandi;
begin
  Assert.AreEqual<Integer>(8, Length(FRegistry.CommandNames));
end;

procedure TTestQ3CVarCommands.DovrebbeStampareUnaVariabileSenzaValore;
begin
  FCVars.Get('Rate', '25000', 0);
  Run('rate');
  Assert.AreEqual('"Rate" is:"25000^7" default:"25000^7"'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeStampareIlValoreInSospeso;
begin
  FCVars.Get('l', 'a', Q3_CVAR_LATCH);
  FCVars.SetLatched('l', 'b');
  FLog.TakePrinted;
  Run('l');
  Assert.AreEqual('"l" is:"a^7" default:"a^7"'#10'latched: "b"'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeImpostareUnaVariabileDalNome;
begin
  FCVars.Get('rate', '1', 0);
  Run('RATE 99 ignored');
  Assert.AreEqual('99', string(FCVars.VariableString('rate')));
end;

procedure TTestQ3CVarCommands.DovrebbeUnireGliArgomentiDiSet;
begin
  Run('set greeting hello  big "wide world"');
  Assert.AreEqual('hello big wide world', string(FCVars.VariableString('greeting')));
  Assert.AreEqual(Q3_CVAR_USER_CREATED, FCVars.Find('greeting').Flags);
end;

procedure TTestQ3CVarCommands.DovrebbeFermareLaSomma;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := 'set big';
  for LIndex := 1 to 5 do
    LText := LText + ' ' + AnsiString(StringOfChar('x', 301));
  Run(LText);
  // 300 + 300 + 300 < 1022, the fourth would reach 1200: the three that fit, with a space after each
  Assert.AreEqual(3 * 301 + 3, Length(FCVars.VariableString('big')));
end;

procedure TTestQ3CVarCommands.DovrebbeDareLUsoDiSet;
begin
  Run('set a');
  Assert.AreEqual('usage: set <variable> <value>'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeAggiungereIFlagConSetuSetsESeta;
begin
  Run('setu u 1');
  Run('sets s 2');
  Run('seta a 3');
  Assert.AreEqual(Q3_CVAR_USER_CREATED or Q3_CVAR_USERINFO, FCVars.Find('u').Flags);
  Assert.AreEqual(Q3_CVAR_USER_CREATED or Q3_CVAR_SERVERINFO, FCVars.Find('s').Flags);
  Assert.AreEqual(Q3_CVAR_USER_CREATED or Q3_CVAR_ARCHIVE, FCVars.Find('a').Flags);
end;

procedure TTestQ3CVarCommands.DovrebbeDareLUsoDeiComandiConFlag;
begin
  Run('setu u');
  Run('sets s');
  Run('seta a 1 2');
  Assert.AreEqual('usage: setu <variable> <value>'#10'usage: sets <variable> <value>'#10 +
    'usage: seta <variable> <value>'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeAlternareUnaVariabile;
begin
  FCVars.Get('t', '0', 0);
  Run('toggle t');
  Assert.AreEqual('1', string(FCVars.VariableString('t')));
  Run('toggle t');
  Assert.AreEqual('0', string(FCVars.VariableString('t')));
  FCVars.SetValueText('t', '0.5');
  Run('toggle t');
  Assert.AreEqual('1', string(FCVars.VariableString('t')));
  Run('toggle missing');
  Assert.AreEqual('1', string(FCVars.VariableString('missing')));
end;

procedure TTestQ3CVarCommands.DovrebbeDareLUsoDiToggleEReset;
begin
  Run('toggle');
  Run('reset');
  Assert.AreEqual('usage: toggle <variable>'#10'usage: reset <variable>'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeRiportareUnaVariabileAlValoreDiReimpostazione;
begin
  FCVars.Get('a', 'one', 0);
  FCVars.SetValueText('a', 'two');
  Run('reset a');
  Assert.AreEqual('one', string(FCVars.VariableString('a')));
end;

procedure TTestQ3CVarCommands.DovrebbeElencareLeVariabili;
begin
  FCVars.Get('abc', 'v', Q3_CVAR_SERVERINFO or Q3_CVAR_ARCHIVE);
  FCVars.Get('xyz', 'w', Q3_CVAR_USERINFO or Q3_CVAR_ROM or Q3_CVAR_INIT or Q3_CVAR_LATCH or Q3_CVAR_CHEAT);
  Run('cvarlist x*');
  Assert.AreEqual(' URI LC xyz "w"'#10#10'3 total cvars'#10'3 cvar indexes'#10, FLog.TakePrinted);
  Run('cvarlist abc');
  Assert.AreEqual('S   A   abc "v"'#10#10'3 total cvars'#10'3 cvar indexes'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeContareTutteLeVariabiliAncheConUnaMaschera;
begin
  FCVars.Get('abc', 'v', 0);
  Run('cvarlist zzz');
  Assert.AreEqual(#10'2 total cvars'#10'2 cvar indexes'#10, FLog.TakePrinted);
end;

procedure TTestQ3CVarCommands.DovrebbeRiavviareLeVariabili;
begin
  Run('set user 1');
  FCVars.Get('code', 'a', 0);
  FCVars.SetValueText('code', 'b');
  Run('cvar_restart');
  Assert.IsNull(FCVars.Find('user'));
  Assert.AreEqual('a', string(FCVars.VariableString('code')));
end;

procedure TTestQ3CVarCommands.DovrebbeDareFalsoPerUnaRigaCheNonEUnaVariabile;
begin
  FArguments.Tokenize('unknown 1');
  Assert.IsFalse(FCommands.Command);
end;

procedure TTestQ3CVarCommands.DovrebbeFunzionareSenzaLog;
var
  LCommands: TQ3CVarCommands;
begin
  LCommands := TQ3CVarCommands.Create(FRegistry, FCVars, FArguments);
  try
    FCVars.Get('a', '1', 0);
    FArguments.Tokenize('a');
    Assert.IsTrue(LCommands.Command);
    FArguments.Tokenize('toggle');
    LCommands.Toggle;
    FArguments.Tokenize('set');
    LCommands.SetCommand;
    FArguments.Tokenize('reset');
    LCommands.ResetCommand;
    FArguments.Tokenize('cvarlist');
    LCommands.List;
    FCVars.Get('l', 'x', Q3_CVAR_LATCH);
    FCVars.SetLatched('l', 'y');
    FArguments.Tokenize('l');
    LCommands.Command;
    FArguments.Tokenize('setu x');
    LCommands.SetUserInfo;
  finally
    LCommands.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CVarCommands);

end.
