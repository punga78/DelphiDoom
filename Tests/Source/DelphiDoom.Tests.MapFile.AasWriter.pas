{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - writing .aas files, with the    }
{  parity of the real idAASFileLocal::Write of Doom 3 (aas_write.golden.txt)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.AasWriter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>A file system that cannot write</summary>
  TAasReadOnlyFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  public
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('MapFile')]
  TTestAasFileWriter = class
  strict private
    FWriter: IAasFileWriter;
    FReader: IAasFileReader;
    function DataFolder: string;
    function LoadData(const AName: string): AnsiString;
    function Escaped(const AText: AnsiString): TStringList;
    procedure CompareWithGolden(const AGolden, AActual: TStringList; const AWhat: string);
    function GoldenBlock(const ALines: TStringList; const ACase, ATag: string): TStringList;
  public
    [Setup]
    procedure Setup;
    /// <summary>
    ///   aas_write.golden.txt is what the real idAASFileLocal::Write prints for the files of
    ///   aas_sample_cases.txt, and for the file it wrote read and written once more
    /// </summary>
    [Test]
    procedure DovrebbeScrivereGliStessiByteDelVeroIdlib;
    [Test]
    procedure DovrebbeScrivereIlFileNelFileSystem;
    [Test]
    procedure DovrebbeDareALFileIlNomeEIlCrcScritti;
    [Test]
    procedure DovrebbeRifiutareUnFileSystemCheNonScrive;
    [Test]
    procedure DovrebbeScrivereUnFileVuotoConLeImpostazioniPredefinite;
    [Test]
    procedure DovrebbeScrivereIFloatSenzaZeriInutili;
    [Test]
    procedure DovrebbeScrivereLaDistanzaDeiPianiNonIlD;
    [Test]
    procedure DovrebbeScrivereLeCoppieDiUnaReachabilitySpeciale;
    [Test]
    procedure DovrebbeInvertireLOrdineDelleReachabilityADogniGiro;
    [Test]
    procedure DovrebbeRileggereIlModelloScritto;
    [Test]
    procedure DovrebbeCrearePerMezzoDellaFactory;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.MapFile.Aas.Factory, DelphiDoom.Tests.IdLib.Fakes;

{ TAasReadOnlyFileSystem }

function TAasReadOnlyFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := False;
end;

function TAasReadOnlyFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

{ TTestAasFileWriter }

procedure TTestAasFileWriter.Setup;
var
  LFileSystem: IIdLibFileSystem;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  FWriter := TAasFileFactory.CreateWriter(LFileSystem);
  FReader := TAasFileFactory.CreateReader(nil);
end;

function TTestAasFileWriter.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\MapFile\');
end;

function TTestAasFileWriter.LoadData(const AName: string): AnsiString;
var
  LBytes: TBytes;
begin
  Assert.IsTrue(TFile.Exists(DataFolder + AName), AName + ' not found in ' + DataFolder);
  LBytes := TFile.ReadAllBytes(DataFolder + AName);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

function TTestAasFileWriter.Escaped(const AText: AnsiString): TStringList;
var
  LLine: string;
  LIndex: Integer;
  LCode: Integer;
begin
  Result := TStringList.Create;
  Result.TrailingLineBreak := False;
  LLine := '';
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Ord(AText[LIndex]);
    case LCode of
      10:
        begin
          Result.Add(LLine);
          LLine := '';
        end;
      9: LLine := LLine + '\t';
      13: LLine := LLine + '\r';
      92: LLine := LLine + '\\';
    else
      if (LCode < 32) or (LCode > 126) then
        LLine := LLine + '\x' + UpperCase(IntToHex(LCode, 2))
      else
        LLine := LLine + Char(LCode);
    end;
  end;
  if LLine <> '' then
    Result.Add(LLine);
end;

function TTestAasFileWriter.GoldenBlock(const ALines: TStringList; const ACase, ATag: string): TStringList;
var
  LIndex: Integer;
  LInCase: Boolean;
  LInBlock: Boolean;
begin
  Result := TStringList.Create;
  LInCase := False;
  LInBlock := False;
  for LIndex := 0 to ALines.Count - 1 do
  begin
    if ALines[LIndex].StartsWith('CASE ') then
    begin
      LInCase := ALines[LIndex] = 'CASE ' + ACase;
      LInBlock := False;
    end
    else if ALines[LIndex].StartsWith('WRITE') then
      LInBlock := LInCase and ALines[LIndex].StartsWith(ATag + ' ')
    else if LInBlock and ALines[LIndex].StartsWith('T|') then
      Result.Add(Copy(ALines[LIndex], 3, MaxInt));
  end;
end;

procedure TTestAasFileWriter.CompareWithGolden(const AGolden, AActual: TStringList; const AWhat: string);
var
  LIndex: Integer;
begin
  Assert.IsTrue(AGolden.Count > 20, 'no golden lines for ' + AWhat);
  Assert.AreEqual<Integer>(AGolden.Count, AActual.Count, AWhat + ': number of lines');
  for LIndex := 0 to AGolden.Count - 1 do
    Assert.AreEqual(AGolden[LIndex], AActual[LIndex], Format('%s line %d', [AWhat, LIndex + 1]));
