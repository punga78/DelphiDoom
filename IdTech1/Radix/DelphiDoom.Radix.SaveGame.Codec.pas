{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSaveGameCodec                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SaveGame.Codec;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.SaveGame.Types;

type
  /// <summary>
  ///   Writes and reads the state of Radix of a saved game (the file beside the one of the engine):
  ///   the header of DelphiDoom.Radix.SaveGame.Types and the records after it. What is not a whole
  ///   file of the version that is written is refused with ERadixException: nothing is guessed
  /// </summary>
  TRadixSaveGameCodec = class
  strict private
    class procedure CheckLengths(const AState: TRadixSaveState); static;
  public
    /// <remarks>
    ///   Raises ERadixException when the players, their level parts and their last triggers are
    ///   not as many
    /// </remarks>
    class function Encode(const AState: TRadixSaveState): TBytes; static;
    /// <remarks>
    ///   Raises ERadixException for a file that is too short or too long, of another version or
    ///   without the magic, or with a negative count
    /// </remarks>
    class function Decode(const ABytes: TBytes): TRadixSaveState; static;
    /// <summary>
    ///   The fingerprints (FNV-1a, 32 bits, of the records as they are written) of the parts of a
    ///   state, to compare in a log the state before a save and after a load
    /// </summary>
    class function Fingerprints(const AState: TRadixSaveState): TRadixSaveFingerprints; static;
  end;

implementation

uses
  DelphiDoom.Radix.Types,
  DelphiDoom.Radix.Level.Types;

// the wraparound of the product of the fingerprint is wanted
{$Q-}
{$R-}

const
  SCountMismatch = 'Radix saved game: %d players, %d level parts and %d last triggers';
  STooShort = 'Radix saved game: the file has %d bytes, the header alone has %d';
  SBadMagic = 'Radix saved game: the file does not start with RADIXSAV';
  SBadVersion = 'Radix saved game: version %d, only version %d is read';
  SBadCount = 'Radix saved game: a negative count in the header';
  SBadSize = 'Radix saved game: the file has %d bytes, its header says %d';

  FNV_OFFSET = 2166136261;
  FNV_PRIME = 16777619;

{ TRadixSaveGameCodec }

class procedure TRadixSaveGameCodec.CheckLengths(const AState: TRadixSaveState);
begin
  if (Length(AState.LevelPlayers) <> Length(AState.Players)) or
    (Length(AState.LastTriggers) <> Length(AState.Players)) then
    raise ERadixException.CreateFmt(SCountMismatch, [Length(AState.Players), Length(AState.LevelPlayers),
      Length(AState.LastTriggers)]);
end;

class function TRadixSaveGameCodec.Encode(const AState: TRadixSaveState): TBytes;
var
  LHeader: TRadixSaveHeader;
  LPosition: Integer;

  procedure Put(const ASource; ACount, ASize: Integer);
  begin
    if ACount > 0 then
      Move(ASource, Result[LPosition], ACount * ASize);
    Inc(LPosition, ACount * ASize);
  end;

begin
  CheckLengths(AState);
  LHeader := Default(TRadixSaveHeader);
  LHeader.Magic := RADIX_SAVE_MAGIC;
  LHeader.Version := RADIX_SAVE_VERSION;
  LHeader.Episode := AState.Episode;
  LHeader.Map := AState.Map;
  LHeader.Players := Length(AState.Players);
  LHeader.Actions := Length(AState.Actions);
  LHeader.Triggers := Length(AState.Triggers);
  LHeader.Walls := Length(AState.Walls);
  LHeader.Shots := Length(AState.Shots);
  LHeader.NamedLevel := AState.NamedLevel;
  LHeader.RandomIndexes := AState.RandomIndexes;

  SetLength(Result, SizeOf(TRadixSaveHeader) +
    LHeader.Players * (SizeOf(TRadixSavePlayer) + SizeOf(TRadixSaveLevelPlayer) + SizeOf(Integer)) +
    LHeader.Actions * SizeOf(TRadixLevelAction) + LHeader.Triggers * SizeOf(TRadixLevelTrigger) +
    LHeader.Walls * SizeOf(TRadixSaveWall) + LHeader.Shots * SizeOf(TRadixSaveShot));
  LPosition := 0;
  Put(LHeader, 1, SizeOf(TRadixSaveHeader));
  Put(Pointer(AState.Players)^, LHeader.Players, SizeOf(TRadixSavePlayer));
  Put(Pointer(AState.LevelPlayers)^, LHeader.Players, SizeOf(TRadixSaveLevelPlayer));
  Put(Pointer(AState.LastTriggers)^, LHeader.Players, SizeOf(Integer));
  Put(Pointer(AState.Actions)^, LHeader.Actions, SizeOf(TRadixLevelAction));
  Put(Pointer(AState.Triggers)^, LHeader.Triggers, SizeOf(TRadixLevelTrigger));
  Put(Pointer(AState.Walls)^, LHeader.Walls, SizeOf(TRadixSaveWall));
  Put(Pointer(AState.Shots)^, LHeader.Shots, SizeOf(TRadixSaveShot));
end;

class function TRadixSaveGameCodec.Decode(const ABytes: TBytes): TRadixSaveState;
var
  LHeader: TRadixSaveHeader;
  LPosition: Integer;
  LExpected: Int64;

  procedure Take(var ATarget; ACount, ASize: Integer);
  begin
    if ACount > 0 then
      Move(ABytes[LPosition], ATarget, ACount * ASize);
    Inc(LPosition, ACount * ASize);
  end;

begin
  if Length(ABytes) < SizeOf(TRadixSaveHeader) then
    raise ERadixException.CreateFmt(STooShort, [Length(ABytes), SizeOf(TRadixSaveHeader)]);
  Move(ABytes[0], LHeader, SizeOf(TRadixSaveHeader));
  if not CompareMem(@LHeader.Magic, @RADIX_SAVE_MAGIC, SizeOf(RADIX_SAVE_MAGIC)) then
    raise ERadixException.Create(SBadMagic);
  if LHeader.Version <> RADIX_SAVE_VERSION then
    raise ERadixException.CreateFmt(SBadVersion, [LHeader.Version, RADIX_SAVE_VERSION]);
  if (LHeader.Players < 0) or (LHeader.Actions < 0) or (LHeader.Triggers < 0) or (LHeader.Walls < 0) or
    (LHeader.Shots < 0) then
    raise ERadixException.Create(SBadCount);
  LExpected := SizeOf(TRadixSaveHeader) +
    Int64(LHeader.Players) * (SizeOf(TRadixSavePlayer) + SizeOf(TRadixSaveLevelPlayer) + SizeOf(Integer)) +
    Int64(LHeader.Actions) * SizeOf(TRadixLevelAction) + Int64(LHeader.Triggers) * SizeOf(TRadixLevelTrigger) +
    Int64(LHeader.Walls) * SizeOf(TRadixSaveWall) + Int64(LHeader.Shots) * SizeOf(TRadixSaveShot);
  if LExpected <> Length(ABytes) then
    raise ERadixException.CreateFmt(SBadSize, [Length(ABytes), LExpected]);

  Result := Default(TRadixSaveState);
  Result.Episode := LHeader.Episode;
  Result.Map := LHeader.Map;
  Result.NamedLevel := LHeader.NamedLevel;
  Result.RandomIndexes := LHeader.RandomIndexes;
  SetLength(Result.Players, LHeader.Players);
  SetLength(Result.LevelPlayers, LHeader.Players);
  SetLength(Result.LastTriggers, LHeader.Players);
  SetLength(Result.Actions, LHeader.Actions);
  SetLength(Result.Triggers, LHeader.Triggers);
  SetLength(Result.Walls, LHeader.Walls);
  SetLength(Result.Shots, LHeader.Shots);
  LPosition := SizeOf(TRadixSaveHeader);
  Take(Pointer(Result.Players)^, LHeader.Players, SizeOf(TRadixSavePlayer));
  Take(Pointer(Result.LevelPlayers)^, LHeader.Players, SizeOf(TRadixSaveLevelPlayer));
  Take(Pointer(Result.LastTriggers)^, LHeader.Players, SizeOf(Integer));
  Take(Pointer(Result.Actions)^, LHeader.Actions, SizeOf(TRadixLevelAction));
  Take(Pointer(Result.Triggers)^, LHeader.Triggers, SizeOf(TRadixLevelTrigger));
  Take(Pointer(Result.Walls)^, LHeader.Walls, SizeOf(TRadixSaveWall));
  Take(Pointer(Result.Shots)^, LHeader.Shots, SizeOf(TRadixSaveShot));
end;

class function TRadixSaveGameCodec.Fingerprints(const AState: TRadixSaveState): TRadixSaveFingerprints;

  function Hash(ASeed: Cardinal; AData: PByte; ACount, ASize: Integer): Cardinal;
  var
    LIndex: Integer;
  begin
    Result := ASeed;
    for LIndex := 0 to ACount * ASize - 1 do
    begin
      Result := (Result xor AData^) * FNV_PRIME;
      Inc(AData);
    end;
  end;

begin
  Result.Players := Hash(FNV_OFFSET, PByte(AState.Players), Length(AState.Players), SizeOf(TRadixSavePlayer));
  Result.LevelPlayers := Hash(FNV_OFFSET, PByte(AState.LevelPlayers), Length(AState.LevelPlayers),
    SizeOf(TRadixSaveLevelPlayer));
  Result.LevelPlayers := Hash(Result.LevelPlayers, PByte(AState.LastTriggers), Length(AState.LastTriggers),
    SizeOf(Integer));
  Result.Actions := Hash(FNV_OFFSET, PByte(AState.Actions), Length(AState.Actions), SizeOf(TRadixLevelAction));
  Result.Triggers := Hash(FNV_OFFSET, PByte(AState.Triggers), Length(AState.Triggers), SizeOf(TRadixLevelTrigger));
  Result.Walls := Hash(FNV_OFFSET, PByte(AState.Walls), Length(AState.Walls), SizeOf(TRadixSaveWall));
  Result.Shots := Hash(FNV_OFFSET, PByte(AState.Shots), Length(AState.Shots), SizeOf(TRadixSaveShot));
end;

end.
