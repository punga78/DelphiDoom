{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the table of the sprite headers }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.SpriteTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf, DelphiDoom.Tests.Renderer.Fakes;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererSpriteTable = class(TObject)
  private
    FDirectory: TFakeLumpDirectory;
    FDirectoryIntf: IRendererLumpDirectory;
    FHeaders: TFakeSpriteHeaders;
    FHeadersIntf: IRendererSpriteHeaders;
    FBuilder: IRendererSpriteTableBuilder;
    function Range(AFirst, ALast: Integer): TRendererLumpRange;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLarghezzaEOffsetInVirgolaFissa;
    [Test]
    procedure DovrebbeSaltareIMarcatori;
    [Test]
    procedure DovrebbeSaltareIlLumpFuoriDaUnaSezioneDiSprite;
    [Test]
    procedure DovrebbeRiprendereDopoUnNuovoMarcatoreDiInizio;
    [Test]
    procedure DovrebbeLeggereLIntestazioneDiOgniSpriteUnaSolaVolta;
    [Test]
    procedure DovrebbeDareTabelleVuoteSenzaLump;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    /// <summary>
    ///   Parity: the scan of R_InitSpriteLumps of the old r_data.pas, copied here as it was,
    ///   and the library give the same table and read the same headers, on random WADs
    /// </summary>
    [Test]
    procedure DovrebbeFareComeLaScansioneDelVecchioR_InitSpriteLumps;
  end;

implementation

// as in the old code: the header values times FRACUNIT are 32 bit integers that wrap around
{$Q-}
{$R-}

uses
  DelphiDoom.Renderer.Factory, DelphiDoom.Renderer.LumpRanges;

{ TTestRendererSpriteTable }

procedure TTestRendererSpriteTable.Setup;
begin
  FDirectory := TFakeLumpDirectory.Create;
  FDirectoryIntf := FDirectory;
  FHeaders := TFakeSpriteHeaders.Create;
  FHeadersIntf := FHeaders;
  FBuilder := TRendererFactory.CreateSpriteTableBuilder(FDirectoryIntf, FHeadersIntf);
end;

procedure TTestRendererSpriteTable.TearDown;
begin
  FBuilder := nil;
  FHeadersIntf := nil;
  FDirectoryIntf := nil;
end;

function TTestRendererSpriteTable.Range(AFirst, ALast: Integer): TRendererLumpRange;
begin
  Result.First := AFirst;
  Result.Last := ALast;
end;

procedure TTestRendererSpriteTable.DovrebbeLeggereLarghezzaEOffsetInVirgolaFissa;
var
  LTable: TRendererSpriteTable;
  LWidth: Integer;
  LLeft: Integer;
  LTop: Integer;
begin
  FDirectory.Add('TROOA1');
  FDirectory.Add('TROOA2');
  LTable := FBuilder.Build(Range(1, 1));
  FHeaders.Header(1, LWidth, LLeft, LTop);
  Assert.AreEqual<Integer>(1, Length(LTable.Width));
  Assert.AreEqual(LWidth * 65536, LTable.Width[0]);
  Assert.AreEqual(LLeft * 65536, LTable.LeftOffset[0]);
  Assert.AreEqual(LTop * 65536, LTable.TopOffset[0]);
  Assert.IsTrue(LTable.Present[0]);
end;

procedure TTestRendererSpriteTable.DovrebbeSaltareIMarcatori;
var
  LTable: TRendererSpriteTable;
begin
  FDirectory.Add('S_START');
  FDirectory.Add('TROOA1');
  FDirectory.Add('S_END');
  LTable := FBuilder.Build(Range(0, 2));
  Assert.IsFalse(LTable.Present[0]);
  Assert.AreEqual(0, LTable.Width[0]);
  Assert.IsTrue(LTable.Present[1]);
  Assert.IsFalse(LTable.Present[2]);
  Assert.AreEqual(0, LTable.Width[2]);
end;

procedure TTestRendererSpriteTable.DovrebbeSaltareIlLumpFuoriDaUnaSezioneDiSprite;
var
  LTable: TRendererSpriteTable;
begin
  FDirectory.Add('TROOA1');
  FDirectory.Add('S_END');
  FDirectory.Add('JUNK');
  LTable := FBuilder.Build(Range(0, 2));
  Assert.IsTrue(LTable.Present[0], 'the range starts in a section');
  Assert.IsFalse(LTable.Present[2], 'after the end marker');
end;

procedure TTestRendererSpriteTable.DovrebbeRiprendereDopoUnNuovoMarcatoreDiInizio;
var
  LTable: TRendererSpriteTable;
begin
  FDirectory.Add('S_END');
  FDirectory.Add('JUNK');
  FDirectory.Add('SS_START');
  FDirectory.Add('NEWA1');
  LTable := FBuilder.Build(Range(0, 3));
  Assert.IsFalse(LTable.Present[1]);
  Assert.IsTrue(LTable.Present[3]);
end;

