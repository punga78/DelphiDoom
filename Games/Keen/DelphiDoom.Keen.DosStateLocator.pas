{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - where the states of the actors are in the         }
{  program of the original                                                      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.DosStateLocator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

const
  /// <summary>sizeof(statetype) of the original: eight words, three far pointers (think, contact, react) and a near pointer</summary>
  KEEN_DOS_STATE_SIZE = 30;

type
  /// <summary>Where the states are in the memory image of the original program</summary>
  TKeenDosStateMap = record
    /// <summary>The address of each state in the data segment (what a pointer to the state holds); -1 if not found</summary>
    Offsets: TArray<Integer>;
    /// <summary>The states that were not found</summary>
    Missing: Integer;
    /// <summary>The states that have the same fields and the same successor as another one: the address is the first</summary>
    Ambiguous: Integer;
    /// <summary>Where the data segment begins in the image: the address of a state plus this is its place</summary>
    DataStart: Integer;
  end;

  /// <summary>
  ///   A saved game of the original has, in each actor, the address of its state in the data segment of the DOS
  ///   program (a near pointer to a statetype). The states are initialized data of the program, so they are in
  ///   the memory image of KDREAMS.EXE: this finds the 213 states of the table in it by their fields (the shapes,
  ///   the kind of progress, the times, the moves and the functions), and takes the data segment from the
  ///   successor that each state points to: all the 213 pointers must agree on where the segment begins, or the
  ///   image is not the program that wrote the game
  /// </summary>
  TKeenDosStateLocator = class
  public
    /// <summary>
    ///   EKeenDataException if the image is not the one of a program that has these states (the successors do not
    ///   agree on the data segment, or fewer than 90% of the states were found)
    /// </summary>
    class function Locate(const AImage: TBytes; const AStates: IKeenStateTable): TKeenDosStateMap; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.StateTypes;

const
  SNotTheProgram = 'Keen: the memory image is not the program that has these states (%s)';

function ReadWord(const AImage: TBytes; APosition: Integer): Integer; inline;
begin
  Result := AImage[APosition] or (AImage[APosition + 1] shl 8);
end;

function ReadLong(const AImage: TBytes; APosition: Integer): Int64; inline;
begin
  Result := Int64(ReadWord(AImage, APosition)) or (Int64(ReadWord(AImage, APosition + 2)) shl 16);
end;

class function TKeenDosStateLocator.Locate(const AImage: TBytes; const AStates: IKeenStateTable): TKeenDosStateMap;
type
  TKey = array[0..7] of Word;
var
  LCount: Integer;
  LCandidates: TArray<TArray<Integer>>;
  LKeys: TArray<TKey>;
  LIndex: Integer;
  LPosition: Integer;
  LDef: TKeenStateDef;
  LMatches: Boolean;
  LField: Integer;
  LThink: TDictionary<Word, Int64>;
  LContact: TDictionary<Word, Int64>;
  LReact: TDictionary<Word, Int64>;
  LChanged: Boolean;
  LKept: TArray<Integer>;
  LCandidate: Integer;
  LOk: Boolean;
  LBases: TDictionary<Integer, Integer>;
  LBase: Integer;
  LBestBase: Integer;
  LBestCount: Integer;
  LNext: Integer;
  LAnchor: Integer;
  LPair: TPair<Integer, Integer>;
  LValue: Integer;
  LFound: Integer;

  function Same(AAction: Word; AValue: Int64; const ATable: TDictionary<Word, Int64>): Boolean;
  var
    LKnown: Int64;
  begin
    if AAction = 0 then
      Exit(AValue = 0);
    Result := (not ATable.TryGetValue(AAction, LKnown)) or (LKnown = AValue);
  end;

begin
  LCount := AStates.Count;
  SetLength(LCandidates, LCount);
  SetLength(LKeys, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LDef := AStates[LIndex];
    LKeys[LIndex][0] := Word(LDef.LeftShape);
    LKeys[LIndex][1] := Word(LDef.RightShape);
    LKeys[LIndex][2] := Word(Ord(LDef.Progress));
    LKeys[LIndex][3] := Word(Ord(LDef.Skippable));
    LKeys[LIndex][4] := Word(Ord(LDef.PushToFloor));
    LKeys[LIndex][5] := Word(LDef.TicTime);
    LKeys[LIndex][6] := Word(LDef.XMove);
    LKeys[LIndex][7] := Word(LDef.YMove);
  end;
  // every place where the eight words of a state are
  for LPosition := 0 to Length(AImage) - KEEN_DOS_STATE_SIZE do
    for LIndex := 0 to LCount - 1 do
    begin
      LMatches := True;
      for LField := 0 to 7 do
        if ReadWord(AImage, LPosition + LField * 2) <> LKeys[LIndex][LField] then
        begin
          LMatches := False;
          Break;
        end;
      if LMatches then
        LCandidates[LIndex] := LCandidates[LIndex] + [LPosition];
    end;
  // the functions: the value of a function pointer is the same in every state that calls it
  LThink := TDictionary<Word, Int64>.Create;
  LContact := TDictionary<Word, Int64>.Create;
  LReact := TDictionary<Word, Int64>.Create;
  LBases := TDictionary<Integer, Integer>.Create;
  try
    repeat
      LChanged := False;
      for LIndex := 0 to LCount - 1 do
      begin
        LDef := AStates[LIndex];
        LKept := nil;
        for LCandidate in LCandidates[LIndex] do
        begin
          LOk := Same(LDef.Think, ReadLong(AImage, LCandidate + 16), LThink) and
            Same(LDef.Contact, ReadLong(AImage, LCandidate + 20), LContact) and
            Same(LDef.React, ReadLong(AImage, LCandidate + 24), LReact);
          if LOk then
            LKept := LKept + [LCandidate];
        end;
        if Length(LKept) <> Length(LCandidates[LIndex]) then
        begin
          LCandidates[LIndex] := LKept;
          LChanged := True;
        end;
        if Length(LCandidates[LIndex]) = 1 then
        begin
          LCandidate := LCandidates[LIndex][0];
          if (LDef.Think <> 0) and not LThink.ContainsKey(LDef.Think) then
          begin
            LThink.Add(LDef.Think, ReadLong(AImage, LCandidate + 16));
            LChanged := True;
          end;
          if (LDef.Contact <> 0) and not LContact.ContainsKey(LDef.Contact) then
          begin
            LContact.Add(LDef.Contact, ReadLong(AImage, LCandidate + 20));
            LChanged := True;
          end;
          if (LDef.React <> 0) and not LReact.ContainsKey(LDef.React) then
          begin
            LReact.Add(LDef.React, ReadLong(AImage, LCandidate + 24));
            LChanged := True;
          end;
        end;
      end;
    until not LChanged;
    // the data segment: for the states that were found once and whose successor was found once too, the address
    // that the successor field holds is the position of the successor minus where the segment begins
    for LIndex := 0 to LCount - 1 do
    begin
      LNext := AStates[LIndex].NextState;
      if (LNext < 0) or (Length(LCandidates[LIndex]) <> 1) or (Length(LCandidates[LNext]) <> 1) then
        Continue;
      LBase := LCandidates[LNext][0] - ReadWord(AImage, LCandidates[LIndex][0] + 28);
      if LBases.TryGetValue(LBase, LValue) then
        LBases[LBase] := LValue + 1
      else
        LBases.Add(LBase, 1);
    end;
    LBestBase := 0;
    LBestCount := 0;
    for LPair in LBases do
      if LPair.Value > LBestCount then
      begin
        LBestBase := LPair.Key;
        LBestCount := LPair.Value;
      end;
    if LBestCount = 0 then
      raise EKeenDataException.CreateFmt(SNotTheProgram, ['no state could be placed']);
    if LBases.Count > 1 then
      raise EKeenDataException.CreateFmt(SNotTheProgram, [Format('%d different data segments', [LBases.Count])]);
    // the successors that are still ambiguous: the one whose successor field points to a place where the
    // successor state is
    repeat
      LChanged := False;
      for LIndex := 0 to LCount - 1 do
      begin
        LNext := AStates[LIndex].NextState;
        if (LNext < 0) or (Length(LCandidates[LIndex]) <= 1) then
          Continue;
        LKept := nil;
        for LCandidate in LCandidates[LIndex] do
        begin
          LAnchor := LBestBase + ReadWord(AImage, LCandidate + 28);
          for LValue in LCandidates[LNext] do
            if LValue = LAnchor then
            begin
              LKept := LKept + [LCandidate];
              Break;
            end;
        end;
        if (Length(LKept) > 0) and (Length(LKept) < Length(LCandidates[LIndex])) then
        begin
          LCandidates[LIndex] := LKept;
          LChanged := True;
        end;
      end;
    until not LChanged;
    // the states of a source file are one after the other in the data, in the order that they are written: of the
    // places that are left, the one that follows the place of the state before (or comes before the next one)
    repeat
      LChanged := False;
      for LIndex := 0 to LCount - 1 do
      begin
        if Length(LCandidates[LIndex]) <= 1 then
          Continue;
        LKept := nil;
        for LCandidate in LCandidates[LIndex] do
          if ((LIndex > 0) and (Length(LCandidates[LIndex - 1]) = 1) and
            (LCandidates[LIndex - 1][0] + KEEN_DOS_STATE_SIZE = LCandidate)) or
            ((LIndex < LCount - 1) and (Length(LCandidates[LIndex + 1]) = 1) and
            (LCandidates[LIndex + 1][0] - KEEN_DOS_STATE_SIZE = LCandidate)) then
            LKept := LKept + [LCandidate];
        if (Length(LKept) > 0) and (Length(LKept) < Length(LCandidates[LIndex])) then
        begin
          LCandidates[LIndex] := LKept;
          LChanged := True;
        end;
      end;
    until not LChanged;
    SetLength(Result.Offsets, LCount);
    Result.DataStart := LBestBase;
    Result.Missing := 0;
    Result.Ambiguous := 0;
    LFound := 0;
    for LIndex := 0 to LCount - 1 do
    begin
      if Length(LCandidates[LIndex]) = 0 then
      begin
        Result.Offsets[LIndex] := -1;
        Inc(Result.Missing);
        Continue;
      end;
      Inc(LFound);
      if Length(LCandidates[LIndex]) > 1 then
        Inc(Result.Ambiguous);
      Result.Offsets[LIndex] := LCandidates[LIndex][0] - LBestBase;
    end;
    if LFound * 10 < LCount * 9 then
      raise EKeenDataException.CreateFmt(SNotTheProgram, [Format('%d of %d states found', [LFound, LCount])]);
  finally
    LBases.Free;
    LReact.Free;
    LContact.Free;
    LThink.Free;
  end;
end;

end.
