{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptClassInfo    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.ClassInfo;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassInfo;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptClassInfo = class
  private
    FEvents: TDoomScriptEventRegistry;
    FBase: TDoomScriptClassInfo;
    FChild: TDoomScriptClassInfo;
    FOther: TDoomScriptClassInfo;
    FLast: string;
    function Handler(const AName: string): TDoomScriptEventHandler;
    procedure Call(const AClass: TDoomScriptClassInfo; const AEvent: TDoomScriptEventDef);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEreditareIGestoriDellaSuperclasse;
    [Test]
    procedure DovrebbeUsareIlGestoreRidefinitoNellaSottoclasse;
    [Test]
    procedure DovrebbeSostituireIlGestoreDellaStessaClasse;
    [Test]
    procedure DovrebbeNonRispondereAUnEventoSenzaGestore;
    [Test]
    procedure DovrebbeRiconoscereLaDiscendenza;
    [Test]
    procedure DovrebbeEsporreNomeESuperclasse;
  end;

implementation

procedure TTestDoomScriptClassInfo.Setup;
begin
  FEvents := TDoomScriptEventRegistry.Create;
  FBase := TDoomScriptClassInfo.Create('base', nil);
  FChild := TDoomScriptClassInfo.Create('child', FBase);
  FOther := TDoomScriptClassInfo.Create('other', nil);
  FLast := '';
end;

procedure TTestDoomScriptClassInfo.TearDown;
begin
  FOther.Free;
  FChild.Free;
  FBase.Free;
  FEvents.Free;
end;

function TTestDoomScriptClassInfo.Handler(const AName: string): TDoomScriptEventHandler;
begin
  Result :=
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      FLast := AName + ':' + string(AEvent.Name);
    end;
end;

procedure TTestDoomScriptClassInfo.Call(const AClass: TDoomScriptClassInfo; const AEvent: TDoomScriptEventDef);
var
  LHandler: TDoomScriptEventHandler;
  LArgs: TDoomScriptEventArgs;
begin
  FLast := '';
  LArgs := Default(TDoomScriptEventArgs);
  LHandler := AClass.FindHandler(AEvent);
  if Assigned(LHandler) then
    LHandler(nil, AEvent, LArgs);
end;

procedure TTestDoomScriptClassInfo.DovrebbeEreditareIGestoriDellaSuperclasse;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := FEvents.Define('ping');
  FBase.AddEvent(LEvent, Handler('base'));
  Assert.IsTrue(FChild.RespondsTo(LEvent));
  Call(FChild, LEvent);
  Assert.AreEqual('base:ping', FLast);
end;

procedure TTestDoomScriptClassInfo.DovrebbeUsareIlGestoreRidefinitoNellaSottoclasse;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := FEvents.Define('ping');
  FBase.AddEvent(LEvent, Handler('base'));
  FChild.AddEvent(LEvent, Handler('child'));
  Call(FChild, LEvent);
  Assert.AreEqual('child:ping', FLast);
  // the superclass keeps its own
  Call(FBase, LEvent);
  Assert.AreEqual('base:ping', FLast);
end;

procedure TTestDoomScriptClassInfo.DovrebbeSostituireIlGestoreDellaStessaClasse;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := FEvents.Define('ping');
  FBase.AddEvent(LEvent, Handler('first'));
  FBase.AddEvent(LEvent, Handler('second'));
  Call(FBase, LEvent);
  Assert.AreEqual('second:ping', FLast);
end;

procedure TTestDoomScriptClassInfo.DovrebbeNonRispondereAUnEventoSenzaGestore;
var
  LPing: TDoomScriptEventDef;
  LPong: TDoomScriptEventDef;
begin
  LPing := FEvents.Define('ping');
  LPong := FEvents.Define('pong');
  FChild.AddEvent(LPing, Handler('child'));
  Assert.IsFalse(FChild.RespondsTo(LPong));
  Assert.IsFalse(Assigned(FChild.FindHandler(LPong)));
  // a handler of the subclass is not seen by the superclass or by another class
  Assert.IsFalse(FBase.RespondsTo(LPing));
  Assert.IsFalse(FOther.RespondsTo(LPing));
  Assert.IsTrue(FChild.RespondsTo(LPing));
end;

procedure TTestDoomScriptClassInfo.DovrebbeRiconoscereLaDiscendenza;
begin
  Assert.IsTrue(FChild.IsType(FChild));
  Assert.IsTrue(FChild.IsType(FBase));
  Assert.IsFalse(FBase.IsType(FChild));
  Assert.IsFalse(FChild.IsType(FOther));
  Assert.IsFalse(FChild.IsType(nil));
end;

procedure TTestDoomScriptClassInfo.DovrebbeEsporreNomeESuperclasse;
begin
  Assert.AreEqual('child', string(FChild.Name));
  Assert.AreSame(FBase, FChild.Super);
  Assert.IsNull(FBase.Super);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptClassInfo);

end.
