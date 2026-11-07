{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the complete node building of the glbsp port          }
{                                                                              }
{  The output is compared with the one of the glbsp 2.24 program on           }
{  Freedoom MAP01 (see Tests\Data\README.md for the criterion)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Wad.Builder;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.RegularExpressions,
  System.SysUtils,
  System.ZLib,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Builder,
  DelphiDoom.Glbsp.Wad.Types;

type
  TLumpMap = TDictionary<string, TBytes>;

  [TestFixture]
  [Category('glbsp')]
  TTestGlbspWadBuilder = class(TObject)
  private
    FLumps: TLumpMap;
    function DataPath(const AFileName: string): string;
    function ReadAllBytes(const AFileName: string): TBytes;
    procedure ReadLumps(const ABytes: TBytes; const ALumps: TLumpMap);
    function Build(const AInput: TBytes; const AOptions: TGlbspOptions;
      const ALevels: Integer = 1): TBytes;
    function WithoutTimeLine(const ABytes: TBytes): string;
    function WordAt(const ABytes: TBytes; const AIndex: Integer): Integer;
    // Empty when the lumps match, otherwise what is different
    function CompareExact(const AName: string; const AExpected, AActual: TLumpMap): string;
    function CompareWords(const AName: string; const AExpected, AActual: TLumpMap;
      const AWordsPerRecord: Integer; const AExactWords: Cardinal): string;
    function CompareFixedVertices(const AExpected, AActual: TLumpMap;
      const AKey: string = 'GL_VERT'): string;
    function CompareZdbspNodes(const AKey: string; const AExpected, AActual: TLumpMap): string;
    // Lumps keyed by name and level ("NODES#MAP02")
    procedure ReadKeyedLumps(const ABytes: TBytes; const ALumps: TLumpMap);
    function CompareKeyedLump(const AKey: string; const AExpected, AActual: TLumpMap;
      const ASpecVersion: Integer): string;
    // Builds AInputFile with AOptions and compares every lump with the output of
    // the glbsp 2.24 program, AReferenceFile: in a reference with AOverlay the
    // lumps that are a copy of the input were left out, so they are taken from
    // the input
    procedure CheckAgainstReference(const AInputFile, AReferenceFile: string;
      const AOptions: TGlbspOptions; const AOverlay: Boolean; const ALevels: Integer = 1);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGwaCoincideConIlProgrammaGlbsp;
    [Test]
    procedure TestNodiNormaliCoincidonoConIlProgrammaGlbsp;
    [Test]
    procedure TestWadSenzaLivelliSollevaEccezione;
    [Test]
    procedure TestIlWadInUscitaPuoEssereRiletto;
    [Test]
    procedure TestVersione5EFormatoZdbspCoincidonoConIlProgrammaGlbsp;
    [Test]
    procedure TestVersione3CoincideConIlProgrammaGlbsp;
    [Test]
    procedure TestVersione1CoincideConIlProgrammaGlbsp;
    [Test]
    procedure TestOpzioniDiCompattazioneCoincidonoConIlProgrammaGlbsp;
    [Test]
    procedure TestModalitaVeloceCoincideConIlProgrammaGlbsp;
    [Test]
    procedure TestLivelliHexenConPolyobjCoincidonoConIlProgrammaGlbsp;
    [Test]
    procedure TestCasiParticolariCoincidonoConIlProgrammaGlbsp;
  end;

implementation

uses
  DelphiDoom.Glbsp.Wad.Document;

const
  FIXED_TIME = 'TEST';

{ TTestGlbspWadBuilder }

procedure TTestGlbspWadBuilder.Setup;
begin
  FLumps := TLumpMap.Create;
end;

procedure TTestGlbspWadBuilder.TearDown;
begin
  FLumps.Free;
end;

function TTestGlbspWadBuilder.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\' + AFileName));
end;

function TTestGlbspWadBuilder.ReadAllBytes(const AFileName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(DataPath(AFileName));
end;

procedure TTestGlbspWadBuilder.ReadLumps(const ABytes: TBytes; const ALumps: TLumpMap);
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex, LCharIndex: Integer;
  LName: string;
  LData: TBytes;
begin
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  for LIndex := 0 to LHeader.NumEntries - 1 do
  begin
    Move(ABytes[LHeader.DirStart + LIndex * WAD_ENTRY_SIZE], LEntry, SizeOf(LEntry));
    LName := '';
    for LCharIndex := 0 to WAD_LUMP_NAME_SIZE - 1 do
    begin
      if LEntry.Name[LCharIndex] = #0 then
        Break;
      LName := LName + string(LEntry.Name[LCharIndex]);
    end;
    SetLength(LData, LEntry.Length);
    if LEntry.Length > 0 then
      Move(ABytes[LEntry.Start], LData[0], LEntry.Length);
    ALumps.AddOrSetValue(LName, Copy(LData));
  end;
end;

function TTestGlbspWadBuilder.Build(const AInput: TBytes; const AOptions: TGlbspOptions;
  const ALevels: Integer): TBytes;
var
  LBuilder: TGlbspWadBuilder;
  LInput: TBytesStream;
  LOutput: TBytesStream;
begin
  LInput := TBytesStream.Create(AInput);
  LOutput := TBytesStream.Create;
  LBuilder := TGlbspWadBuilder.Create(AOptions);
  try
    LBuilder.TimeProvider :=
      function: string
      begin
        Result := FIXED_TIME;
      end;
    Assert.AreEqual(ALevels, LBuilder.Build(LInput, LOutput));
    Result := Copy(LOutput.Bytes, 0, LOutput.Size);
  finally
    LBuilder.Free;
    LOutput.Free;
    LInput.Free;
  end;
end;

function TTestGlbspWadBuilder.WithoutTimeLine(const ABytes: TBytes): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := string(AnsiString(TEncoding.ANSI.GetString(ABytes)));
    for LIndex := LLines.Count - 1 downto 0 do
    begin
      if LLines[LIndex].StartsWith('TIME=') then
        LLines.Delete(LIndex);
    end;
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

function TTestGlbspWadBuilder.WordAt(const ABytes: TBytes; const AIndex: Integer): Integer;
begin
  Result := ABytes[2 * AIndex] or (ABytes[2 * AIndex + 1] shl 8);
end;

function TTestGlbspWadBuilder.CompareExact(const AName: string; const AExpected,
  AActual: TLumpMap): string;
var
  LExpected, LActual: TBytes;
  LIndex: Integer;
begin
  Result := '';
  if not AExpected.TryGetValue(AName, LExpected) then
    Exit(AName + ': missing in the reference');
  if not AActual.TryGetValue(AName, LActual) then
    Exit(AName + ': missing in the output');
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('%s: length %d instead of %d', [AName, Length(LActual), Length(LExpected)]));
  for LIndex := 0 to High(LExpected) do
  begin
    if LExpected[LIndex] <> LActual[LIndex] then
      Exit(Format('%s: byte %d is %d instead of %d', [AName, LIndex, LActual[LIndex],
        LExpected[LIndex]]));
  end;
end;

// The 16 bit words of a record are compared: those whose bit is set in
// AExactWords must be equal, the others may differ by one unit
function TTestGlbspWadBuilder.CompareWords(const AName: string; const AExpected,
  AActual: TLumpMap; const AWordsPerRecord: Integer; const AExactWords: Cardinal): string;
var
  LExpected, LActual: TBytes;
  LIndex, LDifference: Integer;
  LSigned: SmallInt;
begin
  Result := '';
  if not AExpected.TryGetValue(AName, LExpected) then
    Exit(AName + ': missing in the reference');
  if not AActual.TryGetValue(AName, LActual) then
    Exit(AName + ': missing in the output');
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('%s: length %d instead of %d', [AName, Length(LActual), Length(LExpected)]));

  for LIndex := 0 to Length(LExpected) div 2 - 1 do
  begin
    LSigned := SmallInt(WordAt(LExpected, LIndex) - WordAt(LActual, LIndex));
    LDifference := Abs(LSigned);
    if LDifference = 0 then
      Continue;
    if ((AExactWords shr (LIndex mod AWordsPerRecord)) and 1) <> 0 then
      Exit(Format('%s: word %d (field %d of record %d) is %d instead of %d', [AName, LIndex,
        LIndex mod AWordsPerRecord, LIndex div AWordsPerRecord, WordAt(LActual, LIndex),
        WordAt(LExpected, LIndex)]));
    if LDifference > 1 then
      Exit(Format('%s: word %d (field %d of record %d) differs by %d', [AName, LIndex,
        LIndex mod AWordsPerRecord, LIndex div AWordsPerRecord, LDifference]));
  end;
