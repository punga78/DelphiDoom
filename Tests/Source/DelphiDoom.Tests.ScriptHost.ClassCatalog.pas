{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the catalog of the classes that scripts see            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ClassCatalog;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  ps_runtime,
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Interpreter;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostClassCatalog = class(TObject)
  private
    FCatalog: IScriptClassCatalog;
    FImporter: TPSRuntimeClassImporter;
    FInterpreter: TTestInterpreter;
    /// <summary>The catalog with the fake classes, for a game</summary>
    procedure Describe(const AGame: TScriptGame);
    /// <summary>Compiles and runs a script that has the fake classes (and RecordValue, to give the results out)</summary>
    procedure Run(const ASource: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlGiocoDelCatalogo;
    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeDareErroreSeIlNomeDellaClasseEVuoto;
    [Test]
    procedure DovrebbeDareErroreSeLaClasseDelloScriptEnil;
    [Test]
    procedure DovrebbeDareErroreSeLaClasseEGiaNelCatalogoAnchePerLeMaiuscole;
    [Test]
    procedure DovrebbeTenereLeClassiNellOrdineDato;
    [Test]
    procedure DovrebbeTrovareUnaClasseSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareNilPerUnaClasseCheNonCe;
    [Test]
    procedure DovrebbeDareLeProprietaDelCompilatoreInOrdine;
    [Test]
    procedure DovrebbeDareLaProprietaDiStrifeSoloInStrife;
    [Test]
    procedure DovrebbeDareLaProprietaSoloDelRuntimeSoloAlRuntime;
    [Test]
    procedure DovrebbeDareLaProprietaDelCompilatoreInTuttiIGiochiAncheSeIlRuntimeLaDaSoloInStrife;
    [Test]
    procedure DovrebbeLeggereEScrivereUnaProprietaDaUnoScript;
    [Test]
    procedure DovrebbeLeggereUnaProprietaDiSolaLettura;
    [Test]
    procedure DovrebbeChiamareUnMetodo;
    [Test]
    procedure DovrebbeRegistrareIlCostruttoreSenzaErroriNelCompilatoreENelRuntime;
    [Test]
    procedure DovrebbeUsareLaProprietaPredefinitaConUnIndice;
    [Test]
    procedure DovrebbeLegareLaVariabileAllOggettoDelProvider;
    [Test]
    procedure DovrebbeChiedereLOggettoAlProviderSoloQuandoLoScriptECaricato;
    [Test]
    procedure DovrebbeDareErroreDiCompilazioneSeLaProprietaEDiUnAltroGioco;
    [Test]
    procedure DovrebbeCompilareLaProprietaNelGioco;
    [Test]
    procedure DovrebbeDareErroreDiCompilazioneSeLaProprietaEDelSoloRuntime;
    [Test]
    procedure DovrebbeUsareLaClasseDelCompilatoreSenzaLeClassiDelRuntimeDeiAltriGiochi;
  end;

implementation

uses
  System.Classes,
  ps_defs,
  ps_compiler,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>The class that the fake catalog describes: its members are the helpers below</summary>
  TFakeThing = class(TObject)
  public
    Value: Integer;
    constructor Create;
    function Twice(const ANumber: Integer): Integer;
  end;

  TFakeList = class(TObject)
  end;

constructor TFakeThing.Create;
begin
  inherited Create;
  Value := 0;
end;

function TFakeThing.Twice(const ANumber: Integer): Integer;
begin
  Result := ANumber * 2 + Value;
end;

procedure FakeThingValue_R(Self: TFakeThing; var T: Integer);
begin
  T := Self.Value;
end;

procedure FakeThingValue_W(Self: TFakeThing; const T: Integer);
begin
  Self.Value := T;
end;

procedure FakeThingFixed_R(Self: TFakeThing; var T: Integer);
begin
  T := 1000;
end;

procedure FakeThingStrife_R(Self: TFakeThing; var T: Integer);
begin
  T := 666;
end;

procedure FakeThingHidden_R(Self: TFakeThing; var T: Integer);
begin
  T := 5;
end;

procedure FakeListItem_R(Self: TFakeList; var T: Integer; const AIndex: Integer);
begin
  T := AIndex * 10;
end;

var
  // the OnUses of the compiler is a plain function: it reaches the catalog of the running test
  GCatalog: IScriptClassCatalog = nil;
  // the object that the variable Thing is bound to, and how many times it was asked
  GThing: TFakeThing = nil;
  GList: TFakeList = nil;
  GProviderCalls: Integer = 0;

function CatalogOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    // the class that every other class descends from, as ps_import adds it
    Sender.AddClassN(nil, '!TOBJECT');
    GCatalog.RegisterCompiler(Sender);
    Sender.AddDelphiFunction('procedure RecordValue(const AValue: Integer);');
  end;
end;

procedure TTestScriptHostClassCatalog.Describe(const AGame: TScriptGame);
var
  LThing: IScriptClassDescriptor;
  LList: IScriptClassDescriptor;
begin
  FCatalog := TScriptHostFactory.CreateClassCatalog(AGame);
  LThing := FCatalog.AddClass('!TFakeThing', TFakeThing);
  LThing.AddConstructor(@TFakeThing.Create);
  LThing.AddProperty('Value', 'Integer', iptRW, @FakeThingValue_R, @FakeThingValue_W);
  LThing.AddProperty('Fixed', 'Integer', iptR, @FakeThingFixed_R, nil);
  LThing.AddProperty('Strife', 'Integer', iptR, @FakeThingStrife_R, nil, [sgStrife]);
  LThing.AddProperty('Both', 'Integer', iptR, @FakeThingStrife_R, nil, SCRIPT_ALL_GAMES, [sgStrife]);
  LThing.AddRuntimeProperty('Hidden', @FakeThingHidden_R, nil);
  LThing.AddMethod('function Twice(const ANumber: Integer): Integer;', 'Twice', @TFakeThing.Twice);
  LThing.AddVariable('Thing',
    function: TObject
    begin
      Inc(GProviderCalls);
      Result := GThing;
    end);
  LList := FCatalog.AddClass('!TFakeList', TFakeList);
  LList.AddProperty('Item', 'Integer Integer', iptR, @FakeListItem_R, nil);
  LList.AddDefaultProperty('Item');
  LList.AddVariable('List',
    function: TObject
    begin
      Result := GList;
    end);
end;

procedure TTestScriptHostClassCatalog.Run(const ASource: string);
begin
  GCatalog := FCatalog;
  try
    FInterpreter := TTestInterpreter.Create(ASource, True, CatalogOnUses,
      procedure(AExec: TPSExec)
      begin
        FImporter := TPSRuntimeClassImporter.Create;
        FImporter.Add2(TObject, '!TOBJECT').RegisterConstructor(@TObject.Create, 'Create');
        FCatalog.RegisterRuntime(FImporter);
        RegisterClassLibraryRuntime(AExec, FImporter);
        AExec.RegisterDelphiFunction(@RecordValue, 'RECORDVALUE', cdRegister);
      end,
      procedure(AExec: TPSExec)
      begin
        FCatalog.BindVariables(AExec);
      end);
  finally
    GCatalog := nil;
  end;
end;

procedure TTestScriptHostClassCatalog.Setup;
begin
  GThing := TFakeThing.Create;
  GList := TFakeList.Create;
  GProviderCalls := 0;
  GRecordedValue := 0;
  Describe(sgDoom);
end;

procedure TTestScriptHostClassCatalog.TearDown;
begin
  FreeAndNil(FInterpreter);
  FreeAndNil(FImporter);
  FCatalog := nil;
  FreeAndNil(GThing);
  FreeAndNil(GList);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareIlGiocoDelCatalogo;
begin
  Assert.AreEqual(Ord(sgDoom), Ord(FCatalog.Game));
  Assert.AreEqual(Ord(sgHexen), Ord(TScriptHostFactory.CreateClassCatalog(sgHexen).Game));
end;

procedure TTestScriptHostClassCatalog.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, TScriptHostFactory.CreateClassCatalog(sgDoom).Count);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareErroreSeIlNomeDellaClasseEVuoto;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.AddClass('', TFakeThing);
    end, EScriptHostException);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareErroreSeLaClasseDelloScriptEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.AddClass('!TOther', nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareErroreSeLaClasseEGiaNelCatalogoAnchePerLeMaiuscole;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.AddClass('!TFAKETHING', TFakeThing);
    end, EScriptHostException);
