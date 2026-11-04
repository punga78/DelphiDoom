{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - reads the bytes of a module file                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.ByteReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads numbers and text from a block of bytes. A read past the end
  ///   raises ETrackerException: a truncated module is an error, not a crash
  /// </summary>
  TTrackerByteReader = class
  private
    FData: TBytes;
    FPosition: Integer;
    procedure Need(const ACount: Integer);
    function GetSize: Integer;
  public
    constructor Create(const AData: TBytes);

    procedure Seek(const APosition: Integer);
    procedure Skip(const ACount: Integer);
    function ReadByte: Byte;
    /// <summary>Little endian</summary>
    function ReadWord: Word;
    function ReadCardinal: Cardinal;
    /// <summary>Big endian</summary>
    function ReadWordBE: Word;
    /// <summary>Text of ACount bytes, up to the first zero, with no trailing spaces</summary>
    function ReadText(const ACount: Integer): string;
    /// <summary>Raw bytes; fewer if the data ends and ATruncate is true</summary>
    function ReadBytes(const ACount: Integer; const ATruncate: Boolean = False): TBytes;
    function Remaining: Integer;

    property Position: Integer read FPosition;
    property Size: Integer read GetSize;
    property Data: TBytes read FData;
  end;

implementation

uses
  DelphiDoom.Tracker.Types;

const
  STruncated = 'The module is truncated';

{ TTrackerByteReader }

constructor TTrackerByteReader.Create(const AData: TBytes);
begin
  inherited Create;
  FData := AData;
end;

function TTrackerByteReader.GetSize: Integer;
begin
  Result := Length(FData);
end;

procedure TTrackerByteReader.Need(const ACount: Integer);
begin
  if (ACount < 0) or (FPosition + ACount > Length(FData)) then
    raise ETrackerException.Create(STruncated);
end;

function TTrackerByteReader.Remaining: Integer;
begin
  Result := Length(FData) - FPosition;
end;

procedure TTrackerByteReader.Seek(const APosition: Integer);
begin
  if (APosition < 0) or (APosition > Length(FData)) then
    raise ETrackerException.Create(STruncated);
  FPosition := APosition;
end;

procedure TTrackerByteReader.Skip(const ACount: Integer);
begin
  Need(ACount);
  Inc(FPosition, ACount);
end;

function TTrackerByteReader.ReadByte: Byte;
begin
  Need(1);
  Result := FData[FPosition];
  Inc(FPosition);
end;

function TTrackerByteReader.ReadWord: Word;
begin
  Need(2);
  Result := FData[FPosition] or (FData[FPosition + 1] shl 8);
  Inc(FPosition, 2);
end;

function TTrackerByteReader.ReadCardinal: Cardinal;
begin
  Need(4);
  Result := Cardinal(FData[FPosition]) or (Cardinal(FData[FPosition + 1]) shl 8) or
    (Cardinal(FData[FPosition + 2]) shl 16) or (Cardinal(FData[FPosition + 3]) shl 24);
  Inc(FPosition, 4);
end;

function TTrackerByteReader.ReadWordBE: Word;
begin
  Need(2);
  Result := (FData[FPosition] shl 8) or FData[FPosition + 1];
  Inc(FPosition, 2);
end;

function TTrackerByteReader.ReadText(const ACount: Integer): string;
var
  LIndex: Integer;
  LChar: Byte;
begin
  Need(ACount);
  Result := '';
  for LIndex := 0 to ACount - 1 do
  begin
    LChar := FData[FPosition + LIndex];
    if LChar = 0 then
      Break;
    Result := Result + Char(LChar);
  end;
  Inc(FPosition, ACount);
  Result := TrimRight(Result);
end;

function TTrackerByteReader.ReadBytes(const ACount: Integer; const ATruncate: Boolean): TBytes;
var
  LCount: Integer;
begin
  LCount := ACount;
  if ATruncate and (FPosition + LCount > Length(FData)) then
    LCount := Length(FData) - FPosition;
  Need(LCount);
  SetLength(Result, LCount);
  if LCount > 0 then
    Move(FData[FPosition], Result[0], LCount);
  Inc(FPosition, LCount);
end;

end.

