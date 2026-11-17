{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the edit field                            }
{                                                                              }
{  Port of Doom 3 (id Software): framework\EditField.cpp and EditField.h       }
{  (idEditField, without Draw, which needs the renderer).                      }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.EditField;

interface

uses
  System.SysUtils, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Intf,
  DelphiDoom.D3Host.Input.Intf;

const
  /// <summary>MAX_EDIT_LINE: the buffer takes 255 characters and the terminator</summary>
  D3_MAX_EDIT_LINE = 256;

type
  /// <summary>What an edit field needs of the engine, shared by all the fields of a console</summary>
  TD3EditFieldEnvironment = record
    Keys: ID3KeyStates;
    Clipboard: ID3Clipboard;
    Printer: ID3Printer;
    Commands: ICmdCommands;
    CVars: ID3CVarServices;
  end;

  /// <summary>autoComplete_t: the state of the completion of the field, copied along with the field</summary>
  TD3AutoComplete = record
    Valid: Boolean;
    Length: Integer;
    CompletionString: AnsiString;
    CurrentMatch: AnsiString;
    MatchCount: Integer;
    MatchIndex: Integer;
    FindMatchIndex: Integer;
  end;

  /// <summary>
  ///   idEditField: a line of text with a cursor, edited by characters and keys, with the completion of the names
  ///   of the commands and the variables. The buffer is the C array (255 characters and the terminator): the
  ///   edits move bytes as the original does. Assign copies the whole field (the console keeps a history of
  ///   fields), the draw is not ported.
  /// </summary>
  TD3EditField = class
  strict private
    FEnvironment: TD3EditFieldEnvironment;
    FCursor: Integer;
    FScroll: Integer;
    FWidthInChars: Integer;
    FBuffer: array[0..D3_MAX_EDIT_LINE - 1] of Byte;
    FAutoComplete: TD3AutoComplete;
    function BufferLength: Integer;
    function GetText: AnsiString;
    procedure SetTextRaw(const AText: AnsiString);
  public
    constructor Create(const AEnvironment: TD3EditFieldEnvironment);
    /// <summary>The whole state of another field: buffer, cursor, scroll, width and the completion</summary>
    procedure Assign(const AOther: TD3EditField);
    procedure Clear;
    procedure SetWidthInChars(const AWidth: Integer);
    procedure SetCursor(const ACursor: Integer);
    function GetCursor: Integer;
    procedure ClearAutoComplete;
    function GetAutoCompleteLength: Integer;
    procedure AutoComplete;
    /// <summary>idEditField::CharEvent: ctrl-v paste, ctrl-c clear, backspace, ctrl-a home, ctrl-e end, printable characters</summary>
    procedure CharEvent(const ACharacter: Integer);
    procedure KeyDownEvent(const AKey: Integer);
    procedure Paste;
    /// <summary>idEditField::SetBuffer: clears, copies at most 255 characters and puts the cursor at the end</summary>
    procedure SetBuffer(const AText: AnsiString);
    property Text: AnsiString read GetText;
    property Cursor: Integer read FCursor;
    property Scroll: Integer read FScroll;
    property WidthInChars: Integer read FWidthInChars;
    property CompletionState: TD3AutoComplete read FAutoComplete;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Input.Types;

const
  SColorWhite = '^7';

function LowerByte(const AValue: Integer): Integer;
begin
  Result := AValue;
  if (AValue >= Ord('A')) and (AValue <= Ord('Z')) then
    Inc(Result, 32);
end;

// idStr::Icmpn( s, prefix, strlen( prefix ) ) == 0
function StartsWithNoCase(const AText, APrefix: AnsiString): Boolean;
var
  LIndex: Integer;
  LLeft: Integer;
  LRight: Integer;
begin
  Result := False;
  if Length(AText) < Length(APrefix) then
    Exit;
  for LIndex := 1 to Length(APrefix) do
  begin
    LLeft := Byte(AText[LIndex]);
    LRight := Byte(APrefix[LIndex]);
    if LLeft <> LRight then
    begin
      if (LLeft >= Ord('a')) and (LLeft <= Ord('z')) then
        Dec(LLeft, 32);
      if (LRight >= Ord('a')) and (LRight <= Ord('z')) then
        Dec(LRight, 32);
      if LLeft <> LRight then
        Exit;
    end;
  end;
  Result := True;
end;

// idStr::Copynz( dest, src, size ) of a 256 byte array
function Limit255(const AText: AnsiString): AnsiString;
begin
  if Length(AText) > D3_MAX_EDIT_LINE - 1 then
    Result := Copy(AText, 1, D3_MAX_EDIT_LINE - 1)
  else
    Result := AText;
end;

constructor TD3EditField.Create(const AEnvironment: TD3EditFieldEnvironment);
begin
  inherited Create;
  FEnvironment := AEnvironment;
  FWidthInChars := 0;
  Clear;
