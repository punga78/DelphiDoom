{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - printing (idCommonLocal::VPrintf)         }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp.                         }
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
unit DelphiDoom.D3Host.Printer;

interface

uses
  System.SysUtils, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf, DelphiDoom.D3Host.Lifecycle.Intf;

type
  /// <summary>BeginRedirect: what is called with the text when the buffer is full or ends</summary>
  TD3RedirectFlush = reference to procedure(const AText: AnsiString);

  /// <summary>
  ///   Printf, DPrintf, the redirection of the text to a buffer and the log file of idCommonLocal. Callers pass
  ///   a text that is already formatted (the C++ fmt and the varargs are not ported) and without NUL characters.
  ///   Print does nothing while the cvar system is not initialized.
  /// </summary>
  TD3Printer = class(TInterfacedObject, ID3Printer, ID3LogFileControl)
  strict private
    FState: TD3CommonState;
    FCVars: ID3CommonCVars;
    FSettings: ID3CommonSettings;
    FSystem: ID3CommonSystem;
    FConsole: ID3CommonConsole;
    FSession: ID3CommonSession;
    FFiles: ID3CommonFileSystem;
    FCalendar: ID3CommonCalendar;
    [weak] FFatal: ID3FatalErrorSink;
    FLogFile: ID3CommonFile;
    FLogFileFailed: Boolean;
    FLogRecursing: Boolean;
    FRedirectActive: Boolean;
    FRedirectBuffer: AnsiString;
    FRedirectSize: Integer;
    FRedirectFlush: TD3RedirectFlush;
    procedure WriteToLog(const AText: AnsiString);
  public
    constructor Create(const AState: TD3CommonState; const ACVars: ID3CommonCVars; const ASettings: ID3CommonSettings;
      const ASystem: ID3CommonSystem; const AConsole: ID3CommonConsole; const ASession: ID3CommonSession;
      const AFiles: ID3CommonFileSystem; const ACalendar: ID3CommonCalendar);
    /// <summary>
    ///   The fatal error of the log file that cannot be opened. It is a setter because the error handler
    ///   needs the printer and the printer needs the error handler; the printer does not own it
    /// </summary>
    procedure SetFatalErrorSink(const AFatal: ID3FatalErrorSink);
    /// <summary>idCommonLocal::BeginRedirect: nothing if the size is 0 or there is no flush</summary>
    procedure BeginRedirect(const ASize: Integer; const AFlush: TD3RedirectFlush);
    /// <summary>idCommonLocal::EndRedirect: flushes what is in the buffer</summary>
    procedure EndRedirect;
    /// <summary>idCommonLocal::CloseLogFile</summary>
    procedure CloseLogFile;
    /// <summary>idCommonLocal::SetRefreshOnPrint</summary>
    procedure SetRefreshOnPrint(const ASet: Boolean);
    /// <summary>idCommonLocal::VPrintf (and Printf)</summary>
    procedure Printf(const AText: AnsiString);
    /// <summary>idCommonLocal::DPrintf: only with the developer cvar, in red, without refreshing the screen</summary>
    procedure DPrintf(const AText: AnsiString);
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str;

const
  SDefaultLogFileName = 'qconsole.log';
  SLogOpened = 'log file ''%s'' opened on %s';
  SLogOpenFailed = 'failed to open log file ''%s''' + #10;
  STruncated = 'idCommon::VPrintf: truncated to %d characters' + #10;

constructor TD3Printer.Create(const AState: TD3CommonState; const ACVars: ID3CommonCVars;
  const ASettings: ID3CommonSettings; const ASystem: ID3CommonSystem; const AConsole: ID3CommonConsole;
  const ASession: ID3CommonSession; const AFiles: ID3CommonFileSystem; const ACalendar: ID3CommonCalendar);
begin
  inherited Create;
  FState := AState;
  FCVars := ACVars;
  FSettings := ASettings;
  FSystem := ASystem;
  FConsole := AConsole;
  FSession := ASession;
  FFiles := AFiles;
  FCalendar := ACalendar;
end;

procedure TD3Printer.SetFatalErrorSink(const AFatal: ID3FatalErrorSink);
begin
  FFatal := AFatal;
end;

procedure TD3Printer.BeginRedirect(const ASize: Integer; const AFlush: TD3RedirectFlush);
begin
  if (ASize <= 0) or (not Assigned(AFlush)) then
    Exit;
  FRedirectActive := True;
  FRedirectSize := ASize;
  FRedirectFlush := AFlush;
  FRedirectBuffer := '';
end;

procedure TD3Printer.EndRedirect;
begin
  if Assigned(FRedirectFlush) and (FRedirectBuffer <> '') then
    FRedirectFlush(FRedirectBuffer);
  FRedirectActive := False;
  FRedirectSize := 0;
  FRedirectFlush := nil;
  FRedirectBuffer := '';
