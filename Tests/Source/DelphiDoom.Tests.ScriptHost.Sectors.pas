{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sector functions of PS_GAME                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Sectors;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.World.Intf,
  DelphiDoom.Tests.ScriptHost.Fakes,
  DelphiDoom.Tests.ScriptHost.World;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostSectors = class(TObject)
  strict private
    FWorld: TFakeWorld;
    FWorldRef: IScriptWorld;
    FSectors: IScriptSectors;
    FTables: TList<IScriptFunctionTable>;
    function DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDescrivereLeSessantaduFunzioniDeiSettoriDiDoomEStrife;
    [Test]
    procedure DovrebbeDescrivereLeFunzioniDeiSettoriDiHereticEHexenSenzaScostamenti;
    [Test]
    procedure DovrebbeDescrivereISettoriNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLaManigliaDiUnSettoreValido;
    [Test]
    procedure DovrebbeDareIlNumeroNonValidoPerUnSettoreCheNonCe;
    [Test]
    procedure DovrebbeLeggereEScrivereLeAltezze;
    [Test]
    procedure DovrebbeDareAltezzaZeroENonScrivereSeIlSettoreNonCe;
    [Test]
    procedure DovrebbeLeggereEScrivereLeTextureDelPavimentoEDelSoffitto;
    [Test]
    procedure DovrebbeDareLaTextureVuotaPerUnSettoreCheNonCe;
    [Test]
    procedure DovrebbeLeggereLaLuceEDareIlNumeroNonValido;
    [Test]
    procedure DovrebbeScrivereLaLuceSoloTraZeroEDuecentocinquantasei;
    [Test]
    procedure DovrebbeLeggereLoSpecialEIlTag;
    [Test]
    procedure DovrebbeScrivereIlTag;
    [Test]
    procedure DovrebbeDareGliAttoriEILoroNumero;
    [Test]
    procedure DovrebbeDareLeLineeDiUnSettoreEIlLoroNumero;
    [Test]
    procedure DovrebbeLeggereEScrivereGliScostamentiDelleTexture;
    [Test]
    procedure DovrebbeLeggereEScrivereGliAngoli;
    [Test]
    procedure DovrebbeLeggereEScrivereIFlagDelSettore;
    [Test]
    procedure DovrebbeLeggereEScrivereGravitaVentoEAngoloDelVento;
    [Test]
    procedure DovrebbeConservareIlDifettoDelVentoDiUnSettoreCheNonCe;
    [Test]
    procedure DovrebbeDareIlSettoreIntermedioSoloSeValido;
    [Test]
    procedure DovrebbeDareIlSettoreDellaPendenzaODelNumeroNonValido;
    [Test]
    procedure DovrebbeDareIlCieloEIlNumeroDeiSettori;
    [Test]
    procedure DovrebbeDireSeUnSettoreEValido;
    [Test]
    procedure DovrebbeTrovareISettoriConUnTag;
    [Test]
    procedure DovrebbeSuonareSoloConUnNomeEUnSettoreValido;
    [Test]
    procedure DovrebbeSpostareInAltoUnSettore;
    [Test]
    procedure DovrebbeDareLePendenzeDiPavimentoESoffitto;
    [Test]
    procedure DovrebbeNonScrivereNullaPerUnSettoreCheNonCe;
    [Test]
    procedure DovrebbeDareErroreSeIlMondoDeiSettoriEnil;
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
  DelphiDoom.ScriptHost.FunctionList;

type
  /// <summary>Passes on to a real list what a script can compile (the function that gives a class of the scripts is left out)</summary>
  TSectorsWithoutClassResults = class(TInterfacedObject, IScriptFunctionTable)
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

function OnUsesSectorList(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
begin
  Result := string(Name) = 'SYSTEM';
  if Result then
  begin
    Sender.AddTypeS('fixed_t', 'Integer');
    Sender.AddTypeS('angle_t', 'LongWord');
    Sender.AddTypeS('TIntegerArray', 'array of Integer');
    Sender.AddTypeS('TActorArray', 'array of LongWord');
    GUsedList.RegisterCompiler(Sender);
  end;
end;

{ TSectorsWithoutClassResults }

constructor TSectorsWithoutClassResults.Create(const AList: IScriptFunctionTable);
begin
  inherited Create;
  FList := AList;
end;

procedure TSectorsWithoutClassResults.Add(const ADeclaration: string; const ACode: Pointer);
begin
  FList.Add(ADeclaration, ACode);
end;

procedure TSectorsWithoutClassResults.AddWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const ACode: Pointer);
begin
end;

procedure TSectorsWithoutClassResults.AddMethod(const ADeclaration: string;
  const AInstance: TObject; const ACode: Pointer);
begin
  FList.AddMethod(ADeclaration, AInstance, ACode);
end;

procedure TSectorsWithoutClassResults.AddMethodWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const AInstance: TObject; const ACode: Pointer);
begin
end;

