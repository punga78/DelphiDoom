{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OPL2 chip                                           }
{                                                                              }
{  Derived from fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later):      }
{  see Libs\Opl\README.md                                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Opl.Chip;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Opl.Types, DelphiDoom.Opl.Intf, DelphiDoom.Opl.Factory,
  DelphiDoom.Opl.Noise;

type
  /// <summary>Remembers the calls of the chip</summary>
  TOplTestListener = class(TInterfacedObject, IOplChipListener)
  public
    Timers: string;
    Irqs: string;
    Updates: Integer;
    procedure TimerChanged(AChannel: Integer; AIntervalSeconds: Double);
    procedure IrqChanged(AParam: Integer; ALevel: Integer);
    procedure BeforeDataWrite(AParam: Integer);
  end;

  [TestFixture]
  [Category('opl')]
  [Category('opl-chip')]
  TTestOplChip = class(TObject)
  private
    FChip: IOplChip;
    procedure Reg(AChip: IOplChip; ARegister, AValue: Integer);
    procedure PlayNote(AChip: IOplChip);
    function Silent(const ABuffer: TArray<SmallInt>): Boolean;
    function Block(AChip: IOplChip; ALength: Integer): TArray<SmallInt>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareSilenzioSubitoDopoLaCreazione;
    [Test]
    procedure DovrebbeSuonareDopoUnKeyOn;
    [Test]
    procedure DovrebbeTornareSilenziosoDopoIlReset;
    [Test]
    procedure DovrebbeDareSilenzioConVolumeZero;
    [Test]
    procedure DovrebbeRiempireSoloUnCampioneOgniStripe;
    [Test]
    procedure DovrebbeRifiutareUnaStripeNonPositiva;
    [Test]
    procedure DovrebbeRifiutareUnBufferTroppoCorto;
    [Test]
    procedure DovrebbeLeggereZeroDallaPortaDeiDati;
    [Test]
    procedure DovrebbeAlzareIlFlagDelTimerAEIlSegnaleDiInterruzione;
    [Test]
    procedure DovrebbeAbbassareIlSegnaleDiInterruzioneConLaScritturaDelRegistro4;
    [Test]
    procedure DovrebbeAvvisareIlListenerQuandoPartonoITimer;
    [Test]
    procedure DovrebbeAvvisareIlListenerPrimaDiOgniScritturaSullaPortaDeiDati;
    [Test]
    procedure DovrebbeTrattareIlTimerBPerQualsiasiNumeroDiversoDaZero;
    [Test]
    procedure DovrebbeDareLeStesseTabelleAChipDiversiConGliStessiParametri;
    [Test]
    procedure DovrebbeNonSentireIlCambioDiProfonditaDopoIlPrimoBloccoColDifettoDelC;
    [Test]
    procedure DovrebbeAggiornareLaCacheQuandoCambiaIlChipCheProduceCampioni;
    [Test]
    procedure DovrebbeSentireIlCambioDiProfonditaSenzaLaCacheDelC;
    [Test]
    procedure DovrebbeDareGliStessiCampioniConDueChipNellOrdineDelC;
    [Test]
    procedure DovrebbeDareIlRumoreDiRandDellaLibreriaC;
  end;

implementation

{ TOplTestListener }

procedure TOplTestListener.TimerChanged(AChannel: Integer; AIntervalSeconds: Double);
begin
  Timers := Timers + Format('%d:%.9f;', [AChannel, AIntervalSeconds], TFormatSettings.Invariant);
end;

procedure TOplTestListener.IrqChanged(AParam: Integer; ALevel: Integer);
begin
  Irqs := Irqs + Format('%d:%d;', [AParam, ALevel]);
end;

procedure TOplTestListener.BeforeDataWrite(AParam: Integer);
begin
  Inc(Updates);
end;

{ TTestOplChip }

procedure TTestOplChip.Setup;
begin
  FChip := TOplFactory.CreateChip(3579545, 49716);
end;

procedure TTestOplChip.TearDown;
begin
  FChip := nil;
end;

procedure TTestOplChip.Reg(AChip: IOplChip; ARegister, AValue: Integer);
begin
  AChip.WriteRegister(Byte(ARegister), Byte(AValue));
end;

procedure TTestOplChip.PlayNote(AChip: IOplChip);
begin
  // channel 0: a carrier at full level with a fast attack, a modulator with a tone, a note A at block 4
  Reg(AChip, $01, $20);
  Reg(AChip, $20, $01);
  Reg(AChip, $23, $01);
  Reg(AChip, $40, $10);
  Reg(AChip, $43, $00);
  Reg(AChip, $60, $F0);
  Reg(AChip, $63, $F0);
  Reg(AChip, $80, $77);
  Reg(AChip, $83, $77);
  Reg(AChip, $C0, $00);
  Reg(AChip, $A0, $41);
  Reg(AChip, $B0, $32);
end;

function TTestOplChip.Silent(const ABuffer: TArray<SmallInt>): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ABuffer) do
    if ABuffer[LIndex] <> 0 then
      Exit(False);
  Result := True;
