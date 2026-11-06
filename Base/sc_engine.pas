//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------


{$I Doom32.inc}

unit sc_engine;

interface

uses
  d_delphi,
  DelphiDoom.Scanner.Scanner;

//
// JVAL
//
// Script Engine
//
// The scanning is done by TScriptScanner (Libs\Scanner): this class keeps the API that the
// rest of the engine uses and turns the lists of the scanner into TDStringList
//

const
  MAX_STRING_SIZE = 1024;

type
  TScriptEngine = class
  private
    FScanner: TScriptScanner;
  public
    constructor Create(const tx: string); virtual;
    destructor Destroy; override;
    procedure AddIgnoreToken(const s: string);
    procedure Clear;
    procedure SetText(const tx: string); virtual;
    procedure ScriptError(const err: string); overload;
    procedure ScriptError(const Fmt: string; const Args: array of const); overload;
    procedure ScriptPrintLineError(const lnno, offs: integer);
    function GetString: boolean;
    function GetStringEOL: string;
    function GetStringEOLWithQuotes: string;
    function GetTokensEOL: TDStringList;
    function GetStringEOLUnChanged: string;
    function MustGetString: boolean;
    function MustGetStringName(const name: string): boolean;
    function GetInteger: boolean;
    function MustGetInteger: boolean;
    function GetFloat: boolean;
    function MustGetFloat: boolean;
    function GetBoolean: boolean;
    function MustGetBoolean: boolean;
    procedure UnGet;
    function MatchString(const strs: TDStringList): integer; overload;
    function MatchString(const str: string): boolean; overload;
    function MatchPosString(const str: string): boolean;
    function MustMatchString(strs: TDStringList): integer;
    function Compare(const txt: string): boolean; overload;
    function Compare(const txt: string; const scmp: string): boolean; overload;
    procedure AddAlias(const src, dest: string);
    procedure ClearAliases;
    function GetInteger_: integer;
    function GetFloat_: float;
    function GetString_: string;
    function GetBoolean_: boolean;
    function GetFinished_: boolean;
    function GetLine_: integer;
    function GetNewLine_: boolean;
    function GetBracketLevel_: integer;
    function GetParenthesisLevel_: integer;
    function GetQuotedToken_: boolean;
    property _Integer: integer read GetInteger_;
    property _Float: float read GetFloat_;
    property _String: string read GetString_;
    property _Boolean: boolean read GetBoolean_;
    property _Finished: boolean read GetFinished_;
    property _Line: integer read GetLine_;
    property NewLine: boolean read GetNewLine_;
    property BracketLevel: integer read GetBracketLevel_;
    property ParenthesisLevel: integer read GetParenthesisLevel_;
    property QuotedToken: boolean read GetQuotedToken_;
  end;

//==============================================================================
//
// SC_RemoveLineQuotes
//
//==============================================================================
function SC_RemoveLineQuotes(const sctext: string): string;

//==============================================================================
//
// SC_RemoveLineComments
//
//==============================================================================
function SC_RemoveLineComments(const inp: string): string;

//==============================================================================
//
// SC_FixParenthesisLevel
//
//==============================================================================
function SC_FixParenthesisLevel(const inp: string): string;

//==============================================================================
//
// SC_ParamsToList
//
//==============================================================================
function SC_ParamsToList(inp: string): TDStringList;

//==============================================================================
//
// SC_IsStringInQuotes
//
//==============================================================================
function SC_IsStringInQuotes(const s: string): boolean;

//==============================================================================
//
// SC_TokensToList
//
//==============================================================================
function SC_TokensToList(const inp: string): TDStringList;

implementation

uses
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.Scanner.Text;

//==============================================================================
//
// WordsOf
//
//==============================================================================
function WordsOf(const strs: TDStringList): TArray<string>;
var
  i: integer;
begin
  SetLength(Result, strs.Count);
  for i := 0 to strs.Count - 1 do
    Result[i] := strs.Strings[i];
end;

//==============================================================================
//
// ListOf
//
//==============================================================================
function ListOf(const words: TArray<string>): TDStringList;
var
  i: integer;
begin
  result := TDStringList.Create;
  for i := 0 to High(words) do
    result.Add(words[i]);
end;

//==============================================================================
// TScriptEngine.Create
//
// TScriptEngine
//
//==============================================================================
constructor TScriptEngine.Create(const tx: string);
begin
  Inherited Create;
  FScanner := TScriptScanner.Create(tx, TEngineScannerLog.Create);
end;

//==============================================================================
//
// TScriptEngine.Destroy
//
//==============================================================================
destructor TScriptEngine.Destroy;
begin
  FScanner.Free;
  Inherited;
end;

