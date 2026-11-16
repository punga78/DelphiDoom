{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the SHA-1 digest                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Sha1;

{$Q-}
{$R-}

interface

uses
  System.SysUtils;

const
  /// <summary>Bytes of a SHA-1 digest</summary>
  SHA1_DIGEST_SIZE = 20;

type
  /// <summary>
  ///   The SHA-1 of the old m_sha1 in pure Pascal (the old one had asm for the byte swap and the
  ///   rotation). It can be fed in pieces. The digest is the standard one: 20 bytes.
  /// </summary>
  TSha1 = class
  private
    FState: array[0..4] of Cardinal;
    FBlock: array[0..63] of Byte;
    FBlockLength: Integer;
    FTotalLength: Int64;
    procedure ProcessBlock(const ABlock: array of Byte);
  public
    constructor Create;
    procedure Reset;
    procedure Update(const ABuffer; const ASize: Integer);
    /// <summary>Closes the digest and gives it; the object starts again from zero</summary>
    function Finish: TBytes;
    /// <summary>The digest of a buffer</summary>
    class function Calculate(const ABuffer; const ASize: Integer): TBytes; static;
    /// <summary>The digest of the bytes of a string</summary>
    class function CalculateAnsi(const AText: AnsiString): TBytes; static;
    /// <summary>The 20 bytes as a string of 20 characters, the form of the old SHA1_CalcSHA1String</summary>
    class function ToRawString(const ADigest: TBytes): AnsiString; static;
    /// <summary>The digest as 40 hexadecimal digits in lower case</summary>
    class function ToHex(const ADigest: TBytes): string; static;
  end;

implementation

function RotateLeft(const AValue: Cardinal; const ABits: Integer): Cardinal; inline;
begin
  Result := (AValue shl ABits) or (AValue shr (32 - ABits));
end;

{ TSha1 }

constructor TSha1.Create;
begin
  inherited Create;
  Reset;
end;

procedure TSha1.Reset;
begin
  FState[0] := $67452301;
  FState[1] := $EFCDAB89;
  FState[2] := $98BADCFE;
  FState[3] := $10325476;
  FState[4] := $C3D2E1F0;
  FBlockLength := 0;
  FTotalLength := 0;
end;

procedure TSha1.ProcessBlock(const ABlock: array of Byte);
var
  LW: array[0..79] of Cardinal;
  LA, LB, LC, LD, LE, LTemp, LK, LF: Cardinal;
  LIndex: Integer;
begin
  for LIndex := 0 to 15 do
    LW[LIndex] := (Cardinal(ABlock[LIndex * 4]) shl 24) or (Cardinal(ABlock[LIndex * 4 + 1]) shl 16) or
      (Cardinal(ABlock[LIndex * 4 + 2]) shl 8) or Cardinal(ABlock[LIndex * 4 + 3]);
  for LIndex := 16 to 79 do
    LW[LIndex] := RotateLeft(LW[LIndex - 3] xor LW[LIndex - 8] xor LW[LIndex - 14] xor LW[LIndex - 16], 1);

  LA := FState[0];
  LB := FState[1];
  LC := FState[2];
  LD := FState[3];
  LE := FState[4];

  for LIndex := 0 to 79 do
  begin
    if LIndex < 20 then
    begin
      LF := LD xor (LB and (LC xor LD));
      LK := $5A827999;
    end
    else if LIndex < 40 then
    begin
      LF := LB xor LC xor LD;
      LK := $6ED9EBA1;
    end
    else if LIndex < 60 then
    begin
      LF := (LB and LC) or (LD and (LB or LC));
      LK := $8F1BBCDC;
    end
    else
    begin
      LF := LB xor LC xor LD;
      LK := $CA62C1D6;
    end;
    LTemp := RotateLeft(LA, 5) + LF + LE + LK + LW[LIndex];
    LE := LD;
    LD := LC;
    LC := RotateLeft(LB, 30);
    LB := LA;
    LA := LTemp;
  end;

  Inc(FState[0], LA);
  Inc(FState[1], LB);
  Inc(FState[2], LC);
  Inc(FState[3], LD);
  Inc(FState[4], LE);
end;

procedure TSha1.Update(const ABuffer; const ASize: Integer);
var
  LBytes: PByte;
  LRemaining: Integer;
  LCount: Integer;
begin
  if ASize <= 0 then
    Exit;
  LBytes := @ABuffer;
  LRemaining := ASize;
  Inc(FTotalLength, ASize);
  while LRemaining > 0 do
  begin
    LCount := 64 - FBlockLength;
    if LCount > LRemaining then
      LCount := LRemaining;
    Move(LBytes^, FBlock[FBlockLength], LCount);
    Inc(FBlockLength, LCount);
    Inc(LBytes, LCount);
    Dec(LRemaining, LCount);
    if FBlockLength = 64 then
    begin
      ProcessBlock(FBlock);
      FBlockLength := 0;
    end;
  end;
end;

function TSha1.Finish: TBytes;
var
  LBitLength: Int64;
  LIndex: Integer;
  LPadding: Byte;
  LLengthBytes: array[0..7] of Byte;
  LZero: Byte;
begin
  LBitLength := FTotalLength * 8;
  for LIndex := 0 to 7 do
    LLengthBytes[LIndex] := Byte(LBitLength shr (56 - 8 * LIndex));

  LPadding := $80;
  LZero := 0;
  Update(LPadding, 1);
  while FBlockLength <> 56 do
    Update(LZero, 1);
  Update(LLengthBytes, 8);

  SetLength(Result, SHA1_DIGEST_SIZE);
  for LIndex := 0 to SHA1_DIGEST_SIZE - 1 do
    Result[LIndex] := Byte(FState[LIndex div 4] shr (24 - 8 * (LIndex mod 4)));
  Reset;
end;

class function TSha1.Calculate(const ABuffer; const ASize: Integer): TBytes;
var
  LSha: TSha1;
begin
  LSha := TSha1.Create;
  try
    LSha.Update(ABuffer, ASize);
    Result := LSha.Finish;
  finally
    LSha.Free;
  end;
end;

class function TSha1.CalculateAnsi(const AText: AnsiString): TBytes;
var
  LSha: TSha1;
begin
  LSha := TSha1.Create;
  try
    if Length(AText) > 0 then
      LSha.Update(Pointer(AText)^, Length(AText));
    Result := LSha.Finish;
  finally
    LSha.Free;
  end;
end;

class function TSha1.ToRawString(const ADigest: TBytes): AnsiString;
begin
  SetLength(Result, Length(ADigest));
  if Length(ADigest) > 0 then
    Move(ADigest[0], Pointer(Result)^, Length(ADigest));
end;

class function TSha1.ToHex(const ADigest: TBytes): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to Length(ADigest) - 1 do
    Result := Result + LowerCase(IntToHex(ADigest[LIndex], 2));
end;

end.
