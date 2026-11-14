{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the machine and its interpreter:     }
{  what a program is not allowed to do, limits, re-entry, restart, profile     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.Machine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf,
  DelphiDoom.Tests.Qvm.Assembler, DelphiDoom.Tests.Qvm.Support;

type
  TQvmProbe = reference to function(const AMachine: IQvmMachine;
    const AArguments: TQvmSystemCallArguments): Integer;

  /// <summary>A host that does what the test tells it</summary>
  TQvmProbeHost = class(TInterfacedObject, IQvmHost)
  strict private
    FProbe: TQvmProbe;
  public
    constructor Create(const AProbe: TQvmProbe);
    function SystemCall(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer;
  end;

  [TestFixture]
  [Category('Qvm')]
  TTestQvmMachine = class
  strict private
    function Build(const AProgram: TProc<TQvmAssembler>; AImageSize: Integer = 8192): TBytes;
    function Make(const AProgram: TProc<TQvmAssembler>; AImageSize: Integer = 8192): IQvmMachine; overload;
    function Make(const AProgram: TProc<TQvmAssembler>; const AHost: IQvmHost;
      const ALimits: TQvmLimits): IQvmMachine; overload;
    procedure ExpectFault(const AProgram: TProc<TQvmAssembler>; const AText: string; AImageSize: Integer = 8192);
  public
    [Test]
    procedure DovrebbeEseguireIlPuntoDIngressoERestituireIlValore;
    [Test]
    procedure IlComplementoDovrebbeSostituireLaCimaDelloStack;
    [Test]
    procedure IlComplementoDellaVersione132DovrebbeEssereSoloUnOpzione;
    [Test]
    procedure DuecentocinquantacinqueValoriDovrebberoStareNelloStackDegliOperandi;
    [Test]
    procedure UnValoreInPiuDovrebbeEssereUnErroreENonUnaScritturaFuori;
    [Test]
    procedure PushOltreIlLimiteDovrebbeEssereUnErrore;
    [Test]
    procedure LocalOltreIlLimiteDovrebbeEssereUnErrore;
    [Test]
    [TestCase('pop', '7')]
    [TestCase('add', '38')]
    [TestCase('store4', '32')]
    [TestCase('store2', '31')]
    [TestCase('store1', '30')]
    [TestCase('jump', '10')]
    [TestCase('call', '5')]
    [TestCase('arg', '33')]
    [TestCase('block copy', '34')]
    [TestCase('eq', '11')]
    [TestCase('ltu', '17')]
    [TestCase('gef', '26')]
    [TestCase('divi', '40')]
    [TestCase('modu', '43')]
    [TestCase('muli', '44')]
    [TestCase('band', '46')]
    [TestCase('lsh', '50')]
    [TestCase('rshi', '51')]
    [TestCase('rshu', '52')]
    [TestCase('addf', '54')]
    [TestCase('mulf', '57')]
    procedure TogliereDaUnoStackVuotoDovrebbeEssereUnErrore(AOpcode: Integer);
    [Test]
    procedure UnOperazioneSuUnSoloValoreUsaLoSlotLiberoComeNellOriginale;
    [Test]
    procedure IlPuntoDIngressoDeveLasciareUnSoloValore;
    [Test]
    procedure UnFrameCheScendeSottoIlFondoDovrebbeEssereStackOverflow;
    [Test]
    procedure UnaRicorsioneSenzaFineDovrebbeFinireInStackOverflow;
    [Test]
    procedure UnFrameNegativoNonDovrebbePortareLoStackFuoriDallaMemoria;
    [Test]
    procedure UnFrameNonMultiploDiQuattroDovrebbeEssereRifiutato;
    [Test]
    procedure UnLeaveSbagliatoNonDovrebbeLeggereFuoriDallaMemoria;
    [Test]
    procedure UnArgomentoOltreLaFineDellaMemoriaDovrebbeEssereUnErrore;
    [Test]
    [TestCase('oltre l ultima', '5')]
    [TestCase('enorme', '2147483647')]
    procedure ChiamareUnIstruzioneCheNonEsisteDovrebbeEssereUnErrore(ATarget: Integer);
    [Test]
    [TestCase('oltre l ultima', '5')]
    [TestCase('negativa', '-2')]
    [TestCase('enorme', '2147483647')]
    procedure SaltareAUnIstruzioneCheNonEsisteDovrebbeEssereUnErrore(ATarget: Integer);
    [Test]
    [TestCase('fuori dal codice', '12345')]
    [TestCase('negativo', '-2')]
    [TestCase('dentro un operando', '1')]
    [TestCase('nel riempimento finale', '27')]
    procedure TornareAUnIndirizzoCheNonEUnIstruzioneDovrebbeEssereUnErrore(AAddress: Integer);
    [Test]
    procedure TornareAUnIstruzioneVeraDovrebbeFunzionare;
    [Test]
    procedure UnProgrammaCheSuperaLaFineDelCodiceDovrebbeEssereFermato;
    [Test]
    [TestCase('divi', '40,5,0,division by zero')]
    [TestCase('modi', '42,5,0,division by zero')]
    [TestCase('divu', '41,5,0,division by zero')]
    [TestCase('modu', '43,5,0,division by zero')]
    [TestCase('divi minimo', '40,-2147483648,-1,division overflow')]
    [TestCase('modi minimo', '42,-2147483648,-1,division overflow')]
    procedure LeDivisioniCheFermanoIlProcessoreDovrebberoEssereErrori(AOpcode, AFirst, ASecond: Integer;
      const AText: string);
    [Test]
    procedure LaDivisioneSenzaSegnoPerMenoUnoNonEUnErrore;
    [Test]
    procedure UnaCopiaABlocchiCheEsceDallaMemoriaDovrebbeEssereUnErrore;
    [Test]
    procedure UnaCopiaABlocchiNonAllineataDovrebbeEssereLErroreDellOriginale;
    [Test]
    procedure UnCaricamentoAllaFineDellaMemoriaDovrebbeLeggereZeri;
    [Test]
    procedure UnaScritturaConIndirizzoQualsiasiDovrebbeRestareNellaMemoria;
    [Test]
    procedure DopoUnErroreLaMacchinaDovrebbeEssereAncoraUsabile;
    [Test]
    procedure IlLimiteDiIstruzioniDovrebbeFermareUnCicloInfinito;
    [Test]
    procedure IlLimiteDovrebbeValerePerOgniChiamataEsterna;
    [Test]
    procedure IlLimiteDovrebbeContareAncheLeChiamateAnnidate;
    [Test]
    procedure DovrebbeContareLeIstruzioniEseguite;
    [Test]
    procedure DovrebbeContareLeIstruzioniDiBreak;
    [Test]
    procedure LaChiamataDiSistemaDovrebbeRicevereNumeroEArgomenti;
    [Test]
    procedure GliArgomentiOltreLaCimaDelloStackDovrebberoEssereZeri;
    [Test]
    procedure LHostDovrebbePoterRientrareNellaMacchina;
    [Test]
    procedure UnRientroSenzaFineDovrebbeEssereFermato;
    [Test]
    procedure UnEccezioneDellHostDovrebbeUscireELasciareLaMacchinaComEra;
    [Test]
    procedure LHostNonDovrebbePoterToccareMemoriaFuoriDallImmagine;
    [Test]
    procedure PiuDiNoveArgomentiDovrebberoEssereRifiutati;
    [Test]
    procedure GliArgomentiMancantiDovrebberoEssereZero;
    [Test]
    procedure UnImmagineTroppoPiccolaPerUnFrameNonDovrebbeEseguireNulla;
    [Test]
    procedure IlRiavvioDovrebbeRicaricareIDatiELasciareIlResto;
    [Test]
    procedure IlRiavvioConUnFileDiversoDovrebbeEssereRifiutato;
    [Test]
    procedure DovrebbeDareLeInformazioniDellaMacchina;
    [Test]
    procedure IlNomeDovrebbeEssereTagliatoASessantatreCaratteri;
    [Test]
    procedure SenzaNomeOSenzaHostNonDovrebbeNascere;
    [Test]
    procedure UnFileSbagliatoNonDovrebbeLasciareNulla;
    [Test]
    procedure DovrebbeEsporreLaTabellaDeiSaltiDellaVersioneDue;
    [Test]
    procedure IlProfiloDovrebbeContareLeIstruzioniPerFunzioneComeLOriginale;
    [Test]
    procedure SenzaProfiloNonDovrebbeContareNulla;
    [Test]
    procedure LaTracciaDelloStackDovrebbeSeguireIFrame;
    [Test]
    procedure LaDivisioneFloatPerZeroDovrebbeDareInfinitoSenzaEccezioni;
    [Test]
    procedure LaMascheraDelleEccezioniFloatDovrebbeTornareQuellaDiPrima;
    [Test]
    procedure LaMemoriaVistaDallHostDovrebbeEssereQuellaDelProgramma;
    [Test]
    procedure DueMacchineNonDovrebberoCondividereNulla;
  end;

implementation

uses
  System.Math, DelphiDoom.Qvm.Opcodes, DelphiDoom.Qvm.Factory, DelphiDoom.Tests.Qvm.Programs;

const
  FRAME = 16;
  IMAGE = 8192;

{ TQvmProbeHost }

constructor TQvmProbeHost.Create(const AProbe: TQvmProbe);
begin
  inherited Create;
  FProbe := AProbe;
end;

function TQvmProbeHost.SystemCall(const AMachine: IQvmMachine;
  const AArguments: TQvmSystemCallArguments): Integer;
begin
  Result := FProbe(AMachine, AArguments);
end;

{ TTestQvmMachine }

function TTestQvmMachine.Build(const AProgram: TProc<TQvmAssembler>; AImageSize: Integer): TBytes;
var
  LAssembler: TQvmAssembler;
begin
  LAssembler := TQvmAssembler.Create;
  try
    AProgram(LAssembler);
    LAssembler.ImageSize(AImageSize);
    Result := LAssembler.ToBytes;
  finally
    LAssembler.Free;
  end;
end;

function TTestQvmMachine.Make(const AProgram: TProc<TQvmAssembler>; AImageSize: Integer): IQvmMachine;
begin
  Result := TQvmFactory.CreateMachine('prova', Build(AProgram, AImageSize), TQvmNullHost.Create);
end;

function TTestQvmMachine.Make(const AProgram: TProc<TQvmAssembler>; const AHost: IQvmHost;
  const ALimits: TQvmLimits): IQvmMachine;
begin
  Result := TQvmFactory.CreateMachine('prova', Build(AProgram, IMAGE), AHost, ALimits);
end;

procedure TTestQvmMachine.ExpectFault(const AProgram: TProc<TQvmAssembler>; const AText: string;
  AImageSize: Integer);
var
  LMachine: IQvmMachine;
begin
  LMachine := Make(AProgram, AImageSize);
  try
    LMachine.Call(0, []);
    Assert.Fail('il programma e'' arrivato in fondo');
  except
    on E: EQvmExecutionException do
      Assert.Contains(E.Message, AText);
  end;
  // nothing is left half done
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(AImageSize, LMachine.ProgramStack);
end;

procedure TTestQvmMachine.DovrebbeEseguireIlPuntoDIngressoERestituireIlValore;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_SUB), TQvmNullHost.Create);
  Assert.AreEqual(30, LMachine.Call(0, [42, 12]));
  Assert.AreEqual(-5, LMachine.Call(99, [5, 10]));
