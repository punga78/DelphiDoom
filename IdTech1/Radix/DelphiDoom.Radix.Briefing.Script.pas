{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBriefingScript                            }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the reading of the script in RB_Start (radix_briefing.pas of Rad-X) }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Briefing.Script;

interface

uses
  DelphiDoom.Radix.Briefing.Types;

type
  /// <summary>
  ///   Reads the text of a mission briefing of RADIX.DAT: one command for every line ("name" or
  ///   "name: arguments"), a line that starts with ; or // is a comment. The lines print, println
  ///   and printname that follow one another become one command bckPrint. A line that is not a
  ///   command is skipped, as Rad-X did; a number that is missing or wrong is ERadixException
  /// </summary>
  TRadixBriefingScript = class
  public const
    /// <summary>How many commands a briefing holds at most (the rest is dropped, as in Rad-X)</summary>
    MAX_COMMANDS = 512;
  strict private
    class function PrintText(const AArguments: string): string; static;
    class function ReadNumber(const AWords: TArray<string>; AIndex, ALine: Integer): Integer; static;
  public
    /// <param name="APilotName">What printname writes</param>
    class function Parse(const AText: string; const APilotName: string): TArray<TRadixBriefingCommand>; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Radix.Types;

const
  SMissingNumber = 'Radix briefing, line %d: a number is missing';
  SWrongNumber = 'Radix briefing, line %d: "%s" is not a whole number';
  // a print without text is an empty line
  EMPTY_PRINT = '"$"';

{ TRadixBriefingScript }

class function TRadixBriefingScript.PrintText(const AArguments: string): string;
var
  LIndex: Integer;
begin
  if (AArguments = '') or (AArguments.Trim = EMPTY_PRINT) then
    Exit('');
  Result := AArguments;
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] = '$' then
      Result[LIndex] := ' '
    // the small font has the apostrophe at the place of the grave accent
    else if Result[LIndex] = '''' then
      Result[LIndex] := '`';
end;

class function TRadixBriefingScript.ReadNumber(const AWords: TArray<string>; AIndex, ALine: Integer): Integer;
begin
  if AIndex > High(AWords) then
    raise ERadixException.CreateFmt(SMissingNumber, [ALine]);
  if not TryStrToInt(AWords[AIndex], Result) then
    raise ERadixException.CreateFmt(SWrongNumber, [ALine, AWords[AIndex]]);
end;

class function TRadixBriefingScript.Parse(const AText: string;
  const APilotName: string): TArray<TRadixBriefingCommand>;
var
  LLines: TArray<string>;
  LLineIndex: Integer;
  LLine: string;
  LName: string;
  LArguments: string;
  LWords: TArray<string>;
  LSplit: Integer;
  LCount: Integer;
  LPrint: string;
  LPrinting: Boolean;
  LCommand: TRadixBriefingCommand;
  LIndex: Integer;
  LKnown: Boolean;

  procedure Add(const ACommand: TRadixBriefingCommand);
  begin
    if LCount < MAX_COMMANDS then
    begin
      Result[LCount] := ACommand;
      Inc(LCount);
    end;
  end;

  procedure FlushPrint;
  var
    LPrintCommand: TRadixBriefingCommand;
  begin
    if not LPrinting then
      Exit;
    LPrinting := False;
    // a run of prints that wrote nothing is no command (Rad-X dropped it too)
    if LPrint <> '' then
    begin
      LPrintCommand := Default(TRadixBriefingCommand);
      LPrintCommand.Kind := bckPrint;
      LPrintCommand.Text := LPrint;
      Add(LPrintCommand);
    end;
    LPrint := '';
  end;

begin
  LLines := AText.Replace(#13, '').Split([#10]);
  SetLength(Result, MAX_COMMANDS);
  LCount := 0;
  LPrint := '';
  LPrinting := False;
  for LLineIndex := 0 to High(LLines) do
  begin
    LLine := LLines[LLineIndex].Trim;
    if (LLine = '') or LLine.StartsWith(';') or LLine.StartsWith('//') then
      Continue;
    // the name ends at the first colon or blank; what follows are the arguments
    LSplit := 1;
    while (LSplit <= Length(LLine)) and not CharInSet(LLine[LSplit], [':', ' ', #9]) do
      Inc(LSplit);
    LName := UpperCase(Copy(LLine, 1, LSplit - 1));
    LArguments := Copy(LLine, LSplit + 1, MaxInt).TrimLeft;

    if (LName = 'PRINT') or (LName = 'PRINTLN') or (LName = 'PRINTNAME') then
    begin
      LPrinting := True;
      if LName = 'PRINT' then
        LPrint := LPrint + PrintText(LArguments)
      else if LName = 'PRINTLN' then
        LPrint := LPrint + PrintText(LArguments) + #13#10
      else
        LPrint := LPrint + APilotName;
      Continue;
    end;
    FlushPrint;

    LCommand := Default(TRadixBriefingCommand);
    LWords := LArguments.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
    LKnown := True;
    if LName = 'CLEARANIMWINDOW' then
      LCommand.Kind := bckClearAnimWindow
    else if LName = 'CLEARTEXTWINDOW' then
      LCommand.Kind := bckClearTextWindow
    else if LName = 'DELAY' then
    begin
      LCommand.Kind := bckDelay;
      LCommand.Numbers[0] := ReadNumber(LWords, 0, LLineIndex + 1);
    end
    else if (LName = 'DISPLAYANIMATION') or (LName = 'DISPLAYIMAGE') then
    begin
      if LName = 'DISPLAYANIMATION' then
        LCommand.Kind := bckDisplayAnimation
      else
        LCommand.Kind := bckDisplayImage;
      if Length(LWords) = 0 then
        raise ERadixException.CreateFmt(SMissingNumber, [LLineIndex + 1]);
      LCommand.Text := LWords[0];
      for LIndex := 0 to 1 + Ord(LCommand.Kind = bckDisplayAnimation) do
        LCommand.Numbers[LIndex] := ReadNumber(LWords, LIndex + 1, LLineIndex + 1);
    end
    else if LName = 'MAPPRINT' then
    begin
      LCommand.Kind := bckMapPrint;
      LCommand.Numbers[0] := ReadNumber(LWords, 0, LLineIndex + 1);
      LCommand.Numbers[1] := ReadNumber(LWords, 1, LLineIndex + 1);
      // the text is the rest of the line after the two numbers
      LCommand.Text := string.Join(' ', LWords, 2, Length(LWords) - 2);
    end
    else if LName = 'NEXTPOINT' then
      LCommand.Kind := bckNextPoint
    else if LName = 'POINTMAP' then
    begin
      LCommand.Kind := bckPointMap;
      for LIndex := 0 to RADIX_BRIEFING_NUMBERS - 1 do
        LCommand.Numbers[LIndex] := ReadNumber(LWords, LIndex, LLineIndex + 1);
    end
    else if LName = 'SCROLLMAPX' then
    begin
      LCommand.Kind := bckScrollMapX;
      LCommand.Numbers[0] := ReadNumber(LWords, 0, LLineIndex + 1);
    end
    else if LName = 'SHOWSCREEN' then
      LCommand.Kind := bckShowScreen
    else if LName = 'WAITACTION' then
      LCommand.Kind := bckWaitAction
    else
      LKnown := False;
    if LKnown then
      Add(LCommand);
  end;
  FlushPrint;
  SetLength(Result, LCount);
end;

end.
