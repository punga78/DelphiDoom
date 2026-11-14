{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingMeltWipe                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.MeltWipe;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.MeltWipe, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden, DelphiDoom.Tests.Imaging.OldWipe;

type
  /// <summary>The numbers of the generator of the Samples unit, as a source of random bytes</summary>
  TSampleRandomSource = class(TInterfacedObject, IImagingRandom)
  private
    FRandom: TSampleRandom;
  public
    constructor Create(ASeed: Cardinal);
    function NextByte: Byte;
  end;

  /// <summary>A source of random bytes that counts its calls and always gives the same value</summary>
  TConstantRandom = class(TInterfacedObject, IImagingRandom)
  private
    FValue: Byte;
  public
    Calls: Integer;
    constructor Create(AValue: Byte);
    function NextByte: Byte;
  end;

  [TestFixture]
  [Category('imaging')]
  TTestImagingMeltWipe = class(TObject)
  private
    function Settings(AWidth, AHeight, APitch: Integer; AAlpha: Cardinal): TImagingWipeSettings;
    function Screen(AWidth, AHeight: Integer; AColor: Cardinal): TImagingPixels;
  public
    [Test]
    procedure TestAdvanceMatchesOldCodeInEveryCase;
    [Test]
    procedure TestStartCopiesTheStartScreenToTheDestination;
    [Test]
    procedure TestStartUsesThePitchOfTheDestination;
    [Test]
    procedure TestStartAsksForThreeHundredTwentyRandomBytes;
    [Test]
    procedure TestAdvanceFinishesTheWipe;
    [Test]
    procedure TestAdvanceWithZeroTicksGivesTrue;
    [Test]
    procedure TestAdvanceAppliesTheAlphaMask;
    [Test]
    procedure TestAdvanceLeavesThePaddingOfThePitchAlone;
    [Test]
    procedure TestAdvanceBeforeStartRaises;
    [Test]
    procedure TestStartWithBadSettingsRaises;
    [Test]
    procedure TestStartWithSmallBuffersRaises;
    [Test]
    procedure DovrebbeDareLoStessoDelVecchioCodiceSuiBufferDelChiamante;
    [Test]
    procedure DovrebbeRifiutareUnBufferNilInStartOnBuffers;
    [Test]
    procedure DovrebbeRifiutareImpostazioniSbagliateInStartOnBuffers;
    [Test]
    procedure DovrebbeRicominciareSuAltriBufferDopoUnMeltFinito;
  end;

implementation

{ TSampleRandomSource }

constructor TSampleRandomSource.Create(ASeed: Cardinal);
begin
  inherited Create;
  FRandom := TSampleRandom.Create(ASeed);
end;

function TSampleRandomSource.NextByte: Byte;
begin
  Result := FRandom.NextByte;
end;

{ TConstantRandom }

constructor TConstantRandom.Create(AValue: Byte);
begin
  inherited Create;
  FValue := AValue;
end;

function TConstantRandom.NextByte: Byte;
begin
  Inc(Calls);
  Result := FValue;
end;

{ TTestImagingMeltWipe }

function TTestImagingMeltWipe.Settings(AWidth, AHeight, APitch: Integer;
  AAlpha: Cardinal): TImagingWipeSettings;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.DestinationPitch := APitch;
  Result.AlphaMask := AAlpha;
end;

function TTestImagingMeltWipe.Screen(AWidth, AHeight: Integer; AColor: Cardinal): TImagingPixels;
var
  LIndex: Integer;
begin
  SetLength(Result, AWidth * AHeight);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := AColor;
end;

procedure TTestImagingMeltWipe.TestAdvanceMatchesOldCodeInEveryCase;
var
  LCase: TSampleWipeCase;
  LWipe: IImagingMeltWipe;
  LStart, LEnd, LDestination: TImagingPixels;
  LTick: Integer;
  LDone: Boolean;
begin
  for LCase in TImagingSamples.WipeCases do
  begin
    LStart := TImagingSamples.RandomPixels(LCase.Seed + 1, LCase.Width * LCase.Height, $00FFFFFF);
    LEnd := TImagingSamples.RandomPixels(LCase.Seed + 2, LCase.Width * LCase.Height, $00FFFFFF);
    SetLength(LDestination, LCase.Pitch * LCase.Height);
    FillChar(LDestination[0], Length(LDestination) * SizeOf(Cardinal), 0);
    LWipe := TImagingMeltWipe.Create(TSampleRandomSource.Create(LCase.Seed));
    LWipe.Start(Settings(LCase.Width, LCase.Height, LCase.Pitch, LCase.AlphaMask), LStart, LEnd,
      LDestination);
    TImagingGolden.Check('wipe.golden.txt', LCase.Name + '.start',
      TImagingSamples.Hex(TImagingSamples.Hash(LDestination)));
    for LTick := 0 to High(LCase.Ticks) do
    begin
      LDone := LWipe.Advance(LCase.Ticks[LTick]);
      TImagingGolden.Check('wipe.golden.txt', Format('%s.%d', [LCase.Name, LTick]),
        IntToStr(Ord(LDone)) + ':' + TImagingSamples.Hex(TImagingSamples.Hash(LDestination)));
    end;
  end;
end;

procedure TTestImagingMeltWipe.TestStartCopiesTheStartScreenToTheDestination;
var
  LWipe: IImagingMeltWipe;
  LDestination: TImagingPixels;
begin
  LDestination := Screen(4, 3, 0);
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LWipe.Start(Settings(4, 3, 4, 0), Screen(4, 3, $00112233), Screen(4, 3, $00445566), LDestination);
  Assert.AreEqual(Cardinal($00112233), LDestination[0], 'dovrebbe mettere il primo pixel della schermata di partenza');
  Assert.AreEqual(Cardinal($00112233), LDestination[11], 'dovrebbe mettere l''ultimo pixel della schermata di partenza');
end;

procedure TTestImagingMeltWipe.TestStartUsesThePitchOfTheDestination;
var
  LWipe: IImagingMeltWipe;
  LDestination: TImagingPixels;
  LStart: TImagingPixels;
begin
  LDestination := Screen(8, 2, $DEADBEEF);
  LStart := Screen(4, 2, $00112233);
  LStart[4] := $00AABBCC;
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LWipe.Start(Settings(4, 2, 8, 0), LStart, Screen(4, 2, 0), LDestination);
  Assert.AreEqual(Cardinal($00AABBCC), LDestination[8], 'dovrebbe cominciare la seconda riga dopo il passo');
  Assert.AreEqual(Cardinal($DEADBEEF), LDestination[4], 'non dovrebbe toccare il margine del passo');
end;

procedure TTestImagingMeltWipe.TestStartAsksForThreeHundredTwentyRandomBytes;
var
  LRandom: TConstantRandom;
  LRandomIntf: IImagingRandom;
  LWipe: IImagingMeltWipe;
begin
  LRandom := TConstantRandom.Create(0);
  LRandomIntf := LRandom;
  LWipe := TImagingMeltWipe.Create(LRandomIntf);
  LWipe.Start(Settings(4, 3, 4, 0), Screen(4, 3, 1), Screen(4, 3, 2), Screen(4, 3, 0));
  Assert.AreEqual(320, LRandom.Calls, 'dovrebbe chiedere un byte per ognuna delle 320 posizioni');
end;

procedure TTestImagingMeltWipe.TestAdvanceFinishesTheWipe;
var
  LWipe: IImagingMeltWipe;
  LTick: Integer;
  LDone: Boolean;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(7));
  LWipe.Start(Settings(16, 20, 16, 0), Screen(16, 20, 1), Screen(16, 20, 2), Screen(16, 20, 0));
  LDone := False;
  LTick := 0;
  while (not LDone) and (LTick < 1000) do
  begin
    LDone := LWipe.Advance(1);
    Inc(LTick);
  end;
  Assert.IsTrue(LDone, 'dovrebbe finire entro 1000 tic');
  Assert.IsTrue(LWipe.Advance(1), 'dovrebbe restare finita');
