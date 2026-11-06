{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the nodes of the command line                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.NodeListParser;

interface

uses
  System.SysUtils, DelphiDoom.Net.Types;

type
  /// <summary>
  ///   The hosts that follow "-net n" on the command line: "name" or ".1.2.3.4", each one
  ///   optionally followed by ":port"; the list ends at the first argument that starts with "-".
  ///   Reading the arguments themselves stays in the engine (M_CheckParm)
  /// </summary>
  TNetNodeListParser = class
  public
    /// <summary>The other nodes, node 1 first; AStart is the index of the first host in AArguments</summary>
    class function Parse(const AArguments: TArray<string>; AStart: Integer;
      ADefaultPort: Word): TArray<TNetNodeAddress>; static;
    /// <summary>The digits at the beginning of the text, as the atoi of the old code (0 if there are none)</summary>
    class function LeadingNumber(const AText: string): Integer; static;
  end;

implementation

{ TNetNodeListParser }

class function TNetNodeListParser.LeadingNumber(const AText: string): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
begin
  Result := 0;
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] = ' ') do
    Inc(LIndex);
  LNegative := (LIndex <= Length(AText)) and (AText[LIndex] = '-');
  if (LIndex <= Length(AText)) and ((AText[LIndex] = '-') or (AText[LIndex] = '+')) then
    Inc(LIndex);
  while (LIndex <= Length(AText)) and (AText[LIndex] >= '0') and (AText[LIndex] <= '9') do
  begin
    Result := Result * 10 + (Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  if LNegative then
    Result := -Result;
end;

class function TNetNodeListParser.Parse(const AArguments: TArray<string>; AStart: Integer;
  ADefaultPort: Word): TArray<TNetNodeAddress>;
var
  LIndex: Integer;
  LAddress: TNetNodeAddress;
  LList: TArray<TNetNodeAddress>;
begin
  SetLength(LList, 0);
  LIndex := AStart;
  while (LIndex <= High(AArguments)) and (AArguments[LIndex] <> '') and (AArguments[LIndex][1] <> '-') do
  begin
    LAddress := Default(TNetNodeAddress);
    if AArguments[LIndex][1] = '.' then
    begin
      LAddress.IsLiteral := True;
      LAddress.Host := Copy(AArguments[LIndex], 2, Length(AArguments[LIndex]) - 1);
    end
    else
      LAddress.Host := AArguments[LIndex];
    Inc(LIndex);
    if (LIndex <= High(AArguments)) and (AArguments[LIndex] <> '') and (AArguments[LIndex][1] = ':') then
    begin
      LAddress.Port := Word(LeadingNumber(Copy(AArguments[LIndex], 2, Length(AArguments[LIndex]) - 1)) and $FFFF);
      Inc(LIndex);
    end
    else
      LAddress.Port := ADefaultPort;
    SetLength(LList, Length(LList) + 1);
    LList[High(LList)] := LAddress;
  end;
  Result := LList;
end;

end.