end;

procedure TTestAasFileWriter.DovrebbeScrivereGliStessiByteDelVeroIdlib;
const
  CRC = 3000000000;
var
  LGolden, LCases, LActual, LExpected: TStringList;
  LName, LCase, LText: string;
  LFile: TAasFile;
begin
  LGolden := TStringList.Create;
  LCases := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(DataFolder + 'aas_write.golden.txt'), 'aas_write.golden.txt not found');
    LGolden.LoadFromFile(DataFolder + 'aas_write.golden.txt');
    LCases.LoadFromFile(DataFolder + 'aas_sample_cases.txt');
    for LCase in LCases do
    begin
      LName := Trim(LCase);
      if (LName = '') or LName.StartsWith('#') then
        Continue;
      LFile := FReader.ParseText(LoadData(LName), AnsiString(LName));
      try
        LText := string(FWriter.ToText(LFile, CRC));
      finally
        LFile.Free;
      end;
      LExpected := GoldenBlock(LGolden, LName, 'WRITE1');
      LActual := Escaped(AnsiString(LText));
      try
        CompareWithGolden(LExpected, LActual, LName + ' (1st write)');
      finally
        LExpected.Free;
        LActual.Free;
      end;
      // the file that was written, read and written again (the reachabilities turn over)
      LFile := FReader.ParseText(AnsiString(LText), AnsiString(LName));
      try
        LText := string(FWriter.ToText(LFile, CRC));
      finally
        LFile.Free;
      end;
      LExpected := GoldenBlock(LGolden, LName, 'WRITE2');
      LActual := Escaped(AnsiString(LText));
      try
        CompareWithGolden(LExpected, LActual, LName + ' (2nd write)');
      finally
        LExpected.Free;
        LActual.Free;
      end;
    end;
  finally
    LCases.Free;
    LGolden.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeScrivereIlFileNelFileSystem;
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFile: TAasFile;
  LWriter: IAasFileWriter;
begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LWriter := TAasFileFactory.CreateWriter(LFileSystem);
  LFile := TAasFile.Create;
  try
    Assert.IsTrue(LWriter.Write(LFile, 'maps/test.aas48', 7));
    Assert.AreEqual(LWriter.ToText(LFile, 7), LFileSystem.GetFile('maps/test.aas48'));
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeDareALFileIlNomeEIlCrcScritti;
var
  LFile: TAasFile;
begin
  LFile := TAasFile.Create;
  try
    FWriter.Write(LFile, 'x.aas32', 99);
    Assert.AreEqual('x.aas32', string(LFile.Name));
    Assert.AreEqual<Cardinal>(99, LFile.Crc);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeRifiutareUnFileSystemCheNonScrive;
var
  LFile: TAasFile;
  LWriter: IAasFileWriter;
  LRaised: Boolean;
  LMessage: string;
begin
  LWriter := TAasFileFactory.CreateWriter(TAasReadOnlyFileSystem.Create);
  LFile := TAasFile.Create;
  try
    LRaised := False;
    try
      LWriter.Write(LFile, 'x.aas48', 0);
    except
      on E: EAasFileException do
      begin
        LRaised := True;
        LMessage := E.Message;
      end;
    end;
    Assert.IsTrue(LRaised);
    Assert.Contains(LMessage, 'x.aas48');
  finally
    LFile.Free;
  end;
  // without a file system only ToText can be used
  LWriter := TAasFileFactory.CreateWriter(nil);
  LFile := TAasFile.Create;
  try
    Assert.IsTrue(LWriter.ToText(LFile, 0) <> '');
    LRaised := False;
    try
      LWriter.Write(LFile, 'y.aas48', 0);
    except
      on E: EAasFileException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeScrivereUnFileVuotoConLeImpostazioniPredefinite;
var
  LFile: TAasFile;
  LLines: TStringList;
begin
  LFile := TAasFile.Create;
  try
    LLines := Escaped(FWriter.ToText(LFile, 5));
    try
      Assert.AreEqual('DewmAAS "1.07"', LLines[0]);
      Assert.AreEqual('', LLines[1]);
      Assert.AreEqual('5', LLines[2]);
      Assert.AreEqual('settings', LLines[4]);
      Assert.AreEqual('\t\t(-16 -16 0)-(16 16 72)', LLines[8]);
      Assert.AreEqual('\tgravity = (0 0 -1066)', LLines[16]);
      Assert.AreEqual('\ttt_startWalkOffLedge = 100', LLines[25]);
      Assert.AreEqual('planes 0 {', LLines[27]);
      Assert.AreEqual('clusters 0 {', LLines[LLines.Count - 2]);
    finally
      LLines.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeScrivereIFloatSenzaZeriInutili;
var
  LFile: TAasFile;
  LLines: TStringList;
begin
  LFile := TAasFile.Create;
  try
    LFile.Settings.MaxStepHeight := 18.0;
    LFile.Settings.MinFloorCos := 0.7;
    LLines := Escaped(FWriter.ToText(LFile, 0));
    try
      Assert.AreEqual('\tmaxStepHeight = 18', LLines[17]);
      // 0.7 as a float is 0.699999988..., written with ten decimals
      Assert.AreEqual('\tminFloorCos = 0.6999999881', LLines[21]);
    finally
      LLines.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeScrivereLaDistanzaDeiPianiNonIlD;