end;

// GL_VERT: the magic, then pairs of 16.16 numbers that may differ by one unit
function TTestGlbspWadBuilder.CompareFixedVertices(const AExpected, AActual: TLumpMap;
  const AKey: string): string;
var
  LExpected, LActual: TBytes;
  LIndex: Integer;
  LA, LB: Integer;
begin
  Result := '';
  if not AExpected.TryGetValue(AKey, LExpected) then
    Exit(AKey + ': missing in the reference');
  if not AActual.TryGetValue(AKey, LActual) then
    Exit(AKey + ': missing in the output');
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('%s: length %d instead of %d', [AKey, Length(LActual), Length(LExpected)]));
  for LIndex := 0 to 3 do
  begin
    if LExpected[LIndex] <> LActual[LIndex] then
      Exit(AKey + ': wrong magic');
  end;
  for LIndex := 1 to (Length(LExpected) - 4) div 4 do
  begin
    Move(LExpected[4 * LIndex], LA, 4);
    Move(LActual[4 * LIndex], LB, 4);
    if Abs(LA - LB) > 1 then
      Exit(Format('%s: number %d is %d instead of %d', [AKey, LIndex, LB, LA]));
  end;
end;

// The NODES lump of the ZDBSP format: "ZNOD" and a zlib stream. The reference
// was written by a glbsp whose zlib stores the bytes as they are (see
// Tests\Data\README.md), so the stream of the output is decompressed first;
// then vertices and node coordinates may differ by one unit, the rest not
function TTestGlbspWadBuilder.CompareZdbspNodes(const AKey: string; const AExpected,
  AActual: TLumpMap): string;
