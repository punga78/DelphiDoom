{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - sequential reader of a buffer                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.ByteReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads numbers and markers from a buffer, in either byte order. Reading
  ///   past the end gives zero and sets Overrun, like the header reader of
  ///   libsndfile: the caller decides what that means
  /// </summary>
  TSoundByteReader = record
  private
    FData: TBytes;
    FPosition: Int64;
    FBigEndian: Boolean;
    FOverrun: Boolean;
    function Take(ACount: Integer): Boolean;
  public
    constructor Create(const AData: TBytes);

    function ReadByte: Byte;
    function ReadUInt16: Word;
    function ReadUInt32: Cardinal;
    /// <summary>Four characters as an integer, first character on top</summary>
    function ReadMarker: Cardinal;
    procedure Skip(ACount: Int64);

    /// <summary>The integer of a marker such as 'RIFF'</summary>
    class function MarkerOf(const AText: AnsiString): Cardinal; static;
    /// <summary>True for the characters libsndfile accepts in a chunk name: 32 to 126</summary>
    class function IsPrintable(AValue: Cardinal): Boolean; static;

    property BigEndian: Boolean read FBigEndian write FBigEndian;
    property Overrun: Boolean read FOverrun;
    property Position: Int64 read FPosition write FPosition;
    property Data: TBytes read FData;
  end;

implementation

{ TSoundByteReader }

constructor TSoundByteReader.Create(const AData: TBytes);
begin
  FData := AData;
  FPosition := 0;
  FBigEndian := False;
  FOverrun := False;
end;

function TSoundByteReader.Take(ACount: Integer): Boolean;
begin
  Result := (FPosition >= 0) and (FPosition + ACount <= Length(FData));
  if not Result then
  begin
    FOverrun := True;
    Inc(FPosition, ACount);
  end;
end;

function TSoundByteReader.ReadByte: Byte;
begin
  if not Take(1) then
    Exit(0);
  Result := FData[Integer(FPosition)];
  Inc(FPosition);
end;

function TSoundByteReader.ReadUInt16: Word;
var
  LIndex: Integer;
begin
  if not Take(2) then
    Exit(0);
  LIndex := Integer(FPosition);
  if FBigEndian then
    Result := (Word(FData[LIndex]) shl 8) or FData[LIndex + 1]
  else
    Result := (Word(FData[LIndex + 1]) shl 8) or FData[LIndex];
  Inc(FPosition, 2);
end;

function TSoundByteReader.ReadUInt32: Cardinal;
var
  LIndex: Integer;
begin
  if not Take(4) then
    Exit(0);
  LIndex := Integer(FPosition);
  if FBigEndian then
    Result := (Cardinal(FData[LIndex]) shl 24) or (Cardinal(FData[LIndex + 1]) shl 16) or
      (Cardinal(FData[LIndex + 2]) shl 8) or FData[LIndex + 3]
  else
    Result := (Cardinal(FData[LIndex + 3]) shl 24) or (Cardinal(FData[LIndex + 2]) shl 16) or
      (Cardinal(FData[LIndex + 1]) shl 8) or FData[LIndex];
  Inc(FPosition, 4);
end;

function TSoundByteReader.ReadMarker: Cardinal;
var
  LIndex: Integer;
begin
  if not Take(4) then
    Exit(0);
  LIndex := Integer(FPosition);
  Result := (Cardinal(FData[LIndex]) shl 24) or (Cardinal(FData[LIndex + 1]) shl 16) or
    (Cardinal(FData[LIndex + 2]) shl 8) or FData[LIndex + 3];
  Inc(FPosition, 4);
end;

procedure TSoundByteReader.Skip(ACount: Int64);
begin
  Inc(FPosition, ACount);
end;

class function TSoundByteReader.MarkerOf(const AText: AnsiString): Cardinal;
begin
  Result := (Cardinal(Byte(AText[1])) shl 24) or (Cardinal(Byte(AText[2])) shl 16) or
    (Cardinal(Byte(AText[3])) shl 8) or Byte(AText[4]);
end;

class function TSoundByteReader.IsPrintable(AValue: Cardinal): Boolean;
begin
  Result := (AValue >= 32) and (AValue <= 126);
end;

end.
