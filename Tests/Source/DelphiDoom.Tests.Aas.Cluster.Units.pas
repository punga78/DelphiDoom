{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - clustering and optimizer, errors     }
{  and edge cases                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Cluster.Units;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Aas.Intf;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasClusterUnits = class
  strict private
    function Load: IAasFile;
    procedure InitClustering(const AFile: IAasFile);
    procedure Optimize(const AFile: IAasFile);
  public
    [Test]
    procedure DovrebbeNonFareNullaSeCiSonoGiaICluster;
    [Test]
    procedure DovrebbeRifareICluster;
    [Test]
    procedure DovrebbeRifareIClusterSeForzato;
    [Test]
    procedure DovrebbeRifareIClusterSenzaFlussoSuiPiani;
    [Test]
    procedure DovrebbeSollevareSeIlFileNonSiPuoCambiare;
    [Test]
    procedure DovrebbeSollevareSeUnaRaggiungibilitaVaFuoriDallaTabella;
    [Test]
    procedure DovrebbeSollevareSeUnaRaggiungibilitaPortaInUnAreaChePiuNonC;
    [Test]
    procedure DovrebbeSollevareSeUnaFacciaPortaInUnAreaChePiuNonC;
    [Test]
    procedure DovrebbeSollevareSeUnaFacciaHaSpigoliFuoriDallaTabella;
    [Test]
    procedure DovrebbeSollevareSeUnAreaHaFacceFuoriDallaTabella;
    [Test]
    procedure DovrebbeSollevareSeUnAreaUsaUnaFacciaChePiuNonC;
    [Test]
    procedure DovrebbeSollevareSeUnAreaHaNegativoIlPrimoSpigolo;
    [Test]
    procedure DovrebbeOttimizzareIlMondoDiProva;
    [Test]
    procedure DovrebbeSollevareNellOttimizzatoreSeIlFileNonSiPuoCambiare;
    [Test]
    procedure DovrebbeSollevareNellOttimizzatoreSeUnaRaggiungibilitaVaFuori;
    [Test]
    procedure DovrebbeSollevareNellOttimizzatoreSeUnSpigoloUsaUnVertice;
    [Test]
    procedure DovrebbeSollevareNellOttimizzatoreSeUnaFacciaDiScalaHaSpigoliFuori;
    [Test]
    procedure DovrebbeSollevareNellOttimizzatoreSeUnAreaHaFacceFuori;
    [Test]
    procedure DovrebbeTenereIFileDelleSituazioniDelC;
  end;

implementation

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Factory,
  DelphiDoom.Aas.Editor.Intf, DelphiDoom.Aas.Cluster.Intf, DelphiDoom.Aas.Cluster.Types,
  DelphiDoom.Aas.Cluster.Initializer, DelphiDoom.Tests.Aas.Sample;

type
  TNullImport = class(TInterfacedObject, IBotImport)
  public
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

  TForceVars = class(TInterfacedObject, IBotLibVars)
  public
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

  /// <summary>A file that shows IAasFile only: it is not changeable</summary>
  TReadOnlyFile = class(TInterfacedObject, IAasFile)
  public
    function GetVersion: Integer;
    function GetBspChecksum: Integer;
    function GetHeader: TAasFileHeader;
    function GetBBoxes: TArray<TAasBBox>;
    function GetVertexes: TArray<TVec3>;
    function GetPlanes: TArray<TAasPlane>;
    function GetEdges: TArray<TAasEdge>;
    function GetEdgeIndex: TArray<Integer>;
    function GetFaces: TArray<TAasFace>;
    function GetFaceIndex: TArray<Integer>;
    function GetAreas: TArray<TAasArea>;
    function GetAreaSettings: TArray<TAasAreaSettings>;
    function GetReachability: TArray<TAasReachability>;
    function GetNodes: TArray<TAasNode>;
    function GetPortals: TArray<TAasPortal>;
    function GetPortalIndex: TArray<Integer>;
    function GetClusters: TArray<TAasCluster>;
    function LumpBytes(const AIndex: Integer): TBytes;
  end;

{ TNullImport }

procedure TNullImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
end;

procedure TNullImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TNullImport.Time: Single;
begin
  Result := 0;
end;

procedure TNullImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

{ TForceVars }

function TForceVars.GetValue(const AName: AnsiString): Single;
begin
  Result := 1;
end;

function TForceVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := 1;
end;

function TForceVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := '';
end;

{ TReadOnlyFile }

function TReadOnlyFile.GetVersion: Integer;
begin
  Result := Default(Integer);
end;

function TReadOnlyFile.GetBspChecksum: Integer;
begin
  Result := Default(Integer);
end;

function TReadOnlyFile.GetHeader: TAasFileHeader;
begin
  Result := Default(TAasFileHeader);
end;

function TReadOnlyFile.GetBBoxes: TArray<TAasBBox>;
begin
  Result := Default(TArray<TAasBBox>);
end;

function TReadOnlyFile.GetVertexes: TArray<TVec3>;
begin
  Result := Default(TArray<TVec3>);
end;

function TReadOnlyFile.GetPlanes: TArray<TAasPlane>;
begin
  Result := Default(TArray<TAasPlane>);
end;

function TReadOnlyFile.GetEdges: TArray<TAasEdge>;
begin
  Result := Default(TArray<TAasEdge>);
end;

function TReadOnlyFile.GetEdgeIndex: TArray<Integer>;
begin
  Result := Default(TArray<Integer>);
end;

function TReadOnlyFile.GetFaces: TArray<TAasFace>;
begin
  Result := Default(TArray<TAasFace>);
end;

function TReadOnlyFile.GetFaceIndex: TArray<Integer>;
begin
  Result := Default(TArray<Integer>);
end;

function TReadOnlyFile.GetAreas: TArray<TAasArea>;
begin
  Result := Default(TArray<TAasArea>);
end;

function TReadOnlyFile.GetAreaSettings: TArray<TAasAreaSettings>;
begin
  Result := Default(TArray<TAasAreaSettings>);
end;

function TReadOnlyFile.GetReachability: TArray<TAasReachability>;
begin
  Result := Default(TArray<TAasReachability>);
end;

function TReadOnlyFile.GetNodes: TArray<TAasNode>;
begin
  Result := Default(TArray<TAasNode>);
end;

function TReadOnlyFile.GetPortals: TArray<TAasPortal>;
begin
  Result := Default(TArray<TAasPortal>);
end;

function TReadOnlyFile.GetPortalIndex: TArray<Integer>;
begin
  Result := Default(TArray<Integer>);
end;

function TReadOnlyFile.GetClusters: TArray<TAasCluster>;
begin
  Result := Default(TArray<TAasCluster>);
end;

function TReadOnlyFile.LumpBytes(const AIndex: Integer): TBytes;
begin
  Result := nil;
end;

{ TTestAasClusterUnits }

function TTestAasClusterUnits.Load: IAasFile;
var
  LBytes: TBytes;
  LHeader: TAasFileHeader;
begin
  LBytes := TAasSample.Bytes(0);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  Result := TAasFactory.CreateReader(TNullImport.Create, nil, nil).ParseBytes(LBytes, 'maps/cluster.aas',
    LHeader.BspChecksum);
end;

procedure TTestAasClusterUnits.InitClustering(const AFile: IAasFile);
var
  LEditor: IAasFileEditor;
begin
  // the clusters are wiped, so that they are made again
  Assert.IsTrue(Supports(AFile, IAasFileEditor, LEditor));
  LEditor.ReplaceClusterData(nil, nil, nil);
  TAasFactory.CreateClusterInitializer(AFile, TNullImport.Create).InitClustering;
end;

procedure TTestAasClusterUnits.Optimize(const AFile: IAasFile);
begin
  TAasFactory.CreateOptimizer(AFile, TNullImport.Create).Optimize;
end;

procedure TTestAasClusterUnits.DovrebbeNonFareNullaSeCiSonoGiaICluster;
var
  LFile: IAasFile;
  LInitializer: IAasClusterInitializer;
begin
  LFile := Load;
  InitClustering(LFile);
  Assert.IsTrue(Length(LFile.Clusters) > 1);
  LInitializer := TAasFactory.CreateClusterInitializer(LFile, TNullImport.Create);
  Assert.IsFalse(LInitializer.InitClustering);
  LInitializer := TAasFactory.CreateClusterInitializer(LFile, TNullImport.Create, nil);
  Assert.IsFalse(LInitializer.InitClustering);
end;

procedure TTestAasClusterUnits.DovrebbeRifareICluster;
var
  LFile: IAasFile;
  LEditor: IAasFileEditor;
begin
  LFile := Load;
  Supports(LFile, IAasFileEditor, LEditor);
  LEditor.ReplaceClusterData(nil, nil, nil);
  Assert.IsTrue(TAasFactory.CreateClusterInitializer(LFile, TNullImport.Create).InitClustering);
  Assert.IsTrue(Length(LFile.Clusters) > 1);
  Assert.IsTrue(Length(LFile.Portals) > 1);
end;

procedure TTestAasClusterUnits.DovrebbeRifareIClusterSeForzato;
var
  LFile: IAasFile;
begin
  LFile := Load;
  Assert.IsTrue(TAasFactory.CreateClusterInitializer(LFile, TNullImport.Create, TForceVars.Create).InitClustering);
  Assert.IsTrue(Length(LFile.Clusters) > 1);
end;

procedure TTestAasClusterUnits.DovrebbeRifareIClusterSenzaFlussoSuiPiani;
var
  LFile: IAasFile;
  LInitializer: TAasClusterInitializer;
  LKeep: IAasClusterInitializer;
  LEditor: IAasFileEditor;
begin
  LFile := Load;
  Supports(LFile, IAasFileEditor, LEditor);
  LEditor.ReplaceClusterData(nil, nil, nil);
  LInitializer := TAasClusterInitializer.Create(LFile, TNullImport.Create, nil);
  // the interface count owns the object
  LKeep := LInitializer;
  try
    Assert.IsTrue(LInitializer.NoFaceFlood);
    LInitializer.NoFaceFlood := False;
    Assert.IsFalse(LInitializer.NoFaceFlood);
    Assert.IsTrue(LInitializer.InitClustering);
  finally
    LKeep := nil;
  end;
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeIlFileNonSiPuoCambiare;
var
  LFile: IAasFile;
begin
  LFile := TReadOnlyFile.Create;
  Assert.WillRaise(
    procedure
    begin
      TAasFactory.CreateClusterInitializer(LFile, TNullImport.Create, TForceVars.Create).InitClustering;
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnaRaggiungibilitaVaFuoriDallaTabella;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.AreaSettings[1].FirstReachableArea := Length(LFile.Reachability) + 5;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnaRaggiungibilitaPortaInUnAreaChePiuNonC;
var
  LFile: IAasFile;
begin
  LFile := Load;
  Assert.IsTrue(Length(LFile.Reachability) > 0);
  LFile.Reachability[0].AreaNum := Length(LFile.Areas) + 100;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnaFacciaPortaInUnAreaChePiuNonC;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Faces[1].FrontArea := Length(LFile.Areas) + 100;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnaFacciaHaSpigoliFuoriDallaTabella;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Faces[1].FirstEdge := Length(LFile.EdgeIndex) + 100;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnAreaHaFacceFuoriDallaTabella;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Areas[1].FirstFace := Length(LFile.FaceIndex) + 100;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnAreaUsaUnaFacciaChePiuNonC;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.FaceIndex[LFile.Areas[1].FirstFace] := Length(LFile.Faces) + 100;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareSeUnAreaHaNegativoIlPrimoSpigolo;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Areas[1].FirstFace := -3;
  Assert.WillRaise(
    procedure
    begin
      InitClustering(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeOttimizzareIlMondoDiProva;
var
  LFile: IAasFile;
  LIndex: Integer;
begin
  LFile := Load;
  for LIndex := 0 to High(LFile.Faces) do
    if LIndex mod 7 = 3 then
      LFile.Faces[LIndex].FaceFlags := LFile.Faces[LIndex].FaceFlags or FACE_LADDER;
  Optimize(LFile);
  // only the ladder faces are kept (and the dummy ones)
  Assert.IsTrue(Length(LFile.Faces) >= 1);
  Assert.IsTrue(Length(LFile.Faces) < 20);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareNellOttimizzatoreSeIlFileNonSiPuoCambiare;
var
  LFile: IAasFile;
begin
  LFile := TReadOnlyFile.Create;
  Assert.WillRaise(
    procedure
    begin
      Optimize(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareNellOttimizzatoreSeUnaRaggiungibilitaVaFuori;
var
  LFile: IAasFile;
begin
  LFile := Load;
  Assert.IsTrue(Length(LFile.Reachability) > 0);
  LFile.Reachability[0].TravelType := TRAVEL_WALK;
  LFile.Reachability[0].FaceNum := Length(LFile.Faces) + 100;
  Assert.WillRaise(
    procedure
    begin
      Optimize(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareNellOttimizzatoreSeUnSpigoloUsaUnVertice;
var
  LFile: IAasFile;
  LIndex: Integer;
begin
  LFile := Load;
  for LIndex := 0 to High(LFile.Faces) do
    LFile.Faces[LIndex].FaceFlags := LFile.Faces[LIndex].FaceFlags or FACE_LADDER;
  LFile.Edges[1].Vertexes[0] := Length(LFile.Vertexes) + 100;
  Assert.WillRaise(
    procedure
    begin
      Optimize(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareNellOttimizzatoreSeUnaFacciaDiScalaHaSpigoliFuori;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Faces[1].FaceFlags := LFile.Faces[1].FaceFlags or FACE_LADDER;
  LFile.Faces[1].FirstEdge := Length(LFile.EdgeIndex) + 100;
  Assert.WillRaise(
    procedure
    begin
      Optimize(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeSollevareNellOttimizzatoreSeUnAreaHaFacceFuori;
var
  LFile: IAasFile;
begin
  LFile := Load;
  LFile.Areas[1].FirstFace := Length(LFile.FaceIndex) + 100;
  Assert.WillRaise(
    procedure
    begin
      Optimize(LFile);
    end, EAasClusterException);
end;

procedure TTestAasClusterUnits.DovrebbeTenereIFileDelleSituazioniDelC;
var
  LFile: IAasFile;
begin
  // a file that was optimized already: optimizing it again keeps the dummy entries
  LFile := Load;
  Optimize(LFile);
  Optimize(LFile);
  Assert.IsTrue(Length(LFile.Areas) >= 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasClusterUnits);

end.