end;

procedure TTestImagingMeltWipe.TestAdvanceWithZeroTicksGivesTrue;
var
  LWipe: IImagingMeltWipe;
begin
  // come il vecchio codice: senza tic non c'e'' nulla che muova una colonna
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(7));
  LWipe.Start(Settings(8, 8, 8, 0), Screen(8, 8, 1), Screen(8, 8, 2), Screen(8, 8, 0));
  Assert.IsTrue(LWipe.Advance(0), 'dovrebbe dare vero con zero tic');
end;

procedure TTestImagingMeltWipe.TestAdvanceAppliesTheAlphaMask;
var
  LWipe: IImagingMeltWipe;
  LDestination: TImagingPixels;
  LTick: Integer;
begin
  LDestination := Screen(8, 40, 0);
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LWipe.Start(Settings(8, 40, 8, $FF000000), Screen(8, 40, $00000001), Screen(8, 40, $00000002), LDestination);
  for LTick := 1 to 30 do
    LWipe.Advance(1);
  Assert.AreEqual(Cardinal($FF000002), LDestination[0], 'dovrebbe mettere l''alfa sui pixel della nuova schermata');
end;

procedure TTestImagingMeltWipe.TestAdvanceLeavesThePaddingOfThePitchAlone;
var
  LWipe: IImagingMeltWipe;
  LDestination: TImagingPixels;
  LTick, LRow: Integer;
