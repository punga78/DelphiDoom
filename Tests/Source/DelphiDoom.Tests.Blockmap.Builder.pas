{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the blockmap library - TBlockmapBuilder                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Blockmap.Builder;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Blockmap.Types,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Factory,
  DelphiDoom.Tests.Blockmap.Cases,
  DelphiDoom.Tests.Blockmap.Fingerprint;

type
  [TestFixture]
  [Category('blockmap')]
  TTestBlockmapBuilder = class
  strict private
    FBuilder: IBlockmapBuilder;
    class function Point(const AX, AY: Integer): TBlockmapPoint; static;
    class function Line(const AX1, AY1, AX2, AY2: Integer): TBlockmapLine; static;
    procedure AssertLump(const AExpected: array of Integer; const AActual: TBlockmapData);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareUnaCellaConUnaLinea;
    [Test]
    procedure DovrebbeMettereLeLineeInOrdineDecrescenteTraLoZeroEIlMenoUno;
    [Test]
    procedure DovrebbeAggiungereLaLineaATutteLeCelleCheAttraversa;
    [Test]
    procedure DovrebbeDareLeCelleDelleLineeVerticaliEDiagonali;
    [Test]
    procedure DovrebbeUsareLaLarghezzaDellaMappaPerIlLimiteDiWrap;
    [Test]
    procedure DovrebbeDisattivareIlWrapSottoLeDimensioniMassime;
    [Test]
    procedure DovrebbeRifiutareUnLivelloSenzaVertici;
    [Test]
    procedure DovrebbeRifiutareUnaLineaFuoriDallArea;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDueVolte;
    [Test]
    procedure DovrebbeDareLeStesseBlockmapDelVecchioCodice;
  end;

implementation

{ TTestBlockmapBuilder }

class function TTestBlockmapBuilder.Point(const AX, AY: Integer): TBlockmapPoint;
begin
  Result.X := AX * BLOCKMAP_FRACUNIT;
  Result.Y := AY * BLOCKMAP_FRACUNIT;
end;

class function TTestBlockmapBuilder.Line(const AX1, AY1, AX2, AY2: Integer): TBlockmapLine;
begin
  Result.X1 := AX1 * BLOCKMAP_FRACUNIT;
  Result.Y1 := AY1 * BLOCKMAP_FRACUNIT;
  Result.X2 := AX2 * BLOCKMAP_FRACUNIT;
  Result.Y2 := AY2 * BLOCKMAP_FRACUNIT;
end;

procedure TTestBlockmapBuilder.AssertLump(const AExpected: array of Integer;
  const AActual: TBlockmapData);
var
  LIndex: Integer;
begin
  Assert.AreEqual(Length(AExpected), Length(AActual.Lump), 'size of the lump');
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual(AExpected[LIndex], AActual.Lump[LIndex], Format('value %d', [LIndex]));
end;

procedure TTestBlockmapBuilder.Setup;
begin
  FBuilder := TBlockmapFactory.CreateBuilder;
end;

procedure TTestBlockmapBuilder.TearDown;
begin
  FBuilder := nil;
end;

procedure TTestBlockmapBuilder.DovrebbeDareUnaCellaConUnaLinea;
var
  LData: TBlockmapData;
begin
  LData := FBuilder.Build([Point(0, 0), Point(64, 0)], [Line(0, 0, 64, 0)]);
  Assert.AreEqual(1, LData.Columns);
  Assert.AreEqual(1, LData.Rows);
  Assert.AreEqual(0, LData.OriginX);
  Assert.AreEqual(0, LData.OriginY);
  Assert.IsTrue(LData.Built);
  // header, offset of the only block, then 0, line 0, -1
  AssertLump([0, 0, 1, 1, 5, 0, 0, -1], LData);
end;

procedure TTestBlockmapBuilder.DovrebbeMettereLeLineeInOrdineDecrescenteTraLoZeroEIlMenoUno;
var
  LData: TBlockmapData;
begin
  LData := FBuilder.Build([Point(0, 0), Point(64, 0)],
    [Line(0, 0, 64, 0), Line(0, 0, 0, 0), Line(0, 0, 64, 0)]);
  AssertLump([0, 0, 1, 1, 5, 0, 2, 1, 0, -1], LData);
end;

procedure TTestBlockmapBuilder.DovrebbeAggiungereLaLineaATutteLeCelleCheAttraversa;
var
  LData: TBlockmapData;
begin
  LData := FBuilder.Build([Point(0, 0), Point(200, 0)], [Line(0, 0, 200, 0)]);
  Assert.AreEqual(2, LData.Columns);
  Assert.AreEqual(1, LData.Rows);
  // two blocks of three values each after the two offsets
  AssertLump([0, 0, 2, 1, 6, 9, 0, 0, -1, 0, 0, -1], LData);
end;

procedure TTestBlockmapBuilder.DovrebbeDareLeCelleDelleLineeVerticaliEDiagonali;
var
  LData: TBlockmapData;
  LBlock, LOffset: Integer;
  LLines: TArray<Integer>;
begin
  // a diagonal from corner to corner of a 2 by 2 area touches the blocks on the diagonal
  LData := FBuilder.Build([Point(0, 0), Point(255, 255)], [Line(0, 0, 255, 255)]);
  Assert.AreEqual(2, LData.Columns);
  Assert.AreEqual(2, LData.Rows);
  SetLength(LLines, 0);
  for LBlock := 0 to 3 do
  begin
    LOffset := LData.Lump[BLOCKMAP_HEADER_SIZE + LBlock];
    // each list is 0, [line 0], -1
    if LData.Lump[LOffset + 1] = 0 then
    begin
      SetLength(LLines, Length(LLines) + 1);
      LLines[High(LLines)] := LBlock;
    end;
  end;
  Assert.AreEqual(2, Length(LLines), 'the diagonal touches two blocks');
  Assert.AreEqual(0, LLines[0]);
  Assert.AreEqual(3, LLines[1]);

  // a vertical line goes down the two rows of a column
  LData := FBuilder.Build([Point(0, 0), Point(0, 255)], [Line(0, 0, 0, 255)]);
  Assert.AreEqual(1, LData.Columns);
  Assert.AreEqual(2, LData.Rows);
  AssertLump([0, 0, 1, 2, 6, 9, 0, 0, -1, 0, 0, -1], LData);
end;

procedure TTestBlockmapBuilder.DovrebbeUsareLaLarghezzaDellaMappaPerIlLimiteDiWrap;
var
  LData: TBlockmapData;
begin
  // regression: the old code read bmapwidth of the previous level, not the width of this blockmap
  LData := FBuilder.Build([Point(-32000, 0), Point(32000, 0)], [Line(-32000, 0, 32000, 0)]);
  Assert.AreEqual(501, LData.Columns);
  Assert.AreEqual(501 - 512, LData.NegX);
  Assert.AreEqual(BLOCKMAP_NEG_DISABLED, LData.NegY);
end;

procedure TTestBlockmapBuilder.DovrebbeDisattivareIlWrapSottoLeDimensioniMassime;
var
  LData: TBlockmapData;
begin
  LData := FBuilder.Build([Point(0, 0), Point(255 * 128 - 1, 0)], [Line(0, 0, 255 * 128 - 1, 0)]);
  Assert.AreEqual(255, LData.Columns);
  Assert.AreEqual(BLOCKMAP_NEG_DISABLED, LData.NegX);
  Assert.AreEqual(BLOCKMAP_NEG_DISABLED, LData.NegY);
end;

procedure TTestBlockmapBuilder.DovrebbeRifiutareUnLivelloSenzaVertici;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(nil, nil);
    end, EBlockmapException);
