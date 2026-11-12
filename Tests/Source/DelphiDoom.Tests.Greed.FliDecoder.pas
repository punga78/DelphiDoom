{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the FLI movies                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.FliDecoder;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliDecoder,
  DelphiDoom.Greed.FliPlayer, DelphiDoom.Tests.Greed.FliScenarios;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedFliDecoder = class(TObject)
  strict private
    FBuilder: TFliBuilder;
    FDecoder: TGreedFliDecoder;
    FPixels: TBytes;
    procedure Decode(AApproxZero: Byte = 0);
    procedure OneFrame(AType: Integer; const AData: array of Byte);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLIntestazione;
    [Test]
    procedure DovrebbeLeggereIlFilmatoDaUnaPosizione;
    [Test]
    procedure DovrebbeRifiutareUnIntestazioneCorta;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaConIlNumeroMagicoSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnFilmatoTroncato;
    [Test]
    procedure DovrebbeRifiutareUnoSchermoPiccolo;
    [Test]
    procedure DovrebbeDareFalsoDopoLUltimoFotogramma;
    [Test]
    procedure DovrebbeMoltiplicareIColoriPerQuattro;
    [Test]
    procedure DovrebbeLeggere256ColoriSeIlTotaleEZero;
    [Test]
    procedure DovrebbePartireDalColoreDettoInOgniPacchetto;
    [Test]
    procedure DovrebbeNonScrivereOltreLaPaletta;
    [Test]
    procedure DovrebbeUsareLaPalettaData;
    [Test]
    procedure DovrebbeDecodificareRipetizioniEPixelLetterali;
    [Test]
    procedure DovrebbeNonTornareAllInizioDellaRigaNelBlocco15;
    [Test]
    procedure DovrebbeCambiareSoloLeRigheDelBlocco12;
    [Test]
    procedure DovrebbeNonDisegnareLeRigheFuoriDalloSchermo;
    [Test]
    procedure DovrebbeRiempireConIlColoreVicinoAlloZero;
    [Test]
    procedure DovrebbeCopiareLoSchermoIntero;
    [Test]
    procedure DovrebbeLasciareLImmagineInUnFotogrammaVuoto;
    [Test]
    procedure DovrebbeIgnorareUnBloccoSconosciuto;
    [Test]
    procedure DovrebbeLeggereIByteDelBloccoPrecedenteSeIlBloccoECorto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedFliPlayer = class(TObject)
  strict private
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPlayer: TGreedFliPlayer;
    function Movie(AFrames, ASpeed: Integer; AWithColors: Boolean = True): TBytes;
    procedure Ticks(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaMancante;
    [Test]
    procedure DovrebbeNonSuonareUnFilmatoCheNonCE;
    [Test]
    procedure DovrebbeMostrareIlPrimoFotogrammaAllApertura;
    [Test]
    procedure DovrebbeCambiareFotogrammaQuandoIlSuoTempoEPassato;
    [Test]
    procedure DovrebbeFinireDopoLUltimoFotogramma;
    [Test]
    procedure DovrebbeFermarsiAlPrimoTastoECancellareLoSchermo;
    [Test]
    procedure DovrebbeDisegnareTuttoSubitoSeIFotogrammiDuranoZero;
    [Test]
    procedure DovrebbeTenereLaPalettaDelFilmatoPrecedente;
    [Test]
    procedure DovrebbeNonFareNullaSenzaFilmato;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedFliParity = class(TObject)
  strict private
    procedure Check(ALines: TStringList; const AGoldenName: string);
    function MoviesFolder: string;
  public
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleSuiFilmatiSintetici;
    [Test]
    procedure DovrebbeDareGliStessiSchermiDelloOriginaleSuiFilmatiDelGioco;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Greed.MenuScenarios, DelphiDoom.Tests.Greed.RealData,
  DelphiDoom.Tests.Shared.Skip;

function Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

{ TTestGreedFliDecoder }

procedure TTestGreedFliDecoder.Setup;
begin
  FBuilder := TFliBuilder.Create(200, 3);
  SetLength(FPixels, GREED_FLI_SCREEN_BYTES);
  FillChar(FPixels[0], Length(FPixels), 7);
end;

procedure TTestGreedFliDecoder.TearDown;
begin
  FreeAndNil(FDecoder);
  FreeAndNil(FBuilder);
end;

procedure TTestGreedFliDecoder.Decode(AApproxZero: Byte);
begin
  FreeAndNil(FDecoder);
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  FDecoder.ApproxZero := AApproxZero;
  while FDecoder.DecodeFrame(FPixels) do
    ;
end;

procedure TTestGreedFliDecoder.OneFrame(AType: Integer; const AData: array of Byte);
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(AType, Bytes(AData));
  FBuilder.EndFrame;
end;

procedure TTestGreedFliDecoder.DovrebbeLeggereLIntestazione;
begin
  FBuilder.BeginFrame;
  FBuilder.EndFrame;
  FBuilder.BeginFrame;
  FBuilder.EndFrame;
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  Assert.AreEqual(2, FDecoder.FrameCount);
  Assert.AreEqual(320, FDecoder.Width);
  Assert.AreEqual(200, FDecoder.Height);
  Assert.AreEqual(3, FDecoder.Speed);
  Assert.AreEqual(0, FDecoder.CurrentFrame);
  Assert.AreEqual(768, Integer(Length(FDecoder.Palette)));
  Assert.IsFalse(FDecoder.PaletteChanged);
end;

procedure TTestGreedFliDecoder.DovrebbeLeggereIlFilmatoDaUnaPosizione;
var
  LBuilder: TFliBuilder;
begin
  LBuilder := TFliBuilder.Create(120, 9, 37);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(GREED_FLI_CHUNK_CLEAR, nil);
    LBuilder.EndFrame;
    FDecoder := TGreedFliDecoder.Create(LBuilder.Build, 37);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(1, FDecoder.FrameCount);
  Assert.AreEqual(120, FDecoder.Height);
  Assert.AreEqual(9, FDecoder.Speed);
  FDecoder.ApproxZero := 5;
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(Byte(5), FPixels[0]);
end;

procedure TTestGreedFliDecoder.DovrebbeRifiutareUnIntestazioneCorta;
var
  LData: TBytes;
begin
  SetLength(LData, 127);
  Assert.WillRaise(
    procedure
    begin
      TGreedFliDecoder.Create(LData).Free;
    end, EGreedDataException);
  SetLength(LData, 200);
  Assert.WillRaise(
    procedure
    begin
      TGreedFliDecoder.Create(LData, 73).Free;
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      TGreedFliDecoder.Create(LData, -1).Free;
    end, EGreedDataException);
end;

procedure TTestGreedFliDecoder.DovrebbeRifiutareUnFotogrammaConIlNumeroMagicoSbagliato;
begin
  FBuilder.BeginFrame($F1FB);
  FBuilder.EndFrame;
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  Assert.WillRaise(
    procedure
    begin
      FDecoder.DecodeFrame(FPixels);
    end, EGreedDataException);
end;

procedure TTestGreedFliDecoder.DovrebbeRifiutareUnFilmatoTroncato;
var
  LData: TBytes;
  LCut: Integer;
begin
  OneFrame(GREED_FLI_CHUNK_COPY, [1, 2, 3, 4, 5, 6, 7, 8]);
  LData := FBuilder.Build;
  // inside the data of the chunk, inside its header, inside the header of the frame
  for LCut in TArray<Integer>.Create(3, 10, 20) do
  begin
    FreeAndNil(FDecoder);
    FDecoder := TGreedFliDecoder.Create(Copy(LData, 0, Length(LData) - LCut));
    Assert.WillRaise(
      procedure
      begin
        FDecoder.DecodeFrame(FPixels);
      end, EGreedDataException, 'taglio ' + IntToStr(LCut));
  end;
end;

procedure TTestGreedFliDecoder.DovrebbeRifiutareUnoSchermoPiccolo;
var
  LSmall: TBytes;
begin
  FBuilder.BeginFrame;
  FBuilder.EndFrame;
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  SetLength(LSmall, 63999);
  Assert.WillRaise(
    procedure
    begin
      FDecoder.DecodeFrame(LSmall);
    end, EGreedException);
end;

procedure TTestGreedFliDecoder.DovrebbeDareFalsoDopoLUltimoFotogramma;
begin
  FBuilder.BeginFrame;
  FBuilder.EndFrame;
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(1, FDecoder.CurrentFrame);
  Assert.IsFalse(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(1, FDecoder.CurrentFrame);
end;

procedure TTestGreedFliDecoder.DovrebbeMoltiplicareIColoriPerQuattro;
begin
  // one packet: skip 2 colors, 2 colors
  OneFrame(GREED_FLI_CHUNK_COLORS, [1, 0, 2, 2, 1, 2, 3, 63, 64, 65]);
  Decode;
  Assert.IsTrue(FDecoder.PaletteChanged);
  Assert.AreEqual(Byte(0), FDecoder.Palette[5]);
  Assert.AreEqual(Byte(4), FDecoder.Palette[6]);
  Assert.AreEqual(Byte(8), FDecoder.Palette[7]);
  Assert.AreEqual(Byte(12), FDecoder.Palette[8]);
  Assert.AreEqual(Byte(252), FDecoder.Palette[9]);
  Assert.AreEqual(Byte(0), FDecoder.Palette[10], '64 * 4 avvolge nel byte');
  Assert.AreEqual(Byte(4), FDecoder.Palette[11]);
  // the color nearest to the color 0 (black): the 4 is the first that is black as well
  Assert.AreEqual(Byte(1), FDecoder.ApproxZero);
end;

procedure TTestGreedFliDecoder.DovrebbeLeggere256ColoriSeIlTotaleEZero;
var
  LData: TBytes;
  LIndex: Integer;
begin
  SetLength(LData, 4 + 768);
  LData[0] := 1;
  for LIndex := 0 to 767 do
    LData[4 + LIndex] := 10;
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_COLORS, LData);
  FBuilder.EndFrame;
  Decode;
  Assert.AreEqual(Byte(40), FDecoder.Palette[0]);
  Assert.AreEqual(Byte(40), FDecoder.Palette[767]);
end;

procedure TTestGreedFliDecoder.DovrebbePartireDalColoreDettoInOgniPacchetto;
begin
  // two packets, each "skip 1, one color": the FLI format says color 1 and color 3, the original writes both on 1
  OneFrame(GREED_FLI_CHUNK_COLORS, [2, 0, 1, 1, 5, 5, 5, 1, 1, 9, 9, 9]);
  Decode;
  Assert.AreEqual(Byte(36), FDecoder.Palette[3]);
  Assert.AreEqual(Byte(0), FDecoder.Palette[9]);
end;

procedure TTestGreedFliDecoder.DovrebbeNonScrivereOltreLaPaletta;
begin
  // skip 255, 3 colors: the second and the third would be after the palette
  OneFrame(GREED_FLI_CHUNK_COLORS, [1, 0, 255, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3]);
  Decode;
  Assert.AreEqual(Byte(4), FDecoder.Palette[767]);
  Assert.AreEqual(768, Integer(Length(FDecoder.Palette)));
end;

procedure TTestGreedFliDecoder.DovrebbeUsareLaPalettaData;
var
  LPalette: TBytes;
begin
  SetLength(LPalette, 768);
  LPalette[700] := 99;
  OneFrame(GREED_FLI_CHUNK_COLORS, [1, 0, 0, 1, 2, 2, 2]);
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build, 0, LPalette);
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(Byte(99), FDecoder.Palette[700], 'i colori del filmato di prima restano');
  Assert.AreEqual(Byte(8), LPalette[0], 'la paletta data e'' cambiata sul posto');
end;

procedure TTestGreedFliDecoder.DovrebbeDecodificareRipetizioniEPixelLetterali;
var
  LBuilder: TFliBuilder;
begin
  // a movie one row high: 2 packets, "3 times 9" and "2 literal pixels 4, 0"
  LBuilder := TFliBuilder.Create(1, 1);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(GREED_FLI_CHUNK_RUN, Bytes([2, 3, 9, $FE, 4, 0]));
    LBuilder.EndFrame;
    FDecoder := TGreedFliDecoder.Create(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  FDecoder.ApproxZero := 200;
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(Byte(9), FPixels[0]);
  Assert.AreEqual(Byte(9), FPixels[2]);
  Assert.AreEqual(Byte(4), FPixels[3]);
  Assert.AreEqual(Byte(200), FPixels[4], 'lo zero diventa il colore vicino allo zero');
  Assert.AreEqual(Byte(7), FPixels[5]);
end;

procedure TTestGreedFliDecoder.DovrebbeNonTornareAllInizioDellaRigaNelBlocco15;
var
  LBuilder: TFliBuilder;
begin
  // two rows of one packet of 2 pixels each: the second row starts where the first ended, not at the pixel 320
  LBuilder := TFliBuilder.Create(2, 1);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(GREED_FLI_CHUNK_RUN, Bytes([1, 2, 11, 1, 2, 12]));
    LBuilder.EndFrame;
    FDecoder := TGreedFliDecoder.Create(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(Byte(11), FPixels[1]);
  Assert.AreEqual(Byte(12), FPixels[2]);
  Assert.AreEqual(Byte(12), FPixels[3]);
  Assert.AreEqual(Byte(7), FPixels[320]);
end;

procedure TTestGreedFliDecoder.DovrebbeCambiareSoloLeRigheDelBlocco12;
begin
  // from the row 2, 2 rows: the first has "skip 5, 3 times 9" and "skip 1, 2 literal pixels"; the second nothing
  OneFrame(GREED_FLI_CHUNK_LINES, [2, 0, 2, 0, 2, 5, $FD, 9, 1, 2, 21, 22, 0]);
  Decode(33);
  Assert.AreEqual(Byte(7), FPixels[2 * 320 + 4]);
  Assert.AreEqual(Byte(9), FPixels[2 * 320 + 5]);
  Assert.AreEqual(Byte(9), FPixels[2 * 320 + 7]);
  Assert.AreEqual(Byte(7), FPixels[2 * 320 + 8]);
  Assert.AreEqual(Byte(21), FPixels[2 * 320 + 9]);
  Assert.AreEqual(Byte(22), FPixels[2 * 320 + 10]);
  Assert.AreEqual(Byte(7), FPixels[3 * 320]);
  Assert.AreEqual(Byte(7), FPixels[0]);
end;

procedure TTestGreedFliDecoder.DovrebbeNonDisegnareLeRigheFuoriDalloSchermo;
begin
  // the row 199 with a run that passes the end of the screen, then the row 200
  OneFrame(GREED_FLI_CHUNK_LINES, [199, 0, 2, 0, 2, 255, 0, 63, $80, 9, 1, 0, 2, 4, 4]);
  Decode;
  Assert.AreEqual(Byte(9), FPixels[63999]);
  Assert.AreEqual(Byte(9), FPixels[199 * 320 + 318]);
  Assert.AreEqual(Byte(7), FPixels[199 * 320 + 317]);
  Assert.AreEqual(64000, Integer(Length(FPixels)));
end;

procedure TTestGreedFliDecoder.DovrebbeRiempireConIlColoreVicinoAlloZero;
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_CLEAR, nil);
  FBuilder.EndFrame;
  Decode(42);
  Assert.AreEqual(Byte(42), FPixels[0]);
  Assert.AreEqual(Byte(42), FPixels[63999]);
end;

procedure TTestGreedFliDecoder.DovrebbeCopiareLoSchermoIntero;
var
  LData: TBytes;
begin
  SetLength(LData, 64000);
  LData[0] := 3;
  LData[63999] := 4;
  FBuilder.BeginFrame;
  FBuilder.Chunk(GREED_FLI_CHUNK_COPY, LData);
  FBuilder.EndFrame;
  Decode(50);
  Assert.AreEqual(Byte(3), FPixels[0]);
  Assert.AreEqual(Byte(50), FPixels[1]);
  Assert.AreEqual(Byte(4), FPixels[63999]);
end;

procedure TTestGreedFliDecoder.DovrebbeLasciareLImmagineInUnFotogrammaVuoto;
begin
  // the size of the frame is 0: its chunk is not read as a chunk (and is not a frame: the movie ends there)
  FBuilder.BeginFrame;
  FBuilder.EndFrame(True);
  FDecoder := TGreedFliDecoder.Create(FBuilder.Build);
  FDecoder.ApproxZero := 9;
  Assert.IsTrue(FDecoder.DecodeFrame(FPixels));
  Assert.AreEqual(Byte(7), FPixels[0]);
  Assert.IsFalse(FDecoder.PaletteChanged);
end;

procedure TTestGreedFliDecoder.DovrebbeIgnorareUnBloccoSconosciuto;
begin
  FBuilder.BeginFrame;
  FBuilder.Chunk(4, Bytes([1, 0, 0, 1, 9, 9, 9]));
  FBuilder.Chunk(7, Bytes([1, 2, 3]));
  FBuilder.Chunk(GREED_FLI_CHUNK_CLEAR, nil);
  FBuilder.EndFrame;
  Decode(6);
  Assert.IsFalse(FDecoder.PaletteChanged);
  Assert.AreEqual(Byte(0), FDecoder.Palette[0]);
  Assert.AreEqual(Byte(6), FPixels[100], 'il blocco dopo quelli sconosciuti e'' letto');
end;

procedure TTestGreedFliDecoder.DovrebbeLeggereIByteDelBloccoPrecedenteSeIlBloccoECorto;
begin
  // the second chunk says "1 packet" and ends: skip, total and color are the bytes 2.. left by the first chunk
  FBuilder.BeginFrame;
  FBuilder.Chunk(4, Bytes([0, 0, 3, 1, 20, 21, 22]));
  FBuilder.Chunk(GREED_FLI_CHUNK_COLORS, Bytes([1, 0]));
  FBuilder.EndFrame;
  Decode;
  Assert.AreEqual(Byte(80), FDecoder.Palette[9]);
  Assert.AreEqual(Byte(84), FDecoder.Palette[10]);
  Assert.AreEqual(Byte(88), FDecoder.Palette[11]);
end;

{ TTestGreedFliPlayer }

procedure TTestGreedFliPlayer.Setup;
begin
  FArchive := TMenuScenarios.SyntheticArchive;
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, FArchive);
  FInput := TGreedMenuInput.Create;
  FPlayer := TGreedFliPlayer.Create(FDisplay, FInput);
  FDisplay.SetPalette(TFliScenarios.StartPalette);
  FCanvas.PutPixel(0, 0, 77);
end;

procedure TTestGreedFliPlayer.TearDown;
begin
  FPlayer.Free;
  FInput.Free;
  FDisplay.Free;
  FCanvas.Free;
  FArchive := nil;
end;

function TTestGreedFliPlayer.Movie(AFrames, ASpeed: Integer; AWithColors: Boolean): TBytes;
var
  LBuilder: TFliBuilder;
  LFrame: Integer;
begin
  // the frame n is the screen copied with the pixel 0 = 10 + n; the first frame makes the color 5 white
  LBuilder := TFliBuilder.Create(200, ASpeed);
  try
    for LFrame := 0 to AFrames - 1 do
    begin
      LBuilder.BeginFrame;
      if (LFrame = 0) and AWithColors then
        LBuilder.Chunk(GREED_FLI_CHUNK_COLORS, Bytes([1, 0, 5, 1, 63, 63, 63]));
      LBuilder.Chunk(GREED_FLI_CHUNK_LINES, Bytes([0, 0, 1, 0, 1, 0, 1, 10 + LFrame]));
      LBuilder.EndFrame;
    end;
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestGreedFliPlayer.Ticks(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FPlayer.Tick;
end;

procedure TTestGreedFliPlayer.DovrebbeRifiutareUnaDipendenzaMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedFliPlayer.Create(nil, FInput).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedFliPlayer.Create(FDisplay, nil).Free;
    end, EArgumentNilException);
end;

procedure TTestGreedFliPlayer.DovrebbeNonSuonareUnFilmatoCheNonCE;
var
  LVersion: Integer;
begin
  LVersion := FDisplay.PaletteVersion;
  FPlayer.Open(nil);
  Assert.IsFalse(FPlayer.Active);
  Assert.IsFalse(FPlayer.Completed);
  Assert.IsNull(FPlayer.Decoder);
  Assert.AreEqual(Byte(77), FCanvas.GetPixel(0, 0), 'lo schermo resta');
  Assert.AreEqual(LVersion, FDisplay.PaletteVersion);
  Assert.AreEqual(1, FDisplay.RenderClears, 'il livello sotto lo schermo e'' cancellato lo stesso');
end;

procedure TTestGreedFliPlayer.DovrebbeMostrareIlPrimoFotogrammaAllApertura;
begin
  FInput.NewAscii := True;
  FPlayer.Open(Movie(3, 4));
  Assert.IsTrue(FPlayer.Active);
  Assert.IsFalse(FInput.NewAscii, 'un tasto di prima non ferma il filmato');
  Assert.AreEqual(Byte(10), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(0, FPlayer.Frame);
  Assert.AreEqual(Byte(252), FDisplay.Palette[15], 'il colore 5 del filmato');
  Assert.AreEqual(Byte(0), FDisplay.Palette[0], 'il resto e'' nero');
  // the screen was filled with the color nearest to the color 0 of the palette of before
  Assert.AreNotEqual(Byte(0), FCanvas.GetPixel(5, 5));
  Assert.AreEqual(1, FDisplay.RenderClears);
end;

procedure TTestGreedFliPlayer.DovrebbeCambiareFotogrammaQuandoIlSuoTempoEPassato;
begin
  FPlayer.Open(Movie(3, 4));
  Ticks(3);
  Assert.AreEqual(Byte(10), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(0, FPlayer.Frame);
  Ticks(1);
  Assert.AreEqual(Byte(11), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(1, FPlayer.Frame);
  Assert.AreEqual(2, FPlayer.Decoder.CurrentFrame);
end;

procedure TTestGreedFliPlayer.DovrebbeFinireDopoLUltimoFotogramma;
begin
  FPlayer.Open(Movie(3, 4));
  Ticks(11);
  Assert.IsTrue(FPlayer.Active);
  Ticks(1);
  Assert.IsFalse(FPlayer.Active);
  Assert.IsTrue(FPlayer.Completed);
  Assert.AreEqual(3, FPlayer.Frame);
  Assert.AreEqual(Byte(12), FCanvas.GetPixel(0, 0), 'l''ultimo fotogramma resta sullo schermo');
  Assert.AreEqual(12, FInput.TimeCount);
end;

procedure TTestGreedFliPlayer.DovrebbeFermarsiAlPrimoTastoECancellareLoSchermo;
begin
  FPlayer.Open(Movie(10, 4));
  Ticks(5);
  FInput.PressKey(gmkSpace, True);
  Ticks(2);
  Assert.IsTrue(FPlayer.Active, 'il fotogramma in corso finisce il suo tempo');
  Ticks(1);
  Assert.IsFalse(FPlayer.Active);
  Assert.IsFalse(FPlayer.Completed);
  Assert.AreEqual(2, FPlayer.Frame);
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(319, 199));
end;

procedure TTestGreedFliPlayer.DovrebbeDisegnareTuttoSubitoSeIFotogrammiDuranoZero;
begin
  FPlayer.Open(Movie(5, 0));
  Assert.IsFalse(FPlayer.Active);
  Assert.IsTrue(FPlayer.Completed);
  Assert.AreEqual(Byte(14), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(0, FInput.TimeCount);
end;

procedure TTestGreedFliPlayer.DovrebbeTenereLaPalettaDelFilmatoPrecedente;
begin
  FPlayer.Open(Movie(1, 0));
  // the second movie changes the color 6 only: the color 5 of the first is still there
  FPlayer.Open(Bytes([]));
  FPlayer.Open(Movie(1, 0, False));
  Assert.AreEqual(Byte(0), FDisplay.Palette[15], 'senza blocco di colori la paletta mostrata resta nera');
  Assert.AreEqual(Byte(252), FPlayer.Decoder.Palette[15]);
end;

procedure TTestGreedFliPlayer.DovrebbeNonFareNullaSenzaFilmato;
begin
  FInput.TimeCount := 9;
  FPlayer.Tick;
  FPlayer.Step;
  Assert.AreEqual(9, FInput.TimeCount);
  Assert.IsFalse(FPlayer.Active);
end;

{ TTestGreedFliParity }

procedure TTestGreedFliParity.Check(ALines: TStringList; const AGoldenName: string);
var
  LGolden: TStringList;
  LIndex, LDifferent: Integer;
  LFirst: string;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath(AGoldenName));
    Assert.AreEqual(LGolden.Count, ALines.Count, 'the golden file has other movies');
    LDifferent := 0;
    LFirst := '';
    for LIndex := 0 to ALines.Count - 1 do
      if ALines[LIndex] <> LGolden[LIndex] then
      begin
        if LDifferent = 0 then
          LFirst := LGolden[LIndex] + ' / ' + ALines[LIndex];
        Inc(LDifferent);
      end;
    Assert.AreEqual(0, LDifferent, 'movies that differ from the original; the first (original / library): ' +
      LFirst);
  finally
    LGolden.Free;
    ALines.Free;
  end;
end;

function TTestGreedFliParity.MoviesFolder: string;
var
  LRoot: string;
begin
  // Reference\_dati\greed\cdrom, beside the folders of the game and of the demos
  Result := '';
  if TGreedRealData.FullFolder <> '' then
    LRoot := ExtractFileDir(ExcludeTrailingPathDelimiter(TGreedRealData.FullFolder))
  else if TGreedRealData.Demo1016Folder <> '' then
    LRoot := ExtractFileDir(ExcludeTrailingPathDelimiter(TGreedRealData.Demo1016Folder))
  else
    Exit;
  if TDirectory.Exists(TPath.Combine(LRoot, 'cdrom')) then
    Result := TPath.Combine(LRoot, 'cdrom');
end;

procedure TTestGreedFliParity.DovrebbeDareGliStessiSchermiDelloOriginaleSuiFilmatiSintetici;
begin
  Check(FliLibraryLines, 'fli.golden.txt');
end;

procedure TTestGreedFliParity.DovrebbeDareGliStessiSchermiDelloOriginaleSuiFilmatiDelGioco;
var
  LFolder: string;
begin
  LFolder := MoviesFolder;
  if Length(FliFiles(LFolder)) = 0 then
    TTestSkip.Ignore('i filmati del gioco (cdrom\...\MOVIES\*.FLI) non ci sono');
  Check(FliLibraryFileLines(LFolder), 'fli.full.golden.txt');
end;

end.
