{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptMachine      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Machine;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.DoomScript.Types,
  DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.Machine,
  DelphiDoom.DoomScript.Thread, DelphiDoom.DoomScript.Factory;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptMachine = class
  private
    FHost: TDoomScriptFakeHost;
    FHostIntf: IDoomScriptHost;
    FLog: TIdLibLogRecorder;
    FLogIntf: IIdLibLog;
    FFiles: TIdLibMemoryFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FMachine: TDoomScriptMachine;
    procedure Compile(const AText: AnsiString);
    function Run(const AFunction: AnsiString): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCompilareEdEseguireUnaFunzione;
    [Test]
    procedure DovrebbeAspettareIlTempoDellHost;
  end;

implementation

const
  DEFS: AnsiString =
    'scriptEvent void print( string text );'#10 +
    'scriptEvent void println( string text );'#10 +
    'scriptEvent void wait( float time );'#10 +
    'scriptEvent void waitFrame();'#10;

procedure TTestDoomScriptMachine.Setup;
begin
  FHost := TDoomScriptFakeHost.Create;
  FHostIntf := FHost;
  FLog := TIdLibLogRecorder.Create;
  FLogIntf := FLog;
  FFiles := TIdLibMemoryFileSystem.Create;
  FFilesIntf := FFiles;
  FFiles.SetFile('script/doom_defs.script', DEFS);
  FMachine := TDoomScriptFactory.CreateMachine(FHostIntf, FHost, FLogIntf, FFilesIntf);
  FMachine.ScriptProgram.BeginCompilation;
end;

procedure TTestDoomScriptMachine.TearDown;
begin
  FMachine.Free;
  FFilesIntf := nil;
  FLogIntf := nil;
  FHostIntf := nil;
end;

procedure TTestDoomScriptMachine.Compile(const AText: AnsiString);
begin
  FMachine.ScriptProgram.CompileText('test.script', AText, False);
  FMachine.ScriptProgram.FinishCompilation;
end;

function TTestDoomScriptMachine.Run(const AFunction: AnsiString): Boolean;
var
  LFunction: TDoomScriptFunction;
begin
  LFunction := FMachine.ScriptProgram.FindFunction(AFunction);
  Assert.IsNotNull(LFunction, 'function ' + string(AFunction));
  Result := FMachine.CreateThread(LFunction).Start;
end;

procedure TTestDoomScriptMachine.DovrebbeCompilareEdEseguireUnaFunzione;
begin
  Compile('float twice( float x ) { return x * 2; }'#10 +
    'void main() { float a = twice( 21 ); sys.println( "a=" + a ); }'#10);
  Assert.IsTrue(Run('main'));
  Assert.IsTrue(FLog.Entries.IndexOf('P:a=42'#10) >= 0, FLog.Entries.Text);
end;

procedure TTestDoomScriptMachine.DovrebbeAspettareIlTempoDellHost;
begin
  Compile('void main() { sys.print( "one" ); sys.wait( 0.1 ); sys.print( "two" ); }'#10);
  Assert.IsFalse(Run('main'));
  Assert.IsTrue(FLog.Entries.IndexOf('P:one') >= 0);
  Assert.IsTrue(FLog.Entries.IndexOf('P:two') < 0);
  FHost.Time := 99;
  FMachine.ServiceEvents;
  Assert.IsTrue(FLog.Entries.IndexOf('P:two') < 0);
  FHost.Time := 100;
  FMachine.ServiceEvents;
  Assert.IsTrue(FLog.Entries.IndexOf('P:two') >= 0);
  // the thread removes itself at the next service
  FMachine.ServiceEvents;
  Assert.AreEqual(0, FMachine.NumThreads);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptMachine);

end.
