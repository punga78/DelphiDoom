{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the vertex, side and line functions of PS_GAME         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.World;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.World.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes;

type
  /// <summary>A level of the test: 3 vertexes, 3 sides, 4 lines, with what the old code read from the arrays</summary>
  TFakeWorld = class(TInterfacedObject, IScriptWorld)
  public
    Vertexes: array[0..2] of record X, Y: Integer; end;
    SideOffsets: array[0..2, TScriptSideOffset] of Integer;
    SideTextures: array[0..2, TScriptSidePart] of string;
    SideSectors: array[0..2] of Integer;
    LineVertexes: array[0..3, Boolean] of Integer;
    LineDeltas: array[0..3, 0..1] of Integer;
    LineSpecials: array[0..3] of Integer;
    LineArguments: array[0..3, 0..4] of Integer;
    LineTags: array[0..3] of Integer;
    LineFlags: array[0..3, TScriptLineFlag] of Boolean;
    LineSides: array[0..3, Boolean] of Integer;
    LineSectors: array[0..3, Boolean] of Integer;
    /// <summary>Every write that reached the world, as text</summary>
    Writes: string;
    constructor Create;
    function VertexCount: Integer;
    function VertexX(const AIndex: Integer): Integer;
    function VertexY(const AIndex: Integer): Integer;
    function SideCount: Integer;
    function SideOffset(const AIndex: Integer; const AKind: TScriptSideOffset): Integer;
    procedure SetSideOffset(const AIndex: Integer; const AKind: TScriptSideOffset; const AValue: Integer);
    function SideTexture(const AIndex: Integer; const APart: TScriptSidePart): string;
    procedure SetSideTexture(const AIndex: Integer; const APart: TScriptSidePart; const AName: string);
    function SideSectorId(const AIndex: Integer): Integer;
    function LineCount: Integer;
    function LineVertex(const AIndex: Integer; const ASecond: Boolean): Integer;
    function LineDeltaX(const AIndex: Integer): Integer;
    function LineDeltaY(const AIndex: Integer): Integer;
    function LineSpecial(const AIndex: Integer): Integer;
    procedure SetLineSpecial(const AIndex: Integer; const AValue: Integer);
    function LineArgument(const AIndex: Integer; const AArgument: Integer): Integer;
    procedure SetLineArgument(const AIndex: Integer; const AArgument: Integer; const AValue: Byte);
    function LineTag(const AIndex: Integer): Integer;
    procedure SetLineTag(const AIndex: Integer; const AValue: Integer);
    function LineHasFlag(const AIndex: Integer; const AFlag: TScriptLineFlag): Boolean;
    procedure SetLineFlag(const AIndex: Integer; const AFlag: TScriptLineFlag; const AValue: Boolean);
    function LineSideNumber(const AIndex: Integer; const ASecond: Boolean): Integer;
    function LineSectorId(const AIndex: Integer; const ASecond: Boolean): Integer;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostWorld = class(TObject)
  strict private
    FWorld: TFakeWorld;
    FWorldRef: IScriptWorld;
    FTables: TList<IScriptFunctionTable>;
    FSections: TList<IScriptFunctionSection>;
    function Describe(const ASection: IScriptFunctionSection): TFakeFunctionTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeCinqueFunzioniDeiVertici;
    [Test]
    procedure DovrebbeDareLaManigliaDiUnVerticeValido;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerUnVerticeCheNonCe;
    [Test]
    procedure DovrebbeLeggereLeCoordinateDiUnVertice;
    [Test]
    procedure DovrebbeDareZeroPerLeCoordinateDiUnVerticeCheNonCe;
    [Test]
    procedure DovrebbeDireSeUnVerticeEValidoEQuantiSono;
    [Test]
    procedure DovrebbeDareErroreSeIlMondoDeiVerticiEnil;
    [Test]
    procedure DovrebbeDescrivereLeVentiseiFunzioniDeiLati;
    [Test]
    procedure DovrebbeLeggereEScrivereOgniScostamentoDiUnLato;
    [Test]
    procedure DovrebbeConservareIlDifettoDelloScostamentoMedioDelleRighe;
    [Test]
    procedure DovrebbeNonScrivereLoScostamentoDiUnLatoCheNonCe;
    [Test]
    procedure DovrebbeDareZeroPerLoScostamentoDiUnLatoCheNonCe;
    [Test]
    procedure DovrebbeLeggereEScrivereLeTextureDiUnLato;
    [Test]
    procedure DovrebbeDareLaTextureVuotaPerUnLatoCheNonCe;
    [Test]
    procedure DovrebbeDareIlSettoreDiUnLatoOIlNumeroNonValido;
    [Test]
    procedure DovrebbeDareLaManigliaDiUnLatoValido;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDelleLineeDiDoom;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDelleLineeDiHexenSenzaTagETrasparenza;
    [Test]
    procedure DovrebbeDescrivereLeLineeNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLaManigliaDiUnaLineaValida;
    [Test]
    procedure DovrebbeLeggereIVerticiLeDifferenzeEIlSpecialDiUnaLinea;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerIVerticiDiUnaLineaCheNonCe;
    [Test]
    procedure DovrebbeScrivereLoSpecialDiUnaLinea;
    [Test]
    procedure DovrebbeLeggereEScrivereOgniArgomentoDiUnaLinea;
    [Test]
    procedure DovrebbeDareIlByteBassoDiUnArgomentoPiuGrande;
    [Test]
    procedure DovrebbeLeggereEScrivereIlTagDiUnaLinea;
    [Test]
    procedure DovrebbeCambiareIFlagDiUnaLineaSoloSeHaDueLati;
    [Test]
    procedure DovrebbeCambiareIlFlagDegliScriptAncheSenzaDueLati;
    [Test]
    procedure DovrebbeLeggereIFlagDiUnaLineaAnchePerUnaSenzaDueLati;
    [Test]
    procedure DovrebbeDareFalsoAiFlagDiUnaLineaCheNonCe;
    [Test]
    procedure DovrebbeDareILatiEISettoriDiUnaLinea;
    [Test]
    procedure DovrebbeTrovareLeLineeConUnTag;
    [Test]
    procedure DovrebbeNonModificareNullaConUnaLineaCheNonCe;
    [Test]
    procedure DovrebbeDareErroreSeIlMondoDelleLineeEnil;
    [Test]
    procedure DovrebbeChiamareLeFunzioniDaUnoScriptVero;
    [Test]
    procedure DovrebbeUsareLoStessoMetodoPerOgniGiocoDelleLinee;
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
  DelphiDoom.ScriptHost.World.Lines,
  DelphiDoom.ScriptHost.World.Sides,
  DelphiDoom.ScriptHost.World.Vertices;

type
  /// <summary>Passes on to a real list what a script can compile (the functions that give a class of the scripts are left out)</summary>
  TWithoutClassResults = class(TInterfacedObject, IScriptFunctionTable)
  strict private
    FList: IScriptFunctionTable;
  public
    constructor Create(const AList: IScriptFunctionTable);
    procedure Add(const ADeclaration: string; const ACode: Pointer);
    procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const ACode: Pointer);
    procedure AddMethod(const ADeclaration: string; const AInstance: TObject; const ACode: Pointer);
    procedure AddMethodWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const AInstance: TObject; const ACode: Pointer);
  end;

