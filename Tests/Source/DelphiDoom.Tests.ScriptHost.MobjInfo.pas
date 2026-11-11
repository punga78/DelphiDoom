{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mobjinfo functions of PS_GAME                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.MobjInfo;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.TypInfo,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.MobjInfo.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>Three mobj types: the number of a field is 1000 * type + the ordinal of the field, the text is "T<type>_<field>"</summary>
  TFakeMobjInfoSource = class(TInterfacedObject, IScriptMobjInfoSource)
  public
    /// <summary>The value that InheritsFrom has for type 2 (a negative one means "none")</summary>
    InheritsFromOfTypeTwo: Integer;
    constructor Create;
    function Count: Integer;
    function Number(const AType: Integer; const AField: TScriptMobjInfoField): Integer;
    function Text(const AType: Integer; const AField: TScriptMobjInfoField): string;
    function Flag(const AType: Integer; const AFlag: Integer): Boolean;
    function TypeFromEditorNumber(const ANumber: Integer): Integer;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostMobjInfo = class(TObject)
  strict private
    FSource: TFakeMobjInfoSource;
    FSourceRef: IScriptMobjInfoSource;
    FMobjInfo: IScriptMobjInfo;
    FTables: TList<IScriptFunctionTable>;
    FSections: TList<IScriptMobjInfo>;
    function DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeSettantaFunzioniDeiTipiDiDoomHereticEHexen;
    [Test]
    procedure DovrebbeDescrivereGetMobjInfoName2SoloInStrife;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeUsareUnaRigaDellaTabellaPerOgniCampo;
    [Test]
    procedure DovrebbeDareIlCampoGiustoPerOgniFunzioneDellaTabella;
    [Test]
    procedure DovrebbeDareIlValoreDeiNonValidiPerOgniFunzioneDellaTabella;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerGliStatiELeTipologie;
    [Test]
    procedure DovrebbeDareZeroPerIGruppiELeAltreMisure;
    [Test]
    procedure DovrebbeDareTestoVuotoPerUnTipoCheNonCe;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerUnaEreditarietaNegativa;
    [Test]
    procedure DovrebbeDireSeUnTipoEValidoEQuantiSono;
    [Test]
    procedure DovrebbeDareIlTipoDiUnNumeroDiEditor;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerUnNumeroDiEditorNegativoOSenzaTipo;
    [Test]
    procedure DovrebbeDareIlNumeroDiEditorDiUnTipo;
    [Test]
    procedure DovrebbeLeggereIFlagDiUnTipo;
    [Test]
    procedure DovrebbeDareFalsoAiFlagDiUnTipoCheNonCe;
    [Test]
    procedure DovrebbeTenereLoStessoOggettoPiuVolteDescrivendo;
    [Test]
    procedure DovrebbeDareErroreSeLaSorgenteEnil;
    [Test]
    procedure DovrebbeChiamareLeFunzioniDaUnoScriptVero;
  end;

implementation

uses
  ps_defs,
  ps_utils,
  ps_keywords,
  ps_compiler,
  ps_runtime,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.FunctionList,
  DelphiDoom.ScriptHost.MobjInfo.Table,
  DelphiDoom.ScriptHost.World.Intf;

type
  TNumberFunction = function(const AType: Integer): Integer of object;
  TTextFunction = function(const AType: Integer): string of object;
  TFlagFunction = function(const AType: Integer; const AFlag: Integer): Boolean of object;

var
  GUsedList: TScriptFunctionList;

function OnUsesMobjInfoList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
    GUsedList.RegisterCompiler(Sender);
end;

function NameOf(const ADeclaration: string): string;
var
  LStart: Integer;
  LEnd: Integer;
begin
  LStart := Pos(' ', ADeclaration) + 1;
  LEnd := Pos('(', ADeclaration);
  if LEnd = 0 then
    LEnd := Pos(':', ADeclaration);
  Result := Copy(ADeclaration, LStart, LEnd - LStart);
end;

{ TFakeMobjInfoSource }

constructor TFakeMobjInfoSource.Create;
begin
  inherited Create;
  InheritsFromOfTypeTwo := 1;
end;

function TFakeMobjInfoSource.Count: Integer;
begin
  Result := 3;
end;

function TFakeMobjInfoSource.Number(const AType: Integer; const AField: TScriptMobjInfoField): Integer;
begin
  if (AField = mifInheritsFrom) and (AType = 2) then
    Result := InheritsFromOfTypeTwo
  else
    Result := 1000 * AType + Ord(AField);
end;

function TFakeMobjInfoSource.Text(const AType: Integer; const AField: TScriptMobjInfoField): string;
begin
  Result := Format('T%d_%d', [AType, Ord(AField)]);
end;

function TFakeMobjInfoSource.Flag(const AType: Integer; const AFlag: Integer): Boolean;
begin
  Result := Odd(AType + AFlag);
end;

function TFakeMobjInfoSource.TypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  // 3001 is type 1, 3050 is a number that gives a type that does not exist
  Result := ANumber - 3000;
end;

{ TTestScriptHostMobjInfo }

procedure TTestScriptHostMobjInfo.Setup;
begin
  FSource := TFakeMobjInfoSource.Create;
  FSourceRef := FSource;
  FMobjInfo := TScriptHostFactory.CreateMobjInfo(FSourceRef, sgDoom);
  FTables := TList<IScriptFunctionTable>.Create;
  FSections := TList<IScriptMobjInfo>.Create;
end;

procedure TTestScriptHostMobjInfo.TearDown;
begin
  FSections.Free;
  FTables.Free;
  FMobjInfo := nil;
  FSourceRef := nil;
  FSource := nil;
end;

function TTestScriptHostMobjInfo.DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
  LSection: IScriptMobjInfo;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  // the objects that the table remembers as Self live as long as their section
  LSection := TScriptHostFactory.CreateMobjInfo(FSourceRef, AGame);
  FSections.Add(LSection);
  LSection.Describe(LRef);
end;

procedure TTestScriptHostMobjInfo.DovrebbeDescrivereLeSettantaFunzioniDeiTipiDiDoomHereticEHexen;
begin
  Assert.AreEqual(70, DescribeFor(sgDoom).Declarations.Count);
  Assert.AreEqual(70, DescribeFor(sgHeretic).Declarations.Count);
  Assert.AreEqual(70, DescribeFor(sgHexen).Declarations.Count);
end;

procedure TTestScriptHostMobjInfo.DovrebbeDescrivereGetMobjInfoName2SoloInStrife;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgStrife);
  Assert.AreEqual(71, LTable.Declarations.Count);
  Assert.AreEqual('function GetMobjInfoName2(const typ: integer): string;', LTable.Declarations[5]);
  Assert.AreEqual(-1, DescribeFor(sgDoom).Declarations.IndexOf(
    'function GetMobjInfoName2(const typ: integer): string;'));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDescrivereLeFunzioniNellOrdineDelVecchioCodice;