//==============================================================================
//
// TScriptEngine.AddIgnoreToken
//
//==============================================================================
procedure TScriptEngine.AddIgnoreToken(const s: string);
begin
  FScanner.AddIgnoreToken(s);
end;

//==============================================================================
//
// TScriptEngine.Clear
//
//==============================================================================
procedure TScriptEngine.Clear;
begin
  FScanner.SetText('');
end;

//==============================================================================
//
// TScriptEngine.SetText
//
//==============================================================================
procedure TScriptEngine.SetText(const tx: string);
begin
  FScanner.SetText(tx);
end;

//==============================================================================
//
// TScriptEngine.ScriptError
//
//==============================================================================
procedure TScriptEngine.ScriptError(const err: string);
begin
  FScanner.Warn(err);
end;

//==============================================================================
//
// TScriptEngine.ScriptError
//
//==============================================================================
procedure TScriptEngine.ScriptError(const fmt: string; const Args: array of const);
var
  s: string;
begin
  sprintf(s, fmt, Args);
  ScriptError(s);
end;

//==============================================================================
//
// TScriptEngine.ScriptPrintLineError
//
//==============================================================================
procedure TScriptEngine.ScriptPrintLineError(const lnno, offs: integer);
begin
  FScanner.PrintLineError(lnno, offs);
end;

//==============================================================================
//
// TScriptEngine.MustGetString
//
//==============================================================================
function TScriptEngine.MustGetString: boolean;
begin
  result := FScanner.MustGetString;
end;

//==============================================================================
//
// TScriptEngine.MustGetStringName
//
//==============================================================================
function TScriptEngine.MustGetStringName(const name: string): boolean;
begin
  result := FScanner.MustGetStringName(name);
end;

//==============================================================================
//
// TScriptEngine.GetInteger
//
//==============================================================================
function TScriptEngine.GetInteger: boolean;
begin
  result := FScanner.GetInteger;
end;

//==============================================================================
//
// TScriptEngine.MustGetInteger
//
//==============================================================================
function TScriptEngine.MustGetInteger: boolean;
begin
  result := FScanner.MustGetInteger;
end;

//==============================================================================
//
// TScriptEngine.GetFloat
//
//==============================================================================
function TScriptEngine.GetFloat: boolean;
begin
  result := FScanner.GetFloat;
end;

//==============================================================================
//
// TScriptEngine.MustGetFloat
//
//==============================================================================
function TScriptEngine.MustGetFloat: boolean;
begin
  result := FScanner.MustGetFloat;
end;

//==============================================================================
//
// TScriptEngine.GetBoolean
//
//==============================================================================
function TScriptEngine.GetBoolean: boolean;
begin
  result := FScanner.GetBoolean;
end;

//==============================================================================
//
// TScriptEngine.MustGetBoolean
//
//==============================================================================
function TScriptEngine.MustGetBoolean: boolean;
begin
  result := FScanner.MustGetBoolean;
end;

//==============================================================================
//
// TScriptEngine.UnGet
//
//==============================================================================
procedure TScriptEngine.UnGet;
begin
  FScanner.UnGet;
end;

//==============================================================================
//
// TScriptEngine.MatchString
//
//==============================================================================
function TScriptEngine.MatchString(const str: string): boolean;
begin
  result := FScanner.MatchString(str);
end;

//==============================================================================
//
// TScriptEngine.MatchString
//
// Returns the index of the first match to the current word from the passed
// list of strings, or -1 if not found.
//
//==============================================================================
function TScriptEngine.MatchString(const strs: TDStringList): integer;
begin
  result := FScanner.MatchString(WordsOf(strs));
end;

//==============================================================================
//
// TScriptEngine.MatchPosString
//
//==============================================================================
function TScriptEngine.MatchPosString(const str: string): boolean;
begin
  result := FScanner.MatchPosString(str);
end;

//==============================================================================
//
// TScriptEngine.MustMatchString
//
//==============================================================================
function TScriptEngine.MustMatchString(strs: TDStringList): integer;
begin
  result := FScanner.MustMatchString(WordsOf(strs));
end;

//==============================================================================
//
// TScriptEngine.Compare
//
//==============================================================================
function TScriptEngine.Compare(const txt: string): boolean;
begin
  result := FScanner.Compare(txt);
end;

//==============================================================================
//
// TScriptEngine.Compare
//
//==============================================================================
function TScriptEngine.Compare(const txt: string; const scmp: string): boolean;
begin
  result := FScanner.Compare(txt, scmp);
end;

//==============================================================================
//
// TScriptEngine.AddAlias
//
//==============================================================================
procedure TScriptEngine.AddAlias(const src, dest: string);
begin
  FScanner.AddAlias(src, dest);
