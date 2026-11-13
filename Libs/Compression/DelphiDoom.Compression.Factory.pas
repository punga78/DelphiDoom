{******************************************************************************}
{                                                                              }
{  DelphiDoom: compression library - TCompressorFactory (idCompressor::Alloc*) }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): framework\Compressor.cpp }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Compression.Factory;

interface

uses
  DelphiDoom.Compression.Intf;

type
  /// <summary>
  ///   The composition point of the library: the only unit that knows the concrete compressors. Every
  ///   function is the <c>idCompressor::Alloc...</c> of the same name; the result is reference counted and
  ///   still needs <c>Init</c> with a stream.
  /// </summary>
  TCompressorFactory = class
  public
    class function CreateNoCompression: ICompressor; static;
    class function CreateBitStream: ICompressor; static;
    class function CreateRunLength: ICompressor; static;
    class function CreateRunLengthZeroBased: ICompressor; static;
    class function CreateHuffman: ICompressor; static;
    class function CreateArithmetic: ICompressor; static;
    class function CreateLzss: ICompressor; static;
    class function CreateLzssWordAligned: ICompressor; static;
    class function CreateLzw: ICompressor; static;
  end;

implementation

uses
  DelphiDoom.Compression.None, DelphiDoom.Compression.BitStream, DelphiDoom.Compression.RunLength,
  DelphiDoom.Compression.RunLengthZeroBased, DelphiDoom.Compression.Huffman,
  DelphiDoom.Compression.Arithmetic, DelphiDoom.Compression.Lzss,
  DelphiDoom.Compression.LzssWordAligned, DelphiDoom.Compression.Lzw;

{ TCompressorFactory }

class function TCompressorFactory.CreateNoCompression: ICompressor;
begin
  Result := TCompressorNone.Create;
end;

class function TCompressorFactory.CreateBitStream: ICompressor;
begin
  Result := TCompressorBitStream.Create;
end;

class function TCompressorFactory.CreateRunLength: ICompressor;
begin
  Result := TCompressorRunLength.Create;
end;

class function TCompressorFactory.CreateRunLengthZeroBased: ICompressor;
begin
  Result := TCompressorRunLengthZeroBased.Create;
end;

class function TCompressorFactory.CreateHuffman: ICompressor;
begin
  Result := TCompressorHuffman.Create;
end;

class function TCompressorFactory.CreateArithmetic: ICompressor;
begin
  Result := TCompressorArithmetic.Create;
end;

class function TCompressorFactory.CreateLzss: ICompressor;
begin
  Result := TCompressorLzss.Create;
end;

class function TCompressorFactory.CreateLzssWordAligned: ICompressor;
begin
  Result := TCompressorLzssWordAligned.Create;
end;

class function TCompressorFactory.CreateLzw: ICompressor;
begin
  Result := TCompressorLzw.Create;
end;

end.
