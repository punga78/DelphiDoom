{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III Arena / OpenArena dedicated server, console only      }
{  (no window, no renderer, no sound, no socket: the client of the process     }
{  speaks to the server on a wire in memory)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Quake3Server;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Clock.Factory,
  DelphiDoom.Quake3.Types,
  DelphiDoom.Quake3.Clock.Intf,
  DelphiDoom.Quake3.Clock.Adapter,
  DelphiDoom.Quake3.Application;

var
  LArguments: TArray<string>;
  LIndex: Integer;
  LTimer: ITimerResolutionLease;
begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  SetLength(LArguments, ParamCount);
  for LIndex := 1 to ParamCount do
    LArguments[LIndex - 1] := ParamStr(LIndex);
  // a timer of 1 ms, so that the loop wakes up close to when a frame of the server is due
  LTimer := TClockFactory.AcquireTimerResolution(1);
  try
    ExitCode := TQ3Application.Run(LArguments, TQ3ClockAdapter.Create(TClockFactory.CreateClock(nil)),
      procedure(AText: string)
      begin
        Write(AText);
      end);
  except
    on E: Exception do
    begin
      Writeln('Fatal: ', E.ClassName, ': ', E.Message);
      ExitCode := Q3_EXIT_FAILURE;
    end;
  end;
  LTimer := nil;
end.