var
  LExpected, LActual: TBytes;
  LPosition: Integer;

  function Cardinal32(const ABytes: TBytes; const AOffset: Integer): Integer;
  begin
    Move(ABytes[AOffset], Result, 4);
  end;

  function SameBytes(const ACount: Integer): Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;
    for LIndex := LPosition to LPosition + ACount - 1 do
    begin
      if LExpected[LIndex] <> LActual[LIndex] then
        Exit(False);
    end;
    Inc(LPosition, ACount);
  end;

  function NearIntegers(const ACount: Integer): Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;
    for LIndex := 0 to ACount - 1 do
    begin
      if Abs(Cardinal32(LExpected, LPosition) - Cardinal32(LActual, LPosition)) > 1 then
        Exit(False);
      Inc(LPosition, 4);
    end;
  end;

  function NearWords(const ACount: Integer): Boolean;
  var
    LIndex: Integer;
  begin
    Result := True;
    for LIndex := 0 to ACount - 1 do
    begin
      if Abs(SmallInt(PWord(@LExpected[LPosition])^ - PWord(@LActual[LPosition])^)) > 1 then
        Exit(False);
      Inc(LPosition, 2);
    end;
  end;

var
  LPacked: TBytes;
  LCount, LIndex: Integer;
begin
  Result := '';
  if not AExpected.TryGetValue(AKey, LExpected) then
    Exit(AKey + ': missing in the reference');
  if not AActual.TryGetValue(AKey, LActual) then
    Exit(AKey + ': missing in the output');
  if (Length(LActual) < 4) or (TEncoding.ANSI.GetString(LActual, 0, 4) <> 'ZNOD') then
    Exit(AKey + ': no ZNOD magic');
  LPacked := Copy(LActual, 4, MaxInt);
  ZDecompress(LPacked, LActual);
  LExpected := Copy(LExpected, 4, MaxInt);
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('%s: %d bytes instead of %d', [AKey, Length(LActual), Length(LExpected)]));

  LPosition := 0;
  LCount := Cardinal32(LExpected, 4);
  if not SameBytes(8) then
    Exit(AKey + ': vertex counts');
  if not NearIntegers(2 * LCount) then
    Exit(AKey + ': vertices');
  LCount := Cardinal32(LExpected, LPosition);
  if not SameBytes(4 + 4 * LCount) then
    Exit(AKey + ': subsectors');
  LCount := Cardinal32(LExpected, LPosition);
  if not SameBytes(4 + 11 * LCount) then
    Exit(AKey + ': segs');
  LCount := Cardinal32(LExpected, LPosition);
  if not SameBytes(4) then
    Exit(AKey + ': node count');
  for LIndex := 0 to LCount - 1 do
  begin
    // x, y, dx, dy and the two boxes, then the two children
    if not NearWords(12) then
      Exit(Format('%s: coordinates of node %d', [AKey, LIndex]));
    if not SameBytes(8) then
      Exit(Format('%s: children of node %d', [AKey, LIndex]));
  end;