end;

procedure TTestQvmMachine.IlComplementoDovrebbeSostituireLaCimaDelloStack;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Unary(OP_BCOM), TQvmNullHost.Create);
  Assert.AreEqual(-1, LMachine.Call(0, [0]));
  Assert.AreEqual(Integer($EDCBA987), LMachine.Call(0, [$12345678]));
  Assert.AreEqual(High(Integer), LMachine.Call(0, [Low(Integer)]));
end;

procedure TTestQvmMachine.IlComplementoDellaVersione132DovrebbeEssereSoloUnOpzione;
var
  LLimits: TQvmLimits;
  LProgram: TProc<TQvmAssembler>;
begin
  // a, b, OP_BCOM, OP_SUB: with the defect the complement of b goes below the top: (~b) - b
  LProgram :=
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      TQvmPrograms.Argument(A, FRAME, 1);
      TQvmPrograms.Argument(A, FRAME, 2);
      A.Op(OP_BCOM);
      A.Op(OP_SUB);
      A.Op(OP_LEAVE, FRAME);
    end;
  LLimits := TQvmLimits.Default;
  Assert.IsFalse(LLimits.LegacyBitComplement);
  // a - (~b)
  Assert.AreEqual(100 - (not 7), Make(LProgram, TQvmNullHost.Create, LLimits).Call(0, [100, 7]));
  LLimits.LegacyBitComplement := True;
  Assert.AreEqual((not 7) - 7, Make(LProgram, TQvmNullHost.Create, LLimits).Call(0, [100, 7]));
  // with the defect and nothing below the top it would write before the stack
  try
    Make(
      procedure(A: TQvmAssembler)
      begin
        A.Op(OP_ENTER, FRAME);
        A.Op(OP_BCOM);
        A.Op(OP_LEAVE, FRAME);
      end, TQvmNullHost.Create, LLimits).Call(0, []);
    Assert.Fail('nessun errore');
  except
    on E: EQvmExecutionException do
      Assert.Contains(E.Message, 'opStack underflow');
  end;
