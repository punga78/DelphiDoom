{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvars, the list of variables         }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.cpp              }
{  (CreateColumn and idCVarSystemLocal::ListByFlags).                          }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Lister;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CVar.Intf;

type
  /// <summary>
  ///   The output of "listCvars": the variables with a flag, filtered by a mask, sorted by name and
  ///   shown as values, descriptions (in a column), types and ranges, or flags
  /// </summary>
  TCVarLister = class
  strict private
    FCVars: ICVarSystem;
    FLog: IIdLibLog;
    procedure Print(const AText: string);
  public
    constructor Create(const ACVars: ICVarSystem; const ALog: IIdLibLog);
    /// <summary>
    ///   idCVarSystemLocal::ListByFlags: argv(1) can be "-" or "/" followed by help, ?, type, range or
    ///   flags; the rest of the arguments are the mask
    /// </summary>
    procedure ListByFlags(const AArgs: TIdCmdArgs; const AFlags: Integer);
    /// <summary>
    ///   CreateColumn: AText broken into lines of AColumnWidth characters (at a blank, a slash, a comma
    ///   or a backslash) where each break is AIndent. It is as the original is, defects included
    /// </summary>
    class function CreateColumn(const AText: AnsiString; const AColumnWidth: Integer;
      const AIndent: AnsiString): AnsiString; static;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.Variable;

type
  TShow = (shValue, shDescription, shType, shFlags);

function PadRight(const AText: AnsiString; const AWidth: Integer): string;
begin
  Result := string(AText);
  if Length(Result) < AWidth then
    Result := Result + StringOfChar(' ', AWidth - Length(Result));
end;

function Mark(const AFlags: Integer; const AFlag: Integer; const AOn, AOff: string): string;
begin
  if (AFlags and AFlag) <> 0 then
    Result := AOn
  else
    Result := AOff;
end;

{ TCVarLister }

