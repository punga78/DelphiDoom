{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the four games                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Games;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Intf;

type
  TUdmfGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>
  ///   What each game of the engine has for its maps: the bits of the flags of its things and of
  ///   its lines (they are the values of its doomdef and doomdata), the layout of its records. The
  ///   numbers are checked against the old converter by the tests
  /// </summary>
  TUdmfGames = class
  public
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TUdmfGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TUdmfGame): Boolean; static;
    /// <param name="ASounds">Gives the number of a sound by its name; nil for a game without sectors with sounds</param>
    class function CreateProfile(AGame: TUdmfGame; const ASounds: IUdmfSoundResolver): IUdmfProfile; static;
  end;

implementation

uses
  DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Profile, DelphiDoom.Udmf.ThingFormat.Vanilla,
  DelphiDoom.Udmf.ThingFormat.Hexen, DelphiDoom.Udmf.LineFormat.Vanilla,
  DelphiDoom.Udmf.LineFormat.Hexen, DelphiDoom.Udmf.SideFormat, DelphiDoom.Udmf.VertexFormat,
  DelphiDoom.Udmf.SectorFormat;

const
  GAME_NAMES: array[TUdmfGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');

  // the specials of the format of the maps start at 1, the ones of the games at 700
  VANILLA_TRANSLATION: TUdmfSpecialTranslation = (SpecialStart: 700; NormalAdd: 300);

function CommonThingFlags(AOnMidSector, ADoNotTriggerScripts, AFriend: Integer): TUdmfCommonThingFlags;
begin
  Result.OnMidSector := AOnMidSector;
  Result.DoNotTriggerScripts := ADoNotTriggerScripts;
  Result.Friend := AFriend;
end;

/// the flags that every game has, with the bits of the game for the ones that change
function LineFlags(ATriggerScripts, ANoClip, ABlockLand, ABlockPlayers, APassUse, ATransparent1,
  ATransparent2, AJumpOver, ABlockFloaters: Integer): TUdmfLineFlags;
begin
  Result.Blocking := 1;
  Result.BlockMonsters := 2;
  Result.TwoSided := 4;
  Result.DontPegTop := 8;
  Result.DontPegBottom := 16;
  Result.Secret := 32;
  Result.SoundBlock := 64;
  Result.DontDraw := 128;
  Result.TriggerScripts := ATriggerScripts;
  Result.NoClip := ANoClip;
  Result.BlockLandMonsters := ABlockLand;
  Result.BlockPlayers := ABlockPlayers;
  Result.PassUse := APassUse;
  Result.Transparent1 := ATransparent1;
  Result.Transparent2 := ATransparent2;
  Result.JumpOver := AJumpOver;
  Result.BlockFloaters := ABlockFloaters;
end;

function SectorLayout(AHasPanning, AHasSound: Boolean): TUdmfSectorLayout;
begin
  Result.HasPanning := AHasPanning;
  Result.HasSound := AHasSound;
end;

function HexenThingFlags: TUdmfHexenThingFlags;
begin
  Result.GameSingle := 256;
  Result.GameCoop := 512;
  Result.GameDeathmatch := 1024;
  Result.Dormant := 16;
  Result.Fighter := 32;
  Result.Cleric := 64;
  Result.Mage := 128;
end;

{ TUdmfGames }

class function TUdmfGames.NameOf(AGame: TUdmfGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TUdmfGames.TryFromName(const AName: string; out AGame: TUdmfGame): Boolean;
var
  LGame: TUdmfGame;
begin
  for LGame := Low(TUdmfGame) to High(TUdmfGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Result := True;
      Exit;
    end;
  AGame := Doom;
  Result := False;
end;

class function TUdmfGames.CreateProfile(AGame: TUdmfGame;
  const ASounds: IUdmfSoundResolver): IUdmfProfile;
var
  LThings: IUdmfThingFormat;
  LLines: IUdmfLineFormat;
  LLayout: TUdmfSectorLayout;
begin
  case AGame of
    TUdmfGame.Doom:
      begin
        LThings := TUdmfVanillaThingFormat.Create(CommonThingFlags(128, 256, 512), 0,
          VANILLA_TRANSLATION);
        LLines := TUdmfVanillaLineFormat.Create(LineFlags(1024, 2048, 4096, 8192, 512, 0, 0, 0, 0));
        LLayout := SectorLayout(True, True);
      end;
    TUdmfGame.Heretic:
      begin
        LThings := TUdmfVanillaThingFormat.Create(CommonThingFlags(32, 64, 128), 0,
          VANILLA_TRANSLATION);
        LLines := TUdmfVanillaLineFormat.Create(LineFlags(512, 1024, 2048, 4096, 0, 0, 0, 0, 0));
        LLayout := SectorLayout(False, True);
      end;
    TUdmfGame.Hexen:
      begin
        LThings := TUdmfHexenThingFormat.Create(CommonThingFlags(2048, 4096, 8192), HexenThingFlags);
        LLines := TUdmfHexenLineFormat.Create(LineFlags(16384, 32768, 0, 0, 0, 0, 0, 0, 0), $0200, 10);
        LLayout := SectorLayout(False, False);
      end;
  else
    begin // Strife
      LThings := TUdmfVanillaThingFormat.Create(CommonThingFlags(2048, 4096, 8192), 64,
        VANILLA_TRANSLATION);
      LLines := TUdmfVanillaLineFormat.Create(LineFlags(16384, 32768, 0, 0, 8192, 2048, 4096, 512, 1024));
      LLayout := SectorLayout(True, True);
    end;
  end;
  Result := TUdmfProfile.Create(GAME_NAMES[AGame], LThings, LLines, TUdmfSideFormat.Create,
    TUdmfVertexFormat.Create, TUdmfSectorFormat.Create(LLayout, ASounds));
end;

end.