end;

procedure TTestQvmMachine.DuecentocinquantacinqueValoriDovrebberoStareNelloStackDegliOperandi;
var
  LMachine: IQvmMachine;
begin
  LMachine := Make(
    procedure(A: TQvmAssembler)
    var
      LIndex: Integer;
    begin
      A.Op(OP_ENTER, FRAME);
      for LIndex := 1 to QVM_OPERAND_STACK_SIZE - 1 do
        A.Op(OP_CONST, LIndex);
      for LIndex := 1 to QVM_OPERAND_STACK_SIZE - 2 do
        A.Op(OP_ADD);
      A.Op(OP_LEAVE, FRAME);
    end);
  Assert.AreEqual(255 * 256 div 2, LMachine.Call(0, []));
end;

procedure TTestQvmMachine.UnValoreInPiuDovrebbeEssereUnErroreENonUnaScritturaFuori;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    var
      LIndex: Integer;
    begin
      A.Op(OP_ENTER, FRAME);
      for LIndex := 1 to QVM_OPERAND_STACK_SIZE do
        A.Op(OP_CONST, LIndex);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM opStack overflow');
end;

procedure TTestQvmMachine.PushOltreIlLimiteDovrebbeEssereUnErrore;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    var
      LIndex: Integer;
    begin
      A.Op(OP_ENTER, FRAME);
      for LIndex := 1 to 1000 do
        A.Op(OP_PUSH);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM opStack overflow');
end;

procedure TTestQvmMachine.LocalOltreIlLimiteDovrebbeEssereUnErrore;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    var
      LIndex: Integer;
    begin
      A.Op(OP_ENTER, FRAME);
      for LIndex := 1 to QVM_OPERAND_STACK_SIZE do
        A.Op(OP_LOCAL, 8);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM opStack overflow');
end;

procedure TTestQvmMachine.TogliereDaUnoStackVuotoDovrebbeEssereUnErrore(AOpcode: Integer);
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      if TQvmOpcodes.IsBranch(AOpcode) then
        A.Branch(AOpcode, A.MarkNew)
      else if TQvmOpcodes.OperandSize(AOpcode) > 0 then
        A.Op(AOpcode, 8)
      else
        A.Op(AOpcode);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM opStack underflow');
end;

procedure TTestQvmMachine.UnOperazioneSuUnSoloValoreUsaLoSlotLiberoComeNellOriginale;
var
  LMachine: IQvmMachine;
begin
  // "leave a free spot at start of stack": with one value an addition takes the other from the free
  // slot, which here is always zero, and leaves the stack empty
  LMachine := Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 41);
      A.Op(OP_ADD);
      A.Op(OP_PUSH);
      A.Op(OP_LEAVE, FRAME);
    end);
  // the push brings back the slot where 41 was
  Assert.AreEqual(41, LMachine.Call(0, []));
  // a load on an empty stack reads the free slot: the address 0
  LMachine := Make(
    procedure(A: TQvmAssembler)
    begin
      A.Data([$0BADF00D]);
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_LOAD4);
      A.Op(OP_PUSH);
      A.Op(OP_POP);
      A.Op(OP_PUSH);
      A.Op(OP_LEAVE, FRAME);
    end);
  Assert.AreEqual(0, LMachine.Call(0, []));
end;

procedure TTestQvmMachine.IlPuntoDIngressoDeveLasciareUnSoloValore;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_LEAVE, FRAME);
    end, 'Interpreter error: opStack = 0');
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 1);
      A.Op(OP_CONST, 2);
      A.Op(OP_CONST, 3);
      A.Op(OP_LEAVE, FRAME);
    end, 'Interpreter error: opStack = 3');
end;

procedure TTestQvmMachine.UnFrameCheScendeSottoIlFondoDovrebbeEssereStackOverflow;
const
  LARGE = 1 shl 20;
begin
  // the stack is the top QVM_STACK_SIZE bytes of the image
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, QVM_STACK_SIZE - QVM_ENTRY_FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, QVM_STACK_SIZE - QVM_ENTRY_FRAME);
    end, 'VM stack overflow', LARGE);
  // four bytes less and it fits
  Assert.AreEqual(0, Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, QVM_STACK_SIZE - QVM_ENTRY_FRAME - 4);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, QVM_STACK_SIZE - QVM_ENTRY_FRAME - 4);
    end, LARGE).Call(0, []));
  // in an image smaller than the stack the bottom is the address 0
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, IMAGE - QVM_ENTRY_FRAME + 4);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, IMAGE - QVM_ENTRY_FRAME + 4);
    end, 'VM stack overflow');
  Assert.AreEqual(0, Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, IMAGE - QVM_ENTRY_FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, IMAGE - QVM_ENTRY_FRAME);
    end).Call(0, []));
end;

procedure TTestQvmMachine.UnaRicorsioneSenzaFineDovrebbeFinireInStackOverflow;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    var
      LSelf: Integer;
    begin
      LSelf := A.MarkNew;
      A.Op(OP_ENTER, 24);
      A.CallLabel(LSelf);
      A.Op(OP_LEAVE, 24);
    end, 'VM stack overflow', 1 shl 20);
end;

procedure TTestQvmMachine.UnFrameNegativoNonDovrebbePortareLoStackFuoriDallaMemoria;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, -64);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, -64);
    end, 'VM program stack out of range');
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, Low(Integer));
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, 0);
    end, 'VM');
  // up to where a return address and a call number still fit it is allowed
  Assert.AreEqual(0, Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, -(QVM_ENTRY_FRAME - 8));
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, -(QVM_ENTRY_FRAME - 8));
    end).Call(0, []));
end;

procedure TTestQvmMachine.UnFrameNonMultiploDiQuattroDovrebbeEssereRifiutato;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, 18);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, 18);
    end, 'VM program stack misaligned');
end;

procedure TTestQvmMachine.UnLeaveSbagliatoNonDovrebbeLeggereFuoriDallaMemoria;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME + 4096);
    end, 'VM program stack out of range');
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, -IMAGE);
    end, 'VM stack overflow');
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME + 2);
    end, 'VM program stack misaligned');
end;

procedure TTestQvmMachine.UnArgomentoOltreLaFineDellaMemoriaDovrebbeEssereUnErrore;
begin
  // the entry frame is the last 48 bytes: with no frame of its own an offset of 48 is past the end
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_CONST, 1);
      A.Op(OP_ARG, 48);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, 0);
    end, 'OP_ARG outside the data image');
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_CONST, 1);
      A.Op(OP_ARG, 255);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, 0);
    end, 'OP_ARG outside the data image');
  // 44 is the last word
  Assert.AreEqual(0, Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_CONST, 1);
      A.Op(OP_ARG, 44);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, 0);
    end).Call(0, []));