end;

procedure TTestGlbspWadBuilder.ReadKeyedLumps(const ABytes: TBytes; const ALumps: TLumpMap);
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex, LCharIndex: Integer;
  LName, LLevel: string;
  LData: TBytes;
begin
  LLevel := '';
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  for LIndex := 0 to LHeader.NumEntries - 1 do
  begin
    Move(ABytes[LHeader.DirStart + LIndex * WAD_ENTRY_SIZE], LEntry, SizeOf(LEntry));
    LName := '';
    for LCharIndex := 0 to WAD_LUMP_NAME_SIZE - 1 do
    begin
      if LEntry.Name[LCharIndex] = #0 then
        Break;
      LName := LName + string(LEntry.Name[LCharIndex]);
    end;
    // The marker of a level and the GL text lump of the same level
    if TRegEx.IsMatch(LName, '^(GL_)?(MAP\d\d|E\dM\d)$') then
      LLevel := LName.Replace('GL_', '');
    SetLength(LData, LEntry.Length);
    if LEntry.Length > 0 then
      Move(ABytes[LEntry.Start], LData[0], LEntry.Length);
    ALumps.AddOrSetValue(LName + '#' + LLevel, Copy(LData));
  end;
end;

function TTestGlbspWadBuilder.CompareKeyedLump(const AKey: string; const AExpected,
  AActual: TLumpMap; const ASpecVersion: Integer): string;
var
  LName: string;
  LData: TBytes;
begin
  LName := AKey.Substring(0, AKey.IndexOf('#'));
  if LName = 'VERTEXES' then
    Exit(CompareWords(AKey, AExpected, AActual, 2, 0));
  if LName = 'SEGS' then
    // start, end, linedef and side must be equal; the angle and the distance may not
    Exit(CompareWords(AKey, AExpected, AActual, 6, 1 or 2 or 8 or 16));
  if LName = 'NODES' then
  begin
    if AExpected.TryGetValue(AKey, LData) and (Length(LData) >= 4) and
      (TEncoding.ANSI.GetString(LData, 0, 4) = 'ZNOD') then
      Exit(CompareZdbspNodes(AKey, AExpected, AActual));
    Exit(CompareWords(AKey, AExpected, AActual, 14, 3 shl 12));
  end;
  if LName = 'GL_VERT' then
  begin
    if ASpecVersion = 1 then
      Exit(CompareWords(AKey, AExpected, AActual, 2, 0));
    Exit(CompareFixedVertices(AExpected, AActual, AKey));
  end;
  if LName = 'GL_NODES' then
  begin
    // the V5 children are two 32 bit numbers
    if ASpecVersion = 5 then
      Exit(CompareWords(AKey, AExpected, AActual, 16, $F000));
    Exit(CompareWords(AKey, AExpected, AActual, 14, 3 shl 12));
  end;
  if LName.StartsWith('GL_') and (LName <> 'GL_SEGS') and (LName <> 'GL_SSECT') and
    (LName <> 'GL_PVS') then
  begin
    // the text lump of the level
    if WithoutTimeLine(AExpected[AKey]) <> WithoutTimeLine(AActual[AKey]) then
      Exit(AKey + ': ' + WithoutTimeLine(AActual[AKey]));
    Exit('');
  end;
  Result := CompareExact(AKey, AExpected, AActual);
