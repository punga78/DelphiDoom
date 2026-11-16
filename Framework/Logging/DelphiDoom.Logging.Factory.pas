{******************************************************************************}
{                                                                              }
{  DelphiDoom: logging library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Logging.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the class behind ILog</summary>
  TLogFactory = class
  public
    /// <summary>AIsDeveloperMode may be nil</summary>
    class function CreateLog(const ASinks: TArray<ILogSink>;
      const AIsDeveloperMode: TFunc<Boolean>): ILog; static;
  end;

implementation

uses
  DelphiDoom.Logging.Log;

{ TLogFactory }

class function TLogFactory.CreateLog(const ASinks: TArray<ILogSink>;
  const AIsDeveloperMode: TFunc<Boolean>): ILog;
begin
  Result := TLog.Create(ASinks, AIsDeveloperMode);
end;

end.