end;

procedure TTestQvmMachine.ChiamareUnIstruzioneCheNonEsisteDovrebbeEssereUnErrore(ATarget: Integer);
begin
  // five instructions: 0..4
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, ATarget);
      A.Op(OP_CALL);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM call to instruction');
end;

procedure TTestQvmMachine.SaltareAUnIstruzioneCheNonEsisteDovrebbeEssereUnErrore(ATarget: Integer);
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, ATarget);
      A.Op(OP_JUMP);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM jump to instruction');
end;

procedure TTestQvmMachine.TornareAUnIndirizzoCheNonEUnIstruzioneDovrebbeEssereUnErrore(AAddress: Integer);
begin
  // the program overwrites the address its entry point returns to (the -1 that ends the call); the code
  // is 26 bytes padded to 28
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_LOCAL, FRAME);
      A.Op(OP_CONST, AAddress);
      A.Op(OP_STORE4);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'VM return to');
end;

procedure TTestQvmMachine.TornareAUnIstruzioneVeraDovrebbeFunzionare;
var
  LMachine: IQvmMachine;
begin
  // the return address is made the offset of the last two instructions (CONST 77, LEAVE 0): the first
  // leave frees the frame, the second ends the call with the entry frame as it was... but for its return
  // address, which the program puts back first
  LMachine := Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      // 0..4 enter, 5..9 local, 10..14 const, 15 store, 16..20 const, 21..25 leave, 26.. the tail
      A.Op(OP_LOCAL, FRAME);
      A.Op(OP_CONST, 26);
      A.Op(OP_STORE4);
      A.Op(OP_CONST, 5);
      A.Op(OP_LEAVE, FRAME);
      // the tail: runs with the entry frame, sets its return address to -1 and leaves
      A.Op(OP_LOCAL, 0);
      A.Op(OP_CONST, -1);
      A.Op(OP_STORE4);
      A.Op(OP_CONST, 72);
      A.Op(OP_ADD);
      A.Op(OP_LEAVE, 0);
    end);
  Assert.AreEqual(77, LMachine.Call(0, []));
end;

procedure TTestQvmMachine.UnProgrammaCheSuperaLaFineDelCodiceDovrebbeEssereFermato;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 1);
    end, 'VM pc out of range');
  // the padding of the code segment is not run as instructions
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_PUSH);
    end, 'VM pc out of range');
end;

procedure TTestQvmMachine.LeDivisioniCheFermanoIlProcessoreDovrebberoEssereErrori(AOpcode, AFirst,
  ASecond: Integer; const AText: string);
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(AOpcode), TQvmNullHost.Create);
  try
    LMachine.Call(0, [AFirst, ASecond]);
    Assert.Fail('nessun errore');
  except
    on E: EQvmExecutionException do
      Assert.Contains(E.Message, AText);
  end;
end;

procedure TTestQvmMachine.LaDivisioneSenzaSegnoPerMenoUnoNonEUnErrore;
begin
  Assert.AreEqual(0, TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVU),
    TQvmNullHost.Create).Call(0, [Low(Integer), -1]));
  Assert.AreEqual(Low(Integer), TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_MODU),
    TQvmNullHost.Create).Call(0, [Low(Integer), -1]));
  Assert.AreEqual(Low(Integer), TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVI),
    TQvmNullHost.Create).Call(0, [Low(Integer), 1]));
  Assert.AreEqual(-3, TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVI),
    TQvmNullHost.Create).Call(0, [7, -2]));
  Assert.AreEqual(-1, TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_MODI),
    TQvmNullHost.Create).Call(0, [-7, 2]));
end;

procedure TTestQvmMachine.UnaCopiaABlocchiCheEsceDallaMemoriaDovrebbeEssereUnErrore;
begin
  // destination 0, source 8, count -4: the original copies the whole image from 8 and reads past its end
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_CONST, 8);
      A.Op(OP_BLOCK_COPY, -4);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'OP_BLOCK_COPY out of range');
end;

procedure TTestQvmMachine.UnaCopiaABlocchiNonAllineataDovrebbeEssereLErroreDellOriginale;
begin
  ExpectFault(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 1001);
      A.Op(OP_CONST, 2000);
      A.Op(OP_BLOCK_COPY, 8);
      A.Op(OP_CONST, 0);
      A.Op(OP_LEAVE, FRAME);
    end, 'OP_BLOCK_COPY not dword aligned');
end;

procedure TTestQvmMachine.UnCaricamentoAllaFineDellaMemoriaDovrebbeLeggereZeri;
var
  LMachine: IQvmMachine;
begin
  // the ninth argument is the last word of the image; a word read from its last byte has three bytes
  // that are not of the image
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Unary(OP_LOAD4), TQvmNullHost.Create);
  Assert.AreEqual($000000DD, LMachine.Call(0, [IMAGE - 1, 0, 0, 0, 0, 0, 0, 0, Integer($DD000000)]));
  Assert.AreEqual($0000DDCC, LMachine.Call(0, [IMAGE - 2, 0, 0, 0, 0, 0, 0, 0, Integer($DDCC0000)]));
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Unary(OP_LOAD2), TQvmNullHost.Create);
  Assert.AreEqual($000000DD, LMachine.Call(0, [IMAGE - 1, 0, 0, 0, 0, 0, 0, 0, Integer($DD000000)]));
end;

procedure TTestQvmMachine.UnaScritturaConIndirizzoQualsiasiDovrebbeRestareNellaMemoria;
const
  ADDRESSES: array[0..7] of Integer = (-1, -4, Low(Integer), High(Integer), IMAGE, IMAGE - 1, 3 * IMAGE + 5,
    Integer($FFFFE003));
var
  LMachine: IQvmMachine;
  LOpcode, LAddress: Integer;
begin
  for LOpcode in [OP_STORE1, OP_STORE2, OP_STORE4] do
  begin
    LMachine := Make(
      procedure(A: TQvmAssembler)
      begin
        A.Op(OP_ENTER, FRAME);
        TQvmPrograms.Argument(A, FRAME, 1);
        A.Op(OP_CONST, -1);
        A.Op(LOpcode);
        A.Op(OP_CONST, 0);
        A.Op(OP_LEAVE, FRAME);
      end);
    for LAddress in ADDRESSES do
      LMachine.Call(0, [LAddress]);
    // nothing landed after the image
    Assert.AreEqual(0, PInteger(PByte(LMachine.Memory.Range(0, IMAGE)) + IMAGE)^);
    Assert.AreEqual(0, PInteger(PByte(LMachine.Memory.Range(0, IMAGE)) + IMAGE + 4)^);
  end;
