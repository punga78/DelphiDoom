{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - Error and FatalError                      }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp (Error, FatalError).     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.ErrorHandler;

interface

uses
  System.SysUtils, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf,
  DelphiDoom.D3Host.Diagnostics;

type
  /// <summary>
  ///   idCommonLocal::Error and FatalError. The kind of an error (ERP_*) comes from: fs_copyfiles (fatal),
  ///   an OpenGL that is not running (fatal: a program without a renderer never drops), an error inside an
  ///   error (fatal; Quit if the first one was fatal too), more than 3 errors less than 100 ms one from the
  ///   other (fatal). A drop raises ED3HostException with the text and leaves ErrorEntered at 0. A fatal error
  ///   calls Shutdown and System.Error, which do not return in the engine.
  /// </summary>
  TD3ErrorHandler = class(TInterfacedObject, ID3FatalErrorSink, ID3ErrorReporter)
  strict private
    FState: TD3CommonState;
    FCVars: ID3CommonCVars;
    FSystem: ID3CommonSystem;
    FSession: ID3CommonSession;
    FRender: ID3CommonRenderState;
    FBuffer: ICmdBuffer;
    FLifecycle: ID3CommonLifecycle;
    FPrinter: ID3Printer;
    FDiagnostics: TD3Diagnostics;
    FErrorMessage: AnsiString;
    FLastErrorTime: Integer;
    FErrorCount: Integer;
    procedure LeaveForRestart;
  public
    constructor Create(const AState: TD3CommonState; const ACVars: ID3CommonCVars; const ASystem: ID3CommonSystem;
      const ASession: ID3CommonSession; const ARender: ID3CommonRenderState; const ABuffer: ICmdBuffer;
      const ALifecycle: ID3CommonLifecycle; const APrinter: ID3Printer; const ADiagnostics: TD3Diagnostics);
    /// <summary>idCommonLocal::Error (the diagnostics are owned by the caller)</summary>
    procedure Error(const AText: AnsiString);
    /// <summary>idCommonLocal::FatalError: dump out of the game to a system dialog</summary>
    procedure FatalError(const AText: AnsiString);
    /// <summary>The last message, errorMessage of the C++</summary>
    function ErrorMessage: AnsiString;
  end;

implementation

const
  SErrorBanner = '********************' + #10 + 'ERROR: %s' + #10 + '********************' + #10;
  SRecursedFatal = 'FATAL: recursed fatal error:' + #10 + '%s' + #10;
  SVidRestart = 'vid_restart partial windowed' + #10;

constructor TD3ErrorHandler.Create(const AState: TD3CommonState; const ACVars: ID3CommonCVars;
  const ASystem: ID3CommonSystem; const ASession: ID3CommonSession; const ARender: ID3CommonRenderState;
  const ABuffer: ICmdBuffer; const ALifecycle: ID3CommonLifecycle; const APrinter: ID3Printer;
  const ADiagnostics: TD3Diagnostics);
begin
  inherited Create;
  FState := AState;
  FCVars := ACVars;
  FSystem := ASystem;
  FSession := ASession;
  FRender := ARender;
  FBuffer := ABuffer;
  FLifecycle := ALifecycle;
  FPrinter := APrinter;
  FDiagnostics := ADiagnostics;
end;

function TD3ErrorHandler.ErrorMessage: AnsiString;
begin
  Result := FErrorMessage;
end;

procedure TD3ErrorHandler.LeaveForRestart;
begin
  if FCVars.GetCVarBool('r_fullscreen') then
    FBuffer.BufferCommandText(ceNow, SVidRestart);
end;

procedure TD3ErrorHandler.Error(const AText: AnsiString);
var
  LCode: Integer;
  LCurrentTime: Integer;
begin
  LCode := ERP_DROP;

  // always turn this off after an error
  FState.RefreshOnPrint := False;

  // when we are running automated scripts, make sure we know if anything failed
  if FCVars.GetCVarInteger('fs_copyfiles') <> 0 then
    LCode := ERP_FATAL;

  // if we don't have GL running, make it a fatal error
  if not FRender.IsOpenGLRunning then
    LCode := ERP_FATAL;

  // if we got a recursive error, make it fatal
  if FState.ErrorEntered <> 0 then
  begin
    // if we are recursively erroring while exiting from a fatal error, just kill the entire process
    if FState.ErrorEntered = ERP_FATAL then
      FSystem.Quit;
    LCode := ERP_FATAL;
  end;

  // if we are getting a solid stream of ERP_DROP, do an ERP_FATAL
  LCurrentTime := FSystem.Milliseconds;
  if LCurrentTime - FLastErrorTime < 100 then
  begin
    Inc(FErrorCount);
    if FErrorCount > 3 then
      LCode := ERP_FATAL;
  end
  else
    FErrorCount := 0;
  FLastErrorTime := LCurrentTime;

  FState.ErrorEntered := LCode;

  FErrorMessage := TD3MessageText.Limit(AText);

  // copy the error message to the clip board
  FSystem.SetClipboardData(FErrorMessage);

  // add the message to the error list
  FDiagnostics.AddError(FErrorMessage);

  // don't shut down the session for the gui editor or the debugger
  if (FState.Editors and (EDITOR_GUI or EDITOR_DEBUGGER)) = 0 then
    FSession.Stop;

  if LCode = ERP_DISCONNECT then
  begin
    FState.ErrorEntered := 0;
    raise ED3HostException.Create(string(FErrorMessage));
  end
  else if (FState.Editors and (EDITOR_GUI or EDITOR_DEBUGGER)) <> 0 then
  begin
    // the gui editor doesn't want things to com_error so it handles exceptions instead
    FState.ErrorEntered := 0;
    raise ED3HostException.Create(string(FErrorMessage));
  end
  else if LCode = ERP_DROP then
  begin
    FPrinter.Printf(AnsiString(Format(SErrorBanner, [string(FErrorMessage)])));
    FState.ErrorEntered := 0;
    raise ED3HostException.Create(string(FErrorMessage));
  end
  else
    FPrinter.Printf(AnsiString(Format(SErrorBanner, [string(FErrorMessage)])));

  LeaveForRestart;
  FLifecycle.Shutdown;
  FSystem.Error(FErrorMessage);
end;

procedure TD3ErrorHandler.FatalError(const AText: AnsiString);
begin
  // if we got a recursive error, make it fatal
  if FState.ErrorEntered <> 0 then
  begin
    FSystem.Printf(AnsiString(Format(SRecursedFatal, [string(FErrorMessage)])));
    FErrorMessage := TD3MessageText.Limit(AText);
    FSystem.Printf(FErrorMessage + #10);
    // write the console to a log file?
    FSystem.Quit;
    Exit;
  end;
  FState.ErrorEntered := ERP_FATAL;

  FErrorMessage := TD3MessageText.Limit(AText);

  LeaveForRestart;
  FSystem.SetFatalError(FErrorMessage);
  FLifecycle.Shutdown;
  FSystem.Error(FErrorMessage);
end;

end.
