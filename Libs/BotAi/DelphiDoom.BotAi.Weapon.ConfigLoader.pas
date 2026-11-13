{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponConfigLoader, LoadWeaponConfig               }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): LoadWeaponConfig of }
{  code\botlib\be_ai_weap.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.ConfigLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Chat.Source,
  DelphiDoom.BotAi.Weapon.Config, DelphiDoom.BotAi.Weapon.Definitions;

type
  /// <summary>Reads the weapon file (<c>weaponinfo { ... } projectileinfo { ... }</c>)</summary>
  TBotWeaponConfigLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVarStore;
    FDefinitions: TBotWeaponDefinitions;
    function ReadDefinitions(const ASource: TBotChatSource; const AConfig: TBotWeaponConfig; const APath: AnsiString;
      const AMaxWeapons, AMaxProjectiles: Integer): Boolean;
    function FixUp(const AConfig: TBotWeaponConfig; const APath: AnsiString): Boolean;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVarStore;
      const ADefinitions: TBotWeaponDefinitions);
    /// <summary>
    ///   LoadWeaponConfig: <c>max_weaponinfo</c> and <c>max_projectileinfo</c> (32 if missing or negative; the
    ///   negative value is reset) are the sizes of the tables. nil, with the reason printed, if the file or a
    ///   definition is wrong.
    /// </summary>
    function Load(const AFileName: AnsiString): TBotWeaponConfig;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Struct.Reader,
  DelphiDoom.BotAi.Text.CFormat, DelphiDoom.BotAi.Weapon.Types;

{ TBotWeaponConfigLoader }

constructor TBotWeaponConfigLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const ADefinitions: TBotWeaponDefinitions);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FDefinitions := ADefinitions;
end;

function TBotWeaponConfigLoader.ReadDefinitions(const ASource: TBotChatSource; const AConfig: TBotWeaponConfig;
  const APath: AnsiString; const AMaxWeapons, AMaxProjectiles: Integer): Boolean;
var
  LToken: TIdToken;
  LWeaponBytes: TBytes;
  LProjectileBytes: TBytes;
  LWeapon: TBotWeaponInfo;
begin
  Result := False;
  while ASource.ReadToken(LToken) do
  begin
    if TBotChatSource.CText(LToken) = 'weaponinfo' then
    begin
      SetLength(LWeaponBytes, 0);
      SetLength(LWeaponBytes, SizeOf(TBotWeaponInfo));
      if not TBotStructReader.ReadStructure(ASource, FDefinitions.Weapon, LWeaponBytes) then
        Exit;
      Move(LWeaponBytes[0], LWeapon, SizeOf(TBotWeaponInfo));
      if (LWeapon.Number < 0) or (LWeapon.Number >= AMaxWeapons) then
      begin
        FImport.Print(PRT_ERROR, 'weapon info number ' + TBotCFormat.Int(LWeapon.Number) + ' out of range in ' + APath + #10);
        Exit;
      end;
      AConfig.Weapons[LWeapon.Number] := LWeapon;
      AConfig.Weapons[LWeapon.Number].Valid := 1;
    end
    else if TBotChatSource.CText(LToken) = 'projectileinfo' then
    begin
      if AConfig.NumProjectiles >= AMaxProjectiles then
      begin
        FImport.Print(PRT_ERROR, 'more than ' + TBotCFormat.Int(AMaxProjectiles) + ' projectiles defined in ' + APath + #10);
        Exit;
      end;
      SetLength(LProjectileBytes, 0);
      SetLength(LProjectileBytes, SizeOf(TBotProjectileInfo));
      if not TBotStructReader.ReadStructure(ASource, FDefinitions.Projectile, LProjectileBytes) then
        Exit;
      Move(LProjectileBytes[0], AConfig.Projectiles[AConfig.NumProjectiles], SizeOf(TBotProjectileInfo));
      Inc(AConfig.NumProjectiles);
    end
    else
    begin
      FImport.Print(PRT_ERROR, 'unknown definition ' + TBotChatSource.CText(LToken) + ' in ' + APath + #10);
      Exit;
    end;
  end;
  Result := True;
end;

function TBotWeaponConfigLoader.FixUp(const AConfig: TBotWeaponConfig; const APath: AnsiString): Boolean;
var
  LIndex: Integer;
  LProjectile: Integer;
begin
  Result := False;
  for LIndex := 0 to AConfig.NumWeapons - 1 do
  begin
    if AConfig.Weapons[LIndex].Valid = 0 then
      Continue;
    if AConfig.Weapons[LIndex].Name[0] = #0 then
    begin
      FImport.Print(PRT_ERROR, 'weapon ' + TBotCFormat.Int(LIndex) + ' has no name in ' + APath + #10);
      Exit;
    end;
    if AConfig.Weapons[LIndex].Projectile[0] = #0 then
    begin
      FImport.Print(PRT_ERROR, 'weapon ' + BotFieldText(AConfig.Weapons[LIndex].Name) + ' has no projectile in ' +
        APath + #10);
      Exit;
    end;
    // find the projectile info and copy it to the weapon info
    LProjectile := 0;
    while LProjectile < AConfig.NumProjectiles do
    begin
      if BotFieldText(AConfig.Projectiles[LProjectile].Name) = BotFieldText(AConfig.Weapons[LIndex].Projectile) then
      begin
        AConfig.Weapons[LIndex].Proj := AConfig.Projectiles[LProjectile];
        Break;
      end;
      Inc(LProjectile);
    end;
    if LProjectile = AConfig.NumProjectiles then
    begin
      FImport.Print(PRT_ERROR, 'weapon ' + BotFieldText(AConfig.Weapons[LIndex].Name) + ' uses undefined projectile in ' +
        APath + #10);
      Exit;
    end;
  end;
  Result := True;
end;

function TBotWeaponConfigLoader.Load(const AFileName: AnsiString): TBotWeaponConfig;
var
  LMaxWeapons: Integer;
  LMaxProjectiles: Integer;
  LSource: TBotChatSource;
  LRead: Boolean;
begin
  LMaxWeapons := Trunc(FLibVars.GetValueOrCreate('max_weaponinfo', '32'));
  if LMaxWeapons < 0 then
  begin
    FImport.Print(PRT_ERROR, 'max_weaponinfo = ' + TBotCFormat.Int(LMaxWeapons) + #10);
    LMaxWeapons := 32;
    FLibVars.SetText('max_weaponinfo', '32');
  end;
  LMaxProjectiles := Trunc(FLibVars.GetValueOrCreate('max_projectileinfo', '32'));
  if LMaxProjectiles < 0 then
  begin
    FImport.Print(PRT_ERROR, 'max_projectileinfo = ' + TBotCFormat.Int(LMaxProjectiles) + #10);
    LMaxProjectiles := 32;
    FLibVars.SetText('max_projectileinfo', '32');
  end;
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if not Assigned(LSource) then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    Exit(nil);
  end;
  // initialize weapon config
  Result := TBotWeaponConfig.Create(LMaxWeapons, LMaxProjectiles);
  try
    // the structure reader catches the errors of the source (SourceError), which the original also prints
    LRead := ReadDefinitions(LSource, Result, AFileName, LMaxWeapons, LMaxProjectiles);
  finally
    LSource.Free;
  end;
  // fix up weapons
  if LRead then
    LRead := FixUp(Result, AFileName);
  if not LRead then
  begin
    FreeAndNil(Result);
    Exit;
  end;
  if Result.NumWeapons = 0 then
    FImport.Print(PRT_WARNING, 'no weapon info loaded'#10);
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
end;

end.