end;

procedure TTestQvmMachine.DopoUnErroreLaMacchinaDovrebbeEssereAncoraUsabile;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVI), TQvmNullHost.Create);
  Assert.AreEqual(4, LMachine.Call(0, [12, 3]));
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [12, 0]);
    end, EQvmExecutionException);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
  Assert.AreEqual(6, LMachine.Call(0, [12, 2]));
end;

procedure TTestQvmMachine.IlLimiteDiIstruzioniDovrebbeFermareUnCicloInfinito;
var
  LLimits: TQvmLimits;
  LMachine: IQvmMachine;
begin
  LLimits := TQvmLimits.Default;
  LLimits.InstructionLimit := 1000;
  LMachine := Make(
    procedure(A: TQvmAssembler)
    var
      LLoop: Integer;
    begin
      A.Op(OP_ENTER, FRAME);
      LLoop := A.MarkNew;
      A.Jump(LLoop);
    end, TQvmNullHost.Create, LLimits);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, []);
    end, EQvmInstructionLimitException);
  Assert.AreEqual<Int64>(1000, LMachine.InstructionsExecuted);
  Assert.AreEqual(0, LMachine.CallDepth);
end;

procedure TTestQvmMachine.IlLimiteDovrebbeValerePerOgniChiamataEsterna;
var
  LLimits: TQvmLimits;
  LMachine: IQvmMachine;
  LIndex: Integer;
begin
  // the program runs 7 instructions: a limit of 7 lets it end every time, one of 6 never
  LLimits := TQvmLimits.Default;
  LLimits.InstructionLimit := 7;
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create, LLimits);
  for LIndex := 1 to 5 do
    Assert.AreEqual(3, LMachine.Call(0, [1, 2]));
  Assert.AreEqual<Int64>(35, LMachine.InstructionsExecuted);
  LLimits.InstructionLimit := 6;
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create, LLimits);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [1, 2]);
    end, EQvmInstructionLimitException);
end;

procedure TTestQvmMachine.IlLimiteDovrebbeContareAncheLeChiamateAnnidate;
var
  LLimits: TQvmLimits;
  LMachine: IQvmMachine;
  LHost: IQvmHost;
  LText: Integer;
begin
  // every level runs 13 instructions before it asks the host to enter again: no limit of nesting is
  // reached, the instructions are
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      Result := AMachine.Call(0, [200]);
    end);
  LLimits := TQvmLimits.Default;
  LLimits.InstructionLimit := 100;
  LLimits.MaxCallDepth := 1000;
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost, LLimits);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [200]);
    end, EQvmInstructionLimitException);
  Assert.AreEqual<Int64>(100, LMachine.InstructionsExecuted);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
end;

procedure TTestQvmMachine.DovrebbeContareLeIstruzioniEseguite;
var
  LMachine: IQvmMachine;
begin
  // enter, local, load, local, load, add, leave
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  Assert.AreEqual<Int64>(0, LMachine.InstructionsExecuted);
  LMachine.Call(0, [1, 2]);
  Assert.AreEqual<Int64>(7, LMachine.InstructionsExecuted);
  LMachine.Call(0, [1, 2]);
  Assert.AreEqual<Int64>(14, LMachine.InstructionsExecuted);
  Assert.AreEqual(7, LMachine.InstructionCount);
end;

procedure TTestQvmMachine.DovrebbeContareLeIstruzioniDiBreak;
var
  LMachine: IQvmMachine;
begin
  LMachine := Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_BREAK);
      A.Op(OP_BREAK);
      A.Op(OP_UNDEF);
      A.Op(OP_IGNORE);
      A.Op(OP_CONST, 9);
      A.Op(OP_BREAK);
      A.Op(OP_LEAVE, FRAME);
    end);
  Assert.AreEqual(9, LMachine.Call(0, []));
  Assert.AreEqual(3, LMachine.BreakCount);
end;

procedure TTestQvmMachine.LaChiamataDiSistemaDovrebbeRicevereNumeroEArgomenti;
var
  LMachine: IQvmMachine;
  LHost: TQvmNullHost;
  LKeeper: IQvmHost;
  LText: Integer;
begin
  LHost := TQvmNullHost.Create;
  LKeeper := LHost;
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LKeeper);
  Assert.AreEqual(0, LMachine.Call(0, [77, 10, 20, 30]));
  Assert.AreEqual(1, LHost.Count);
  Assert.AreEqual<Int64>(1, LMachine.SystemCallCount);
  Assert.AreEqual(77, LHost.Last[0]);
  Assert.AreEqual(10, LHost.Last[1]);
  Assert.AreEqual(20, LHost.Last[2]);
  Assert.AreEqual(30, LHost.Last[3]);
  // the number 0 is the address -1, the largest one the address of the smallest integer
  LMachine.Call(0, [0]);
  Assert.AreEqual(0, LHost.Last[0]);
  LMachine.Call(0, [High(Integer)]);
  Assert.AreEqual(High(Integer), LHost.Last[0]);
  Assert.AreEqual<Int64>(3, LMachine.SystemCallCount);
end;

procedure TTestQvmMachine.GliArgomentiOltreLaCimaDelloStackDovrebberoEssereZeri;
var
  LMachine: IQvmMachine;
  LHost: TQvmNullHost;
  LKeeper: IQvmHost;
  LIndex: Integer;
begin
  // a system call from a frame of 16 bytes on top of the entry frame: the sixteen integers the host sees
  // start 4 bytes into it and run over the entry frame (its return address, the command, the nine
  // arguments); the last one is the first word after the image
  LHost := TQvmNullHost.Create;
  LKeeper := LHost;
  LMachine := TQvmFactory.CreateMachine('prova', Build(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_ENTER, FRAME);
      A.SystemCall(9);
      A.Op(OP_LEAVE, FRAME);
    end, IMAGE), LKeeper);
  LMachine.Call(1, [2, 3, 4, 5, 6, 7, 8, 9, 10]);
  Assert.AreEqual(9, LHost.Last[0]);
  Assert.AreEqual(-1, LHost.Last[3]);
  for LIndex := 5 to 14 do
    Assert.AreEqual(LIndex - 4, LHost.Last[LIndex]);
  Assert.AreEqual(0, LHost.Last[15]);
end;

procedure TTestQvmMachine.LHostDovrebbePoterRientrareNellaMacchina;
var
  LMachine: IQvmMachine;
  LHost: IQvmHost;
  LText, LDepthSeen, LStackSeen, LDeepest: Integer;
