{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the composition root                        }
{                                                                              }
{  The one place that knows the concrete classes of the dedicated server:      }
{  the console, the file system on the paks, the host of qagame with the       }
{  botlib, the server in memory, the network on a wire in memory, the client   }
{  without a screen and the main loop.                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Quake3.Clock.Intf, DelphiDoom.Quake3.Types, DelphiDoom.Quake3.DedicatedServer;

type
  /// <summary>Assembles a dedicated server of Quake III from the command line, a clock and a place to write to</summary>
  TQuake3Factory = class sealed
  public
    /// <summary>
    ///   The "set" lines of the command line run first (Com_StartupVariable: the latched variables like g_gametype
    ///   and sv_maxclients take the value from the start, fs_basepath and fs_game say where the paks are); then the
    ///   file system, the server and the rest are made, and the other lines wait in the command buffer. Raises
    ///   EQ3ProgramException when the folder of the game is not there
    /// </summary>
    class function CreateDedicatedServer(const AOptions: TQ3ProgramOptions; const AClock: IQ3Clock;
      const AWriter: TProc<string>): TQ3DedicatedServer; static;
  end;

implementation

uses
  System.IOUtils, System.Math, DelphiDoom.Net.LoopbackTransport, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Factory,
  DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Console.Q3.UnhandledCommands, DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.SourceHandles,
  DelphiDoom.Scanner.Q3.ScriptLoader, DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.Factory,
  DelphiDoom.Net.Q3.ConsoleInfoWriter, DelphiDoom.Qvm.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.ClientScriptFiles, DelphiDoom.Q3Host.Server, DelphiDoom.Q3Host.ServerNetwork,
  DelphiDoom.Quake3.ConsoleOutput, DelphiDoom.Quake3.CommandLine, DelphiDoom.Quake3.BotCvars,
  DelphiDoom.Quake3.Calendar, DelphiDoom.Quake3.HostTime, DelphiDoom.Quake3.ServerCommands,
  DelphiDoom.Quake3.DummyClient, DelphiDoom.Quake3.DedicatedLoop;

resourcestring
  SNoBasePath = 'The folder fs_basepath "%s" does not exist';

const
  // the protocol that the server and the client of this process speak (Quake III 1.32)
  PROTOCOL_VERSION = 68;

{ TQuake3Factory }

class function TQuake3Factory.CreateDedicatedServer(const AOptions: TQ3ProgramOptions; const AClock: IQ3Clock;
  const AWriter: TProc<string>): TQ3DedicatedServer;
var
  LServer: TQ3DedicatedServer;
  LOutput: TQ3ConsoleOutput;
  LUnhandled: IQ3UnhandledCommands;
  LCoder: IQ3HuffmanCoder;
  LFsSettings: TGameFsSettings;
  LSettings: TQ3ServerSettings;
  LLines: TArray<AnsiString>;
  LLine: AnsiString;
  LBasePath, LGame: string;
  LCount: Integer;
begin
  LServer := TQ3DedicatedServer.Create;
  try
    LOutput := TQ3ConsoleOutput.Create(AWriter);
    // the interface keeps the output alive; every other holder takes its own reference
    LServer.Parts.Print := LOutput;

    // Cmd_ExecuteString ends here for a line that is not a command: the game of the server may take it ("addbot")
    LUnhandled := TQ3UnhandledCommands.Create(nil,
      function: Boolean
      begin
        Result := Assigned(LServer.Parts.Server) and LServer.Parts.Server.IsRunning;
      end,
      nil,
      function: Boolean
      begin
        Result := Assigned(LServer.Parts.Server.Game) and (LServer.Parts.Server.Game.Call(GAME_CONSOLE_COMMAND, []) <> 0);
      end,
      nil, nil);
    LServer.Parts.Console := TQ3Console.Create(LOutput, nil, LUnhandled, TQ3ConsoleInfoWriter.Create);
    LServer.Parts.Console.Init;
    TQ3BotCvars.Register(LServer.Parts.Console.CVars);

    // Com_StartupVariable: the set lines run before the server makes its variables
    LCount := 0;
    SetLength(LLines, Length(AOptions.Commands));
    for LLine in AOptions.Commands do
      if TQ3CommandLine.IsSetCommand(LLine) then
        LServer.Parts.Console.Commands.ExecuteString(LLine)
      else
      begin
        LLines[LCount] := LLine;
        Inc(LCount);
      end;
    SetLength(LLines, LCount);
    LServer.Parts.StartupLines := LLines;

    // FS_InitFilesystem
    LBasePath := string(LServer.Parts.Console.CVars.VariableString('fs_basepath'));
    if LBasePath = '' then
      LBasePath := GetCurrentDir;
    if not TDirectory.Exists(LBasePath) then
      raise EQ3ProgramException.CreateFmt(SNoBasePath, [LBasePath]);
    LGame := string(LServer.Parts.Console.CVars.VariableString('fs_game'));
    if LGame = '' then
      LGame := 'baseoa';
    LFsSettings := Default(TGameFsSettings);
    LFsSettings.BasePath := LBasePath;
    LFsSettings.SavePath := string(LServer.Parts.Console.CVars.VariableString('fs_homepath'));
    if LFsSettings.SavePath = '' then
      LFsSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'Quake3Server');
    LFsSettings.GameBase := 'baseoa';
    LFsSettings.Game := LGame;
    LFsSettings.PakExtension := '.pk3';
    LServer.Parts.Files := TGameFileSystemFactory.CreateOnDisk(LFsSettings);
    LServer.Parts.Files.Startup;

    // the precompiler of the botlib reads its scripts from the paks
    LServer.Parts.Globals := TQ3GlobalDefines.Create;
    LServer.Parts.Sources := TQ3SourceHandles.Create(
      TQ3ScriptLoader.Create(TQ3HostScriptFiles.Create(LServer.Parts.Files), nil), nil, LServer.Parts.Globals);

    LCoder := TQ3NetFactory.CreateMessageHuffman;

    // SV_Init: the server and the host of qagame
    LSettings := Default(TQ3ServerSettings);
    LSettings.Files := LServer.Parts.Files;
    LSettings.Console := LServer.Parts.Console;
    LSettings.Print := LOutput;
    LSettings.Calendar := TQ3SystemCalendar.Create;
    LSettings.Time := TQ3ClockHostTime.Create(AClock);
    LSettings.Limits := TQvmLimits.Default;
    // OpenArena runs on ioquake3: the qagame of a bot copies a literal that does not start on a dword
    LSettings.Limits.UnalignedBlockCopy := True;
    LSettings.Sources := LServer.Parts.Sources;
    LSettings.Protocol := PROTOCOL_VERSION;
    LSettings.ClientRunning := not AOptions.NoClient;
    LServer.Parts.Server := TQ3Server.Create(LSettings);

    // the network of the process: the server on one end of a wire in memory, the client on the other
    if not AOptions.NoClient then
    begin
      LServer.Parts.Wire := TNetLoopbackPair.Create;
      LServer.Parts.ServerNetwork := TQ3ServerNetwork.Create(LServer.Parts.Server, LServer.Parts.Wire.Left,
        LServer.Parts.Console.Arguments, LCoder, True);
      LServer.Parts.ServerNetworkIntf := LServer.Parts.ServerNetwork;
      LServer.Parts.Server.SetOutput(LServer.Parts.ServerNetworkIntf);
      LServer.Parts.Dummy := TQ3DummyClient.Create(LServer.Parts.Server, LServer.Parts.Wire.Right,
        LServer.Parts.Console.Arguments, LCoder);
    end;

    LServer.Parts.Commands := TQ3ServerCommands.Create(LServer.Parts.Console.Commands,
      LServer.Parts.Console.Arguments, LServer.Parts.Console.CVars, LServer.Parts.Server, LOutput,
      procedure
      begin
        if Assigned(LServer.Parts.Loop) then
          LServer.Parts.Loop.Quit;
      end);

    // Com_Frame: the network of the client, the packets of the server, SV_Frame, the packets for the client
    LServer.Parts.Loop := TQ3DedicatedLoop.Create(AClock, LServer.Parts.Console.Buffer, LOutput,
      function: Integer
      begin
        // SV_FrameMsec
        Result := 1000 div Max(1, LServer.Parts.Console.CVars.VariableIntegerValue('sv_fps'));
      end, AOptions.Frames);
    if Assigned(LServer.Parts.Dummy) then
      LServer.Parts.Loop.AddStage(
        procedure(AMilliseconds: Integer)
        begin
          LServer.Parts.Dummy.SendFrame;
        end);
    if Assigned(LServer.Parts.ServerNetwork) then
      LServer.Parts.Loop.AddStage(
        procedure(AMilliseconds: Integer)
        begin
          LServer.Parts.ServerNetwork.Poll;
        end);
    LServer.Parts.Loop.AddStage(
      procedure(AMilliseconds: Integer)
      begin
        LServer.Parts.Server.Frame(AMilliseconds);
      end);
    if Assigned(LServer.Parts.Dummy) then
      LServer.Parts.Loop.AddStage(
        procedure(AMilliseconds: Integer)
        begin
          LServer.Parts.Dummy.ReceiveFrame;
        end);

    // Com_AddStartupCommands: the commands of the command line run in the first frame
    for LLine in LServer.Parts.StartupLines do
      LServer.Parts.Console.Buffer.AddText(LLine + #10);
  except
    LServer.Free;
    raise;
  end;
  Result := LServer;
end;

end.