end;

procedure TD3EditField.Assign(const AOther: TD3EditField);
begin
  FCursor := AOther.FCursor;
  FScroll := AOther.FScroll;
  FWidthInChars := AOther.FWidthInChars;
  FBuffer := AOther.FBuffer;
  FAutoComplete := AOther.FAutoComplete;
end;

function TD3EditField.BufferLength: Integer;
begin
  Result := 0;
  while (Result < D3_MAX_EDIT_LINE) and (FBuffer[Result] <> 0) do
    Inc(Result);
end;

function TD3EditField.GetText: AnsiString;
var
  LLength: Integer;
begin
  LLength := BufferLength;
  SetLength(Result, LLength);
  if LLength > 0 then
    Move(FBuffer[0], Result[1], LLength);
end;

procedure TD3EditField.SetTextRaw(const AText: AnsiString);
var
  LLength: Integer;
begin
  LLength := Length(AText);
  if LLength > D3_MAX_EDIT_LINE - 1 then
    LLength := D3_MAX_EDIT_LINE - 1;
  if LLength > 0 then
    Move(AText[1], FBuffer[0], LLength);
  FBuffer[LLength] := 0;
end;

procedure TD3EditField.Clear;
begin
  FBuffer[0] := 0;
  FCursor := 0;
  FScroll := 0;
  FAutoComplete.Length := 0;
  FAutoComplete.Valid := False;
end;

procedure TD3EditField.SetWidthInChars(const AWidth: Integer);
begin
  FWidthInChars := AWidth;
end;

procedure TD3EditField.SetCursor(const ACursor: Integer);
begin
  FCursor := ACursor;
end;

function TD3EditField.GetCursor: Integer;
begin
  Result := FCursor;
end;

procedure TD3EditField.ClearAutoComplete;
begin
  if (FAutoComplete.Length > 0) and (FAutoComplete.Length <= BufferLength) then
  begin
    FBuffer[FAutoComplete.Length] := 0;
    if FCursor > FAutoComplete.Length then
      FCursor := FAutoComplete.Length;
  end;
  FAutoComplete.Length := 0;
  FAutoComplete.Valid := False;
end;

function TD3EditField.GetAutoCompleteLength: Integer;
begin
  Result := FAutoComplete.Length;
end;

procedure TD3EditField.AutoComplete;
var
  LGlobal: TD3AutoComplete;
  LArgs: TIdCmdArgs;
  LCompletionArgString: AnsiString;
  LFindMatches: TCmdCompletionCallback;
  LFindIndexMatch: TCmdCompletionCallback;
  LPrintMatches: TCmdCompletionCallback;
  LPrintCvarMatches: TCmdCompletionCallback;
  LBuffer: AnsiString;
  LLimit: Integer;
