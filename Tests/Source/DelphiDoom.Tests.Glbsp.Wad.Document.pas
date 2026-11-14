{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the WAD model of the glbsp port                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Wad.Document;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump,
  DelphiDoom.Glbsp.Wad.Types;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspWadDocument = class(TObject)
  private
    FWad: TGlbspWad;
    FInput: TBytesStream;
    function BuildWad(const ANames: array of AnsiString): TBytesStream;
    procedure Load(const AStream: TBytesStream; const ALoadAll, AGwaMode: Boolean);
    function DirectoryNames(const AWad: TGlbspWad): string;
    function WriteToBytes: TBytes;
    // The name of a directory entry: up to 8 characters, ended by the first #0
    class function EntryName(const AEntry: TRawWadEntry): string; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLeggeUnLivelloCompleto;
    [Test]
    procedure TestIlSecondoLivelloNonEsiste;
    [Test]
    procedure TestMagicErratoSollevaEccezione;
    [Test]
    procedure TestIntestazioneTroncataSollevaEccezione;
    [Test]
    procedure TestLumpDelLivelloHannoLeDimensioniAttese;
    [Test]
    procedure TestRiscritturaRilegge;
    [Test]
    procedure TestRiscritturaConLumpDaCopiare;
    [Test]
    procedure TestLumpGLPrecedentiSonoScartati;
    [Test]
    procedure TestLumpDuplicatoDelLivelloEIgnorato;
    [Test]
    procedure TestLumpNonDelLivelloTerminaIlLivello;
    [Test]
    procedure TestNomeLungoGeneraMarcatoreGLLevel;
    [Test]
    procedure TestLumpGLSonoOrdinatiInScrittura;
    [Test]
    procedure TestModalitaGwaScriveSoloIlNuovo;
    [Test]
    procedure TestNomiDellaDirectorySonoOttoByteRiempitiDiZeri;
    [Test]
    procedure TestCreaLumpEsistenteLoSvuota;
    [Test]
    procedure TestAllineamentoA4Byte;
    [Test]
    procedure TestSegnalazioneLimitiZdbsp;
  end;

implementation

const
  BASIC_LEVEL: array[0..8] of AnsiString = ('MAP01', 'THINGS', 'LINEDEFS',
    'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS', 'NODES', 'SECTORS');

function MapSamplePath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\glbsp_map01.wad'));
end;

{ TTestGlbspWadDocument }

class function TTestGlbspWadDocument.EntryName(const AEntry: TRawWadEntry): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to WAD_LUMP_NAME_SIZE - 1 do
  begin
    if AEntry.Name[LIndex] = #0 then
      Break;
    Result := Result + string(AEntry.Name[LIndex]);
  end;
end;

procedure TTestGlbspWadDocument.Setup;
begin
  FWad := TGlbspWad.Create;
end;

procedure TTestGlbspWadDocument.TearDown;
begin
  FWad.Free;
  FInput.Free;
  FInput := nil;
end;

// Builds a PWAD whose lumps hold three bytes each, so that the length is not
// aligned; the data is made of the first letters of the name of the lump
function TTestGlbspWadDocument.BuildWad(const ANames: array of AnsiString): TBytesStream;
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex: Integer;
  LCharIndex: Integer;
  LData: TBytes;
  LPositions: array of Integer;
begin
  Result := TBytesStream.Create;
  LHeader.MagicType := 'PWAD';
  LHeader.NumEntries := Length(ANames);
  LHeader.DirStart := 0;
  Result.WriteBuffer(LHeader, SizeOf(LHeader));
  SetLength(LPositions, Length(ANames));
  SetLength(LData, 3);
  for LIndex := 0 to High(ANames) do
  begin
    LPositions[LIndex] := Result.Position;
    for LCharIndex := 0 to 2 do
      LData[LCharIndex] := Byte(ANames[LIndex][1 + (LCharIndex mod Length(ANames[LIndex]))]);
    Result.WriteBuffer(LData[0], 3);
  end;
  LHeader.DirStart := Result.Position;
  for LIndex := 0 to High(ANames) do
  begin
    FillChar(LEntry, SizeOf(LEntry), 0);
    LEntry.Start := LPositions[LIndex];
    LEntry.Length := 3;
    for LCharIndex := 1 to Length(ANames[LIndex]) do
      LEntry.Name[LCharIndex - 1] := ANames[LIndex][LCharIndex];
    Result.WriteBuffer(LEntry, SizeOf(LEntry));
  end;
  Result.Position := 0;
  Result.WriteBuffer(LHeader, SizeOf(LHeader));
  Result.Position := 0;
end;

procedure TTestGlbspWadDocument.Load(const AStream: TBytesStream; const ALoadAll,
  AGwaMode: Boolean);
begin
  FInput := AStream;
  FWad.ReadFromStream(FInput, ALoadAll, AGwaMode);
end;

function TTestGlbspWadDocument.DirectoryNames(const AWad: TGlbspWad): string;
var
  LLump: TGlbspLump;
  LChild: TGlbspLump;
begin
  Result := '';
  for LLump in AWad.Directory do
  begin
    Result := Result + string(LLump.Name) + ' ';
    if Assigned(LLump.LevelInfo) then
    begin
      for LChild in LLump.LevelInfo.Children do
        Result := Result + string(LChild.Name) + ' ';
    end;
  end;
  Result := Trim(Result);
end;

function TTestGlbspWadDocument.WriteToBytes: TBytes;
var
  LOutput: TBytesStream;
begin
  LOutput := TBytesStream.Create;
  try
    FWad.WriteToStream(LOutput);
    Result := Copy(LOutput.Bytes, 0, LOutput.Size);
  finally
    LOutput.Free;
  end;
end;

procedure TTestGlbspWadDocument.TestLeggeUnLivelloCompleto;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);

  Assert.AreEqual(1, FWad.CountLevels);
  Assert.AreEqual(9, FWad.NumEntries);
  Assert.AreEqual(1, FWad.LevelNames.Count);
  Assert.AreEqual('MAP01', FWad.LevelNames[0]);
  Assert.IsTrue(FWad.FindNextLevel);
  Assert.AreEqual('MAP01', string(FWad.GetLevelName));
  Assert.IsNotNull(FWad.FindLevelLump('VERTEXES'));
  Assert.IsNull(FWad.FindLevelLump('REJECT'));
