{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - things found by name and by inheritance   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.MobjLookup;

interface

uses
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.MobjAliases;

type
  /// <summary>
  ///   The searches on the table of the things that the scripts and the patches use: by name
  ///   (the old Info_GetMobjNumForName) and the first ancestor (Info_GetInheritance)
  /// </summary>
  TInfoMobjLookup = class sealed
  strict private
    FSource: IInfoMobjSource;
    FAliases: TInfoMobjAliases;
    FNameSize: Integer;
    function Truncated(const AName: string): string;
  public
    /// <summary>
    ///   ASource is the table; AAliases (not owned, may be nil: then no alias is found) the
    ///   other names; ANameSize the longest name a thing can have (MOBJINFONAMESIZE of the game)
    /// </summary>
    constructor Create(const ASource: IInfoMobjSource; const AAliases: TInfoMobjAliases;
      const ANameSize: Integer);
    /// <summary>
    ///   The thing with the name, or with the number written as the name; -1 if none. The last
    ///   thing of the table wins; blanks and case do not count; then the aliases are looked at
    /// </summary>
    function NumForName(const AName: string): Integer;
    /// <summary>
    ///   The thing at the end of the chain of "inherits from" that starts at AIndex, or AIndex if
    ///   it inherits from nothing or the chain does not end (a thing outside the table counts as
    ///   the end)
    /// </summary>
    function RootOf(const AIndex: Integer): Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TInfoMobjLookup }

constructor TInfoMobjLookup.Create(const ASource: IInfoMobjSource; const AAliases: TInfoMobjAliases;
  const ANameSize: Integer);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
  FAliases := AAliases;
  FNameSize := ANameSize;
end;

function TInfoMobjLookup.Truncated(const AName: string): string;
begin
  Result := AName;
  if Length(Result) > FNameSize then
    SetLength(Result, FNameSize);
end;

function TInfoMobjLookup.NumForName(const AName: string): Integer;
var
  LName: string;
  LIndex: Integer;
  LCount: Integer;
begin
  if (AName = '') or (AName = '-1') then
    Exit(-1);

  LCount := FSource.Count;
  Result := TScannerStrings.ToInteger(AName, -1);
  if (Result >= 0) and (Result < LCount) and (IntToStr(Result) = AName) then
    Exit;

  LName := Truncated(TScannerStrings.UpperAscii(TScannerStrings.Trim(AName)));
  for LIndex := LCount - 1 downto 0 do
    if TScannerStrings.UpperAscii(TScannerStrings.Trim(FSource.Name(LIndex))) = LName then
      Exit(LIndex);

  LName := Truncated(TScannerStrings.UpperAscii(TScannerStrings.Trim(AName)).Replace(' ', ''));
  for LIndex := LCount - 1 downto 0 do
    if TScannerStrings.UpperAscii(TScannerStrings.Trim(FSource.Name(LIndex))).Replace(' ', '') = LName then
      Exit(LIndex);

  if Assigned(FAliases) then
    Result := FAliases.Find(LName, LCount)
  else
    Result := -1;
end;

function TInfoMobjLookup.RootOf(const AIndex: Integer): Integer;
var
  LCurrent: Integer;
  LLoops: Integer;
  LParent: Integer;
begin
  Result := FSource.InheritsFrom(AIndex);
  if Result <> -1 then
  begin
    LCurrent := AIndex;
    LLoops := 0;
    while True do
    begin
      LCurrent := FSource.InheritsFrom(LCurrent);
      if (LCurrent < 0) or (LCurrent >= FSource.Count) then
      begin
        Result := -1;
        Break;
      end;
      LParent := FSource.InheritsFrom(LCurrent);
      if LParent = -1 then
        Exit;
      Result := LParent;
      Inc(LLoops);
      if LLoops > FSource.Count then
      begin
        Result := -1;
        Break;
      end;
    end;
  end;

  if Result = -1 then
    Result := AIndex;
end;

end.
