{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the constants of the scripts in the compiler           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ConstantsCompiler;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostConstantsCompiler = class(TObject)
  public
    [Test]
    procedure DovrebbeDareErroreSeIlCompilatoreEnil;
    [Test]
    procedure DovrebbeFarLeggereAUnoScriptUnaCostanteIntera;
    [Test]
    procedure DovrebbeFarLeggereAUnoScriptUnaCostanteSenzaSegno;
    [Test]
    procedure DovrebbeFarLeggereAUnoScriptUnaCostanteReale;
    [Test]
    procedure DovrebbeNonDistinguereLeMaiuscoleNelNomeDellaCostante;
    [Test]
    procedure DovrebbeDareErroreDiCompilazioneSeLaCostanteNonEstataAggiunta;
    [Test]
    procedure DovrebbeFarLeggereAUnoScriptTutteLeCostantiDellaFabbrica;
  end;

implementation

uses
  System.SysUtils,
  ps_defs,
  ps_compiler,
  DelphiDoom.ScriptHost.Constants.Compiler,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.Tests.ScriptHost.ConstantFakes,
  DelphiDoom.Tests.ScriptHost.Interpreter;

var
  // the OnUses of the compiler is a plain function: it reaches the provider of the running test
  GProvider: IScriptConstantProvider = nil;

function ConstantsOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result and Assigned(GProvider) then
    GProvider.Describe(TScriptHostFactory.CreateCompilerConstants(Sender));
end;

type
  /// <summary>Writes a constant of each type: 2147483647, 4294967295 and 1.5</summary>
  TThreeConstants = class(TInterfacedObject, IScriptConstantProvider)
  public
    procedure Describe(const ATable: IScriptConstantTable);
  end;

procedure TThreeConstants.Describe(const ATable: IScriptConstantTable);
begin
  ATable.AddInteger('KInt', 2147483647);
  ATable.AddLongWord('KLong', 4294967295);
  ATable.AddExtended('KReal', 1.5);
end;

function Run(const ASource: string; const AProvider: IScriptConstantProvider): TTestInterpreter;
begin
  GProvider := AProvider;
  try
    Result := TTestInterpreter.Create(ASource, True, ConstantsOnUses, nil, nil);
  finally
    GProvider := nil;
  end;
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeDareErroreSeIlCompilatoreEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptCompilerConstants.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeFarLeggereAUnoScriptUnaCostanteIntera;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := Run('var a: integer;'#13#10'begin'#13#10'  a := KInt;'#13#10'end.', TThreeConstants.Create);
  try
    Assert.AreEqual(2147483647, LInterpreter.IntegerOf(0));
  finally
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeFarLeggereAUnoScriptUnaCostanteSenzaSegno;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := Run('var a: longword;'#13#10'begin'#13#10'  a := KLong;'#13#10'end.', TThreeConstants.Create);
  try
    // the variable holds 4294967295: read as a signed integer it is -1
    Assert.AreEqual(-1, LInterpreter.IntegerOf(0));
  finally
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeFarLeggereAUnoScriptUnaCostanteReale;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := Run('var a: extended;'#13#10'begin'#13#10'  a := KReal;'#13#10'end.', TThreeConstants.Create);
  try
    Assert.AreEqual(1.5, LInterpreter.FloatOf(0), 0.0000001);
  finally
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeNonDistinguereLeMaiuscoleNelNomeDellaCostante;
var
  LInterpreter: TTestInterpreter;
begin
  LInterpreter := Run('var a: integer;'#13#10'begin'#13#10'  a := kint;'#13#10'end.', TThreeConstants.Create);
  try
    Assert.AreEqual(2147483647, LInterpreter.IntegerOf(0));
  finally
    LInterpreter.Free;
  end;
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeDareErroreDiCompilazioneSeLaCostanteNonEstataAggiunta;
begin
  Assert.WillRaiseDescendant(
    procedure
    begin
      Run('var a: integer;'#13#10'begin'#13#10'  a := KMissing;'#13#10'end.', TThreeConstants.Create).Free;
    end, Exception);
end;

procedure TTestScriptHostConstantsCompiler.DovrebbeFarLeggereAUnoScriptTutteLeCostantiDellaFabbrica;
var
  LInterpreter: TTestInterpreter;
begin
  // a basic constant, a generalized one and the ones that the engine gives
  LInterpreter := Run('var a, b, c: integer;'#13#10'begin'#13#10'  a := DAMAGE_MASK;'#13#10'  b := MAXINT;'#13#10 +
    '  c := MOBJ_X + GAME_X + WORLD_X + GROUP_X;'#13#10'end.',
    TScriptHostFactory.CreateConstants(TFakeConstantProvider.Create(['MOBJ_X']),
      TFakeConstantProvider.Create(['GAME_X']), TFakeConstantProvider.Create(['WORLD_X']),
      TFakeConstantProvider.Create(['GROUP_X'])));
  try
    Assert.AreEqual(96, LInterpreter.IntegerOf(0));
    Assert.AreEqual(2147483647, LInterpreter.IntegerOf(1));
    Assert.AreEqual(0, LInterpreter.IntegerOf(2));
  finally
    LInterpreter.Free;
  end;
end;

end.