var
  LTable: TFakeFunctionTable;
  LFlag: Integer;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual('function IsValidMobjType(const typ: integer): boolean;', LTable.Declarations[0]);
  Assert.AreEqual('function GetMobjTypeFromEditorNumber(const en: integer): integer;', LTable.Declarations[1]);
  Assert.AreEqual('function GetEditorNumberFromMobjType(const typ: integer): integer;', LTable.Declarations[2]);
  Assert.AreEqual('function GetMobjInfoCount: integer;', LTable.Declarations[3]);
  Assert.AreEqual('function GetMobjInfoName(const typ: integer): string;', LTable.Declarations[4]);
  LFlag := LTable.Declarations.IndexOf('function GetMobjInfoFlag(const typ: Integer; const flg: integer): boolean;');
  Assert.IsTrue(LFlag > 0);
  Assert.AreEqual('function GetMobjInfoActiveSound(const typ: integer): string;', LTable.Declarations[LFlag - 1]);
  Assert.AreEqual('function GetMobjInfoRaiseState(const typ: integer): integer;', LTable.Declarations[LFlag + 1]);
  Assert.AreEqual('function GetMobjInfoSpriteDX(const dx: integer): integer;',
    LTable.Declarations[LTable.Declarations.IndexOf('function GetMobjInfoSpriteDX(const dx: integer): integer;')]);
  Assert.AreEqual('function GetMobjInfoMeleeThreshold(const typ: integer): integer;',
    LTable.Declarations[LTable.Declarations.Count - 1]);
end;

procedure TTestScriptHostMobjInfo.DovrebbeUsareUnaRigaDellaTabellaPerOgniCampo;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LName: string;
  LField: string;
begin
  LTable := DescribeFor(sgStrife);
  for LIndex := 4 to LTable.Declarations.Count - 1 do
  begin
    LName := NameOf(LTable.Declarations[LIndex]);
    if (LName = 'GetMobjInfoFlag') or (LName = 'GetMobjInfoName2') then
      Continue;
    // the field of the row has the name of the function: GetMobjInfoSpawnState reads mifSpawnState
    LField := 'mif' + Copy(LName, Length('GetMobjInfo') + 1, MaxInt);
    Assert.IsTrue(SameText(LField,
        string(GetEnumName(TypeInfo(TScriptMobjInfoField),
          Ord(SCRIPT_MOBJINFO_FUNCTIONS[LIndex - 4].Field)))),
      LName);
  end;
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlCampoGiustoPerOgniFunzioneDellaTabella;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LMethod: TMethod;
  LRow: TScriptMobjInfoFunction;
  LKind: TScriptMobjInfoKind;
  LChecked: Integer;