end;

procedure TD3Printer.CloseLogFile;
begin
  if Assigned(FLogFile) then
  begin
    // make sure no further Printf attempts to open the log file again
    FSettings.DisableLogFile;
    FFiles.CloseFile(FLogFile);
    FLogFile := nil;
  end;
end;

procedure TD3Printer.SetRefreshOnPrint(const ASet: Boolean);
begin
  FState.RefreshOnPrint := ASet;
end;

procedure TD3Printer.WriteToLog(const AText: AnsiString);
var
  LFileName: AnsiString;
begin
  if (FSettings.LogFile = 0) or FLogFileFailed or (not FFiles.IsInitialized) then
    Exit;
  if (not Assigned(FLogFile)) and (not FLogRecursing) then
  begin
    LFileName := FSettings.LogFileName;
    if LFileName = '' then
      LFileName := SDefaultLogFileName;
    // OpenFileWrite can cause recursive prints into here
    FLogRecursing := True;
    FLogFile := FFiles.OpenFileWrite(LFileName, '');
    if not Assigned(FLogFile) then
    begin
      FLogFileFailed := True;
      if Assigned(FFatal) then
        FFatal.FatalError(AnsiString(Format(SLogOpenFailed, [string(LFileName)])));
    end;
    FLogRecursing := False;
    if Assigned(FLogFile) and (FSettings.LogFile > 1) then
      // force it to not buffer so we get valid data even if we are crashing
      FLogFile.ForceFlush;
    Printf(AnsiString(Format(SLogOpened, [string(LFileName), string(FCalendar.CurrentTimeText)])) + #10);
  end;
  if Assigned(FLogFile) then
  begin
    if AText <> '' then
      FLogFile.Write(AText[1], Length(AText));
    // ForceFlush doesn't help a whole lot
    FLogFile.Flush;
  end;
end;

procedure TD3Printer.Printf(const AText: AnsiString);
var
  LMessage: AnsiString;
  LPrefix: AnsiString;
  LTime: Integer;
  LLimit: Integer;
  LColorFree: TIdStr;
begin
  // if the cvar system is not initialized
  if not FCVars.IsInitialized then
    Exit;

  // optionally put a timestamp at the beginning of each print
  LPrefix := '';
  if FSettings.TimestampPrints <> 0 then
  begin
    LTime := FSystem.Milliseconds;
    if FSettings.TimestampPrints = 1 then
      LTime := LTime div 1000;
    LPrefix := AnsiString('[' + IntToStr(LTime) + ']');
  end;

  // don't overflow: idStr::vsnPrintf( msg + timeLength, MAX - timeLength - 1, ... ) keeps size - 2 characters
  LLimit := D3_MAX_PRINT_MSG_SIZE - Length(LPrefix) - 2;
  if Length(AText) > LLimit then
  begin
    LMessage := LPrefix + Copy(AText, 1, LLimit) + #10;
    FSystem.Printf(AnsiString(Format(STruncated, [Length(LMessage) - 1])));
  end
  else
    LMessage := LPrefix + AText;

  if FRedirectActive then
  begin
    if Length(LMessage) + Length(FRedirectBuffer) > FRedirectSize - 1 then
    begin
      FRedirectFlush(FRedirectBuffer);
      FRedirectBuffer := '';
    end;
    FRedirectBuffer := FRedirectBuffer + LMessage;
    Exit;
  end;

  // echo to console buffer
  FConsole.Print(LMessage);

  // remove any color codes
  LColorFree := TIdStr.Create(LMessage);
  LColorFree.RemoveColors;
  LMessage := LColorFree.Text;

  // echo to dedicated console and early console
  FSystem.Printf(LMessage);

  WriteToLog(LMessage);

  // don't trigger any updates if we are in the process of doing a fatal error
  if FState.ErrorEntered <> ERP_FATAL then
  begin
    // update the console if we are in a long-running command, like dmap
    if FState.RefreshOnPrint then
      FSession.UpdateScreen;
    // let session redraw the animated loading screen if necessary
    FSession.PacifierUpdate;
  end;
end;

procedure TD3Printer.DPrintf(const AText: AnsiString);
var
  LTemp: Boolean;
begin
  // don't confuse non-developers with techie stuff...
  if (not FCVars.IsInitialized) or (not FSettings.Developer) then
    Exit;
  // never refresh the screen, which could cause reentrancy problems
  LTemp := FState.RefreshOnPrint;
  FState.RefreshOnPrint := False;
  try
    Printf(D3_COLOR_RED + TD3MessageText.Limit(AText));
  finally
    FState.RefreshOnPrint := LTemp;
  end;
end;

end.
