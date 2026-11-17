{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Quake III host library (the system calls of   }
{  qagame, cgame and ui, DUnitX)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Q3Host;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.BotAi.Import.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Models.Q3Player.TokenReader in '..\Framework\Models\DelphiDoom.Models.Q3Player.TokenReader.pas',
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask in '..\IdTech4\Decl\DelphiDoom.Decl.Q3Shader.Calc.FloatMask.pas',
  DelphiDoom.Wad.Types in '..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Source.Zip in '..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Qvm.Types in '..\IdTech4\Qvm\DelphiDoom.Qvm.Types.pas',
  DelphiDoom.Qvm.Opcodes in '..\IdTech4\Qvm\DelphiDoom.Qvm.Opcodes.pas',
  DelphiDoom.Qvm.Intf in '..\IdTech4\Qvm\DelphiDoom.Qvm.Intf.pas',
  DelphiDoom.Qvm.Image in '..\IdTech4\Qvm\DelphiDoom.Qvm.Image.pas',
  DelphiDoom.Qvm.Code in '..\IdTech4\Qvm\DelphiDoom.Qvm.Code.pas',
  DelphiDoom.Qvm.Memory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Memory.pas',
  DelphiDoom.Qvm.Symbols in '..\IdTech4\Qvm\DelphiDoom.Qvm.Symbols.pas',
  DelphiDoom.Qvm.FloatMath in '..\IdTech4\Qvm\DelphiDoom.Qvm.FloatMath.pas',
  DelphiDoom.Qvm.Interpreter in '..\IdTech4\Qvm\DelphiDoom.Qvm.Interpreter.pas',
  DelphiDoom.Qvm.Machine in '..\IdTech4\Qvm\DelphiDoom.Qvm.Machine.pas',
  DelphiDoom.Qvm.Manager in '..\IdTech4\Qvm\DelphiDoom.Qvm.Manager.pas',
  DelphiDoom.Qvm.Factory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Factory.pas',
  DelphiDoom.Q3Host.Types in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Types.pas',
  DelphiDoom.Q3Host.Opcodes in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Opcodes.pas',
  DelphiDoom.Q3Host.OpcodeTables in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeTables.pas',
  DelphiDoom.Q3Host.OpcodeCatalog in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeCatalog.pas',
  DelphiDoom.Q3Host.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Intf.pas',
  DelphiDoom.Q3Host.Arguments in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Arguments.pas',
  DelphiDoom.Q3Host.SyscallHost in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.SyscallHost.pas',
  DelphiDoom.Q3Host.CommonSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CommonSyscalls.pas',
  DelphiDoom.Q3Host.Services.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Services.Intf.pas',
  DelphiDoom.Q3Host.CvarSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CvarSyscalls.pas',
  DelphiDoom.Q3Host.FileSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.FileSyscalls.pas',
  DelphiDoom.Q3Host.GameFiles in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameFiles.pas',
  DelphiDoom.Q3Host.ClipMap in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClipMap.pas',
  DelphiDoom.Q3Host.MapLoader in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.MapLoader.pas',
  DelphiDoom.Q3Host.TraceMemory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.TraceMemory.pas',
  DelphiDoom.Q3Host.EntityTokens in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.EntityTokens.pas',
  DelphiDoom.Q3Host.CollisionSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CollisionSyscalls.pas',
  DelphiDoom.Q3Host.ServerState in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ServerState.pas',
  DelphiDoom.Q3Host.GameWorld in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameWorld.pas',
  DelphiDoom.Q3Host.GameSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameSyscalls.pas',
  DelphiDoom.Q3Host.MiscSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.MiscSyscalls.pas',
  DelphiDoom.Q3Host.Bot.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Intf.pas',
  DelphiDoom.Q3Host.Bot.Memory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Memory.pas',
  DelphiDoom.Q3Host.Bot.Import in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Import.pas',
  DelphiDoom.Q3Host.Bot.Files in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Files.pas',
  DelphiDoom.Q3Host.Bot.EntitySource in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.EntitySource.pas',
  DelphiDoom.Q3Host.Bot.Bsp in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Bsp.pas',
  DelphiDoom.Q3Host.Bot.Aas in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Aas.pas',
  DelphiDoom.Q3Host.Bot.NullRouter in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.NullRouter.pas',
  DelphiDoom.Q3Host.Bot.Botlib in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Botlib.pas',
  DelphiDoom.Q3Host.Bot.Server in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Server.pas',
  DelphiDoom.Q3Host.Bot.Registrar in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Registrar.pas',
  DelphiDoom.Q3Host.Bot.CoreSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.CoreSyscalls.pas',
  DelphiDoom.Q3Host.Bot.AasSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.AasSyscalls.pas',
  DelphiDoom.Q3Host.Bot.EaSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.EaSyscalls.pas',
  DelphiDoom.Q3Host.Bot.ChatSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.ChatSyscalls.pas',
  DelphiDoom.Q3Host.Bot.GoalSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.GoalSyscalls.pas',
  DelphiDoom.Q3Host.Bot.MoveSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.MoveSyscalls.pas',
  DelphiDoom.Q3Host.Bot.Factory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Bot.Factory.pas',
  DelphiDoom.Q3Host.Client.Types in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Types.pas',
  DelphiDoom.Q3Host.Client.KeyNames in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.KeyNames.pas',
  DelphiDoom.Q3Host.Client.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Intf.pas',
  DelphiDoom.Q3Host.ClientState in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientState.pas',
  DelphiDoom.Q3Host.ClientMessageSink in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientMessageSink.pas',
  DelphiDoom.Q3Host.ServerSnapshots in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ServerSnapshots.pas',
  DelphiDoom.Q3Host.Server.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Server.Intf.pas',
  DelphiDoom.Q3Host.Server in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Server.pas',
  DelphiDoom.Q3Host.ClientPacketWriter in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientPacketWriter.pas',
  DelphiDoom.Q3Host.NetTransportAdapter in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.NetTransportAdapter.pas',
  DelphiDoom.Q3Host.ServerNetwork in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ServerNetwork.pas',
  DelphiDoom.Q3Host.ClientNetwork in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientNetwork.pas',
  DelphiDoom.Net.Q3.HashKey in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.HashKey.pas',
  DelphiDoom.Net.Q3.PacketCrypt in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.PacketCrypt.pas',
  DelphiDoom.Net.LoopbackTransport in '..\Framework\NetTransport\DelphiDoom.Net.LoopbackTransport.pas',
  DelphiDoom.Q3Host.ClientKeys in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientKeys.pas',
  DelphiDoom.Q3Host.UiNetAddress in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.UiNetAddress.pas',
  DelphiDoom.Q3Host.UiLanServers in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.UiLanServers.pas',
  DelphiDoom.Q3Host.ClientCdKey in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientCdKey.pas',
  DelphiDoom.Q3Host.ClientRecordingRenderer in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientRecordingRenderer.pas',
  DelphiDoom.Q3Host.ClientSoundAdapter in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientSoundAdapter.pas',
  DelphiDoom.Q3Host.ClientRoqCinematics in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientRoqCinematics.pas',
  DelphiDoom.Q3Host.ClientMathSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientMathSyscalls.pas',
  DelphiDoom.Q3Host.ClientScriptFiles in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientScriptFiles.pas',
  DelphiDoom.Q3Host.ClientScriptLog in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientScriptLog.pas',
  DelphiDoom.Q3Host.ClientStateSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientStateSyscalls.pas',
  DelphiDoom.Q3Host.ClientKeySyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientKeySyscalls.pas',
  DelphiDoom.Q3Host.ClientSoundSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientSoundSyscalls.pas',
  DelphiDoom.Q3Host.ClientCinematicSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientCinematicSyscalls.pas',
  DelphiDoom.Q3Host.ClientRendererSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientRendererSyscalls.pas',
  DelphiDoom.Q3Host.ClientPrecompilerSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientPrecompilerSyscalls.pas',
  DelphiDoom.Q3Host.UiLanSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.UiLanSyscalls.pas',
  DelphiDoom.Q3Host.UiCdKeySyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.UiCdKeySyscalls.pas',
  DelphiDoom.Q3Host.Client.Services in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Services.pas',
  DelphiDoom.Q3Host.Factory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Factory.pas',
  DelphiDoom.Tests.Shared.Fnv in 'Source\DelphiDoom.Tests.Shared.Fnv.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Qvm.Assembler in 'Source\DelphiDoom.Tests.Qvm.Assembler.pas',
  DelphiDoom.Tests.Qvm.Support in 'Source\DelphiDoom.Tests.Qvm.Support.pas',
  DelphiDoom.Tests.Qvm.Programs in 'Source\DelphiDoom.Tests.Qvm.Programs.pas',
  DelphiDoom.Tests.Q3Host.Support in 'Source\DelphiDoom.Tests.Q3Host.Support.pas',
  DelphiDoom.Tests.Q3Host.Catalog in 'Source\DelphiDoom.Tests.Q3Host.Catalog.pas',
  DelphiDoom.Tests.Q3Host.Math in 'Source\DelphiDoom.Tests.Q3Host.Math.pas',
  DelphiDoom.Tests.Q3Host.Host in 'Source\DelphiDoom.Tests.Q3Host.Host.pas',
  DelphiDoom.Tests.Q3Host.Init in 'Source\DelphiDoom.Tests.Q3Host.Init.pas',
  DelphiDoom.Tests.Q3Host.Services in 'Source\DelphiDoom.Tests.Q3Host.Services.pas',
  DelphiDoom.Tests.Q3Host.Layout in 'Source\DelphiDoom.Tests.Q3Host.Layout.pas',
  DelphiDoom.Tests.Q3Host.Cvars in 'Source\DelphiDoom.Tests.Q3Host.Cvars.pas',
  DelphiDoom.Tests.Q3Host.Files in 'Source\DelphiDoom.Tests.Q3Host.Files.pas',
  DelphiDoom.Tests.Q3Host.GameWorld in 'Source\DelphiDoom.Tests.Q3Host.GameWorld.pas',
  DelphiDoom.Tests.Q3Host.BotLayout in 'Source\DelphiDoom.Tests.Q3Host.BotLayout.pas',
  DelphiDoom.Tests.Q3Host.BotCalls in 'Source\DelphiDoom.Tests.Q3Host.BotCalls.pas',
  DelphiDoom.Tests.Q3Host.BotReach in 'Source\DelphiDoom.Tests.Q3Host.BotReach.pas',
  DelphiDoom.Tests.Q3Host.Reach in 'Source\DelphiDoom.Tests.Q3Host.Reach.pas',
  DelphiDoom.Tests.Q3Host.Coverage in 'Source\DelphiDoom.Tests.Q3Host.Coverage.pas',
  DelphiDoom.Tests.Q3Host.ClientSupport in 'Source\DelphiDoom.Tests.Q3Host.ClientSupport.pas',
  DelphiDoom.Tests.Q3Host.ClientState in 'Source\DelphiDoom.Tests.Q3Host.ClientState.pas',
  DelphiDoom.Tests.Q3Host.ClientKeys in 'Source\DelphiDoom.Tests.Q3Host.ClientKeys.pas',
  DelphiDoom.Tests.Q3Host.ClientLan in 'Source\DelphiDoom.Tests.Q3Host.ClientLan.pas',
  DelphiDoom.Tests.Q3Host.ClientServices in 'Source\DelphiDoom.Tests.Q3Host.ClientServices.pas',
  DelphiDoom.Tests.Audio.Q3.Fakes in 'Source\DelphiDoom.Tests.Audio.Q3.Fakes.pas',
  DelphiDoom.Tests.Q3Host.ClientSound in 'Source\DelphiDoom.Tests.Q3Host.ClientSound.pas',
  DelphiDoom.Tests.Q3Host.ClientRoq in 'Source\DelphiDoom.Tests.Q3Host.ClientRoq.pas',
  DelphiDoom.Tests.Q3Host.ClientReach in 'Source\DelphiDoom.Tests.Q3Host.ClientReach.pas',
  DelphiDoom.Tests.Q3Host.LoopRig in 'Source\DelphiDoom.Tests.Q3Host.LoopRig.pas',
  DelphiDoom.Tests.Q3Host.LocalLoop in 'Source\DelphiDoom.Tests.Q3Host.LocalLoop.pas',
  DelphiDoom.Tests.Q3Host.NetworkLoop in 'Source\DelphiDoom.Tests.Q3Host.NetworkLoop.pas',
  DelphiDoom.Tests.Q3Host.ClientMessageSink in 'Source\DelphiDoom.Tests.Q3Host.ClientMessageSink.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