begin
  LTable := DescribeFor(sgStrife);
  LChecked := 0;
  for LIndex := 4 to LTable.Declarations.Count - 1 do
  begin
    LRow := SCRIPT_MOBJINFO_FUNCTIONS[LIndex - 4];
    if LRow.Shape = msFlag then
      Continue;
    LMethod.Code := LTable.Codes[LIndex];
    LMethod.Data := LTable.Instances[LIndex];
    LKind := SCRIPT_MOBJINFO_FIELDS[LRow.Field].Kind;
    if LKind in [mikText, mikSound] then
      Assert.AreEqual(Format('T1_%d', [Ord(LRow.Field)]), TTextFunction(LMethod)(1), LTable.Declarations[LIndex])
    else
      Assert.AreEqual(1000 + Ord(LRow.Field), TNumberFunction(LMethod)(1), LTable.Declarations[LIndex]);
    Inc(LChecked);
  end;
  Assert.AreEqual(66, LChecked);
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlValoreDeiNonValidiPerOgniFunzioneDellaTabella;
var
  LTable: TFakeFunctionTable;
  LIndex: Integer;
  LMethod: TMethod;
  LRow: TScriptMobjInfoFunction;
begin
  LTable := DescribeFor(sgStrife);
  for LIndex := 4 to LTable.Declarations.Count - 1 do
  begin
    LRow := SCRIPT_MOBJINFO_FUNCTIONS[LIndex - 4];
    if LRow.Shape = msFlag then
      Continue;
    LMethod.Code := LTable.Codes[LIndex];
    LMethod.Data := LTable.Instances[LIndex];
    if SCRIPT_MOBJINFO_FIELDS[LRow.Field].Kind in [mikText, mikSound] then
    begin
      Assert.AreEqual('', TTextFunction(LMethod)(3), LTable.Declarations[LIndex]);
      Assert.AreEqual('', TTextFunction(LMethod)(-1), LTable.Declarations[LIndex]);
    end
    else
    begin
      Assert.AreEqual(SCRIPT_MOBJINFO_FIELDS[LRow.Field].Invalid, TNumberFunction(LMethod)(3),
        LTable.Declarations[LIndex]);
      Assert.AreEqual(SCRIPT_MOBJINFO_FIELDS[LRow.Field].Invalid, TNumberFunction(LMethod)(-1),
        LTable.Declarations[LIndex]);
    end;
  end;
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlNumeroNonValidoPerGliStatiELeTipologie;
begin
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifSpawnState, 9));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifDeathState, -1));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifDropItem, 9));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifMissiletype, 9));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifInheritsFrom, 9));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifDoomEdNum, 9));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareZeroPerIGruppiELeAltreMisure;
begin
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifInfightingGroup, 9));
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifProjectileGroup, 9));
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifSplashGroup, 9));
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifRadius, 9));
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifSpeed, -3));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareTestoVuotoPerUnTipoCheNonCe;
begin
  Assert.AreEqual('', FMobjInfo.GetText(mifName, 3));
  Assert.AreEqual('', FMobjInfo.GetText(mifSeeSound, -1));
  Assert.AreEqual(Format('T1_%d', [Ord(mifObituary)]), FMobjInfo.GetText(mifObituary, 1));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlNumeroNonValidoPerUnaEreditarietaNegativa;
begin
  Assert.AreEqual(1000 + Ord(mifInheritsFrom), FMobjInfo.GetNumber(mifInheritsFrom, 1));
  FSource.InheritsFromOfTypeTwo := -1;
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetNumber(mifInheritsFrom, 2));
  FSource.InheritsFromOfTypeTwo := 0;
  Assert.AreEqual(0, FMobjInfo.GetNumber(mifInheritsFrom, 2));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDireSeUnTipoEValidoEQuantiSono;
begin
  Assert.IsTrue(FMobjInfo.IsValidMobjType(0));
  Assert.IsTrue(FMobjInfo.IsValidMobjType(2));
  Assert.IsFalse(FMobjInfo.IsValidMobjType(3));
  Assert.IsFalse(FMobjInfo.IsValidMobjType(-1));
  Assert.AreEqual(3, FMobjInfo.GetMobjInfoCount);
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlTipoDiUnNumeroDiEditor;
begin
  Assert.AreEqual(1, FMobjInfo.GetMobjTypeFromEditorNumber(3001));
  Assert.AreEqual(0, FMobjInfo.GetMobjTypeFromEditorNumber(3000));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlNumeroNonValidoPerUnNumeroDiEditorNegativoOSenzaTipo;
