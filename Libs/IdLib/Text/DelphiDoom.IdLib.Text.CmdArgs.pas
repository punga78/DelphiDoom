{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib text - TIdCmdArgs, the tokenizer of command lines         }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\CmdArgs.h, CmdArgs.cpp.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Text.CmdArgs;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf;

const
  /// <summary>idCmdArgs::MAX_COMMAND_ARGS</summary>
  ID_MAX_COMMAND_ARGS = 64;
  /// <summary>idCmdArgs::MAX_COMMAND_STRING: 2 * MAX_STRING_CHARS</summary>
  ID_MAX_COMMAND_STRING = 2 * 1024;

type
  /// <summary>
  ///   idCmdArgs: the arguments of a console command. <c>TokenizeString</c> breaks a text into
  ///   tokens with the lexer (no errors or warnings, strings are not concatenated, path names and
  ///   IP addresses allowed, a minus sign before a number joins it, <c>$name</c> expands a console
  ///   variable). The cvar system is optional: without it a <c>$name</c> gives "&lt;unknown&gt;".
  ///   At most 64 tokens and 2048 bytes (the original stops silently, so does this).
  /// </summary>
  TIdCmdArgs = class
  private
    FArguments: array[0..ID_MAX_COMMAND_ARGS - 1] of AnsiString;
    FArgumentCount: Integer;
    FTotalLength: Integer;
    FCVars: IIdLibCVars;
  public
    constructor Create(const ACVars: IIdLibCVars = nil);
    /// <summary>operator=</summary>
    procedure Assign(const AOther: TIdCmdArgs);
    function Argc: Integer;
    /// <summary>The argument, or an empty string if the index is out of range</summary>
    function Argv(const AIndex: Integer): AnsiString;
    /// <summary>One string with argv(start) to argv(end), separated by spaces or quoted when escaped</summary>
    function Args(const AStart: Integer = 1; const AEnd: Integer = -1; const AEscapeArgs: Boolean = False): AnsiString;
    procedure TokenizeString(const AText: AnsiString; const AKeepAsStrings: Boolean);
    procedure AppendArg(const AText: AnsiString);
    procedure Clear;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Lexer;

{ TIdCmdArgs }

constructor TIdCmdArgs.Create(const ACVars: IIdLibCVars);
begin
  inherited Create;
  FCVars := ACVars;
  FArgumentCount := 0;
  FTotalLength := 0;
end;

procedure TIdCmdArgs.Assign(const AOther: TIdCmdArgs);
var
  LIndex: Integer;
begin
  FArgumentCount := AOther.FArgumentCount;
  FTotalLength := AOther.FTotalLength;
  for LIndex := 0 to FArgumentCount - 1 do
    FArguments[LIndex] := AOther.FArguments[LIndex];
end;

function TIdCmdArgs.Argc: Integer;
begin
  Result := FArgumentCount;
end;

function TIdCmdArgs.Argv(const AIndex: Integer): AnsiString;
begin
  if (AIndex >= 0) and (AIndex < FArgumentCount) then
    Result := FArguments[AIndex]
  else
    Result := '';
end;

function TIdCmdArgs.Args(const AStart, AEnd: Integer; const AEscapeArgs: Boolean): AnsiString;
var
  LEnd, LIndex, LChar: Integer;
begin
  LEnd := AEnd;
  if LEnd < 0 then
    LEnd := FArgumentCount - 1
  else if LEnd >= FArgumentCount then
    LEnd := FArgumentCount - 1;
  Result := '';
  if AEscapeArgs then
    Result := Result + '"';
  for LIndex := AStart to LEnd do
  begin
    if LIndex > AStart then
    begin
      if AEscapeArgs then
        Result := Result + '" "'
      else
        Result := Result + ' ';
    end;
    if AEscapeArgs and (Pos('\', string(FArguments[LIndex])) > 0) then
    begin
      for LChar := 1 to Length(FArguments[LIndex]) do
        if FArguments[LIndex][LChar] = '\' then
          Result := Result + '\\'
        else
          Result := Result + FArguments[LIndex][LChar];
    end
    else
      Result := Result + FArguments[LIndex];
  end;
  if AEscapeArgs then
    Result := Result + '"';
end;

procedure TIdCmdArgs.TokenizeString(const AText: AnsiString; const AKeepAsStrings: Boolean);
var
  LLexer: TIdLexer;
  LToken, LNumber: TIdToken;
  LLength, LFlags: Integer;
  LText: AnsiString;
begin
  // clear previous args
  FArgumentCount := 0;
  FTotalLength := 0;
  LFlags := LEXFL_NOERRORS or LEXFL_NOWARNINGS or LEXFL_NOSTRINGCONCAT or LEXFL_ALLOWPATHNAMES or
    LEXFL_NOSTRINGESCAPECHARS or LEXFL_ALLOWIPADDRESSES;
  if AKeepAsStrings then
    LFlags := LFlags or LEXFL_ONLYSTRINGS;
  LLexer := TIdLexer.Create(0);
  try
    LLexer.LoadMemory(AText, 'idCmdSystemLocal::TokenizeString');
    LLexer.Flags := LFlags;
    LToken := TIdToken.Create;
    LNumber := TIdToken.Create;
    while True do
    begin
      if FArgumentCount = ID_MAX_COMMAND_ARGS then
        Exit;
      if not LLexer.ReadToken(LToken) then
        Exit;
      // check for negative numbers
      if (not AKeepAsStrings) and LToken.IsText('-') then
        if LLexer.CheckTokenType(TT_NUMBER, 0, LNumber) then
          LToken.Text := '-' + LNumber.Text;
      // check for cvar expansion
      if LToken.IsText('$') then
      begin
        if not LLexer.ReadToken(LToken) then
          Exit;
        if Assigned(FCVars) then
          LToken.Text := FCVars.GetCVarString(LToken.Text)
        else
          LToken.Text := '<unknown>';
      end;
      LText := Copy(LToken.Text, 1, Length(LToken.Text));
      LLength := Length(LText);
      if FTotalLength + LLength + 1 > ID_MAX_COMMAND_STRING then
        Exit;
      FArguments[FArgumentCount] := LText;
      Inc(FArgumentCount);
      Inc(FTotalLength, LLength + 1);
    end;
  finally
    LLexer.Free;
  end;
end;

procedure TIdCmdArgs.AppendArg(const AText: AnsiString);
begin
  if FArgumentCount = 0 then
  begin
    FArgumentCount := 1;
    FArguments[0] := AText;
    FTotalLength := Length(AText) + 1;
  end
  else
  begin
    FArguments[FArgumentCount] := AText;
    Inc(FArgumentCount);
    Inc(FTotalLength, Length(AText) + 1);
  end;
end;

procedure TIdCmdArgs.Clear;
begin
  FArgumentCount := 0;
  FTotalLength := 0;
end;

end.
