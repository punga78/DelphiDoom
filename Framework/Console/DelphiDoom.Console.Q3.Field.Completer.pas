{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, command completion         }
{                                                                              }
{  Field_CompleteCommand of common.c (FindMatches, PrintMatches,               }
{  keyConcatArgs, ConcatRemaining): the Tab key.                               }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Field.Completer;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.Field.Types;

type
  /// <summary>
  ///   Tab expansion of the first word of a field over the command names and the variable names (case
  ///   is ignored). One match: the line becomes "\name" and a space (or keeps the rest of the line);
  ///   several: it becomes the part they share and the matches are printed. The original tokenizes the
  ///   field with the console arguments, so the arguments of the console are changed by a completion.
  ///   Quirk kept: the common part is cut only as far as the names that come after the first are
  ///   long, so a later name that is a prefix of the shortest match leaves it as it was
  /// </summary>
  TQ3FieldCompleter = class
  strict private
    FArguments: IQ3CommandArguments;
    FCommands: IQ3CommandRegistry;
    FCVars: IQ3CVarSystem;
    FLog: IQ3ConsoleLog;
    class function IsSamePrefix(const AText, APrefix: AnsiString): Boolean; static;
    class function LowerByte(AChar: Byte): Byte; static;
    procedure Print(const AText: string);
    procedure AppendArguments(var AField: TQ3EditField);
    procedure AppendRemaining(var AField: TQ3EditField; const ASource, AStart: AnsiString);
    function Names: TArray<AnsiString>;
  public
    /// <summary>The log is optional; the others are the ones the console uses</summary>
    constructor Create(const AArguments: IQ3CommandArguments; const ACommands: IQ3CommandRegistry;
      const ACVars: IQ3CVarSystem; const ALog: IQ3ConsoleLog = nil);
    /// <summary>Field_CompleteCommand</summary>
    procedure Complete(var AField: TQ3EditField);
  end;

implementation

{ TQ3FieldCompleter }

