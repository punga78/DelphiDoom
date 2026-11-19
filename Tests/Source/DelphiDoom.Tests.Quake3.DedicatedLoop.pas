{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III program - the main loop of the           }
{  dedicated server on a clock that the test moves                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Quake3.DedicatedLoop;

interface

uses
  DUnitX.TestFramework, System.Generics.Collections, System.SysUtils, DelphiDoom.Clock.ManualClock,
  DelphiDoom.Console.Q3.Factory, DelphiDoom.Quake3.Clock.Intf, DelphiDoom.Quake3.DedicatedLoop;

type
  [TestFixture]
  [Category('Quake3')]
  TTestQ3DedicatedLoop = class
  strict private
    FManual: TManualClock;
    FManualIntf: IInterface;
    FClock: IQ3Clock;
    FConsole: TQ3Console;
    FPrinted: string;
    FMilliseconds: TList<Integer>;
    function CreateLoop(AFrameLimit: Integer; AMinMilliseconds: Integer): TQ3DedicatedLoop;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlLimiteDiFrameDovrebbeFermareIlCiclo;
    [Test]
    procedure OgniFrameDovrebbeDurareAlmenoIlMinimoSenzaAttendereDiPiu;
    [Test]
    procedure IlCicloDovrebbeDormireNonGirareAVuoto;
    [Test]
    procedure QuitDovrebbeFermareDopoIlFrameInCorso;
    [Test]
    procedure IlBufferDeiComandiDovrebbeEseguireAOgniFrame;
    [Test]
    procedure UnFrameLungoDovrebbeDareIlHitchWarningEPassareIntero;
    [Test]
    procedure UnFrameLunghissimoDovrebbeEssereTagliatoACinquemila;
    [Test]
    procedure GliStadiDovrebberoGirareNellOrdineAggiunto;
    [Test]
    procedure SenzaLimiteDovrebbeGirareFinoAQuit;
    [Test]
    procedure IlMinimoDovrebbeEssereRilettoOgniFrame;
  end;

implementation

uses
  DelphiDoom.Clock.Intf, DelphiDoom.Quake3.Clock.Adapter, DelphiDoom.Quake3.ConsoleOutput, DelphiDoom.Quake3.Types;

{ TTestQ3DedicatedLoop }

procedure TTestQ3DedicatedLoop.Setup;
begin
  FManual := TManualClock.Create;
  FManualIntf := FManual;
  FClock := TQ3ClockAdapter.Create(FManual as IClock);
  FConsole := TQ3Console.Create;
  FConsole.Init;
  FPrinted := '';
  FMilliseconds := TList<Integer>.Create;
end;

procedure TTestQ3DedicatedLoop.TearDown;
begin
  FMilliseconds.Free;
  FConsole.Free;
  FClock := nil;
  FManualIntf := nil;
end;

function TTestQ3DedicatedLoop.CreateLoop(AFrameLimit, AMinMilliseconds: Integer): TQ3DedicatedLoop;
begin
  Result := TQ3DedicatedLoop.Create(FClock, FConsole.Buffer,
    TQ3ConsoleOutput.Create(
      procedure(AText: string)
      begin
        FPrinted := FPrinted + AText;
      end),
    function: Integer
    begin
      Result := AMinMilliseconds;
    end, AFrameLimit);
  Result.AddStage(
    procedure(AMilliseconds: Integer)
    begin
      FMilliseconds.Add(AMilliseconds);
    end);
end;

procedure TTestQ3DedicatedLoop.IlLimiteDiFrameDovrebbeFermareIlCiclo;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(7, 50);
  try
    Assert.AreEqual(7, LLoop.Run);
    Assert.AreEqual(7, LLoop.Frames);
    Assert.AreEqual<Integer>(7, FMilliseconds.Count);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.OgniFrameDovrebbeDurareAlmenoIlMinimoSenzaAttendereDiPiu;
var
  LLoop: TQ3DedicatedLoop;
  LMilliseconds: Integer;
begin
  LLoop := CreateLoop(5, 50);
  try
    LLoop.Run;
    for LMilliseconds in FMilliseconds do
      Assert.AreEqual(50, LMilliseconds);
    // cinque frame da 50 ms: l'orologio ha fatto 250 ms
    Assert.AreEqual(250, FClock.Milliseconds);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.IlCicloDovrebbeDormireNonGirareAVuoto;
var
  LLoop: TQ3DedicatedLoop;
begin
  // con l'orologio manuale solo Sleep fa passare il tempo: se il ciclo girasse a vuoto non finirebbe mai
  LLoop := CreateLoop(1, 20);
  try
    LLoop.RunFrame;
    Assert.AreEqual(20, FClock.Milliseconds);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.QuitDovrebbeFermareDopoIlFrameInCorso;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(Q3_FRAMES_UNLIMITED, 50);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        if FMilliseconds.Count = 3 then
          LLoop.Quit;
      end);
    Assert.AreEqual(3, LLoop.Run);
    Assert.IsTrue(LLoop.IsQuitRequested);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.IlBufferDeiComandiDovrebbeEseguireAOgniFrame;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(2, 50);
  try
    FConsole.Buffer.AddText('set prova uno'#10);
    LLoop.RunFrame;
    Assert.AreEqual('uno', string(FConsole.CVars.VariableString('prova')));
    FConsole.Buffer.AddText('set prova due'#10);
    LLoop.RunFrame;
    Assert.AreEqual('due', string(FConsole.CVars.VariableString('prova')));
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.UnFrameLungoDovrebbeDareIlHitchWarningEPassareIntero;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(3, 50);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        // il caricamento di una mappa: tra il frame 1 e il 2 passano 800 ms (misurati dall'inizio del frame 1)
        if FMilliseconds.Count = 1 then
          FManual.Advance(800);
      end);
    LLoop.Run;
    Assert.AreEqual(50, FMilliseconds[0]);
    Assert.AreEqual(800, FMilliseconds[1]);
    Assert.AreEqual(50, FMilliseconds[2]);
    Assert.IsTrue(FPrinted.Contains('Hitch warning: 800 msec frame time'), FPrinted);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.UnFrameLunghissimoDovrebbeEssereTagliatoACinquemila;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(2, 50);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        if FMilliseconds.Count = 1 then
          FManual.Advance(9000);
      end);
    LLoop.Run;
    Assert.AreEqual(5000, FMilliseconds[1]);
    Assert.IsTrue(FPrinted.Contains('Hitch warning: 9000'), FPrinted);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.GliStadiDovrebberoGirareNellOrdineAggiunto;
