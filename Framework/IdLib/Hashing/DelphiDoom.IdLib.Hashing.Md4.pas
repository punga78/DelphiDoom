{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib hashing - the MD4 message digest (idLib MD4.cpp)          }
{                                                                              }
{  Rewrite of the digest of idLib (id Software, Doom 3, GPL v3) from RFC 1320. }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Hashing.Md4;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Hashing.Types;

type
  /// <summary>
  ///   MD4 over one buffer or a series of buffers (MD4_Init, MD4_Update, MD4_Final of idLib).
  ///   An instance computes one digest; <c>Final</c> returns it and <c>Reset</c> starts again.
  /// </summary>
  TIdMd4 = class
  private
    FState: array[0..3] of Cardinal;
    FBitCount: UInt64;
    FBuffer: array[0..63] of Byte;
    procedure Transform(const ABlock: PByte);
  public
    constructor Create;
    procedure Reset;
    procedure Update(const AData; const ASize: Integer);
    function Final: TIdDigest128;
    /// <summary>The digest of a buffer</summary>
    class function Digest(const AData; const ASize: Integer): TIdDigest128; static;
    /// <summary>MD4_BlockChecksum of idLib: the digest folded to 32 bits with xor</summary>
    class function BlockChecksum(const AData; const ASize: Integer): Cardinal; static;
  end;

implementation

const
  ROUND_2_ORDER: array[0..15] of Byte = (0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15);
  ROUND_3_ORDER: array[0..15] of Byte = (0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15);
  ROUND_1_SHIFT: array[0..3] of Byte = (3, 7, 11, 19);
  ROUND_2_SHIFT: array[0..3] of Byte = (3, 5, 9, 13);
  ROUND_3_SHIFT: array[0..3] of Byte = (3, 9, 11, 15);

function RotateLeft(const AValue: Cardinal; const ACount: Integer): Cardinal; inline;
begin
  Result := (AValue shl ACount) or (AValue shr (32 - ACount));
end;

{ TIdMd4 }

constructor TIdMd4.Create;
begin
  inherited Create;
  Reset;
end;

procedure TIdMd4.Reset;
begin
  FState[0] := $67452301;
  FState[1] := $EFCDAB89;
  FState[2] := $98BADCFE;
  FState[3] := $10325476;
  FBitCount := 0;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TIdMd4.Transform(const ABlock: PByte);
var
  LWords: array[0..15] of Cardinal;
  LIndex: Integer;
  LA, LB, LC, LD, LTemp: Cardinal;
begin
  for LIndex := 0 to 15 do
    LWords[LIndex] := Cardinal(ABlock[LIndex * 4]) or (Cardinal(ABlock[LIndex * 4 + 1]) shl 8) or
      (Cardinal(ABlock[LIndex * 4 + 2]) shl 16) or (Cardinal(ABlock[LIndex * 4 + 3]) shl 24);
  LA := FState[0];
  LB := FState[1];
  LC := FState[2];
  LD := FState[3];
  // After every step the four registers rotate: (a, b, c, d) becomes (d, t, b, c)
  for LIndex := 0 to 15 do
  begin
    LTemp := RotateLeft(LA + ((LB and LC) or ((not LB) and LD)) + LWords[LIndex], ROUND_1_SHIFT[LIndex and 3]);
    LA := LD; LD := LC; LC := LB; LB := LTemp;
  end;
  for LIndex := 0 to 15 do
  begin
    LTemp := RotateLeft(LA + ((LB and LC) or (LB and LD) or (LC and LD)) + LWords[ROUND_2_ORDER[LIndex]] +
      $5A827999, ROUND_2_SHIFT[LIndex and 3]);
    LA := LD; LD := LC; LC := LB; LB := LTemp;
  end;
  for LIndex := 0 to 15 do
  begin
    LTemp := RotateLeft(LA + (LB xor LC xor LD) + LWords[ROUND_3_ORDER[LIndex]] + $6ED9EBA1,
      ROUND_3_SHIFT[LIndex and 3]);
    LA := LD; LD := LC; LC := LB; LB := LTemp;
  end;
  FState[0] := FState[0] + LA;
  FState[1] := FState[1] + LB;
  FState[2] := FState[2] + LC;
  FState[3] := FState[3] + LD;
end;

procedure TIdMd4.Update(const AData; const ASize: Integer);
var
  LInput: PByte;
  LIndex, LRemaining, LPartLength: Integer;
begin
  if ASize <= 0 then
    Exit;
  LInput := @AData;
  LIndex := Integer((FBitCount shr 3) and $3F);
  Inc(FBitCount, UInt64(ASize) shl 3);
  LRemaining := ASize;
  LPartLength := 64 - LIndex;
  if LRemaining >= LPartLength then
  begin
    Move(LInput^, FBuffer[LIndex], LPartLength);
    Transform(@FBuffer[0]);
    Inc(LInput, LPartLength);
    Dec(LRemaining, LPartLength);
    LIndex := 0;
    while LRemaining >= 64 do
    begin
      Transform(LInput);
      Inc(LInput, 64);
      Dec(LRemaining, 64);
    end;
  end;
  if LRemaining > 0 then
    Move(LInput^, FBuffer[LIndex], LRemaining);
end;

function TIdMd4.Final: TIdDigest128;
var
  LBits: array[0..7] of Byte;
  LPadding: array[0..63] of Byte;
  LIndex, LPadLength, LWord: Integer;
  LBitCount: UInt64;
begin
  LBitCount := FBitCount;
  for LIndex := 0 to 7 do
    LBits[LIndex] := Byte(LBitCount shr (8 * LIndex));
  LIndex := Integer((FBitCount shr 3) and $3F);
  if LIndex < 56 then
    LPadLength := 56 - LIndex
  else
    LPadLength := 120 - LIndex;
  FillChar(LPadding, SizeOf(LPadding), 0);
  LPadding[0] := $80;
  Update(LPadding, LPadLength);
  Update(LBits, 8);
  for LWord := 0 to 3 do
    for LIndex := 0 to 3 do
      Result[LWord * 4 + LIndex] := Byte(FState[LWord] shr (8 * LIndex));
  Reset;
end;

class function TIdMd4.Digest(const AData; const ASize: Integer): TIdDigest128;
var
  LHash: TIdMd4;
begin
  LHash := TIdMd4.Create;
  try
    LHash.Update(AData, ASize);
    Result := LHash.Final;
  finally
    LHash.Free;
  end;
end;

class function TIdMd4.BlockChecksum(const AData; const ASize: Integer): Cardinal;
begin
  Result := TIdDigests.FoldToCardinal(Digest(AData, ASize));
end;

end.
