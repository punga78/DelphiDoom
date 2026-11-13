{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom geoscape library - from the landing       }
{  confirmation to the battle (the launcher that the Battlescape gives)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.MissionLauncher;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomGeoscape.Control.Intf,
  DelphiDoom.XcomGeoscape.MissionLauncher.Intf, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>The launcher of the tests: keeps the requests it receives</summary>
  TFakeLauncher = class(TInterfacedObject, IXcomMissionLauncher)
  strict private
    FRequests: TArray<TXcomMissionRequest>;
  public
    procedure BeginMission(const ARequest: TXcomMissionRequest);
    property Requests: TArray<TXcomMissionRequest> read FRequests;
  end;

  [TestFixture]
  [Category('xcom-geoscape')]
  TTestXcomMissionLauncher = class(TObject)
  strict private
    FWorld: TTestWorld;
    FLauncher: TFakeLauncher;
    FLauncherRef: IXcomMissionLauncher;
    FCraftRules: TXcomRuleCraft;
    FUfoRules: TXcomRuleUfo;
    FCraft: TXcomCraft;
    FUfo: TXcomUfo;
    function Confirm(AStatus: Integer): TXcomState;
    procedure Click(AState: TXcomState; AButtonIndex: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvviareIlRecuperoDiUnUfoSchiantato;
    [Test]
    procedure DovrebbeAvviareLAssaltoDiUnUfoAterra;
    [Test]
    procedure DovrebbeDareTexturEOmbraAlLanciatore;
    [Test]
    procedure DovrebbeRimandareIlVelivoloAllaBaseConNo;
    [Test]
    procedure DovrebbeSegnalareLaMancanzaDiUnaMissione;
    [Test]
    procedure DovrebbeChiudereLaConfermaSenzaLanciatore;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.ConfirmLandingState, DelphiDoom.XcomGeoscape.Strategy;

type
  TStateCracker = class(TXcomState);

{ TFakeLauncher }

procedure TFakeLauncher.BeginMission(const ARequest: TXcomMissionRequest);
begin
  FRequests := FRequests + [ARequest];
end;

{ TTestXcomMissionLauncher }

procedure TTestXcomMissionLauncher.Setup;
begin
  FWorld := TTestWorld.Create;
  FLauncher := TFakeLauncher.Create;
  FLauncherRef := FLauncher;
  FCraftRules := TXcomRuleCraft.Create('STR_TRITON');
  FUfoRules := TXcomRuleUfo.Create('STR_SMALL_SCOUT');
  FCraft := TXcomCraft.Create(FCraftRules, nil, 1);
  FUfo := TXcomUfo.Create(FUfoRules);
end;

procedure TTestXcomMissionLauncher.TearDown;
begin
  FCraft.Free;
  FUfo.Free;
  FUfoRules.Free;
  FCraftRules.Free;
  FLauncherRef := nil;
  FWorld.Free;
end;

function TTestXcomMissionLauncher.Confirm(AStatus: Integer): TXcomState;
begin
  FUfo.Status := AStatus;
  FCraft.SetDestination(FUfo);
  Result := TXcomConfirmLandingState.Create(FWorld.Game, FCraft, FLauncherRef, 3, 9);
  FWorld.Game.PushState(Result);
end;

procedure TTestXcomMissionLauncher.Click(AState: TXcomState; AButtonIndex: Integer);
var
  LWidget: TXcomWidget;
  LCount: Integer;
begin
  FWorld.Wait(400);
  LCount := 0;
  for LWidget in TStateCracker(AState).Surfaces do
    if LWidget is TXcomTextButton then
    begin
      if LCount = AButtonIndex then
      begin
        FWorld.Click((LWidget.X + LWidget.Width div 2) * 2, (LWidget.Y + LWidget.Height div 2) * 2);
        Exit;
      end;
      Inc(LCount);
    end;
  Assert.Fail('pulsante non trovato');
end;

procedure TTestXcomMissionLauncher.DovrebbeAvviareIlRecuperoDiUnUfoSchiantato;
var
  LState: TXcomState;
begin
  LState := Confirm(TXcomUfo.STATUS_CRASHED);
  Click(LState, 0);
  Assert.AreEqual<Integer>(1, Length(FLauncher.Requests));
  Assert.AreEqual('STR_UFO_CRASH_RECOVERY', FLauncher.Requests[0].MissionType);
  Assert.IsTrue(FLauncher.Requests[0].Ufo = FUfo);
  Assert.IsTrue(FLauncher.Requests[0].Craft = FCraft);
end;

procedure TTestXcomMissionLauncher.DovrebbeAvviareLAssaltoDiUnUfoAterra;
var
  LState: TXcomState;
begin
  LState := Confirm(TXcomUfo.STATUS_LANDED);
  Click(LState, 0);
  Assert.AreEqual('STR_UFO_GROUND_ASSAULT', FLauncher.Requests[0].MissionType);
end;

procedure TTestXcomMissionLauncher.DovrebbeDareTexturEOmbraAlLanciatore;
var
  LState: TXcomState;
begin
  LState := Confirm(TXcomUfo.STATUS_LANDED);
  Click(LState, 0);
  Assert.AreEqual(3, FLauncher.Requests[0].WorldTexture);
  Assert.AreEqual(9, FLauncher.Requests[0].WorldShade);
  Assert.IsFalse(FWorld.Game.IsState(LState), 'la conferma e'' chiusa prima del briefing');
end;

procedure TTestXcomMissionLauncher.DovrebbeRimandareIlVelivoloAllaBaseConNo;
var
  LState: TXcomState;
begin
  LState := Confirm(TXcomUfo.STATUS_LANDED);
  Click(LState, 1);
  Assert.AreEqual<Integer>(0, Length(FLauncher.Requests));
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

procedure TTestXcomMissionLauncher.DovrebbeSegnalareLaMancanzaDiUnaMissione;
var
  LState: TXcomConfirmLandingState;
  LRaised: Boolean;
  LBase: TXcomBase;
begin
  // a base is a target but never a mission
  LBase := TXcomBase.Create;
  FCraft.SetDestination(LBase);
  LState := TXcomConfirmLandingState.Create(FWorld.Game, FCraft, FLauncherRef);
  try
    LRaised := False;
    try
      LState.Request;
    except
      on EXcomGeoscapeException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised);
  finally
    LState.Free;
    FCraft.SetDestination(nil);
    LBase.Free;
  end;
end;

procedure TTestXcomMissionLauncher.DovrebbeChiudereLaConfermaSenzaLanciatore;
var
  LState: TXcomState;
begin
  FUfo.Status := TXcomUfo.STATUS_LANDED;
  FCraft.SetDestination(FUfo);
  LState := TXcomConfirmLandingState.Create(FWorld.Game, FCraft, nil);
  FWorld.Game.PushState(LState);
  Click(LState, 0);
  Assert.IsFalse(FWorld.Game.IsState(LState));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMissionLauncher);

end.