var
  GUsedList: TScriptFunctionList;

function OnUsesWorldList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    Sender.AddTypeS('fixed_t', 'Integer');
    Sender.AddTypeS('TIntegerArray', 'array of Integer');
    GUsedList.RegisterCompiler(Sender);
  end;
end;

{ TWithoutClassResults }

constructor TWithoutClassResults.Create(const AList: IScriptFunctionTable);
begin
  inherited Create;
  FList := AList;
end;

procedure TWithoutClassResults.Add(const ADeclaration: string; const ACode: Pointer);
begin
  FList.Add(ADeclaration, ACode);
end;

procedure TWithoutClassResults.AddWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const ACode: Pointer);
begin
end;

procedure TWithoutClassResults.AddMethod(const ADeclaration: string; const AInstance: TObject;
  const ACode: Pointer);
begin
  FList.AddMethod(ADeclaration, AInstance, ACode);
end;

procedure TWithoutClassResults.AddMethodWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const AInstance: TObject; const ACode: Pointer);
begin
end;

{ TFakeWorld }

constructor TFakeWorld.Create;
var
  LIndex: Integer;
  LKind: TScriptSideOffset;
  LPart: TScriptSidePart;
  LArgument: Integer;
begin
  inherited Create;
  for LIndex := 0 to 2 do
  begin
    Vertexes[LIndex].X := 100 * (LIndex + 1);
    Vertexes[LIndex].Y := -10 * (LIndex + 1);
    for LKind := Low(TScriptSideOffset) to High(TScriptSideOffset) do
      SideOffsets[LIndex, LKind] := 1000 * (LIndex + 1) + Ord(LKind);
    for LPart := Low(TScriptSidePart) to High(TScriptSidePart) do
      SideTextures[LIndex, LPart] := Format('tex%d%d', [LIndex, Ord(LPart)]);
    SideSectors[LIndex] := 7 + LIndex;
  end;
  for LIndex := 0 to 3 do
  begin
    LineVertexes[LIndex, False] := LIndex;
    LineVertexes[LIndex, True] := LIndex + 10;
    LineDeltas[LIndex, 0] := 64 * LIndex;
    LineDeltas[LIndex, 1] := -64 * LIndex;
    LineSpecials[LIndex] := 100 + LIndex;
    for LArgument := 0 to 4 do
      LineArguments[LIndex, LArgument] := 10 * LIndex + LArgument;
    LineTags[LIndex] := 5;
    LineSides[LIndex, False] := LIndex mod 3;
    LineSides[LIndex, True] := (LIndex + 1) mod 3;
    LineSectors[LIndex, False] := 20 + LIndex;
    LineSectors[LIndex, True] := 30 + LIndex;
  end;
  // line 3: one sided, no back sector; line 2: a side that is not there
  LineSides[3, True] := -1;
  LineSectors[3, True] := SCRIPT_WORLD_NO_SECTOR;
  LineSides[2, True] := 99;
  LineTags[1] := 6;
  LineTags[3] := 5;
