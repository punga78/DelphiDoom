{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the size of the image of an executable       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.PeImageReader;

interface

uses
  System.Classes;

type
  /// <summary>Reads SizeOfImage from the headers of a Portable Executable</summary>
  TPeImageReader = class
  public
    /// <summary>
    ///   SizeOfImage of the optional header of a PE32 or PE32+ file; 0 if the stream is not
    ///   one. The position of the stream is not kept
    /// </summary>
    class function ReadImageSize(AStream: TStream): Cardinal; static;
  end;

implementation

const
  DOS_SIGNATURE = $5A4D;           // 'MZ'
  PE_SIGNATURE = $00004550;        // 'PE'#0#0
  PE32_MAGIC = $010B;
  PE32_PLUS_MAGIC = $020B;
  PE32_OPTIONAL_HEADER_SIZE = 224;
  PE32_PLUS_OPTIONAL_HEADER_SIZE = 240;
  PE_NEW_HEADER_OFFSET_POSITION = $3C;
  // the same place in both optional headers
  SIZE_OF_IMAGE_OFFSET = 56;
  FILE_HEADER_SIZE = 20;
  SIZE_OF_OPTIONAL_HEADER_OFFSET = 16;

function ReadExactly(AStream: TStream; var ABuffer; ACount: Integer): Boolean;
begin
  Result := AStream.Read(ABuffer, ACount) = ACount;
end;

{ TPeImageReader }

class function TPeImageReader.ReadImageSize(AStream: TStream): Cardinal;
var
  LDosSignature: Word;
  LHeaderOffset: Cardinal;
  LSignature: Cardinal;
  LFileHeader: array[0..FILE_HEADER_SIZE - 1] of Byte;
  LOptionalSize: Word;
  LOptional: array[0..SIZE_OF_IMAGE_OFFSET + 3] of Byte;
  LMagic: Word;
begin
  Result := 0;
  AStream.Position := 0;
  if not ReadExactly(AStream, LDosSignature, SizeOf(LDosSignature)) then
    Exit;
  if LDosSignature <> DOS_SIGNATURE then
    Exit;
  AStream.Position := PE_NEW_HEADER_OFFSET_POSITION;
  if not ReadExactly(AStream, LHeaderOffset, SizeOf(LHeaderOffset)) then
    Exit;
  if LHeaderOffset = 0 then
    Exit;
  AStream.Position := LHeaderOffset;
  if not ReadExactly(AStream, LSignature, SizeOf(LSignature)) then
    Exit;
  if LSignature <> PE_SIGNATURE then
    Exit;
  if not ReadExactly(AStream, LFileHeader, SizeOf(LFileHeader)) then
    Exit;
  LOptionalSize := PWord(@LFileHeader[SIZE_OF_OPTIONAL_HEADER_OFFSET])^;
  if not ReadExactly(AStream, LOptional, SizeOf(LOptional)) then
    Exit;
  LMagic := PWord(@LOptional[0])^;
  if ((LMagic = PE32_MAGIC) and (LOptionalSize = PE32_OPTIONAL_HEADER_SIZE)) or
    ((LMagic = PE32_PLUS_MAGIC) and (LOptionalSize = PE32_PLUS_OPTIONAL_HEADER_SIZE)) then
    Result := PCardinal(@LOptional[SIZE_OF_IMAGE_OFFSET])^;
end;

end.
