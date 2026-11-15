{******************************************************************************}
{                                                                              }
{  DelphiDoom: Tracker library - reader of the numbers and text of a module    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.ByteReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Bytes.Reader;

type
  /// <summary>
  ///   Reads numbers and text from a block of bytes. A read past the end
  ///   raises ETrackerException: a truncated module is an error, not a crash.
  ///   The cursor is the common TByteReader of Libs\Bytes (little endian ReadWord and ReadCardinal,
  ///   big endian ReadWordBE); this class adds the text and the truncating block, and gives it the
  ///   exception of this library
  /// </summary>
  TTrackerByteReader = class(TByteReader)
  protected
    procedure RaiseOverrun(ACount: Integer); override;
  public
    /// <summary>Moves the cursor; a position outside the data is an error</summary>
    procedure Seek(APosition: Integer); override;
    /// <summary>Text of ACount bytes, up to the first zero, with no trailing spaces</summary>
    function ReadText(const ACount: Integer): string;
    /// <summary>Raw bytes; fewer if the data ends and ATruncate is true</summary>
    function ReadBytes(const ACount: Integer; const ATruncate: Boolean = False): TBytes;
  end;

implementation

uses
  DelphiDoom.Tracker.Types;

const
  STruncated = 'The module is truncated';

{ TTrackerByteReader }

procedure TTrackerByteReader.RaiseOverrun(ACount: Integer);
begin
  raise ETrackerException.Create(STruncated);
end;

procedure TTrackerByteReader.Seek(APosition: Integer);
begin
  if (APosition < 0) or (APosition > Size) then
    raise ETrackerException.Create(STruncated);
  inherited Seek(APosition);
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
    LChar := Data[Position + LIndex];
    if LChar = 0 then
      Break;
    Result := Result + Char(LChar);
  end;
  Skip(ACount);
  Result := TrimRight(Result);
end;

function TTrackerByteReader.ReadBytes(const ACount: Integer; const ATruncate: Boolean): TBytes;
var
  LCount: Integer;
begin
  LCount := ACount;
  if ATruncate and (Position + LCount > Size) then
    LCount := Size - Position;
  Result := ReadBlock(LCount);
end;

end.
