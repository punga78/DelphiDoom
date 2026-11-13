{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the machine, the shutdown  }
{  and the fatal errors                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Lifecycle;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf, DelphiDoom.Tests.EngineSystem.Fakes;

type
  /// <summary>A plan that gives the steps that the test sets</summary>
  TFakePlan = class(TInterfacedObject, IShutdownPlan)
  public
    Items: TArray<TShutdownStep>;
    LastCode: Integer;
    function Steps(ACode: Integer): TArray<TShutdownStep>;
  end;

  /// <summary>The steps of the fatal error, written in a list; the state is a field</summary>
  TFakeFatalSteps = class(TInterfacedObject, IFatalErrorSteps)
  public
    Calls: TStringList;
    Failing: Boolean;
    constructor Create;
    destructor Destroy; override;
    function IsFailing: Boolean;
    procedure FlashOutput;
    procedure MarkFailing;
    procedure FinishDemo;
    procedure Report(const AMessage: string);
    procedure Terminate;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestMachineProfileBuilder = class(TObject)
  public
    [Test]
    procedure DovrebbeRifiutareUnProcessoreNullo;
    [Test]
    procedure DovrebbeScrivereLeEstensioni;
    [Test]
    procedure DovrebbeDecidereIFiliSeNonCeConfigurazione;
    [Test]
    procedure DovrebbeTenereLaConfigurazioneSeCe;
    [Test]
    procedure DovrebbeScrivereIlModoDeiFili;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodice;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestShutdownSequence = class(TObject)
  private
    FLog: TRecordingLog;
    FLogRef: ILog;
    FPlan: TFakePlan;
    FPlanRef: IShutdownPlan;
    FTerminated: TStringList;
    FSequence: IShutdownSequence;
    FRan: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareParametriNulli;
    [Test]
    procedure DovrebbeEssereFinitoSoloDopoRun;
    [Test]
    procedure DovrebbeScrivereEEseguireOgniPassoInOrdine;
    [Test]
    procedure DovrebbeScrivereLaRigaDiUnPassoSenzaAzione;
    [Test]
    procedure DovrebbeDareIlCodiceAlPianoEAlTermine;
    [Test]
    procedure DovrebbeNonTerminareSeUnPassoDaErrore;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestFatalErrorHandler = class(TObject)
  private
    FSteps: TFakeFatalSteps;
    FStepsRef: IFatalErrorSteps;
    FHandler: IFatalErrorHandler;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIPassiNulli;
    [Test]
    procedure DovrebbeFareIPassiNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeIgnorareUnErroreDentroUnErrore;
    [Test]
    procedure DovrebbeNonDipendereDaNientAltroCheDaiPassi;
  end;

implementation

uses
  DelphiDoom.Platform.Intf, DelphiDoom.EngineSystem.Factory, DelphiDoom.EngineSystem.MachineProfileBuilder,
  DelphiDoom.EngineSystem.ShutdownSequence, DelphiDoom.EngineSystem.FatalErrorHandler,
  DelphiDoom.Tests.EngineSystem.Legacy;

{ TFakePlan }

function TFakePlan.Steps(ACode: Integer): TArray<TShutdownStep>;
begin
  LastCode := ACode;
  Result := Items;
end;

{ TFakeFatalSteps }

constructor TFakeFatalSteps.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
end;

destructor TFakeFatalSteps.Destroy;
begin
  Calls.Free;
  inherited Destroy;
end;

function TFakeFatalSteps.IsFailing: Boolean;
begin
  Calls.Add('isfailing');
  Result := Failing;
end;

procedure TFakeFatalSteps.FlashOutput;
begin
  Calls.Add('flash');
end;

procedure TFakeFatalSteps.MarkFailing;
begin
  Calls.Add('mark');
  Failing := True;
end;

procedure TFakeFatalSteps.FinishDemo;
begin
  Calls.Add('demo');
end;

procedure TFakeFatalSteps.Report(const AMessage: string);
begin
  Calls.Add('report ' + AMessage);
end;

procedure TFakeFatalSteps.Terminate;
begin
  Calls.Add('terminate');
end;

function Join(AList: TStrings): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AList.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ';';
    Result := Result + AList[LIndex];
  end;
end;

{ TTestMachineProfileBuilder }

procedure TTestMachineProfileBuilder.DovrebbeRifiutareUnProcessoreNullo;
begin
  Assert.WillRaise(
    procedure
    begin
      TMachineProfileBuilder.Detect(nil, True, False);
    end, EArgumentNilException);
end;

procedure TTestMachineProfileBuilder.DovrebbeScrivereLeEstensioni;
var
  LProfile: TMachineProfile;
begin
  LProfile := TMachineProfileBuilder.Detect(TFakeCpu.Create(1, True, True), True, False);
  Assert.IsTrue(LProfile.HasMmx);
  Assert.IsTrue(LProfile.Has3DNow);
  Assert.AreEqual(' MMX extentions detected'#13#10, LProfile.Lines[0]);
  Assert.AreEqual(' AMD 3D Now! extentions detected'#13#10, LProfile.Lines[1]);
end;

procedure TTestMachineProfileBuilder.DovrebbeDecidereIFiliSeNonCeConfigurazione;
begin
  Assert.IsTrue(TMachineProfileBuilder.Detect(TFakeCpu.Create(4, False, False), True, False).UseMultithread);
  Assert.IsFalse(TMachineProfileBuilder.Detect(TFakeCpu.Create(1, False, False), True, True).UseMultithread);
end;

procedure TTestMachineProfileBuilder.DovrebbeTenereLaConfigurazioneSeCe;
begin
  Assert.IsFalse(TMachineProfileBuilder.Detect(TFakeCpu.Create(8, False, False), False, False).UseMultithread);
  Assert.IsTrue(TMachineProfileBuilder.Detect(TFakeCpu.Create(1, False, False), False, True).UseMultithread);
end;

procedure TTestMachineProfileBuilder.DovrebbeScrivereIlModoDeiFili;
var
  LProfile: TMachineProfile;
begin
  LProfile := TMachineProfileBuilder.Detect(TFakeCpu.Create(4, False, False), True, False);
  Assert.AreEqual(' Multi-core system detected (4 CPUs)'#13#10, LProfile.Lines[0]);
  Assert.AreEqual(' Multithreading mode ON'#13#10, LProfile.Lines[1]);
  LProfile := TMachineProfileBuilder.Detect(TFakeCpu.Create(4, False, False), False, False);
  Assert.AreEqual(' Multithreading mode OFF (will not use all cores)'#13#10, LProfile.Lines[1]);
  LProfile := TMachineProfileBuilder.Detect(TFakeCpu.Create(1, False, False), True, False);
  Assert.AreEqual(' Multithreading mode OFF'#13#10, LProfile.Lines[0]);
end;

procedure TTestMachineProfileBuilder.DovrebbeDareLoStessoRisultatoDelVecchioCodice;
var
  LCpus: Integer;
  LFlags: Integer;
  LNotFound: Integer;
  LCurrent: Integer;
  LCpu: ICpuInfo;
  LOld: TLegacyCpu;
  LProfile: TMachineProfile;
  LText: string;
  LLine: string;
begin
  for LCpus := 1 to 9 do
    for LFlags := 0 to 3 do
      for LNotFound := 0 to 1 do
        for LCurrent := 0 to 1 do
        begin
          LCpu := TFakeCpu.Create(LCpus, LFlags and 1 <> 0, LFlags and 2 <> 0);
          LOld := TLegacyCpu.Create;
          try
            LOld.usemultithread := LCurrent = 1;
            LOld.I_DetectCPU(LCpu, LNotFound = 1);
            LProfile := TMachineProfileBuilder.Detect(LCpu, LNotFound = 1, LCurrent = 1);
            LText := '';
            for LLine in LProfile.Lines do
              LText := LText + LLine;
            Assert.AreEqual(LOld.Output, LText);
            Assert.AreEqual(LOld.mmxMachine <> 0, LProfile.HasMmx);
            Assert.AreEqual(LOld.AMD3DNowMachine <> 0, LProfile.Has3DNow);
            Assert.AreEqual(LOld.numcpus, LProfile.ProcessorCount);
            Assert.AreEqual(LOld.usemultithread, LProfile.UseMultithread);
          finally
            LOld.Free;
          end;
        end;
end;

{ TTestShutdownSequence }

procedure TTestShutdownSequence.Setup;
begin
  FLog := TRecordingLog.Create;
  FLogRef := FLog;
  FPlan := TFakePlan.Create;
  FPlanRef := FPlan;
  FTerminated := TStringList.Create;
  FRan := TStringList.Create;
  FSequence := TEngineSystemFactory.CreateShutdownSequence(FPlanRef, FLogRef,
    procedure(ACode: Integer)
    begin
      FTerminated.Add(IntToStr(ACode));
    end);
end;

procedure TTestShutdownSequence.TearDown;
begin
  FSequence := nil;
  FRan.Free;
  FTerminated.Free;
  FPlanRef := nil;
  FLogRef := nil;
end;

procedure TTestShutdownSequence.DovrebbeRifiutareParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TShutdownSequence.Create(nil, FLogRef, procedure(ACode: Integer) begin end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TShutdownSequence.Create(FPlanRef, nil, procedure(ACode: Integer) begin end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TShutdownSequence.Create(FPlanRef, FLogRef, nil);
    end, EArgumentNilException);
end;

procedure TTestShutdownSequence.DovrebbeEssereFinitoSoloDopoRun;
begin
  Assert.IsFalse(FSequence.IsFinished);
  FSequence.Run(0);
  Assert.IsTrue(FSequence.IsFinished);
end;

procedure TTestShutdownSequence.DovrebbeScrivereEEseguireOgniPassoInOrdine;
begin
  SetLength(FPlan.Items, 2);
  FPlan.Items[0] := TShutdownStep.Make('one'#13#10,
    procedure
    begin
      FRan.Add('one');
    end);
  FPlan.Items[1] := TShutdownStep.Make('two'#13#10,
    procedure
    begin
      FRan.Add('two');
    end);
  FSequence.Run(0);
  Assert.AreEqual(#13#10'I_Destroy: Game finished.'#13#10#13#10'one'#13#10'two'#13#10, FLog.InfoText);
  Assert.AreEqual('one;two', Join(FRan));
end;

procedure TTestShutdownSequence.DovrebbeScrivereLaRigaDiUnPassoSenzaAzione;
begin
  SetLength(FPlan.Items, 1);
  FPlan.Items[0] := TShutdownStep.Make('only a line'#13#10, nil);
  FSequence.Run(0);
  Assert.IsTrue(Pos('only a line', FLog.InfoText) > 0);
end;

procedure TTestShutdownSequence.DovrebbeDareIlCodiceAlPianoEAlTermine;
begin
  FSequence.Run(3);
  Assert.AreEqual(3, FPlan.LastCode);
  Assert.AreEqual('3', Join(FTerminated));
end;

procedure TTestShutdownSequence.DovrebbeNonTerminareSeUnPassoDaErrore;
begin
  SetLength(FPlan.Items, 1);
  FPlan.Items[0] := TShutdownStep.Make('x',
    procedure
    begin
      raise Exception.Create('step failed');
    end);
  Assert.WillRaise(
    procedure
    begin
      FSequence.Run(1);
    end, Exception, 'step failed');
  Assert.AreEqual(0, FTerminated.Count);
end;

{ TTestFatalErrorHandler }

procedure TTestFatalErrorHandler.Setup;
begin
  FSteps := TFakeFatalSteps.Create;
  FStepsRef := FSteps;
  FHandler := TEngineSystemFactory.CreateFatalErrorHandler(FStepsRef);
end;

procedure TTestFatalErrorHandler.TearDown;
begin
  FHandler := nil;
  FStepsRef := nil;
end;

procedure TTestFatalErrorHandler.DovrebbeRifiutareIPassiNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TFatalErrorHandler.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestFatalErrorHandler.DovrebbeFareIPassiNellOrdineDelVecchioCodice;
begin
  FHandler.Handle('boom');
  // I_Error: the guard, I_FlashCachedOutput, in_i_error := true, the demo, the message, I_Destroy(1)
  Assert.AreEqual('isfailing;flash;mark;demo;report boom;terminate', Join(FSteps.Calls));
end;

procedure TTestFatalErrorHandler.DovrebbeIgnorareUnErroreDentroUnErrore;
begin
  FSteps.Failing := True;
  FHandler.Handle('again');
  Assert.AreEqual('isfailing', Join(FSteps.Calls));
end;

procedure TTestFatalErrorHandler.DovrebbeNonDipendereDaNientAltroCheDaiPassi;
begin
  // twice: the second error finds the state that the first one left
  FHandler.Handle('first');
  FHandler.Handle('second');
  Assert.AreEqual('isfailing;flash;mark;demo;report first;terminate;isfailing', Join(FSteps.Calls));
end;

end.
