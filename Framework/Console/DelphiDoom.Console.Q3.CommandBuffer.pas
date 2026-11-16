{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, command text buffer        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cmd.c           }
{  (Cbuf_Init, Cbuf_AddText, Cbuf_InsertText, Cbuf_ExecuteText, Cbuf_Execute). }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CommandBuffer;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   The text of the commands still to run (16 KB). A line ends at a line feed, a carriage return or a
  ///   semicolon outside quotes; a line of 1023 characters or more is cut there, and the character after
  ///   the cut is lost with it (the original deletes <c>i + 1</c> characters). A <c>wait</c> pending makes
  ///   <c>Execute</c> leave the rest for the next call. The text of the commands ends at the first NUL
  /// </summary>
  TQ3CommandBuffer = class(TInterfacedObject, IQ3CommandBuffer)
  strict private
    FRegistry: IQ3CommandRegistry;
    FLog: IQ3ConsoleLog;
    FText: AnsiString;
    FWait: Integer;
    class function CutAtNul(const AText: AnsiString): AnsiString; static;
    procedure Print(const AText: string);
  public
    /// <summary>The registry runs the lines; the log gets the overflow messages (nil = silence)</summary>
    constructor Create(const ARegistry: IQ3CommandRegistry; const ALog: IQ3ConsoleLog = nil);
    function GetWait: Integer;
    procedure SetWait(AValue: Integer);
    procedure AddText(const AText: AnsiString);
    procedure InsertText(const AText: AnsiString);
    procedure ExecuteText(AWhen: TQ3Execution; const AText: AnsiString);
    procedure Execute;
    /// <summary>The characters still in the buffer</summary>
    function Pending: AnsiString;
  end;

implementation

{ TQ3CommandBuffer }

constructor TQ3CommandBuffer.Create(const ARegistry: IQ3CommandRegistry; const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  FRegistry := ARegistry;
  FLog := ALog;
end;

class function TQ3CommandBuffer.CutAtNul(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] = #0 then
    begin
      SetLength(Result, LIndex - 1);
      Exit;
    end;
end;

procedure TQ3CommandBuffer.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

function TQ3CommandBuffer.GetWait: Integer;
begin
  Result := FWait;
end;

procedure TQ3CommandBuffer.SetWait(AValue: Integer);
begin
  FWait := AValue;
end;

procedure TQ3CommandBuffer.AddText(const AText: AnsiString);
var
  LText: AnsiString;
begin
  LText := CutAtNul(AText);
  if Length(FText) + Length(LText) >= Q3_MAX_CMD_BUFFER then
  begin
    Print('Cbuf_AddText: overflow'#10);
    Exit;
  end;
  FText := FText + LText;
end;

procedure TQ3CommandBuffer.InsertText(const AText: AnsiString);
var
  LText: AnsiString;
begin
  LText := CutAtNul(AText);
  if Length(LText) + 1 + Length(FText) > Q3_MAX_CMD_BUFFER then
  begin
    Print('Cbuf_InsertText overflowed'#10);
    Exit;
  end;
  FText := LText + #10 + FText;
end;

procedure TQ3CommandBuffer.ExecuteText(AWhen: TQ3Execution; const AText: AnsiString);
begin
  case AWhen of
    qeNow:
      if CutAtNul(AText) <> '' then
        FRegistry.ExecuteString(AText)
      else
        Execute;
    qeInsert:
      InsertText(AText);
    qeAppend:
      AddText(AText);
  else
    raise EQ3ConsoleException.Create(SQ3ConsoleBadExecution);
  end;
end;

procedure TQ3CommandBuffer.Execute;
var
  LIndex: Integer;
  LQuotes: Integer;
  LLine: AnsiString;
  LChar: AnsiChar;
begin
  while Length(FText) > 0 do
  begin
    if FWait <> 0 then
    begin
      Dec(FWait);
      Break;
    end;
    LQuotes := 0;
    LIndex := 0;
    while LIndex < Length(FText) do
    begin
      LChar := FText[LIndex + 1];
      if LChar = '"' then
        Inc(LQuotes);
      if ((LQuotes and 1) = 0) and (LChar = ';') then
        Break;
      if (LChar = #10) or (LChar = #13) then
        Break;
      Inc(LIndex);
    end;
    if LIndex >= Q3_MAX_CMD_LINE - 1 then
      LIndex := Q3_MAX_CMD_LINE - 1;
    LLine := Copy(FText, 1, LIndex);
    // the line is removed before it runs: commands (exec) insert text at the start of the buffer
    if LIndex >= Length(FText) then
      FText := ''
    else
      Delete(FText, 1, LIndex + 1);
    FRegistry.ExecuteString(LLine);
  end;
end;

function TQ3CommandBuffer.Pending: AnsiString;
begin
  Result := FText;
end;

end.
