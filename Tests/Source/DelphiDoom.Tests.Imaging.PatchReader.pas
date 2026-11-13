{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingPatchReader                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.PatchReader;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf, DelphiDoom.Imaging.PatchReader,
  DelphiDoom.Imaging.Factory, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  /// <summary>A painter that records what it is asked and writes the offset of the column in the first row</summary>
  TFakePainter = class(TInterfacedObject, IImagingColumnPainter)
  public
    Offsets: TList<Integer>;
    OriginYs: TList<Integer>;
    Heights: TList<Integer>;
    constructor Create;
    destructor Destroy; override;
    procedure Paint(const ASource: TBytes; ASourceOffset: Integer; var ACache: TBytes;
      ACacheOffset, AOriginY, ACacheHeight: Integer; const AMarks: TBytes;
      AMarksOffset: Integer);
  end;

  [TestFixture]
  [Category('imaging')]
  TTestImagingPatchReader = class(TObject)
  private
    FFake: TFakePainter;
    FFakeIntf: IImagingColumnPainter;
    FReader: IImagingPatchReader;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestReadMatchesOldCodeInEveryCase;
    [Test]
    procedure TestReadGivesTheHeaderValues;
    [Test]
    procedure TestReadPaintsEveryColumnFromItsOffset;
    [Test]
    procedure TestReadPaintsFromTheTopWithTheHeightOfThePatch;
    [Test]
    procedure TestReadPutsEachColumnInItsColumn;
    [Test]
    procedure TestReadOfAnEmptyPatchGivesNoPixels;
    [Test]
    procedure TestReadOfAShortLumpRaises;
    [Test]
    procedure TestReadOfNegativeWidthRaises;
    [Test]
    procedure TestReadOfATableOutsideTheLumpRaises;
    [Test]
    procedure TestReadOfAColumnOutsideTheLumpRaises;
    [Test]
    procedure TestReadWithTheStandardPainter;
  end;

implementation

{ TFakePainter }

constructor TFakePainter.Create;
begin
  inherited Create;
  Offsets := TList<Integer>.Create;
  OriginYs := TList<Integer>.Create;
  Heights := TList<Integer>.Create;
end;

destructor TFakePainter.Destroy;
begin
  Offsets.Free;
  OriginYs.Free;
  Heights.Free;
  inherited Destroy;
end;

procedure TFakePainter.Paint(const ASource: TBytes; ASourceOffset: Integer; var ACache: TBytes;
  ACacheOffset, AOriginY, ACacheHeight: Integer; const AMarks: TBytes; AMarksOffset: Integer);
begin
  Offsets.Add(ASourceOffset);
  OriginYs.Add(AOriginY);
  Heights.Add(ACacheHeight);
  ACache[ACacheOffset] := Byte(ASourceOffset);
  AMarks[AMarksOffset] := $FF;
end;

{ TTestImagingPatchReader }

procedure TTestImagingPatchReader.Setup;
begin
  FFake := TFakePainter.Create;
  FFakeIntf := FFake;
  FReader := TImagingPatchReader.Create(FFakeIntf);
end;

procedure TTestImagingPatchReader.TestReadMatchesOldCodeInEveryCase;
var
  LCase: TSamplePatchCase;
  LImage: TImagingPatchImage;
  LReader: IImagingPatchReader;
begin
  LReader := TImagingFactory.CreatePatchReader;
  for LCase in TImagingSamples.PatchCases do
  begin
    LImage := LReader.Read(LCase.Lump);
    TImagingGolden.Check('patch.golden.txt', LCase.Name,
      Format('%dx%d:%d:%d:%s:%s', [LImage.Width, LImage.Height, LImage.LeftOffset, LImage.TopOffset,
        TImagingSamples.Hex(TImagingSamples.Hash(LImage.Pixels)),
        TImagingSamples.Hex(TImagingSamples.Hash(LImage.Opaque))]));
  end;
end;

procedure TTestImagingPatchReader.TestReadGivesTheHeaderValues;
var
  LImage: TImagingPatchImage;
begin
  LImage := FReader.Read(TImagingSamples.Patch(2, 3, -4, 5,
    [TImagingSamples.Column([])], [0, 0]));
  Assert.AreEqual(2, LImage.Width, 'dovrebbe leggere la larghezza');
  Assert.AreEqual(3, LImage.Height, 'dovrebbe leggere l''altezza');
  Assert.AreEqual(-4, LImage.LeftOffset, 'dovrebbe leggere lo scostamento sinistro');
  Assert.AreEqual(5, LImage.TopOffset, 'dovrebbe leggere lo scostamento alto');
  Assert.AreEqual<Integer>(6, Length(LImage.Pixels), 'dovrebbe dare un pixel per ogni cella');
  Assert.AreEqual<Integer>(6, Length(LImage.Opaque), 'dovrebbe dare un segno per ogni cella');
end;

procedure TTestImagingPatchReader.TestReadPaintsEveryColumnFromItsOffset;
var
  LLump: TBytes;
  LHeaderSize: Integer;
begin
  LLump := TImagingSamples.Patch(3, 2, 0, 0,
    [TImagingSamples.Column([]), TImagingSamples.Column([])], [0, 1, 0]);
  LHeaderSize := 8 + 3 * 4;
  FReader.Read(LLump);
  Assert.AreEqual(3, FFake.Offsets.Count, 'dovrebbe dipingere una volta ogni colonna');
  Assert.AreEqual(LHeaderSize, FFake.Offsets[0], 'dovrebbe dipingere la prima colonna dal suo scostamento');
  Assert.AreEqual(LHeaderSize + 1, FFake.Offsets[1], 'dovrebbe dipingere la seconda colonna dal suo scostamento');
  Assert.AreEqual(LHeaderSize, FFake.Offsets[2], 'dovrebbe poter ripetere una colonna');
end;

procedure TTestImagingPatchReader.TestReadPaintsFromTheTopWithTheHeightOfThePatch;
begin
  FReader.Read(TImagingSamples.Patch(2, 7, 0, 0, [TImagingSamples.Column([])], [0, 0]));
  Assert.AreEqual(0, FFake.OriginYs[0], 'dovrebbe dipingere con l''origine in alto');
  Assert.AreEqual(7, FFake.Heights[1], 'dovrebbe dipingere con l''altezza del patch');
end;

procedure TTestImagingPatchReader.TestReadPutsEachColumnInItsColumn;
var
  LImage: TImagingPatchImage;
  LHeaderSize: Integer;
begin
  LHeaderSize := 8 + 3 * 4;
  LImage := FReader.Read(TImagingSamples.Patch(3, 2, 0, 0,
    [TImagingSamples.Column([]), TImagingSamples.Column([])], [0, 1, 0]));
  Assert.AreEqual(Integer(Byte(LHeaderSize)), Integer(LImage.Pixels[0]), 'dovrebbe mettere la prima colonna nella colonna 0');
  Assert.AreEqual(Integer(Byte(LHeaderSize + 1)), Integer(LImage.Pixels[1]), 'dovrebbe mettere la seconda colonna nella colonna 1');
  Assert.AreEqual(Integer($FF), Integer(LImage.Opaque[2]), 'dovrebbe copiare i segni della prima riga');
  Assert.AreEqual(Integer(0), Integer(LImage.Opaque[3]), 'non dovrebbe segnare la seconda riga');
end;

procedure TTestImagingPatchReader.TestReadOfAnEmptyPatchGivesNoPixels;
var
  LImage: TImagingPatchImage;
begin
  LImage := FReader.Read(TImagingSamples.Patch(0, 0, 0, 0, [], []));
  Assert.AreEqual<Integer>(0, Length(LImage.Pixels), 'non dovrebbe dare pixel');
  Assert.AreEqual(0, FFake.Offsets.Count, 'non dovrebbe dipingere');
end;

procedure TTestImagingPatchReader.TestReadOfAShortLumpRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(TBytes.Create(1, 0, 2));
    end, EImagingException, 'dovrebbe rifiutare un lump piu'' corto dell''intestazione');