end;

function TTestOplChip.Block(AChip: IOplChip; ALength: Integer): TArray<SmallInt>;
begin
  SetLength(Result, ALength);
  AChip.GenerateSamples(Result, ALength);
end;

procedure TTestOplChip.DovrebbeDareSilenzioSubitoDopoLaCreazione;
begin
  Assert.IsTrue(Silent(Block(FChip, 500)));
end;

procedure TTestOplChip.DovrebbeSuonareDopoUnKeyOn;
begin
  PlayNote(FChip);
  Assert.IsFalse(Silent(Block(FChip, 500)));
end;

procedure TTestOplChip.DovrebbeTornareSilenziosoDopoIlReset;
begin
  PlayNote(FChip);
  Block(FChip, 100);
  FChip.Reset;
  Assert.IsTrue(Silent(Block(FChip, 500)));
end;

procedure TTestOplChip.DovrebbeDareSilenzioConVolumeZero;
var
  LBuffer: TArray<SmallInt>;
begin
  PlayNote(FChip);
  SetLength(LBuffer, 300);
  FChip.GenerateSamples(LBuffer, 0, 300, 1, 0.0);
  Assert.IsTrue(Silent(LBuffer));
end;

procedure TTestOplChip.DovrebbeRiempireSoloUnCampioneOgniStripe;
var
  LBuffer: TArray<SmallInt>;
  LIndex: Integer;
begin
  PlayNote(FChip);
  SetLength(LBuffer, 200);
  for LIndex := 0 to High(LBuffer) do
    LBuffer[LIndex] := 777;
  FChip.GenerateSamples(LBuffer, 1, 199, 2, 1.0);
  for LIndex := 0 to High(LBuffer) do
    if (LIndex and 1) = 0 then
      Assert.AreEqual(Integer(777), Integer(LBuffer[LIndex]), 'slot pari ' + IntToStr(LIndex));
end;

procedure TTestOplChip.DovrebbeRifiutareUnaStripeNonPositiva;
var
  LBuffer: TArray<SmallInt>;
begin
  SetLength(LBuffer, 10);
  Assert.WillRaise(
    procedure
    begin
      FChip.GenerateSamples(LBuffer, 0, 10, 0, 1.0);
    end, EOplException);
end;

procedure TTestOplChip.DovrebbeRifiutareUnBufferTroppoCorto;
var
  LBuffer: TArray<SmallInt>;
begin
  SetLength(LBuffer, 10);
  // the second chip of a pair writes the slots 1, 3, ...: an odd length would go past the end (the C does)
  Assert.WillRaise(
    procedure
    begin
      FChip.GenerateSamples(LBuffer, 1, 10, 1, 1.0);
    end, EOplException);
  Assert.WillRaise(
    procedure
    begin
      FChip.GenerateSamples(LBuffer, 0, 11, 1, 1.0);
    end, EOplException);
end;

procedure TTestOplChip.DovrebbeLeggereZeroDallaPortaDeiDati;
begin
  Reg(FChip, $05, $12);
  Assert.AreEqual(Integer(0), Integer(FChip.Read(1)));
  Assert.AreEqual(Integer(0), Integer(FChip.Read(3)));
end;