{ TTestScriptHostSectors }

procedure TTestScriptHostSectors.Setup;
begin
  FWorld := TFakeWorld.Create;
  FWorldRef := FWorld;
  FSectors := TScriptHostFactory.CreateSectors(FWorldRef, sgDoom);
  FTables := TList<IScriptFunctionTable>.Create;
end;

procedure TTestScriptHostSectors.TearDown;
begin
  FTables.Free;
  FSectors := nil;
  FWorldRef := nil;
  FWorld := nil;
end;

function TTestScriptHostSectors.DescribeFor(const AGame: TScriptGame): TFakeFunctionTable;
var
  LRef: IScriptFunctionTable;
begin
  Result := TFakeFunctionTable.Create;
  LRef := Result;
  FTables.Add(LRef);
  TScriptHostFactory.CreateSectors(FWorldRef, AGame).Describe(LRef);
end;

procedure TTestScriptHostSectors.DovrebbeDescrivereLeSessantaduFunzioniDeiSettoriDiDoomEStrife;
begin
  Assert.AreEqual(62, DescribeFor(sgDoom).Declarations.Count);
  Assert.AreEqual(62, DescribeFor(sgStrife).Declarations.Count);
  Assert.IsTrue(DescribeFor(sgDoom).Declarations.IndexOf(
    'function GetSectorFloorXOffset(const sec: Integer): fixed_t;') >= 0);
end;

procedure TTestScriptHostSectors.DovrebbeDescrivereLeFunzioniDeiSettoriDiHereticEHexenSenzaScostamenti;
var
  LTable: TFakeFunctionTable;
begin
  LTable := DescribeFor(sgHeretic);
  Assert.AreEqual(54, LTable.Declarations.Count);
  Assert.AreEqual(-1, LTable.Declarations.IndexOf(
    'function GetSectorFloorXOffset(const sec: Integer): fixed_t;'));
  Assert.AreEqual(54, DescribeFor(sgHexen).Declarations.Count);
end;

procedure TTestScriptHostSectors.DovrebbeDescrivereISettoriNellOrdineDelVecchioCodice;
var
  LTable: TFakeFunctionTable;
  LLast: Integer;
begin
  LTable := DescribeFor(sgDoom);
  Assert.AreEqual('procedure TSector(const id: Integer);', LTable.Declarations[0]);
  Assert.AreEqual('!TSector', LTable.ResultTypes[0]);
  Assert.AreEqual('function TSector(const id: Integer): !TSector;', LTable.ExportDeclarations[0]);
  Assert.AreEqual('function GetSectorFloorHeight(const sec: Integer): fixed_t;', LTable.Declarations[1]);
  Assert.AreEqual('function GetSectorNumLines(const sec: Integer): Integer;', LTable.Declarations[17]);
  Assert.AreEqual('function GetSectorFloorXOffset(const sec: Integer): fixed_t;', LTable.Declarations[18]);
  Assert.AreEqual('function GetSectorFloorAngle(const sec: Integer): angle_t;', LTable.Declarations[26]);
  LLast := LTable.Declarations.Count - 1;
  Assert.AreEqual('function FindSectorsFromTag(const tag: integer): TIntegerArray;',
    LTable.Declarations[LLast - 4]);
  Assert.AreEqual('procedure SectorMoveZ(const secid: integer; const dz: fixed_t);',
    LTable.Declarations[LLast - 2]);
  Assert.IsTrue(LTable.Declarations[LLast].StartsWith('procedure SetSectorCeilingSlope(const secid'));
  // one object answers every function
  Assert.IsNotNull(LTable.Instances[0]);
  Assert.AreSame(LTable.Instances[0], LTable.Instances[LLast]);