end;

procedure TTestBlockmapBuilder.DovrebbeRifiutareUnaLineaFuoriDallArea;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build([Point(0, 0), Point(64, 64)], [Line(0, 0, 5000, 5000)]);
    end, EBlockmapException);
end;

procedure TTestBlockmapBuilder.DovrebbeDareLoStessoRisultatoDueVolte;
var
  LFirst, LSecond: TBlockmapData;
  LVertexes: TArray<TBlockmapPoint>;
  LLines: TArray<TBlockmapLine>;
begin
  LVertexes := [Point(-300, -200), Point(500, 400), Point(0, 0)];
  LLines := [Line(-300, -200, 500, 400), Line(0, 0, 500, 400)];
  LFirst := FBuilder.Build(LVertexes, LLines);
  LSecond := FBuilder.Build(LVertexes, LLines);
  Assert.AreEqual(TBlockmapFingerprint.OfIntegers(LFirst.Lump),
    TBlockmapFingerprint.OfIntegers(LSecond.Lump));
  Assert.AreEqual(-300, LFirst.OriginX);
  Assert.AreEqual(-200, LFirst.OriginY);
end;

procedure TTestBlockmapBuilder.DovrebbeDareLeStesseBlockmapDelVecchioCodice;
var
  LNames: TArray<string>;
  LName: string;
  LCase: TBlockmapCase;
  LData: TBlockmapData;
  LFailures: string;
begin
  LNames := TBlockmapCase.FileNames;
  if Length(LNames) = 0 then
  begin
    Assert.Pass('no levels in Tests\Data\Blockmap');
    Exit;
  end;
  LFailures := '';
  for LName in LNames do
  begin
    LCase := TBlockmapCase.Load(LName);
    try
      LData := FBuilder.Build(LCase.Vertexes, LCase.Lines);
      if (LData.Columns <> LCase.Columns) or (LData.Rows <> LCase.Rows) or
        (Length(LData.Lump) <> LCase.LumpSize) or
        (TBlockmapFingerprint.OfIntegers(LData.Lump) <> LCase.BlockmapFingerprint) then
        LFailures := LFailures + ' ' + LCase.Name;
    finally
      LCase.Free;
    end;
  end;
  Assert.AreEqual('', LFailures, 'levels with a different blockmap');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBlockmapBuilder);

end.