begin
  LDestination := Screen(16, 20, $DEADBEEF);
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LWipe.Start(Settings(8, 20, 16, 0), Screen(8, 20, 1), Screen(8, 20, 2), LDestination);
  for LTick := 1 to 60 do
    LWipe.Advance(1);
  for LRow := 0 to 19 do
    Assert.AreEqual(Cardinal($DEADBEEF), LDestination[LRow * 16 + 12], 'dovrebbe lasciare il margine della riga ' + IntToStr(LRow));
end;

procedure TTestImagingMeltWipe.TestAdvanceBeforeStartRaises;
var
  LWipe: IImagingMeltWipe;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  Assert.WillRaise(
    procedure
    begin
      LWipe.Advance(1);
    end, EImagingException, 'dovrebbe rifiutare Advance senza Start');
end;

procedure TTestImagingMeltWipe.TestStartWithBadSettingsRaises;
var
  LWipe: IImagingMeltWipe;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(0, 4, 4, 0), nil, nil, nil);
    end, EImagingException, 'dovrebbe rifiutare la larghezza zero');
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(4, 0, 4, 0), nil, nil, nil);
    end, EImagingException, 'dovrebbe rifiutare l''altezza zero');
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(8, 4, 4, 0), Screen(8, 4, 0), Screen(8, 4, 0), Screen(8, 4, 0));
    end, EImagingException, 'dovrebbe rifiutare un passo piu'' piccolo della larghezza');
end;

procedure TTestImagingMeltWipe.TestStartWithSmallBuffersRaises;
var
  LWipe: IImagingMeltWipe;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(4, 4, 4, 0), Screen(4, 3, 0), Screen(4, 4, 0), Screen(4, 4, 0));
    end, EImagingException, 'dovrebbe rifiutare una schermata di partenza troppo piccola');
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(4, 4, 4, 0), Screen(4, 4, 0), Screen(4, 3, 0), Screen(4, 4, 0));
    end, EImagingException, 'dovrebbe rifiutare una schermata di arrivo troppo piccola');
  Assert.WillRaise(
    procedure
    begin
      LWipe.Start(Settings(4, 4, 4, 0), Screen(4, 4, 0), Screen(4, 4, 0), Screen(4, 3, 0));
    end, EImagingException, 'dovrebbe rifiutare una destinazione troppo piccola');