end;

procedure TTestScriptHostSectors.DovrebbeDareLaManigliaDiUnSettoreValido;
begin
  Assert.AreEqual(3, FSectors.TSector(2));
  Assert.AreEqual(1, FSectors.TSector(0));
end;

procedure TTestScriptHostSectors.DovrebbeDareIlNumeroNonValidoPerUnSettoreCheNonCe;
begin
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.TSector(3));
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.TSector(-1));
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereLeAltezze;
begin
  Assert.AreEqual(256, FSectors.GetSectorFloorHeight(1));
  Assert.AreEqual(512, FSectors.GetSectorCeilingHeight(1));
  FSectors.SetSectorFloorHeight(1, 40);
  FSectors.SetSectorCeilingHeight(2, 50);
  Assert.AreEqual(40, FWorld.SectorHeights[1, splFloor]);
  Assert.AreEqual(50, FWorld.SectorHeights[2, splCeiling]);
  Assert.AreEqual('H(1,0,40)H(2,1,50)', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeDareAltezzaZeroENonScrivereSeIlSettoreNonCe;
begin
  Assert.AreEqual(0, FSectors.GetSectorFloorHeight(3));
  Assert.AreEqual(0, FSectors.GetSectorCeilingHeight(-1));
  FSectors.SetSectorFloorHeight(3, 1);
  FSectors.SetSectorCeilingHeight(-1, 1);
  Assert.AreEqual('', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereLeTextureDelPavimentoEDelSoffitto;
begin
  Assert.AreEqual('FLAT10', FSectors.GetSectorFloorPicture(1));
  Assert.AreEqual('FLAT11', FSectors.GetSectorCeilingPicture(1));
  FSectors.SetSectorFloorPicture(2, 'NEWFLOOR');
  FSectors.SetSectorCeilingPicture(2, 'NEWCEIL');
  Assert.AreEqual('NEWFLOOR', FWorld.SectorPictures[2, splFloor]);
  Assert.AreEqual('NEWCEIL', FWorld.SectorPictures[2, splCeiling]);
end;

procedure TTestScriptHostSectors.DovrebbeDareLaTextureVuotaPerUnSettoreCheNonCe;
begin
  Assert.AreEqual('', FSectors.GetSectorFloorPicture(5));
  Assert.AreEqual('', FSectors.GetSectorCeilingPicture(-2));
  FSectors.SetSectorFloorPicture(5, 'X');
  Assert.AreEqual('', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeLeggereLaLuceEDareIlNumeroNonValido;
begin
  Assert.AreEqual(101, FSectors.GetSectorLightLevel(1));
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorLightLevel(3));
end;

procedure TTestScriptHostSectors.DovrebbeScrivereLaLuceSoloTraZeroEDuecentocinquantasei;
begin
  FSectors.SetSectorLightLevel(0, 0);
  Assert.AreEqual(0, FWorld.SectorLights[0]);
  FSectors.SetSectorLightLevel(0, 255);
  Assert.AreEqual(255, FWorld.SectorLights[0]);
  FSectors.SetSectorLightLevel(0, 128);
  FSectors.SetSectorLightLevel(0, 256);
  Assert.AreEqual(255, FWorld.SectorLights[0]);
  FSectors.SetSectorLightLevel(0, 100);
  FSectors.SetSectorLightLevel(0, 257);
  Assert.AreEqual(100, FWorld.SectorLights[0]);
  FSectors.SetSectorLightLevel(0, -1);
  Assert.AreEqual(100, FWorld.SectorLights[0]);
  FSectors.SetSectorLightLevel(9, 10);
  Assert.AreEqual(100, FWorld.SectorLights[0]);
end;

procedure TTestScriptHostSectors.DovrebbeLeggereLoSpecialEIlTag;
begin
  Assert.AreEqual(10, FSectors.GetSectorSpecial(1));
  Assert.AreEqual(41, FSectors.GetSectorTag(1));
  Assert.AreEqual(0, FSectors.GetSectorSpecial(3));
  Assert.AreEqual(0, FSectors.GetSectorTag(-1));
end;

procedure TTestScriptHostSectors.DovrebbeScrivereIlTag;
begin
  FSectors.SetSectorTag(2, 99);
  Assert.AreEqual(99, FWorld.SectorTags[2]);
  FSectors.SetSectorTag(3, 98);
  Assert.AreEqual(99, FWorld.SectorTags[2]);
end;

procedure TTestScriptHostSectors.DovrebbeDareGliAttoriEILoroNumero;
var
  LKeys: TArray<Cardinal>;
begin
  LKeys := FSectors.GetSectorActors(0);
  Assert.AreEqual(3, Integer(Length(LKeys)));
  Assert.AreEqual(Cardinal(12), LKeys[1]);
  Assert.AreEqual(3, FSectors.GetSectorNumActors(0));
  Assert.AreEqual(0, Integer(Length(FSectors.GetSectorActors(1))));
  Assert.AreEqual(0, Integer(Length(FSectors.GetSectorActors(7))));
  Assert.AreEqual(0, FSectors.GetSectorNumActors(7));
end;

procedure TTestScriptHostSectors.DovrebbeDareLeLineeDiUnSettoreEIlLoroNumero;
var
  LLines: TArray<Integer>;
begin
  LLines := FSectors.GetSectorLines(0);
  Assert.AreEqual(2, Integer(Length(LLines)));
  Assert.AreEqual(2, LLines[0]);
  Assert.AreEqual(0, LLines[1]);
  Assert.AreEqual(2, FSectors.GetSectorNumLines(0));
  Assert.AreEqual(1, FSectors.GetSectorNumLines(1));
  Assert.AreEqual(0, FSectors.GetSectorNumLines(2));
  Assert.AreEqual(0, Integer(Length(FSectors.GetSectorLines(-1))));
  Assert.AreEqual(0, FSectors.GetSectorNumLines(3));
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereGliScostamentiDelleTexture;
begin
  Assert.AreEqual(10, FSectors.GetSectorFloorXOffset(1));
  Assert.AreEqual(11, FSectors.GetSectorFloorYOffset(1));
  Assert.AreEqual(12, FSectors.GetSectorCeilingXOffset(1));
  Assert.AreEqual(13, FSectors.GetSectorCeilingYOffset(1));
  FSectors.SetSectorFloorXOffset(1, 1);
  FSectors.SetSectorFloorYOffset(1, 2);
  FSectors.SetSectorCeilingXOffset(1, 3);
  FSectors.SetSectorCeilingYOffset(1, 4);
  Assert.AreEqual(1, FWorld.SectorOffsets[1, ssoFloorX]);
  Assert.AreEqual(2, FWorld.SectorOffsets[1, ssoFloorY]);
  Assert.AreEqual(3, FWorld.SectorOffsets[1, ssoCeilingX]);
  Assert.AreEqual(4, FWorld.SectorOffsets[1, ssoCeilingY]);
  Assert.AreEqual(0, FSectors.GetSectorFloorXOffset(8));
  FSectors.SetSectorFloorXOffset(8, 5);
  Assert.AreEqual(1, FWorld.SectorOffsets[1, ssoFloorX]);
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereGliAngoli;
begin
  Assert.AreEqual(Cardinal(100), FSectors.GetSectorFloorAngle(1));
  Assert.AreEqual(101, FSectors.GetSectorFloorAngleX(1));
  Assert.AreEqual(102, FSectors.GetSectorFloorAngleY(1));
  Assert.AreEqual(Cardinal(103), FSectors.GetSectorCeilingAngle(1));
  Assert.AreEqual(104, FSectors.GetSectorCeilingAngleX(1));
  Assert.AreEqual(105, FSectors.GetSectorCeilingAngleY(1));
  FSectors.SetSectorFloorAngle(2, $FFFFFFF0);
  FSectors.SetSectorFloorAngleX(2, 1);
  FSectors.SetSectorFloorAngleY(2, 2);
  FSectors.SetSectorCeilingAngle(2, 3);
  FSectors.SetSectorCeilingAngleX(2, 4);
  FSectors.SetSectorCeilingAngleY(2, 5);
  // the same bits, read back as unsigned
  Assert.AreEqual(Cardinal($FFFFFFF0), Cardinal(FWorld.SectorAngles[2, ssaFloor]));
  Assert.AreEqual(Cardinal($FFFFFFF0), FSectors.GetSectorFloorAngle(2));
  Assert.AreEqual(1, FWorld.SectorAngles[2, ssaFloorX]);
  Assert.AreEqual(2, FWorld.SectorAngles[2, ssaFloorY]);
  Assert.AreEqual(3, FWorld.SectorAngles[2, ssaCeiling]);
  Assert.AreEqual(4, FWorld.SectorAngles[2, ssaCeilingX]);
  Assert.AreEqual(5, FWorld.SectorAngles[2, ssaCeilingY]);
  Assert.AreEqual(0, FSectors.GetSectorFloorAngleX(3));
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereIFlagDelSettore;
begin
  // sector 1: flag k is true when (1 + k) is odd, that is ripple floor and interpolate...
  Assert.AreEqual(FWorld.SectorFlags[1, ssfRippleFloor], FSectors.GetSectorRippleFloor(1));
  Assert.AreEqual(FWorld.SectorFlags[1, ssfRippleCeiling], FSectors.GetSectorRippleCeiling(1));
  Assert.AreEqual(FWorld.SectorFlags[1, ssfInterpolate], FSectors.GetSectorInterpolate(1));
  Assert.AreEqual(FWorld.SectorFlags[1, ssfFog], FSectors.GetSectorFog(1));
  FSectors.SetSectorRippleFloor(0, True);
  FSectors.SetSectorRippleCeiling(0, True);
  FSectors.SetSectorInterpolate(0, True);
  FSectors.SetSectorFog(0, True);
  Assert.IsTrue(FWorld.SectorFlags[0, ssfRippleFloor]);
  Assert.IsTrue(FWorld.SectorFlags[0, ssfRippleCeiling]);
  Assert.IsTrue(FWorld.SectorFlags[0, ssfInterpolate]);
  Assert.IsTrue(FWorld.SectorFlags[0, ssfFog]);
  FSectors.SetSectorFog(0, False);
  Assert.IsFalse(FWorld.SectorFlags[0, ssfFog]);
  Assert.IsFalse(FSectors.GetSectorRippleFloor(3));
  Assert.IsFalse(FSectors.GetSectorFog(-1));
  Assert.IsFalse(FSectors.GetSectorInterpolate(3));
end;

procedure TTestScriptHostSectors.DovrebbeLeggereEScrivereGravitaVentoEAngoloDelVento;
begin
  Assert.AreEqual(10000, FSectors.GetSectorGravity(1));
  Assert.AreEqual(10001, FSectors.GetSectorWindThrust(1));
  Assert.AreEqual(Cardinal(10002), FSectors.GetSectorWindAngle(1));
  FSectors.SetSectorGravity(1, 7);
  FSectors.SetSectorWindThrust(1, 8);
  FSectors.SetSectorWindAngle(1, $80000000);
  Assert.AreEqual(7, FWorld.SectorValues[1, ssvGravity]);
  Assert.AreEqual(8, FWorld.SectorValues[1, ssvWindThrust]);
  Assert.AreEqual(Cardinal($80000000), FSectors.GetSectorWindAngle(1));
end;

procedure TTestScriptHostSectors.DovrebbeConservareIlDifettoDelVentoDiUnSettoreCheNonCe;
begin
  // the old code answered with the normal gravity (65536), for the thrust and for the angle too
  Assert.AreEqual(65536, FSectors.GetSectorGravity(3));
  Assert.AreEqual(65536, FSectors.GetSectorWindThrust(3));
  Assert.AreEqual(Cardinal(65536), FSectors.GetSectorWindAngle(-1));
end;

procedure TTestScriptHostSectors.DovrebbeDareIlSettoreIntermedioSoloSeValido;
begin
  Assert.AreEqual(1, FSectors.GetSectorMidSector(1));
  // sector 2 has the number 77 and the level has 3 sectors
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorMidSector(2));
  FWorld.SectorMids[0] := -1;
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorMidSector(0));
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorMidSector(5));
end;