end;

function TFakeWorld.VertexCount: Integer;
begin
  Result := 3;
end;

function TFakeWorld.VertexX(const AIndex: Integer): Integer;
begin
  Result := Vertexes[AIndex].X;
end;

function TFakeWorld.VertexY(const AIndex: Integer): Integer;
begin
  Result := Vertexes[AIndex].Y;
end;

function TFakeWorld.SideCount: Integer;
begin
  Result := 3;
end;

function TFakeWorld.SideOffset(const AIndex: Integer; const AKind: TScriptSideOffset): Integer;
begin
  Result := SideOffsets[AIndex, AKind];
end;

procedure TFakeWorld.SetSideOffset(const AIndex: Integer; const AKind: TScriptSideOffset;
  const AValue: Integer);
begin
  SideOffsets[AIndex, AKind] := AValue;
  Writes := Writes + Format('O(%d,%d,%d)', [AIndex, Ord(AKind), AValue]);
end;

function TFakeWorld.SideTexture(const AIndex: Integer; const APart: TScriptSidePart): string;
begin
  Result := SideTextures[AIndex, APart];
end;

procedure TFakeWorld.SetSideTexture(const AIndex: Integer; const APart: TScriptSidePart;
  const AName: string);
begin
  SideTextures[AIndex, APart] := AName;
  Writes := Writes + Format('T(%d,%d,%s)', [AIndex, Ord(APart), AName]);
end;

function TFakeWorld.SideSectorId(const AIndex: Integer): Integer;
begin
  Result := SideSectors[AIndex];
end;

function TFakeWorld.LineCount: Integer;
begin
  Result := 4;
end;

function TFakeWorld.LineVertex(const AIndex: Integer; const ASecond: Boolean): Integer;
begin
  Result := LineVertexes[AIndex, ASecond];
end;

function TFakeWorld.LineDeltaX(const AIndex: Integer): Integer;
begin
  Result := LineDeltas[AIndex, 0];
end;

function TFakeWorld.LineDeltaY(const AIndex: Integer): Integer;
begin
  Result := LineDeltas[AIndex, 1];
end;

function TFakeWorld.LineSpecial(const AIndex: Integer): Integer;
begin
  Result := LineSpecials[AIndex];
end;

procedure TFakeWorld.SetLineSpecial(const AIndex: Integer; const AValue: Integer);
begin
  LineSpecials[AIndex] := AValue;
  Writes := Writes + Format('S(%d,%d)', [AIndex, AValue]);
end;

function TFakeWorld.LineArgument(const AIndex: Integer; const AArgument: Integer): Integer;
begin
  Result := LineArguments[AIndex, AArgument];
end;

procedure TFakeWorld.SetLineArgument(const AIndex: Integer; const AArgument: Integer;
  const AValue: Byte);
begin
  LineArguments[AIndex, AArgument] := AValue;
  Writes := Writes + Format('A(%d,%d,%d)', [AIndex, AArgument, AValue]);
end;

function TFakeWorld.LineTag(const AIndex: Integer): Integer;
begin
  Result := LineTags[AIndex];
end;

procedure TFakeWorld.SetLineTag(const AIndex: Integer; const AValue: Integer);
begin
  LineTags[AIndex] := AValue;
  Writes := Writes + Format('G(%d,%d)', [AIndex, AValue]);
end;

function TFakeWorld.LineHasFlag(const AIndex: Integer; const AFlag: TScriptLineFlag): Boolean;
begin
  Result := LineFlags[AIndex, AFlag];
end;

procedure TFakeWorld.SetLineFlag(const AIndex: Integer; const AFlag: TScriptLineFlag;
  const AValue: Boolean);
begin
  LineFlags[AIndex, AFlag] := AValue;
  Writes := Writes + Format('F(%d,%d,%s)', [AIndex, Ord(AFlag), BoolToStr(AValue, True)]);
end;

function TFakeWorld.LineSideNumber(const AIndex: Integer; const ASecond: Boolean): Integer;
begin
  Result := LineSides[AIndex, ASecond];
end;

function TFakeWorld.LineSectorId(const AIndex: Integer; const ASecond: Boolean): Integer;
begin
  Result := LineSectors[AIndex, ASecond];
end;

{ TTestScriptHostWorld }

