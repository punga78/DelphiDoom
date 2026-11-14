{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the pilot that follows a script   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.ScriptPilot;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.ScriptParser,
  DelphiDoom.Parity.ScriptPilot,
  DelphiDoom.Parity.Types,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParityScriptPilot = class(TObject)
  strict private
    FLog: TFakeParityLog;
    FLogRef: IParityLog;
    FPilot: IParityPilot;
    FView: TParityPilotView;
    procedure Load(const AScript: string);
    /// <summary>The player of the test: at a point of the map (map units), looking at an angle in degrees</summary>
    procedure Place(AX, AY, AZ: Integer; ADegrees: Integer);
    /// <summary>The nearest enemy that the view of the test tells (map units)</summary>
    procedure PlaceEnemy(AX, AY, AZ: Integer);
    function Next: TParityPilotCommand;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaTenutaDovrebbeDareGliStessiTastiPerISuoiTic;
    [Test]
    procedure DopoUnaTenutaDovrebbePassareAlPassoSeguente;
    [Test]
    procedure IlTastoUsoDovrebbeEsserePremutoUnaVoltaOgniSeiTic;
    [Test]
    procedure LArmaDovrebbeEssereChiestaSoloAlPrimoTic;
    [Test]
    procedure FinitiIPassiDovrebbeEssereFinitoDalTicDopo;
    [Test]
    procedure UnoScriptVuotoDovrebbeFinireSubito;
    [Test]
    procedure PrimaCheIlGiocatoreNascaNonDovrebbeConsumareIPassi;
    [Test]
    procedure AllaMorteDelGiocatoreDovrebbeFermarsiEDirlo;
    [Test]
    procedure UnVaiDovrebbeSpingereAvantiVersoUnPuntoDavanti;
    [Test]
    procedure UnVaiDovrebbeGirareASinistraVersoUnPuntoASinistra;
    [Test]
    procedure UnVaiDovrebbeGirareADestraVersoUnPuntoADestra;
    [Test]
    procedure UnVaiNonDovrebbeSpingereSeIlPuntoNonEDavanti;
    [Test]
    procedure LaSterzataDiUnVaiDovrebbeEssereUnMultiploDi256EntroIlLimite;
    [Test]
    procedure UnVaiDovrebbeFinireDentroIlRaggio;
    [Test]
    procedure UnVaiConUnaQuotaDovrebbeSalireOScendere;
    [Test]
    procedure UnVaiDovrebbeSparareEUsareSeRichiesto;
    [Test]
    procedure UnVaiCheNonArrivaDovrebbeRinunciareEFermareLoScript;
    [Test]
    procedure UnGuardaDovrebbeGirareSenzaMuoversiEFinireQuandoEAllineato;
    [Test]
    procedure UnSaliDovrebbePremereSaltoFinoAllaQuota;
    [Test]
    procedure LaBombaDovrebbeEsserePremutaUnaVoltaEIlPostbruciatoreTenuto;
    [Test]
    procedure SalvaECaricaDovrebberoEssereChiestiPerUnTicSolo;
    [Test]
    procedure UnSalvaInFondoAlCopioneDovrebbeEssereChiestoLoStesso;
    [Test]
    procedure UnSaliVersoIlBassoDovrebbePremereAbbassati;
    [Test]
    procedure SenzaPassiCheCombattonoNonDovrebbeChiedereINemici;
    [Test]
    procedure ConUnPassoCheCombatteDovrebbeChiedereIlRaggioPiuGrande;
    [Test]
    procedure UnaCacciaDovrebbeGirareVersoIlNemicoESparareQuandoEAllineata;
    [Test]
    procedure UnaCacciaDovrebbeMettersiAllaQuotaDelNemico;
    [Test]
    procedure UnaCacciaDovrebbeSpostarsiDiLatoUnPoDiQuaEUnPoDiLa;
    [Test]
    procedure UnaCacciaDovrebbeAvvicinarsiAUnNemicoLontanoEAllontanarsiDaUnoVicino;
    [Test]
    procedure UnaCacciaSenzaNemiciDovrebbeFinireDopoVentiTic;
    [Test]
    procedure UnaCacciaDovrebbeFinireAlSuoTempoSenzaFermareLoScript;
    [Test]
    procedure UnNemicoFuoriRaggioNonDovrebbeEssereCombattuto;
    [Test]
    procedure UnVaiCheCombatteDovrebbeFermarsiPerIlNemicoEPoiRiprendere;
    [Test]
    procedure UnaSostaDovrebbeAspettareLaSaluteRichiesta;
    [Test]
    procedure UnaSostaDovrebbeCombattereChiSiAvvicina;
    [Test]
    procedure UnaSostaDovrebbeFinireAlSuoTempoSenzaFermareLoScript;
    [Test]
    procedure IlRapportoDovrebbeDireRigaTicEPosizioneDiOgniPasso;
    [Test]
    procedure SenzaRapportoDovrebbeFunzionareLoStesso;
    [Test]
    procedure LoStessoScriptELeStesseVisteDovrebberoDareGliStessiComandi;
    [Test]
    procedure UnPilotaSimulatoDovrebbeRaggiungereUnaSerieDiPunti;
  end;

implementation

const
  FRACUNIT = 65536;

procedure TTestParityScriptPilot.Setup;
begin
  FLog := TFakeParityLog.Create;
  FLogRef := FLog;
  FView := Default(TParityPilotView);
  FView.Alive := True;
end;

procedure TTestParityScriptPilot.TearDown;
begin
  FPilot := nil;
  FLogRef := nil;
  FLog := nil;
end;

procedure TTestParityScriptPilot.Load(const AScript: string);
begin
  FPilot := TParityScriptPilot.Create(TParityScriptParser.Parse(AScript), FLogRef);
end;

procedure TTestParityScriptPilot.Place(AX, AY, AZ: Integer; ADegrees: Integer);
begin
  FView.X := AX * FRACUNIT;
  FView.Y := AY * FRACUNIT;
  FView.Z := AZ * FRACUNIT;
  FView.Angle := Cardinal((Int64(ADegrees) * $40000000) div 90);
end;

procedure TTestParityScriptPilot.PlaceEnemy(AX, AY, AZ: Integer);
begin
  FView.HasEnemy := True;
  FView.EnemyX := AX * FRACUNIT;
  FView.EnemyY := AY * FRACUNIT;
  FView.EnemyZ := AZ * FRACUNIT;
end;

function TTestParityScriptPilot.Next: TParityPilotCommand;
begin
  Result := FPilot.NextCommand(FView);
  Inc(FView.Tic);
end;

procedure TTestParityScriptPilot.UnaTenutaDovrebbeDareGliStessiTastiPerISuoiTic;
var
  LIndex: Integer;
  LCommand: TParityPilotCommand;
begin
  Load('hold 5 forward 40 side 10 turn -2 look 3 fire jump');
  for LIndex := 1 to 5 do
  begin
    LCommand := Next;
    Assert.AreEqual(40, LCommand.Forward);
    Assert.AreEqual(10, LCommand.Side);
    Assert.AreEqual(-512, LCommand.Turn);
    Assert.AreEqual(3, LCommand.Look);
    Assert.IsTrue(LCommand.Fire);
    Assert.IsTrue(LCommand.Jump);
    Assert.IsFalse(LCommand.Crouch);
  end;
end;

procedure TTestParityScriptPilot.DopoUnaTenutaDovrebbePassareAlPassoSeguente;
begin
  Load('hold 2 forward 10'#10'hold 2 back 20');
  Assert.AreEqual(10, Next.Forward);
  Assert.AreEqual(10, Next.Forward);
  Assert.AreEqual(-20, Next.Forward);
  Assert.AreEqual(-20, Next.Forward);
end;

procedure TTestParityScriptPilot.IlTastoUsoDovrebbeEsserePremutoUnaVoltaOgniSeiTic;
var
  LIndex: Integer;
  LUses: string;
begin
  Load('hold 13 use');
  LUses := '';
  for LIndex := 1 to 13 do
    if Next.Use then
      LUses := LUses + 'U'
    else
      LUses := LUses + '.';
  Assert.AreEqual('U.....U.....U', LUses);
end;

procedure TTestParityScriptPilot.LArmaDovrebbeEssereChiestaSoloAlPrimoTic;
begin
  Load('hold 3 weapon 5');
  Assert.AreEqual(5, Next.Weapon);
  Assert.AreEqual(0, Next.Weapon);
  Assert.AreEqual(0, Next.Weapon);
end;

procedure TTestParityScriptPilot.FinitiIPassiDovrebbeEssereFinitoDalTicDopo;
var
  LCommand: TParityPilotCommand;
begin
  Load('hold 2 fire');
  Next;
  Next;
  Assert.IsFalse(FPilot.IsFinished(FView.Tic));
  // the tic after the last step has an empty command, then the pilot has finished
  LCommand := Next;
  Assert.IsFalse(LCommand.Fire);
  Assert.IsTrue(FPilot.IsFinished(FView.Tic));
  Assert.Contains(FLog.Lines.Text, 'script complete at tic 2');
end;

procedure TTestParityScriptPilot.UnoScriptVuotoDovrebbeFinireSubito;
begin
  Load('# nothing');
  Assert.IsFalse(FPilot.IsFinished(0));
  Next;
  Assert.IsTrue(FPilot.IsFinished(1));
end;

procedure TTestParityScriptPilot.PrimaCheIlGiocatoreNascaNonDovrebbeConsumareIPassi;
var
  LIndex: Integer;
begin
  Load('hold 2 fire');
  FView.Alive := False;
  for LIndex := 1 to 10 do
    Assert.IsFalse(Next.Fire);
  Assert.IsFalse(FPilot.IsFinished(FView.Tic));
  FView.Alive := True;
  Assert.IsTrue(Next.Fire);
  Assert.IsTrue(Next.Fire);
end;

procedure TTestParityScriptPilot.AllaMorteDelGiocatoreDovrebbeFermarsiEDirlo;
begin
  Load('hold 50 fire');
  Next;
  FView.Alive := False;
  Assert.IsFalse(Next.Fire);
  Assert.IsTrue(FPilot.IsFinished(FView.Tic));
  Assert.Contains(FLog.Lines.Text, 'THE PLAYER DIED');
  Assert.Contains(FLog.Lines.Text, 'script stopped at tic 1');
end;

procedure TTestParityScriptPilot.UnVaiDovrebbeSpingereAvantiVersoUnPuntoDavanti;
var
  LCommand: TParityPilotCommand;
begin
  Load('goto 1000 0');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.AreEqual(50, LCommand.Forward);
  Assert.AreEqual(0, LCommand.Turn);
end;

procedure TTestParityScriptPilot.UnVaiDovrebbeGirareASinistraVersoUnPuntoASinistra;
begin
  Load('goto 0 1000');
  Place(0, 0, 0, 0);
  Assert.AreEqual(1280, Next.Turn);
end;

procedure TTestParityScriptPilot.UnVaiDovrebbeGirareADestraVersoUnPuntoADestra;
begin
  Load('goto 0 -1000');
  Place(0, 0, 0, 0);
  Assert.AreEqual(-1280, Next.Turn);
end;

procedure TTestParityScriptPilot.UnVaiNonDovrebbeSpingereSeIlPuntoNonEDavanti;
begin
  Load('goto -1000 0 speed 30');
  Place(0, 0, 0, 0);
  Assert.AreEqual(0, Next.Forward);
  // 20 degrees off the nose is near enough
  Place(0, 0, 0, 160);
  Assert.AreEqual(30, Next.Forward);
end;

procedure TTestParityScriptPilot.LaSterzataDiUnVaiDovrebbeEssereUnMultiploDi256EntroIlLimite;
var
  LDegrees: Integer;
  LTurn: Integer;
begin
  Load('goto 777 333');
  for LDegrees := 0 to 359 do
  begin
    Place(0, 0, 0, LDegrees);
    LTurn := Next.Turn;
    Assert.AreEqual(0, LTurn mod 256);
    Assert.IsTrue(Abs(LTurn) <= 1280, IntToStr(LDegrees));
  end;
end;

procedure TTestParityScriptPilot.UnVaiDovrebbeFinireDentroIlRaggio;
begin
  Load('goto 100 100 radius 20'#10'hold 1 fire');
  Place(100, 121, 0, 0);
  Assert.IsFalse(Next.Fire);
  Place(100, 119, 0, 0);
  // inside the radius: the step is over and the next one answers in the same tic
  Assert.IsTrue(Next.Fire);
end;

procedure TTestParityScriptPilot.UnVaiConUnaQuotaDovrebbeSalireOScendere;
var
  LCommand: TParityPilotCommand;
begin
  Load('goto 1000 0 z 100');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.IsTrue(LCommand.Jump);
  Assert.IsFalse(LCommand.Crouch);
  Place(0, 0, 200, 0);
  LCommand := Next;
  Assert.IsFalse(LCommand.Jump);
  Assert.IsTrue(LCommand.Crouch);
  Place(0, 0, 104, 0);
  LCommand := Next;
  Assert.IsFalse(LCommand.Jump);
  Assert.IsFalse(LCommand.Crouch);
end;

procedure TTestParityScriptPilot.UnVaiDovrebbeSparareEUsareSeRichiesto;
var
  LCommand: TParityPilotCommand;
begin
  Load('goto 1000 0 fire use');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.IsTrue(LCommand.Fire);
  Assert.IsTrue(LCommand.Use);
  LCommand := Next;
  Assert.IsTrue(LCommand.Fire);
  Assert.IsFalse(LCommand.Use);
end;

procedure TTestParityScriptPilot.UnVaiCheNonArrivaDovrebbeRinunciareEFermareLoScript;
var
  LIndex: Integer;
begin
  Load('goto 1000 0 timeout 10'#10'hold 5 fire');
  Place(0, 0, 0, 0);
  for LIndex := 1 to 10 do
    Assert.AreEqual(50, Next.Forward);
  Assert.IsFalse(FPilot.IsFinished(FView.Tic));
  Assert.AreEqual(0, Next.Forward);
  Assert.IsTrue(FPilot.IsFinished(FView.Tic));
  Assert.Contains(FLog.Lines.Text, 'line 1 goto: GAVE UP at tic 10');
  // the steps after the one that gave up are not done
  Assert.IsFalse(Next.Fire);
end;

procedure TTestParityScriptPilot.UnGuardaDovrebbeGirareSenzaMuoversiEFinireQuandoEAllineato;
var
  LCommand: TParityPilotCommand;
begin
  Load('face 0 500 fire'#10'hold 1 forward 7');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.AreEqual(1280, LCommand.Turn);
  Assert.AreEqual(0, LCommand.Forward);
  Assert.IsTrue(LCommand.Fire);
  Place(0, 0, 0, 90);
  Assert.AreEqual(7, Next.Forward);
end;

procedure TTestParityScriptPilot.LaBombaDovrebbeEsserePremutaUnaVoltaEIlPostbruciatoreTenuto;
var
  LCommand: TParityPilotCommand;
begin
  Load('hold 3 forward 50 afterburner bomb'#10'goto 1000 0 afterburner'#10'hold 1 forward 10');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.IsTrue(LCommand.Bomb);
  Assert.IsTrue(LCommand.Afterburner);
  LCommand := Next;
  Assert.IsFalse(LCommand.Bomb);
  Assert.IsTrue(LCommand.Afterburner);
  Next;
  LCommand := Next;
  Assert.AreEqual(50, LCommand.Forward);
  Assert.IsTrue(LCommand.Afterburner);
  Assert.IsFalse(LCommand.Bomb);
  Place(1000, 0, 0, 0);
  LCommand := Next;
  Assert.IsFalse(LCommand.Afterburner);
end;

procedure TTestParityScriptPilot.SalvaECaricaDovrebberoEssereChiestiPerUnTicSolo;
var
  LCommand: TParityPilotCommand;
begin
  Load('hold 1 forward 10'#10'save 2'#10'hold 2 forward 20'#10'load 4'#10'hold 1 forward 30');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.AreEqual(10, LCommand.Forward);
  Assert.IsFalse(LCommand.Save);
  // the save takes no tic: it goes with the first command of the step after it
  LCommand := Next;
  Assert.IsTrue(LCommand.Save);
  Assert.IsFalse(LCommand.Load);
  Assert.AreEqual(2, LCommand.Slot);
  Assert.AreEqual(20, LCommand.Forward);
  LCommand := Next;
  Assert.IsFalse(LCommand.Save);
  Assert.AreEqual(20, LCommand.Forward);
  LCommand := Next;
  Assert.IsTrue(LCommand.Load);
  Assert.IsFalse(LCommand.Save);
  Assert.AreEqual(4, LCommand.Slot);
  Assert.AreEqual(30, LCommand.Forward);
  LCommand := Next;
  Assert.IsFalse(LCommand.Load);
  Assert.IsTrue(FPilot.IsFinished(0));
end;

procedure TTestParityScriptPilot.UnSalvaInFondoAlCopioneDovrebbeEssereChiestoLoStesso;
var
  LCommand: TParityPilotCommand;
begin
  Load('hold 1 forward 10'#10'save 1');
  Place(0, 0, 0, 0);
  Next;
  LCommand := Next;
  Assert.IsTrue(LCommand.Save);
  Assert.AreEqual(1, LCommand.Slot);
  Assert.AreEqual(0, LCommand.Forward);
  Assert.IsTrue(FPilot.IsFinished(0));
end;

procedure TTestParityScriptPilot.UnSaliDovrebbePremereSaltoFinoAllaQuota;
var
  LCommand: TParityPilotCommand;
begin
  Load('climb 64'#10'hold 1 fire');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.IsTrue(LCommand.Jump);
  Assert.AreEqual(0, LCommand.Forward);
  Place(0, 0, 60, 0);
  Assert.IsTrue(Next.Fire);
end;

procedure TTestParityScriptPilot.UnSaliVersoIlBassoDovrebbePremereAbbassati;
var
  LCommand: TParityPilotCommand;
begin
  Load('climb -64');
  Place(0, 0, 0, 0);
  LCommand := Next;
  Assert.IsTrue(LCommand.Crouch);
  Assert.IsFalse(LCommand.Jump);
end;

procedure TTestParityScriptPilot.SenzaPassiCheCombattonoNonDovrebbeChiedereINemici;
begin
  Load('hold 5 fire'#10'goto 1 2'#10'face 3 4'#10'climb 5');
  Assert.AreEqual(0, FPilot.EnemyRange);
end;

procedure TTestParityScriptPilot.ConUnPassoCheCombatteDovrebbeChiedereIlRaggioPiuGrande;
begin
  Load('hunt 5 range 300'#10'goto 1 2 fight range 900'#10'hunt 5 range 100');
  Assert.AreEqual(900, FPilot.EnemyRange);
end;

procedure TTestParityScriptPilot.UnaCacciaDovrebbeGirareVersoIlNemicoESparareQuandoEAllineata;
var
  LCommand: TParityPilotCommand;
begin
  Load('hunt 100');
  Place(0, 0, 0, 0);
  PlaceEnemy(0, 500, 0);
  LCommand := Next;
  Assert.AreEqual(1280, LCommand.Turn);
  Assert.IsFalse(LCommand.Fire);
  Assert.AreEqual(0, LCommand.Forward);
  Place(0, 0, 0, 88);
  LCommand := Next;
  Assert.IsTrue(LCommand.Fire);
end;

procedure TTestParityScriptPilot.UnaCacciaDovrebbeMettersiAllaQuotaDelNemico;
begin
  Load('hunt 100');
  Place(0, 0, 0, 0);
  PlaceEnemy(500, 0, 200);
  Assert.IsTrue(Next.Jump);
  PlaceEnemy(500, 0, -200);
  Assert.IsTrue(Next.Crouch);
end;

procedure TTestParityScriptPilot.UnaCacciaDovrebbeSpostarsiDiLatoUnPoDiQuaEUnPoDiLa;
var
  LIndex: Integer;
  LRight: Integer;
  LLeft: Integer;
begin
  Load('hunt 100');
  Place(0, 0, 0, 0);
  PlaceEnemy(500, 0, 0);
  LRight := 0;
  LLeft := 0;
  for LIndex := 1 to 64 do
    if Next.Side > 0 then
      Inc(LRight)
    else
      Inc(LLeft);
  Assert.AreEqual(32, LRight);
  Assert.AreEqual(32, LLeft);
end;

procedure TTestParityScriptPilot.UnaCacciaDovrebbeAvvicinarsiAUnNemicoLontanoEAllontanarsiDaUnoVicino;
begin
  Load('hunt 100');
  Place(0, 0, 0, 0);
  PlaceEnemy(1000, 0, 0);
  Assert.AreEqual(25, Next.Forward);
  PlaceEnemy(600, 0, 0);
  Assert.AreEqual(0, Next.Forward);
  PlaceEnemy(250, 0, 0);
  Assert.AreEqual(-25, Next.Forward);
  // not while the nose is still turning to it
  PlaceEnemy(0, 1000, 0);
  Assert.AreEqual(0, Next.Forward);
end;

procedure TTestParityScriptPilot.UnaCacciaSenzaNemiciDovrebbeFinireDopoVentiTic;
var
  LIndex: Integer;
begin
  Load('hunt 500'#10'hold 1 forward 9');
  for LIndex := 1 to 19 do
    Assert.AreEqual(0, Next.Forward);
  Assert.AreEqual(9, Next.Forward);
end;

procedure TTestParityScriptPilot.UnaCacciaDovrebbeFinireAlSuoTempoSenzaFermareLoScript;
var
  LIndex: Integer;
begin
  Load('hunt 30'#10'hold 1 forward 9');
  Place(0, 0, 0, 0);
  PlaceEnemy(500, 0, 0);
  for LIndex := 1 to 30 do
    Assert.IsTrue(Next.Fire);
  Assert.AreEqual(9, Next.Forward);
  Assert.IsFalse(FLog.Lines.Text.Contains('GAVE UP'));
end;

procedure TTestParityScriptPilot.UnNemicoFuoriRaggioNonDovrebbeEssereCombattuto;
begin
  Load('hunt 100 range 400');
  Place(0, 0, 0, 0);
  PlaceEnemy(500, 0, 0);
  Assert.IsFalse(Next.Fire);
  PlaceEnemy(390, 0, 0);
  Assert.IsTrue(Next.Fire);
end;

procedure TTestParityScriptPilot.UnVaiCheCombatteDovrebbeFermarsiPerIlNemicoEPoiRiprendere;
var
  LCommand: TParityPilotCommand;
begin
  Load('goto 2000 0 fight');
  Place(0, 0, 0, 0);
  Assert.AreEqual(50, Next.Forward);
  PlaceEnemy(0, -600, 0);
  LCommand := Next;
  Assert.AreEqual(0, LCommand.Forward);
  Assert.AreEqual(-1280, LCommand.Turn);
  FView.HasEnemy := False;
  Assert.AreEqual(50, Next.Forward);
end;

procedure TTestParityScriptPilot.UnaSostaDovrebbeAspettareLaSaluteRichiesta;
var
  LIndex: Integer;
  LCommand: TParityPilotCommand;
begin
  Load('heal 80 1000'#10'hold 1 forward 9');
  FView.Health := 40;
  for LIndex := 1 to 50 do
  begin
    LCommand := Next;
    Assert.AreEqual(0, LCommand.Forward);
    Assert.IsFalse(LCommand.Fire);
  end;
  FView.Health := 80;
  Assert.AreEqual(9, Next.Forward);
end;

procedure TTestParityScriptPilot.UnaSostaDovrebbeCombattereChiSiAvvicina;
begin
  Load('heal 80 1000');
  FView.Health := 40;
  Place(0, 0, 0, 0);
  PlaceEnemy(600, 0, 0);
  Assert.IsTrue(Next.Fire);
end;

procedure TTestParityScriptPilot.UnaSostaDovrebbeFinireAlSuoTempoSenzaFermareLoScript;
var
  LIndex: Integer;
begin
  Load('heal 80 30'#10'hold 1 forward 9');
  FView.Health := 40;
  for LIndex := 1 to 30 do
    Assert.AreEqual(0, Next.Forward);
  Assert.AreEqual(9, Next.Forward);
  Assert.IsFalse(FLog.Lines.Text.Contains('GAVE UP'));
end;

procedure TTestParityScriptPilot.IlRapportoDovrebbeDireRigaTicEPosizioneDiOgniPasso;
begin
  Load('# way'#10'hold 2'#10'goto 5 5');
  Place(5, 6, 7, 0);
  FView.Tic := 40;
  Next;
  Next;
  Next;
  Assert.AreEqual('line 2 hold: done at tic 42 after 2 tics, player at 5 6 7', FLog.Lines[0]);
  Assert.AreEqual('line 3 goto: done at tic 42 after 0 tics, player at 5 6 7', FLog.Lines[1]);
  Assert.AreEqual('script complete at tic 42', FLog.Lines[2]);
  Assert.IsTrue(FLog.FlushCount >= 3);
end;

procedure TTestParityScriptPilot.SenzaRapportoDovrebbeFunzionareLoStesso;
begin
  FPilot := TParityScriptPilot.Create(TParityScriptParser.Parse('hold 1 fire'), nil);
  Assert.IsTrue(Next.Fire);
  Next;
  Assert.IsTrue(FPilot.IsFinished(FView.Tic));
end;

procedure TTestParityScriptPilot.LoStessoScriptELeStesseVisteDovrebberoDareGliStessiComandi;
const
  SCRIPT = 'goto 300 200 fire'#10'face 0 0'#10'hold 9 side 12';
var
  LFirst: IParityPilot;
  LSecond: IParityPilot;
  LIndex: Integer;
  LOne: TParityPilotCommand;
  LTwo: TParityPilotCommand;
begin
  LFirst := TParityScriptPilot.Create(TParityScriptParser.Parse(SCRIPT), nil);
  LSecond := TParityScriptPilot.Create(TParityScriptParser.Parse(SCRIPT), nil);
  for LIndex := 0 to 199 do
  begin
    Place(LIndex * 2, LIndex, 0, LIndex * 3);
    FView.Tic := LIndex;
    LOne := LFirst.NextCommand(FView);
    LTwo := LSecond.NextCommand(FView);
    Assert.AreEqual(LOne.Forward, LTwo.Forward);
    Assert.AreEqual(LOne.Side, LTwo.Side);
    Assert.AreEqual(LOne.Turn, LTwo.Turn);
    Assert.AreEqual(LOne.Fire, LTwo.Fire);
  end;
end;

procedure TTestParityScriptPilot.UnPilotaSimulatoDovrebbeRaggiungereUnaSerieDiPunti;
var
  LCommand: TParityPilotCommand;
  LX: Double;
  LY: Double;
  LSpeedX: Double;
  LSpeedY: Double;
  LAngle: Integer;
  LRadians: Double;
  LTics: Integer;
begin
  // a craft with thrust and drag, as the player of the engine in flight: the pilot must not circle a point
  Load('goto 600 0'#10'goto 600 500'#10'goto -200 500 radius 32'#10'goto 0 0');
  LX := 0;
  LY := 0;
  LSpeedX := 0;
  LSpeedY := 0;
  LAngle := 16384;
  LTics := 0;
  while not FPilot.IsFinished(LTics) and (LTics < 3000) do
  begin
    FView.Tic := LTics;
    FView.X := Round(LX * FRACUNIT);
    FView.Y := Round(LY * FRACUNIT);
    FView.Angle := Cardinal(LAngle and $FFFF) shl 16;
    LCommand := FPilot.NextCommand(FView);
    LAngle := LAngle + LCommand.Turn;
    LRadians := (LAngle and $FFFF) * Pi / 32768;
    LSpeedX := (LSpeedX + LCommand.Forward * 2048 / FRACUNIT * Cos(LRadians)) * 15 / 16;
    LSpeedY := (LSpeedY + LCommand.Forward * 2048 / FRACUNIT * Sin(LRadians)) * 15 / 16;
    LX := LX + LSpeedX;
    LY := LY + LSpeedY;
    Inc(LTics);
  end;
  Assert.IsTrue(LTics < 3000, 'the pilot never arrived');
  Assert.Contains(FLog.Lines.Text, 'script complete');
  Assert.IsFalse(FLog.Lines.Text.Contains('GAVE UP'), FLog.Lines.Text);
end;

end.