procedure TTestScriptHostSectors.DovrebbeDareIlSettoreDellaPendenzaODelNumeroNonValido;
begin
  Assert.AreEqual(1, FSectors.GetSectorSlopeSector(2));
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorSlopeSector(0));
  Assert.AreEqual(SCRIPT_INVALID_ID, FSectors.GetSectorSlopeSector(3));
end;

procedure TTestScriptHostSectors.DovrebbeDareIlCieloEIlNumeroDeiSettori;
begin
  Assert.AreEqual('F_SKY1', FSectors.SkyPicture);
  Assert.AreEqual(3, FSectors.GetSectorCount);
end;

procedure TTestScriptHostSectors.DovrebbeDireSeUnSettoreEValido;
begin
  Assert.IsTrue(FSectors.IsValidSector(0));
  Assert.IsTrue(FSectors.IsValidSector(2));
  Assert.IsFalse(FSectors.IsValidSector(3));
  Assert.IsFalse(FSectors.IsValidSector(-1));
end;

procedure TTestScriptHostSectors.DovrebbeTrovareISettoriConUnTag;
var
  LFound: TArray<Integer>;
begin
  LFound := FSectors.FindSectorsFromTag(40);
  Assert.AreEqual(2, Integer(Length(LFound)));
  Assert.AreEqual(0, LFound[0]);
  Assert.AreEqual(2, LFound[1]);
  Assert.AreEqual(1, Integer(Length(FSectors.FindSectorsFromTag(41))));
  Assert.AreEqual(0, Integer(Length(FSectors.FindSectorsFromTag(42))));
