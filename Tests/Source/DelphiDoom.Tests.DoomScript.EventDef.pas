{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptEventDef     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.EventDef;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptEventDef = class
  public
    [Test]
    procedure DovrebbeCalcolareGliOffsetDegliArgomenti;
    [Test]
    procedure DovrebbeContareLaDimensioneDiUnaTraccia;
    [Test]
    procedure DovrebbeAccettareUnEventoSenzaArgomenti;
    [Test]
    procedure DovrebbeRifiutareUnFormatoNonValido;
    [Test]
    procedure DovrebbeRifiutareTroppiArgomenti;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiArgomentoFuoriIntervallo;
  end;

implementation

procedure TTestDoomScriptEventDef.DovrebbeCalcolareGliOffsetDegliArgomenti;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := TDoomScriptEventDef.Create('ev', 'dfvseE', 'f', 3);
  try
    Assert.AreEqual('ev', string(LEvent.Name));
    Assert.AreEqual('dfvseE', string(LEvent.ArgFormat));
    Assert.AreEqual('f', string(AnsiString(LEvent.ReturnType)));
    Assert.AreEqual(3, LEvent.EventNum);
    Assert.AreEqual(6, LEvent.GetNumArgs);
    Assert.AreEqual(0, LEvent.GetArgOffset(0));
    Assert.AreEqual(4, LEvent.GetArgOffset(1));
    Assert.AreEqual(8, LEvent.GetArgOffset(2));
    Assert.AreEqual(20, LEvent.GetArgOffset(3));
    Assert.AreEqual(20 + DS_MAX_STRING_LEN, LEvent.GetArgOffset(4));
    Assert.AreEqual(24 + DS_MAX_STRING_LEN, LEvent.GetArgOffset(5));
    Assert.AreEqual(28 + DS_MAX_STRING_LEN, LEvent.ArgSize);
    // the arguments the format does not have are at offset zero
    Assert.AreEqual(0, LEvent.GetArgOffset(7));
  finally
    LEvent.Free;
  end;
end;

procedure TTestDoomScriptEventDef.DovrebbeContareLaDimensioneDiUnaTraccia;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := TDoomScriptEventDef.Create('touch', 'et', DS_EVENT_VOID, 0);
  try
    Assert.AreEqual(4, LEvent.GetArgOffset(1));
    // sizeof( trace_t ) + MAX_STRING_LEN + sizeof( bool ) of the 32 bit build
    Assert.AreEqual(4 + 100 + DS_MAX_STRING_LEN + 1, LEvent.ArgSize);
  finally
    LEvent.Free;
  end;
end;

procedure TTestDoomScriptEventDef.DovrebbeAccettareUnEventoSenzaArgomenti;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := TDoomScriptEventDef.Create('none', '', DS_EVENT_VOID, 9);
  try
    Assert.AreEqual(0, LEvent.GetNumArgs);
    Assert.AreEqual(0, LEvent.ArgSize);
    Assert.IsTrue(LEvent.ReturnType = DS_EVENT_VOID);
  finally
    LEvent.Free;
  end;
end;

procedure TTestDoomScriptEventDef.DovrebbeRifiutareUnFormatoNonValido;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptEventDef.Create('bad', 'dx', DS_EVENT_VOID, 0).Free;
    end, EDoomScriptError, 'idEventDef::idEventDef : Invalid arg format ''dx'' string for ''bad'' event.');
end;

procedure TTestDoomScriptEventDef.DovrebbeRifiutareTroppiArgomenti;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptEventDef.Create('many', 'ddddddddd', DS_EVENT_VOID, 0).Free;
    end, EDoomScriptError, 'idEventDef::idEventDef : Too many args for ''many'' event.');
end;

procedure TTestDoomScriptEventDef.DovrebbeRifiutareUnIndiceDiArgomentoFuoriIntervallo;
var
  LEvent: TDoomScriptEventDef;
begin
  LEvent := TDoomScriptEventDef.Create('ev', 'd', DS_EVENT_VOID, 0);
  try
    TDoomScriptTestSupport.ExpectError(
      procedure
      begin
        LEvent.GetArgOffset(-1);
      end, EDoomScriptMemoryError, 'idEventDef::GetArgOffset: argument -1 out of range');
    TDoomScriptTestSupport.ExpectError(
      procedure
      begin
        LEvent.GetArgOffset(DS_EVENT_MAXARGS);
      end, EDoomScriptMemoryError, 'idEventDef::GetArgOffset: argument 8 out of range');
  finally
    LEvent.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptEventDef);

end.