end;

procedure TTestGlbspWadBuilder.CheckAgainstReference(const AInputFile, AReferenceFile: string;
  const AOptions: TGlbspOptions; const AOverlay: Boolean; const ALevels: Integer);
var
  LInput: TBytes;
  LReference: TLumpMap;
  LExpected: TLumpMap;
  LKey: string;
  LPair: TPair<string, TBytes>;
  LDifference, LDifferences: string;
begin
  LInput := ReadAllBytes(AInputFile);
  LExpected := TLumpMap.Create;
  LReference := TLumpMap.Create;
  try
    if AOverlay then
      ReadKeyedLumps(LInput, LExpected);
    ReadKeyedLumps(ReadAllBytes(AReferenceFile), LReference);
    for LPair in LReference do
      LExpected.AddOrSetValue(LPair.Key, LPair.Value);

    ReadKeyedLumps(Build(LInput, AOptions, ALevels), FLumps);

    LDifferences := '';
    for LKey in FLumps.Keys do
    begin
      if not LExpected.ContainsKey(LKey) then
        LDifferences := LDifferences + LKey + ': not in the reference; ';
    end;
    for LKey in LExpected.Keys do
    begin
      LDifference := CompareKeyedLump(LKey, LExpected, FLumps, AOptions.SpecVersion);
      if LDifference <> '' then
        LDifferences := LDifferences + LDifference + '; ';
    end;
    Assert.AreEqual('', LDifferences);
  finally
    LReference.Free;
    LExpected.Free;
  end;
end;

procedure TTestGlbspWadBuilder.TestGwaCoincideConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
  LExpected: TLumpMap;
  LOutput: TBytes;
  LText: TBytes;
  LExpectedText: TBytes;
begin
  if not TFile.Exists(DataPath('glbsp_map01.gwa')) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.gwa not found');
    Exit;
  end;
  LOptions := TGlbspOptions.Default;
  LOptions.GwaMode := True;
  LExpected := TLumpMap.Create;
  try
    ReadLumps(ReadAllBytes('glbsp_map01.gwa'), LExpected);

    LOutput := Build(ReadAllBytes('glbsp_map01.wad'), LOptions);
    ReadLumps(LOutput, FLumps);

    Assert.AreEqual('', CompareExact('GL_SEGS', LExpected, FLumps));
    Assert.AreEqual('', CompareExact('GL_SSECT', LExpected, FLumps));
    Assert.AreEqual('', CompareFixedVertices(LExpected, FLumps));
    // x, y, dx, dy and the boxes may differ by one; the children may not
    Assert.AreEqual('', CompareWords('GL_NODES', LExpected, FLumps, 14, 3 shl 12));
    Assert.AreEqual('', CompareExact('GL_PVS', LExpected, FLumps));

    LText := FLumps['GL_MAP01'];
    LExpectedText := LExpected['GL_MAP01'];
    Assert.AreEqual(WithoutTimeLine(LExpectedText), WithoutTimeLine(LText));
    Assert.AreEqual(6, FLumps.Count, 'only the GL lumps are in a GWA');
  finally
    LExpected.Free;
  end;
end;

procedure TTestGlbspWadBuilder.TestNodiNormaliCoincidonoConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
  LExpected: TLumpMap;
  LOutput: TBytes;
  LName: string;
