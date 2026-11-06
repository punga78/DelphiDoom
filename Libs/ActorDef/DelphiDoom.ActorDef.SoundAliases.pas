{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the aliases of the sounds                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.SoundAliases;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Intf;

type
  /// <summary>
  ///   The names that SNDINFO gives to the sounds (the old SC_SoundAlias). A name of the
  ///   definitions is an alias, the name of a lump of 8 characters or less, or $random followed by
  ///   one of those. The aliases are kept as the lines NAME=VALUE that the old list had
  /// </summary>
  TActorDefSoundAliases = class(TInterfacedObject, IActorDefSoundResolver, IActorDefSoundAliasTable)
  private
    FLog: ILog;
    FLines: TArray<string>;
    function IndexOfName(const AName: string): Integer;
    function ValueOf(const AName: string): string;
  public
    constructor Create(const ALog: ILog);
    /// <summary>The text of SNDINFO is read as upper case with the quotes and the braces as spaces and \ as /</summary>
    class function Normalize(const AText: string): string; static;
    procedure Add(const AName, AValue: string);
    function Resolve(const ASound: string): string;
    /// <summary>The lines NAME=VALUE, in the order in which they were added</summary>
    function Lines: TArray<string>;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings, DelphiDoom.ActorDef.Text;

{ TActorDefSoundAliases }

constructor TActorDefSoundAliases.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

class function TActorDefSoundAliases.Normalize(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
  begin
    if Result[LIndex] = '\' then
      Result[LIndex] := '/'
    else if CharInSet(Result[LIndex], ['"', '{', '}']) then
      Result[LIndex] := ' '
    else if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
  end;
end;

procedure TActorDefSoundAliases.Add(const AName, AValue: string);
begin
  SetLength(FLines, Length(FLines) + 1);
  FLines[High(FLines)] := AName + '=' + AValue;
end;

function TActorDefSoundAliases.Lines: TArray<string>;
begin
  Result := FLines;
end;

function TActorDefSoundAliases.IndexOfName(const AName: string): Integer;
var
  LPrefix: string;
begin
  LPrefix := AName + '=';
  for Result := 0 to High(FLines) do
    if Copy(FLines[Result], 1, Length(LPrefix)) = LPrefix then
      Exit;
  Result := -1;
end;

function TActorDefSoundAliases.ValueOf(const AName: string): string;
var
  LIndex: Integer;
begin
  LIndex := IndexOfName(AName);
  if LIndex >= 0 then
    Result := Copy(FLines[LIndex], Length(AName) + 2, MaxInt)
  else
    Result := '';
end;

function TActorDefSoundAliases.Resolve(const ASound: string): string;
var
  LCheck: string;
  LPosition: Integer;
begin
  if ASound = '' then
    Exit('0');

  LCheck := Normalize(ASound);
  if TActorDefText.FirstWord(LCheck) = '$RANDOM' then
  begin
    LPosition := Pos(' ', LCheck);
    if LPosition = 0 then
      LCheck := ''
    else
      LCheck := TScannerStrings.Trim(Copy(LCheck, LPosition + 1, MaxInt));
  end;

  if IndexOfName(LCheck) >= 0 then
  begin
    Result := ValueOf(LCheck);
    if (Length(Result) > 8) or (Pos('/', Result) > 0) then
      if IndexOfName(Result) >= 0 then
        Result := ValueOf(Result);
    if (Length(Result) > 8) or (Pos('/', Result) > 0) then
    begin
      if Assigned(FLog) then
        FLog.Warning(Format('SC_SoundAlias(): Sound %s has length %d > 8.'#13#10,
          [Result, Length(Result)]));
      Result := '0';
    end;
    Exit;
  end;

  if Pos('/', ASound) > 0 then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('SC_SoundAlias(): Sound %s does not have a corresponding alias.'#13#10,
        [ASound]));
    Exit('0');
  end;

  if Length(ASound) > 8 then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('SC_SoundAlias(): Sound %s has length %d > 8.'#13#10,
        [ASound, Length(ASound)]));
    Exit('0');
  end;

  Result := ASound;
end;

end.