procedure TTestScriptHostWorld.Setup;
begin
  FWorld := TFakeWorld.Create;
  FWorldRef := FWorld;
  FTables := TList<IScriptFunctionTable>.Create;
  FSections := TList<IScriptFunctionSection>.Create;
end;

procedure TTestScriptHostWorld.TearDown;
begin
  // the objects that the interpreter calls live as long as their section
  FTables.Free;
  FSections.Free;
  FWorldRef := nil;
  FWorld := nil;
end;

function TTestScriptHostWorld.Describe(const ASection: IScriptFunctionSection): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  FSections.Add(ASection);
  ASection.Describe(LRef);
end;

procedure TTestScriptHostWorld.DovrebbeDescrivereLeCinqueFunzioniDeiVertici;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateVertices(FWorldRef));
  Assert.AreEqual(5, LTable.Declarations.Count);
  Assert.AreEqual('procedure TVertex(const id: Integer);', LTable.Declarations[0]);
  Assert.AreEqual('!TVertex', LTable.ResultTypes[0]);
  Assert.AreEqual('function TVertex(const id: Integer): !TVertex;', LTable.ExportDeclarations[0]);
  Assert.IsNotNull(LTable.Instances[0]);
  Assert.AreEqual('function GetVertexX(const v: integer): fixed_t;', LTable.Declarations[1]);
  Assert.AreEqual('function GetVertexY(const v: integer): fixed_t;', LTable.Declarations[2]);
  Assert.AreEqual('function IsValidVertex(const v: Integer): boolean;', LTable.Declarations[3]);
  Assert.AreEqual('function GetVertexCount: Integer;', LTable.Declarations[4]);
end;

procedure TTestScriptHostWorld.DovrebbeDareLaManigliaDiUnVerticeValido;
var
  LVertices: IScriptVertices;
begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  Assert.AreEqual(1, LVertices.TVertex(0));
  Assert.AreEqual(3, LVertices.TVertex(2));
end;

procedure TTestScriptHostWorld.DovrebbeDareIlNumeroNonValidoPerUnVerticeCheNonCe;
var
  LVertices: IScriptVertices;
begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  Assert.AreEqual(SCRIPT_INVALID_ID, LVertices.TVertex(3));
  Assert.AreEqual(SCRIPT_INVALID_ID, LVertices.TVertex(-1));
end;

procedure TTestScriptHostWorld.DovrebbeLeggereLeCoordinateDiUnVertice;
var
  LVertices: IScriptVertices;
begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  Assert.AreEqual(200, LVertices.GetVertexX(1));
  Assert.AreEqual(-30, LVertices.GetVertexY(2));
end;

procedure TTestScriptHostWorld.DovrebbeDareZeroPerLeCoordinateDiUnVerticeCheNonCe;
var
  LVertices: IScriptVertices;
begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  Assert.AreEqual(0, LVertices.GetVertexX(3));
  Assert.AreEqual(0, LVertices.GetVertexY(-1));
end;

procedure TTestScriptHostWorld.DovrebbeDireSeUnVerticeEValidoEQuantiSono;
var
  LVertices: IScriptVertices;
begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  Assert.IsTrue(LVertices.IsValidVertex(0));
  Assert.IsTrue(LVertices.IsValidVertex(2));
  Assert.IsFalse(LVertices.IsValidVertex(3));
  Assert.IsFalse(LVertices.IsValidVertex(-1));
  Assert.AreEqual(3, LVertices.GetVertexCount);
end;

procedure TTestScriptHostWorld.DovrebbeDareErroreSeIlMondoDeiVerticiEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateVertices(nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostWorld.DovrebbeDescrivereLeVentiseiFunzioniDeiLati;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateSides(FWorldRef));
  // TSide, 16 offsets, 6 textures, the sector, the validity and the count
  Assert.AreEqual(26, LTable.Declarations.Count);
  Assert.AreEqual('procedure TSide(const id: Integer);', LTable.Declarations[0]);
  Assert.AreEqual('!TSide', LTable.ResultTypes[0]);
  Assert.AreEqual('function GetSideTextureOffset(const sd: Integer): fixed_t;', LTable.Declarations[1]);
  Assert.AreEqual('procedure SetSideTextureOffset(const sd: Integer; const offs: fixed_t);',
    LTable.Declarations[2]);
  Assert.AreEqual('function GetSideTopTextureOffset(const sd: Integer): Integer;', LTable.Declarations[3]);
  Assert.AreEqual('procedure SetSideMidRowOffset(const sd: Integer; const offs: Integer);',
    LTable.Declarations[16]);
  Assert.AreEqual('function GetSideTopTexture(const sd: Integer): string;', LTable.Declarations[17]);
  Assert.AreEqual('procedure SetSideMiddleTexture(const sd: Integer; const tex: string);',
    LTable.Declarations[22]);
  Assert.AreEqual('function GetSideSector(const sd: Integer): integer;', LTable.Declarations[23]);
  Assert.AreEqual('function IsValidSide(const sd: Integer): boolean;', LTable.Declarations[24]);
  Assert.AreEqual('function GetSideCount: Integer;', LTable.Declarations[25]);