end;

procedure TTestScriptHostSectors.DovrebbeSuonareSoloConUnNomeEUnSettoreValido;
begin
  FSectors.SectorPlaySound(1, 'DSDOROPN');
  FSectors.SectorPlaySound(1, '');
  FSectors.SectorPlaySound(3, 'DSDOROPN');
  Assert.AreEqual('N(1,DSDOROPN)', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeSpostareInAltoUnSettore;
begin
  FSectors.SectorMoveZ(2, 64);
  FSectors.SectorMoveZ(3, 64);
  Assert.AreEqual('Z(2,64)', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeDareLePendenzeDiPavimentoESoffitto;
begin
  FSectors.SetSectorFloorSlope(1, 1, 2, 3, 4, 5, 6, 7, 8, 9);
  FSectors.SetSectorCeilingSlope(2, 9, 8, 7, 6, 5, 4, 3, 2, 1);
  Assert.AreEqual('F(1,1,2,3,4,5,6,7,8,9)C(2,9,8,7,6,5,4,3,2,1)', FWorld.Writes);
end;

procedure TTestScriptHostSectors.DovrebbeNonScrivereNullaPerUnSettoreCheNonCe;
begin
  FSectors.SetSectorFloorSlope(3, 1, 2, 3, 4, 5, 6, 7, 8, 9);
  FSectors.SetSectorCeilingSlope(-1, 1, 2, 3, 4, 5, 6, 7, 8, 9);
  FSectors.SetSectorFloorAngle(3, 1);
  FSectors.SetSectorGravity(3, 1);
  FSectors.SetSectorLightLevel(3, 1);
  FSectors.SetSectorWindAngle(-1, 1);
  FSectors.SectorMoveZ(-1, 1);
  Assert.AreEqual('', FWorld.Writes);
  Assert.AreEqual(101, FWorld.SectorLights[1]);
end;

procedure TTestScriptHostSectors.DovrebbeDareErroreSeIlMondoDeiSettoriEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSectors(nil, sgDoom);
    end,
    EArgumentNilException);
end;

procedure TTestScriptHostSectors.DovrebbeChiamareLeFunzioniDaUnoScriptVero;
const
  SCRIPT_TEXT =
    'var fh, tg, n, c, nl: Integer; pic, sky: string; a: TActorArray; f: TIntegerArray;'#13#10 +
    'begin'#13#10 +
    '  fh := GetSectorFloorHeight(1);'#13#10 +
    '  SetSectorTag(2, 77);'#13#10 +
    '  tg := GetSectorTag(2);'#13#10 +
    '  SetSectorCeilingPicture(0, ''SKYX'');'#13#10 +
    '  pic := GetSectorCeilingPicture(0);'#13#10 +
    '  a := GetSectorActors(0);'#13#10 +
    '  n := Length(a);'#13#10 +
    '  f := FindSectorsFromTag(40);'#13#10 +
    '  c := GetSectorCount;'#13#10 +
    '  nl := GetSectorNumLines(0);'#13#10 +
    '  sky := SkyPicture;'#13#10 +
    '  SetSectorFloorSlope(1, 1, 2, 3, 4, 5, 6, 7, 8, 9);'#13#10 +
    '  SetSectorFloorAngle(1, 2000000000);'#13#10 +
    '  SectorMoveZ(0, 8);'#13#10 +
    'end.';
var
  LList: TScriptFunctionList;
  LListRef: IScriptFunctionTable;
  LTable: IScriptFunctionTable;
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

begin
  LList := TScriptFunctionList.Create('PS_GAME');
  LListRef := LList;
  LTable := TSectorsWithoutClassResults.Create(LListRef);
  FSectors.Describe(LTable);
  LCompiler := TPSPascalCompiler.Create(PRTabArray(@DefaultLookupTable), DEFAULT_KEYWORD_COUNT);
  LExec := TPSExec.Create;
  try
    GUsedList := LList;
    LCompiler.OnUses := OnUsesSectorList;
    Assert.IsTrue(LCompiler.Compile(TbtString(SCRIPT_TEXT)), 'compile');
    LCompiler.GetOutput(LBytes);
    LList.RegisterExecutor(LExec);
    Assert.IsTrue(LExec.LoadData(LBytes), 'load');
    Assert.IsTrue(LExec.RunScript, 'run');
    Assert.AreEqual(256, IntegerAt(0));
    Assert.AreEqual(77, IntegerAt(1));
    Assert.AreEqual(3, IntegerAt(2));
    Assert.AreEqual(3, IntegerAt(3));
    Assert.AreEqual(2, IntegerAt(4));
    Assert.AreEqual('SKYX', FWorld.SectorPictures[0, splCeiling]);
    Assert.AreEqual(77, FWorld.SectorTags[2]);
    Assert.AreEqual('P(0,1,SKYX)F(1,1,2,3,4,5,6,7,8,9)Z(0,8)', FWorld.Writes);
    Assert.AreEqual(2000000000, FWorld.SectorAngles[1, ssaFloor]);
  finally
    LExec.Free;
    LCompiler.Free;
    LTable := nil;
    LListRef := nil;
    LList.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptHostSectors);

end.
