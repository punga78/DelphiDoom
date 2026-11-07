{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the zone library - a replay of random operations       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zone.Replay;

{$Q-}
{$R-}
// the generator and the digest wrap around on purpose

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Whatever is under test: the allocator of the library or, in the program that made the
  ///   golden file, the old TMemManager of the engine
  /// </summary>
  TZoneReplayTarget = class abstract
  public
    function Malloc(ASize, ATag: Integer; AUser: PPointer): Pointer; virtual; abstract;
    function Realloc(APointer: Pointer; ASize, ATag: Integer; AUser: PPointer): Pointer; virtual; abstract;
    procedure Release(APointer: Pointer); virtual; abstract;
    function SizeOfBlock(APointer: Pointer): Integer; virtual; abstract;
    procedure ChangeTag(APointer: Pointer; ATag: Integer); virtual; abstract;
    procedure FreeTags(ALowTag, AHighTag: Integer); virtual; abstract;
    function BlockCount: Integer; virtual; abstract;
  end;

  /// <summary>
  ///   Applies a long, repeatable series of operations (malloc, free, realloc, tag changes,
  ///   free of ranges of tags) to a target and gives a line of digest every few steps. The
  ///   digest never contains an address: only counts, sizes, the bytes of the blocks and
  ///   whether the user variables are set
  /// </summary>
  TZoneReplay = class
  public
    /// <summary>Lines "seed step hash blocks"; a line that begins with ERR is a broken rule</summary>
    class function Run(ATarget: TZoneReplayTarget; ASeed, ASteps, AReportEvery: Integer): TArray<string>; static;
  end;

implementation

const
  SLOTS = 48;
  TAGS: array[0..7] of Integer = (1, 2, 3, 4, 50, 51, 100, 101);

type
  TSlot = record
    Data: PByte;
    Size: Integer;
    Tag: Integer;
    Fill: Byte;
    UsesUser: Boolean;
  end;

procedure Mix(var AHash: Cardinal; AValue: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
  begin
    AHash := (AHash xor (AValue and $FF)) * 16777619;
    AValue := AValue shr 8;
  end;
end;

class function TZoneReplay.Run(ATarget: TZoneReplayTarget; ASeed, ASteps,
  AReportEvery: Integer): TArray<string>;
var
  LState: Cardinal;
  LSlots: array[0..SLOTS - 1] of TSlot;
  LUsers: array[0..SLOTS - 1] of Pointer;
  LLines: TArray<string>;
  LHash: Cardinal;
  LStep: Integer;
  LRoll: Integer;
  LSlot: Integer;
  LOldSize: Integer;
  LNewSize: Integer;
  LLow: Integer;
  LHigh: Integer;
  LTemp: Integer;
  LNewTag: Integer;
  LIndex: Integer;
  LByte: Integer;
  LNewData: Pointer;
  LBlocks: Integer;

  function Next(ALimit: Integer): Integer;
  begin
    LState := LState * 1103515245 + 12345;
    Result := Integer((LState shr 16) and $7FFF) mod ALimit;
  end;

  procedure Fail(const AMessage: string);
  begin
    SetLength(LLines, Length(LLines) + 1);
    LLines[High(LLines)] := Format('ERR seed %d step %d: %s', [ASeed, LStep, AMessage]);
  end;

  procedure Fill(ASlot: Integer; AFrom: Integer);
  begin
    if LSlots[ASlot].Size > AFrom then
      FillChar(LSlots[ASlot].Data[AFrom], LSlots[ASlot].Size - AFrom, LSlots[ASlot].Fill);
  end;

  function UserOf(ASlot: Integer): PPointer;
  begin
    if Next(2) = 0 then
      Result := nil
    else
      Result := @LUsers[ASlot];
  end;

  procedure DoMalloc(ASlot, AMaxSize, ATag: Integer);
  var
    LUser: PPointer;
  begin
    LUser := UserOf(ASlot);
    LSlots[ASlot].Size := Next(AMaxSize + 1);
    LSlots[ASlot].Tag := ATag;
    LSlots[ASlot].Fill := Byte(ASlot * 13 + LStep);
    LSlots[ASlot].UsesUser := Assigned(LUser);
    LSlots[ASlot].Data := ATarget.Malloc(LSlots[ASlot].Size, ATag, LUser);
    Fill(ASlot, 0);
  end;

  procedure Kill(ASlot: Integer);
  begin
    LSlots[ASlot].Data := nil;
    if LSlots[ASlot].UsesUser and Assigned(LUsers[ASlot]) then
      Fail('the user pointer was not cleared');
    LSlots[ASlot].UsesUser := False;
    LUsers[ASlot] := nil;
  end;

  procedure Digest;
  var
    LSlotIndex: Integer;
    LByteIndex: Integer;
  begin
    Mix(LHash, Cardinal(ATarget.BlockCount));
    for LSlotIndex := 0 to SLOTS - 1 do
      if Assigned(LSlots[LSlotIndex].Data) then
      begin
        Mix(LHash, Cardinal(LSlotIndex));
        Mix(LHash, Cardinal(LSlots[LSlotIndex].Size));
        if ATarget.SizeOfBlock(LSlots[LSlotIndex].Data) <> LSlots[LSlotIndex].Size then
          Fail('the size of a block is wrong');
        if LSlots[LSlotIndex].UsesUser then
          if LUsers[LSlotIndex] <> Pointer(LSlots[LSlotIndex].Data) then
            Fail('the user pointer does not hold the block');
        Mix(LHash, Cardinal(Ord(LSlots[LSlotIndex].UsesUser)));
        for LByteIndex := 0 to LSlots[LSlotIndex].Size - 1 do
          Mix(LHash, LSlots[LSlotIndex].Data[LByteIndex]);
      end;
  end;

begin
  SetLength(LLines, 0);
  LState := Cardinal(ASeed) * 2654435761 + 1;
  FillChar(LSlots, SizeOf(LSlots), 0);
  FillChar(LUsers, SizeOf(LUsers), 0);
  LHash := 2166136261;
  for LStep := 1 to ASteps do
  begin
    LSlot := Next(SLOTS);
    LRoll := Next(100);
    Mix(LHash, Cardinal(LRoll));
    if LRoll < 40 then
    begin
      if not Assigned(LSlots[LSlot].Data) then
        DoMalloc(LSlot, 300, TAGS[Next(8)])
      else
      begin
        ATarget.Release(LSlots[LSlot].Data);
        Kill(LSlot);
      end;
    end
    else if LRoll < 60 then
    begin
      if Assigned(LSlots[LSlot].Data) then
      begin
        LOldSize := LSlots[LSlot].Size;
        LNewSize := Next(301);
        LNewTag := TAGS[Next(8)];
        // a realloc to the same size leaves the block as it is, tag included
        if LNewSize <> LOldSize then
          LSlots[LSlot].Tag := LNewTag;
        if LSlots[LSlot].UsesUser then
          LNewData := ATarget.Realloc(LSlots[LSlot].Data, LNewSize, LNewTag, @LUsers[LSlot])
        else
          LNewData := ATarget.Realloc(LSlots[LSlot].Data, LNewSize, LNewTag, nil);
        if LNewSize = 0 then
        begin
          if Assigned(LNewData) then
            Fail('a size of 0 must give nil');
          Kill(LSlot);
        end
        else
        begin
          LSlots[LSlot].Data := LNewData;
          LSlots[LSlot].Size := LNewSize;
          // what fits must have been kept
          if LOldSize < LNewSize then
            LTemp := LOldSize
          else
            LTemp := LNewSize;
          for LIndex := 0 to LTemp - 1 do
            if LSlots[LSlot].Data[LIndex] <> LSlots[LSlot].Fill then
            begin
              Fail('the bytes were not kept by the realloc');
              Break;
            end;
          Fill(LSlot, LTemp);
        end;
      end;
    end
    else if LRoll < 75 then
    begin
      if Assigned(LSlots[LSlot].Data) then
      begin
        LSlots[LSlot].Tag := TAGS[Next(8)];
        ATarget.ChangeTag(LSlots[LSlot].Data, LSlots[LSlot].Tag);
      end;
    end
    else if LRoll < 90 then
    begin
      LLow := TAGS[Next(8)];
      LHigh := TAGS[Next(8)];
      if LLow > LHigh then
      begin
        LTemp := LLow;
        LLow := LHigh;
        LHigh := LTemp;
      end;
      ATarget.FreeTags(LLow, LHigh);
      for LIndex := 0 to SLOTS - 1 do
        if Assigned(LSlots[LIndex].Data) and (LSlots[LIndex].Tag >= LLow) and
           (LSlots[LIndex].Tag <= LHigh) then
          Kill(LIndex);
    end
    else if not Assigned(LSlots[LSlot].Data) then
      DoMalloc(LSlot, 5000, 101);

    Digest;
    if (LStep mod AReportEvery = 0) or (LStep = ASteps) then
    begin
      LBlocks := ATarget.BlockCount;
      SetLength(LLines, Length(LLines) + 1);
      LLines[High(LLines)] := Format('%d %d %s %d', [ASeed, LStep, IntToHex(LHash, 8), LBlocks]);
    end;
  end;
  // whatever is left is freed, as the shutdown does
  for LByte := 0 to SLOTS - 1 do
    if Assigned(LSlots[LByte].Data) then
      ATarget.Release(LSlots[LByte].Data);
  Result := LLines;
end;

end.
