{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixScoreTable                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_score.pas of Rad-X (the table of the ten best pilots)         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Score.Table;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Debriefing;

const
  RADIX_PILOT_NAME_SIZE = 16;
  RADIX_SCORE_COUNT = 10;
  RADIX_SCORE_DIGEST_SIZE = 20;

type
  /// <summary>
  ///   One row of the file of the scores, as Rad-X wrote it (scrotetableitem_t): 51 bytes. Digest is
  ///   the SHA-1 of the 31 bytes before its text (its length byte, 20, is one of them)
  /// </summary>
  TRadixScoreEntry = packed record
    Name: string[RADIX_PILOT_NAME_SIZE];
    Episode: Integer;
    Map: Integer;
    Skill: Byte;
    Rating: Integer;
    Digest: string[RADIX_SCORE_DIGEST_SIZE];
  end;

  /// <summary>
  ///   The table of the ten best pilots of Radix: sorted by rating (the best first, a new pilot goes
  ///   after the ones with the same rating), with the file format of Rad-X (ten rows of 51 bytes).
  ///   A row whose digest is wrong is emptied when the file is read, as Rad-X did
  /// </summary>
  TRadixScoreTable = class
  public const
    ENTRY_SIZE = 51;
    FILE_SIZE = RADIX_SCORE_COUNT * ENTRY_SIZE;
    /// <summary>The levels of an episode: the rating of a pilot is the sum of their scores</summary>
    LEVELS_PER_EPISODE = 9;
    /// <summary>What PositionOf gives for a rating that does not enter the table</summary>
    NO_POSITION = RADIX_SCORE_COUNT + 1;
  strict private
    FEntries: array[0..RADIX_SCORE_COUNT - 1] of TRadixScoreEntry;
    class function DigestOf(const AEntry: TRadixScoreEntry): ShortString; static;
    procedure Seal(AIndex: Integer);
    procedure Sort;
    function GetEntry(AIndex: Integer): TRadixScoreEntry;
  public
    constructor Create;
    /// <summary>Ten empty rows</summary>
    procedure Clear;
    /// <summary>
    ///   The score of one level: the five marks of the debriefing, the secondary objective twice
    ///   (as RX_CalculatePlayerSingleScore of Rad-X)
    /// </summary>
    class function LevelScore(const AScore: TRadixDebriefingScore): Integer; static;
    /// <summary>
    ///   What the debriefing foresees: the rating of a pilot that flies the nine levels of an
    ///   episode as this one
    /// </summary>
    class function ProjectedRating(const AScore: TRadixDebriefingScore): Integer; static;
    /// <summary>The place (1..10) that a rating would take, NO_POSITION if it does not enter</summary>
    function PositionOf(ARating: Integer): Integer;
    /// <summary>
    ///   Puts the pilot in the table if the rating is better than one of the ten; the place taken
    ///   (1..10) or NO_POSITION. The name is cut at 16 characters
    /// </summary>
    function Add(const AName: AnsiString; AEpisode, AMap, ASkill, ARating: Integer): Integer;
    /// <summary>True for a row that holds a pilot (episode and map are not zero)</summary>
    function IsUsed(AIndex: Integer): Boolean;
    /// <summary>The bytes of the file (510)</summary>
    function Encode: TBytes;
    /// <summary>
    ///   Reads the bytes of a file. ERadixException (the table is left empty) if the size is not the
    ///   one of the file; the number of rows emptied because their digest was wrong is the result
    /// </summary>
    function Decode(const ABytes: TBytes): Integer;
    /// <summary>The rows from the best, 0..9</summary>
    property Entries[AIndex: Integer]: TRadixScoreEntry read GetEntry; default;
  end;

implementation

uses
  DelphiDoom.MathCore.Sha1,
  DelphiDoom.Radix.Types;

const
  SWrongSize = 'Radix score table: the file is %d bytes long, not %d';
  SWrongIndex = 'Radix score table: there is no row %d';
  // what the digest covers: the row without the text of the digest
  DIGESTED_SIZE = SizeOf(TRadixScoreEntry) - RADIX_SCORE_DIGEST_SIZE;

{ TRadixScoreTable }

constructor TRadixScoreTable.Create;
begin
  inherited Create;
  Clear;
end;

class function TRadixScoreTable.DigestOf(const AEntry: TRadixScoreEntry): ShortString;
var
  LEntry: TRadixScoreEntry;
begin
  LEntry := AEntry;
  // the length byte of the digest is inside what is digested: always the one of a full digest
  LEntry.Digest[0] := AnsiChar(RADIX_SCORE_DIGEST_SIZE);
  Result := ShortString(TSha1.ToRawString(TSha1.Calculate(LEntry, DIGESTED_SIZE)));
end;

procedure TRadixScoreTable.Seal(AIndex: Integer);
begin
  FEntries[AIndex].Digest := DigestOf(FEntries[AIndex]);
end;

procedure TRadixScoreTable.Clear;
var
  LIndex: Integer;
begin
  FillChar(FEntries, SizeOf(FEntries), 0);
  for LIndex := 0 to RADIX_SCORE_COUNT - 1 do
    Seal(LIndex);
end;

procedure TRadixScoreTable.Sort;
var
  LPass: Integer;
  LIndex: Integer;
  LEntry: TRadixScoreEntry;
begin
  // the bubble sort of Rad-X: rows with the same rating keep their order
  for LPass := 0 to RADIX_SCORE_COUNT - 1 do
    for LIndex := 0 to RADIX_SCORE_COUNT - 2 do
      if FEntries[LIndex].Rating < FEntries[LIndex + 1].Rating then
      begin
        LEntry := FEntries[LIndex];
        FEntries[LIndex] := FEntries[LIndex + 1];
        FEntries[LIndex + 1] := LEntry;
      end;
end;

function TRadixScoreTable.GetEntry(AIndex: Integer): TRadixScoreEntry;
begin
  if (AIndex < 0) or (AIndex >= RADIX_SCORE_COUNT) then
    raise ERadixException.CreateFmt(SWrongIndex, [AIndex]);
  Result := FEntries[AIndex];
end;

class function TRadixScoreTable.LevelScore(const AScore: TRadixDebriefingScore): Integer;
begin
  Result := AScore.Secondary + AScore.Secondary + AScore.KillRatio + AScore.FlyingTime + AScore.Secrets +
    AScore.ProficientFlying;
end;

class function TRadixScoreTable.ProjectedRating(const AScore: TRadixDebriefingScore): Integer;
begin
  Result := LevelScore(AScore) * LEVELS_PER_EPISODE;
end;

function TRadixScoreTable.PositionOf(ARating: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RADIX_SCORE_COUNT - 1 do
    if ARating > FEntries[LIndex].Rating then
      Exit(LIndex + 1);
  Result := NO_POSITION;
end;

function TRadixScoreTable.Add(const AName: AnsiString; AEpisode, AMap, ASkill, ARating: Integer): Integer;
var
  LLast: Integer;
begin
  Result := PositionOf(ARating);
  if Result = NO_POSITION then
    Exit;
  // the new pilot takes the place of the last one, then the table is sorted again
  LLast := RADIX_SCORE_COUNT - 1;
  FillChar(FEntries[LLast], SizeOf(TRadixScoreEntry), 0);
  FEntries[LLast].Name := ShortString(Copy(AName, 1, RADIX_PILOT_NAME_SIZE));
  FEntries[LLast].Episode := AEpisode;
  FEntries[LLast].Map := AMap;
  FEntries[LLast].Skill := Byte(ASkill and $FF);
  FEntries[LLast].Rating := ARating;
  Seal(LLast);
  Sort;
end;

function TRadixScoreTable.IsUsed(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < RADIX_SCORE_COUNT) and (FEntries[AIndex].Episode <> 0) and
    (FEntries[AIndex].Map <> 0);
end;

function TRadixScoreTable.Encode: TBytes;
begin
  SetLength(Result, SizeOf(FEntries));
  Move(FEntries, Result[0], SizeOf(FEntries));
end;

function TRadixScoreTable.Decode(const ABytes: TBytes): Integer;
var
  LIndex: Integer;
begin
  Clear;
  if Length(ABytes) <> SizeOf(FEntries) then
    raise ERadixException.CreateFmt(SWrongSize, [Length(ABytes), SizeOf(FEntries)]);
  Move(ABytes[0], FEntries, SizeOf(FEntries));
  Result := 0;
  for LIndex := 0 to RADIX_SCORE_COUNT - 1 do
    if FEntries[LIndex].Digest <> DigestOf(FEntries[LIndex]) then
    begin
      FillChar(FEntries[LIndex], SizeOf(TRadixScoreEntry), 0);
      Seal(LIndex);
      Inc(Result);
    end;
  Sort;
end;

end.