begin
  LDepthSeen := -1;
  LStackSeen := -1;
  LDeepest := 0;
  // the call 300 enters again with the call 301, which only looks
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      if AMachine.CallDepth > LDeepest then
        LDeepest := AMachine.CallDepth;
      if AArguments[0] = 300 then
        Exit(AMachine.Call(0, [301, AArguments[1] + 1]) * 2);
      LDepthSeen := AMachine.CallDepth;
      LStackSeen := AMachine.ProgramStack;
      Result := AArguments[1] * 10;
    end);
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost);
  Assert.AreEqual(100, LMachine.Call(0, [300, 4]));
  Assert.AreEqual(2, LDepthSeen);
  Assert.AreEqual(2, LDeepest);
  // two frames of 48 + 32 bytes and the 4 the machine keeps for each system call
  Assert.AreEqual(IMAGE - 2 * (QVM_ENTRY_FRAME + 32 + 4), LStackSeen);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
  Assert.AreEqual(IMAGE - QVM_STACK_SIZE, LMachine.StackBottom);
end;

procedure TTestQvmMachine.UnRientroSenzaFineDovrebbeEssereFermato;
var
  LMachine: IQvmMachine;
  LHost: IQvmHost;
  LLimits: TQvmLimits;
  LText, LDeepest: Integer;
begin
  LDeepest := 0;
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      if AMachine.CallDepth > LDeepest then
        LDeepest := AMachine.CallDepth;
      Result := AMachine.Call(0, [300]);
    end);
  LLimits := TQvmLimits.Default;
  LLimits.MaxCallDepth := 10;
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost, LLimits);
  try
    LMachine.Call(0, [300]);
    Assert.Fail('nessun errore');
  except
    on E: EQvmExecutionException do
      Assert.Contains(E.Message, 'entered 10 times');
  end;
  Assert.AreEqual(10, LDeepest);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
end;

procedure TTestQvmMachine.UnEccezioneDellHostDovrebbeUscireELasciareLaMacchinaComEra;
var
  LMachine: IQvmMachine;
  LHost: IQvmHost;
  LText: Integer;
begin
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      if AArguments[0] = 1 then
        raise EQvmFakeHostError.Create('fine');
      if AArguments[0] = 2 then
        Exit(AMachine.Call(0, [1]));
      Result := 5;
    end);
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [1]);
    end, EQvmFakeHostError);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
  // from two levels down too
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [2]);
    end, EQvmFakeHostError);
  Assert.AreEqual(0, LMachine.CallDepth);
  Assert.AreEqual(IMAGE, LMachine.ProgramStack);
  Assert.AreEqual(5, LMachine.Call(0, [3]));
end;

procedure TTestQvmMachine.LHostNonDovrebbePoterToccareMemoriaFuoriDallImmagine;
var
  LMachine: IQvmMachine;
  LHost: IQvmHost;
  LText: Integer;
begin
  // the program gives the host a pointer and a length, as a trap_ function does
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      AMachine.Memory.Fill(AArguments[1], $7F, AArguments[2]);
      Result := 0;
    end);
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost);
  LMachine.Call(0, [5, 4000, 16]);
  Assert.AreEqual($7F7F7F7F, LMachine.Memory.ReadInt32(4012));
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [5, IMAGE - 8, 9]);
    end, EQvmExecutionException);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [5, 100, -1]);
    end, EQvmExecutionException);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [5, 100, High(Integer)]);
    end, EQvmExecutionException);
  Assert.AreEqual(0, LMachine.Memory.ReadInt32(IMAGE - 8));
end;

procedure TTestQvmMachine.PiuDiNoveArgomentiDovrebberoEssereRifiutati;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  Assert.AreEqual(3, LMachine.Call(0, [1, 2, 3, 4, 5, 6, 7, 8, 9]));
  Assert.WillRaise(
    procedure
    begin
      LMachine.Call(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    end, EQvmException);
end;

procedure TTestQvmMachine.GliArgomentiMancantiDovrebberoEssereZero;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  Assert.AreEqual(11, LMachine.Call(0, [5, 6]));
  // what the call before left in the frame is not seen
  Assert.AreEqual(5, LMachine.Call(0, [5]));
  Assert.AreEqual(0, LMachine.Call(0, []));
end;

procedure TTestQvmMachine.UnImmagineTroppoPiccolaPerUnFrameNonDovrebbeEseguireNulla;
var
  LSize: Integer;
  LMachine: IQvmMachine;
begin
  for LSize in [0, 1, 2, 4, 16, 32] do
  begin
    LMachine := Make(
      procedure(A: TQvmAssembler)
      begin
        A.Op(OP_CONST, 1);
        A.Op(OP_LEAVE, 0);
      end, LSize);
    Assert.WillRaise(
      procedure
      begin
        LMachine.Call(0, []);
      end, EQvmExecutionException, IntToStr(LSize));
    Assert.AreEqual<Int64>(0, LMachine.InstructionsExecuted);
  end;
  // 48 bytes are not enough either: the frame needs 8 more for a call; 64 are
  Assert.AreEqual(1, Make(
    procedure(A: TQvmAssembler)
    begin
      A.Op(OP_CONST, 1);
      A.Op(OP_LEAVE, 0);
    end, 64).Call(0, []));
end;

procedure TTestQvmMachine.IlRiavvioDovrebbeRicaricareIDatiELasciareIlResto;
var
  LMachine: IQvmMachine;
  LFile: TBytes;
begin
  LFile := Build(
    procedure(A: TQvmAssembler)
    begin
      A.Data([111, 222]);
      // data[0] += argument; returns data[0]
      A.Op(OP_ENTER, FRAME);
      A.Op(OP_CONST, 0);
      A.Op(OP_CONST, 0);
      A.Op(OP_LOAD4);
      TQvmPrograms.Argument(A, FRAME, 1);
      A.Op(OP_ADD);
      A.Op(OP_STORE4);
      A.Op(OP_CONST, 0);
      A.Op(OP_LOAD4);
      A.Op(OP_LEAVE, FRAME);
    end, IMAGE);
  LMachine := TQvmFactory.CreateMachine('prova', LFile, TQvmNullHost.Create);
  Assert.AreEqual(116, LMachine.Call(0, [5]));
  Assert.AreEqual(121, LMachine.Call(0, [5]));
  LMachine.Memory.WriteInt32(5000, 42);
  LMachine.Restart(LFile);
  Assert.AreEqual(111, LMachine.Memory.ReadInt32(0));
  Assert.AreEqual(222, LMachine.Memory.ReadInt32(4));
  Assert.AreEqual(0, LMachine.Memory.ReadInt32(5000));
  Assert.AreEqual(112, LMachine.Call(0, [1]));
  // the counters are of the machine, not of the data
  Assert.AreEqual<Int64>(33, LMachine.InstructionsExecuted);
end;

procedure TTestQvmMachine.IlRiavvioConUnFileDiversoDovrebbeEssereRifiutato;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LMachine.Memory.WriteInt32(100, 7);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Restart(TQvmPrograms.Sieve(2 * IMAGE));
    end, EQvmFormatException);
  Assert.WillRaise(
    procedure
    begin
      LMachine.Restart(nil);
    end, EQvmFormatException);
  // the data are as they were
  Assert.AreEqual(7, LMachine.Memory.ReadInt32(100));
  Assert.AreEqual(3, LMachine.Call(0, [1, 2]));