end;

procedure TTestGlbspWadDocument.TestIlSecondoLivelloNonEsiste;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);

  Assert.IsTrue(FWad.FindNextLevel);
  Assert.IsFalse(FWad.FindNextLevel);
  Assert.IsNull(FWad.CurrentLevel);
end;

procedure TTestGlbspWadDocument.TestMagicErratoSollevaEccezione;
var
  LStream: TBytesStream;
begin
  LStream := BuildWad(BASIC_LEVEL);
  LStream.Bytes[0] := Ord('X');
  FInput := LStream;

  Assert.WillRaise(
    procedure
    begin
      FWad.ReadFromStream(LStream, True, False);
    end, EGlbspWadException);
end;

procedure TTestGlbspWadDocument.TestIntestazioneTroncataSollevaEccezione;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create(TBytes.Create(Ord('P'), Ord('W'), Ord('A')));
  FInput := LStream;

  Assert.WillRaise(
    procedure
    begin
      FWad.ReadFromStream(LStream, True, False);
    end, EGlbspWadException);
end;

procedure TTestGlbspWadDocument.TestLumpDelLivelloHannoLeDimensioniAttese;
var
  LStream: TFileStream;
  LBytes: TBytesStream;
begin
  if not TFile.Exists(MapSamplePath) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found: ' + MapSamplePath);
    Exit;
  end;
  LBytes := TBytesStream.Create;
  LStream := TFileStream.Create(MapSamplePath, fmOpenRead or fmShareDenyNone);
  try
    LBytes.CopyFrom(LStream, 0);
  finally
    LStream.Free;
  end;
  Load(LBytes, True, False);

  Assert.AreEqual(1, FWad.CountLevels);
  Assert.IsTrue(FWad.FindNextLevel);
  Assert.AreEqual(2000, FWad.FindLevelLump('THINGS').Length);
  Assert.AreEqual(17836, FWad.FindLevelLump('LINEDEFS').Length);
  Assert.AreEqual(61230, FWad.FindLevelLump('SIDEDEFS').Length);
  Assert.AreEqual(4756, FWad.FindLevelLump('VERTEXES').Length);
  Assert.AreEqual(5486, FWad.FindLevelLump('SECTORS').Length);
  Assert.AreEqual(6304, FWad.FindLevelLump('BLOCKMAP').Length);
  Assert.AreEqual(0, FWad.Warnings.Count);