end;

procedure TTestScriptHostWorld.DovrebbeLeggereEScrivereOgniScostamentoDiUnLato;
var
  LSides: TScriptSides;
begin
  LSides := TScriptSides.Create(FWorldRef);
  try
    Assert.AreEqual(2000, LSides.GetSideTextureOffset(1));
    Assert.AreEqual(2001, LSides.GetSideTopTextureOffset(1));
    Assert.AreEqual(2002, LSides.GetSideBottomTextureOffset(1));
    Assert.AreEqual(2003, LSides.GetSideMidTextureOffset(1));
    Assert.AreEqual(2004, LSides.GetSideRowOffset(1));
    Assert.AreEqual(2005, LSides.GetSideTopRowOffset(1));
    Assert.AreEqual(2006, LSides.GetSideBottomRowOffset(1));
    LSides.SetSideTextureOffset(0, 11);
    LSides.SetSideTopTextureOffset(0, 12);
    LSides.SetSideBottomTextureOffset(0, 13);
    LSides.SetSideMidTextureOffset(0, 14);
    LSides.SetSideRowOffset(0, 15);
    LSides.SetSideTopRowOffset(0, 16);
    LSides.SetSideBottomRowOffset(0, 17);
    Assert.AreEqual('O(0,0,11)O(0,1,12)O(0,2,13)O(0,3,14)O(0,4,15)O(0,5,16)O(0,6,17)', FWorld.Writes);
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeConservareIlDifettoDelloScostamentoMedioDelleRighe;
var
  LSides: TScriptSides;
begin
  // a defect of the old code, kept: the "mid row offset" is the bottom row offset
  LSides := TScriptSides.Create(FWorldRef);
  try
    Assert.AreEqual(1006, LSides.GetSideMidRowOffset(0));
    LSides.SetSideMidRowOffset(0, 99);
    Assert.AreEqual('O(0,6,99)', FWorld.Writes);
    Assert.AreEqual(99, LSides.GetSideBottomRowOffset(0));
    // the interface that the properties of the classes of the scripts use has the same behaviour
    Assert.AreEqual(99, LSides.GetOffset(0, sofMidRow));
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeNonScrivereLoScostamentoDiUnLatoCheNonCe;
var
  LSides: TScriptSides;
begin
  LSides := TScriptSides.Create(FWorldRef);
  try
    LSides.SetSideTextureOffset(3, 1);
    LSides.SetSideRowOffset(-1, 1);
    LSides.SetSideMidRowOffset(3, 1);
    Assert.AreEqual('', FWorld.Writes);
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareZeroPerLoScostamentoDiUnLatoCheNonCe;
var
  LSides: TScriptSides;
begin
  LSides := TScriptSides.Create(FWorldRef);
  try
    Assert.AreEqual(0, LSides.GetSideTextureOffset(3));
    Assert.AreEqual(0, LSides.GetSideMidRowOffset(-1));
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeLeggereEScrivereLeTextureDiUnLato;
var
  LSides: TScriptSides;
begin
  LSides := TScriptSides.Create(FWorldRef);
  try
    Assert.AreEqual('tex10', LSides.GetSideTopTexture(1));
    Assert.AreEqual('tex11', LSides.GetSideBottomTexture(1));
    Assert.AreEqual('tex12', LSides.GetSideMiddleTexture(1));
    LSides.SetSideTopTexture(2, 'A');
    LSides.SetSideBottomTexture(2, 'B');
    LSides.SetSideMiddleTexture(2, 'C');
    Assert.AreEqual('T(2,0,A)T(2,1,B)T(2,2,C)', FWorld.Writes);
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareLaTextureVuotaPerUnLatoCheNonCe;
var
  LSides: TScriptSides;
begin
  LSides := TScriptSides.Create(FWorldRef);
  try
    Assert.AreEqual('', LSides.GetSideTopTexture(3));
    LSides.SetSideMiddleTexture(-1, 'A');
    Assert.AreEqual('', FWorld.Writes);
  finally
    LSides.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareIlSettoreDiUnLatoOIlNumeroNonValido;
var
  LSides: IScriptSides;
begin
  LSides := TScriptHostFactory.CreateSides(FWorldRef);
  Assert.AreEqual(8, LSides.GetSideSector(1));
  Assert.AreEqual(SCRIPT_INVALID_ID, LSides.GetSideSector(3));
  Assert.IsTrue(LSides.IsValidSide(2));
  Assert.IsFalse(LSides.IsValidSide(3));
  Assert.AreEqual(3, LSides.GetSideCount);
end;

procedure TTestScriptHostWorld.DovrebbeDareLaManigliaDiUnLatoValido;
var
  LSides: IScriptSides;