begin
  LFindMatches :=
    procedure(const AText: AnsiString)
    var
      LPosition: Integer;
    begin
      if not StartsWithNoCase(AText, LGlobal.CompletionString) then
        Exit;
      Inc(LGlobal.MatchCount);
      if LGlobal.MatchCount = 1 then
      begin
        LGlobal.CurrentMatch := Limit255(AText);
        Exit;
      end;
      // cut currentMatch to the amount common with s
      for LPosition := 1 to Length(AText) do
      begin
        if (LPosition > Length(LGlobal.CurrentMatch)) or
          (LowerByte(Byte(LGlobal.CurrentMatch[LPosition])) <> LowerByte(Byte(AText[LPosition]))) then
        begin
          LGlobal.CurrentMatch := Copy(LGlobal.CurrentMatch, 1, LPosition - 1);
          Exit;
        end;
      end;
      LGlobal.CurrentMatch := Copy(LGlobal.CurrentMatch, 1, Length(AText));
    end;
  LFindIndexMatch :=
    procedure(const AText: AnsiString)
    begin
      if not StartsWithNoCase(AText, LGlobal.CompletionString) then
        Exit;
      if LGlobal.FindMatchIndex = LGlobal.MatchIndex then
        LGlobal.CurrentMatch := Limit255(AText);
      Inc(LGlobal.FindMatchIndex);
    end;
  LPrintMatches :=
    procedure(const AText: AnsiString)
    begin
      if StartsWithNoCase(AText, LGlobal.CurrentMatch) then
        FEnvironment.Printer.Printf('    ' + AText + #10);
    end;
  LPrintCvarMatches :=
    procedure(const AText: AnsiString)
    begin
      if StartsWithNoCase(AText, LGlobal.CurrentMatch) then
        FEnvironment.Printer.Printf('    ' + AText + SColorWhite + ' = "' + FEnvironment.CVars.GetCVarString(AText) +
          '"' + #10);
    end;
  if not FAutoComplete.Valid then
  begin
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString(GetText, False);
      FAutoComplete.CompletionString := Limit255(LArgs.Argv(0));
      LCompletionArgString := Limit255(LArgs.Args);
    finally
      LArgs.Free;
    end;
    FAutoComplete.MatchCount := 0;
    FAutoComplete.MatchIndex := 0;
    FAutoComplete.CurrentMatch := '';
    if Length(FAutoComplete.CompletionString) = 0 then
      Exit;
    LGlobal := FAutoComplete;
    FEnvironment.Commands.CommandCompletion(LFindMatches);
    FEnvironment.CVars.CommandCompletion(LFindMatches);
    FAutoComplete := LGlobal;
    if FAutoComplete.MatchCount = 0 then
      Exit; // no matches
    // when there's only one match or there's an argument
    if (FAutoComplete.MatchCount = 1) or (LCompletionArgString <> '') then
    begin
      // try completing arguments
      FAutoComplete.CompletionString := Limit255(FAutoComplete.CompletionString + ' ' + LCompletionArgString);
      FAutoComplete.MatchCount := 0;
      LGlobal := FAutoComplete;
      FEnvironment.Commands.ArgCompletion(FAutoComplete.CompletionString, LFindMatches);
      FEnvironment.CVars.ArgCompletion(FAutoComplete.CompletionString, LFindMatches);
      FAutoComplete := LGlobal;
      SetTextRaw(FAutoComplete.CurrentMatch);
      if FAutoComplete.MatchCount = 0 then
      begin
        // no argument matches
        LBuffer := Limit255(GetText + ' ' + LCompletionArgString);
        SetTextRaw(LBuffer);
        SetCursor(BufferLength);
        Exit;
      end;
    end
    else
    begin
      // multiple matches, complete to shortest
      SetTextRaw(FAutoComplete.CurrentMatch);
      if Length(LCompletionArgString) > 0 then
        SetTextRaw(Limit255(GetText + ' ' + LCompletionArgString));
    end;
    FAutoComplete.Length := BufferLength;
    FAutoComplete.Valid := FAutoComplete.MatchCount <> 1;
    SetCursor(FAutoComplete.Length);
    FEnvironment.Printer.Printf(']' + GetText + #10);
    // run through again, printing matches
    LGlobal := FAutoComplete;
    FEnvironment.Commands.CommandCompletion(LPrintMatches);
    FEnvironment.Commands.ArgCompletion(FAutoComplete.CompletionString, LPrintMatches);
    FEnvironment.CVars.CommandCompletion(LPrintCvarMatches);
    FEnvironment.CVars.ArgCompletion(FAutoComplete.CompletionString, LPrintMatches);
  end
  else if FAutoComplete.MatchCount <> 1 then
  begin
    // get the next match and show instead
    Inc(FAutoComplete.MatchIndex);
    if FAutoComplete.MatchIndex = FAutoComplete.MatchCount then
      FAutoComplete.MatchIndex := 0;
    FAutoComplete.FindMatchIndex := 0;
    LGlobal := FAutoComplete;
    FEnvironment.Commands.CommandCompletion(LFindIndexMatch);
    FEnvironment.Commands.ArgCompletion(FAutoComplete.CompletionString, LFindIndexMatch);
    FEnvironment.CVars.CommandCompletion(LFindIndexMatch);
    FEnvironment.CVars.ArgCompletion(FAutoComplete.CompletionString, LFindIndexMatch);
    FAutoComplete := LGlobal;
    // and print it
    SetTextRaw(FAutoComplete.CurrentMatch);
    LLimit := BufferLength;
    if FAutoComplete.Length > LLimit then
      FAutoComplete.Length := LLimit;
    SetCursor(FAutoComplete.Length);
  end;
end;

procedure TD3EditField.CharEvent(const ACharacter: Integer);
var
  LLength: Integer;
begin
  if ACharacter = Ord('v') - Ord('a') + 1 then // ctrl-v is paste
  begin
    Paste;
    Exit;
  end;
  if ACharacter = Ord('c') - Ord('a') + 1 then // ctrl-c clears the field
  begin
    Clear;
    Exit;
  end;
  LLength := BufferLength;
  if (ACharacter = Ord('h') - Ord('a') + 1) or (ACharacter = K_BACKSPACE) then // ctrl-h is backspace
  begin
    if FCursor > 0 then
    begin
      Move(FBuffer[FCursor], FBuffer[FCursor - 1], LLength + 1 - FCursor);
      Dec(FCursor);
      if FCursor < FScroll then
        Dec(FScroll);
    end;
    Exit;
  end;
  if ACharacter = Ord('a') - Ord('a') + 1 then // ctrl-a is home
  begin
    FCursor := 0;
    FScroll := 0;
    Exit;
  end;
  if ACharacter = Ord('e') - Ord('a') + 1 then // ctrl-e is end
  begin
    FCursor := LLength;
    FScroll := FCursor - FWidthInChars;
    Exit;
  end;
  // ignore any other non printable chars
  if ACharacter < 32 then
    Exit;
  if FEnvironment.Keys.GetOverstrikeMode then
  begin
    if FCursor = D3_MAX_EDIT_LINE - 1 then
      Exit;
    FBuffer[FCursor] := Byte(ACharacter);
    Inc(FCursor);
  end
  else
  begin
    if LLength = D3_MAX_EDIT_LINE - 1 then
      Exit; // all full
    Move(FBuffer[FCursor], FBuffer[FCursor + 1], LLength + 1 - FCursor);
    FBuffer[FCursor] := Byte(ACharacter);
    Inc(FCursor);
  end;
  if FCursor >= FWidthInChars then
    Inc(FScroll);
  if FCursor = LLength + 1 then
    FBuffer[FCursor] := 0;
end;

procedure TD3EditField.KeyDownEvent(const AKey: Integer);
var
  LLength: Integer;
  LKeys: ID3KeyStates;
begin
  LKeys := FEnvironment.Keys;
  // shift-insert is paste
  if ((AKey = K_INS) or (AKey = K_KP_INS)) and LKeys.IsDown(K_SHIFT) then
  begin
    ClearAutoComplete;
    Paste;
    Exit;
  end;
  LLength := BufferLength;
  if AKey = K_DEL then
  begin
    if FAutoComplete.Length <> 0 then
      ClearAutoComplete
    else if FCursor < LLength then
      Move(FBuffer[FCursor + 1], FBuffer[FCursor], LLength - FCursor);
    Exit;
  end;
  if AKey = K_RIGHTARROW then
  begin
    if LKeys.IsDown(K_CTRL) then
    begin
      // skip to next word
      while (FCursor < LLength) and (FBuffer[FCursor] <> Ord(' ')) do
        Inc(FCursor);
      while (FCursor < LLength) and (FBuffer[FCursor] = Ord(' ')) do
        Inc(FCursor);
    end
    else
      Inc(FCursor);
    if FCursor > LLength then
      FCursor := LLength;
    if FCursor >= FScroll + FWidthInChars then
      FScroll := FCursor - FWidthInChars + 1;
    if FAutoComplete.Length > 0 then
      FAutoComplete.Length := FCursor;
    Exit;
  end;
  if AKey = K_LEFTARROW then
  begin
    if LKeys.IsDown(K_CTRL) then
    begin
      // skip to previous word
      while (FCursor > 0) and (FBuffer[FCursor - 1] = Ord(' ')) do
        Dec(FCursor);
      while (FCursor > 0) and (FBuffer[FCursor - 1] <> Ord(' ')) do
        Dec(FCursor);
    end
    else
      Dec(FCursor);
    if FCursor < 0 then
      FCursor := 0;
    if FCursor < FScroll then
      FScroll := FCursor;
    if FAutoComplete.Length <> 0 then
      FAutoComplete.Length := FCursor;
    Exit;
  end;
  if (AKey = K_HOME) or ((LowerByte(AKey) = Ord('a')) and LKeys.IsDown(K_CTRL)) then
  begin
    FCursor := 0;
    FScroll := 0;
    if FAutoComplete.Length <> 0 then
    begin
      FAutoComplete.Length := FCursor;
      FAutoComplete.Valid := False;
    end;
    Exit;
  end;
  if (AKey = K_END) or ((LowerByte(AKey) = Ord('e')) and LKeys.IsDown(K_CTRL)) then
  begin
    FCursor := LLength;
    if FCursor >= FScroll + FWidthInChars then
      FScroll := FCursor - FWidthInChars + 1;
    if FAutoComplete.Length <> 0 then
    begin
      FAutoComplete.Length := FCursor;
      FAutoComplete.Valid := False;
    end;
    Exit;
  end;
  if AKey = K_INS then
  begin
    LKeys.SetOverstrikeMode(not LKeys.GetOverstrikeMode);
    Exit;
  end;
  // clear autocompletion buffer on normal key input
  if (AKey <> K_CAPSLOCK) and (AKey <> K_ALT) and (AKey <> K_CTRL) and (AKey <> K_SHIFT) then
    ClearAutoComplete;
end;

procedure TD3EditField.Paste;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  if not FEnvironment.Clipboard.GetClipboardData(LText) then
    Exit;
  // sent as if typed, so insert / overstrike works properly; the original passes a signed char
  for LIndex := 1 to Length(LText) do
    CharEvent(ShortInt(Byte(LText[LIndex])));
end;

procedure TD3EditField.SetBuffer(const AText: AnsiString);
begin
  Clear;
  SetTextRaw(AText);
  SetCursor(BufferLength);
end;

end.