var
  LLoop: TQ3DedicatedLoop;
  LOrder: string;
begin
  LOrder := '';
  LLoop := TQ3DedicatedLoop.Create(FClock, FConsole.Buffer, nil, nil, 2);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        LOrder := LOrder + 'a';
      end);
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        LOrder := LOrder + 'b';
      end);
    LLoop.Run;
    Assert.AreEqual('abab', LOrder);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.SenzaLimiteDovrebbeGirareFinoAQuit;
var
  LLoop: TQ3DedicatedLoop;
begin
  LLoop := CreateLoop(Q3_FRAMES_UNLIMITED, 10);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        if FMilliseconds.Count >= 40 then
          LLoop.Quit;
      end);
    Assert.AreEqual(40, LLoop.Run);
  finally
    LLoop.Free;
  end;
end;

procedure TTestQ3DedicatedLoop.IlMinimoDovrebbeEssereRilettoOgniFrame;
var
  LLoop: TQ3DedicatedLoop;
  LMinimum: Integer;
begin
  LMinimum := 50;
  LLoop := TQ3DedicatedLoop.Create(FClock, FConsole.Buffer, nil,
    function: Integer
    begin
      Result := LMinimum;
    end, 4);
  try
    LLoop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        FMilliseconds.Add(AMilliseconds);
        // sv_fps cambia: i frame diventano da 25 ms
        LMinimum := 25;
      end);
    LLoop.Run;
    Assert.AreEqual(50, FMilliseconds[0]);
    Assert.AreEqual(25, FMilliseconds[1]);
    Assert.AreEqual(25, FMilliseconds[3]);
  finally
    LLoop.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3DedicatedLoop);

end.