constructor TQ3FieldCompleter.Create(const AArguments: IQ3CommandArguments; const ACommands: IQ3CommandRegistry;
  const ACVars: IQ3CVarSystem; const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  FArguments := AArguments;
  FCommands := ACommands;
  FCVars := ACVars;
  FLog := ALog;
end;

class function TQ3FieldCompleter.LowerByte(AChar: Byte): Byte;
begin
  if (AChar >= Ord('A')) and (AChar <= Ord('Z')) then
    Result := AChar + 32
  else
    Result := AChar;
end;

class function TQ3FieldCompleter.IsSamePrefix(const AText, APrefix: AnsiString): Boolean;
var
  LIndex: Integer;
  LFirst: Byte;
  LSecond: Byte;
begin
  // !Q_stricmpn(AText, APrefix, strlen(APrefix)): the first characters of both agree without case
  for LIndex := 1 to Length(APrefix) do
  begin
    if LIndex <= Length(AText) then
      LFirst := Ord(AText[LIndex])
    else
      LFirst := 0;
    LSecond := Ord(APrefix[LIndex]);
    if (LFirst <> LSecond) and (LowerByte(LFirst) <> LowerByte(LSecond)) then
      Exit(False);
  end;
  Result := True;
end;

procedure TQ3FieldCompleter.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

function TQ3FieldCompleter.Names: TArray<AnsiString>;
var
  LCommands: TArray<AnsiString>;
  LVariables: TArray<TQ3CVar>;
  LIndex: Integer;
begin
  // Cmd_CommandCompletion and then Cvar_CommandCompletion, each in the order of its list
  LCommands := FCommands.CommandNames;
  LVariables := FCVars.Variables;
  SetLength(Result, Length(LCommands) + Length(LVariables));
  for LIndex := 0 to High(LCommands) do
    Result[LIndex] := LCommands[LIndex];
  for LIndex := 0 to High(LVariables) do
    Result[Length(LCommands) + LIndex] := LVariables[LIndex].Name;
end;

procedure TQ3FieldCompleter.AppendArguments(var AField: TQ3EditField);
var
  LIndex: Integer;
  LArgument: AnsiString;
  LHasSpace: Boolean;
begin
  // keyConcatArgs: the arguments after the first, with quotes round those that have a space
  for LIndex := 1 to FArguments.Count - 1 do
  begin
    AField.Append(' ');
    LArgument := FArguments.Argv(LIndex);
    LHasSpace := Pos(AnsiString(' '), LArgument) > 0;
    if LHasSpace then
      AField.Append('"');
    AField.Append(LArgument);
    if LHasSpace then
      AField.Append('"');
  end;
end;

procedure TQ3FieldCompleter.AppendRemaining(var AField: TQ3EditField; const ASource, AStart: AnsiString);
var
  LPosition: Integer;
begin
  // ConcatRemaining: what follows the first occurrence of the word in the old line, or the arguments
  LPosition := Pos(AStart, ASource);
  if LPosition = 0 then
  begin
    AppendArguments(AField);
    Exit;
  end;
  AField.Append(Copy(ASource, LPosition + Length(AStart), MaxInt));
end;

procedure TQ3FieldCompleter.Complete(var AField: TQ3EditField);
var
  LOld: TQ3EditField;
  LWord: AnsiString;
  LShortest: array[0..Q3_MAX_TOKEN_CHARS - 1] of Byte;
  LMatchCount: Integer;
  LName: AnsiString;
  LNames: TArray<AnsiString>;
  LIndex: Integer;
  LShortestText: AnsiString;

  function ShortestText: AnsiString;
  var
    LLength: Integer;
  begin
    LLength := 0;
    while (LLength < Q3_MAX_TOKEN_CHARS) and (LShortest[LLength] <> 0) do
      Inc(LLength);
    SetString(Result, PAnsiChar(@LShortest[0]), LLength);
  end;

begin
  // only the first token counts
  FArguments.Tokenize(AField.Text);
  LWord := FArguments.Argv(0);
  if (LWord <> '') and ((LWord[1] = '\') or (LWord[1] = '/')) then
    Delete(LWord, 1, 1);
  LMatchCount := 0;
  FillChar(LShortest, SizeOf(LShortest), 0);
  if LWord = '' then
    Exit;
  LNames := Names;
  for LName in LNames do
  begin
    if not IsSamePrefix(LName, LWord) then
      Continue;
    Inc(LMatchCount);
    if LMatchCount = 1 then
    begin
      // Q_strncpyz into the buffer of MAX_TOKEN_CHARS
      FillChar(LShortest, SizeOf(LShortest), 0);
      for LIndex := 1 to Length(LName) do
        if LIndex < Q3_MAX_TOKEN_CHARS then
          LShortest[LIndex - 1] := Ord(LName[LIndex]);
      Continue;
    end;
    // cut the shortest match to what it shares with the name
    for LIndex := 0 to Length(LName) - 1 do
      if (LIndex < Q3_MAX_TOKEN_CHARS) and (LowerByte(LShortest[LIndex]) <> LowerByte(Ord(LName[LIndex + 1]))) then
        LShortest[LIndex] := 0;
  end;
  if LMatchCount = 0 then
    Exit;
  LOld := AField;
  LShortestText := ShortestText;
  if LMatchCount = 1 then
  begin
    AField.Assign('\' + LShortestText, FLog);
    if FArguments.Count = 1 then
      AField.Append(' ')
    else
      AppendRemaining(AField, LOld.Text, LWord);
    AField.Cursor := AField.Length;
    Exit;
  end;
  // several matches: complete to the shortest and show them
  AField.Assign('\' + LShortestText, FLog);
  AField.Cursor := AField.Length;
  AppendRemaining(AField, LOld.Text, LWord);
  Print(Format(']%s'#10, [string(AField.Text)]));
  for LName in LNames do
    if IsSamePrefix(LName, LShortestText) then
      Print(Format('    %s'#10, [string(LName)]));
end;

end.