begin
  if not TFile.Exists(DataPath('glbsp_map01_normal.wad')) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01_normal.wad not found');
    Exit;
  end;
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LExpected := TLumpMap.Create;
  try
    ReadLumps(ReadAllBytes('glbsp_map01_normal.wad'), LExpected);

    LOutput := Build(ReadAllBytes('glbsp_map01.wad'), LOptions);
    ReadLumps(LOutput, FLumps);

    for LName in ['THINGS', 'LINEDEFS', 'SIDEDEFS', 'SECTORS', 'REJECT', 'BLOCKMAP',
      'SSECTORS', 'GL_SEGS', 'GL_SSECT'] do
      Assert.AreEqual('', CompareExact(LName, LExpected, FLumps));
    Assert.AreEqual('', CompareWords('VERTEXES', LExpected, FLumps, 2, 0));
    // start, end, linedef and side must be equal; the angle and the distance may not
    Assert.AreEqual('', CompareWords('SEGS', LExpected, FLumps, 6, 1 or 2 or 8 or 16));
    Assert.AreEqual('', CompareWords('NODES', LExpected, FLumps, 14, 3 shl 12));
    Assert.AreEqual('', CompareFixedVertices(LExpected, FLumps));
    Assert.AreEqual('', CompareWords('GL_NODES', LExpected, FLumps, 14, 3 shl 12));
    Assert.AreEqual(WithoutTimeLine(LExpected['GL_MAP01']), WithoutTimeLine(FLumps['GL_MAP01']));
  finally
    LExpected.Free;
  end;
end;

procedure TTestGlbspWadBuilder.TestWadSenzaLivelliSollevaEccezione;
var
  LHeader: TRawWadHeader;
  LInput: TBytesStream;
  LOutput: TBytesStream;
  LBuilder: TGlbspWadBuilder;
begin
  LHeader.MagicType := 'PWAD';
  LHeader.NumEntries := 0;
  LHeader.DirStart := WAD_HEADER_SIZE;
  LInput := TBytesStream.Create;
  LOutput := TBytesStream.Create;
  LBuilder := TGlbspWadBuilder.Create(TGlbspOptions.Default);
  try
    LInput.WriteBuffer(LHeader, SizeOf(LHeader));

    Assert.WillRaise(
      procedure
      begin
        LBuilder.Build(LInput, LOutput);
      end, EGlbspBuildException);
  finally
    LBuilder.Free;
    LOutput.Free;
    LInput.Free;
  end;
end;

procedure TTestGlbspWadBuilder.TestIlWadInUscitaPuoEssereRiletto;
var
  LOptions: TGlbspOptions;
  LOutput: TBytes;
  LStream: TBytesStream;
  LWad: TGlbspWad;
begin
  if not TFile.Exists(DataPath('glbsp_map01.wad')) then
  begin
    Assert.Pass('Tests\Data\glbsp_map01.wad not found');
    Exit;
  end;
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LOutput := Build(ReadAllBytes('glbsp_map01.wad'), LOptions);

  LStream := TBytesStream.Create(LOutput);
  LWad := TGlbspWad.Create;
  try
    LWad.ReadFromStream(LStream, True, False);

    // The GL lumps are discarded when a WAD is read: the level is still one,
    // and its ten lumps are there
    Assert.AreEqual(1, LWad.CountLevels);
    Assert.IsTrue(LWad.FindNextLevel);
    Assert.IsNotNull(LWad.FindLevelLump('NODES'));
    Assert.IsNotNull(LWad.FindLevelLump('BLOCKMAP'));
    Assert.AreEqual(0, LWad.Warnings.Count);
  finally
    LWad.Free;
    LStream.Free;
  end;
end;

// -q -xp -n -v5: GL nodes of version 5 and the normal nodes in the ZDBSP
// format, since they are asked with V5
procedure TTestGlbspWadBuilder.TestVersione5EFormatoZdbspCoincidonoConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LOptions.SpecVersion := 5;
  CheckAgainstReference('glbsp_map01.wad', 'glbsp_map01_v5.wad', LOptions, True);
  Assert.AreEqual(0, Integer(Length(FLumps['SEGS#MAP01'])),'SEGS stays empty in the ZDBSP format');
end;

