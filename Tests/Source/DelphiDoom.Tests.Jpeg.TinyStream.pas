{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - a stream written by hand            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.TinyStream;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The smallest JPEG streams that have an image: one component, 8x8
  ///   pixels, one block that has only the DC. Every pixel of the image has
  ///   the same value, which the tests can work out by hand
  /// </summary>
  TJpegTinyStream = class
  public
    /// <summary>
    ///   An 8x8 gray stream (quantization table of ones) whose only block has
    ///   the DC coefficient ADc
    /// </summary>
    /// <param name="AProgressive">One progressive scan of the DC instead of a sequential scan</param>
    /// <param name="AFillBeforeScan">Bytes put after the first marker (for example an empty APP0)</param>
    class function Build(ADc: Integer; AProgressive: Boolean;
      const AFillBeforeScan: TBytes = nil): TBytes; static;

    /// <summary>
    ///   The value of the pixels that the inverse DCT gives for a block that
    ///   has only the DC ADc (and a quantizer of 1): 128 plus ADc / 8,
    ///   rounded, and limited to 0..255
    /// </summary>
    class function ExpectedSample(ADc: Integer): Byte; static;
  end;

implementation

type
  TBitList = record
    Bytes: TBytes;
    Count: Integer;
    procedure Add(AValue, ABits: Integer);
    function Finish: TBytes;
  end;

procedure TBitList.Add(AValue, ABits: Integer);
var
  LIndex: Integer;
  LBit: Integer;
begin
  for LIndex := ABits - 1 downto 0 do
  begin
    LBit := (AValue shr LIndex) and 1;
    if Count mod 8 = 0 then
      SetLength(Bytes, Length(Bytes) + 1);
    if LBit <> 0 then
      Bytes[High(Bytes)] := Bytes[High(Bytes)] or Byte($80 shr (Count mod 8));
    Inc(Count);
  end;
end;

function TBitList.Finish: TBytes;
var
  LIndex: Integer;
  LByte: Integer;
begin
  // The last byte is filled with ones; a byte FF is followed by a zero
  while Count mod 8 <> 0 do
    Add(1, 1);
  SetLength(Result, 0);
  for LIndex := 0 to High(Bytes) do
  begin
    LByte := Bytes[LIndex];
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Byte(LByte);
    if LByte = $FF then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := 0;
    end;
  end;
end;

procedure Append(var ADest: TBytes; const ASource: array of Byte);
var
  LStart: Integer;
begin
  LStart := Length(ADest);
  SetLength(ADest, LStart + Length(ASource));
  if Length(ASource) > 0 then
    Move(ASource[0], ADest[LStart], Length(ASource));
end;

{ TJpegTinyStream }

class function TJpegTinyStream.Build(ADc: Integer; AProgressive: Boolean;
  const AFillBeforeScan: TBytes): TBytes;
var
  LBits: TBitList;
  LCategory: Integer;
  LMagnitude: Integer;
  LIndex: Integer;
  LTable: TBytes;
  LData: TBytes;
begin
  Result := nil;
  Append(Result, [$FF, $D8]);
  if Length(AFillBeforeScan) > 0 then
    Append(Result, AFillBeforeScan);

  // Quantization table 0: all ones
  Append(Result, [$FF, $DB, $00, $43, $00]);
  SetLength(LTable, 64);
  for LIndex := 0 to 63 do
    LTable[LIndex] := 1;
  Append(Result, LTable);

  // Frame: 8 bits, 8x8, one component
  if AProgressive then
    Append(Result, [$FF, $C2])
  else
    Append(Result, [$FF, $C0]);
  Append(Result, [$00, $0B, $08, $00, $08, $00, $08, $01, $01, $11, $00]);

  // DC table 0: twelve codes of 4 bits (0000 to 1011) for the sizes 0 to 11
  Append(Result, [$FF, $C4, $00, 2 + 1 + 16 + 12, $00, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Append(Result, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
  // AC table 0: the end of block is the code 0
  Append(Result, [$FF, $C4, $00, 2 + 1 + 16 + 1, $10, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  Append(Result, [0]);

  // Scan: the component, the tables, all the coefficients (or the DC)
  Append(Result, [$FF, $DA, $00, $08, $01, $01, $00]);
  if AProgressive then
    Append(Result, [0, 0, $00])
  else
    Append(Result, [0, 63, $00]);

  // The data: the size of the difference, the difference, the end of block
  LMagnitude := Abs(ADc);
  LCategory := 0;
  while LMagnitude <> 0 do
  begin
    Inc(LCategory);
    LMagnitude := LMagnitude shr 1;
  end;
  LBits := Default(TBitList);
  LBits.Add(LCategory, 4);
  if LCategory > 0 then
  begin
    if ADc < 0 then
      LBits.Add(ADc - 1, LCategory)
    else
      LBits.Add(ADc, LCategory);
  end;
  if not AProgressive then
    LBits.Add(0, 1);
  LData := LBits.Finish;
  Append(Result, LData);

  Append(Result, [$FF, $D9]);
end;

class function TJpegTinyStream.ExpectedSample(ADc: Integer): Byte;
var
  LValue: Integer;
begin
  // The DC is multiplied by 4 (two bits of precision), then 16 is added to
  // round and the sum is divided by 32
  LValue := ADc * 4 + 16;
  if LValue >= 0 then
    LValue := LValue div 32
  else
    LValue := -((-LValue + 31) div 32);
  LValue := LValue + 128;
  if LValue < 0 then
    LValue := 0
  else if LValue > 255 then
    LValue := 255;
  Result := Byte(LValue);
end;

end.
