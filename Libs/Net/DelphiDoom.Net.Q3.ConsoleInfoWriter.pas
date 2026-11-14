{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - info strings for the Quake III console            }
{                                                                              }
{  Connects the console (IQ3InfoStringWriter of Libs\Console) to the info      }
{  strings of Quake III (TQ3InfoString): the console does not depend on this   }
{  library, this unit knows both.                                              }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.ConsoleInfoWriter;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Console.Q3.Intf, DelphiDoom.Net.Q3.InfoString;

type
  /// <summary>
  ///   Info_SetValueForKey and Info_SetValueForKey_Big for the cvars: what the original prints with
  ///   <c>Com_Printf</c> (one line each) goes to the console log, as in the original
  /// </summary>
  TQ3ConsoleInfoWriter = class(TInterfacedObject, IQ3InfoStringWriter)
  strict private
    type
      /// <summary>The ILog TQ3InfoString wants, on top of Com_Printf: each message is a line</summary>
      TPrintLog = class(TInterfacedObject, ILog)
      strict private
        FTarget: IQ3ConsoleLog;
      public
        constructor Create(const ATarget: IQ3ConsoleLog);
        procedure Info(const AText: string);
        procedure Warning(const AText: string);
        procedure DevWarning(const AText: string);
        procedure Error(const AText: string);
      end;
    var
      FLog: ILog;
  public
    /// <summary>The log is optional (nil = silent)</summary>
    constructor Create(const ALog: IQ3ConsoleLog = nil);
    /// <summary>Raises EQ3InfoStringException for a string already over the limit (Com_Error in the original)</summary>
    function SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString; ABig: Boolean): Boolean;
  end;

implementation

{ TQ3ConsoleInfoWriter.TPrintLog }

constructor TQ3ConsoleInfoWriter.TPrintLog.Create(const ATarget: IQ3ConsoleLog);
begin
  inherited Create;
  FTarget := ATarget;
end;

procedure TQ3ConsoleInfoWriter.TPrintLog.Info(const AText: string);
begin
  FTarget.Print(AText + #10);
end;

procedure TQ3ConsoleInfoWriter.TPrintLog.Warning(const AText: string);
begin
  FTarget.Print(AText + #10);
end;

procedure TQ3ConsoleInfoWriter.TPrintLog.DevWarning(const AText: string);
begin
  FTarget.DevPrint(AText + #10);
end;

procedure TQ3ConsoleInfoWriter.TPrintLog.Error(const AText: string);
begin
  FTarget.Print(AText + #10);
end;

{ TQ3ConsoleInfoWriter }

constructor TQ3ConsoleInfoWriter.Create(const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  if Assigned(ALog) then
    FLog := TPrintLog.Create(ALog);
end;

function TQ3ConsoleInfoWriter.SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString;
  ABig: Boolean): Boolean;
begin
  Result := TQ3InfoString.SetValueForKey(AInfo, AKey, AValue, ABig, FLog);
end;

end.
