{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sprite and beam models of Doom 3 and of the model  }
{  files on IGameFileSystem (DUnitX)                                           }
{                                                                              }
{  The geometry is worked out by hand from Model_sprite.cpp and Model_beam.cpp }
{  (the models need the renderer: they cannot be compiled alone).              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Dynamic;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Source.GameFileSystem, DelphiDoom.Models.Dynamic.Types,
  DelphiDoom.Models.Dynamic.SpriteModel, DelphiDoom.Models.Dynamic.BeamModel;

type
  [TestFixture]
  [Category('models')]
  TTestSpriteModel = class(TObject)
  public
    [Test]
    procedure DovrebbeFareUnQuadratoNelPianoYZ;
    [Test]
    procedure DovrebbeColorareDaiParametriDelloShader;
    [Test]
    procedure DovrebbeDareGliIndiciEIlMateriale;
    [Test]
    procedure DovrebbeDareLeBoundsDalLatoMaggiore;
  end;

  [TestFixture]
  [Category('models')]
  TTestBeamModel = class(TObject)
  public
    [Test]
    procedure DovrebbeFareUnNastroVersoIlBersaglioChiRivoltoAllaVista;
    [Test]
    procedure DovrebbeUsareLaLarghezzaEL_assePiuMeno;
    [Test]
    procedure DovrebbeTrasformareIlBersaglioNelLocale;
    [Test]
    procedure DovrebbeDareLeBoundsDelBersaglio;
  end;

  [TestFixture]
  [Category('models')]
  TTestModelGameFileSource = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIByteComeStringaA8BitEIlTempo;
    [Test]
    procedure DovrebbeDireFalsoSeIlFileNonCe;
    [Test]
    procedure DovrebbeDareTempoZeroPerUnFileInUnPak;
  end;

implementation

type
  TTimestampFile = class(TInterfacedObject, IGameFile)
  strict private
    FTimestamp: Int64;
  public
    constructor Create(ATimestamp: Int64);
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Integer;
    function GetTimestamp: Int64;
    function GetPack: IGamePack;
    function ReadAll: TBytes;
  end;

  TTwoFileSystem = class(TInterfacedObject, IGameFileSystem)
  public
    procedure Startup;
    procedure Restart;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags; const AGameDir: string): IGameFile;
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    function FileLength(const ARelativePath: string): Integer;
    function FileIsInPak(const ARelativePath: string): Boolean;
    function ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
      const AGameDir: string): TArray<string>;
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
      const AGameDir: string): TArray<string>;
    function SearchPaths: TArray<TGameSearchPath>;
    function PackChecksums: TArray<Cardinal>;
    function AddonPackFileNames: TArray<string>;
  end;

constructor TTimestampFile.Create(ATimestamp: Int64);
begin
  inherited Create;
  FTimestamp := ATimestamp;
end;

function TTimestampFile.GetName: string;
begin
  Result := '';
end;

function TTimestampFile.GetFullPath: string;
begin
  Result := '';
end;

function TTimestampFile.GetLength: Integer;
begin
  Result := 0;
end;

function TTimestampFile.GetTimestamp: Int64;
begin
  Result := FTimestamp;
end;

function TTimestampFile.GetPack: IGamePack;
begin
  Result := nil;
end;

function TTimestampFile.ReadAll: TBytes;
begin
  Result := nil;
end;

procedure TTwoFileSystem.Startup;
begin
end;

procedure TTwoFileSystem.Restart;
begin
end;

procedure TTwoFileSystem.Shutdown;
begin
end;

function TTwoFileSystem.IsInitialized: Boolean;
begin
  Result := True;
end;

function TTwoFileSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
begin
  // "models/a.ase" is in a folder with a time stamp; "models/b.ase" is in a pak (nil here: no file object)
  if SameText(ARelativePath, 'models/a.ase') then
    Result := TTimestampFile.Create(777)
  else
    Result := nil;
end;

function TTwoFileSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
begin
  Result := SameText(ARelativePath, 'models/a.ase') or SameText(ARelativePath, 'models/b.ase');
  if Result then
    AData := TBytes.Create(Ord('*'), 200, 0, 65)
  else
    AData := nil;
end;

function TTwoFileSystem.FileLength(const ARelativePath: string): Integer;
begin
  Result := -1;
end;

function TTwoFileSystem.FileIsInPak(const ARelativePath: string): Boolean;
begin
  Result := False;
end;

function TTwoFileSystem.ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TTwoFileSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TTwoFileSystem.SearchPaths: TArray<TGameSearchPath>;
begin
  Result := nil;
