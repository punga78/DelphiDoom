{******************************************************************************}
{                                                                              }
{  DelphiDoom: the log that the scanners of the engine write to                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.Log;

interface

uses
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Sends the messages to I_Warning at the time of the call, so a script read before the
  ///   composition root has given the log to i_system still prints (with printf)
  /// </summary>
  TEngineScannerLog = class(TInterfacedObject, ILog)
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

implementation

uses
  i_system;

{ TEngineScannerLog }

procedure TEngineScannerLog.Info(const AText: string);
begin
  I_Warning(AText);
end;

procedure TEngineScannerLog.Warning(const AText: string);
begin
  I_Warning(AText);
end;

procedure TEngineScannerLog.DevWarning(const AText: string);
begin
  I_DevWarning(AText);
end;

procedure TEngineScannerLog.Error(const AText: string);
begin
  I_Warning(AText);
end;

end.