end;

procedure TTestQvmMachine.DovrebbeDareLeInformazioniDellaMacchina;
var
  LMachine: IQvmMachine;
  LInfo: TQvmInfo;
begin
  LMachine := TQvmFactory.CreateMachine('modulo', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LInfo := LMachine.Info;
  Assert.AreEqual<AnsiString>('modulo', LInfo.Name);
  Assert.AreEqual<AnsiString>('modulo', LMachine.Name);
  // 5 + 5 + 1 + 5 + 1 + 1 + 5 bytes, padded to 24
  Assert.AreEqual(24, LInfo.CodeLength);
  Assert.AreEqual(7 * 4, LInfo.TableLength);
  Assert.AreEqual(IMAGE, LInfo.DataLength);
  Assert.AreEqual(IMAGE, LMachine.Memory.Size);
  Assert.AreEqual(IMAGE - 1, LMachine.Memory.Mask);
  Assert.AreEqual<Integer>(0, Length(LMachine.JumpTargets));
  Assert.IsFalse(LMachine.Profiling);
end;

procedure TTestQvmMachine.IlNomeDovrebbeEssereTagliatoASessantatreCaratteri;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine(AnsiString(StringOfChar('n', 100)), TQvmPrograms.Binary(OP_ADD),
    TQvmNullHost.Create);
  Assert.AreEqual<Integer>(63, Length(LMachine.Name));
end;

procedure TTestQvmMachine.SenzaNomeOSenzaHostNonDovrebbeNascere;
begin
  Assert.WillRaise(
    procedure
    begin
      TQvmFactory.CreateMachine('', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
    end, EQvmException);
  Assert.WillRaise(
    procedure
    begin
      TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), nil);
    end, EQvmException);
end;

procedure TTestQvmMachine.UnFileSbagliatoNonDovrebbeLasciareNulla;
var
  LFile: TBytes;
begin
  Assert.WillRaise(
    procedure
    begin
      TQvmFactory.CreateMachine('prova', nil, TQvmNullHost.Create);
    end, EQvmFormatException);
  // good header, bad code
  LFile := TQvmPrograms.Binary(OP_ADD);
  LFile[SizeOf(TQvmHeader)] := 200;
  Assert.WillRaise(
    procedure
    begin
      TQvmFactory.CreateMachine('prova', LFile, TQvmNullHost.Create);
    end, EQvmFormatException);
end;

procedure TTestQvmMachine.DovrebbeEsporreLaTabellaDeiSaltiDellaVersioneDue;
var
  LAssembler: TQvmAssembler;
  LMachine: IQvmMachine;
begin
  LAssembler := TQvmAssembler.Create;
  try
    LAssembler.Op(OP_ENTER, FRAME);
    LAssembler.Op(OP_CONST, 123);
    LAssembler.Op(OP_LEAVE, FRAME);
    LAssembler.JumpTargets([2, 1]);
    LAssembler.ImageSize(IMAGE);
    LMachine := TQvmFactory.CreateMachine('prova', LAssembler.ToBytes(True), TQvmNullHost.Create);
  finally
    LAssembler.Free;
  end;
  Assert.AreEqual(123, LMachine.Call(0, []));
  Assert.AreEqual<Integer>(2, Length(LMachine.JumpTargets));
  Assert.AreEqual(2, LMachine.JumpTargets[0]);
  Assert.AreEqual(1, LMachine.JumpTargets[1]);
end;

procedure TTestQvmMachine.IlProfiloDovrebbeContareLeIstruzioniPerFunzioneComeLOriginale;
var
  LMachine: IQvmMachine;
  LHelper: Integer;
  LProfile: TQvmProfile;
begin
  LHelper := 0;
  LMachine := Make(
    procedure(A: TQvmAssembler)
    var
      LLabel: Integer;
    begin
      LLabel := A.NewLabel;
      // vmMain: 8 instructions
      A.Op(OP_ENTER, 24);
      A.Op(OP_CONST, 5);
      A.Op(OP_ARG, 8);
      A.CallLabel(LLabel);
      A.Op(OP_CONST, 1);
      A.Op(OP_ADD);
      A.Op(OP_LEAVE, 24);
      // helper: 5 instructions
      A.Mark(LLabel);
      LHelper := A.Here;
      A.Op(OP_ENTER, 16);
      A.LoadLocal(16 + 8);
      A.Op(OP_NEGI);
      A.Op(OP_LEAVE, 16);
    end);
  Assert.AreEqual(3, LMachine.Symbols.Load(AnsiString(Format('0 0 vmMain' + #10 + '0 %x helper' + #10 +
    '0 fff never', [LHelper]))));
  LMachine.Profiling := True;
  Assert.IsTrue(LMachine.Profiling);
  Assert.AreEqual(-4, LMachine.Call(0, []));
  Assert.AreEqual<Int64>(13, LMachine.InstructionsExecuted);
  LProfile := LMachine.Symbols.TakeProfile;
  Assert.AreEqual<Int64>(13, LProfile.Total);
  Assert.AreEqual<AnsiString>('never', LProfile.Entries[0].Name);
  Assert.AreEqual<Int64>(0, LProfile.Entries[0].Count);
  // the OP_ENTER of a function is counted on its caller, its OP_LEAVE on the function: 4 of the helper,
  // and the 9 of vmMain are its 8 less its own enter (counted before any symbol is known: on vmMain,
  // which is the symbol of the address 0) plus the enter of the helper
  Assert.AreEqual<AnsiString>('helper', LProfile.Entries[1].Name);
  Assert.AreEqual<Int64>(4, LProfile.Entries[1].Count);
  Assert.AreEqual<AnsiString>('vmMain', LProfile.Entries[2].Name);
  Assert.AreEqual<Int64>(9, LProfile.Entries[2].Count);
  Assert.AreEqual(69, LProfile.Entries[2].Percent);
  // taken: a second call counts again from nothing
  LMachine.Call(0, []);
  Assert.AreEqual<Int64>(13, LMachine.Symbols.TakeProfile.Total);
  Assert.AreEqual<AnsiString>('vmMain', LMachine.Symbols.ValueToSymbol(0));
  Assert.AreEqual(0, LMachine.Symbols.SymbolToValue('vmMain'));
  Assert.AreEqual(3, LMachine.Symbols.Count);
