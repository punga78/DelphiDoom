{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the log of the game for the game host library          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostLog;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   ILog of Libs\Logging on the log of the game: what Libs\GameHost says goes there with the levels of OpenXcom
  ///   (INFO, WARN and ERROR). An error is only written: nothing ends the program here
  /// </summary>
  TXcomHostLog = class(TInterfacedObject, ILog)
  strict private
    FLog: IXcomLog;
  public
    constructor Create(const ALog: IXcomLog);
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

implementation

const
  SLogInfo = 'INFO';
  SLogWarning = 'WARN';
  SLogError = 'ERROR';

constructor TXcomHostLog.Create(const ALog: IXcomLog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

procedure TXcomHostLog.Info(const AText: string);
begin
  FLog.Write(SLogInfo, AText);
end;

procedure TXcomHostLog.Warning(const AText: string);
begin
  FLog.Write(SLogWarning, AText);
end;

procedure TXcomHostLog.DevWarning(const AText: string);
begin
  FLog.Write(SLogWarning, AText);
end;

procedure TXcomHostLog.Error(const AText: string);
begin
  FLog.Write(SLogError, AText);
end;

end.
