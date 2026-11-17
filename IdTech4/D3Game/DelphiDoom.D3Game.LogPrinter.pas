{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the output of the game to a log           }
{                                                                              }
{  Written for this repository (the original prints through common).          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.LogPrinter;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.D3Game.Intf;

type
  /// <summary>
  ///   <c>ID3GamePrinter</c> on an <c>IIdLibLog</c>: <c>Printf</c> is printed, <c>Warning</c> is a warning, and the
  ///   message of an <c>Error</c> is a warning too (the log has no error level: the game raises the exception)
  /// </summary>
  TD3GameLogPrinter = class(TInterfacedObject, ID3GamePrinter)
  strict private
    FLog: IIdLibLog;
  public
    constructor Create(const ALog: IIdLibLog);
    procedure Printf(const AText: AnsiString);
    procedure Warning(const AText: AnsiString);
    procedure Error(const AText: AnsiString);
  end;

implementation

constructor TD3GameLogPrinter.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TD3GameLogPrinter.Printf(const AText: AnsiString);
begin
  FLog.Printf(string(AText));
end;

procedure TD3GameLogPrinter.Warning(const AText: AnsiString);
begin
  FLog.Warning(string(AText));
end;

procedure TD3GameLogPrinter.Error(const AText: AnsiString);
begin
  FLog.Warning(string(AText));
end;

end.
