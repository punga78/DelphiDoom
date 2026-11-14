{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the voxels of the test PK3         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Pk3;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf, DelphiDoom.Tests.Voxel.Fakes;

type
  /// <summary>
  ///   Reads the voxels of Tests\Data\Pk3\src\voxels (the same bytes that are in zpktest.pk3, see
  ///   the README of the folder) with the classes of the library and a file source that serves
  ///   them by name, as the engine does with the PK3: a KVX, a DDVOX and a VOX of 8x8x8 made on
  ///   purpose (a stepped pyramid, twice, and a sphere), with the VOXELDEF that names them
  /// </summary>
  [TestFixture]
  [Category('voxel')]
  [Category('pk3')]
  TTestVoxelPk3 = class(TObject)
  private
    FDataDir: string;
    FLog: TVoxelFakeLog;
    FLogInterface: ILog;
    FSource: TVoxelFakeSource;
    FSourceInterface: IVoxelFileSource;
    FLoader: IVoxelLoader;
    function Bytes(const ARelative: string): TBytes;
    function Filled(const AModel: IVoxelModel): Integer;
    function FilledCube(const ACube: IVoxelCube): Integer;
    function PyramidHeight(AX, AY: Integer): Integer;
    function InsideSphere(AX, AY, AZ: Integer): Boolean;
    function SphereCount: Integer;
    procedure CheckPyramid(const AModel: IVoxelModel);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIlKvxDelPk3;
    [Test]
    procedure DovrebbeLeggereIlDdvoxDelPk3;
    [Test]
    procedure DovrebbeLeggereIlVoxDelPk3;
    [Test]
    procedure DovrebbeLeggereIVoxelPerNomeSenzaAvvisi;
    [Test]
    procedure DovrebbeFareIlCuboDelKvxPerLoSpriteSenzaPerdereVoxel;
    [Test]
    procedure DovrebbeFareIlCuboDelKvxPerIlRendererSenzaPerdereVoxel;
    [Test]
    procedure DovrebbeFareIlCuboDelDdvoxEDelVox;
    [Test]
    procedure DovrebbeFareLaPatchDelloSpriteDiOgniVoxel;
    [Test]
    procedure DovrebbeLeggereIlVoxeldefDelPk3;
    [Test]
    procedure DovrebbeFareDaiVoxelDelPk3TreSpriteNuovi;
  end;

implementation

uses
  System.Math, DelphiDoom.Voxel.Factory;

const
  SIDE = 8;

{ TTestVoxelPk3 }

procedure TTestVoxelPk3.Setup;
begin
  FDataDir := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Pk3\src'));
  FLog := TVoxelFakeLog.Create;
  FLogInterface := FLog;
  FSource := TVoxelFakeSource.Create;
  FSourceInterface := FSource;
  FSource.AddFile('ZVKAA.KVX', Bytes('voxels\ZVKAA.KVX'));
  FSource.AddFile('ZVDAA.DDVOX', Bytes('voxels\ZVDAA.DDVOX'));
  FSource.AddFile('ZVSAA.VOX', Bytes('voxels\ZVSAA.VOX'));
  FLoader := TVoxelFactory.CreateLoader(FSourceInterface, FLogInterface);
end;

procedure TTestVoxelPk3.TearDown;
begin
  FLoader := nil;
  FSourceInterface := nil;
  FLogInterface := nil;
end;

function TTestVoxelPk3.Bytes(const ARelative: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.Combine(FDataDir, ARelative));
end;

function TTestVoxelPk3.Filled(const AModel: IVoxelModel): Integer;
var
  LCell: Cardinal;
begin
  Result := 0;
  for LCell in AModel.Cells do
    if LCell <> 0 then
      Inc(Result);
end;

function TTestVoxelPk3.FilledCube(const ACube: IVoxelCube): Integer;
var
  LCell: Cardinal;
begin
  Result := 0;
  for LCell in ACube.Cells do
    if LCell <> 0 then
      Inc(Result);
end;

// the generator: the height of the column (x, y) is 8 - max(|2x - 7|, |2y - 7|), from the bottom
function TTestVoxelPk3.PyramidHeight(AX, AY: Integer): Integer;
begin
  Result := 8 - Max(Abs(2 * AX - 7), Abs(2 * AY - 7));
end;

// the generator: the voxels of the sphere are the ones that are at most 3.5 from the center
function TTestVoxelPk3.InsideSphere(AX, AY, AZ: Integer): Boolean;
begin
  Result := Sqr(AX - 3.5) + Sqr(AY - 3.5) + Sqr(AZ - 3.5) <= 12.25;
end;

function TTestVoxelPk3.SphereCount: Integer;
var
  LX, LY, LZ: Integer;
begin
  Result := 0;
  for LX := 0 to SIDE - 1 do
    for LY := 0 to SIDE - 1 do
      for LZ := 0 to SIDE - 1 do
        if InsideSphere(LX, LY, LZ) then
          Inc(Result);
end;

procedure TTestVoxelPk3.CheckPyramid(const AModel: IVoxelModel);
var
  LX, LY, LZ, LTotal: Integer;
begin
  Assert.AreEqual(SIDE, AModel.SizeX, 'SizeX');
  Assert.AreEqual(SIDE, AModel.SizeY, 'SizeY');
  Assert.AreEqual(SIDE, AModel.SizeZ, 'SizeZ');
  LTotal := 0;
  for LX := 0 to SIDE - 1 do
    for LY := 0 to SIDE - 1 do
    begin
      Inc(LTotal, PyramidHeight(LX, LY));
      for LZ := 0 to SIDE - 1 do
        // z = 0 is the top: the column fills the last PyramidHeight cells
        Assert.AreEqual(LZ >= SIDE - PyramidHeight(LX, LY), AModel.Cell(LX, LY, LZ) <> 0,
          Format('cella (%d, %d, %d)', [LX, LY, LZ]));
    end;
  Assert.AreEqual(176, LTotal, 'la piramide ha 176 voxel');
  Assert.AreEqual(LTotal, Filled(AModel), 'dovrebbe avere solo quei voxel');
end;

procedure TTestVoxelPk3.DovrebbeLeggereIlKvxDelPk3;
var
  LModel: IVoxelModel;
begin
  LModel := FLoader.Load('ZVKAA.KVX');
  Assert.IsNotNull(LModel, 'dovrebbe leggerlo');
  Assert.AreEqual(Ord(vfKvx), Ord(LModel.Format), 'dovrebbe essere un KVX');
  CheckPyramid(LModel);
  Assert.AreEqual(SIDE div 2 * KVX_PIVOT_UNIT, LModel.PivotX, 'pivot x');
  Assert.AreEqual(SIDE div 2 * KVX_PIVOT_UNIT, LModel.PivotY, 'pivot y');
  Assert.AreEqual(SIDE * KVX_PIVOT_UNIT, LModel.PivotZ, 'pivot z');
end;

procedure TTestVoxelPk3.DovrebbeLeggereIlDdvoxDelPk3;
var
  LModel: IVoxelModel;
begin
  LModel := FLoader.Load('ZVDAA.DDVOX');
  Assert.IsNotNull(LModel, 'dovrebbe leggerlo');
  Assert.AreEqual(Ord(vfDdvox), Ord(LModel.Format), 'dovrebbe essere un DDVOX');
  CheckPyramid(LModel);
end;

procedure TTestVoxelPk3.DovrebbeLeggereIlVoxDelPk3;
var
  LModel: IVoxelModel;
  LX, LY, LZ: Integer;
begin
  LModel := FLoader.Load('ZVSAA.VOX');
  Assert.IsNotNull(LModel, 'dovrebbe leggerlo');
  Assert.AreEqual(Ord(vfSlab6), Ord(LModel.Format), 'dovrebbe essere un VOX di Slab6');
  Assert.AreEqual(SIDE, LModel.SizeX, 'SizeX');
  Assert.AreEqual(SIDE, LModel.SizeY, 'SizeY');
  Assert.AreEqual(SIDE, LModel.SizeZ, 'SizeZ');
  for LX := 0 to SIDE - 1 do
    for LY := 0 to SIDE - 1 do
      for LZ := 0 to SIDE - 1 do
        Assert.AreEqual(InsideSphere(LX, LY, LZ), LModel.Cell(LX, LY, LZ) <> 0,
          Format('cella (%d, %d, %d)', [LX, LY, LZ]));
  Assert.AreEqual(SphereCount, Filled(LModel), 'dovrebbe avere solo i voxel della sfera');
end;

procedure TTestVoxelPk3.DovrebbeLeggereIVoxelPerNomeSenzaAvvisi;
begin
  Assert.IsTrue(FLoader.IsSupported('ZVKAA.KVX'), 'KVX');
  Assert.IsTrue(FLoader.IsSupported('zvdaa.ddvox'), 'DDVOX in minuscolo');
  Assert.IsTrue(FLoader.IsSupported('ZVSAA.VOX'), 'VOX');
  Assert.IsNotNull(FLoader.Load('ZVKAA.KVX'));
  Assert.IsNotNull(FLoader.Load('ZVDAA.DDVOX'));
  Assert.IsNotNull(FLoader.Load('ZVSAA.VOX'));
  Assert.AreEqual(0, FLog.Warnings.Count, 'non dovrebbe avvisare');
  Assert.IsNull(FLoader.Load('NONE.KVX'), 'un voxel che non c''e'' da nil senza avviso');
  Assert.AreEqual(0, FLog.Warnings.Count, 'neppure per un file che manca');
end;

procedure TTestVoxelPk3.DovrebbeFareIlCuboDelKvxPerLoSpriteSenzaPerdereVoxel;
var
  LCube: IVoxelCube;
begin
  LCube := TVoxelFactory.CreateCubeBuilder.Build(FLoader.Load('ZVKAA.KVX'), cfSprite);
  Assert.AreEqual(0, LCube.Size mod 2, 'il lato di uno sprite e'' pari');
  Assert.IsTrue(LCube.Size >= SIDE, 'il cubo contiene il modello');
  Assert.AreEqual(176, FilledCube(LCube), 'nessun voxel perso');
end;

procedure TTestVoxelPk3.DovrebbeFareIlCuboDelKvxPerIlRendererSenzaPerdereVoxel;
var
  LCube: IVoxelCube;
begin
  LCube := TVoxelFactory.CreateCubeBuilder.Build(FLoader.Load('ZVKAA.KVX'), cfRenderer);
  Assert.IsTrue(LCube.Size > SIDE, 'il renderer lascia un voxel di margine');
  Assert.AreEqual(176, FilledCube(LCube), 'nessun voxel perso');
end;

procedure TTestVoxelPk3.DovrebbeFareIlCuboDelDdvoxEDelVox;
var
  LCube: IVoxelCube;
begin
  LCube := TVoxelFactory.CreateCubeBuilder.Build(FLoader.Load('ZVDAA.DDVOX'), cfSprite);
  Assert.AreEqual(SIDE, LCube.Size, 'il cubo del DDVOX e'' il suo lato');
  Assert.AreEqual(176, FilledCube(LCube), 'voxel del DDVOX');
  LCube := TVoxelFactory.CreateCubeBuilder.Build(FLoader.Load('ZVSAA.VOX'), cfSprite);
  Assert.AreEqual(SIDE, LCube.Size, 'il cubo del VOX e'' il suo lato');
  Assert.AreEqual(SphereCount, FilledCube(LCube), 'voxel del VOX');
end;

procedure TTestVoxelPk3.DovrebbeFareLaPatchDelloSpriteDiOgniVoxel;
var
  LBuilder: IVoxelPatchBuilder;
  LName: string;
  LPatch: TBytes;
  LWidth, LHeight: Integer;
begin
  LBuilder := TVoxelFactory.CreatePatchBuilder(TVoxelFakeMapper.Create);
  for LName in ['ZVKAA.KVX', 'ZVDAA.DDVOX', 'ZVSAA.VOX'] do
  begin
    LPatch := LBuilder.Build(TVoxelFactory.CreateCubeBuilder.Build(FLoader.Load(LName), cfSprite));
    Assert.IsTrue(Length(LPatch) > 8, 'dovrebbe avere piu'' dell''intestazione: ' + LName);
    LWidth := SmallInt(LPatch[0] or (LPatch[1] shl 8));
    LHeight := SmallInt(LPatch[2] or (LPatch[3] shl 8));
    Assert.IsTrue((LWidth > 0) and (LHeight > 0), 'dimensioni della patch di ' + LName);
    Assert.IsTrue(8 + 4 * LWidth <= Length(LPatch), 'tabella delle colonne di ' + LName);
  end;
end;

procedure TTestVoxelPk3.DovrebbeLeggereIlVoxeldefDelPk3;
var
  LParser: IVoxelDefinitionParser;
  LSink: TVoxelFakeSink;
  LSinkInterface: IVoxelDefinitionSink;
  LText: string;
begin
  LText := TEncoding.ASCII.GetString(Bytes('VOXELDEF'));
  LSink := TVoxelFakeSink.Create;
  LSinkInterface := LSink;
  LParser := TVoxelFactory.CreateDefinitionParser(TVoxelFakeLookup.Create, FLogInterface);
  LParser.Parse(LText, LSinkInterface);
  // the three voxels have names that come from the file: the sink is called with each of them
  Assert.IsTrue(Pos('V ZVKAA.KVX|', LSink.Lines.Text) > 0, 'dovrebbe dare il KVX: ' + LSink.Lines.Text);
  Assert.IsTrue(Pos('V ZVDAA.DDVOX|', LSink.Lines.Text) > 0, 'dovrebbe dare il DDVOX: ' + LSink.Lines.Text);
  Assert.IsTrue(Pos('V ZVSAA.VOX|', LSink.Lines.Text) > 0, 'dovrebbe dare il VOX: ' + LSink.Lines.Text);
  Assert.IsTrue(Pos('C treda|ZVKAA.KVX', LSink.Lines.Text) > 0, 'dovrebbe controllare lo sprite sostituito');
end;

procedure TTestVoxelPk3.DovrebbeFareDaiVoxelDelPk3TreSpriteNuovi;
var
  LNames: IVoxelSpriteNames;
  LFile: string;
begin
  // a game with a sprite section that has none of the sprites of the files
  LNames := TVoxelFactory.CreateSpriteNames(TVoxelFakeLumpNames.Create(['S_START', 'POSSA1', 'S_END']));
  for LFile in ['voxels\ZVKAA.KVX', 'voxels\ZVDAA.DDVOX', 'voxels\ZVSAA.VOX', 'VOXELDEF',
    'textures\ZPKPNG.PNG', 'sounds\ZPKWAV.WAV'] do
    LNames.AddFileName(LFile);
  Assert.AreEqual(3, LNames.Count, 'solo i tre voxel diventano sprite');
  Assert.AreEqual('ZVKAA.KVX', LNames.Entry(0));
  Assert.AreEqual('ZVKAA0', LNames.SpriteName(0));
  Assert.AreEqual('ZVDAA0', LNames.SpriteName(1));
  Assert.AreEqual('ZVSAA0', LNames.SpriteName(2));
  // a game that already has the sprite keeps it
  LNames := TVoxelFactory.CreateSpriteNames(TVoxelFakeLumpNames.Create(['S_START', 'ZVKAA1', 'S_END']));
  LNames.AddFileName('voxels\ZVKAA.KVX');
  Assert.AreEqual(0, LNames.Count, 'uno sprite che il gioco ha gia'' non si sostituisce');
end;

end.
