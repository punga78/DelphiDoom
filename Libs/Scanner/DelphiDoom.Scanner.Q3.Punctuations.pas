{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TQ3PunctuationTable, the punctuations of the  }
{  script parser of Quake III Arena                                            }
{                                                                              }
{  Port of the Quake III Arena GPL Source Code (id Software), code\botlib\     }
{  l_script.c: default_punctuations and PS_CreatePunctuationTable.             }
{  Copyright (C) 1999-2005 Id Software, Inc. Licensed under the GNU General    }
{  Public License, version 2 or later.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Q3.Punctuations;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.Q3.Types;

type
  /// <summary>
  ///   A set of punctuations and the table of the first character: for every first character the
  ///   punctuations are kept longer first (a later one of the same length goes after the earlier ones),
  ///   as PS_CreatePunctuationTable sorts them
  /// </summary>
  TQ3PunctuationTable = class sealed
  strict private
    FPunctuations: TQ3PunctuationArray;
    FBuckets: array[0..255] of TArray<Integer>;
  public
    /// <summary>The set of the script (nil or empty: the default C/C++ set)</summary>
    constructor Create(const APunctuations: TQ3PunctuationArray);
    /// <summary>default_punctuations: the C/C++ set (with the dollar sign)</summary>
    class function DefaultSet: TQ3PunctuationArray; static;
    /// <summary>
    ///   PS_ReadPunctuation: the index of the punctuation that the buffer has at APosition (the end is the
    ///   index of the first byte after the text), or -1
    /// </summary>
    function Find(const ABuffer: TBytes; const APosition, AEnd: Integer): Integer;
    /// <summary>PunctuationFromNum: the text of the punctuation with the number ("unkown punctuation" if none)</summary>
    function TextFromNumber(const ANumber: Integer): AnsiString;
    property Punctuations: TQ3PunctuationArray read FPunctuations;
  end;

implementation

{ TQ3PunctuationTable }

constructor TQ3PunctuationTable.Create(const APunctuations: TQ3PunctuationArray);
var
  LIndex: Integer;
  LPosition: Integer;
  LFirst: Integer;
  LBucket: TArray<Integer>;
begin
  inherited Create;
  if Length(APunctuations) = 0 then
    FPunctuations := DefaultSet
  else
    FPunctuations := APunctuations;
  for LIndex := 0 to High(FPunctuations) do
  begin
    if FPunctuations[LIndex].Text = '' then
      Continue;
    LFirst := Ord(FPunctuations[LIndex].Text[1]);
    LBucket := FBuckets[LFirst];
    LPosition := 0;
    while (LPosition < Length(LBucket)) and
      (Length(FPunctuations[LBucket[LPosition]].Text) >= Length(FPunctuations[LIndex].Text)) do
      Inc(LPosition);
    SetLength(LBucket, Length(LBucket) + 1);
    Move(LBucket[LPosition], LBucket[LPosition + 1], (High(LBucket) - LPosition) * SizeOf(Integer));
    LBucket[LPosition] := LIndex;
    FBuckets[LFirst] := LBucket;
  end;
end;

class function TQ3PunctuationTable.DefaultSet: TQ3PunctuationArray;
const
  Texts: array[0..52] of AnsiString = (
    '>>=', '<<=', '...', '##', '&&', '||', '>=', '<=', '==', '!=', '*=', '/=', '%=', '+=', '-=', '++',
    '--', '&=', '|=', '^=', '>>', '<<', '->', '::', '.*', '*', '/', '%', '+', '-', '=', '&', '|', '^',
    '~', '!', '>', '<', '.', ',', ';', ':', '?', '(', ')', '{', '}', '[', ']', '\', '#', '$', '');
  Numbers: array[0..52] of Integer = (
    P_RSHIFT_ASSIGN, P_LSHIFT_ASSIGN, P_PARMS, P_PRECOMPMERGE, P_LOGIC_AND, P_LOGIC_OR, P_LOGIC_GEQ,
    P_LOGIC_LEQ, P_LOGIC_EQ, P_LOGIC_UNEQ, P_MUL_ASSIGN, P_DIV_ASSIGN, P_MOD_ASSIGN, P_ADD_ASSIGN,
    P_SUB_ASSIGN, P_INC, P_DEC, P_BIN_AND_ASSIGN, P_BIN_OR_ASSIGN, P_BIN_XOR_ASSIGN, P_RSHIFT, P_LSHIFT,
    P_POINTERREF, P_CPP1, P_CPP2, P_MUL, P_DIV, P_MOD, P_ADD, P_SUB, P_ASSIGN, P_BIN_AND, P_BIN_OR,
    P_BIN_XOR, P_BIN_NOT, P_LOGIC_NOT, P_LOGIC_GREATER, P_LOGIC_LESS, P_REF, P_COMMA, P_SEMICOLON, P_COLON,
    P_QUESTIONMARK, P_PARENTHESESOPEN, P_PARENTHESESCLOSE, P_BRACEOPEN, P_BRACECLOSE, P_SQBRACKETOPEN,
    P_SQBRACKETCLOSE, P_BACKSLASH, P_PRECOMP, P_DOLLAR, 0);
var
  LIndex: Integer;
begin
  // the last entry (empty text) is the terminator of the C array
  SetLength(Result, Length(Texts) - 1);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Text := Texts[LIndex];
    Result[LIndex].Number := Numbers[LIndex];
  end;
end;

function TQ3PunctuationTable.Find(const ABuffer: TBytes; const APosition, AEnd: Integer): Integer;
var
  LBucket: TArray<Integer>;
  LIndex: Integer;
  LLength: Integer;
  LByte: Integer;
  LMatch: Boolean;
begin
  Result := -1;
  LBucket := FBuckets[ABuffer[APosition]];
  for LIndex := 0 to High(LBucket) do
  begin
    LLength := Length(FPunctuations[LBucket[LIndex]].Text);
    // if the script contains at least as much characters as the punctuation
    if APosition + LLength <= AEnd then
    begin
      LMatch := True;
      for LByte := 1 to LLength do
        if ABuffer[APosition + LByte - 1] <> Byte(FPunctuations[LBucket[LIndex]].Text[LByte]) then
        begin
          LMatch := False;
          Break;
        end;
      if LMatch then
        Exit(LBucket[LIndex]);
    end;
  end;
end;

function TQ3PunctuationTable.TextFromNumber(const ANumber: Integer): AnsiString;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FPunctuations) do
    if FPunctuations[LIndex].Number = ANumber then
      Exit(FPunctuations[LIndex].Text);
  Result := 'unkown punctuation';
end;

end.
