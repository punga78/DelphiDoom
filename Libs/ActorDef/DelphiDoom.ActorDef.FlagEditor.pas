{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the removal of a flag from a list of flags   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.FlagEditor;

interface

uses
  DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   Takes a flag off a list of words (the old RemoveFlag of the parser). It keeps the old
  ///   rules: the words of the result are in upper case, each one followed by a space, and a
  ///   word that starts with M goes only if it is one of the names with the MF_ prefixes. That
  ///   is why -MISSILE does not take off a MISSILE that was added without prefix, while
  ///   -MF_MISSILE takes off MF_MISSILE
  /// </summary>
  TActorDefFlagEditor = class
  public
    /// <param name="AHasFlags2">The game has the MF2_ list: MF2_ is a prefix of the flag to remove</param>
    class function Remove(const AFlags, AFlag: string; AHasFlags2: Boolean;
      const ALog: ILog): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings, DelphiDoom.Scanner.Scanner;

{ TActorDefFlagEditor }

class function TActorDefFlagEditor.Remove(const AFlags, AFlag: string; AHasFlags2: Boolean;
  const ALog: ILog): string;
var
  LScanner: TScriptScanner;
  LCheck: string;
  LItem: string;
begin
  Result := '';
  LCheck := TScannerStrings.UpperAscii(AFlag);
  if LCheck = '' then
    Exit(AFlags);
  if LCheck[1] = 'M' then
  begin
    if LCheck.StartsWith('MF6_EX_') then
      LCheck := Copy(LCheck, 8, MaxInt)
    else if LCheck.StartsWith('MF5_EX_') then
      LCheck := Copy(LCheck, 8, MaxInt)
    else if LCheck.StartsWith('MF4_EX_') then
      LCheck := Copy(LCheck, 8, MaxInt)
    else if LCheck.StartsWith('MF3_EX_') then
      LCheck := Copy(LCheck, 8, MaxInt)
    else if LCheck.StartsWith('MF2_EX_') then
      LCheck := Copy(LCheck, 8, MaxInt)
    else if LCheck.StartsWith('MF_EX_') then
      LCheck := Copy(LCheck, 7, MaxInt)
    else if AHasFlags2 and LCheck.StartsWith('MF2_') then
      LCheck := Copy(LCheck, 5, MaxInt)
    else if LCheck.StartsWith('MF_') then
      LCheck := Copy(LCheck, 4, MaxInt);
  end;
  LScanner := TScriptScanner.Create(AFlags, ALog);
  try
    while LScanner.GetString do
    begin
      LItem := TScannerStrings.UpperAscii(LScanner.AsString);
      // the old code read the first character of an empty word as a #0
      if (LItem <> LCheck) and ((LItem = '') or (LItem[1] <> 'M')) then
        Result := Result + LItem + ' '
      else if (LItem <> 'MF_' + LCheck) and
        (LItem <> 'MF2_' + LCheck) and
        (LItem <> 'MF_EX_' + LCheck) and
        (LItem <> 'MF2_EX_' + LCheck) and
        (LItem <> 'MF3_EX_' + LCheck) and
        (LItem <> 'MF4_EX_' + LCheck) and
        (LItem <> 'MF5_EX_' + LCheck) and
        (LItem <> 'MF6_EX_' + LCheck) then
        Result := Result + LItem + ' ';
    end;
  finally
    LScanner.Free;
  end;
end;

end.
