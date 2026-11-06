{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the line that the user types                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.InputLine;

interface

uses
  DelphiDoom.Console.Intf, DelphiDoom.Console.History, DelphiDoom.Console.Completer;

type
  /// <summary>
  ///   The input buffer of the console (ConsoleInputBuff): the prompt and what is typed after
  ///   it. Keys, shift and drawing stay in the engine; the engine calls these methods
  ///   </summary>
  TConsoleInputLine = class
  private
    FPrompt: string;
    FInterpreter: IConsoleInterpreter;
    FOutput: IConsoleOutput;
    FHistory: TConsoleHistory;
    FCompleter: TConsoleCompleter;
    FBuffer: string;
    FNeedsUpdate: Boolean;
    function GetCommandText: string;
  public
    /// <summary>The line takes the history and the completer and frees them. The completer may be nil</summary>
    constructor Create(const APrompt: string; const AInterpreter: IConsoleInterpreter;
      const AOutput: IConsoleOutput; AHistory: TConsoleHistory; ACompleter: TConsoleCompleter);
    destructor Destroy; override;
    /// <summary>Back to the prompt alone</summary>
    procedure Reset;
    function IsEmpty: Boolean;
    procedure AppendChar(AChar: Char);
    procedure Backspace;
    /// <summary>The previous line of the history in the buffer. False if there is none</summary>
    function HistoryPrevious: Boolean;
    function HistoryNext: Boolean;
    /// <summary>
    ///   The line is written on the console, goes in the history and runs; if it is not a
    ///   command the console says so. Gives false (doing nothing) if the line is empty
    /// </summary>
    function Submit: Boolean;
    /// <summary>
    ///   TAB: the name of the command is completed as far as it is the only possible one; if
    ///   there are many the console lists them. Gives how many names fit
    /// </summary>
    function Complete: Integer;
    property Buffer: string read FBuffer;
    /// <summary>What was typed, without the prompt</summary>
    property CommandText: string read GetCommandText;
    /// <summary>True when the buffer changed and the console must draw it again; the engine clears it</summary>
    property NeedsUpdate: Boolean read FNeedsUpdate write FNeedsUpdate;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Text;

const
  LINE_BREAK = #13#10;
  UNKNOWN_COMMAND = 'Unknown command' + LINE_BREAK;

{ TConsoleInputLine }

constructor TConsoleInputLine.Create(const APrompt: string; const AInterpreter: IConsoleInterpreter;
  const AOutput: IConsoleOutput; AHistory: TConsoleHistory; ACompleter: TConsoleCompleter);
begin
  inherited Create;
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create('AInterpreter');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(AHistory) then
    raise EArgumentNilException.Create('AHistory');
  FPrompt := APrompt;
  FInterpreter := AInterpreter;
  FOutput := AOutput;
  FHistory := AHistory;
  FCompleter := ACompleter;
  Reset;
end;

destructor TConsoleInputLine.Destroy;
begin
  FCompleter.Free;
  FHistory.Free;
  inherited Destroy;
end;

function TConsoleInputLine.GetCommandText: string;
begin
  Result := Copy(FBuffer, Length(FPrompt) + 1, Length(FBuffer) - Length(FPrompt));
end;

procedure TConsoleInputLine.Reset;
begin
  FBuffer := FPrompt;
  FNeedsUpdate := True;
end;

function TConsoleInputLine.IsEmpty: Boolean;
begin
  Result := FBuffer = FPrompt;
end;

procedure TConsoleInputLine.AppendChar(AChar: Char);
begin
  FBuffer := FBuffer + AChar;
  FNeedsUpdate := True;
end;

procedure TConsoleInputLine.Backspace;
begin
  if not IsEmpty then
  begin
    SetLength(FBuffer, Length(FBuffer) - 1);
    FNeedsUpdate := True;
  end;
end;

function TConsoleInputLine.HistoryPrevious: Boolean;
var
  LLine: string;
begin
  Result := FHistory.Previous(LLine);
  if Result then
  begin
    FBuffer := LLine;
    FNeedsUpdate := True;
  end;
end;

function TConsoleInputLine.HistoryNext: Boolean;
var
  LLine: string;
begin
  Result := FHistory.Next(LLine);
  if Result then
  begin
    FBuffer := LLine;
    FNeedsUpdate := True;
  end;
end;

function TConsoleInputLine.Submit: Boolean;
var
  LLine: string;
begin
  Result := not IsEmpty;
  if not Result then
    Exit;
  LLine := FBuffer;
  FOutput.Write(LLine + LINE_BREAK);
  FHistory.Add(LLine);
  if not FInterpreter.Execute(Copy(LLine, Length(FPrompt) + 1, Length(LLine) - Length(FPrompt))) then
    FOutput.Write(UNKNOWN_COMMAND);
  Reset;
end;

function TConsoleInputLine.Complete: Integer;
var
  LTyped: string;
  LNames: TArray<string>;
  LCommon: string;
  LName: string;
  LList: string;
begin
  Result := 0;
  if not Assigned(FCompleter) then
    Exit;
  LTyped := CommandText;
  if Pos(' ', LTyped) > 0 then
    Exit;
  LNames := FCompleter.Candidates(LTyped);
  Result := Length(LNames);
  if Result = 0 then
    Exit;

  if Result = 1 then
  begin
    FBuffer := FPrompt + LNames[0] + ' ';
    FNeedsUpdate := True;
    Exit;
  end;

  LCommon := TConsoleCompleter.CommonPrefix(LNames);
  if Length(LCommon) > Length(LTyped) then
  begin
    FBuffer := FPrompt + LCommon;
    FNeedsUpdate := True;
  end;
  LList := '';
  for LName in LNames do
    LList := LList + ' ' + LName;
  FOutput.Write(TConsoleText.Trim(LList) + LINE_BREAK);
end;

end.
