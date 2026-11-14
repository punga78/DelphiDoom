{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptFactory      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptFactory = class
  public
    [Test]
    procedure DovrebbeRifiutareUnaMacchinaSenzaHost;
    [Test]
    procedure DovrebbeDichiarareLeClassiDiBaseEGliEventiDeiThread;
    [Test]
    procedure DovrebbeFunzionareSenzaMondoSenzaLogESenzaFile;
    [Test]
    procedure DovrebbeDareMacchineIndipendenti;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Intf,
  DelphiDoom.DoomScript.ClassInfo, DelphiDoom.DoomScript.Machine, DelphiDoom.DoomScript.Factory,
  DelphiDoom.Tests.DoomScript.Fakes, DelphiDoom.Tests.DoomScript.Rig, DelphiDoom.Tests.DoomScript.Support;

procedure TTestDoomScriptFactory.DovrebbeRifiutareUnaMacchinaSenzaHost;
begin
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptFactory.CreateMachine(nil, nil, nil, nil);
    end, EDoomScriptError, 'TDoomScriptFactory: a script machine needs a host');
end;

procedure TTestDoomScriptFactory.DovrebbeDichiarareLeClassiDiBaseEGliEventiDeiThread;
var
  LHost: IDoomScriptHost;
  LMachine: TDoomScriptMachine;
  LRoot: TDoomScriptClassInfo;
  LThreads: TDoomScriptClassInfo;
begin
  LHost := TDoomScriptFakeHost.Create;
  LMachine := TDoomScriptFactory.CreateMachine(LHost, nil, nil, nil);
  try
    LRoot := LMachine.Classes.GetClass('idClass');
    LThreads := LMachine.Classes.GetClass('idThread');
    Assert.IsNotNull(LRoot);
    Assert.IsNotNull(LThreads);
    Assert.AreSame(LRoot, LThreads.Super);
    Assert.AreSame(LThreads, LMachine.Context.ThreadClass);
    Assert.IsNull(LMachine.Classes.GetClass('idEntity'), 'the classes of the game are of the host');
    Assert.IsNotNull(LMachine.Events.FindEvent('waitFrame'));
    Assert.IsNotNull(LMachine.Events.FindEvent('<execute>'));
    Assert.AreSame(LMachine.Context.EvExecute, LMachine.Events.FindEvent('<execute>'));
    Assert.AreSame(LMachine.Context.EvRemove, LMachine.Events.FindEvent('<immediateremove>'));
    Assert.AreSame(LMachine.Context.EvSetCallback, LMachine.Events.FindEvent('<script_setcallback>'));
    Assert.IsTrue(LThreads.RespondsTo(LMachine.SysEvents.Wait));
    Assert.IsFalse(LRoot.RespondsTo(LMachine.SysEvents.Wait));
    Assert.AreSame(LMachine.Context.ScriptProgram, LMachine.ScriptProgram);
    Assert.AreSame(LMachine.Context.Queue, LMachine.Queue);
    Assert.AreSame(LMachine.Context.Entities, LMachine.Entities);
    Assert.AreEqual(0, LMachine.NumThreads);
  finally
    LMachine.Free;
  end;
end;

procedure TTestDoomScriptFactory.DovrebbeFunzionareSenzaMondoSenzaLogESenzaFile;
var
  LHost: IDoomScriptHost;
  LMachine: TDoomScriptMachine;
begin
  LHost := TDoomScriptFakeHost.Create;
  LMachine := TDoomScriptFactory.CreateMachine(LHost, nil, nil, nil);
  try
    LMachine.ScriptProgram.BeginCompilation;
    // without a file system there is no default script to include (an error of the parser, as in the game)
    // and no file to compile
    TDoomScriptTestSupport.ExpectClass(
      procedure
      begin
        LMachine.ScriptProgram.CompileText('x', 'float a;'#10, False);
      end, EIdLexerException);
    TDoomScriptTestSupport.ExpectClass(
      procedure
      begin
        LMachine.ScriptProgram.CompileFile('script/x.script');
      end, EDoomScriptError);
    // nothing is printed and nothing fails without a log
    LMachine.CreateThread.DisplayInfo;
    LMachine.ScriptProgram.Disassemble;
  finally
    LMachine.Free;
  end;
end;

procedure TTestDoomScriptFactory.DovrebbeDareMacchineIndipendenti;
var
  LFirst: TDoomScriptTestRig;
  LSecond: TDoomScriptTestRig;
begin
  // no global state: two machines do not see each other's programs, threads and events
  LFirst := TDoomScriptTestRig.Create;
  LSecond := TDoomScriptTestRig.Create;
  try
    LFirst.Compile('void only_first() { sys.pause(); }'#10);
    LSecond.Compile('void only_second() { }'#10);
    Assert.IsNull(LSecond.Machine.ScriptProgram.FindFunction('only_first'));
    Assert.IsNull(LFirst.Machine.ScriptProgram.FindFunction('only_second'));
    LFirst.Run('only_first');
    Assert.AreEqual(1, LFirst.Machine.NumThreads);
    Assert.AreEqual(0, LSecond.Machine.NumThreads);
    Assert.AreEqual(1, LSecond.Machine.CreateThread.ThreadNum);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptFactory);

end.