end;

procedure TTestScriptHostClassCatalog.DovrebbeTenereLeClassiNellOrdineDato;
begin
  Assert.AreEqual(2, FCatalog.Count);
  Assert.AreEqual('!TFakeThing', FCatalog.ClassAt(0).ScriptName);
  Assert.AreEqual('!TFakeList', FCatalog.ClassAt(1).ScriptName);
end;

procedure TTestScriptHostClassCatalog.DovrebbeTrovareUnaClasseSenzaDistinguereLeMaiuscole;
begin
  Assert.IsNotNull(FCatalog.FindClass('!tfakelist'));
  Assert.AreEqual('!TFakeList', FCatalog.FindClass('!tfakelist').ScriptName);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareNilPerUnaClasseCheNonCe;
begin
  Assert.IsNull(FCatalog.FindClass('!TNothing'));
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareLeProprietaDelCompilatoreInOrdine;
begin
  Assert.AreEqual('Value,Fixed,Both', string.Join(',', FCatalog.FindClass('!TFakeThing').CompilerProperties(sgDoom)));
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareLaProprietaDiStrifeSoloInStrife;
begin
  Assert.AreEqual('Value,Fixed,Strife,Both',
    string.Join(',', FCatalog.FindClass('!TFakeThing').CompilerProperties(sgStrife)));
  Assert.AreEqual('Value,Fixed,Both', string.Join(',', FCatalog.FindClass('!TFakeThing').CompilerProperties(sgHeretic)));
  Assert.AreEqual('Value,Fixed,Both', string.Join(',', FCatalog.FindClass('!TFakeThing').CompilerProperties(sgHexen)));
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareLaProprietaSoloDelRuntimeSoloAlRuntime;
begin
  Assert.AreEqual('Value,Fixed,Hidden', string.Join(',', FCatalog.FindClass('!TFakeThing').RuntimeProperties(sgDoom)));
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareLaProprietaDelCompilatoreInTuttiIGiochiAncheSeIlRuntimeLaDaSoloInStrife;
begin
  // the compiler knows Both in all the games; the interpreter has it in Strife only (as Name2 of MobjInfo)
  Assert.AreEqual('Value,Fixed,Hidden', string.Join(',', FCatalog.FindClass('!TFakeThing').RuntimeProperties(sgHexen)));
  Assert.AreEqual('Value,Fixed,Strife,Both,Hidden',
    string.Join(',', FCatalog.FindClass('!TFakeThing').RuntimeProperties(sgStrife)));
