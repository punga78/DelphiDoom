{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the trace of the options file on a log    }
{  (issue 186)                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.OptionsAuditLog;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.OptionsAudit.Intf;

type
  /// <summary>
  ///   IXcomOptionsAudit on two IXcomLog: the trace (nil: off) with the time, the process that writes (two games on the
  ///   same user folder are told apart) and the reason, and the warnings (nil: nowhere)
  /// </summary>
  TXcomOptionsAuditLog = class(TInterfacedObject, IXcomOptionsAudit)
  strict private
    FTrace: IXcomLog;
    FWarnings: IXcomLog;
    FNow: TFunc<string>;
    FProcessId: Cardinal;
  public
    /// <param name="ANow">The time as text (the clock is not read here, so a test can fix it)</param>
    constructor Create(const ATrace, AWarnings: IXcomLog; const ANow: TFunc<string>; AProcessId: Cardinal);
    procedure Report(const AReason, AMessage: string);
    procedure Warning(const AMessage: string);
  end;

implementation

constructor TXcomOptionsAuditLog.Create(const ATrace, AWarnings: IXcomLog; const ANow: TFunc<string>;
  AProcessId: Cardinal);
begin
  inherited Create;
  if not Assigned(ANow) then
    raise EArgumentNilException.Create('ANow');
  FTrace := ATrace;
  FWarnings := AWarnings;
  FNow := ANow;
  FProcessId := AProcessId;
end;

procedure TXcomOptionsAuditLog.Report(const AReason, AMessage: string);
begin
  if FTrace <> nil then
    FTrace.Write('OPTIONS', Format('%s pid=%d [%s] %s', [FNow(), FProcessId, AReason, AMessage]));
end;

procedure TXcomOptionsAuditLog.Warning(const AMessage: string);
var
  LLine: string;
begin
  LLine := Format('%s pid=%d %s', [FNow(), FProcessId, AMessage]);
  if FWarnings <> nil then
    FWarnings.Write('WARN', LLine);
  if FTrace <> nil then
    FTrace.Write('OPTIONS', LLine);
end;

end.
