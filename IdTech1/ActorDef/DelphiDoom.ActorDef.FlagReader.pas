{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the flags of a definition                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.FlagReader;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Scanner, DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   Tells if the current word of the scanner is a flag of one of the lists of the engine, and
  ///   adds it to (or takes it off) the list of words of the definition. A word can be written
  ///   as +FLAG, MF_FLAG, +MF_FLAG ... (the prefixes depend on the list), and some old names are
  ///   aliases of the new ones (CANPASS is PASSMOBJ ...)
  /// </summary>
  TActorDefFlagReader = class
  private
    FScanner: TScriptScanner;
    FCatalog: IActorDefFlagCatalog;
    FProfile: TActorDefProfile;
    FLog: ILog;
    procedure AddFlagAliases;
    procedure PrefixesOf(ACategory: TActorDefFlagCategory; out AStrip, AMatch: TArray<string>);
    function StripPrefix(const AStrip: TArray<string>; const AFlag: string): string;
    function MatchVariants(const AMatch: TArray<string>; const AFlag: string): Boolean;
    function StartsWithMinus: Boolean;
  public
    constructor Create(AScanner: TScriptScanner; const ACatalog: IActorDefFlagCatalog;
      const AProfile: TActorDefProfile; const ALog: ILog);
    /// <summary>The current word adds a flag of the list: it is appended to AFlags</summary>
    function TryAdd(ACategory: TActorDefFlagCategory; var AFlags: string): Boolean;
    /// <summary>The current word is -FLAG: the flag is taken off AFlags</summary>
    function TryRemove(ACategory: TActorDefFlagCategory; var AFlags: string): Boolean;
    /// <summary>
    ///   The flags of a weapon. The old code looked for the word in the flags of the actors
    ///   (and not in the ones of the weapons), as many as the weapon flags: that is kept
    /// </summary>
    function TryAddWeapon(var AFlags: string): Boolean;
    function TryRemoveWeapon(var AFlags: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.FlagEditor;

const
  SEPARATOR = '|';

{ TActorDefFlagReader }

constructor TActorDefFlagReader.Create(AScanner: TScriptScanner; const ACatalog: IActorDefFlagCatalog;
  const AProfile: TActorDefProfile; const ALog: ILog);
begin
  inherited Create;
  FScanner := AScanner;
  FCatalog := ACatalog;
  FProfile := AProfile;
  FLog := ALog;
end;

procedure TActorDefFlagReader.AddFlagAliases;
begin
  FScanner.AddAlias('CANPASS', 'PASSMOBJ');
  FScanner.AddAlias('+CANPASS', 'PASSMOBJ');
  FScanner.AddAlias('-CANPASS', '-PASSMOBJ');
  FScanner.AddAlias('DONTSPLASH', 'NOHITFLOOR');
  FScanner.AddAlias('+DONTSPLASH', 'NOHITFLOOR');
  FScanner.AddAlias('-DONTSPLASH', '-NOHITFLOOR');
  FScanner.AddAlias('FRIENDLY', 'FRIEND');
  FScanner.AddAlias('+FRIENDLY', 'FRIEND');
  FScanner.AddAlias('-FRIENDLY', '-FRIEND');
  FScanner.AddAlias('ACTIVATEIMPACT', 'IMPACT');
  FScanner.AddAlias('+ACTIVATEIMPACT', '+IMPACT');
  FScanner.AddAlias('-ACTIVATEIMPACT', '-IMPACT');
  FScanner.AddAlias('CANPUSHWALLS', 'PUSHWALL');
  FScanner.AddAlias('+CANPUSHWALLS', '+PUSHWALL');
  FScanner.AddAlias('-CANPUSHWALLS', '-PUSHWALL');
  FScanner.AddAlias('ACTIVATEPCROSS', 'PCROSS');
  FScanner.AddAlias('+ACTIVATEPCROSS', '+PCROSS');
  FScanner.AddAlias('-ACTIVATEPCROSS', '-PCROSS');
  FScanner.AddAlias('ACTIVATEMCROSS', 'MCROSS');
  FScanner.AddAlias('+ACTIVATEMCROSS', '+MCROSS');
  FScanner.AddAlias('-ACTIVATEMCROSS', '-MCROSS');
end;

procedure TActorDefFlagReader.PrefixesOf(ACategory: TActorDefFlagCategory; out AStrip,
  AMatch: TArray<string>);
var
  LStrip: string;
  LMatch: string;
begin
  // AStrip: the prefixes that the names of the engine lose, in order; AMatch: the ways to write
  // a flag, * is the flag
  case ACategory of
    TActorDefFlagCategory.Flags:
      begin
        LStrip := 'MF_';
        LMatch := '*|+*|MF_*|+MF_*';
      end;
    TActorDefFlagCategory.Flags2:
      begin
        LStrip := 'MF2_|MF_';
        LMatch := '*|+*|MF_*|MF2_*|+MF_*|+MF2_*';
      end;
    TActorDefFlagCategory.FlagsEx:
      begin
        LStrip := 'MF_EX_|MF_';
        LMatch := '*|+*|MF_*|MF_EX_*|+MF_*|+MF_EX_*';
      end;
    TActorDefFlagCategory.Flags2Ex:
      begin
        LStrip := 'MF2_EX_|MF_EX_|MF2_|MF_';
        LMatch := '*|+*|MF2_*|MF2_EX_*|+MF2_*|+MF2_EX_*';
      end;
    TActorDefFlagCategory.Flags3Ex:
      begin
        LStrip := 'MF3_EX_|MF2_EX_|MF_EX_|MF2_|MF_';
        LMatch := '*|+*|MF3_*|MF3_EX_*|+MF3_*|+MF3_EX_*';
      end;
    TActorDefFlagCategory.Flags4Ex:
      begin
        LStrip := 'MF4_EX_|MF3_EX_|MF2_EX_|MF_EX_|MF2_|MF_';
        LMatch := '*|+*|MF4_*|MF4_EX_*|+MF4_*|+MF4_EX_*';
      end;
    TActorDefFlagCategory.Flags5Ex:
      begin
        LStrip := 'MF5_EX_|MF4_EX_|MF3_EX_|MF2_EX_|MF_EX_|MF2_|MF_';
        LMatch := '*|+*|MF5_*|MF5_EX_*|+MF5_*|+MF5_EX_*';
      end;
  else
    begin
      LStrip := 'MF6_EX_|MF5_EX_|MF4_EX_|MF3_EX_|MF2_EX_|MF_EX_|MF2_|MF_';
      LMatch := '*|+*|MF6_*|MF6_EX_*|+MF6_*|+MF6_EX_*';
    end;
  end;
  AStrip := LStrip.Split([SEPARATOR]);
  AMatch := LMatch.Split([SEPARATOR]);
end;

function TActorDefFlagReader.StripPrefix(const AStrip: TArray<string>; const AFlag: string): string;
var
  LPrefix: string;
begin
  for LPrefix in AStrip do
    if AFlag.StartsWith(LPrefix) then
      Exit(Copy(AFlag, Length(LPrefix) + 1, MaxInt));
  Result := AFlag;
end;

function TActorDefFlagReader.MatchVariants(const AMatch: TArray<string>; const AFlag: string): Boolean;
var
  LTemplate: string;
begin
  AddFlagAliases;
  Result := False;
  for LTemplate in AMatch do
    if FScanner.MatchString(LTemplate.Replace('*', AFlag)) then
    begin
      Result := True;
      Break;
    end;
  FScanner.ClearAliases;
end;

function TActorDefFlagReader.StartsWithMinus: Boolean;
var
  LWord: string;
begin
  LWord := FScanner.AsString;
  Result := (LWord <> '') and (LWord[1] = '-');
end;

function TActorDefFlagReader.TryAdd(ACategory: TActorDefFlagCategory; var AFlags: string): Boolean;
var
  LStrip: TArray<string>;
  LMatch: TArray<string>;
  LList: TArray<string>;
  LFlag: string;
  LIndex: Integer;
begin
  PrefixesOf(ACategory, LStrip, LMatch);
  LList := FCatalog.Flags(ACategory);
  for LIndex := 0 to High(LList) do
  begin
    LFlag := StripPrefix(LStrip, LList[LIndex]);
    if MatchVariants(LMatch, LFlag) then
    begin
      AFlags := AFlags + LFlag + ' ';
      Exit(True);
    end;
  end;
  Result := False;
end;

function TActorDefFlagReader.TryRemove(ACategory: TActorDefFlagCategory; var AFlags: string): Boolean;
var
  LStrip: TArray<string>;
  LMatch: TArray<string>;
  LList: TArray<string>;
  LFlag: string;
  LIndex: Integer;
begin
  if not StartsWithMinus then
    Exit(False);
  PrefixesOf(ACategory, LStrip, LMatch);
  LList := FCatalog.Flags(ACategory);
  for LIndex := 0 to High(LList) do
  begin
    LFlag := StripPrefix(LStrip, LList[LIndex]);
    if MatchVariants(LMatch, '-' + LFlag) then
    begin
      AFlags := TActorDefFlagEditor.Remove(AFlags, LFlag, FProfile.HasFlags2, FLog);
      Exit(True);
    end;
  end;
  Result := False;
end;

function TActorDefFlagReader.TryAddWeapon(var AFlags: string): Boolean;
var
  LWeaponFlags: TArray<string>;
  LActorFlags: TArray<string>;
  LFlag: string;
  LIndex: Integer;
begin
  LWeaponFlags := FCatalog.Flags(TActorDefFlagCategory.Weapon);
  LActorFlags := FCatalog.Flags(TActorDefFlagCategory.Flags);
  for LIndex := 0 to High(LWeaponFlags) do
  begin
    // the old code read the name in the list of the actors
    if LIndex > High(LActorFlags) then
      Break;
    LFlag := LActorFlags[LIndex];
    if FScanner.MatchString(LFlag) or FScanner.MatchString('+' + LFlag) or
      FScanner.MatchString('WPF_' + LFlag) or FScanner.MatchString('+WPF_' + LFlag) then
    begin
      AFlags := AFlags + LFlag + ' ';
      Exit(True);
    end;
  end;
  Result := False;
end;

function TActorDefFlagReader.TryRemoveWeapon(var AFlags: string): Boolean;
var
  LWeaponFlags: TArray<string>;
  LFlag: string;
  LName: string;
  LIndex: Integer;
begin
  if not StartsWithMinus then
    Exit(False);
  LWeaponFlags := FCatalog.Flags(TActorDefFlagCategory.Weapon);
  for LIndex := 0 to High(LWeaponFlags) do
  begin
    LFlag := LWeaponFlags[LIndex];
    LName := '-' + LFlag;
    if FScanner.MatchString(LName) or FScanner.MatchString('+' + LName) or
      FScanner.MatchString('WPF_' + LName) or FScanner.MatchString('+WPF_' + LName) then
    begin
      AFlags := TActorDefFlagEditor.Remove(AFlags, LFlag, FProfile.HasFlags2, FLog);
      Exit(True);
    end;
  end;
  Result := False;
end;

end.