end;

procedure TTestImagingMeltWipe.DovrebbeDareLoStessoDelVecchioCodiceSuiBufferDelChiamante;
const
  SCENARIOS = 150;
var
  LScenario: Integer;
  LRandom: TSampleRandom;
  LWidth, LHeight, LPitch, LTicks, LStep: Integer;
  LOpenGl: Boolean;
  LStart, LEnd, LOldScreen, LNewScreen: TImagingPixels;
  LOld: TOldWipe;
  LNew: IImagingMeltWipe;
  LOldDone, LNewDone: Boolean;
  LWhere: string;
begin
  for LScenario := 1 to SCENARIOS do
  begin
    LRandom := TSampleRandom.Create(Cardinal(LScenario) * 7919);
    LWidth := 1 + Integer(LRandom.NextCardinal shr 8) mod 400;
    LHeight := 1 + Integer(LRandom.NextCardinal shr 8) mod 260;
    LOpenGl := (LRandom.NextByte and 1) = 1;
    LPitch := LWidth;
    if LOpenGl then
    begin
      // the power of two of wipe_glsize
      LPitch := 1;
      while LPitch < LWidth do
        LPitch := LPitch * 2;
    end;
    LStart := TImagingSamples.RandomPixels(LScenario * 3 + 1, LWidth * LHeight, $00FFFFFF);
    LEnd := TImagingSamples.RandomPixels(LScenario * 3 + 2, LWidth * LHeight, $00FFFFFF);
    LOldScreen := TImagingSamples.RandomPixels(LScenario * 3 + 3, LPitch * LHeight, $FFFFFFFF);
    LNewScreen := Copy(LOldScreen);

    LOld := TOldWipe.Create(TSampleRandomSource.Create(LScenario));
    try
      LOld.SCREENWIDTH := LWidth;
      LOld.SCREENHEIGHT := LHeight;
      LOld.WIPESCREENWIDTH := LPitch;
      LOld.OpenGl := LOpenGl;
      LOld.wipe_scr_start := @LStart[0];
      LOld.wipe_scr_end := @LEnd[0];
      LOld.screen := @LOldScreen[0];
      LOld.wipe_initMelt;

      LNew := TImagingMeltWipe.Create(TSampleRandomSource.Create(LScenario));
      if LOpenGl then
        LNew.StartOnBuffers(Settings(LWidth, LHeight, LPitch, $FF000000), @LStart[0], @LEnd[0],
          @LNewScreen[0])
      else
        LNew.StartOnBuffers(Settings(LWidth, LHeight, LPitch, 0), @LStart[0], @LEnd[0],
          @LNewScreen[0]);
      LWhere := Format('scenario %d (%dx%d passo %d)', [LScenario, LWidth, LHeight, LPitch]);
      Assert.AreEqual(TImagingSamples.Hash(LOldScreen), TImagingSamples.Hash(LNewScreen),
        'dovrebbe copiare la schermata di partenza come il vecchio: ' + LWhere);

      LStep := 0;
      repeat
        Inc(LStep);
        LTicks := LRandom.NextByte mod 4;
        LOldDone := LOld.wipe_doMelt(LTicks) <> 0;
        LNewDone := LNew.Advance(LTicks);
        Assert.AreEqual(LOldDone, LNewDone,
          Format('dovrebbe finire quando finisce il vecchio: %s passo %d', [LWhere, LStep]));
        Assert.AreEqual(TImagingSamples.Hash(LOldScreen), TImagingSamples.Hash(LNewScreen),
          Format('dovrebbe scrivere gli stessi pixel del vecchio: %s passo %d', [LWhere, LStep]));
        // a call with zero tics says "over" in the old code too: go on until a real end
      until (LOldDone and (LTicks > 0)) or (LStep > 5000);
      Assert.IsTrue(LStep <= 5000, 'dovrebbe finire: ' + LWhere);
    finally
      LOld.Free;
    end;
  end;
