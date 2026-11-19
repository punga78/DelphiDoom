{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - what the executable does                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Application;

interface

uses
  System.SysUtils, DelphiDoom.Quake3.Clock.Intf;

type
  /// <summary>
  ///   Quake3Server.exe without the process around it: parse the command line, assemble the server, run it and
  ///   give the exit code. The clock and the writer come from outside so that a test runs it on a manual clock
  /// </summary>
  TQ3Application = class sealed
  public
    /// <summary>Exit codes in DelphiDoom.Quake3.Types (Q3_EXIT_*)</summary>
    class function Run(const AArguments: array of string; const AClock: IQ3Clock;
      const AWriter: TProc<string>): Integer; static;
  end;

implementation

uses
  DelphiDoom.Quake3.Types, DelphiDoom.Quake3.CommandLine, DelphiDoom.Quake3.Factory, DelphiDoom.Quake3.DedicatedServer;

{ TQ3Application }

class function TQ3Application.Run(const AArguments: array of string; const AClock: IQ3Clock;
  const AWriter: TProc<string>): Integer;
var
  LOptions: TQ3ProgramOptions;
  LError, LLine: string;
  LServer: TQ3DedicatedServer;
begin
  if not TQ3CommandLine.Parse(AArguments, LOptions, LError) then
  begin
    AWriter(LError + #10#10);
    for LLine in TQ3CommandLine.Usage do
      AWriter(LLine + #10);
    Exit(Q3_EXIT_USAGE);
  end;
  if LOptions.Help then
  begin
    for LLine in TQ3CommandLine.Usage do
      AWriter(LLine + #10);
    Exit(Q3_EXIT_OK);
  end;
  try
    LServer := TQuake3Factory.CreateDedicatedServer(LOptions, AClock, AWriter);
  except
    on E: Exception do
    begin
      AWriter('Fatal: ' + E.Message + #10);
      Exit(Q3_EXIT_FAILURE);
    end;
  end;
  try
    Result := LServer.Run;
  finally
    LServer.Free;
  end;
end;

end.
