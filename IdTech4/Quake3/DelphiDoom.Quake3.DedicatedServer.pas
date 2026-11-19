{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the dedicated server as a whole             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.DedicatedServer;

interface

uses
  System.SysUtils, DelphiDoom.Net.LoopbackTransport, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Scanner.Q3.GlobalDefines, DelphiDoom.Scanner.Q3.SourceHandles, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Server, DelphiDoom.Q3Host.Server.Intf, DelphiDoom.Q3Host.ServerNetwork,
  DelphiDoom.Quake3.DummyClient, DelphiDoom.Quake3.ServerCommands, DelphiDoom.Quake3.DedicatedLoop,
  DelphiDoom.Quake3.Types;

type
  /// <summary>
  ///   The pieces of a server that TQ3DedicatedServer owns and frees in the order that works. The factory fills
  ///   them one by one (a piece that is still nil when something fails is simply not freed)
  /// </summary>
  TQ3DedicatedParts = record
    Console: TQ3Console;
    Print: IQ3HostConsole;
    Files: IGameFileSystem;
    Globals: TQ3GlobalDefines;
    Sources: TQ3SourceHandles;
    Server: TQ3Server;
    Wire: TNetLoopbackPair;
    ServerNetwork: TQ3ServerNetwork;
    ServerNetworkIntf: IQ3ServerOutput;
    Dummy: TQ3DummyClient;
    Commands: TQ3ServerCommands;
    Loop: TQ3DedicatedLoop;
    /// <summary>The lines of the command line that run in the buffer (the "set" lines already ran)</summary>
    StartupLines: TArray<AnsiString>;
  end;

  /// <summary>
  ///   A dedicated server of Quake III in this process, assembled by TQuake3Factory: Run executes the main loop
  ///   and turns what stops it into the exit code of the program
  /// </summary>
  TQ3DedicatedServer = class
  public
    /// <summary>Filled by the factory; the owner of everything in it is this object</summary>
    Parts: TQ3DedicatedParts;
    destructor Destroy; override;
    /// <summary>
    ///   Runs the loop to its end and says how it ended: Q3_EXIT_OK (the frames were done or "quit" ran),
    ///   Q3_EXIT_COM_ERROR, Q3_EXIT_UNSERVED_TRAP or Q3_EXIT_FAILURE (a map that is not there is one); the
    ///   reason goes to the console
    /// </summary>
    function Run: Integer;
  end;

implementation

uses
  DelphiDoom.Q3Host.Types, DelphiDoom.Qvm.Types;

resourcestring
  SComError = 'Com_Error: %s';
  SUnservedTrap = 'Fatal: %s';
  SVmFault = 'Fatal: the virtual machine stopped: %s';
  SFailure = 'Fatal: %s: %s';

{ TQ3DedicatedServer }

destructor TQ3DedicatedServer.Destroy;
begin
  // the server lets go of its output before the output goes
  if Assigned(Parts.Server) then
    Parts.Server.SetOutput(nil);
  Parts.Dummy.Free;
  Parts.ServerNetworkIntf := nil;
  Parts.ServerNetwork := nil;
  Parts.Wire.Free;
  Parts.Loop.Free;
  Parts.Commands.Free;
  Parts.Server.Free;
  Parts.Sources.Free;
  Parts.Globals.Free;
  if Assigned(Parts.Files) then
    Parts.Files.Shutdown;
  Parts.Files := nil;
  Parts.Console.Free;
  inherited Destroy;
end;

function TQ3DedicatedServer.Run: Integer;
begin
  Result := Q3_EXIT_OK;
  try
    Parts.Loop.Run;
    if Assigned(Parts.Commands) and Parts.Commands.MapFailed then
      Result := Q3_EXIT_FAILURE;
  except
    on E: EQ3ModuleErrorException do
    begin
      Parts.Print.Print(AnsiString(Format(SComError, [Trim(E.Message)]) + #10));
      Result := Q3_EXIT_COM_ERROR;
    end;
    on E: EQ3UnhandledSyscallException do
    begin
      Parts.Print.Print(AnsiString(Format(SUnservedTrap, [Trim(E.Message)]) + #10));
      Result := Q3_EXIT_UNSERVED_TRAP;
    end;
    on E: EQ3UnknownSyscallException do
    begin
      Parts.Print.Print(AnsiString(Format(SUnservedTrap, [Trim(E.Message)]) + #10));
      Result := Q3_EXIT_UNSERVED_TRAP;
    end;
    on E: EQvmException do
    begin
      Parts.Print.Print(AnsiString(Format(SVmFault, [Trim(E.Message)]) + #10));
      Result := Q3_EXIT_FAILURE;
    end;
    on E: Exception do
    begin
      Parts.Print.Print(AnsiString(Format(SFailure, [E.ClassName, Trim(E.Message)]) + #10));
      Result := Q3_EXIT_FAILURE;
    end;
  end;
end;

end.