end;

procedure TTestImagingPatchReader.TestReadOfNegativeWidthRaises;
var
  LLump: TBytes;
begin
  LLump := TImagingSamples.Patch(1, 1, 0, 0, [TImagingSamples.Column([])], [0]);
  PSmallInt(@LLump[0])^ := -1;
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(LLump);
    end, EImagingException, 'dovrebbe rifiutare una larghezza negativa');
end;

procedure TTestImagingPatchReader.TestReadOfATableOutsideTheLumpRaises;
var
  LLump: TBytes;
begin
  LLump := TImagingSamples.Patch(1, 1, 0, 0, [TImagingSamples.Column([])], [0]);
  PSmallInt(@LLump[0])^ := 100;
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(LLump);
    end, EImagingException, 'dovrebbe rifiutare una tabella di colonne che esce dal lump');
end;

procedure TTestImagingPatchReader.TestReadOfAColumnOutsideTheLumpRaises;
var
  LLump: TBytes;
begin
  LLump := TImagingSamples.Patch(1, 1, 0, 0, [TImagingSamples.Column([])], [0]);
  PInteger(@LLump[8])^ := Length(LLump) + 10;
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(LLump);
    end, EImagingException, 'dovrebbe rifiutare una colonna fuori dal lump');
end;

procedure TTestImagingPatchReader.TestReadWithTheStandardPainter;
var
  LImage: TImagingPatchImage;
  LColumn: TBytes;
  LPost: TSamplePost;
begin
  LPost.TopDelta := 1;
  LPost.Length := 2;
  LPost.Seed := 3;
  LColumn := TImagingSamples.Column([LPost]);
  LImage := TImagingFactory.CreatePatchReader.Read(TImagingSamples.Patch(1, 4, 0, 0, [LColumn], [0]));
  Assert.AreEqual(Integer($FF), Integer(LImage.Opaque[1]), 'dovrebbe segnare il primo pixel del post');
  Assert.AreEqual(Integer(0), Integer(LImage.Opaque[0]), 'non dovrebbe segnare sopra il post');
  Assert.AreEqual(Integer(LColumn[3]), Integer(LImage.Pixels[1]), 'dovrebbe dare il pixel del post');
end;

end.
