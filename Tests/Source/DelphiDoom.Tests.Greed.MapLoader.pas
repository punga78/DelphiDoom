{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - finding and loading a map           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.MapLoader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedMapLoader = class(TObject)
  private
    FArchive: IGreedArchive;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaMappaDalLumpChePassaLaPrima;
    [Test]
    procedure DovrebbeLeggereLaMappaDalFileSeIlLumpEVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnLumpVuotoSenzaFile;
    [Test]
    procedure DovrebbeRifiutareUnLumpVuotoSeIlFileNonCe;
    [Test]
    procedure DovrebbeRifiutareUnArchivioSenzaIlLumpMap;
    [Test]
    procedure DovrebbeRifiutareUnFileCortoDiUnLumpVuoto;
    [Test]
    procedure DovrebbeRifiutareUnFileDiUnAltroFormato;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Greed.MapLoader, DelphiDoom.Tests.Greed.Builders;

type
  /// <summary>Files in memory</summary>
  TFakeFiles = class(TInterfacedObject, IGreedExternalFiles)
  public
    Name: string;
    Bytes: TBytes;
    function Exists(const AName: string): Boolean;
    function ReadAll(const AName: string): TBytes;
  end;

function TFakeFiles.Exists(const AName: string): Boolean;
begin
  Result := SameText(AName, Name);
end;

function TFakeFiles.ReadAll(const AName: string): TBytes;
begin
  Result := Bytes;
end;

{ TTestGreedMapLoader }

procedure TTestGreedMapLoader.Setup;
begin
  FArchive := TGreedTestArchive.Open;
end;

procedure TTestGreedMapLoader.TearDown;
begin
  FArchive := nil;
end;

procedure TTestGreedMapLoader.DovrebbeLeggereLaMappaDalLumpChePassaLaPrima;
var
  LMap: IGreedMap;
begin
  // "map" is the lump 1: the map 0 is the lump 2
  LMap := TGreedFactory.CreateMapLoader(FArchive, nil).Load(0);
  Assert.AreEqual(5, Integer(LMap.Planes[gpNorthWall][5]));
  Assert.AreEqual(3, Length(LMap.Trailer));
end;

procedure TTestGreedMapLoader.DovrebbeLeggereLaMappaDalFileSeIlLumpEVuoto;
var
  LFiles: TFakeFiles;
  LFilesIntf: IGreedExternalFiles;
  LMap: IGreedMap;
begin
  LFiles := TFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Name := 'LEVEL2.LAY';
  LFiles.Bytes := TGreedLumps.MapBytes(nil);
  LFiles.Bytes[0] := 111;
  LMap := TGreedFactory.CreateMapLoader(FArchive, LFilesIntf).Load(1);
  Assert.AreEqual(111, Integer(LMap.Planes[gpNorthWall][0]));
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnaMappaCheNonCe;
var
  LLoader: IGreedMapLoader;
begin
  LLoader := TGreedFactory.CreateMapLoader(FArchive, nil);
  Assert.WillRaise(procedure begin LLoader.Load(-1); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin LLoader.Load(TGreedTestArchive.LUMP_COUNT); end, EGreedNotFoundException);
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnLumpVuotoSenzaFile;
var
  LLoader: IGreedMapLoader;
begin
  LLoader := TGreedFactory.CreateMapLoader(FArchive, nil);
  Assert.WillRaise(procedure begin LLoader.Load(1); end, EGreedNotFoundException);
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnLumpVuotoSeIlFileNonCe;
var
  LLoader: IGreedMapLoader;
begin
  LLoader := TGreedFactory.CreateMapLoader(FArchive, TFakeFiles.Create);
  Assert.WillRaise(procedure begin LLoader.Load(1); end, EGreedNotFoundException);
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnArchivioSenzaIlLumpMap;
var
  LBlo: TGreedBlo;
  LLoader: IGreedMapLoader;
begin
  LBlo := TGreedBlo.Create;
  try
    LLoader := TGreedFactory.CreateMapLoader(LBlo.Add('x', nil).Open, nil);
  finally
    LBlo.Free;
  end;
  Assert.WillRaise(procedure begin LLoader.Load(0); end, EGreedNotFoundException);
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnFileCortoDiUnLumpVuoto;
var
  LFiles: TFakeFiles;
  LFilesIntf: IGreedExternalFiles;
  LLoader: IGreedMapLoader;
begin
  LFiles := TFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Name := 'level2.lay';
  LFiles.Bytes := TBytes.Create(1, 2, 3);
  LLoader := TGreedFactory.CreateMapLoader(FArchive, LFilesIntf);
  Assert.WillRaise(procedure begin LLoader.Load(1); end, EGreedDataException);
end;

procedure TTestGreedMapLoader.DovrebbeRifiutareUnFileDiUnAltroFormato;
var
  LFiles: TFakeFiles;
  LFilesIntf: IGreedExternalFiles;
  LLoader: IGreedMapLoader;
begin
  // the .LVL of the demo 1.016 has 143360 bytes: a layout that the reader does not know
  LFiles := TFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Name := 'level2.lay';
  SetLength(LFiles.Bytes, 143360);
  LLoader := TGreedFactory.CreateMapLoader(FArchive, LFilesIntf);
  Assert.WillRaise(procedure begin LLoader.Load(1); end, EGreedDataException);
end;

procedure TTestGreedMapLoader.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(procedure begin TGreedMapLoader.Create(nil, TGreedFactory.CreateMapReader, nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedMapLoader.Create(FArchive, nil, nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedMapLoader);

end.
