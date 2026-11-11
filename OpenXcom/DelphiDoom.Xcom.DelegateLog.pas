{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the log of the program                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.DelegateLog;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>Receives a line of the log, already with its level in front ("[WARN] ...")</summary>
  TXcomLogLine = reference to procedure(const ALine: string);

  /// <summary>IXcomLog that gives every line to a procedure of the program (the standard output of Xcom32)</summary>
  TXcomDelegateLog = class(TInterfacedObject, IXcomLog)
  strict private
    FOnLine: TXcomLogLine;
  public
    constructor Create(const AOnLine: TXcomLogLine);
    procedure Write(const ALevel, AMessage: string);
  end;

implementation

constructor TXcomDelegateLog.Create(const AOnLine: TXcomLogLine);
begin
  inherited Create;
  if not Assigned(AOnLine) then
    raise EArgumentNilException.Create('AOnLine');
  FOnLine := AOnLine;
end;

procedure TXcomDelegateLog.Write(const ALevel, AMessage: string);
begin
  FOnLine(Format('[%s] %s', [ALevel, AMessage]));
end;

end.