// -q -xp -v3, a GWA
procedure TTestGlbspWadBuilder.TestVersione3CoincideConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.GwaMode := True;
  LOptions.SpecVersion := 3;
  CheckAgainstReference('glbsp_map01.wad', 'glbsp_map01_v3.gwa', LOptions, False);
end;

// -q -xp -v1, a GWA: the GL vertices are 16 bit numbers
procedure TTestGlbspWadBuilder.TestVersione1CoincideConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.GwaMode := True;
  LOptions.SpecVersion := 1;
  CheckAgainstReference('glbsp_map01.wad', 'glbsp_map01_v1.gwa', LOptions, False);
end;

// -q -xp -n -p -m -u -y -w -xr
procedure TTestGlbspWadBuilder.TestOpzioniDiCompattazioneCoincidonoConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LOptions.PackSides := True;
  LOptions.MergeVert := True;
  LOptions.PruneSect := True;
  LOptions.WindowFx := True;
  LOptions.MiniWarnings := True;
  LOptions.NoReject := True;
  CheckAgainstReference('glbsp_map01.wad', 'glbsp_map01_options.wad', LOptions, True);
end;

// -q -xp -f, a GWA: the original nodes are reused to choose the partitions
procedure TTestGlbspWadBuilder.TestModalitaVeloceCoincideConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.GwaMode := True;
  LOptions.Fast := True;
  CheckAgainstReference('glbsp_map01.wad', 'glbsp_map01_fast.gwa', LOptions, False);
end;

// -q -xp -n -w on two Hexen levels with polyobj spots of Hexen (MAP01) and
// ZDoom (MAP02); glbsp warned about the two spots that are not in a sector
procedure TTestGlbspWadBuilder.TestLivelliHexenConPolyobjCoincidonoConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
  LBuilder: TGlbspWadBuilder;
  LInput, LOutput: TBytesStream;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LOptions.MiniWarnings := True;
  CheckAgainstReference('glbsp_hexen.wad', 'glbsp_hexen_normal.wad', LOptions, True, 2);

  LInput := TBytesStream.Create(ReadAllBytes('glbsp_hexen.wad'));
  LOutput := TBytesStream.Create;
  LBuilder := TGlbspWadBuilder.Create(LOptions);
  try
    Assert.AreEqual(2, LBuilder.Build(LInput, LOutput));
    Assert.AreEqual('Bad polyobj thing at (-192,5000).'#13#10 +
      'Invalid Polyobj thing at (6000,-192).'#13#10, LBuilder.Messages.Text);
  finally
    LBuilder.Free;
    LOutput.Free;
    LInput.Free;
  end;
end;

// -q -xp -n -y -w on three small levels made for the odd cases: a one-sided
// window, sidedefs that are missing, a sector that is not closed, lines and
// nodes longer than 16 bits and a blockmap too large. The warnings are those
// that glbsp printed, in the same order
procedure TTestGlbspWadBuilder.TestCasiParticolariCoincidonoConIlProgrammaGlbsp;
var
  LOptions: TGlbspOptions;
  LBuilder: TGlbspWadBuilder;
  LInput, LOutput: TBytesStream;
  LExpected: TStringList;
begin
  LOptions := TGlbspOptions.Default;
  LOptions.ForceNormal := True;
  LOptions.WindowFx := True;
  LOptions.MiniWarnings := True;
  CheckAgainstReference('glbsp_odd.wad', 'glbsp_odd_normal.wad', LOptions, True, 3);

  LInput := TBytesStream.Create(ReadAllBytes('glbsp_odd.wad'));
  LOutput := TBytesStream.Create;
  LBuilder := TGlbspWadBuilder.Create(LOptions);
  LExpected := TStringList.Create;
  try
    // A list, so that the line breaks of the file do not matter
    LExpected.LoadFromFile(DataPath('glbsp_odd_warnings.txt'));
    Assert.AreEqual(3, LBuilder.Build(LInput, LOutput));
    Assert.AreEqual(LExpected.Text, LBuilder.Messages.Text);
  finally
    LExpected.Free;
    LBuilder.Free;
    LOutput.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspWadBuilder);

end.
