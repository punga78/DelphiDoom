{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the session block of a saved game          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.SaveGameSessionBlock;

interface

type
  /// <summary>
  ///   The bytes that follow the version of a saved game and describe the session: skill,
  ///   episode (not in Strife), map and one flag byte for every player slot
  ///   (G_DoSaveGameInFile and G_DoLoadGame of g_game)
  /// </summary>
  TSaveGameSessionBlock = class sealed
  public
    /// <summary>The number of bytes of the block</summary>
    /// <param name="APlayerCount">The number of player slots (MAXPLAYERS)</param>
    /// <param name="AHasEpisode">False in Strife, which has no episode byte</param>
    class function BlockSize(const APlayerCount: Integer; const AHasEpisode: Boolean): Integer; static;

    /// <summary>Writes the block: BlockSize bytes</summary>
    /// <param name="ADestination">Where it goes</param>
    /// <param name="ASkill">The skill as a byte</param>
    /// <param name="AEpisode">The episode, not written when AHasEpisode is False</param>
    /// <param name="AMap">The map</param>
    /// <param name="AHasEpisode">False in Strife</param>
    /// <param name="APlayersInGame">The flags of the player slots: a byte 1 or 0 each</param>
    class procedure Write(const ADestination: PByte; const ASkill, AEpisode, AMap: Byte;
      const AHasEpisode: Boolean; const APlayersInGame: array of Boolean); static;

    /// <summary>Reads the block written by Write (any byte other than 0 is a player in game)</summary>
    /// <param name="ASource">The bytes of the file</param>
    /// <param name="AHasEpisode">False in Strife</param>
    /// <param name="ASkill">The skill as a byte</param>
    /// <param name="AEpisode">The episode: 0 when AHasEpisode is False</param>
    /// <param name="AMap">The map</param>
    /// <param name="APlayersInGame">The flags to fill: its length is the number of player slots</param>
    class procedure Read(const ASource: PByte; const AHasEpisode: Boolean;
      out ASkill, AEpisode, AMap: Byte; var APlayersInGame: array of Boolean); static;
  end;

implementation

{ TSaveGameSessionBlock }

class function TSaveGameSessionBlock.BlockSize(const APlayerCount: Integer;
  const AHasEpisode: Boolean): Integer;
begin
  Result := 2 + APlayerCount;
  if AHasEpisode then
    Inc(Result);
end;

class procedure TSaveGameSessionBlock.Write(const ADestination: PByte;
  const ASkill, AEpisode, AMap: Byte; const AHasEpisode: Boolean;
  const APlayersInGame: array of Boolean);
var
  LCursor: PByte;
  LIndex: Integer;
begin
  LCursor := ADestination;
  LCursor^ := ASkill;
  Inc(LCursor);
  if AHasEpisode then
  begin
    LCursor^ := AEpisode;
    Inc(LCursor);
  end;
  LCursor^ := AMap;
  Inc(LCursor);
  for LIndex := 0 to High(APlayersInGame) do
  begin
    if APlayersInGame[LIndex] then
      LCursor^ := 1
    else
      LCursor^ := 0;
    Inc(LCursor);
  end;
end;

class procedure TSaveGameSessionBlock.Read(const ASource: PByte; const AHasEpisode: Boolean;
  out ASkill, AEpisode, AMap: Byte; var APlayersInGame: array of Boolean);
var
  LCursor: PByte;
  LIndex: Integer;
begin
  LCursor := ASource;
  ASkill := LCursor^;
  Inc(LCursor);
  AEpisode := 0;
  if AHasEpisode then
  begin
    AEpisode := LCursor^;
    Inc(LCursor);
  end;
  AMap := LCursor^;
  Inc(LCursor);
  for LIndex := 0 to High(APlayersInGame) do
  begin
    APlayersInGame[LIndex] := LCursor^ <> 0;
    Inc(LCursor);
  end;
end;

end.