end;

function TTwoFileSystem.PackChecksums: TArray<Cardinal>;
begin
  Result := nil;
end;

function TTwoFileSystem.AddonPackFileNames: TArray<string>;
begin
  Result := nil;
end;

{ TTestSpriteModel }

procedure TTestSpriteModel.DovrebbeFareUnQuadratoNelPianoYZ;
var
  LEntity: TDynamicEntity;
  LSnapshot: TDynamicSnapshot;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.ShaderParms[SHADERPARM_SPRITE_WIDTH] := 10;
  LEntity.ShaderParms[SHADERPARM_SPRITE_HEIGHT] := 4;
  LSnapshot := TSpriteModel.Create.Instantiate(LEntity);
  Assert.AreEqual('_sprite_Snapshot_', LSnapshot.Name);
  Assert.AreEqual<Integer>(4, Length(LSnapshot.Surface.Triangles.Verts));
  with LSnapshot.Surface.Triangles do
  begin
    Assert.AreEqual(0.0, Double(Verts[0].Xyz.X), 0);
    Assert.AreEqual(5.0, Double(Verts[0].Xyz.Y), 0);
    Assert.AreEqual(2.0, Double(Verts[0].Xyz.Z), 0);
    Assert.AreEqual(-5.0, Double(Verts[1].Xyz.Y), 0);
    Assert.AreEqual(2.0, Double(Verts[1].Xyz.Z), 0);
    Assert.AreEqual(-5.0, Double(Verts[2].Xyz.Y), 0);
    Assert.AreEqual(-2.0, Double(Verts[2].Xyz.Z), 0);
    Assert.AreEqual(5.0, Double(Verts[3].Xyz.Y), 0);
    Assert.AreEqual(-2.0, Double(Verts[3].Xyz.Z), 0);
    // the normal and the tangents of the original, the texture corners in order
    Assert.AreEqual(1.0, Double(Verts[2].Normal.X), 0);
    Assert.AreEqual(1.0, Double(Verts[1].Tangents[0].Y), 0);
    Assert.AreEqual(1.0, Double(Verts[3].Tangents[1].Z), 0);
    Assert.AreEqual(1.0, Double(Verts[2].St.X), 0);
    Assert.AreEqual(1.0, Double(Verts[2].St.Y), 0);
    Assert.AreEqual(0.0, Double(Verts[3].St.X), 0);
    Assert.AreEqual(1.0, Double(Verts[3].St.Y), 0);
  end;
  Assert.AreEqual(-5.0, Double(LSnapshot.Bounds.Mins.Y), 0);
  Assert.AreEqual(2.0, Double(LSnapshot.Bounds.Maxs.Z), 0);
end;

procedure TTestSpriteModel.DovrebbeColorareDaiParametriDelloShader;
var
  LEntity: TDynamicEntity;
  LSnapshot: TDynamicSnapshot;
  LIndex: Integer;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.ShaderParms[SHADERPARM_RED] := 1;
  LEntity.ShaderParms[SHADERPARM_GREEN] := 0;
  LEntity.ShaderParms[SHADERPARM_BLUE] := 0.2;
  LEntity.ShaderParms[SHADERPARM_ALPHA] := 0.5;
  LSnapshot := TSpriteModel.Create.Instantiate(LEntity);
  for LIndex := 0 to 3 do
    with LSnapshot.Surface.Triangles.Verts[LIndex].Color do
    begin
      Assert.AreEqual(255, Integer(R));
      Assert.AreEqual(0, Integer(G));
      Assert.AreEqual(51, Integer(B));
      Assert.IsTrue((A = 127) or (A = 128));
    end;
end;

procedure TTestSpriteModel.DovrebbeDareGliIndiciEIlMateriale;
var
  LSnapshot: TDynamicSnapshot;
begin
  LSnapshot := TSpriteModel.Create.Instantiate(TDynamicEntity.Default);
  Assert.AreEqual<Integer>(6, Length(LSnapshot.Surface.Triangles.Indexes));
  Assert.AreEqual(0, LSnapshot.Surface.Triangles.Indexes[0]);
  Assert.AreEqual(1, LSnapshot.Surface.Triangles.Indexes[1]);
  Assert.AreEqual(3, LSnapshot.Surface.Triangles.Indexes[2]);
  Assert.AreEqual(1, LSnapshot.Surface.Triangles.Indexes[3]);
  Assert.AreEqual(2, LSnapshot.Surface.Triangles.Indexes[4]);
  Assert.AreEqual(3, LSnapshot.Surface.Triangles.Indexes[5]);
  Assert.AreEqual('_default', string(LSnapshot.Surface.MaterialName));
  Assert.IsTrue(LSnapshot.Surface.HasGeometry);
