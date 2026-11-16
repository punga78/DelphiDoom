{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the other names of the things             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.MobjAliases;

interface

uses
  System.Generics.Collections;

type
  /// <summary>
  ///   The names that a script gives to a thing besides its own ("alias=number", upper case,
  ///   without blanks); the one added last is found first
  /// </summary>
  TInfoMobjAliases = class sealed
  strict private
    FEntries: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds the name for the thing, if the same pair is not there already</summary>
    procedure Add(const AAlias: string; const AIndex: Integer);
    /// <summary>
    ///   The thing a name stands for: DEH_ACTOR_n is the thing n if there are that many things
    ///   (ACount), otherwise the names that were added; -1 if none. The name is read upper case
    ///   and without blanks
    /// </summary>
    function Find(const AName: string; const ACount: Integer): Integer;
    function Count: Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Info.Range,
  DelphiDoom.Scanner.Strings;

const
  DehActorPrefix = 'DEH_ACTOR_';

function NormalizeAlias(const AText: string): string;
begin
  Result := TScannerStrings.UpperAscii(AText.Replace(' ', ''));
end;

{ TInfoMobjAliases }

constructor TInfoMobjAliases.Create;
begin
  inherited Create;
  FEntries := TList<string>.Create;
end;

destructor TInfoMobjAliases.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TInfoMobjAliases.Add(const AAlias: string; const AIndex: Integer);
var
  LEntry: string;
  LExisting: string;
begin
  LEntry := NormalizeAlias(AAlias) + '=' + IntToStr(AIndex);
  for LExisting in FEntries do
    if AnsiCompareText(LExisting, LEntry) = 0 then
      Exit;
  FEntries.Add(LEntry);
end;

function TInfoMobjAliases.Find(const AName: string; const ACount: Integer): Integer;
var
  LCheck: string;
  LNumber: string;
  LIndex: Integer;
  LFirst: string;
  LSecond: string;
begin
  LCheck := NormalizeAlias(AName);
  if LCheck.StartsWith(DehActorPrefix) then
  begin
    LNumber := Copy(LCheck, Length(DehActorPrefix) + 1, Length(LCheck) - Length(DehActorPrefix));
    if TScannerStrings.IsDigits(LNumber) then
    begin
      Result := TScannerStrings.ToInteger(LNumber);
      if TInfoRange.Contains(Result, 0, ACount - 1) then
        Exit;
    end;
  end;

  LCheck := LCheck + '=';
  for LIndex := FEntries.Count - 1 downto 0 do
    if FEntries[LIndex].StartsWith(LCheck) then
    begin
      TScannerStrings.SplitAtFirst(FEntries[LIndex], LFirst, LSecond, '=');
      Exit(TScannerStrings.ToInteger(LSecond));
    end;
  Result := -1;
end;

function TInfoMobjAliases.Count: Integer;
begin
  Result := FEntries.Count;
end;

end.