end;

procedure TTestGlbspWadDocument.TestRiscritturaRilegge;
var
  LOutput: TBytes;
  LSecond: TGlbspWad;
  LStream: TBytesStream;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);
  LOutput := WriteToBytes;

  LSecond := TGlbspWad.Create;
  LStream := TBytesStream.Create(LOutput);
  try
    LSecond.ReadFromStream(LStream, True, False);
    Assert.AreEqual(FWad.Directory.Count, LSecond.Directory.Count);
    Assert.AreEqual(9, LSecond.NumEntries);
    LSecond.FindNextLevel;
    Assert.AreEqual(3, LSecond.FindLevelLump('SEGS').Length);
    Assert.AreEqual(Ord('S'), Integer(LSecond.FindLevelLump('SEGS').Data[0]));
  finally
    LStream.Free;
    LSecond.Free;
  end;
end;

procedure TTestGlbspWadDocument.TestRiscritturaConLumpDaCopiare;
var
  LOutput: TBytes;
  LSecond: TGlbspWad;
  LStream: TBytesStream;
begin
  // Without loading the lumps they are copied from the input at write time
  Load(BuildWad(BASIC_LEVEL), False, False);
  LOutput := WriteToBytes;

  LSecond := TGlbspWad.Create;
  LStream := TBytesStream.Create(LOutput);
  try
    LSecond.ReadFromStream(LStream, True, False);
    LSecond.FindNextLevel;
    Assert.AreEqual(Ord('N'), Integer(LSecond.FindLevelLump('NODES').Data[0]));
  finally
    LStream.Free;
    LSecond.Free;
  end;
end;

procedure TTestGlbspWadDocument.TestLumpGLPrecedentiSonoScartati;
begin
  Load(BuildWad(['MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES',
    'GL_MAP01', 'GL_VERT', 'GL_SEGS', 'MUSIC']), True, False);

  Assert.AreEqual(6, FWad.NumEntries);
  Assert.AreEqual('MAP01 VERTEXES SIDEDEFS LINEDEFS THINGS MUSIC', DirectoryNames(FWad));
end;