end;

procedure TTestSpriteModel.DovrebbeDareLeBoundsDalLatoMaggiore;
var
  LEntity: TDynamicEntity;
  LModel: TSpriteModel;
begin
  LModel := TSpriteModel.Create;
  try
    LEntity := TDynamicEntity.Default;
    LEntity.ShaderParms[SHADERPARM_SPRITE_WIDTH] := 10;
    LEntity.ShaderParms[SHADERPARM_SPRITE_HEIGHT] := 30;
    Assert.AreEqual(-15.0, Double(LModel.Bounds(LEntity).Mins.X), 0);
    Assert.AreEqual(15.0, Double(LModel.Bounds(LEntity).Maxs.Z), 0);
    // without an entity: 8 units each way
    Assert.AreEqual(-8.0, Double(LModel.Bounds(LEntity, False).Mins.Y), 0);
    Assert.AreEqual(8.0, Double(LModel.Bounds(LEntity, False).Maxs.Y), 0);
  finally
    LModel.Free;
  end;
end;

{ TTestBeamModel }

procedure TTestBeamModel.DovrebbeFareUnNastroVersoIlBersaglioChiRivoltoAllaVista;
var
  LEntity: TDynamicEntity;
  LSnapshot: TDynamicSnapshot;
  LModel: TBeamModel;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.ShaderParms[SHADERPARM_BEAM_END_X] := 100;
  LModel := TBeamModel.Create;
  try
    // the target at 100 along x, the view above the middle of the beam: the beam x (0, 0, -100) from the view to the
    // middle makes the minor axis along +y, of length one without a width
    LSnapshot := LModel.Instantiate(LEntity, TIdVec3.Create(50, 0, 100));
  finally
    LModel.Free;
  end;
  Assert.AreEqual('_beam_Snapshot_', LSnapshot.Name);
  with LSnapshot.Surface.Triangles do
  begin
    Assert.AreEqual(0.0, Double(Verts[0].Xyz.X), 0.001);
    Assert.AreEqual(1.0, Double(Verts[0].Xyz.Y), 0.01);
    Assert.AreEqual(-1.0, Double(Verts[1].Xyz.Y), 0.01);
    Assert.AreEqual(100.0, Double(Verts[2].Xyz.X), 0.01);
    Assert.AreEqual(1.0, Double(Verts[2].Xyz.Y), 0.01);
    Assert.AreEqual(100.0, Double(Verts[3].Xyz.X), 0.01);
    Assert.AreEqual(-1.0, Double(Verts[3].Xyz.Y), 0.01);
    Assert.AreEqual(0.0, Double(Verts[0].St.X), 0);
    Assert.AreEqual(1.0, Double(Verts[1].St.Y), 0);
    Assert.AreEqual(1.0, Double(Verts[2].St.X), 0);
    Assert.AreEqual(0.0, Double(Verts[2].St.Y), 0);
    Assert.AreEqual(2, Indexes[1]);
    Assert.AreEqual(1, Indexes[2]);
    Assert.AreEqual(3, Indexes[4]);
  end;
end;

procedure TTestBeamModel.DovrebbeUsareLaLarghezzaEL_assePiuMeno;
var
  LEntity: TDynamicEntity;
  LSnapshot: TDynamicSnapshot;
  LModel: TBeamModel;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.ShaderParms[SHADERPARM_BEAM_END_X] := 100;
  LEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] := 8;
  LEntity.ShaderParms[SHADERPARM_RED] := 1;
  LEntity.ShaderParms[SHADERPARM_ALPHA] := 1;
  LModel := TBeamModel.Create;
  try
    // a view on the other side: the minor axis flips with the view
    LSnapshot := LModel.Instantiate(LEntity, TIdVec3.Create(50, 0, -100));
  finally
    LModel.Free;
  end;
  Assert.AreEqual(-4.0, Double(LSnapshot.Surface.Triangles.Verts[0].Xyz.Y), 0.04);
  Assert.AreEqual(4.0, Double(LSnapshot.Surface.Triangles.Verts[1].Xyz.Y), 0.04);
  Assert.AreEqual(255, Integer(LSnapshot.Surface.Triangles.Verts[3].Color.R));
  Assert.AreEqual(255, Integer(LSnapshot.Surface.Triangles.Verts[3].Color.A));
  Assert.AreEqual(0, Integer(LSnapshot.Surface.Triangles.Verts[3].Color.G));
