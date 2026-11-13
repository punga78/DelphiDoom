{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the messages of the parser go to the Gui log      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.IdLibLog;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Intf, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>The log that idParser writes to (file, line and text are already in its message), as an IGuiLog line</summary>
  TGuiIdLibLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FLog: IGuiLog;
  public
    constructor Create(const ALog: IGuiLog);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

implementation

constructor TGuiIdLibLog.Create(const ALog: IGuiLog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TGuiIdLibLog.Printf(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Info(AMessage);
end;

procedure TGuiIdLibLog.Warning(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Info(AMessage);
end;

end.
