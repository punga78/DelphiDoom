{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command list of the Quake III console              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.CommandSystem;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.CommandArguments,
  DelphiDoom.Console.Q3.CommandSystem, DelphiDoom.Tests.Console.Q3.Fakes;

type
  TFakeCVarHandler = class(TInterfacedObject, IQ3CVarCommandHandler)
  public
    Handles: Boolean;
    Calls: Integer;
    function Command: Boolean;
  end;

  [TestFixture]
  [Category('console')]
  TTestQ3CommandSystem = class(TObject)
  private
    FArguments: IQ3CommandArguments;
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FUnhandled: TFakeQ3Unhandled;
    FUnhandledIntf: IQ3UnhandledCommands;
    FSystem: TQ3CommandSystem;
    FSystemIntf: IQ3CommandRegistry;
    FCalls: string;
    procedure First;
    procedure Second;
    function Names: string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeRifiutareArgomentiNil;
    [Test]
    procedure DovrebbeEseguireUnComandoSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeMettereInTestaIlComandoEseguito;
    [Test]
    procedure DovrebbeSegnalareUnComandoGiaDefinitoSoloConUnaFunzione;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscoleQuandoAggiungeERimuove;
    [Test]
    procedure DovrebbeIgnorareUnRigaSenzaToken;
    [Test]
    procedure DovrebbeDareLaRigaAlGestoreDelleCvarSeNonECUnComando;
    [Test]
    procedure DovrebbeDareLaRigaAlGiocoSeNessunoLaGestisce;
    [Test]
    procedure DovrebbeProseguireConLeCvarPerUnComandoSenzaFunzione;
    [Test]
    procedure DovrebbeFunzionareSenzaGestoriNeLog;
  end;

implementation

function TFakeCVarHandler.Command: Boolean;
begin
  Inc(Calls);
  Result := Handles;
end;

procedure TTestQ3CommandSystem.Setup;
begin
  FArguments := TQ3CommandArguments.Create;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FUnhandled := TFakeQ3Unhandled.Create(FLogIntf);
  FUnhandledIntf := FUnhandled;
  FSystem := TQ3CommandSystem.Create(FArguments, FLogIntf, FUnhandledIntf);
  FSystemIntf := FSystem;
  FCalls := '';
end;

procedure TTestQ3CommandSystem.First;
begin
  FCalls := FCalls + 'first:' + string(FArguments.Argv(1)) + ';';
end;

procedure TTestQ3CommandSystem.Second;
begin
  FCalls := FCalls + 'second;';
end;

function TTestQ3CommandSystem.Names: string;
var
  LName: AnsiString;
begin
  Result := '';
  for LName in FSystemIntf.CommandNames do
    Result := Result + string(LName) + ' ';
end;

procedure TTestQ3CommandSystem.DovrebbeRifiutareArgomentiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3CommandSystem.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestQ3CommandSystem.DovrebbeEseguireUnComandoSenzaDistinguereLeMaiuscole;
begin
  FSystemIntf.AddCommand('Alpha', First);
  FSystemIntf.ExecuteString('aLPHA x');
  Assert.AreEqual('first:x;', FCalls);
end;

procedure TTestQ3CommandSystem.DovrebbeMettereInTestaIlComandoEseguito;
begin
  FSystemIntf.AddCommand('a', First);
  FSystemIntf.AddCommand('b', Second);
  Assert.AreEqual('b a ', Names);
  FSystemIntf.ExecuteString('a');
  Assert.AreEqual('a b ', Names);
end;

procedure TTestQ3CommandSystem.DovrebbeSegnalareUnComandoGiaDefinitoSoloConUnaFunzione;
begin
  FSystemIntf.AddCommand('a', First);
  FSystemIntf.AddCommand('a', Second);
  Assert.AreEqual('Cmd_AddCommand: a already defined'#10, FLog.TakePrinted);
  FSystemIntf.AddCommand('a', nil);
  Assert.AreEqual('', FLog.TakePrinted);
  FSystemIntf.ExecuteString('a');
  Assert.AreEqual('first:;', FCalls);
end;

procedure TTestQ3CommandSystem.DovrebbeDistinguereLeMaiuscoleQuandoAggiungeERimuove;
begin
  FSystemIntf.AddCommand('a', First);
  FSystemIntf.AddCommand('A', Second);
  Assert.AreEqual('A a ', Names);
  FSystemIntf.RemoveCommand('a');
  FSystemIntf.RemoveCommand('missing');
  Assert.AreEqual('A ', Names);
end;

procedure TTestQ3CommandSystem.DovrebbeIgnorareUnRigaSenzaToken;
begin
  FSystemIntf.ExecuteString('  // niente');
  Assert.AreEqual<Integer>(0, Length(FUnhandled.Lines));
end;

procedure TTestQ3CommandSystem.DovrebbeDareLaRigaAlGestoreDelleCvarSeNonECUnComando;
var
  LHandler: TFakeCVarHandler;
  LHandlerIntf: IQ3CVarCommandHandler;
begin
  LHandler := TFakeCVarHandler.Create;
  LHandlerIntf := LHandler;
  LHandler.Handles := True;
  FSystem.CVarHandler := LHandlerIntf;
  FSystemIntf.ExecuteString('somevar 5');
  Assert.AreEqual(1, LHandler.Calls);
  Assert.AreEqual<Integer>(0, Length(FUnhandled.Lines));
  FSystem.CVarHandler := nil;
end;

procedure TTestQ3CommandSystem.DovrebbeDareLaRigaAlGiocoSeNessunoLaGestisce;
var
  LHandler: TFakeCVarHandler;
  LHandlerIntf: IQ3CVarCommandHandler;
begin
  LHandler := TFakeCVarHandler.Create;
  LHandlerIntf := LHandler;
  FSystem.CVarHandler := LHandlerIntf;
  FSystemIntf.ExecuteString('chat hello  world');
  Assert.AreEqual<Integer>(1, Length(FUnhandled.Lines));
  Assert.AreEqual('chat hello  world', string(FUnhandled.Lines[0]));
  FSystem.CVarHandler := nil;
end;

procedure TTestQ3CommandSystem.DovrebbeProseguireConLeCvarPerUnComandoSenzaFunzione;
begin
  FSystemIntf.AddCommand('gamecmd', nil);
  FSystemIntf.ExecuteString('gamecmd 1');
  Assert.AreEqual<Integer>(1, Length(FUnhandled.Lines));
end;

procedure TTestQ3CommandSystem.DovrebbeFunzionareSenzaGestoriNeLog;
var
  LSystem: IQ3CommandRegistry;
begin
  LSystem := TQ3CommandSystem.Create(FArguments);
  LSystem.AddCommand('a', First);
  LSystem.AddCommand('a', First);
  LSystem.ExecuteString('unknown');
  LSystem.ExecuteString('a');
  Assert.AreEqual('first:;', FCalls);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CommandSystem);

end.
