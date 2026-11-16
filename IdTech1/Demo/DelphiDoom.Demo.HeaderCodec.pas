{******************************************************************************}
{                                                                              }
{  DelphiDoom: demo library - reading and writing the header of a demo         }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Demo.HeaderCodec;

{$POINTERMATH ON}

interface

uses
  DelphiDoom.Demo.Types;

type
  /// <summary>
  ///   The bytes of the header of a demo (G_BeginRecording and the first part of G_DoPlayDemo)
  /// </summary>
  /// <remarks>
  ///   It works on a pointer that it moves, like <c>demo_p</c> of the engine, and it does not check
  ///   the length: a truncated demo reads what follows in memory, as the old code did. The policy
  ///   (which versions play, which warning to give) stays with the caller
  /// </remarks>
  TDemoHeaderCodec = class sealed
  public
    /// <summary>
    ///   Reads the version byte, after the magic if the file starts with it
    /// </summary>
    /// <param name="APosition">Start of the file; moved to the version byte</param>
    /// <param name="AMagic">The four bytes the demos of the game start with</param>
    /// <param name="AVersion">The version of the demo</param>
    /// <returns>True if the file started with the magic; false for a demo with no magic</returns>
    class function ReadVersion(var APosition: PByte; const AMagic: Cardinal;
      out AVersion: Byte): Boolean; static;

    /// <summary>
    ///   Reads the fields that follow the version byte
    /// </summary>
    /// <param name="APosition">On the version byte; moved after the last byte of the header</param>
    /// <param name="AProfile">The header of the game</param>
    /// <param name="AOldDemo">An old demo of Doom (1.9): it has no byte of the compatibility mode</param>
    /// <param name="AHeader">The fields; the ones the version does not have are zero</param>
    class procedure Read(var APosition: PByte; const AProfile: TDemoHeaderProfile;
      const AOldDemo: Boolean; out AHeader: TDemoHeader); static;

    /// <summary>
    ///   Writes the magic, the version and the fields
    /// </summary>
    /// <param name="APosition">Where the demo starts; moved after the last byte of the header</param>
    class procedure Write(var APosition: PByte; const AProfile: TDemoHeaderProfile;
      const AHeader: TDemoHeader); static;
  end;

implementation

{ TDemoHeaderCodec }

class function TDemoHeaderCodec.ReadVersion(var APosition: PByte; const AMagic: Cardinal;
  out AVersion: Byte): Boolean;
begin
  Result := PCardinal(APosition)^ = AMagic;
  if Result then
    Inc(APosition, 4);
  AVersion := APosition[0];
end;

class procedure TDemoHeaderCodec.Read(var APosition: PByte; const AProfile: TDemoHeaderProfile;
  const AOldDemo: Boolean; out AHeader: TDemoHeader);
var
  LIndex: Integer;
begin
  AHeader := Default(TDemoHeader);
  AHeader.Version := APosition[0];
  Inc(APosition);

  AHeader.Skill := APosition[0];
  Inc(APosition);

  if AProfile.HasEpisode then
  begin
    AHeader.Episode := APosition[0];
    Inc(APosition);
  end;

  AHeader.Map := APosition[0];
  Inc(APosition);

  AHeader.Deathmatch := APosition[0];
  Inc(APosition);

  AHeader.Respawn := APosition[0] <> 0;
  Inc(APosition);

  AHeader.Fast := APosition[0] <> 0;
  Inc(APosition);

  AHeader.NoMonsters := APosition[0] <> 0;
  Inc(APosition);

  if not AOldDemo then
  begin
    AHeader.Compatibility := APosition[0] <> 0;
    Inc(APosition);
  end;

  if AHeader.Version >= AProfile.SpawnRandomMinVersion then
  begin
    AHeader.SpawnRandomMonsters := APosition[0] <> 0;
    Inc(APosition);
  end;

  if (AHeader.Version >= AProfile.SpawnRandomMinVersion) and
     (AHeader.Version >= AProfile.SeedMinVersion) then
  begin
    AHeader.HasSeed := True;
    AHeader.Seed := APosition[0];
    Inc(APosition);
  end;

  if AProfile.HasDogs and (AHeader.Version >= AProfile.DogsMinVersion) then
  begin
    AHeader.Dogs := APosition[0];
    Inc(APosition);
    AHeader.DogJumping := APosition[0];
    Inc(APosition);
  end;

  AHeader.ConsolePlayer := APosition[0];
  Inc(APosition);

  for LIndex := 0 to AProfile.PlayerCount - 1 do
  begin
    AHeader.PlayersInGame[LIndex] := APosition[0] <> 0;
    Inc(APosition);
  end;
end;

class procedure TDemoHeaderCodec.Write(var APosition: PByte; const AProfile: TDemoHeaderProfile;
  const AHeader: TDemoHeader);
var
  LIndex: Integer;

  procedure PutByte(const AValue: Byte);
  begin
    APosition[0] := AValue;
    Inc(APosition);
  end;

  procedure PutFlag(const AValue: Boolean);
  begin
    if AValue then
      PutByte(1)
    else
      PutByte(0);
  end;

begin
  PCardinal(APosition)^ := AProfile.Magic;
  Inc(APosition, 4);

  PutByte(AHeader.Version);
  PutByte(AHeader.Skill);
  if AProfile.HasEpisode then
    PutByte(AHeader.Episode);
  PutByte(AHeader.Map);
  PutByte(AHeader.Deathmatch);
  PutFlag(AHeader.Respawn);
  PutFlag(AHeader.Fast);
  PutFlag(AHeader.NoMonsters);
  PutFlag(AHeader.Compatibility);
  PutFlag(AHeader.SpawnRandomMonsters);
  PutByte(AHeader.Seed);
  if AProfile.HasDogs then
  begin
    PutByte(AHeader.Dogs);
    PutByte(AHeader.DogJumping);
  end;
  PutByte(AHeader.ConsolePlayer);
  for LIndex := 0 to AProfile.PlayerCount - 1 do
    PutFlag(AHeader.PlayersInGame[LIndex]);
end;

end.
