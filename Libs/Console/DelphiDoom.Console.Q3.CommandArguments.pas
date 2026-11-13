{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, command line tokenizer     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cmd.c           }
{  (Cmd_TokenizeString, Cmd_Argc, Cmd_Argv, Cmd_Args, Cmd_ArgsFrom, Cmd_Cmd).  }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CommandArguments;

interface

uses
  System.SysUtils,DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   The tokens of the last command line. Quotes make one token (no escapes), spaces and control
  ///   characters separate, <c>//</c> ends the line, <c>/* */</c> is skipped, at most 1024 tokens are kept.
  ///   Bytes of 128 and above count as separators: the original reads a signed <c>char</c>, so they
  ///   are negative and "below a space". Text ends at the first NUL, as a C string. Unlike the original
  ///   nothing is limited by the sizes of its static buffers (<c>Cmd_Args</c> overflows its 1024
  ///   characters)
  /// </summary>
  TQ3CommandArguments = class(TInterfacedObject, IQ3CommandArguments)
  strict private
    FTokens: TArray<AnsiString>;
    FCount: Integer;
    FCommand: AnsiString;
    class function IsSeparator(AChar: AnsiChar): Boolean; static; inline;
    procedure AddToken(const AToken: AnsiString);
    function Join(AFrom: Integer): AnsiString;
  public
    constructor Create;
    procedure Tokenize(const AText: AnsiString);
    function Count: Integer;
    function Argv(AIndex: Integer): AnsiString;
    function Args: AnsiString;
    function ArgsFrom(AIndex: Integer): AnsiString;
    function Cmd: AnsiString;
  end;

implementation

{ TQ3CommandArguments }

constructor TQ3CommandArguments.Create;
begin
  inherited Create;
  SetLength(FTokens, Q3_MAX_STRING_TOKENS);
end;

class function TQ3CommandArguments.IsSeparator(AChar: AnsiChar): Boolean;
begin
  // signed char <= ' '
  Result := ShortInt(Ord(AChar)) <= 32;
end;

procedure TQ3CommandArguments.AddToken(const AToken: AnsiString);
begin
  FTokens[FCount] := AToken;
  Inc(FCount);
end;

procedure TQ3CommandArguments.Tokenize(const AText: AnsiString);
var
  LText: AnsiString;
  LLength: Integer;
  LPosition: Integer;
  LToken: AnsiString;

  function CharAt(AIndex: Integer): AnsiChar;
  begin
    if AIndex <= LLength then
      Result := LText[AIndex]
    else
      Result := #0;
  end;

begin
  FCount := 0;
  LText := AText;
  for LPosition := 1 to Length(LText) do
    if LText[LPosition] = #0 then
    begin
      // a NUL ends the C string
      SetLength(LText, LPosition - 1);
      Break;
    end;
  LLength := Length(LText);
  FCommand := Copy(LText, 1, Q3_BIG_INFO_STRING - 1);
  LPosition := 1;
  while True do
  begin
    if FCount = Q3_MAX_STRING_TOKENS then
      Exit;
    while True do
    begin
      while (CharAt(LPosition) <> #0) and IsSeparator(CharAt(LPosition)) do
        Inc(LPosition);
      if CharAt(LPosition) = #0 then
        Exit;
      if (CharAt(LPosition) = '/') and (CharAt(LPosition + 1) = '/') then
        Exit;
      if (CharAt(LPosition) = '/') and (CharAt(LPosition + 1) = '*') then
      begin
        while (CharAt(LPosition) <> #0) and not ((CharAt(LPosition) = '*') and (CharAt(LPosition + 1) = '/')) do
          Inc(LPosition);
        if CharAt(LPosition) = #0 then
          Exit;
        Inc(LPosition, 2);
      end
      else
        Break;
    end;
    if CharAt(LPosition) = '"' then
    begin
      Inc(LPosition);
      LToken := '';
      while (CharAt(LPosition) <> #0) and (CharAt(LPosition) <> '"') do
      begin
        LToken := LToken + CharAt(LPosition);
        Inc(LPosition);
      end;
      AddToken(LToken);
      if CharAt(LPosition) = #0 then
        Exit;
      Inc(LPosition);
      Continue;
    end;
    LToken := '';
    while (CharAt(LPosition) <> #0) and not IsSeparator(CharAt(LPosition)) do
    begin
      if CharAt(LPosition) = '"' then
        Break;
      if (CharAt(LPosition) = '/') and ((CharAt(LPosition + 1) = '/') or (CharAt(LPosition + 1) = '*')) then
        Break;
      LToken := LToken + CharAt(LPosition);
      Inc(LPosition);
    end;
    AddToken(LToken);
    if CharAt(LPosition) = #0 then
      Exit;
  end;
end;

function TQ3CommandArguments.Count: Integer;
begin
  Result := FCount;
end;

function TQ3CommandArguments.Argv(AIndex: Integer): AnsiString;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    Result := ''
  else
    Result := FTokens[AIndex];
end;

function TQ3CommandArguments.Join(AFrom: Integer): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := AFrom to FCount - 1 do
  begin
    Result := Result + FTokens[LIndex];
    if LIndex <> FCount - 1 then
      Result := Result + ' ';
  end;
end;

function TQ3CommandArguments.Args: AnsiString;
begin
  Result := Join(1);
end;

function TQ3CommandArguments.ArgsFrom(AIndex: Integer): AnsiString;
begin
  if AIndex < 0 then
    AIndex := 0;
  Result := Join(AIndex);
end;

function TQ3CommandArguments.Cmd: AnsiString;
begin
  Result := FCommand;
end;

end.
