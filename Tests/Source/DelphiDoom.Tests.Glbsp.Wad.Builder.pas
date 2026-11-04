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
  System.SysUtils,
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
    function Build(const AInput: TBytes; const AOptions: TGlbspOptions): TBytes;
    function WithoutTimeLine(const ABytes: TBytes): string;
    function WordAt(const ABytes: TBytes; const AIndex: Integer): Integer;
    // Empty when the lumps match, otherwise what is different
    function CompareExact(const AName: string; const AExpected, AActual: TLumpMap): string;
    function CompareWords(const AName: string; const AExpected, AActual: TLumpMap;
      const AWordsPerRecord: Integer; const AExactWords: Cardinal): string;
    function CompareFixedVertices(const AExpected, AActual: TLumpMap): string;
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

function TTestGlbspWadBuilder.Build(const AInput: TBytes; const AOptions: TGlbspOptions): TBytes;
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
    Assert.AreEqual(1, LBuilder.Build(LInput, LOutput));
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
  LIndex, LDifference, LDifferent: Integer;
  LSigned: SmallInt;
begin
  Result := '';
  if not AExpected.TryGetValue(AName, LExpected) then
    Exit(AName + ': missing in the reference');
  if not AActual.TryGetValue(AName, LActual) then
    Exit(AName + ': missing in the output');
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('%s: length %d instead of %d', [AName, Length(LActual), Length(LExpected)]));

  LDifferent := 0;
  for LIndex := 0 to Length(LExpected) div 2 - 1 do
  begin
    LSigned := SmallInt(WordAt(LExpected, LIndex) - WordAt(LActual, LIndex));
    LDifference := Abs(LSigned);
    if LDifference = 0 then
      Continue;
    Inc(LDifferent);
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
function TTestGlbspWadBuilder.CompareFixedVertices(const AExpected, AActual: TLumpMap): string;
var
  LExpected, LActual: TBytes;
  LIndex: Integer;
  LA, LB: Integer;
begin
  Result := '';
  if not AExpected.TryGetValue('GL_VERT', LExpected) then
    Exit('GL_VERT: missing in the reference');
  if not AActual.TryGetValue('GL_VERT', LActual) then
    Exit('GL_VERT: missing in the output');
  if Length(LExpected) <> Length(LActual) then
    Exit(Format('GL_VERT: length %d instead of %d', [Length(LActual), Length(LExpected)]));
  for LIndex := 0 to 3 do
  begin
    if LExpected[LIndex] <> LActual[LIndex] then
      Exit('GL_VERT: wrong magic');
  end;
  for LIndex := 1 to (Length(LExpected) - 4) div 4 do
  begin
    Move(LExpected[4 * LIndex], LA, 4);
    Move(LActual[4 * LIndex], LB, 4);
    if Abs(LA - LB) > 1 then
      Exit(Format('GL_VERT: number %d is %d instead of %d', [LIndex, LB, LA]));
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

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspWadBuilder);

end.
