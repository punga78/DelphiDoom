{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the scanner                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Scanner;

interface

type
  /// <summary>
  ///   Cuts a text in words like the script engine of the old code: a word ends at a space or
  ///   at one of { } ( ) , and at //; a word in quotes keeps everything up to the closing quote;
  ///   // up to the end of the line is a comment and a lone slash is dropped. A word is at most
  ///   1023 characters
  /// </summary>
  TUdmfScanner = class
  public
    const
      MAX_WORD_LENGTH = 1023;
  private
    FText: string;
    FPosition: Integer; // 1-based, the next character
    FValue: string;
    function IsSeparator(AChar: Char): Boolean;
  public
    constructor Create(const AText: string);
    /// <summary>The next word, in Value; false at the end of the text</summary>
    function GetString: Boolean;
    property Value: string read FValue;
  end;

implementation

{ TUdmfScanner }

constructor TUdmfScanner.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FPosition := 1;
end;

function TUdmfScanner.IsSeparator(AChar: Char): Boolean;
begin
  Result := (AChar = '{') or (AChar = '}') or (AChar = '(') or (AChar = ')') or (AChar = ',');
end;

function TUdmfScanner.GetString: Boolean;
var
  LEnd: Integer;
  LFound: Boolean;
  LWord: string;
begin
  Result := False;
  LEnd := Length(FText) + 1;
  if FPosition >= LEnd then
    Exit;

  LFound := False;
  while not LFound do
  begin
    while (FPosition < LEnd) and ((FText[FPosition] <= #32) or IsSeparator(FText[FPosition])) do
      Inc(FPosition);

    if FPosition >= LEnd then
      Exit;

    if FText[FPosition] <> '/' then
      LFound := True
    else
    begin
      // a comment, or a lone slash that is dropped
      Inc(FPosition);
      if (FPosition < LEnd) and (FText[FPosition] = '/') then
      begin
        while (FPosition < LEnd) and (FText[FPosition] <> #13) and (FText[FPosition] <> #10) do
          Inc(FPosition);
        if FPosition >= LEnd then
          Exit;
      end;
    end;
  end;

  LWord := '';
  if FText[FPosition] = '"' then
  begin
    Inc(FPosition);
    while (FPosition < LEnd) and (FText[FPosition] <> '"') and (Length(LWord) < MAX_WORD_LENGTH) do
    begin
      LWord := LWord + FText[FPosition];
      Inc(FPosition);
    end;
    Inc(FPosition);
  end
  else
  begin
    while (FPosition < LEnd) and (FText[FPosition] > #32) and not IsSeparator(FText[FPosition]) and
      not ((FText[FPosition] = '/') and (FPosition + 1 < LEnd) and (FText[FPosition + 1] = '/')) and
      (Length(LWord) < MAX_WORD_LENGTH) do
    begin
      LWord := LWord + FText[FPosition];
      Inc(FPosition);
    end;
  end;

  FValue := LWord;
  Result := True;
end;

end.