begin
  LSides := TScriptHostFactory.CreateSides(FWorldRef);
  Assert.AreEqual(3, LSides.TSide(2));
  Assert.AreEqual(SCRIPT_INVALID_ID, LSides.TSide(3));
  Assert.AreEqual(SCRIPT_INVALID_ID, LSides.TSide(-5));
end;

procedure TTestScriptHostWorld.DovrebbeDescrivereLeFunzioniDelleLineeDiDoom;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, sgDoom));
  Assert.AreEqual(34, LTable.Declarations.Count);
  Assert.IsTrue(LTable.Declarations.IndexOf('function GetLineTag(const ld: Integer): integer;') >= 0);
  Assert.IsTrue(LTable.Declarations.IndexOf('procedure SetLineTransparent(const ld: Integer; const x: Boolean);') >= 0);
  Assert.AreEqual('function FindLinesFromTag(const tag: integer): TIntegerArray;',
    LTable.Declarations[LTable.Declarations.Count - 1]);
  LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, sgHeretic));
  Assert.AreEqual(34, LTable.Declarations.Count);
  LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, sgStrife));
  Assert.AreEqual(34, LTable.Declarations.Count);
end;

procedure TTestScriptHostWorld.DovrebbeDescrivereLeFunzioniDelleLineeDiHexenSenzaTagETrasparenza;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, sgHexen));
  Assert.AreEqual(29, LTable.Declarations.Count);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf('function GetLineTag(const ld: Integer): integer;'));
  Assert.AreEqual(-1, LTable.Declarations.IndexOf('function GetLineTransparent(const ld: Integer): Boolean;'));
  Assert.AreEqual(-1, LTable.Declarations.IndexOf('function FindLinesFromTag(const tag: integer): TIntegerArray;'));
  Assert.AreEqual('function GetLineCount: Integer;', LTable.Declarations[LTable.Declarations.Count - 1]);
end;

procedure TTestScriptHostWorld.DovrebbeDescrivereLeLineeNellOrdineDelVecchioCodice;
var
  LTable: TFakeFunctionTable;
begin
  LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, sgStrife));
  Assert.AreEqual('procedure TLine(const id: Integer);', LTable.Declarations[0]);
  Assert.AreEqual('!TLine', LTable.ResultTypes[0]);
  Assert.AreEqual('function GetLineVertex1(const ld: Integer): integer;', LTable.Declarations[1]);
  Assert.AreEqual('function GetLineDX(const ld: Integer): fixed_t;', LTable.Declarations[3]);
  Assert.AreEqual('function GetLineSpecial(const ld: Integer): integer;', LTable.Declarations[5]);
  Assert.AreEqual('function GetLineArg1(const ld: Integer): byte;', LTable.Declarations[7]);
  Assert.AreEqual('procedure SetLineArg5(const ld: Integer; const arg: byte);', LTable.Declarations[16]);
  Assert.AreEqual('function GetLineTag(const ld: Integer): integer;', LTable.Declarations[17]);
  Assert.AreEqual('procedure SetLineTransparent(const ld: Integer; const x: Boolean);', LTable.Declarations[20]);
  Assert.AreEqual('function GetLineIsBlocking(const ld: Integer): Boolean;', LTable.Declarations[21]);
  Assert.AreEqual('procedure SetLineTriggerScripts(const ld: Integer; const x: Boolean);', LTable.Declarations[26]);
  Assert.AreEqual('function GetLineCount: Integer;', LTable.Declarations[32]);
end;

procedure TTestScriptHostWorld.DovrebbeDareLaManigliaDiUnaLineaValida;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(4, LLines.TLine(3));
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.TLine(4));
  Assert.IsTrue(LLines.IsValidLine(0));
  Assert.IsFalse(LLines.IsValidLine(-1));
  Assert.AreEqual(4, LLines.GetLineCount);
end;

procedure TTestScriptHostWorld.DovrebbeLeggereIVerticiLeDifferenzeEIlSpecialDiUnaLinea;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(2, LLines.GetLineVertex1(2));
  Assert.AreEqual(12, LLines.GetLineVertex2(2));
  Assert.AreEqual(128, LLines.GetLineDX(2));
  Assert.AreEqual(-128, LLines.GetLineDY(2));
  Assert.AreEqual(102, LLines.GetLineSpecial(2));
end;

procedure TTestScriptHostWorld.DovrebbeDareIlNumeroNonValidoPerIVerticiDiUnaLineaCheNonCe;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineVertex1(4));
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineVertex2(-1));
  Assert.AreEqual(0, LLines.GetLineDX(9));
  Assert.AreEqual(0, LLines.GetLineDY(9));
  Assert.AreEqual(0, LLines.GetLineSpecial(9));
end;

procedure TTestScriptHostWorld.DovrebbeScrivereLoSpecialDiUnaLinea;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  LLines.SetLineSpecial(1, 55);
  Assert.AreEqual('S(1,55)', FWorld.Writes);
