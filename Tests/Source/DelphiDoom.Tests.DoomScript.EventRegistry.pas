{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptEventRegistry}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.EventRegistry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventRegistry, DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptEventRegistry = class
  private
    FRegistry: TDoomScriptEventRegistry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNumerareGliEventiNellOrdineDiDefinizione;
    [Test]
    procedure DovrebbeDareLaStessaDefinizioneSeRipetutaUguale;
    [Test]
    procedure DovrebbeRifiutareLaStessaDefinizioneConUnAltroFormato;
    [Test]
    procedure DovrebbeRifiutareLaStessaDefinizioneConUnAltroTipoDiRitorno;
    [Test]
    procedure DovrebbeCercareConLeMaiuscole;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiEventoFuoriIntervallo;
    [Test]
    procedure DovrebbeNonRegistrareUnEventoColFormatoSbagliato;
    [Test]
    procedure DovrebbeFermarsiAlMassimoDegliEventi;
  end;

implementation

procedure TTestDoomScriptEventRegistry.Setup;
begin
  FRegistry := TDoomScriptEventRegistry.Create;
end;

procedure TTestDoomScriptEventRegistry.TearDown;
begin
  FRegistry.Free;
end;

procedure TTestDoomScriptEventRegistry.DovrebbeNumerareGliEventiNellOrdineDiDefinizione;
var
  LFirst: TDoomScriptEventDef;
  LSecond: TDoomScriptEventDef;
begin
  Assert.AreEqual(0, FRegistry.Count);
  LFirst := FRegistry.Define('first');
  LSecond := FRegistry.Define('second', 'sf', 'v');
  Assert.AreEqual(2, FRegistry.Count);
  Assert.AreEqual(0, LFirst.EventNum);
  Assert.AreEqual(1, LSecond.EventNum);
  Assert.AreSame(LFirst, FRegistry.GetEvent(0));
  Assert.AreSame(LSecond, FRegistry.GetEvent(1));
  Assert.AreEqual('', string(LFirst.ArgFormat));
  Assert.IsTrue(LFirst.ReturnType = DS_EVENT_VOID);
  Assert.AreEqual('sf', string(LSecond.ArgFormat));
  Assert.AreEqual('v', string(AnsiString(LSecond.ReturnType)));
end;

procedure TTestDoomScriptEventRegistry.DovrebbeDareLaStessaDefinizioneSeRipetutaUguale;
var
  LFirst: TDoomScriptEventDef;
begin
  LFirst := FRegistry.Define('same', 'd', 'f');
  Assert.AreSame(LFirst, FRegistry.Define('same', 'd', 'f'));
  Assert.AreEqual(1, FRegistry.Count);
end;

procedure TTestDoomScriptEventRegistry.DovrebbeRifiutareLaStessaDefinizioneConUnAltroFormato;
begin
  FRegistry.Define('a', 'd');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.Define('a', 'f');
    end, EDoomScriptError,
    'idEvent ''a'' defined twice with same name but differing format strings (''f''!=''d'').');
  Assert.AreEqual(1, FRegistry.Count);
end;

procedure TTestDoomScriptEventRegistry.DovrebbeRifiutareLaStessaDefinizioneConUnAltroTipoDiRitorno;
begin
  FRegistry.Define('a', '', 'd');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.Define('a', '', 'f');
    end, EDoomScriptError,
    'idEvent ''a'' defined twice with same name but differing return types (''f''!=''d'').');
  Assert.AreEqual(1, FRegistry.Count);
end;

procedure TTestDoomScriptEventRegistry.DovrebbeCercareConLeMaiuscole;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := FRegistry.Define('SpawnString', 'ss', 's');
  Assert.AreSame(LEvent, FRegistry.FindEvent('SpawnString'));
  Assert.IsNull(FRegistry.FindEvent('spawnstring'));
  Assert.IsNull(FRegistry.FindEvent('other'));
  // a name that differs only in case is another event
  Assert.AreNotSame(LEvent, FRegistry.Define('spawnstring'));
  Assert.AreEqual(2, FRegistry.Count);
end;

procedure TTestDoomScriptEventRegistry.DovrebbeRifiutareUnNumeroDiEventoFuoriIntervallo;
begin
  FRegistry.Define('one');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.GetEvent(-1);
    end, EDoomScriptMemoryError, 'idEventDef::GetEventCommand: event -1 out of range');
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.GetEvent(1);
    end, EDoomScriptMemoryError, 'idEventDef::GetEventCommand: event 1 out of range');
end;

procedure TTestDoomScriptEventRegistry.DovrebbeNonRegistrareUnEventoColFormatoSbagliato;
begin
  TDoomScriptTestSupport.ExpectClass(
    procedure
    begin
      FRegistry.Define('bad', 'q');
    end, EDoomScriptError);
  Assert.AreEqual(0, FRegistry.Count);
  Assert.IsNull(FRegistry.FindEvent('bad'));
end;

procedure TTestDoomScriptEventRegistry.DovrebbeFermarsiAlMassimoDegliEventi;
var
  LIndex: Integer;
begin
  for LIndex := 0 to DS_MAX_EVENTS - 1 do
    FRegistry.Define(AnsiString('event' + IntToStr(LIndex)));
  Assert.AreEqual(DS_MAX_EVENTS, FRegistry.Count);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      FRegistry.Define('one_too_many');
    end, EDoomScriptError, 'numEventDefs >= MAX_EVENTS');
  // an event that is already there is still found
  Assert.AreEqual(DS_MAX_EVENTS - 1, FRegistry.Define('event4095').EventNum);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptEventRegistry);

end.
