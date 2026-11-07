{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - sequential reader of the bytes of a file      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.ByteReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads the bytes of an image file one piece after the other, as the decoders read
  ///   a stream. Past the end it gives zeros (the old streams left the buffer as it was,
  ///   with whatever the memory had) and remembers that it happened
  /// </summary>
  TTextureByteReader = class
  strict private
    FSource: TBytes;
    FPosition: Integer;
    FOverrun: Boolean;
    function GetSize: Integer;
  public
    constructor Create(const ASource: TBytes);
    /// <summary>Copies ACount bytes to ADest; the missing ones are zeros</summary>
    /// <returns>How many bytes were really there</returns>
    function Read(var ADest; ACount: Integer): Integer;
    function ReadByte: Byte;
    function ReadWord: Word;
    procedure Seek(APosition: Integer);
    /// <summary>The bytes from APosition, ACount of them (zeros past the end)</summary>
    function ReadBytes(ACount: Integer): TBytes;
    property Position: Integer read FPosition;
    property Size: Integer read GetSize;
    /// <summary>True as soon as a read asked for a byte that the source does not have</summary>
    property Overrun: Boolean read FOverrun;
  end;

implementation

{ TTextureByteReader }

constructor TTextureByteReader.Create(const ASource: TBytes);
begin
  inherited Create;
  FSource := ASource;
end;

function TTextureByteReader.GetSize: Integer;
begin
  Result := Length(FSource);
end;

function TTextureByteReader.Read(var ADest; ACount: Integer): Integer;
var
  LAvailable: Integer;
begin
  if ACount <= 0 then
    Exit(0);
  LAvailable := Length(FSource) - FPosition;
  if LAvailable < 0 then
    LAvailable := 0;
  if LAvailable > ACount then
    LAvailable := ACount;
  if LAvailable > 0 then
    Move(FSource[FPosition], ADest, LAvailable);
  if LAvailable < ACount then
  begin
    FillChar(Pointer(NativeUInt(@ADest) + NativeUInt(LAvailable))^, ACount - LAvailable, 0);
    FOverrun := True;
  end;
  Inc(FPosition, ACount);
  Result := LAvailable;
end;

function TTextureByteReader.ReadByte: Byte;
begin
  Read(Result, SizeOf(Result));
end;

function TTextureByteReader.ReadWord: Word;
begin
  Read(Result, SizeOf(Result));
end;

procedure TTextureByteReader.Seek(APosition: Integer);
begin
  if APosition < 0 then
    APosition := 0;
  FPosition := APosition;
end;

function TTextureByteReader.ReadBytes(ACount: Integer): TBytes;
begin
  if ACount < 0 then
    ACount := 0;
  SetLength(Result, ACount);
  if ACount > 0 then
    Read(Result[0], ACount);
end;

end.