constructor TCVarLister.Create(const ACVars: ICVarSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FCVars := ACVars;
  FLog := ALog;
end;

procedure TCVarLister.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

class function TCVarLister.CreateColumn(const AText: AnsiString; const AColumnWidth: Integer;
  const AIndent: AnsiString): AnsiString;
var
  LIndex, LLastLine: Integer;

  // text[i] of a C string: a char is signed, the end is 0
  function Ch(const APosition: Integer): Integer;
  begin
    if APosition < Length(AText) then
      Result := ShortInt(Byte(AText[APosition + 1]))
    else
      Result := 0;
  end;

begin
  Result := '';
  LLastLine := 0;
  LIndex := 0;
  while Ch(LIndex) <> 0 do
  begin
    if (LIndex - LLastLine >= AColumnWidth) or (Ch(LIndex) = 10) then
    begin
      while (LIndex > 0) and (Ch(LIndex) > 32) and (Ch(LIndex) <> Ord('/')) and (Ch(LIndex) <> Ord(',')) and
        (Ch(LIndex) <> Ord('\')) do
        Dec(LIndex);
      while LLastLine < LIndex do
      begin
        Result := Result + AText[LLastLine + 1];
        Inc(LLastLine);
      end;
      Result := Result + AIndent;
      Inc(LLastLine);
    end;
    Inc(LIndex);
  end;
  while LLastLine < LIndex do
  begin
    Result := Result + AText[LLastLine + 1];
    Inc(LLastLine);
  end;
end;

procedure TCVarLister.ListByFlags(const AArgs: TIdCmdArgs; const AFlags: Integer);
const
  NUM_COLUMNS = 77;
  NUM_NAME_CHARS = 33;
  NUM_DESCRIPTION_CHARS = NUM_COLUMNS - NUM_NAME_CHARS;
  NAME_WIDTH = 32;
var
  LArgNumber, LIndex, LStringIndex: Integer;
  LShow: TShow;
  LMatch: TIdStr;
  LList: TArray<TCVar>;
  LCount: Integer;
  LVariable: TCVar;
  LIndent, LLine: string;
begin
  LArgNumber := 1;
  LShow := shValue;

  if (TIdStrings.Icmp(AArgs.Argv(LArgNumber), '-') = 0) or (TIdStrings.Icmp(AArgs.Argv(LArgNumber), '/') = 0) then
  begin
    if (TIdStrings.Icmp(AArgs.Argv(LArgNumber + 1), 'help') = 0) or
      (TIdStrings.Icmp(AArgs.Argv(LArgNumber + 1), '?') = 0) then
    begin
      LArgNumber := 3;
      LShow := shDescription;
    end
    else if (TIdStrings.Icmp(AArgs.Argv(LArgNumber + 1), 'type') = 0) or
      (TIdStrings.Icmp(AArgs.Argv(LArgNumber + 1), 'range') = 0) then
    begin
      LArgNumber := 3;
      LShow := shType;
    end
    else if TIdStrings.Icmp(AArgs.Argv(LArgNumber + 1), 'flags') = 0 then
    begin
      LArgNumber := 3;
      LShow := shFlags;
    end;
  end;

  if AArgs.Argc > LArgNumber then
  begin
    LMatch := TIdStr.Create(AArgs.Args(LArgNumber, -1));
    LMatch.Replace(' ', '');
  end
  else
    LMatch := TIdStr.Create('');

  SetLength(LList, FCVars.Count);
  LCount := 0;
  for LIndex := 0 to FCVars.Count - 1 do
  begin
    LVariable := FCVars.Item(LIndex);
    if (LVariable.Flags and AFlags) = 0 then
      Continue;
    if (LMatch.Length > 0) and not TIdStrings.Filter(LMatch, LVariable.Name, False) then
      Continue;
    LList[LCount] := LVariable;
    Inc(LCount);
  end;
  SetLength(LList, LCount);

  // idList::Sort is a qsort: names that differ only in case have no defined order, here the order of creation is kept
  TArray.Sort<TCVar>(LList, TComparer<TCVar>.Construct(
    function(const ALeft, ARight: TCVar): Integer
    begin
      Result := TIdStrings.Icmp(ALeft.Name, ARight.Name);
    end));

  case LShow of
    shValue:
      for LIndex := 0 to High(LList) do
        Print(PadRight(LList[LIndex].Name, NAME_WIDTH) + ' ^7"' + string(LList[LIndex].GetString) + '"'#10);
    shDescription:
      begin
        LIndent := #10 + StringOfChar(' ', NUM_NAME_CHARS);
        for LIndex := 0 to High(LList) do
          Print(PadRight(LList[LIndex].Name, NAME_WIDTH) + ' ^7' +
            string(CreateColumn(LList[LIndex].Description, NUM_DESCRIPTION_CHARS, AnsiString(LIndent))) + #10);
      end;
    shType:
      for LIndex := 0 to High(LList) do
      begin
        LVariable := LList[LIndex];
        LLine := PadRight(LVariable.Name, NAME_WIDTH) + ' ';
        if (LVariable.Flags and CVAR_BOOL) <> 0 then
          Print(LLine + '^5bool'#10)
        else if (LVariable.Flags and CVAR_INTEGER) <> 0 then
        begin
          if LVariable.ValueMin < LVariable.ValueMax then
            Print(LLine + '^2int ^7[' + IntToStr(Trunc(LVariable.ValueMin)) + ', ' + IntToStr(Trunc(LVariable.ValueMax)) +
              ']'#10)
          else
            Print(LLine + '^2int'#10);
        end
        else if (LVariable.Flags and CVAR_FLOAT) <> 0 then
        begin
          if LVariable.ValueMin < LVariable.ValueMax then
            Print(LLine + '^1float ^7[' + string(TIdStrings.FloatToText(LVariable.ValueMin)) + ', ' +
              string(TIdStrings.FloatToText(LVariable.ValueMax)) + ']'#10)
          else
            Print(LLine + '^1float'#10);
        end
        else if Length(LVariable.ValueStrings) > 0 then
        begin
          Print(LLine + '^7string ^7[');
          for LStringIndex := 0 to High(LVariable.ValueStrings) do
            if LStringIndex > 0 then
              Print('^7, ' + string(LVariable.ValueStrings[LStringIndex]))
            else
              Print('^7' + string(LVariable.ValueStrings[LStringIndex]));
          Print('^7]'#10);
        end
        else
          Print(LLine + '^7string'#10);
      end;
    shFlags:
      for LIndex := 0 to High(LList) do
      begin
        LVariable := LList[LIndex];
        LLine := PadRight(LVariable.Name, NAME_WIDTH) + ' ';
        if (LVariable.Flags and CVAR_BOOL) <> 0 then
          LLine := LLine + '^5B '
        else if (LVariable.Flags and CVAR_INTEGER) <> 0 then
          LLine := LLine + '^2I '
        else if (LVariable.Flags and CVAR_FLOAT) <> 0 then
          LLine := LLine + '^1F '
        else
          LLine := LLine + '^7S ';
        if (LVariable.Flags and CVAR_SYSTEM) <> 0 then
          LLine := LLine + '^7SYS  '
        else if (LVariable.Flags and CVAR_RENDERER) <> 0 then
          LLine := LLine + '^7RNDR '
        else if (LVariable.Flags and CVAR_SOUND) <> 0 then
          LLine := LLine + '^7SND  '
        else if (LVariable.Flags and CVAR_GUI) <> 0 then
          LLine := LLine + '^7GUI  '
        else if (LVariable.Flags and CVAR_GAME) <> 0 then
          LLine := LLine + '^7GAME '
        else if (LVariable.Flags and CVAR_TOOL) <> 0 then
          LLine := LLine + '^7TOOL '
        else
          LLine := LLine + '^7     ';
        LLine := LLine + Mark(LVariable.Flags, CVAR_USERINFO, 'UI ', '   ') +
          Mark(LVariable.Flags, CVAR_SERVERINFO, 'SI ', '   ') +
          Mark(LVariable.Flags, CVAR_STATIC, 'ST ', '   ') +
          Mark(LVariable.Flags, CVAR_CHEAT, 'CH ', '   ') +
          Mark(LVariable.Flags, CVAR_INIT, 'IN ', '   ') +
          Mark(LVariable.Flags, CVAR_ROM, 'RO ', '   ') +
          Mark(LVariable.Flags, CVAR_ARCHIVE, 'AR ', '   ') +
          Mark(LVariable.Flags, CVAR_MODIFIED, 'MO ', '   ') + #10;
        Print(LLine);
      end;
  end;

  Print(#10 + IntToStr(Length(LList)) + ' cvars listed'#10#10);
  Print('listCvar [search string]          = list cvar values'#10 +
    'listCvar -help [search string]    = list cvar descriptions'#10 +
    'listCvar -type [search string]    = list cvar types'#10 +
    'listCvar -flags [search string]   = list cvar flags'#10);
end;

end.