end;

procedure TTestQvmMachine.SenzaProfiloNonDovrebbeContareNulla;
var
  LMachine: IQvmMachine;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LMachine.Symbols.Load('0 0 vmMain');
  LMachine.Call(0, [1, 2]);
  Assert.AreEqual<Int64>(0, LMachine.Symbols.TakeProfile.Total);
  // and with the profile but no symbols nothing breaks
  LMachine.Symbols.Load('');
  LMachine.Profiling := True;
  Assert.AreEqual(3, LMachine.Call(0, [1, 2]));
  Assert.AreEqual<Int64>(0, LMachine.Symbols.TakeProfile.Total);
end;

procedure TTestQvmMachine.LaTracciaDelloStackDovrebbeSeguireIFrame;
var
  LMachine: IQvmMachine;
  LTrace: TArray<AnsiString>;
  LIndex: Integer;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LMachine.Symbols.Load('0 0 vmMain' + #10 + '0 3 second');
  // frames as the debug build of the original leaves them: at +4 where the frame of the caller is, and
  // there the address the caller will return to
  LMachine.Memory.WriteInt32(1000 + 4, 2000);
  LMachine.Memory.WriteInt32(2000, 12);
  LMachine.Memory.WriteInt32(2000 + 4, 3000);
  LMachine.Memory.WriteInt32(3000, -1);
  LTrace := LMachine.StackTrace(1, 1000);
  Assert.AreEqual<Integer>(2, Length(LTrace));
  Assert.AreEqual<AnsiString>('vmMain+1', LTrace[0]);
  Assert.AreEqual<AnsiString>('second+1', LTrace[1]);
  // frames that never end stop at 32
  for LIndex := 0 to 99 do
  begin
    LMachine.Memory.WriteInt32(4000 + 16 * LIndex + 4, 4000 + 16 * (LIndex + 1));
    LMachine.Memory.WriteInt32(4000 + 16 * LIndex, LIndex);
  end;
  Assert.AreEqual<Integer>(32, Length(LMachine.StackTrace(0, 4000)));
  // a frame at the very end of the image is an error, not a read outside
  Assert.WillRaise(
    procedure
    begin
      LMachine.StackTrace(0, IMAGE - 6);
    end, EQvmExecutionException);
end;

procedure TTestQvmMachine.LaDivisioneFloatPerZeroDovrebbeDareInfinitoSenzaEccezioni;
var
  LMachine: IQvmMachine;
  LMask: TArithmeticExceptionMask;
begin
  // even when the caller wants its own float errors as exceptions
  LMask := SetExceptionMask([exDenormalized, exUnderflow, exPrecision]);
  try
    LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVF), TQvmNullHost.Create);
    Assert.AreEqual($7F800000, LMachine.Call(0, [$3F800000, 0]));
    Assert.AreEqual(Integer($FF800000), LMachine.Call(0, [Integer($BF800000), 0]));
    Assert.AreEqual(Integer($FFC00000), LMachine.Call(0, [0, 0]));
    LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_MULF), TQvmNullHost.Create);
    Assert.AreEqual($7F800000, LMachine.Call(0, [$7F7FFFFF, $7F7FFFFF]));
    Assert.AreEqual(0, LMachine.Call(0, [1, 1]));
  finally
    SetExceptionMask(LMask);
  end;
end;

procedure TTestQvmMachine.LaMascheraDelleEccezioniFloatDovrebbeTornareQuellaDiPrima;
var
  LMachine: IQvmMachine;
  LMask, LInside: TArithmeticExceptionMask;
  LHost: IQvmHost;
  LText: Integer;
begin
  LHost := TQvmProbeHost.Create(
    function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
    begin
      LInside := GetExceptionMask;
      Result := 0;
    end);
  LMask := SetExceptionMask([exPrecision]);
  try
    LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.AnySystemCall(LText), LHost);
    LMachine.Call(0, [5]);
    Assert.IsTrue(GetExceptionMask = [exPrecision]);
    // the host is called as the engine of the original runs: everything masked
    Assert.IsTrue(LInside = exAllArithmeticExceptions);
    LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Binary(OP_DIVI), TQvmNullHost.Create);
    Assert.WillRaise(
      procedure
      begin
        LMachine.Call(0, [1, 0]);
      end, EQvmExecutionException);
    Assert.IsTrue(GetExceptionMask = [exPrecision]);
  finally
    SetExceptionMask(LMask);
  end;
end;

procedure TTestQvmMachine.LaMemoriaVistaDallHostDovrebbeEssereQuellaDelProgramma;
var
  LMachine: IQvmMachine;
  LMemory: IQvmMemory;
  LBytes: TBytes;
begin
  LMachine := TQvmFactory.CreateMachine('prova', TQvmPrograms.Unary(OP_LOAD4), TQvmNullHost.Create);
  LMemory := LMachine.Memory;
  LMemory.WriteInt32(1000, $11223344);
  Assert.AreEqual($11223344, LMachine.Call(0, [1000]));
  Assert.AreEqual($11223344, LMemory.ReadInt32(1000));
  LMemory.WriteByte(1000, $55);
  Assert.AreEqual<Integer>($55, LMemory.ReadByte(1000));
  Assert.AreEqual($11223355, LMachine.Call(0, [1000 + IMAGE]));
  Assert.IsNull(LMemory.ArgPtr(0, 1));
  Assert.IsTrue(LMemory.ArgPtr(1000, 4) = LMemory.Range(1000, 4));
  LMemory.WriteString(2000, 'testo', 32);
  Assert.AreEqual<AnsiString>('testo', LMemory.ReadString(2000));
  LMemory.WriteBytes(2100, [9, 8, 7]);
  LBytes := LMemory.ReadBytes(2100, 3);
  Assert.AreEqual<Integer>(7, LBytes[2]);
  LMemory.Fill(2200, 3, 4);
  LMemory.Copy(2300, 2200, 4);
  Assert.AreEqual($03030303, LMachine.Call(0, [2300]));
end;

procedure TTestQvmMachine.DueMacchineNonDovrebberoCondividereNulla;
var
  LFirst, LSecond: IQvmMachine;
begin
  LFirst := TQvmFactory.CreateMachine('uno', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LSecond := TQvmFactory.CreateMachine('due', TQvmPrograms.Binary(OP_ADD), TQvmNullHost.Create);
  LFirst.Memory.WriteInt32(1000, 1);
  LFirst.Call(0, [1, 2]);
  Assert.AreEqual(0, LSecond.Memory.ReadInt32(1000));
  Assert.AreEqual<Int64>(0, LSecond.InstructionsExecuted);
  Assert.AreEqual(0, LSecond.Symbols.Count);
end;

end.