end;

procedure TTestScriptHostWorld.DovrebbeLeggereEScrivereOgniArgomentoDiUnaLinea;
var
  LLines: TScriptLines;
begin
  LLines := TScriptLines.Create(FWorldRef, sgHexen);
  try
    Assert.AreEqual(30, Integer(LLines.GetLineArg1(3)));
    Assert.AreEqual(31, Integer(LLines.GetLineArg2(3)));
    Assert.AreEqual(32, Integer(LLines.GetLineArg3(3)));
    Assert.AreEqual(33, Integer(LLines.GetLineArg4(3)));
    Assert.AreEqual(34, Integer(LLines.GetLineArg5(3)));
    LLines.SetLineArg1(1, 1);
    LLines.SetLineArg2(1, 2);
    LLines.SetLineArg3(1, 3);
    LLines.SetLineArg4(1, 4);
    LLines.SetLineArg5(1, 5);
    Assert.AreEqual('A(1,0,1)A(1,1,2)A(1,2,3)A(1,3,4)A(1,4,5)', FWorld.Writes);
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareIlByteBassoDiUnArgomentoPiuGrande;
var
  LLines: IScriptLines;
begin
  // the games that keep an argument in an integer: the old assignment gave the low byte
  FWorld.LineArguments[0, 2] := 300;
  FWorld.LineArguments[0, 3] := -1;
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(44, Integer(LLines.GetLineArgument(0, 2)));
  Assert.AreEqual(255, Integer(LLines.GetLineArgument(0, 3)));
end;

procedure TTestScriptHostWorld.DovrebbeLeggereEScrivereIlTagDiUnaLinea;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(6, LLines.GetLineTag(1));
  LLines.SetLineTag(1, 9);
  Assert.AreEqual('G(1,9)', FWorld.Writes);
  Assert.AreEqual(0, LLines.GetLineTag(7));
end;

procedure TTestScriptHostWorld.DovrebbeCambiareIFlagDiUnaLineaSoloSeHaDueLati;
var
  LLines: TScriptLines;
begin
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    // line 0 has the sides 0 and 1
    LLines.SetLineIsBlocking(0, True);
    LLines.SetLineIsBlockingMonsters(0, True);
    LLines.SetLineTransparent(0, True);
    Assert.AreEqual('F(0,0,True)F(0,1,True)F(0,3,True)', FWorld.Writes);
    Assert.IsTrue(LLines.GetLineIsBlocking(0));
    Assert.IsTrue(LLines.GetLineIsBlockingMonsters(0));
    Assert.IsTrue(LLines.GetLineTransparent(0));
    LLines.SetLineIsBlocking(0, False);
    Assert.IsFalse(LLines.GetLineIsBlocking(0));
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeCambiareIlFlagDegliScriptAncheSenzaDueLati;
var
  LLines: TScriptLines;
begin
  // line 3 has no back side, line 2 has a back side that is not in the level: they take no flag,
  // except the one of the scripts (it had no test of the sides)
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    LLines.SetLineIsBlocking(3, True);
    LLines.SetLineIsBlockingMonsters(2, True);
    LLines.SetLineTransparent(3, True);
    Assert.AreEqual('', FWorld.Writes);
    LLines.SetLineTriggerScripts(3, True);
    LLines.SetLineTriggerScripts(2, True);
    Assert.AreEqual('F(3,2,True)F(2,2,True)', FWorld.Writes);
    Assert.IsTrue(LLines.GetLineTriggerScripts(3));
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeLeggereIFlagDiUnaLineaAnchePerUnaSenzaDueLati;
var
  LLines: TScriptLines;
begin
  FWorld.LineFlags[3, slfBlocking] := True;
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    Assert.IsTrue(LLines.GetLineIsBlocking(3));
    Assert.IsFalse(LLines.GetLineIsBlockingMonsters(3));
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareFalsoAiFlagDiUnaLineaCheNonCe;
var
  LLines: TScriptLines;
begin
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    Assert.IsFalse(LLines.GetLineIsBlocking(-1));
    Assert.IsFalse(LLines.GetLineTransparent(4));
    Assert.IsFalse(LLines.GetLineTriggerScripts(40));
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareILatiEISettoriDiUnaLinea;
var
  LLines: IScriptLines;
begin
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  Assert.AreEqual(1, LLines.GetLineFrontSide(1));
  Assert.AreEqual(2, LLines.GetLineBackSide(1));
  Assert.AreEqual(-1, LLines.GetLineBackSide(3));
  Assert.AreEqual(21, LLines.GetLineFrontSector(1));
  Assert.AreEqual(31, LLines.GetLineBackSector(1));
  // a line without a back sector, and one that is not there
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineBackSector(3));
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineFrontSector(4));
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineFrontSide(4));
  Assert.AreEqual(SCRIPT_INVALID_ID, LLines.GetLineBackSide(-1));
