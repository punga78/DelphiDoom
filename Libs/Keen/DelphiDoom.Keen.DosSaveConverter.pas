{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a saved game of the DOS program as a saved game   }
{  of this port                                                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SaveGame and LoadGame of kd_demo.c                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.DosSaveConverter;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.DosStateLocator;

type
  /// <summary>What a conversion found, for the program that asks for it</summary>
  TKeenDosSaveInfo = record
    /// <summary>The name that the player gave to the game</summary>
    Name: AnsiString;
    /// <summary>The level that was played (0 is the world map)</summary>
    MapOn: Integer;
    /// <summary>The actors in the file, the player and the score box included</summary>
    Actors: Integer;
    /// <summary>Pointers to states and to actors that were turned into the numbers that this port keeps</summary>
    PointersConverted: Integer;
  end;

  /// <summary>
  ///   The file of a saved game of the DOS program (SAVEGMn.KDR) has the layout that this port writes (the header
  ///   of 40 bytes, gametype, the three planes of the map in RLEW, the actors) with one difference: the actors have
  ///   addresses. A near pointer to the state (an address in the data segment of the program, found in the
  ///   executable by TKeenDosStateLocator), the sprite and the links of the list. This turns the addresses into
  ///   what the port keeps: the number of the state plus 1, no sprite, a link while another actor follows. The
  ///   fields of an actor that are pointers by what the game does with them are turned too: the original state of
  ///   an enemy that became a flower, the flower that a puff of smoke gives back, the zees above Keen when he
  ///   sleeps. Not rebuilt, because the DOS file has nothing of them: the sprite (every actor draws itself again) and
  ///   whether an actor needs to react (it does)
  /// </summary>
  TKeenDosSaveConverter = class
  public
    /// <summary>
    ///   EKeenDataException if the file is not a saved game of the DOS program (the signature, the length, the
    ///   planes, no actors), if an actor has a state that is not one of the 213 (the executable is not the one that
    ///   wrote the game) or if a link of the list does not lead to the next actor
    /// </summary>
    class function Convert(const ADosFile: TBytes; const AStates: TKeenDosStateMap;
      out AInfo: TKeenDosSaveInfo): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTable;

const
  SBadSignature = 'Keen: the file is not a saved game of Keen Dreams (no "KDR" signature)';
  STooShort = 'Keen: the saved game ends too soon (%s)';
  SBadState = 'Keen: the actor %d has a state at %x, that is not one of the states of this program';
  SBadLink = 'Keen: the links of the actors of the saved game do not follow each other (actor %d)';
  SNoActors = 'Keen: the saved game has no actors (the player and the score box are always there)';
  SBadMap = 'Keen: the saved game is of the level %d, that does not exist';
  SDifferentSize = 'Keen: the size of the actors is not a whole number (%d bytes left)';

  /// <summary>The header of the DOS program: sizeof(SaveGame), with the byte that the compiler adds</summary>
  HEADER_SIZE = 40;
  GAMESTATE_SIZE = 60;

function ReadWord(const ABytes: TBytes; APosition: Integer): Integer; inline;
begin
  Result := ABytes[APosition] or (ABytes[APosition + 1] shl 8);
end;

class function TKeenDosSaveConverter.Convert(const ADosFile: TBytes; const AStates: TKeenDosStateMap;
  out AInfo: TKeenDosSaveInfo): TBytes;
var
  LPosition: Integer;
  LPlane: Integer;
  LLength: Integer;
  LObjectsStart: Integer;
  LCount: Integer;
  LActor: Integer;
  LAddresses: TArray<Integer>;
  LRecords: TArray<TKeenSaveObject>;
  LRecord: TKeenSaveObject;
  LStateIndex: Integer;
  LIndex: Integer;
  LStream: TBytes;
  LNameLength: Integer;

  function StateOf(AAddress: Integer): Integer;
  var
    LFound: Integer;
  begin
    for LFound := 0 to High(AStates.Offsets) do
      if AStates.Offsets[LFound] = AAddress then
        Exit(LFound);
    Result := -1;
  end;

  function ActorOf(AAddress: Integer): Integer;
  var
    LFound: Integer;
  begin
    for LFound := 0 to High(LAddresses) do
      if LAddresses[LFound] = AAddress then
        Exit(LFound);
    Result := -1;
  end;

begin
  AInfo := Default(TKeenDosSaveInfo);
  if Length(ADosFile) < HEADER_SIZE + GAMESTATE_SIZE then
    raise EKeenDataException.CreateFmt(STooShort, ['the header and the state of the game']);
  if (ADosFile[0] <> Ord('K')) or (ADosFile[1] <> Ord('D')) or (ADosFile[2] <> Ord('R')) or (ADosFile[3] <> 0) then
    raise EKeenDataException.Create(SBadSignature);
  LNameLength := 0;
  while (LNameLength < 32) and (ADosFile[6 + LNameLength] <> 0) do
    Inc(LNameLength);
  SetLength(AInfo.Name, LNameLength);
  if LNameLength > 0 then
    Move(ADosFile[6], AInfo.Name[1], LNameLength);
  AInfo.MapOn := SmallInt(ReadWord(ADosFile, HEADER_SIZE + 54));
  if (AInfo.MapOn < 0) or (AInfo.MapOn >= KEEN_GAMELEVELS) then
    raise EKeenDataException.CreateFmt(SBadMap, [AInfo.MapOn]);
  // the three planes: a 16 bit length and the data
  LPosition := HEADER_SIZE + GAMESTATE_SIZE;
  for LPlane := 0 to 2 do
  begin
    if LPosition + 2 > Length(ADosFile) then
      raise EKeenDataException.CreateFmt(STooShort, ['the planes of the map']);
    LLength := ReadWord(ADosFile, LPosition);
    Inc(LPosition, 2 + LLength);
    if LPosition > Length(ADosFile) then
      raise EKeenDataException.CreateFmt(STooShort, ['the planes of the map']);
  end;
  LObjectsStart := LPosition;
  if (Length(ADosFile) - LObjectsStart) mod SizeOf(TKeenSaveObject) <> 0 then
    raise EKeenDataException.CreateFmt(SDifferentSize, [(Length(ADosFile) - LObjectsStart) mod SizeOf(TKeenSaveObject)]);
  LCount := (Length(ADosFile) - LObjectsStart) div SizeOf(TKeenSaveObject);
  if LCount < 2 then
    raise EKeenDataException.Create(SNoActors);
  AInfo.Actors := LCount;
  SetLength(LRecords, LCount);
  Move(ADosFile[LObjectsStart], LRecords[0], LCount * SizeOf(TKeenSaveObject));
  // the address of each actor: the link of the one before it, the player's is the back link of the second
  SetLength(LAddresses, LCount);
  LAddresses[0] := LRecords[1].Prev;
  for LActor := 1 to LCount - 1 do
    LAddresses[LActor] := LRecords[LActor - 1].Next;
  // the back links say it a second time: each actor points back to the one before it, and the last one has no next
  for LActor := 2 to LCount - 1 do
    if LRecords[LActor].Prev <> LAddresses[LActor - 1] then
      raise EKeenDataException.CreateFmt(SBadLink, [LActor]);
  if (LRecords[0].Prev <> 0) or (LRecords[LCount - 1].Next <> 0) then
    raise EKeenDataException.CreateFmt(SBadLink, [LCount - 1]);
  for LActor := 0 to LCount - 1 do
  begin
    LRecord := LRecords[LActor];
    if LRecord.State = 0 then
      LStateIndex := -1
    else
    begin
      LStateIndex := StateOf(LRecord.State);
      if LStateIndex < 0 then
        raise EKeenDataException.CreateFmt(SBadState, [LActor, Integer(LRecord.State)]);
    end;
    // what the game keeps in temp1 and temp2 as a pointer (the DOS has addresses, this port has numbers):
    // the flower keeps the state that the enemy had (temp2), the puff that takes the flower away keeps the flower
    // (temp1), Keen asleep keeps the zees (temp1, or the address of an actor that is not in the list when there
    // are none yet)
    case LStateIndex of
      KEEN_STATE_S_FLOWER1..KEEN_STATE_S_FLOWER6:
        begin
          LIndex := StateOf(LRecord.Temp2);
          if LIndex < 0 then
            raise EKeenDataException.CreateFmt(SBadState, [LActor, Integer(Word(LRecord.Temp2))]);
          LRecord.Temp2 := SmallInt(LIndex);
          Inc(AInfo.PointersConverted);
        end;
      KEEN_STATE_S_POOFFROM1..KEEN_STATE_S_POOFFROM6:
        begin
          LIndex := ActorOf(Word(LRecord.Temp1));
          if LIndex < 0 then
            raise EKeenDataException.CreateFmt(SBadLink, [LActor]);
          LRecord.Temp1 := SmallInt(LIndex);
          Inc(AInfo.PointersConverted);
        end;
      KEEN_STATE_S_KEENGOSLEEP2, KEEN_STATE_S_KEENSLEEP1, KEEN_STATE_S_KEENSLEEP2:
        if LActor = 0 then
        begin
          LIndex := ActorOf(Word(LRecord.Temp1));
          if LIndex < 0 then
            LIndex := KEEN_DUMMY_SLOT;
          LRecord.Temp1 := SmallInt(LIndex);
          Inc(AInfo.PointersConverted);
        end;
    end;
    LRecord.State := Word(LStateIndex + 1);
    LRecord.Sprite := KEEN_SAVE_NIL;
    if LActor < LCount - 1 then
      LRecord.Next := 1
    else
      LRecord.Next := KEEN_SAVE_NIL;
    LRecord.Prev := KEEN_SAVE_NIL;
    LRecords[LActor] := LRecord;
  end;
  SetLength(LStream, LObjectsStart + LCount * SizeOf(TKeenSaveObject));
  Move(ADosFile[0], LStream[0], LObjectsStart);
  Move(LRecords[0], LStream[LObjectsStart], LCount * SizeOf(TKeenSaveObject));
  Result := LStream;
end;

end.
