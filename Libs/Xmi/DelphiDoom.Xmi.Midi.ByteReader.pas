{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - reads bytes and variable length numbers           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Midi.ByteReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Result of reading a variable length number
  /// </summary>
  TXmiVarLengthStatus = (Complete, Overflow, EndOfData);

  /// <summary>
  ///   A cursor over a block of bytes. It copies nothing: the block must stay
  ///   alive while the reader is used
  /// </summary>
  TXmiByteReader = class
  private
    FData: TBytes;
    FStart: Integer;
    FEnd: Integer;
    FPosition: Integer;
    function GetAtEnd: Boolean;
  public
    /// <param name="AStart">First byte of the part to read</param>
    /// <param name="ACount">Number of bytes of the part to read</param>
    constructor Create(const AData: TBytes; AStart, ACount: Integer);

    /// <summary>
    ///   Reads a byte; raises EXmiDataException at the end of the data
    /// </summary>
    function ReadByte: Byte;

    /// <summary>
    ///   Number of bytes still to read
    /// </summary>
    function Remaining: Integer;

    /// <summary>
    ///   Moves the cursor back by one byte (after looking at a byte that
    ///   belongs to the next element)
    /// </summary>
    procedure StepBack;

    /// <summary>
    ///   MIDI number: seven bits per byte, the most significant first, the
    ///   last byte without the high bit
    /// </summary>
    function ReadMidiNumber(out AValue: UInt64): TXmiVarLengthStatus;

    /// <summary>
    ///   Number of the delays of XMI events: bytes of $7F are summed until a
    ///   byte below $7F; a byte with the high bit starts the next event and
    ///   is not consumed
    /// </summary>
    function ReadXmiDelay(out AValue: UInt64): TXmiVarLengthStatus;

    property AtEnd: Boolean read GetAtEnd;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types;

const
  // A number of more than 64 bits is an error
  MAX_BITS = 64;

{ TXmiByteReader }

constructor TXmiByteReader.Create(const AData: TBytes; AStart, ACount: Integer);
begin
  inherited Create;
  if (AStart < 0) or (ACount < 0) or (AStart > Length(AData)) or
     (AStart + ACount > Length(AData)) then
    raise EArgumentOutOfRangeException.Create('The part is outside the data');

  FData := AData;
  FStart := AStart;
  FEnd := AStart + ACount;
  FPosition := AStart;
end;

function TXmiByteReader.GetAtEnd: Boolean;
begin
  Result := FPosition >= FEnd;
end;

function TXmiByteReader.Remaining: Integer;
begin
  Result := FEnd - FPosition;
end;

function TXmiByteReader.ReadByte: Byte;
begin
  if FPosition >= FEnd then
    raise EXmiDataException.Create('Unexpected end of the data');

  Result := FData[FPosition];
  Inc(FPosition);
end;

procedure TXmiByteReader.StepBack;
begin
  if FPosition > FStart then
    Dec(FPosition);
end;

function TXmiByteReader.ReadMidiNumber(out AValue: UInt64): TXmiVarLengthStatus;
var
  LByte: Byte;
  LBits: Integer;
begin
  AValue := 0;
  if FPosition >= FEnd then
    Exit(TXmiVarLengthStatus.EndOfData);

  LByte := ReadByte;
  LBits := 7;
  AValue := LByte and 127;
  while (LByte shr 7) = 1 do
  begin
    if FPosition >= FEnd then
      Exit(TXmiVarLengthStatus.EndOfData);

    LByte := ReadByte;
    if LBits + 7 <= MAX_BITS then
      Inc(LBits, 7)
    else
      Exit(TXmiVarLengthStatus.Overflow);

    AValue := (AValue shl 7) or (LByte and 127);
  end;
  Result := TXmiVarLengthStatus.Complete;
end;

function TXmiByteReader.ReadXmiDelay(out AValue: UInt64): TXmiVarLengthStatus;
var
  LByte: Byte;
begin
  AValue := 0;
  if FPosition >= FEnd then
    Exit(TXmiVarLengthStatus.EndOfData);

  LByte := ReadByte;
  while LByte = $7F do
  begin
    AValue := AValue + LByte;
    if FPosition >= FEnd then
      Exit(TXmiVarLengthStatus.EndOfData);

    LByte := ReadByte;
  end;

  if LByte >= $80 then
    StepBack
  else
    AValue := AValue + LByte;
  Result := TXmiVarLengthStatus.Complete;
end;

end.