end;

//==============================================================================
//
// TScriptEngine.ClearAliases
//
//==============================================================================
procedure TScriptEngine.ClearAliases;
begin
  FScanner.ClearAliases;
end;

//==============================================================================
//
// TScriptEngine.GetString
//
//==============================================================================
function TScriptEngine.GetString: boolean;
begin
  result := FScanner.GetString;
end;

//==============================================================================
//
// TScriptEngine.GetStringEOL
//
//==============================================================================
function TScriptEngine.GetStringEOL: string;
begin
  result := FScanner.GetStringEOL;
end;

//==============================================================================
//
// TScriptEngine.GetStringEOLWithQuotes
//
//==============================================================================
function TScriptEngine.GetStringEOLWithQuotes: string;
begin
  result := FScanner.GetStringEOLWithQuotes;
end;

//==============================================================================
//
// TScriptEngine.GetTokensEOL
//
//==============================================================================
function TScriptEngine.GetTokensEOL: TDStringList;
begin
  result := ListOf(FScanner.GetTokensEOL);
end;

//==============================================================================
//
// TScriptEngine.GetStringEOLUnChanged
//
//==============================================================================
function TScriptEngine.GetStringEOLUnChanged: string;
begin
  result := FScanner.GetStringEOLUnchanged;
end;

//==============================================================================
//
// TScriptEngine.GetInteger_
//
//==============================================================================
function TScriptEngine.GetInteger_: integer;
begin
  result := FScanner.AsInteger;
end;

//==============================================================================
//
// TScriptEngine.GetFloat_
//
//==============================================================================
function TScriptEngine.GetFloat_: float;
begin
  result := FScanner.AsFloat;
end;

//==============================================================================
//
// TScriptEngine.GetString_
//
//==============================================================================
function TScriptEngine.GetString_: string;
begin
  result := FScanner.AsString;
end;

//==============================================================================
//
// TScriptEngine.GetBoolean_
//
//==============================================================================
function TScriptEngine.GetBoolean_: boolean;
begin
  result := FScanner.AsBoolean;
end;

//==============================================================================
//
// TScriptEngine.GetFinished_
//
//==============================================================================
function TScriptEngine.GetFinished_: boolean;
begin
  result := FScanner.Finished;
end;

//==============================================================================
//
// TScriptEngine.GetLine_
//
//==============================================================================
function TScriptEngine.GetLine_: integer;
begin
  result := FScanner.Line;
end;

//==============================================================================
//
// TScriptEngine.GetNewLine_
//
//==============================================================================
function TScriptEngine.GetNewLine_: boolean;
begin
  result := FScanner.NewLine;
end;

//==============================================================================
//
// TScriptEngine.GetBracketLevel_
//
//==============================================================================
function TScriptEngine.GetBracketLevel_: integer;
begin
  result := FScanner.BracketLevel;
end;

//==============================================================================
//
// TScriptEngine.GetParenthesisLevel_
//
//==============================================================================
function TScriptEngine.GetParenthesisLevel_: integer;
begin
  result := FScanner.ParenthesisLevel;
end;

//==============================================================================
//
// TScriptEngine.GetQuotedToken_
//
//==============================================================================
function TScriptEngine.GetQuotedToken_: boolean;
begin
  result := FScanner.QuotedToken;
end;

//==============================================================================
//
// SC_RemoveLineQuotes
//
//==============================================================================
function SC_RemoveLineQuotes(const sctext: string): string;
begin
  result := TScannerText.RemoveLineQuotes(sctext);
end;

//==============================================================================
//
// SC_RemoveLineComments
//
//==============================================================================
function SC_RemoveLineComments(const inp: string): string;
begin
  result := TScannerText.RemoveLineComments(inp);
end;

//==============================================================================
//
// SC_FixParenthesisLevel
//
//==============================================================================
function SC_FixParenthesisLevel(const inp: string): string;
begin
  result := TScannerText.FixParenthesisLevel(inp);
end;

//==============================================================================
//
// SC_ParamsToList
//
//==============================================================================
function SC_ParamsToList(inp: string): TDStringList;
begin
  result := ListOf(TScannerText.ParamsToList(inp));
end;

//==============================================================================
//
// SC_IsStringInQuotes
//
//==============================================================================
function SC_IsStringInQuotes(const s: string): boolean;
begin
  result := TScannerText.IsStringInQuotes(s);
end;

//==============================================================================
//
// SC_TokensToList
//
//==============================================================================
function SC_TokensToList(const inp: string): TDStringList;
begin
  result := ListOf(TScannerText.TokensToList(inp, TEngineScannerLog.Create));
end;

end.
