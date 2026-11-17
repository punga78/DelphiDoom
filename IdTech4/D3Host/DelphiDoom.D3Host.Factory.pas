{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - factory (composition of idCommon)         }
{                                                                              }
{  Written for this repository; it assembles the classes ported from           }
{  framework\Common.cpp and EventLoop.cpp of Doom 3 (id Software).             }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is available under the GNU General Public License, version 3 or   }
{  (at your option) any later version, with the additional terms of the        }
{  Doom 3 Source Code License (Reference\doom3\COPYING.txt).                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Factory;

interface

uses
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Common;

type
  /// <summary>What the program gives to idCommon: every system it uses, as a small interface</summary>
  TD3HostServices = record
    CVars: ID3CommonCVars;
    Settings: ID3CommonSettings;
    System: ID3CommonSystem;
    Console: ID3CommonConsole;
    Session: ID3CommonSession;
    Render: ID3CommonRenderState;
    Files: ID3CommonFileSystem;
    Calendar: ID3CommonCalendar;
    Lifecycle: ID3CommonLifecycle;
    /// <summary>The command buffer (Framework\Console, profile id Tech 4)</summary>
    Buffer: ICmdBuffer;
    Keys: ID3KeyTracker;
    Events: ID3EventSource;
    Journal: ID3JournalSettings;
  end;

  TD3HostFactory = class
  public
    /// <summary>Builds the printer, the warnings, the errors, the command line and the event loop, wired together</summary>
    class function CreateCommon(const AServices: TD3HostServices): TD3CommonHost; static;
  end;

implementation

uses
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Printer, DelphiDoom.D3Host.Diagnostics, DelphiDoom.D3Host.ErrorHandler,
  DelphiDoom.D3Host.CommandLine, DelphiDoom.D3Host.EventLoop;

class function TD3HostFactory.CreateCommon(const AServices: TD3HostServices): TD3CommonHost;
var
  LState: TD3CommonState;
  LPrinter: TD3Printer;
  LPrinterRef: ID3Printer;
  LDiagnostics: TD3Diagnostics;
  LErrors: TD3ErrorHandler;
  LErrorsRef: ID3FatalErrorSink;
  LCommandLine: TD3CommandLine;
  LCommandLineRef: ID3StartupVariables;
  LEventLoop: TD3EventLoop;
begin
  LState := TD3CommonState.Create;
  LPrinter := TD3Printer.Create(LState, AServices.CVars, AServices.Settings, AServices.System, AServices.Console,
    AServices.Session, AServices.Files, AServices.Calendar);
  LPrinterRef := LPrinter;
  LDiagnostics := TD3Diagnostics.Create(LPrinterRef, AServices.Files, AServices.Settings);
  LErrors := TD3ErrorHandler.Create(LState, AServices.CVars, AServices.System, AServices.Session, AServices.Render,
    AServices.Buffer, AServices.Lifecycle, LPrinterRef, LDiagnostics);
  LErrorsRef := LErrors;
  LPrinter.SetFatalErrorSink(LErrorsRef);
  LCommandLine := TD3CommandLine.Create(AServices.CVars, AServices.Buffer, LState);
  LCommandLineRef := LCommandLine;
  LEventLoop := TD3EventLoop.Create(AServices.Events, AServices.Session, AServices.Keys, AServices.Buffer,
    AServices.Files, AServices.System, LPrinterRef, LCommandLineRef, AServices.Journal, LErrorsRef);
  Result := TD3CommonHost.Create(LState, LPrinter, LDiagnostics, LErrors, LCommandLine, LEventLoop);
end;

end.