end;

procedure TTestBeamModel.DovrebbeTrasformareIlBersaglioNelLocale;
var
  LEntity: TDynamicEntity;
  LSnapshot: TDynamicSnapshot;
  LModel: TBeamModel;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.Origin := TIdVec3.Create(10, 0, 0);
  // an axis that turns x into y: local = axis * (world - origin)
  LEntity.Axis := TIdMat3.Create(TIdVec3.Create(0, 1, 0), TIdVec3.Create(-1, 0, 0), TIdVec3.Create(0, 0, 1));
  LEntity.ShaderParms[SHADERPARM_BEAM_END_X] := 10;
  LEntity.ShaderParms[SHADERPARM_BEAM_END_Y] := 50;
  LModel := TBeamModel.Create;
  try
    LSnapshot := LModel.Instantiate(LEntity, TIdVec3.Create(10, 25, 100));
  finally
    LModel.Free;
  end;
  // the world offset (0, 50, 0) is (50, 0, 0) in the local frame
  Assert.AreEqual(50.0, Double(LSnapshot.Surface.Triangles.Verts[2].Xyz.X), 0.05);
  Assert.AreEqual(0.0, Double(LSnapshot.Surface.Triangles.Verts[2].Xyz.Z), 0.05);
end;

procedure TTestBeamModel.DovrebbeDareLeBoundsDelBersaglio;
var
  LEntity: TDynamicEntity;
  LModel: TBeamModel;
  LBounds: TGeoBounds;
begin
  LEntity := TDynamicEntity.Default;
  LEntity.ShaderParms[SHADERPARM_BEAM_END_X] := 100;
  LEntity.ShaderParms[SHADERPARM_BEAM_END_Y] := -30;
  LModel := TBeamModel.Create;
  try
    LBounds := LModel.Bounds(LEntity);
    Assert.AreEqual(0.0, Double(LBounds.Mins.X), 0);
    Assert.AreEqual(100.0, Double(LBounds.Maxs.X), 0);
    Assert.AreEqual(-30.0, Double(LBounds.Mins.Y), 0);
    LEntity.ShaderParms[SHADERPARM_BEAM_WIDTH] := 10;
    LBounds := LModel.Bounds(LEntity);
    Assert.AreEqual(105.0, Double(LBounds.Maxs.X), 0);
    Assert.AreEqual(-5.0, Double(LBounds.Mins.X), 0);
    Assert.AreEqual(-8.0, Double(LModel.Bounds(LEntity, False).Mins.X), 0);
  finally
    LModel.Free;
  end;
end;

{ TTestModelGameFileSource }

procedure TTestModelGameFileSource.DovrebbeLeggereIByteComeStringaA8BitEIlTempo;
var
  LSource: IModelFileSource;
  LData: AnsiString;
  LTime: Int64;
begin
  LSource := TModelGameFileSource.Create(TTwoFileSystem.Create);
  Assert.IsTrue(LSource.ReadFile('models/a.ase', LData, LTime));
  Assert.AreEqual(4, Length(LData));
  Assert.AreEqual(200, Integer(Ord(LData[2])));
  Assert.AreEqual(0, Integer(Ord(LData[3])));
  Assert.AreEqual<Int64>(777, LTime);
end;

procedure TTestModelGameFileSource.DovrebbeDireFalsoSeIlFileNonCe;
var
  LSource: IModelFileSource;
  LData: AnsiString;
  LTime: Int64;
begin
  LSource := TModelGameFileSource.Create(TTwoFileSystem.Create);
  Assert.IsFalse(LSource.ReadFile('models/none.ase', LData, LTime));
  Assert.AreEqual('', string(LData));
  Assert.AreEqual<Int64>(0, LTime);
end;

procedure TTestModelGameFileSource.DovrebbeDareTempoZeroPerUnFileInUnPak;
var
  LSource: IModelFileSource;
  LData: AnsiString;
  LTime: Int64;
begin
  LSource := TModelGameFileSource.Create(TTwoFileSystem.Create);
  Assert.IsTrue(LSource.ReadFile('models/b.ase', LData, LTime));
  Assert.AreEqual<Int64>(0, LTime);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSpriteModel);
  TDUnitX.RegisterTestFixture(TTestBeamModel);
  TDUnitX.RegisterTestFixture(TTestModelGameFileSource);

end.
