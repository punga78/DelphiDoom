{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptEventTarget  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.EventTarget;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptEventTarget = class
  private
    FEvents: TDoomScriptEventRegistry;
    FClass: TDoomScriptClassInfo;
    FTarget: TDoomScriptEventTarget;
    FSeenTarget: TObject;
    FSeenInt: Integer;
    FSeenText: string;
    FCalls: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEseguireIlGestoreConGliArgomenti;
    [Test]
    procedure DovrebbeDareFalsoSenzaGestore;
    [Test]
    procedure DovrebbeEseguireUnEventoSenzaArgomenti;
    [Test]
    procedure DovrebbeRifiutareUnTargetSenzaClasse;
    [Test]
    procedure DovrebbeEsporreLaSuaClasse;
  end;

implementation

procedure TTestDoomScriptEventTarget.Setup;
begin
  FEvents := TDoomScriptEventRegistry.Create;
  FClass := TDoomScriptClassInfo.Create('thing', nil);
  FTarget := TDoomScriptEventTarget.Create(FClass);
  FSeenTarget := nil;
  FSeenInt := 0;
  FSeenText := '';
  FCalls := 0;
end;

procedure TTestDoomScriptEventTarget.TearDown;
begin
  FTarget.Free;
  FClass.Free;
  FEvents.Free;
end;

procedure TTestDoomScriptEventTarget.DovrebbeEseguireIlGestoreConGliArgomenti;
var
  LEvent: TDoomScriptEventDef;
  LArgs: TDoomScriptEventArgs;
begin
  LEvent := FEvents.Define('set', 'ds');
  FClass.AddEvent(LEvent,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      Inc(FCalls);
      FSeenTarget := ATarget;
      FSeenInt := AArgs[0].IntValue;
      FSeenText := string(AArgs[1].StringValue);
    end);
  LArgs := Default(TDoomScriptEventArgs);
  LArgs[0] := TDoomScriptConvert.IntArg(12);
  LArgs[1] := TDoomScriptConvert.StringArg('text');
  Assert.IsTrue(FTarget.RespondsTo(LEvent));
  Assert.IsTrue(FTarget.ProcessEvent(LEvent, LArgs));
  Assert.AreEqual(1, FCalls);
  Assert.AreSame(FTarget, FSeenTarget);
  Assert.AreEqual(12, FSeenInt);
  Assert.AreEqual('text', FSeenText);
end;

procedure TTestDoomScriptEventTarget.DovrebbeDareFalsoSenzaGestore;
var
  LEvent: TDoomScriptEventDef;
  LArgs: TDoomScriptEventArgs;
begin
  LEvent := FEvents.Define('unknown');
  LArgs := Default(TDoomScriptEventArgs);
  Assert.IsFalse(FTarget.RespondsTo(LEvent));
  Assert.IsFalse(FTarget.ProcessEvent(LEvent, LArgs));
  Assert.IsFalse(FTarget.ProcessEvent(LEvent));
end;

procedure TTestDoomScriptEventTarget.DovrebbeEseguireUnEventoSenzaArgomenti;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := FEvents.Define('go');
  FClass.AddEvent(LEvent,
    procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      Inc(FCalls);
      FSeenInt := AArgs[0].IntValue + AArgs[7].IntValue;
      FSeenText := string(AArgs[0].StringValue) + string(AEvent.Name);
    end);
  FSeenInt := 99;
  Assert.IsTrue(FTarget.ProcessEvent(LEvent));
  Assert.AreEqual(1, FCalls);
  // the arguments are all empty
  Assert.AreEqual(0, FSeenInt);
  Assert.AreEqual('go', FSeenText);
end;

procedure TTestDoomScriptEventTarget.DovrebbeRifiutareUnTargetSenzaClasse;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptEventTarget.Create(nil).Free;
    end, EDoomScriptError, 'TDoomScriptEventTarget: a target needs a class');
end;

procedure TTestDoomScriptEventTarget.DovrebbeEsporreLaSuaClasse;
begin
  Assert.AreSame(FClass, FTarget.EventClass);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptEventTarget);

end.
