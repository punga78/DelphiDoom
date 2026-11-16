{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the number of a song from its name              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.MusicNumberResolver;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>
  ///   S_GetMusicNumForName of sounds.pas: a number as text is a song of the table; a name
  ///   is searched (with or without the "D_" prefix) and, if it is not there, added to the
  ///   table with the number of its lump. The problems are warnings and the song 0
  /// </summary>
  TMusicNumberResolver = class(TInterfacedObject, IMusicNumberResolver)
  strict private
    FTable: IMusicTable;
    FFinder: TSoundLumpFinder;
    FLog: ILog;
  public
    /// <summary>EArgumentNilException if a dependency is missing</summary>
    constructor Create(const ATable: IMusicTable; const AFinder: TSoundLumpFinder;
      const ALog: ILog);
    function NumberForName(const AName: string): Integer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Audio.SoundNames;

const
  SNoMusicName = 'S_GetMusicNumForName(): No music name specified, using default'#13#10;
  SNoSoundName = 'S_GetMusicNumForName(): No sound name specified, using default'#13#10;
  SMusicLimit = 'S_GetMusicNumForName(): Can not add "%s" music, limit of %d music lumps exceeded'#13#10;

{ TMusicNumberResolver }

constructor TMusicNumberResolver.Create(const ATable: IMusicTable;
  const AFinder: TSoundLumpFinder; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ATable) then
    raise EArgumentNilException.Create('ATable');
  if not Assigned(AFinder) then
    raise EArgumentNilException.Create('AFinder');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FTable := ATable;
  FFinder := AFinder;
  FLog := ALog;
end;

function TMusicNumberResolver.NumberForName(const AName: string): Integer;
var
  LName: string;
  LLump: Integer;
begin
  if TSoundNames.IsNumber(AName, Result) and (Result >= 0) and (Result < FTable.Count) then
    Exit;

  if AName = '' then
  begin
    FLog.Warning(SNoMusicName);
    Result := 0;
    Exit;
  end;

  LName := TSoundNames.Upper(AName);
  Result := FTable.FindByName(LName);
  if Result >= 0 then
    Exit;

  // not found: a new song, if the table has room
  if FTable.Count >= FTable.Capacity - 1 then
  begin
    FLog.Warning(Format(SMusicLimit, [AName, FTable.Count]));
    Result := 0;
    Exit;
  end;

  if TSoundNames.HasPrefix('D_', LName) then
    LName := Copy(LName, 3, Length(LName) - 2);
  if LName = '' then // normally this does not happen
  begin
    FLog.Warning(SNoSoundName);
    Result := 0;
    Exit;
  end;

  Result := FTable.Count;
  LLump := FFinder('D_' + LName);
  if LLump < 0 then
    LLump := FFinder(LName);
  FTable.Define(Result, LName, LLump);
  FTable.Count := Result + 1;
end;

end.
