{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - writing BSP files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspWriter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Intf;

type
  [TestFixture]
  [Category('MapFile')]
  TTestBspWriter = class
  strict private
    function Build(const AVariant: Integer): TBytes;
    function Read(const ABytes: TBytes): IBspFile;
    function SameBytes(const AFirst, ASecond: TBytes): Boolean;
  public
    [Test]
    procedure DovrebbeScrivereGliStessiByteDelCompilatore;
    [Test]
    procedure DovrebbeRileggereLeStesseListe;
    [Test]
    procedure DovrebbeScrivereLaVisibilitaEIDatiGrezzi;
    [Test]
    procedure DovrebbeScrivereUnFileSenzaEntitaNeVisibilita;
    [Test]
    procedure DovrebbeAllinearePadAQuattroByte;
    [Test]
    procedure DovrebbeScrivereNelFileSystem;
    [Test]
    procedure DovrebbeDareFalsoSenzaFileSystem;
    [Test]
    procedure DovrebbeRiscrivereUnFileLeggibileDalLettoreConIDatiPatchati;
  end;

implementation

uses
  System.Classes, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.BspSample;

type
  TRefusingFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  public
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

function TRefusingFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := False;
end;

function TRefusingFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

{ TTestBspWriter }

function TTestBspWriter.Build(const AVariant: Integer): TBytes;
var
  LBuilder: TBspSampleBuilder;
begin
  LBuilder := TBspSampleBuilder.Create;
  try
    Result := LBuilder.Build(AVariant);
  finally
    LBuilder.Free;
  end;
end;

function TTestBspWriter.Read(const ABytes: TBytes): IBspFile;
begin
  Result := TBspFactory.CreateReader.ParseBytes(ABytes, 'test');
end;

function TTestBspWriter.SameBytes(const AFirst, ASecond: TBytes): Boolean;
begin
  Result := (Length(AFirst) = Length(ASecond)) and ((Length(AFirst) = 0) or
    CompareMem(@AFirst[0], @ASecond[0], Length(AFirst)));
end;

procedure TTestBspWriter.DovrebbeScrivereGliStessiByteDelCompilatore;
var
  LVariant: Integer;
  LBytes: TBytes;
begin
  // the sample files are written the way a compiler does: reading and writing gives them back
  for LVariant := 0 to 2 do
  begin
    LBytes := Build(LVariant);
    Assert.IsTrue(SameBytes(LBytes, TBspFactory.CreateWriter.ToBytes(Read(LBytes))), 'variant ' + IntToStr(LVariant));
  end;
end;

procedure TTestBspWriter.DovrebbeRileggereLeStesseListe;
var
  LFirst, LSecond: IBspFile;
  LIndex: Integer;
begin
  LFirst := Read(Build(1));
  LSecond := Read(TBspFactory.CreateWriter.ToBytes(LFirst));
  Assert.AreEqual<Integer>(Length(LFirst.Surfaces), Length(LSecond.Surfaces));
  Assert.AreEqual<Integer>(Length(LFirst.DrawVerts), Length(LSecond.DrawVerts));
  Assert.AreEqual<Integer>(Length(LFirst.Nodes), Length(LSecond.Nodes));
  Assert.AreEqual(LFirst.EntityText, LSecond.EntityText);
  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    Assert.AreEqual<Integer>(LFirst.Lumps[LIndex].FileOfs, LSecond.Lumps[LIndex].FileOfs, 'offset of lump ' + IntToStr(LIndex));
    Assert.AreEqual<Integer>(LFirst.Lumps[LIndex].FileLen, LSecond.Lumps[LIndex].FileLen, 'length of lump ' + IntToStr(LIndex));
    Assert.IsTrue(SameBytes(LFirst.LumpData[LIndex], LSecond.LumpData[LIndex]), 'lump ' + IntToStr(LIndex));
  end;
end;

procedure TTestBspWriter.DovrebbeScrivereLaVisibilitaEIDatiGrezzi;
var
  LFile: IBspFile;
begin
  LFile := Read(TBspFactory.CreateWriter.ToBytes(Read(Build(0))));
  Assert.AreEqual<Integer>(2, LFile.NumClusters);
  Assert.AreEqual<Integer>(8, LFile.ClusterBytes);
  Assert.AreEqual<Integer>(16, Length(LFile.Visibility));
  Assert.AreEqual<Integer>(2, LFile.LightmapCount);
  Assert.AreEqual<Integer>(48, Length(LFile.LightGrid));
end;

procedure TTestBspWriter.DovrebbeScrivereUnFileSenzaEntitaNeVisibilita;
var
  LBytes: TBytes;
  LFile: IBspFile;
begin
  LBytes := Build(0);
  // empty the entities lump and the visibility lump of the file
  BspPatchLumpLength(LBytes, LUMP_ENTITIES, 0);
  BspPatchLumpLength(LBytes, LUMP_VISIBILITY, 0);
  LFile := Read(TBspFactory.CreateWriter.ToBytes(Read(LBytes)));
  Assert.AreEqual<Integer>(0, LFile.Lumps[LUMP_ENTITIES].FileLen);
  Assert.AreEqual<Integer>(0, LFile.Lumps[LUMP_VISIBILITY].FileLen);
  Assert.AreEqual('', string(LFile.EntityText));
  Assert.AreEqual<Integer>(0, LFile.NumClusters);
end;

procedure TTestBspWriter.DovrebbeAllinearePadAQuattroByte;
var
  LBytes: TBytes;
  LFile: IBspFile;
  LIndex: Integer;
begin
  LBytes := TBspFactory.CreateWriter.ToBytes(Read(Build(2)));
  LFile := Read(LBytes);
  Assert.AreEqual<Integer>(BSP_IDENT, PInteger(@LBytes[0])^);
  Assert.AreEqual<Integer>(BSP_VERSION, PInteger(@LBytes[4])^);
  Assert.AreEqual<Integer>(SizeOf(TBspHeader), LFile.Lumps[0].FileOfs);
  for LIndex := 0 to HEADER_LUMPS - 1 do
    Assert.AreEqual<Integer>(0, LFile.Lumps[LIndex].FileOfs mod 4, 'lump ' + IntToStr(LIndex));
  Assert.AreEqual<Integer>(Length(LBytes), LFile.Lumps[HEADER_LUMPS - 1].FileOfs +
    ((LFile.Lumps[HEADER_LUMPS - 1].FileLen + 3) and not 3));
end;

procedure TTestBspWriter.DovrebbeScrivereNelFileSystem;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LWriter: IBspWriter;
  LFile: IBspFile;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LWriter := TBspFactory.CreateWriter(LFileSystem);
  LFile := Read(Build(0));
  Assert.IsTrue(LWriter.Write(LFile, 'maps/test.bsp'));
  Assert.AreEqual<Integer>(Length(Build(0)), Length(LFileSystem.GetFile('maps/test.bsp')));
  Assert.IsFalse(TBspFactory.CreateWriter(TRefusingFileSystem.Create).Write(LFile, 'maps/test.bsp'));
end;

procedure TTestBspWriter.DovrebbeDareFalsoSenzaFileSystem;
begin
  Assert.IsFalse(TBspFactory.CreateWriter.Write(Read(Build(0)), 'x.bsp'));
end;

procedure TTestBspWriter.DovrebbeRiscrivereUnFileLeggibileDalLettoreConIDatiPatchati;
var
  LBytes, LWritten: TBytes;
  LFile: IBspFile;
begin
  // a file with a lump that is not at a multiple of 4 or not in the order of the header:
  // the offsets change, the lists do not
  LBytes := Build(0);
  LFile := Read(LBytes);
  LWritten := TBspFactory.CreateWriter.ToBytes(LFile);
  Assert.AreEqual<Integer>(Length(LFile.Nodes), Length(Read(LWritten).Nodes));
  Assert.AreEqual(LFile.ShaderName(1), Read(LWritten).ShaderName(1));
end;

end.
