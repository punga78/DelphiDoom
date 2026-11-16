{******************************************************************************}
{                                                                              }
{  DelphiDoom: bytes library - cursor over a block of bytes (issue #229)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Bytes.Reader;

// The numbers are built from single bytes (shifts that drop the high bits on purpose)
{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Types;

type
  /// <summary>
  ///   A cursor over a block of bytes: little endian and big endian numbers, raw blocks, skipping and seeking.
  ///   A read that goes past the end calls RaiseOverrun, which a library overrides to raise its own exception
  ///   with its own message (the default raises EByteReaderException): no read ever touches memory that is not
  ///   there. The bytes are not copied, so the array must stay alive while the reader is used
  /// </summary>
  TByteReader = class
  strict private
    FData: TBytes;
    FStart: Integer;
    FLimit: Integer;
    FPosition: Integer;
    function GetSize: Integer;
    function GetAtEnd: Boolean;
  protected
    /// <summary>Raises the exception of a read of ACount bytes that does not fit; the default is EByteReaderException</summary>
    procedure RaiseOverrun(ACount: Integer); virtual;
    /// <summary>Checks that ACount bytes can be read from the position; calls RaiseOverrun if not</summary>
    procedure Need(ACount: Integer);
  public
    constructor Create(const AData: TBytes); overload;
    /// <summary>A reader of the part of AData that starts at AStart and has ACount bytes</summary>
    /// <exception cref="EArgumentOutOfRangeException">The part is not inside AData</exception>
    constructor Create(const AData: TBytes; AStart, ACount: Integer); overload;
    function ReadByte: Byte;
    /// <summary>Little endian</summary>
    function ReadWord: Word;
    /// <summary>Little endian</summary>
    function ReadSmallInt: SmallInt;
    /// <summary>Little endian</summary>
    function ReadCardinal: Cardinal;
    /// <summary>Little endian</summary>
    function ReadInteger: Integer;
    /// <summary>Big endian</summary>
    function ReadWordBE: Word;
    /// <summary>Big endian</summary>
    function ReadCardinalBE: Cardinal;
    /// <summary>A copy of the next ACount bytes</summary>
    function ReadBlock(ACount: Integer): TBytes;
    procedure Skip(ACount: Integer);
    /// <summary>Moves the cursor; the position is not checked until the next read</summary>
    procedure Seek(APosition: Integer); virtual;
    /// <summary>Moves the cursor back by one byte, but not before the start of the part</summary>
    procedure StepBack;
    /// <summary>Bytes still to read (negative if the cursor was moved past the end)</summary>
    function Remaining: Integer;
    property Position: Integer read FPosition write Seek;
    /// <summary>Length of the whole array</summary>
    property Size: Integer read GetSize;
    property Data: TBytes read FData;
    property AtEnd: Boolean read GetAtEnd;
  end;

implementation

{ TByteReader }

constructor TByteReader.Create(const AData: TBytes);
begin
  inherited Create;
  FData := AData;
  FLimit := Length(AData);
end;

constructor TByteReader.Create(const AData: TBytes; AStart, ACount: Integer);
begin
  inherited Create;
  if (AStart < 0) or (ACount < 0) or (AStart > Length(AData)) or
    (Int64(AStart) + ACount > Length(AData)) then
    raise EArgumentOutOfRangeException.Create('The part is outside the data');
  FData := AData;
  FStart := AStart;
  FLimit := AStart + ACount;
  FPosition := AStart;
end;

function TByteReader.GetSize: Integer;
begin
  Result := Length(FData);
end;

function TByteReader.GetAtEnd: Boolean;
begin
  Result := FPosition >= FLimit;
end;

procedure TByteReader.RaiseOverrun(ACount: Integer);
begin
  raise EByteReaderException.CreateFmt(
    'Read of %d bytes at %d goes past the end of the data (%d bytes)', [ACount, FPosition, Length(FData)]);
end;

procedure TByteReader.Need(ACount: Integer);
begin
  if (ACount < 0) or (FPosition < 0) or (Int64(FPosition) + ACount > FLimit) then
    RaiseOverrun(ACount);
end;

function TByteReader.ReadByte: Byte;
begin
  Need(1);
  Result := FData[FPosition];
  Inc(FPosition);
end;

function TByteReader.ReadWord: Word;
begin
  Need(2);
  Result := Word(FData[FPosition]) or (Word(FData[FPosition + 1]) shl 8);
  Inc(FPosition, 2);
end;

function TByteReader.ReadSmallInt: SmallInt;
begin
  Result := SmallInt(ReadWord);
end;

function TByteReader.ReadCardinal: Cardinal;
begin
  Need(4);
  Result := Cardinal(FData[FPosition]) or (Cardinal(FData[FPosition + 1]) shl 8) or
    (Cardinal(FData[FPosition + 2]) shl 16) or (Cardinal(FData[FPosition + 3]) shl 24);
  Inc(FPosition, 4);
end;

function TByteReader.ReadInteger: Integer;
begin
  Result := Integer(ReadCardinal);
end;

function TByteReader.ReadWordBE: Word;
begin
  Need(2);
  Result := (Word(FData[FPosition]) shl 8) or Word(FData[FPosition + 1]);
  Inc(FPosition, 2);
end;

function TByteReader.ReadCardinalBE: Cardinal;
begin
  Need(4);
  Result := (Cardinal(FData[FPosition]) shl 24) or (Cardinal(FData[FPosition + 1]) shl 16) or
    (Cardinal(FData[FPosition + 2]) shl 8) or Cardinal(FData[FPosition + 3]);
  Inc(FPosition, 4);
end;

function TByteReader.ReadBlock(ACount: Integer): TBytes;
begin
  Need(ACount);
  SetLength(Result, ACount);
  if ACount > 0 then
    Move(FData[FPosition], Result[0], ACount);
  Inc(FPosition, ACount);
end;

procedure TByteReader.Skip(ACount: Integer);
begin
  Need(ACount);
  Inc(FPosition, ACount);
end;

procedure TByteReader.Seek(APosition: Integer);
begin
  FPosition := APosition;
end;

procedure TByteReader.StepBack;
begin
  if FPosition > FStart then
    Dec(FPosition);
end;

function TByteReader.Remaining: Integer;
begin
  Result := FLimit - FPosition;
end;

end.
