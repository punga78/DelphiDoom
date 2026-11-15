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
  System.SysUtils,
  DelphiDoom.Bytes.Reader;

type
  /// <summary>
  ///   Result of reading a variable length number
  /// </summary>
  TXmiVarLengthStatus = (Complete, Overflow, EndOfData);

  /// <summary>
  ///   A cursor over a part of a block of bytes (TByteReader of Libs\Bytes, created with the
  ///   start and the length of the part): ReadByte raises EXmiDataException at the end of the
  ///   part. It copies nothing: the block must stay alive while the reader is used. It adds
  ///   the variable length numbers of MIDI and XMI
  /// </summary>
  TXmiByteReader = class(TByteReader)
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  public
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
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Types;

const
  // A number of more than 64 bits is an error
  MAX_BITS = 64;

{ TXmiByteReader }

procedure TXmiByteReader.RaiseOverrun(ACount: Integer);
begin
  raise EXmiDataException.Create('Unexpected end of the data');
end;

function TXmiByteReader.ReadMidiNumber(out AValue: UInt64): TXmiVarLengthStatus;
var
  LByte: Byte;
  LBits: Integer;
begin
  AValue := 0;
  if AtEnd then
    Exit(TXmiVarLengthStatus.EndOfData);

  LByte := ReadByte;
  LBits := 7;
  AValue := LByte and 127;
  while (LByte shr 7) = 1 do
  begin
    if AtEnd then
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
  if AtEnd then
    Exit(TXmiVarLengthStatus.EndOfData);

  LByte := ReadByte;
  while LByte = $7F do
  begin
    AValue := AValue + LByte;
    if AtEnd then
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
