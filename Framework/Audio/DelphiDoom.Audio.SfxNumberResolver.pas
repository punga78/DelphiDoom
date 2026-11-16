{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the number of a sound from its name             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SfxNumberResolver;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>
  ///   S_GetSoundNumForName and S_GetSoundNameForNum of sounds.pas. A number as text is a
  ///   sound of the table (for the games with DEHEXTRA, also the slots "fre500".."fre699");
  ///   a name goes through the aliases of SNDINFO and is searched with and without the "DS"
  ///   prefix; if it is not there it takes an empty slot (those games) or is added to
  ///   the table. The problems are warnings and the default sound of the game. One instance
  ///   for the whole run: it remembers the first slot that may be empty
  /// </summary>
  TSfxNumberResolver = class(TInterfacedObject, ISfxNumberResolver)
  strict private
    FTable: ISfxTable;
    FAliases: TSoundNameResolver;
    FLog: ILog;
    // the empty slots below this one were taken (a unit variable of sounds.pas before)
    FFirstFreeSlot: Integer;
    function UseDefault: Integer;
  public
    /// <summary>EArgumentNilException if a dependency is missing</summary>
    constructor Create(const ATable: ISfxTable; const AAliases: TSoundNameResolver;
      const ALog: ILog);
    function NumberForName(const AName: string): Integer;
    function NameForNumber(ANumber: Integer): string;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Audio.SoundNames;

const
  SNoSoundName = 'S_GetSoundNumForName(): No sound name specified, using default'#13#10;
  SSoundLimit = 'S_GetSoundNumForName(): Can not add %s sound, limit of %d sounds exceeded'#13#10;
  DEHEXTRA_FIRST = 500;
  DEHEXTRA_LAST = 699;
  DEHEXTRA_PREFIX = 'fre';

{ TSfxNumberResolver }

constructor TSfxNumberResolver.Create(const ATable: ISfxTable; const AAliases: TSoundNameResolver;
  const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ATable) then
    raise EArgumentNilException.Create('ATable');
  if not Assigned(AAliases) then
    raise EArgumentNilException.Create('AAliases');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FTable := ATable;
  FAliases := AAliases;
  FLog := ALog;
  FFirstFreeSlot := 1;
end;

function TSfxNumberResolver.UseDefault: Integer;
begin
  Result := FTable.DefaultSfx;
end;

function TSfxNumberResolver.NumberForName(const AName: string): Integer;
var
  LIsNumber: Boolean;
  LName: string;
  LFree: Integer;
  LDehExtraName: string;
begin
  LIsNumber := TSoundNames.IsNumber(AName, Result);
  if FTable.HasDynamicSlots then
  begin
    if LIsNumber then
    begin
      if (Result >= 0) and (Result < FTable.Count) and (FTable.NameOf(Result) <> '') then
        Exit;

      // DEHEXTRA: a numbered slot that the patch declared
      if (Result >= DEHEXTRA_FIRST) and (Result <= DEHEXTRA_LAST) then
      begin
        LDehExtraName := DEHEXTRA_PREFIX + IntToStr(Result);
        if FTable.NameOf(Result) = LDehExtraName then
        begin
          if FTable.Count <= Result then
            FTable.Count := Result + 1;
          FTable.Define(Result, LDehExtraName, '');
          Exit;
        end;
      end;
    end;
  end
  else if (Result >= 0) and (Result < FTable.Count) and LIsNumber then
    Exit;

  if AName = '' then
  begin
    FLog.Warning(SNoSoundName);
    Result := UseDefault;
    Exit;
  end;

  LName := TSoundNames.Upper(FAliases(AName));
  Result := FTable.FindByName(LName);
  if Result >= 0 then
    Exit;

  if FTable.HasDynamicSlots then
  begin
    // not found: an empty slot, if there is one (the name keeps its "DS" prefix)
    LFree := FTable.FindEmptySlot(FFirstFreeSlot);
    if LFree >= 0 then
    begin
      Result := LFree;
      FFirstFreeSlot := LFree + 1;
      FTable.Define(Result, LName, '');
      Exit;
    end;
  end;

  // not found: a new sound, if the table has room
  if FTable.Count >= FTable.Capacity - 1 then
  begin
    FLog.Warning(Format(SSoundLimit, [AName, FTable.Count]));
    Result := UseDefault;
    Exit;
  end;

  if TSoundNames.HasPrefix('DS', LName) then
    LName := Copy(LName, 3, Length(LName) - 2);
  if LName = '' then // normally this does not happen
  begin
    FLog.Warning(SNoSoundName);
    Result := UseDefault;
    Exit;
  end;

  Result := FTable.Count;
  FTable.Define(Result, LName, AName);
  FTable.Count := Result + 1;
end;

function TSfxNumberResolver.NameForNumber(ANumber: Integer): string;
begin
  if (ANumber < 0) or (ANumber >= FTable.Count) then
    Result := ''
  else
    Result := TSoundNames.Upper(FTable.NameOf(ANumber));
end;

end.