end;

procedure TTestScriptHostWorld.DovrebbeTrovareLeLineeConUnTag;
var
  LLines: TScriptLines;
  LFound: TArray<Integer>;
begin
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    LFound := LLines.FindLinesFromTag(5);
    Assert.AreEqual(3, Length(LFound));
    Assert.AreEqual(0, LFound[0]);
    Assert.AreEqual(2, LFound[1]);
    Assert.AreEqual(3, LFound[2]);
    LFound := LLines.FindLinesFromTag(6);
    Assert.AreEqual(1, Length(LFound));
    Assert.AreEqual(1, LFound[0]);
    Assert.AreEqual(0, Length(LLines.FindLinesFromTag(77)));
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeNonModificareNullaConUnaLineaCheNonCe;
var
  LLines: TScriptLines;
begin
  LLines := TScriptLines.Create(FWorldRef, sgDoom);
  try
    LLines.SetLineSpecial(4, 1);
    LLines.SetLineArg3(-1, 1);
    LLines.SetLineTag(99, 1);
    LLines.SetLineTriggerScripts(4, True);
    Assert.AreEqual('', FWorld.Writes);
  finally
    LLines.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeDareErroreSeIlMondoDelleLineeEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateLines(nil, sgDoom);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSides(nil);
    end, EArgumentNilException);
end;

procedure TTestScriptHostWorld.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var vx, sc, sp, bs, n: Integer; tx: string; a: TIntegerArray;'#13#10 +
    'begin'#13#10 +
    '  vx := GetVertexX(1);'#13#10 +
    '  sc := GetSideCount;'#13#10 +
    '  tx := GetSideTopTexture(1);'#13#10 +
    '  SetSideBottomTexture(1, ''xyz'');'#13#10 +
    '  sp := GetLineSpecial(2);'#13#10 +
    '  SetLineSpecial(2, 77);'#13#10 +
    '  SetLineIsBlocking(0, true);'#13#10 +
    '  bs := GetLineArg3(3);'#13#10 +
    '  a := FindLinesFromTag(5);'#13#10 +
    '  n := Length(a);'#13#10 +
    'end.';
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LTable: IScriptFunctionTable;
  LCompiler: TPSPascalCompiler;
  LExec: TPSExec;
  LBytes: TbtString;
  LVertices, LSides, LLines: IScriptFunctionSection;

  function IntegerAt(const AIndex: Integer): Integer;
  var
    LVariable: PIFVariant;
  begin
    LVariable := LExec.GetVarNo(AIndex);
    Result := PSGetInt(@PPSVariantData(LVariable).Data, LVariable.FType);
  end;

begin
  LVertices := TScriptHostFactory.CreateVertices(FWorldRef);
  LSides := TScriptHostFactory.CreateSides(FWorldRef);
  LLines := TScriptHostFactory.CreateLines(FWorldRef, sgDoom);
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  LTable := TWithoutClassResults.Create(LListRef);
  LVertices.Describe(LTable);
  LSides.Describe(LTable);
  LLines.Describe(LTable);
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  LExec := TPSExec.Create;
  try
    GUsedList := LList;
    LCompiler.OnUses := OnUsesWorldList;
    Assert.IsTrue(LCompiler.Compile(TbtString(SCRIPT_TEXT)), 'compile');
    LCompiler.GetOutput(LBytes);
    LList.RegisterExecutor(LExec);
    Assert.IsTrue(LExec.LoadData(LBytes), 'load');
    Assert.IsTrue(LExec.RunScript, 'run');
    Assert.AreEqual(200, IntegerAt(0));
    Assert.AreEqual(3, IntegerAt(1));
    Assert.AreEqual(102, IntegerAt(2));
    Assert.AreEqual(30 + 2, IntegerAt(3));
    Assert.AreEqual(3, IntegerAt(4));
    Assert.AreEqual('xyz', FWorld.SideTextures[1, sspBottom]);
    Assert.AreEqual(77, FWorld.LineSpecials[2]);
    Assert.IsTrue(FWorld.LineFlags[0, slfBlocking]);
  finally
    LExec.Free;
    LCompiler.Free;
    LTable := nil;
    LListRef := nil;
    LList.Free;
  end;
end;

procedure TTestScriptHostWorld.DovrebbeUsareLoStessoMetodoPerOgniGiocoDelleLinee;
var
  LGame: TScriptGame;
  LTable: TFakeFunctionTable;
  LIndex: Integer;
begin
  // every game has a table whose code addresses are methods of the same class and with an instance
  for LGame := Low(TScriptGame) to High(TScriptGame) do
  begin
    LTable := Describe(TScriptHostFactory.CreateLines(FWorldRef, LGame));
    for LIndex := 0 to LTable.Declarations.Count - 1 do
      Assert.IsNotNull(LTable.Instances[LIndex], LTable.Declarations[LIndex]);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostWorld);

end.
