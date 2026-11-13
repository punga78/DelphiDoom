{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap builder of the glbsp port                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Blockmap.Builder;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Blockmap.Builder,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Node.Builder,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump,
  DelphiDoom.Glbsp.Wad.Types;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspBlockmapBuilder = class(TObject)
  private
    FData: TGlbspLevelData;
    FWad: TGlbspWad;
    FInput: TBytesStream;
    FOptions: TGlbspOptions;
    FMessages: TStringList;
    FBuilder: TGlbspBlockmapBuilder;
    procedure CreateWad;
    procedure AddLine(const AX1, AY1, AX2, AY2: Integer);
    function Lump: TBytes;
    function WordAt(const ABytes: TBytes; const AIndex: Integer): Integer;
    function BlockLines(const ABytes: TBytes; const ABlock: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestOrigineEDimensioniArrotondateAOtto;
    [Test]
    procedure TestLimitiDellaMappaPassatiAlCostruttoreDeiSeg;
    [Test]
    procedure TestStanzaQuadrataAssegnaLeLineeAiBlocchi;
    [Test]
    procedure TestBlocchiUgualiSiCondividono;
    [Test]
    procedure TestBlocchiVuotiPuntanoAlBloccoNullo;
    [Test]
    procedure TestLineaDiagonaleToccaSoloIBlocchiAttraversati;
    [Test]
    procedure TestMappaTroppoGrandeVieneTroncata;
  end;

implementation

{ TTestGlbspBlockmapBuilder }

procedure TTestGlbspBlockmapBuilder.Setup;
begin
  FData := TGlbspLevelData.Create;
  FWad := TGlbspWad.Create;
  FOptions := TGlbspOptions.Default;
  FOptions.MiniWarnings := True;
  FMessages := TStringList.Create;
  CreateWad;
end;

procedure TTestGlbspBlockmapBuilder.TearDown;
begin
  FBuilder.Free;
  FMessages.Free;
  FWad.Free;
  FInput.Free;
  FData.Free;
end;

// A WAD with one empty level, only to have a current level to write to
procedure TTestGlbspBlockmapBuilder.CreateWad;
const
  NAMES: array[0..4] of AnsiString = ('MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES');
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex, LCharIndex: Integer;
begin
  FInput := TBytesStream.Create;
  LHeader.MagicType := 'PWAD';
  LHeader.NumEntries := Length(NAMES);
  LHeader.DirStart := WAD_HEADER_SIZE;
  FInput.WriteBuffer(LHeader, SizeOf(LHeader));
  for LIndex := 0 to High(NAMES) do
  begin
    FillChar(LEntry, SizeOf(LEntry), 0);
    LEntry.Start := WAD_HEADER_SIZE;
    for LCharIndex := 1 to Length(NAMES[LIndex]) do
      LEntry.Name[LCharIndex - 1] := NAMES[LIndex][LCharIndex];
    FInput.WriteBuffer(LEntry, SizeOf(LEntry));
  end;
  FInput.Position := 0;
  FWad.ReadFromStream(FInput, True, False);
  FWad.FindNextLevel;
end;

procedure TTestGlbspBlockmapBuilder.AddLine(const AX1, AY1, AX2, AY2: Integer);
var
  LLine: TGlbspLinedef;
begin
  LLine := FData.NewLinedef;
  LLine.Start := FData.NewVertex;
  LLine.Start.X := AX1;
  LLine.Start.Y := AY1;
  LLine.EndVertex := FData.NewVertex;
  LLine.EndVertex.X := AX2;
  LLine.EndVertex.Y := AY2;
  LLine.Index := FData.Linedefs.Count - 1;
  LLine.ZeroLength := (AX1 = AX2) and (AY1 = AY2);
end;

function TTestGlbspBlockmapBuilder.Lump: TBytes;
var
  LLump: TGlbspLump;
begin
  LLump := FWad.FindLevelLump('BLOCKMAP');
  Assert.IsNotNull(LLump);
  Result := Copy(LLump.Data, 0, LLump.Length);
end;

function TTestGlbspBlockmapBuilder.WordAt(const ABytes: TBytes; const AIndex: Integer): Integer;
begin
  Result := ABytes[2 * AIndex] or (ABytes[2 * AIndex + 1] shl 8);
end;

// The lines listed for a block, found through its pointer
function TTestGlbspBlockmapBuilder.BlockLines(const ABytes: TBytes;
  const ABlock: Integer): string;
var
  LOffset: Integer;
begin
  Result := '';
  LOffset := WordAt(ABytes, 4 + ABlock);
  Assert.AreEqual(0, WordAt(ABytes, LOffset), 'a list starts with zero');
  Inc(LOffset);
  while WordAt(ABytes, LOffset) <> $FFFF do
  begin
    Result := Result + IntToStr(WordAt(ABytes, LOffset)) + ' ';
    Inc(LOffset);
  end;
  Result := Trim(Result);
end;

procedure TTestGlbspBlockmapBuilder.TestOrigineEDimensioniArrotondateAOtto;
begin
  AddLine(-13, -21, 300, 200);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);

  FBuilder.InitBlockmap;

  // The origin goes down to a multiple of 8
  Assert.AreEqual(-16, FBuilder.BlockX);
  Assert.AreEqual(-24, FBuilder.BlockY);
  Assert.AreEqual((300 + 16) div 128 + 1, FBuilder.BlockW);
  Assert.AreEqual((200 + 24) div 128 + 1, FBuilder.BlockH);
end;

procedure TTestGlbspBlockmapBuilder.TestLimitiDellaMappaPassatiAlCostruttoreDeiSeg;
var
  LBounds: TGlbspBlockmapBounds;
begin
  AddLine(0, 0, 128, 128);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;

  LBounds := FBuilder.GetBounds;

  Assert.AreEqual(0, LBounds.X);
  Assert.AreEqual(0, LBounds.Y);
  Assert.AreEqual(2, LBounds.Width);
  Assert.AreEqual(2, LBounds.Height);
end;

procedure TTestGlbspBlockmapBuilder.TestStanzaQuadrataAssegnaLeLineeAiBlocchi;
var
  LBytes: TBytes;
begin
  // A room of 128: the lines 0 (left), 1 (top), 2 (right), 3 (bottom)
  AddLine(0, 0, 0, 128);
  AddLine(0, 128, 128, 128);
  AddLine(128, 128, 128, 0);
  AddLine(128, 0, 0, 0);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;

  FBuilder.PutBlockmap;

  LBytes := Lump;
  // Header: origin (0,0), 2 by 2 blocks
  Assert.AreEqual(0, WordAt(LBytes, 0));
  Assert.AreEqual(0, WordAt(LBytes, 1));
  Assert.AreEqual(2, WordAt(LBytes, 2));
  Assert.AreEqual(2, WordAt(LBytes, 3));
  // 4 header words, 4 pointers, 2 for the null block, 4 lists of 4 words
  Assert.AreEqual<Integer>(2 * (4 + 4 + 2 + 4 * 4), Length(LBytes));
  Assert.AreEqual('0 3', BlockLines(LBytes, 0));
  Assert.AreEqual('2 3', BlockLines(LBytes, 1));
  Assert.AreEqual('0 1', BlockLines(LBytes, 2));
  Assert.AreEqual('1 2', BlockLines(LBytes, 3));
  Assert.IsFalse(FBuilder.Overflowed);
end;

procedure TTestGlbspBlockmapBuilder.TestBlocchiUgualiSiCondividono;
var
  LBytes: TBytes;
begin
  // One long horizontal line: the 4 blocks have the same list
  AddLine(0, 0, 384, 0);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;

  FBuilder.PutBlockmap;

  LBytes := Lump;
  Assert.AreEqual(4, FBuilder.BlockW);
  Assert.AreEqual(1, FBuilder.BlockH);
  // 4 header words, 4 pointers, 2 null block words, one list of 3 words
  Assert.AreEqual<Integer>(2 * (4 + 4 + 2 + 3), Length(LBytes));
  Assert.AreEqual(WordAt(LBytes, 4), WordAt(LBytes, 5));
  Assert.AreEqual(WordAt(LBytes, 4), WordAt(LBytes, 7));
  Assert.AreEqual('0', BlockLines(LBytes, 3));
  Assert.AreEqual(35, FBuilder.Compression);
end;

procedure TTestGlbspBlockmapBuilder.TestBlocchiVuotiPuntanoAlBloccoNullo;
var
  LBytes: TBytes;
  LNullOffset: Integer;
begin
  AddLine(0, 0, 0, 10);
  AddLine(384, 384, 384, 394);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;

  FBuilder.PutBlockmap;

  LBytes := Lump;
  Assert.AreEqual(4, FBuilder.BlockW);
  Assert.AreEqual(4, FBuilder.BlockH);
  // The null block follows the pointers: header words + number of blocks
  LNullOffset := 4 + 16;
  Assert.AreEqual(LNullOffset, WordAt(LBytes, 4 + 5));
  Assert.AreEqual(0, WordAt(LBytes, LNullOffset));
  Assert.AreEqual($FFFF, WordAt(LBytes, LNullOffset + 1));
  Assert.AreEqual('0', BlockLines(LBytes, 0));
  Assert.AreEqual('1', BlockLines(LBytes, 15));
end;

procedure TTestGlbspBlockmapBuilder.TestLineaDiagonaleToccaSoloIBlocchiAttraversati;
var
  LBytes: TBytes;
begin
  // A diagonal across a 3 by 3 area: it misses the blocks of the two corners
  AddLine(0, 0, 383, 383);
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;

  FBuilder.PutBlockmap;

  LBytes := Lump;
  Assert.AreEqual(3, FBuilder.BlockW);
  Assert.AreEqual('0', BlockLines(LBytes, 0));
  Assert.AreEqual('0', BlockLines(LBytes, 4));
  Assert.AreEqual('0', BlockLines(LBytes, 8));
  // The empty blocks use the null block, with no line
  Assert.AreEqual('', BlockLines(LBytes, 2));
  Assert.AreEqual('', BlockLines(LBytes, 6));
end;

procedure TTestGlbspBlockmapBuilder.TestMappaTroppoGrandeVieneTroncata;
begin
  AddLine(0, 0, 1920, 0);
  AddLine(0, 0, 0, 1920);
  FOptions.BlockLimit := 100;
  FBuilder := TGlbspBlockmapBuilder.Create(FData, FWad, FOptions, FMessages);
  FBuilder.InitBlockmap;
  Assert.AreEqual(16, FBuilder.BlockW);
  Assert.AreEqual(16, FBuilder.BlockH);

  FBuilder.PutBlockmap;

  Assert.AreEqual(10, FBuilder.BlockW);
  Assert.AreEqual(10, FBuilder.BlockH);
  Assert.AreEqual(1, FMessages.Count);
  Assert.Contains(FMessages[0], 'Truncated to 10x10 blocks');
  Assert.AreEqual(LIMIT_BMAP_TRUNC, FWad.CurrentLevel.LevelInfo.SoftLimit and LIMIT_BMAP_TRUNC);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspBlockmapBuilder);

end.

