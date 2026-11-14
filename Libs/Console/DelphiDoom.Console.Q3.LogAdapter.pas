{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, log on ILog                }
{                                                                              }
{  Com_Printf and Com_DPrintf of the console on the log of the engine.         }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.LogAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   <c>IQ3ConsoleLog</c> on an <c>ILog</c>: <c>Print</c> is <c>ILog.Info</c> (the text as it is, with its
  ///   line feeds); <c>DevPrint</c> is the same text only while the function says the program runs in
  ///   developer mode (<c>com_developer</c>), asked every time like <c>TLog</c> does. <c>DevWarning</c>
  ///   is not used because it adds the "I_Warning: " prefix, which <c>Com_DPrintf</c> does not
  /// </summary>
  TQ3ConsoleLogAdapter = class(TInterfacedObject, IQ3ConsoleLog)
  strict private
    FLog: ILog;
    FIsDeveloperMode: TFunc<Boolean>;
  public
    /// <summary>AIsDeveloperMode may be nil: <c>DevPrint</c> is then always silent</summary>
    constructor Create(const ALog: ILog; const AIsDeveloperMode: TFunc<Boolean> = nil);
    procedure Print(const AText: string);
    procedure DevPrint(const AText: string);
  end;

implementation

{ TQ3ConsoleLogAdapter }

constructor TQ3ConsoleLogAdapter.Create(const ALog: ILog; const AIsDeveloperMode: TFunc<Boolean>);
begin
  inherited Create;
  FLog := ALog;
  FIsDeveloperMode := AIsDeveloperMode;
end;

procedure TQ3ConsoleLogAdapter.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

procedure TQ3ConsoleLogAdapter.DevPrint(const AText: string);
begin
  if Assigned(FLog) and Assigned(FIsDeveloperMode) and FIsDeveloperMode() then
    FLog.Info(AText);
end;

end.