end;

procedure TTestImagingMeltWipe.DovrebbeRifiutareUnBufferNilInStartOnBuffers;
var
  LWipe: IImagingMeltWipe;
  LScreen: TImagingPixels;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LScreen := Screen(4, 4, 0);
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(4, 4, 4, 0), nil, @LScreen[0], @LScreen[0]);
    end, EImagingException, 'dovrebbe rifiutare la schermata di partenza nil');
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(4, 4, 4, 0), @LScreen[0], nil, @LScreen[0]);
    end, EImagingException, 'dovrebbe rifiutare la schermata di arrivo nil');
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(4, 4, 4, 0), @LScreen[0], @LScreen[0], nil);
    end, EImagingException, 'dovrebbe rifiutare la destinazione nil');
  Assert.WillRaise(
    procedure
    begin
      LWipe.Advance(1);
    end, EImagingException, 'non dovrebbe risultare avviato dopo un rifiuto');
end;

procedure TTestImagingMeltWipe.DovrebbeRifiutareImpostazioniSbagliateInStartOnBuffers;
var
  LWipe: IImagingMeltWipe;
  LScreen: TImagingPixels;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LScreen := Screen(8, 8, 0);
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(0, 4, 4, 0), @LScreen[0], @LScreen[0], @LScreen[0]);
    end, EImagingException, 'dovrebbe rifiutare la larghezza zero');
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(4, -1, 4, 0), @LScreen[0], @LScreen[0], @LScreen[0]);
    end, EImagingException, 'dovrebbe rifiutare l''altezza negativa');
  Assert.WillRaise(
    procedure
    begin
      LWipe.StartOnBuffers(Settings(8, 4, 4, 0), @LScreen[0], @LScreen[0], @LScreen[0]);
    end, EImagingException, 'dovrebbe rifiutare un passo piu'' piccolo della larghezza');
end;

procedure TTestImagingMeltWipe.DovrebbeRicominciareSuAltriBufferDopoUnMeltFinito;
var
  LWipe: IImagingMeltWipe;
  LStart, LEnd, LFirst, LSecond: TImagingPixels;
  LGuard: Integer;
  LIndex: Integer;
begin
  LWipe := TImagingMeltWipe.Create(TConstantRandom.Create(0));
  LStart := Screen(6, 5, $111111);
  LEnd := Screen(6, 5, $222222);
  LFirst := Screen(6, 5, 0);
  LSecond := Screen(6, 5, 0);

  LWipe.StartOnBuffers(Settings(6, 5, 6, 0), @LStart[0], @LEnd[0], @LFirst[0]);
  LGuard := 0;
  while not LWipe.Advance(1) do
    Inc(LGuard);
  Assert.IsTrue(LGuard > 0, 'il primo melt dovrebbe durare qualche tic');

  // the engine starts a melt at each change of scene with the same object
  LWipe.StartOnBuffers(Settings(6, 5, 6, 0), @LEnd[0], @LStart[0], @LSecond[0]);
  for LIndex := 0 to High(LSecond) do
    Assert.AreEqual(Cardinal($222222), LSecond[LIndex],
      'il secondo melt dovrebbe partire dalla sua schermata, pixel ' + IntToStr(LIndex));
  LGuard := 0;
  while not LWipe.Advance(1) do
    Inc(LGuard);
  Assert.IsTrue(LGuard > 0, 'il secondo melt dovrebbe ripartire dalle posizioni iniziali');
  // as in the old code a column is not drawn in the tic in which it reaches the bottom: the
  // last rows keep the old screen (the engine draws the whole frame right after), so only the
  // first row is sure
  for LIndex := 0 to 5 do
    Assert.AreEqual(Cardinal($111111), LSecond[LIndex],
      'il secondo melt dovrebbe finire sulla sua schermata di arrivo, pixel ' + IntToStr(LIndex));
end;

end.
