{******************************************************************************}
{                                                                              }
{  DelphiDoom: logging library - the log                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Logging.Log;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Sends the messages to its sinks, in the order they were given. Developer mode is asked to
  ///   a function every time, because it can change while the program runs
  /// </summary>
  TLog = class(TInterfacedObject, ILog)
  private
    FSinks: TArray<ILogSink>;
    FIsDeveloperMode: TFunc<Boolean>;
    procedure Send(AChannel: TLogChannel; const AText: string);
  public
    /// <summary>AIsDeveloperMode may be nil: the program is never in developer mode</summary>
    constructor Create(const ASinks: TArray<ILogSink>; const AIsDeveloperMode: TFunc<Boolean>);
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

implementation

{ TLog }

constructor TLog.Create(const ASinks: TArray<ILogSink>; const AIsDeveloperMode: TFunc<Boolean>);
begin
  inherited Create;
  FSinks := Copy(ASinks);
  FIsDeveloperMode := AIsDeveloperMode;
end;

procedure TLog.Send(AChannel: TLogChannel; const AText: string);
var
  LSink: ILogSink;
begin
  for LSink in FSinks do
    LSink.Write(AChannel, AText);
end;

procedure TLog.Info(const AText: string);
begin
  Send(TLogChannel.Output, AText);
end;

procedure TLog.Warning(const AText: string);
var
  LText: string;
begin
  LText := LOG_WARNING_PREFIX + AText;
  Send(TLogChannel.ErrorFile, LText);
  Send(TLogChannel.Output, LText);
end;

procedure TLog.DevWarning(const AText: string);
begin
  if Assigned(FIsDeveloperMode) and FIsDeveloperMode() then
    Warning(AText);
end;

procedure TLog.Error(const AText: string);
var
  LText: string;
begin
  LText := LOG_ERROR_PREFIX + AText + LOG_LINE_BREAK;
  Send(TLogChannel.ErrorFile, LText);
  Send(TLogChannel.Dialog, AText);
  Send(TLogChannel.Output, LText);
end;

end.