procedure TTestGlbspWadDocument.TestLumpDuplicatoDelLivelloEIgnorato;
begin
  Load(BuildWad(['MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'THINGS']),
    True, False);

  Assert.AreEqual(5, FWad.NumEntries);
  Assert.AreEqual(1, FWad.Warnings.Count);
  Assert.Contains(FWad.Warnings[0], 'Duplicate entry ''THINGS'' ignored in MAP01');
end;

procedure TTestGlbspWadDocument.TestLumpNonDelLivelloTerminaIlLivello;
begin
  Load(BuildWad(['MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'PLAYPAL',
    'SEGS']), True, False);

  Assert.AreEqual(7, FWad.NumEntries);
  Assert.AreEqual(1, FWad.Warnings.Count);
  Assert.Contains(FWad.Warnings[0], 'Level lump ''SEGS'' found outside any level');
  Assert.AreEqual('MAP01 VERTEXES SIDEDEFS LINEDEFS THINGS PLAYPAL SEGS',
    DirectoryNames(FWad));
end;

procedure TTestGlbspWadDocument.TestNomeLungoGeneraMarcatoreGLLevel;
var
  LMarker: TGlbspLump;
begin
  Load(BuildWad(['MYLEVEL', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES']), True, False);
  FWad.FindNextLevel;

  FWad.CreateGLLump('GL_VERT');

  // "LEVEL=MYLEVEL" and a line feed
  LMarker := FWad.Directory[1];
  Assert.AreEqual('GL_LEVEL', string(LMarker.Name));
  Assert.AreEqual(14, LMarker.Length);
  Assert.AreEqual(Ord('L'), Integer(LMarker.Data[0]));
  Assert.AreEqual(10, Integer(LMarker.Data[13]));
end;

procedure TTestGlbspWadDocument.TestLumpGLSonoOrdinatiInScrittura;
var
  LOutput: TBytes;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);
  FWad.FindNextLevel;
  FWad.CreateGLLump('GL_PVS');
  FWad.CreateGLLump('GL_NODES');
  FWad.CreateGLLump('GL_SSECT');
  FWad.CreateGLLump('GL_SEGS');
  FWad.CreateGLLump('GL_VERT');

  LOutput := WriteToBytes;

  Assert.IsTrue(Length(LOutput) > 0);
  Assert.AreEqual(15, FWad.NumEntries);
  Assert.AreEqual(
    'MAP01 THINGS LINEDEFS SIDEDEFS VERTEXES SEGS SSECTORS NODES SECTORS ' +
    'GL_MAP01 GL_VERT GL_SEGS GL_SSECT GL_NODES GL_PVS', DirectoryNames(FWad));
end;

procedure TTestGlbspWadDocument.TestModalitaGwaScriveSoloIlNuovo;
var
  LOutput: TBytes;
  LEntry: TRawWadEntry;
  LNames: string;
  LIndex: Integer;
  LDirStart: Integer;
begin
  Load(BuildWad(BASIC_LEVEL), False, True);
  FWad.FindNextLevel;
  FWad.CreateGLLump('GL_VERT').Append('abcde');

  LOutput := WriteToBytes;

  Assert.AreEqual(Ord('P'), Integer(LOutput[0]));
  Assert.AreEqual(2, PInteger(@LOutput[4])^);
  LDirStart := PInteger(@LOutput[8])^;
  LNames := '';
  for LIndex := 0 to 1 do
  begin
    Move(LOutput[LDirStart + LIndex * WAD_ENTRY_SIZE], LEntry, SizeOf(LEntry));
    LNames := LNames + EntryName(LEntry) + ' ';
  end;
  Assert.AreEqual('GL_MAP01 GL_VERT ', LNames);
end;

// Regression: the name of an entry has no terminator when it is 8 characters
// long, so it must never be read as a PAnsiChar (the test above did, and in
// Debug read the bytes on the stack after the record). The library fills the
// rest of a short name with zeros
procedure TTestGlbspWadDocument.TestNomiDellaDirectorySonoOttoByteRiempitiDiZeri;
const
  EXPECTED: array[0..1] of AnsiString = ('GL_MAP01', 'GL_VERT'#0);
var
  LOutput: TBytes;
  LDirStart: Integer;
  LIndex: Integer;
  LName: AnsiString;
begin
  Load(BuildWad(BASIC_LEVEL), False, True);
  FWad.FindNextLevel;
  FWad.CreateGLLump('GL_VERT').Append('abcde');

  LOutput := WriteToBytes;

  LDirStart := PInteger(@LOutput[8])^;
  for LIndex := 0 to 1 do
  begin
    SetString(LName, PAnsiChar(@LOutput[LDirStart + LIndex * WAD_ENTRY_SIZE + 8]),
      WAD_LUMP_NAME_SIZE);
    Assert.AreEqual(string(EXPECTED[LIndex]), string(LName));
  end;
end;

procedure TTestGlbspWadDocument.TestCreaLumpEsistenteLoSvuota;
var
  LLump: TGlbspLump;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);
  FWad.FindNextLevel;

  LLump := FWad.CreateLevelLump('SEGS');

  Assert.AreEqual(0, LLump.Length);
  Assert.AreSame(LLump, FWad.FindLevelLump('SEGS'));
  Assert.AreEqual(8, FWad.CurrentLevel.LevelInfo.Children.Count);
end;

procedure TTestGlbspWadDocument.TestAllineamentoA4Byte;
var
  LOutput: TBytes;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);

  LOutput := WriteToBytes;

  // 12 header bytes, 9 lumps of 3 bytes aligned to 4
  Assert.AreEqual(12 + 9 * 4, FWad.DirStart);
  Assert.AreEqual<Integer>(FWad.DirStart + 9 * WAD_ENTRY_SIZE, Length(LOutput));
end;

procedure TTestGlbspWadDocument.TestSegnalazioneLimitiZdbsp;
begin
  Load(BuildWad(BASIC_LEVEL), True, False);
  FWad.FindNextLevel;

  FWad.MarkSoftFailure(LIMIT_VERTEXES or LIMIT_SEGS);
  FWad.MarkHardFailure(LIMIT_VERTEXES);
  FWad.MarkZDSwitch;

  Assert.AreEqual(LIMIT_SEGS, FWad.CurrentLevel.LevelInfo.SoftLimit);
  Assert.AreEqual(0, FWad.CurrentLevel.LevelInfo.HardLimit);
  Assert.AreEqual(LIMIT_ZDBSP, FWad.CurrentLevel.LevelInfo.V5Switch);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspWadDocument);

end.