var
  LFile: TAasFile;
  LPlane: TGeoPlane;
  LText: AnsiString;
begin
  LFile := TAasFile.Create;
  try
    LPlane := TGeoPlane.Make(1, 0, 0, 0);
    LPlane.SetDist(64);
    LFile.Planes := [LPlane];
    LText := FWriter.ToText(LFile, 0);
    Assert.IsTrue(Pos(AnsiString('planes 1 {'#10#9'0 ( 1 0 0 64 )'#10'}'), LText) > 0);
    Assert.AreEqual<Single>(-64, LPlane.D);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeScrivereLeCoppieDiUnaReachabilitySpeciale;
var
  LFile: TAasFile;
  LArea: TAasArea;
  LReach: TAasReachability;
  LText: AnsiString;
begin
  LFile := TAasFile.Create;
  try
    LArea := TAasArea.Create;
    LFile.Areas.Add(LArea);
    LReach := TAasReachability.Create;
    LArea.Reach.Add(LReach);
    LReach.TravelType := TFL_SPECIAL;
    LReach.ToAreaNum := 0;
    LReach.EnsureSpecial.SetValue('Key', 'va lue');
    LText := FWriter.ToText(LFile, 0);
    Assert.IsTrue(Pos(AnsiString('{'#10#9#9#9'"Key" "va lue"'#10#9#9'}'#10), LText) > 0);
    // a travel type that is not special gets no pair, even if the object has some
    LReach.TravelType := TFL_WALK;
    LText := FWriter.ToText(LFile, 0);
    Assert.AreEqual(0, Pos(AnsiString('"Key"'), LText));
    // a special one without any pair
    LReach.TravelType := TFL_SPECIAL;
    LReach.EnsureSpecial.Clear;
    Assert.IsTrue(Pos(AnsiString('{'#10#9#9'}'#10), FWriter.ToText(LFile, 0)) > 0);
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeInvertireLOrdineDelleReachabilityADogniGiro;
var
  LFile, LBack: TAasFile;
  LText: AnsiString;
begin
  LFile := FReader.ParseText(LoadData('aas_walk.aas'), 'aas_walk.aas');
  try
    // the area 2 has the file order 1, 3: the chain (the model) has 3, 1
    Assert.AreEqual<Integer>(3, LFile.Areas[2].Reach[0].ToAreaNum);
    LText := FWriter.ToText(LFile, 1);
    LBack := FReader.ParseText(LText, 'again');
    try
      Assert.AreEqual<Integer>(1, LBack.Areas[2].Reach[0].ToAreaNum);
      Assert.AreEqual<Integer>(3, LBack.Areas[2].Reach[1].ToAreaNum);
    finally
      LBack.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeRileggereIlModelloScritto;
var
  LFile, LBack: TAasFile;
  LIndex: Integer;
begin
  LFile := FReader.ParseText(LoadData('aas_rooms.aas'), 'aas_rooms.aas');
  try
    LBack := FReader.ParseText(FWriter.ToText(LFile, 2882400001), 'back', 2882400001);
    try
      Assert.AreEqual<Integer>(LFile.NumPlanes, LBack.NumPlanes);
      Assert.AreEqual<Integer>(LFile.NumVertices, LBack.NumVertices);
      Assert.AreEqual<Integer>(LFile.NumEdges, LBack.NumEdges);
      Assert.AreEqual<Integer>(LFile.NumFaces, LBack.NumFaces);
      Assert.AreEqual<Integer>(LFile.NumAreas, LBack.NumAreas);
      Assert.AreEqual<Integer>(LFile.NumNodes, LBack.NumNodes);
      Assert.AreEqual<Integer>(LFile.NumReachabilities, LBack.NumReachabilities);
      Assert.AreEqual<Integer>(LFile.NumClusters, LBack.NumClusters);
      Assert.AreEqual<Integer>(LFile.Settings.NumBoundingBoxes, LBack.Settings.NumBoundingBoxes);
      for LIndex := 0 to LFile.NumPlanes - 1 do
        Assert.IsTrue(LFile.Planes[LIndex].Compare(LBack.Planes[LIndex]), 'plane ' + IntToStr(LIndex));
      for LIndex := 0 to LFile.NumFaces - 1 do
        Assert.AreEqual<Integer>(LFile.Faces[LIndex].FirstEdge, LBack.Faces[LIndex].FirstEdge);
      Assert.AreEqual<Single>(LFile.Areas[2].Bounds.Maxs.X, LBack.Areas[2].Bounds.Maxs.X);
    finally
      LBack.Free;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TTestAasFileWriter.DovrebbeCrearePerMezzoDellaFactory;
begin
  Assert.IsNotNull(TAasFileFactory.CreateWriter(nil));
  Assert.IsNotNull(TAasFileFactory.CreateWriter(TIdLibMemoryFileSystem.Create, TIdLibLogRecorder.Create));
end;

end.