end;

procedure TTestScriptHostClassCatalog.DovrebbeLeggereEScrivereUnaProprietaDaUnoScript;
begin
  Run('begin'#13#10'  Thing.Value := 7;'#13#10'  Thing.Value := Thing.Value + 3;'#13#10'  RecordValue(Thing.Value);'#13#10'end.');
  Assert.AreEqual(10, GRecordedValue);
  Assert.AreEqual(10, GThing.Value);
end;

procedure TTestScriptHostClassCatalog.DovrebbeLeggereUnaProprietaDiSolaLettura;
begin
  Run('begin'#13#10'  RecordValue(Thing.Fixed);'#13#10'end.');
  Assert.AreEqual(1000, GRecordedValue);
end;

procedure TTestScriptHostClassCatalog.DovrebbeChiamareUnMetodo;
begin
  GThing.Value := 5;
  Run('begin'#13#10'  RecordValue(Thing.Twice(21));'#13#10'end.');
  Assert.AreEqual(47, GRecordedValue);
end;

procedure TTestScriptHostClassCatalog.DovrebbeRegistrareIlCostruttoreSenzaErroriNelCompilatoreENelRuntime;
begin
  // the name of the class begins with ! : a script cannot write it, the constructor is for the classes that it can reach
  Run('begin'#13#10'  RecordValue(Thing.Value + 1);'#13#10'end.');
  Assert.AreEqual(1, GRecordedValue);
end;

procedure TTestScriptHostClassCatalog.DovrebbeUsareLaProprietaPredefinitaConUnIndice;
begin
  Run('begin'#13#10'  RecordValue(List[7]);'#13#10'end.');
  Assert.AreEqual(70, GRecordedValue);
end;

procedure TTestScriptHostClassCatalog.DovrebbeLegareLaVariabileAllOggettoDelProvider;
begin
  GThing.Value := 41;
  Run('begin'#13#10'  Thing.Value := Thing.Value + 1;'#13#10'end.');
  // the variable is the object that the provider gave, not a copy
  Assert.AreEqual(42, GThing.Value);
end;

procedure TTestScriptHostClassCatalog.DovrebbeChiedereLOggettoAlProviderSoloQuandoLoScriptECaricato;
begin
  Assert.AreEqual(0, GProviderCalls, 'asked while describing');
  Run('begin'#13#10'end.');
  Assert.AreEqual(1, GProviderCalls);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareErroreDiCompilazioneSeLaProprietaEDiUnAltroGioco;
begin
  Assert.WillRaiseDescendant(
    procedure
    begin
      Run('begin'#13#10'  RecordValue(Thing.Strife);'#13#10'end.');
    end, Exception);
end;

procedure TTestScriptHostClassCatalog.DovrebbeCompilareLaProprietaNelGioco;
begin
  Describe(sgStrife);
  Run('begin'#13#10'  RecordValue(Thing.Strife);'#13#10'end.');
  Assert.AreEqual(666, GRecordedValue);
end;

procedure TTestScriptHostClassCatalog.DovrebbeDareErroreDiCompilazioneSeLaProprietaEDelSoloRuntime;
begin
  Assert.WillRaiseDescendant(
    procedure
    begin
      Run('begin'#13#10'  RecordValue(Thing.Hidden);'#13#10'end.');
    end, Exception);
end;

procedure TTestScriptHostClassCatalog.DovrebbeUsareLaClasseDelCompilatoreSenzaLeClassiDelRuntimeDeiAltriGiochi;
begin
  // Both: the compiler has it in Doom, the interpreter has not: the script compiles and the interpreter
  // does not find the property (the old registration of Name2 of MobjInfo, kept as it was)
  Assert.WillRaiseDescendant(
    procedure
    begin
      Run('begin'#13#10'  RecordValue(Thing.Both);'#13#10'end.');
    end, Exception);
end;

end.
