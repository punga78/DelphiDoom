{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - where the events of the window go    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppSessionEventSink;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.War.App.SessionEventSink, DelphiDoom.Tests.War.AppSession;

type
  /// <summary>The sink of the window: the scale of the mouse and the way to the session</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppSessionEventSink = class(TObject)
  strict private
    FRig: TAppSessionRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDividereLaPosizioneDelMousePerLaScala;
    [Test]
    procedure DovrebbeDividereAncheIClicDelMouse;
    [Test]
    procedure DovrebbeLasciareStareGliEventiCheNonSonoDelMouse;
    [Test]
    procedure DovrebbeNonCambiareNullaConLaScalaUno;
    [Test]
    procedure DovrebbeRifiutareUnaSessioneNilEUnaScalaZero;
  end;

implementation

{ TTestWarAppSessionEventSink }

procedure TTestWarAppSessionEventSink.Setup;
begin
  FRig := TAppSessionRig.Create(1000);
end;

procedure TTestWarAppSessionEventSink.TearDown;
begin
  FRig.Free;
end;

procedure TTestWarAppSessionEventSink.DovrebbeDividereLaPosizioneDelMousePerLaScala;
var
  LSink: IGameHostEventSink;
  LEvent: TGameHostEvent;
begin
  LSink := TWarSessionEventSink.Create(FRig.Session, 3);
  LEvent := TGameHostEvent.Make(hekMouseMotion);
  LEvent.X := 959;
  LEvent.Y := 601;
  LSink.Post(LEvent);
  Assert.AreEqual('E 3 0 319 200', FRig.CurrentGame.Log[0]);
end;

procedure TTestWarAppSessionEventSink.DovrebbeDividereAncheIClicDelMouse;
var
  LSink: IGameHostEventSink;
  LEvent: TGameHostEvent;
begin
  LSink := TWarSessionEventSink.Create(FRig.Session, 2);
  LEvent := TGameHostEvent.Make(hekMouseDown);
  LEvent.X := 100;
  LEvent.Y := 50;
  LSink.Post(LEvent);
  LEvent.Kind := hekMouseUp;
  LSink.Post(LEvent);
  Assert.AreEqual('E 4 0 50 25', FRig.CurrentGame.Log[0]);
  Assert.AreEqual('E 5 0 50 25', FRig.CurrentGame.Log[1]);
end;

procedure TTestWarAppSessionEventSink.DovrebbeLasciareStareGliEventiCheNonSonoDelMouse;
var
  LSink: IGameHostEventSink;
  LEvent: TGameHostEvent;
begin
  LSink := TWarSessionEventSink.Create(FRig.Session, 4);
  LEvent := TGameHostEvent.Make(hekKeyDown);
  LEvent.VirtualKey := $4D;
  LEvent.X := 40;
  LEvent.Y := 80;
  LSink.Post(LEvent);
  Assert.AreEqual('E 1 77 40 80', FRig.CurrentGame.Log[0]);
end;

procedure TTestWarAppSessionEventSink.DovrebbeNonCambiareNullaConLaScalaUno;
var
  LSink: IGameHostEventSink;
  LEvent: TGameHostEvent;
begin
  LSink := TWarSessionEventSink.Create(FRig.Session, 1);
  LEvent := TGameHostEvent.Make(hekMouseMotion);
  LEvent.X := 123;
  LEvent.Y := 45;
  LSink.Post(LEvent);
  Assert.AreEqual('E 3 0 123 45', FRig.CurrentGame.Log[0]);
end;

procedure TTestWarAppSessionEventSink.DovrebbeRifiutareUnaSessioneNilEUnaScalaZero;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSessionEventSink.Create(nil, 3);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TWarSessionEventSink.Create(FRig.Session, 0);
    end, EArgumentOutOfRangeException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppSessionEventSink);

end.
