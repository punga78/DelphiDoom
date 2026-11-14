{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the construction of the Doom 3 collision models        }
{  (issue #108)                                                                }
{                                                                              }
{  Tests\Data\Collision\Doom3\<map>.cm is what the REAL Doom 3 code writes for }
{  <map>.map (Tools\Verifica\108). The library reads the same map, builds the  }
{  models (brushes, patches, merging of polygons, internal edges, polygons    }
{  chopped by brushes and by the proc BSP tree, edge normals, optimisation)    }
{  and writes the .cm text: it has to be the same text, byte for byte.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Doom3Builder;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  [Category('parity')]
  TTestDoom3Builder = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    function BuildText(const AName: string; AWithProc: Boolean): string;
  public
    [Test]
    procedure DovrebbeScrivereLoStessoCmDellaStanza;
    [Test]
    procedure DovrebbeScrivereLoStessoCmDelleTegoleConIlProc;
    [Test]
    procedure DovrebbeUnirePoligoniComplanariEMarcareGliSpigoliInterni;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model, DelphiDoom.Collision.Builder,
  DelphiDoom.Collision.Builder.Chopper, DelphiDoom.Collision.CmFile.Writer, DelphiDoom.Collision.Factory,
  DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf, DelphiDoom.MapFile.Factory, DelphiDoom.MapFile.Proc.Intf,
  DelphiDoom.MapFile.Proc.Factory, DelphiDoom.MapFile.Proc.ProcFile, DelphiDoom.MapFile.Proc.Types,
  DelphiDoom.Tests.Collision.Support;

function TTestDoom3Builder.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\Doom3\' + AFileName);
end;

function TTestDoom3Builder.BuildText(const AName: string; AWithProc: Boolean): string;
var
  LMap: TMapFile;
  LBuilder: TCollisionModelBuilder;
  LCatalog: ICollisionMaterialCatalog;
  LModels: TObjectList<TCollisionModel>;
  LModel: TCollisionModel;
  LProc: TProcFile;
  LNodes: TArray<TCollisionProcNode>;
  LIndex: Integer;
begin
  LCatalog := CreateDoom3Catalog;
  LMap := TMapFileFactory.CreateReader(nil).ParseText(AnsiString(TFile.ReadAllText(DataPath(AName + '.map'),
    TEncoding.ASCII)), AnsiString(AName));
  LModels := TObjectList<TCollisionModel>.Create(True);
  try
    LBuilder := TCollisionFactory.CreateBuilder(nil);
    try
      if AWithProc then
      begin
        LProc := TProcFileFactory.CreateReader(nil).ParseText(AnsiString(TFile.ReadAllText(DataPath(AName + '.proc'),
          TEncoding.ASCII)), AnsiString(AName));
        try
          LNodes := TCollisionChopper.NodesFromProcFile(LProc);
        finally
          LProc.Free;
        end;
        LBuilder.SetProcNodes(LNodes);
      end;
      for LIndex := 0 to LMap.GetNumEntities - 1 do
      begin
        LModel := LBuilder.BuildFromEntity(LMap.GetEntity(LIndex), LCatalog, LModels.Count);
        if Assigned(LModel) then
          LModels.Add(LModel);
      end;
    finally
      LBuilder.Free;
    end;
    Result := TCollisionFileWriter.ToText(LModels.ToArray, LMap.GeometryCrc);
  finally
    LModels.Free;
    LMap.Free;
  end;
end;

procedure TTestDoom3Builder.DovrebbeScrivereLoStessoCmDellaStanza;
var
  LExpected: string;
  LActual: string;
  LIndex: Integer;
begin
  LExpected := TFile.ReadAllText(DataPath('room.cm'), TEncoding.ASCII);
  LActual := BuildText('room', False);
  if LExpected <> LActual then
  begin
    LIndex := 1;
    while (LIndex <= Length(LExpected)) and (LIndex <= Length(LActual)) and (LExpected[LIndex] = LActual[LIndex]) do
      Inc(LIndex);
    Assert.Fail(Format('the .cm text differs at character %d (sizes %d and %d): C++ "%s" Delphi "%s"',
      [LIndex, Length(LExpected), Length(LActual), Copy(LExpected, LIndex - 40, 120), Copy(LActual, LIndex - 40, 120)]));
  end;
end;

procedure TTestDoom3Builder.DovrebbeScrivereLoStessoCmDelleTegoleConIlProc;
var
  LExpected: string;
  LActual: string;
  LIndex: Integer;
begin
  LExpected := TFile.ReadAllText(DataPath('tiles.cm'), TEncoding.ASCII);
  LActual := BuildText('tiles', True);
  if LExpected <> LActual then
  begin
    LIndex := 1;
    while (LIndex <= Length(LExpected)) and (LIndex <= Length(LActual)) and (LExpected[LIndex] = LActual[LIndex]) do
      Inc(LIndex);
    Assert.Fail(Format('the .cm text differs at character %d (sizes %d and %d): C++ "%s" Delphi "%s"',
      [LIndex, Length(LExpected), Length(LActual), Copy(LExpected, LIndex - 40, 120), Copy(LActual, LIndex - 40, 120)]));
  end;
end;

procedure TTestDoom3Builder.DovrebbeUnirePoligoniComplanariEMarcareGliSpigoliInterni;
var
  LMap: TMapFile;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
begin
  LMap := TMapFileFactory.CreateReader(nil).ParseText(AnsiString(TFile.ReadAllText(DataPath('tiles.map'),
    TEncoding.ASCII)), 'tiles');
  try
    LBuilder := TCollisionFactory.CreateBuilder(nil);
    try
      LModel := LBuilder.BuildFromEntity(LMap.GetEntity(0), CreateDoom3Catalog, 0);
      try
        // the numbers of the statistics of the original (printed by the C++ harness for this map)
        Assert.IsTrue(LModel.NumMergedPolys > 0, 'no polygon was merged');
        Assert.IsTrue(LModel.NumInternalEdges > 0, 'no internal edge was found');
        Assert.IsTrue(LModel.NumRemovedPolys > 0, 'no contained polygon was removed');
      finally
        LModel.Free;
      end;
    finally
      LBuilder.Free;
    end;
  finally
    LMap.Free;
  end;
end;

end.