procedure TTestOplChip.DovrebbeAlzareIlFlagDelTimerAEIlSegnaleDiInterruzione;
begin
  Reg(FChip, $04, $01); // timer 1 on, the other masks open: the status mask is $79
  Assert.AreEqual(Integer(1), FChip.TimerOver(0));
  Assert.AreEqual(Integer($C0), Integer(FChip.Read(0)), 'IRQ e timer A');
  Assert.AreEqual(Integer(1), FChip.TimerOver(1));
  Assert.AreEqual(Integer($E0), Integer(FChip.Read(0)), 'anche il timer B');
end;

procedure TTestOplChip.DovrebbeAbbassareIlSegnaleDiInterruzioneConLaScritturaDelRegistro4;
begin
  Reg(FChip, $04, $01);
  FChip.TimerOver(0);
  Reg(FChip, $04, $80);
  Assert.AreEqual(Integer(0), Integer(FChip.Read(0)));
  Assert.AreEqual(Integer(0), FChip.Write(0, 0));
end;

procedure TTestOplChip.DovrebbeAvvisareIlListenerQuandoPartonoITimer;
var
  LListener: TOplTestListener;
  LHolder: IOplChipListener;
begin
  LListener := TOplTestListener.Create;
  LHolder := LListener;
  FChip.SetListener(LHolder, 10, 7, 3);
  Reg(FChip, $02, $F0); // timer 1: (256 - 240) * 4 = 64 ticks
  Reg(FChip, $03, $FF); // timer 2: 16 ticks
  Reg(FChip, $04, $03);
  // the timer 2 first, then the timer 1; one tick lasts 72 cycles of the clock
  Assert.AreEqual(Format('11:%.9f;10:%.9f;', [16 * 72.0 / 3579545, 64 * 72.0 / 3579545], TFormatSettings.Invariant),
    LListener.Timers);
  FChip.TimerOver(0);
  Assert.AreEqual('7:1;', LListener.Irqs);
end;

procedure TTestOplChip.DovrebbeAvvisareIlListenerPrimaDiOgniScritturaSullaPortaDeiDati;
var
  LListener: TOplTestListener;
  LHolder: IOplChipListener;
begin
  LListener := TOplTestListener.Create;
  LHolder := LListener;
  FChip.SetListener(LHolder, 0, 0, 5);
  FChip.Write(0, $20);
  Assert.AreEqual(0, LListener.Updates);
  FChip.Write(1, $01);
  FChip.Write(1, $02);
  Assert.AreEqual(2, LListener.Updates);
end;

procedure TTestOplChip.DovrebbeTrattareIlTimerBPerQualsiasiNumeroDiversoDaZero;
begin
  Reg(FChip, $04, $02);
  FChip.TimerOver(5);
  Assert.AreEqual(Integer($A0), Integer(FChip.Read(0)), 'flag del timer B e interruzione');
end;

procedure TTestOplChip.DovrebbeDareLeStesseTabelleAChipDiversiConGliStessiParametri;
var
  LFirst: IOplChip;
  LSecond: IOplChip;
  LA, LB: TArray<SmallInt>;
  LIndex: Integer;
begin
  LFirst := TOplFactory.CreateChip(3579545, 22050);
  LSecond := TOplFactory.CreateChip(3579545, 22050);
  PlayNote(LFirst);
  PlayNote(LSecond);
  LA := Block(LFirst, 400);
  LB := Block(LSecond, 400);
  for LIndex := 0 to 399 do
    Assert.AreEqual(Integer(LA[LIndex]), Integer(LB[LIndex]));
end;

procedure TTestOplChip.DovrebbeNonSentireIlCambioDiProfonditaDopoIlPrimoBloccoColDifettoDelC;
var
  LReference: IOplChip;
  LChanged: IOplChip;
  LA, LB: TArray<SmallInt>;
  LIndex: Integer;
begin
  LReference := TOplFactory.CreateChip(3579545, 49716);
  LChanged := TOplFactory.CreateChip(3579545, 49716);
  PlayNote(LReference);
  PlayNote(LChanged);
  Reg(LReference, $20, $81); // tremolo on the modulator
  Reg(LChanged, $20, $81);
  // one chip after the other: the C refreshes its globals whenever the chip that makes the samples changes
  Block(LReference, 50);
  LA := Block(LReference, 3000);
  Block(LChanged, 50);
  // the depth bit is written after the first block: the C keeps the old depth in its globals
  Reg(LChanged, $BD, $80);
  LB := Block(LChanged, 3000);
  for LIndex := 0 to High(LA) do
    Assert.AreEqual(Integer(LA[LIndex]), Integer(LB[LIndex]), 'campione ' + IntToStr(LIndex));