begin
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetMobjTypeFromEditorNumber(-1));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetMobjTypeFromEditorNumber(3050));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetMobjTypeFromEditorNumber(5));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareIlNumeroDiEditorDiUnTipo;
begin
  Assert.AreEqual(1000 + Ord(mifDoomEdNum), FMobjInfo.GetEditorNumberFromMobjType(1));
  Assert.AreEqual(SCRIPT_INVALID_ID, FMobjInfo.GetEditorNumberFromMobjType(3));
end;

procedure TTestScriptHostMobjInfo.DovrebbeLeggereIFlagDiUnTipo;
begin
  Assert.IsTrue(FMobjInfo.GetMobjInfoFlag(1, 2));
  Assert.IsFalse(FMobjInfo.GetMobjInfoFlag(1, 1));
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareFalsoAiFlagDiUnTipoCheNonCe;
begin
  // the fake would answer true for type 5 and flag 2 if it were asked
  Assert.IsFalse(FMobjInfo.GetMobjInfoFlag(5, 2));
  Assert.IsFalse(FMobjInfo.GetMobjInfoFlag(-1, 0));
end;

procedure TTestScriptHostMobjInfo.DovrebbeTenereLoStessoOggettoPiuVolteDescrivendo;
var
  LFirst: TFakeFunctionTable;
  LSecond: TFakeFunctionTable;
  LFirstRef: IScriptFunctionTable;
  LSecondRef: IScriptFunctionTable;
  LSection: IScriptMobjInfo;
begin
  LSection := TScriptHostFactory.CreateMobjInfo(FSourceRef, sgStrife);
  LFirst := TFakeFunctionTable.Create;
  LFirstRef := LFirst;
  LSection.Describe(LFirstRef);
  LSecond := TFakeFunctionTable.Create;
  LSecondRef := LSecond;
  LSection.Describe(LSecondRef);
  Assert.AreEqual(LFirst.Declarations.Count, LSecond.Declarations.Count);
  Assert.AreSame(LFirst.Instances[4], LSecond.Instances[4]);
  // GetMobjInfoName2 shares the object of GetMobjInfoName
  Assert.AreSame(LFirst.Instances[4], LFirst.Instances[5]);
  Assert.AreNotSame(LFirst.Instances[4], LFirst.Instances[6]);
end;

procedure TTestScriptHostMobjInfo.DovrebbeDareErroreSeLaSorgenteEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateMobjInfo(nil, sgDoom);
    end,
    EArgumentNilException);
end;

procedure TTestScriptHostMobjInfo.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var n, sp, ed, ss, fl: Integer; nm, snd: string; b: Boolean;'#13#10 +
    'begin'#13#10 +
    '  n := GetMobjInfoCount;'#13#10 +
    '  sp := GetMobjInfoSpeed(2);'#13#10 +
    '  ed := GetMobjTypeFromEditorNumber(3001);'#13#10 +
    '  ss := GetMobjInfoSpawnState(7);'#13#10 +
    '  nm := GetMobjInfoName(1);'#13#10 +
    '  snd := GetMobjInfoSeeSound(1);'#13#10 +
    '  b := GetMobjInfoFlag(1, 2);'#13#10 +
    'end.';
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;

  function IntegerAt(const AIndex: Integer): Integer;
  var
    LVariable: PIFVariant;
  begin
    LVariable := LExec.GetVarNo(AIndex);
    Result := PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType);
  end;

  function StringAt(const AIndex: Integer): string;
  var
    LVariable: PIFVariant;
  begin
    LVariable := LExec.GetVarNo(AIndex);
    Result := string(PSGetString(@PPSVariantData(LVariable).Data, LVariable.FType));
  end;

begin
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  FMobjInfo.Describe(LListRef);
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  LExec := TPSExec.Create;
  try
    GUsedList := LList;
    LCompiler.OnUses := OnUsesMobjInfoList;
    Assert.IsTrue(LCompiler.Compile(TbtString(SCRIPT_TEXT)), 'compile');
    LCompiler.GetOutput(LBytes);
    LList.RegisterExecutor(LExec);
    Assert.IsTrue(LExec.LoadData(LBytes), 'load');
    Assert.IsTrue(LExec.RunScript, 'run');
    Assert.AreEqual(3, IntegerAt(0));
    Assert.AreEqual(2000 + Ord(mifSpeed), IntegerAt(1));
    Assert.AreEqual(1, IntegerAt(2));
    Assert.AreEqual(SCRIPT_INVALID_ID, IntegerAt(3));
    Assert.AreEqual(Format('T1_%d', [Ord(mifName)]), StringAt(5));
    Assert.AreEqual(Format('T1_%d', [Ord(mifSeeSound)]), StringAt(6));
  finally
    LExec.Free;
    LCompiler.Free;
    LListRef := nil;
    LList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostMobjInfo);

end.
