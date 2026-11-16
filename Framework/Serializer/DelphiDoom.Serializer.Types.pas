{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - kinds of field, field, exception           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.Types;

interface

uses
  System.SysUtils;

{$SCOPEDENUMS ON}

type
  /// <summary>
  ///   What a field of a record holds. The order is the one of the old serializetype_t of the
  ///   engine; the sizes on disk are in SERIALIZER_FIELD_SIZES and do not depend on 32 or 64 bit
  /// </summary>
  TSerializerFieldKind = (
    /// <summary>A block of bytes, written when it is not all zeroes</summary>
    Generic,
    UnsignedByte,
    SignedByte,
    UnsignedWord,
    SignedWord,
    UnsignedLong,
    SignedLong,
    SignedQuad,
    /// <summary>A 32 bit float</summary>
    Float,
    /// <summary>A pointer to a state, written as the index of the state</summary>
    State,
    /// <summary>A pointer to a mobj, written as its key</summary>
    Mobj,
    /// <summary>A pointer to a player, written as the number of the player (index + 1)</summary>
    Player,
    /// <summary>A short string: a length byte and up to 255 characters of 8 bit</summary>
    Text,
    /// <summary>
    ///   A whole number as wide as a pointer in the record (NativeInt, or a pointer kept as a mark):
    ///   4 bytes in the stream, with the sign, whatever the width in memory (issue #40)
    /// </summary>
    NativeInteger
  );

const
  /// <summary>Bytes of each kind in the stream (Generic: given by the field; Text: the text capacity)</summary>
  SERIALIZER_FIELD_SIZES: array[TSerializerFieldKind] of Integer = (
    0, 1, 1, 2, 2, 4, 4, 8, 4, 4, 4, 4, 255, 4
  );

  /// <summary>Longest text of a Text field</summary>
  SERIALIZER_TEXT_CAPACITY = 255;

  /// <summary>The id that ends a record in the stream; the ids of the fields start from 1</summary>
  SERIALIZER_END_MARKER = 0;

type
  /// <summary>Called on a record after one of its fields has been read from the stream</summary>
  TSerializerLoadedProc = reference to procedure(const AStruct: Pointer);

  /// <summary>
  ///   One field of the table of a record: where it is (from the start of the record), what it
  ///   is, what it is when it is not in the stream
  /// </summary>
  TSerializerField = record
    /// <summary>The number in the stream, from 1: the position of the field in the table</summary>
    Id: Word;
    /// <summary>Distance of the field from the start of the record</summary>
    Offset: NativeInt;
    Kind: TSerializerFieldKind;
    /// <summary>Bytes of the field in the stream (the length of a Generic one)</summary>
    Size: Integer;
    IntegerDefault: Int64;
    FloatDefault: Single;
    TextDefault: AnsiString;
    OnLoaded: TSerializerLoadedProc;
  end;

  /// <summary>A stream that cannot be read or written as the table says</summary>
  ESerializerException = class(Exception);

  /// <summary>
  ///   A value as wide as a pointer in memory (a pointer, a NativeInt) and 4 bytes on disk, as in the saved
  ///   games of the 32 bit program: an index, a key, -1, or an address that the reader only tests against nil
  /// </summary>
  TSerializerNativeValue = record
  public
    /// <summary>The 32 bits on disk; a value that is not 0 never becomes 0 (it stays "not nil")</summary>
    class function ToDisk(AValue: NativeInt): Integer; static;
    /// <summary>The value in memory, with the sign (-1 stays -1)</summary>
    class function FromDisk(AValue: Integer): NativeInt; static; inline;
  end;

  /// <summary>
  ///   A run of a record that goes from memory to disk in one step: bytes copied as they are, or one
  ///   value as wide as a pointer in memory and 4 bytes on disk
  /// </summary>
  TDiskLayoutSegment = record
    NativeOffset: Integer;
    DiskOffset: Integer;
    /// <summary>Bytes of a run of plain bytes (not used by a reference)</summary>
    Size: Integer;
    Reference: Boolean;
  end;

resourcestring
  SDiskLayoutNoTypeInfo = 'The record of a saved game has no type information';
  SDiskLayoutUnsupportedType = 'The field %s of %s has a type that cannot be saved raw (%s)';
  SDiskLayoutDescribeField =
    'The field %s of %s has an unnamed type and its size on disk is not certain: describe it (DescribeArray)';
  SDiskLayoutVariant = 'The field %s of %s overlaps another field in a way that is not supported';
  SDiskLayoutNotUnderstood = 'The layout in memory of %s is not the one worked out from its fields';
  SDiskLayoutNotIdentity = 'With a 32 bit program the layout on disk of %s must be the one in memory';
  SDiskLayoutWrongCount = 'The description of the field %s of %s is wrong: %d elements of %d bytes in %d bytes';
  SSerializerUnknownFieldId = 'The stream has a field number (%d) that the table does not have (%d fields)';
  SSerializerBufferOverrun = 'The memory of the serializer is too small: %d bytes';

implementation

{ TSerializerNativeValue }

class function TSerializerNativeValue.ToDisk(AValue: NativeInt): Integer;
begin
  Result := Integer(AValue and $FFFFFFFF);
  // a 64 bit address whose low half is 0 would be read back as nil
  if (Result = 0) and (AValue <> 0) then
    Result := 1;
end;

class function TSerializerNativeValue.FromDisk(AValue: Integer): NativeInt;
begin
  Result := AValue;
end;

end.
