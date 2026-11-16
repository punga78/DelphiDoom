{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the names of the MBF21 groups             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.GroupNames;

interface

uses
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types;

type
  /// <summary>
  ///   The names of one kind of group of things (infighting, projectile, splash): a few names
  ///   with a fixed value, then the names that patches and scripts add, whose value is their
  ///   position in a list (the old Info_*GroupToString and Info_*GroupToInt)
  /// </summary>
  TInfoGroupNames = class sealed
  strict private
    FPrefix: string;
    FUnknownValue: Integer;
    FFixed: TArray<TInfoGroupName>;
    FList: IInfoNameList;
    FConsts: IInfoConstSink;
  public
    /// <summary>
    ///   APrefix starts every name ("IG_"). AUnknownValue is what a negative number is read as.
    ///   AFixed are the names with a value of their own, in the order they are tried. AList
    ///   holds the added names; AConsts is told about every name that ToValue adds
    /// </summary>
    constructor Create(const APrefix: string; const AUnknownValue: Integer;
      const AFixed: TArray<TInfoGroupName>; const AList: IInfoNameList; const AConsts: IInfoConstSink);
    /// <summary>The name of a value: the fixed name, the name in the list, or the number as a text</summary>
    function ToText(const AValue: Integer): string;
    /// <summary>
    ///   The value of a name (the prefix may be left out, the case does not count) or of a number
    ///   written as a text; a number not in the list is added as PREFIX + number
    /// </summary>
    function ToValue(const AText: string): Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Info.Range,
  DelphiDoom.Scanner.Strings;

{ TInfoGroupNames }

constructor TInfoGroupNames.Create(const APrefix: string; const AUnknownValue: Integer;
  const AFixed: TArray<TInfoGroupName>; const AList: IInfoNameList; const AConsts: IInfoConstSink);
begin
  inherited Create;
  if not Assigned(AList) then
    raise EArgumentNilException.Create('AList');
  if not Assigned(AConsts) then
    raise EArgumentNilException.Create('AConsts');
  FPrefix := APrefix;
  FUnknownValue := AUnknownValue;
  FFixed := AFixed;
  FList := AList;
  FConsts := AConsts;
end;

function TInfoGroupNames.ToText(const AValue: Integer): string;
var
  LFixed: TInfoGroupName;
begin
  for LFixed in FFixed do
    if LFixed.Value = AValue then
      Exit(LFixed.Name);
  if TInfoRange.Contains(AValue, 0, FList.Count - 1) then
    Result := FList.Name(AValue)
  else
    Result := IntToStr(AValue);
end;

function TInfoGroupNames.ToValue(const AText: string): Integer;
var
  LCheck: string;
  LFixed: TInfoGroupName;
begin
  LCheck := TScannerStrings.UpperAscii(AText);
  if not LCheck.StartsWith(FPrefix) then
    LCheck := FPrefix + LCheck;

  for LFixed in FFixed do
    if LFixed.Name = LCheck then
      Exit(LFixed.Value);

  Result := FList.IndexOf(LCheck);
  if Result >= 0 then
    Exit;

  Result := TScannerStrings.ToInteger(AText);
  if Result < 0 then
    Result := FUnknownValue
  else
  begin
    LCheck := FPrefix + IntToStr(Result);
    Result := FList.Add(LCheck);
    FConsts.AddConst(LCheck, Result);
  end;
end;

end.