end;

procedure TTestOplChip.DovrebbeAggiornareLaCacheQuandoCambiaIlChipCheProduceCampioni;
var
  LReference: IOplChip;
  LChanged: IOplChip;
  LA, LB: TArray<SmallInt>;
  LIndex: Integer;
  LDifferent: Boolean;
begin
  LReference := TOplFactory.CreateChip(3579545, 49716);
  LChanged := TOplFactory.CreateChip(3579545, 49716);
  PlayNote(LReference);
  PlayNote(LChanged);
  Reg(LReference, $20, $81);
  Reg(LChanged, $20, $81);
  Block(LReference, 50);
  Block(LChanged, 50);
  Reg(LChanged, $BD, $80);
  // the other chip made the samples in between: the globals of the C are copied again from this one
  LA := Block(LReference, 3000);
  LB := Block(LChanged, 3000);
  LDifferent := False;
  for LIndex := 0 to High(LA) do
    if LA[LIndex] <> LB[LIndex] then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;

procedure TTestOplChip.DovrebbeSentireIlCambioDiProfonditaSenzaLaCacheDelC;
var
  LReference: IOplChip;
  LChanged: IOplChip;
  LA, LB: TArray<SmallInt>;
  LIndex: Integer;
  LDifferent: Boolean;
begin
  LReference := TOplFactory.CreateChip(3579545, 49716);
  LChanged := TOplFactory.CreateChip(3579545, 49716);
  LChanged.LegacyLfoCache := False;
  PlayNote(LReference);
  PlayNote(LChanged);
  Reg(LReference, $20, $81);
  Reg(LChanged, $20, $81);
  Block(LReference, 50);
  LA := Block(LReference, 3000);
  Block(LChanged, 50);
  Reg(LChanged, $BD, $80);
  LB := Block(LChanged, 3000);
  LDifferent := False;
  for LIndex := 0 to High(LA) do
    if LA[LIndex] <> LB[LIndex] then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;

procedure TTestOplChip.DovrebbeDareGliStessiCampioniConDueChipNellOrdineDelC;
var
  LLeft: IOplChip;
  LRight: IOplChip;
  LSingle: IOplChip;
  LStereo: TArray<SmallInt>;
  LMono: TArray<SmallInt>;
  LIndex: Integer;
begin
  LLeft := TOplFactory.CreateChip(3579545, 22050);
  LRight := TOplFactory.CreateChip(3579545, 22050);
  LSingle := TOplFactory.CreateChip(3579545, 22050);
  PlayNote(LLeft);
  PlayNote(LRight);
  PlayNote(LSingle);
  SetLength(LStereo, 400);
  LLeft.GenerateSamples(LStereo, 0, 200, 2, 1.0);
  LRight.GenerateSamples(LStereo, 1, 200, 2, 1.0);
  LMono := Block(LSingle, 100);
  for LIndex := 0 to 99 do
  begin
    Assert.AreEqual(Integer(LMono[LIndex]), Integer(LStereo[LIndex * 2]), 'sinistra');
    Assert.AreEqual(Integer(LMono[LIndex]), Integer(LStereo[LIndex * 2 + 1]), 'destra');
  end;
end;

procedure TTestOplChip.DovrebbeDareIlRumoreDiRandDellaLibreriaC;
var
  LNoise: IOplNoiseSource;
  LIndex: Integer;
const
  // rand() after srand(1) of the Windows C library: 41, 18467, 6334, 26500, 19169, 15724, 11478, 29358, 26962, 24464
  EXPECTED: array[0..9] of Integer = (1, 1, 0, 0, 1, 0, 0, 0, 0, 0);
begin
  LNoise := TOplMsvcrtNoise.Create(1);
  for LIndex := 0 to 9 do
    Assert.AreEqual(EXPECTED[LIndex], LNoise.NextBit, 'bit ' + IntToStr(LIndex));
end;

end.