procedure TTestRendererSpriteTable.DovrebbeLeggereLIntestazioneDiOgniSpriteUnaSolaVolta;
begin
  FDirectory.Add('S_START');
  FDirectory.Add('A1');
  FDirectory.Add('A2');
  FDirectory.Add('S_END');
  FBuilder.Build(Range(0, 3));
  Assert.AreEqual<Integer>(2, Length(FHeaders.Reads));
  Assert.AreEqual(1, FHeaders.Reads[0]);
  Assert.AreEqual(2, FHeaders.Reads[1]);
end;

procedure TTestRendererSpriteTable.DovrebbeDareTabelleVuoteSenzaLump;
var
  LTable: TRendererSpriteTable;
begin
  LTable := FBuilder.Build(Range(5, 4));
  Assert.AreEqual<Integer>(0, Length(LTable.Width));
  Assert.AreEqual<Integer>(0, Length(LTable.Present));
  LTable := FBuilder.Build(Range(5, 2));
  Assert.AreEqual<Integer>(0, Length(LTable.Width));
end;

procedure TTestRendererSpriteTable.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateSpriteTableBuilder(nil, FHeadersIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateSpriteTableBuilder(FDirectoryIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestRendererSpriteTable.DovrebbeFareComeLaScansioneDelVecchioR_InitSpriteLumps;
const
  NAMES: array[0..7] of string = ('S_START', 'S_END', 'SS_START', 'SS_END', 'TROOA1', 'TROOB1',
    'PLAYPAL', 'POSSA1');
var
  LScenario: Integer;
  LCount: Integer;
  LIndex: Integer;
  LDirectory: TFakeLumpDirectory;
  LDirectoryIntf: IRendererLumpDirectory;
  LHeaders: TFakeSpriteHeaders;
  LHeadersIntf: IRendererSpriteHeaders;
  LOldHeaders: TFakeSpriteHeaders;
  LOldHeadersIntf: IRendererSpriteHeaders;
  LTable: TRendererSpriteTable;
  LFirst: Integer;
  LLast: Integer;
  // the old code, as it was
  numspritelumps: Integer;
  spritewidth: array of Integer;
  spriteoffset: array of Integer;
  spritetopoffset: array of Integer;
  spritepresent: array of Boolean;
  in_loop: Boolean;
  lumpname: string;
  width, leftoffset, topoffset: Integer;
  i: Integer;
begin
  RandSeed := 20261116;
  for LScenario := 1 to 300 do
  begin
    LDirectory := TFakeLumpDirectory.Create;
    LDirectoryIntf := LDirectory;
    LHeaders := TFakeSpriteHeaders.Create;
    LHeadersIntf := LHeaders;
    LOldHeaders := TFakeSpriteHeaders.Create;
    LOldHeadersIntf := LOldHeaders;
    LCount := 1 + Random(40);
    for LIndex := 1 to LCount do
      LDirectory.Add(NAMES[Random(Length(NAMES))]);
    LFirst := Random(LCount);
    LLast := LFirst + Random(LCount - LFirst);

    LTable := TRendererFactory.CreateSpriteTableBuilder(LDirectoryIntf, LHeadersIntf)
      .Build(Range(LFirst, LLast));

    // the old scan
    numspritelumps := LLast - LFirst + 1;
    SetLength(spritewidth, numspritelumps);
    SetLength(spriteoffset, numspritelumps);
    SetLength(spritetopoffset, numspritelumps);
    SetLength(spritepresent, numspritelumps);
    in_loop := True;
    for i := 0 to numspritelumps - 1 do
    begin
      spritewidth[i] := 0;
      spriteoffset[i] := 0;
      spritetopoffset[i] := 0;
      spritepresent[i] := False;
      lumpname := TRendererLumpRanges.LumpNameAsText(LDirectory.LumpName(LFirst + i));
      if (lumpname = 'SS_START') or (lumpname = 'S_START') then
        in_loop := True
      else if (lumpname = 'SS_END') or (lumpname = 'S_END') then
        in_loop := False
      else if in_loop then
      begin
        LOldHeaders.Header(LFirst + i, width, leftoffset, topoffset);
        spritewidth[i] := width * 65536;
        spriteoffset[i] := leftoffset * 65536;
        spritetopoffset[i] := topoffset * 65536;
        spritepresent[i] := True;
      end;
    end;

    Assert.AreEqual<Integer>(numspritelumps, Length(LTable.Width), 'scenario ' + IntToStr(LScenario));
    for i := 0 to numspritelumps - 1 do
    begin
      Assert.AreEqual(spritewidth[i], LTable.Width[i]);
      Assert.AreEqual(spriteoffset[i], LTable.LeftOffset[i]);
      Assert.AreEqual(spritetopoffset[i], LTable.TopOffset[i]);
      Assert.AreEqual(spritepresent[i], LTable.Present[i]);
    end;
    Assert.AreEqual<Integer>(Length(LOldHeaders.Reads), Length(LHeaders.Reads));
    for i := 0 to High(LHeaders.Reads) do
      Assert.AreEqual(LOldHeaders.Reads[i], LHeaders.Reads[i]);
  end;
end;
initialization
  TDUnitX.RegisterTestFixture(TTestRendererSpriteTable);

end.
