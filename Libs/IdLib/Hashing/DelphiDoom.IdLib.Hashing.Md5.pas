{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib hashing - the MD5 message digest (idLib MD5.cpp)          }
{                                                                              }
{  Rewrite of the digest of idLib (id Software, Doom 3, GPL v3) from RFC 1321. }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Hashing.Md5;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Hashing.Types;

type
  /// <summary>
  ///   MD5 over one buffer or a series of buffers (MD5_Init, MD5_Update, MD5_Final of idLib).
  ///   An instance computes one digest; <c>Final</c> returns it and <c>Reset</c> starts again.
  /// </summary>
  TIdMd5 = class
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
    /// <summary>MD5_BlockChecksum of idLib: the digest folded to 32 bits with xor</summary>
    class function BlockChecksum(const AData; const ASize: Integer): Cardinal; static;
  end;

implementation

const
  SINE_TABLE: array[0..63] of Cardinal = (
    $D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A, $A8304613, $FD469501,
    $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE, $6B901122, $FD987193, $A679438E, $49B40821,
    $F61E2562, $C040B340, $265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,
    $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8, $676F02D9, $8D2A4C8A,
    $FFFA3942, $8771F681, $6D9D6122, $FDE5380C, $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70,
    $289B7EC6, $EAA127FA, $D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,
    $F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92, $FFEFF47D, $85845DD1,
    $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1, $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391);

  SHIFTS: array[0..15] of Byte = (7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21);

function RotateLeft(const AValue: Cardinal; const ACount: Integer): Cardinal; inline;
begin
  Result := (AValue shl ACount) or (AValue shr (32 - ACount));
end;

{ TIdMd5 }

constructor TIdMd5.Create;
begin
  inherited Create;
  Reset;
end;

procedure TIdMd5.Reset;
begin
  FState[0] := $67452301;
  FState[1] := $EFCDAB89;
  FState[2] := $98BADCFE;
  FState[3] := $10325476;
  FBitCount := 0;
  FillChar(FBuffer, SizeOf(FBuffer), 0);
end;

procedure TIdMd5.Transform(const ABlock: PByte);
var
  LWords: array[0..15] of Cardinal;
  LStep, LWordIndex: Integer;
  LA, LB, LC, LD, LMix, LTemp: Cardinal;
begin
  for LStep := 0 to 15 do
    LWords[LStep] := Cardinal(ABlock[LStep * 4]) or (Cardinal(ABlock[LStep * 4 + 1]) shl 8) or
      (Cardinal(ABlock[LStep * 4 + 2]) shl 16) or (Cardinal(ABlock[LStep * 4 + 3]) shl 24);
  LA := FState[0];
  LB := FState[1];
  LC := FState[2];
  LD := FState[3];
  for LStep := 0 to 63 do
  begin
    case LStep shr 4 of
      0:
        begin
          LMix := (LB and LC) or ((not LB) and LD);
          LWordIndex := LStep;
        end;
      1:
        begin
          LMix := (LB and LD) or (LC and (not LD));
          LWordIndex := (5 * LStep + 1) and 15;
        end;
      2:
        begin
          LMix := LB xor LC xor LD;
          LWordIndex := (3 * LStep + 5) and 15;
        end;
    else
      begin
        LMix := LC xor (LB or (not LD));
        LWordIndex := (7 * LStep) and 15;
      end;
    end;
    LTemp := LB + RotateLeft(LA + LMix + SINE_TABLE[LStep] + LWords[LWordIndex],
      SHIFTS[((LStep shr 4) shl 2) + (LStep and 3)]);
    LA := LD;
    LD := LC;
    LC := LB;
    LB := LTemp;
  end;
  FState[0] := FState[0] + LA;
  FState[1] := FState[1] + LB;
  FState[2] := FState[2] + LC;
  FState[3] := FState[3] + LD;
end;

procedure TIdMd5.Update(const AData; const ASize: Integer);
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

function TIdMd5.Final: TIdDigest128;
var
  LBits: array[0..7] of Byte;
  LPadding: array[0..63] of Byte;
  LIndex, LPadLength, LWord: Integer;
begin
  for LIndex := 0 to 7 do
    LBits[LIndex] := Byte(FBitCount shr (8 * LIndex));
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

class function TIdMd5.Digest(const AData; const ASize: Integer): TIdDigest128;
var
  LHash: TIdMd5;
begin
  LHash := TIdMd5.Create;
  try
    LHash.Update(AData, ASize);
    Result := LHash.Final;
  finally
    LHash.Free;
  end;
end;

class function TIdMd5.BlockChecksum(const AData; const ASize: Integer): Cardinal;
begin
  Result := TIdDigests.FoldToCardinal(Digest(AData, ASize));
end;

end.
