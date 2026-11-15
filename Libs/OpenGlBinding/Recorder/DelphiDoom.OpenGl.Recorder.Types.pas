{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - shared types and constants               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>glPixelStorei: GL_UNPACK_ROW_LENGTH</summary>
  GLR_UNPACK_ROW_LENGTH = $0CF2;
  /// <summary>glPixelStorei: GL_UNPACK_SKIP_ROWS</summary>
  GLR_UNPACK_SKIP_ROWS = $0CF3;
  /// <summary>glPixelStorei: GL_UNPACK_SKIP_PIXELS</summary>
  GLR_UNPACK_SKIP_PIXELS = $0CF4;
  /// <summary>glPixelStorei: GL_UNPACK_ALIGNMENT</summary>
  GLR_UNPACK_ALIGNMENT = $0CF5;
  /// <summary>glPixelStorei: GL_UNPACK_SKIP_IMAGES</summary>
  GLR_UNPACK_SKIP_IMAGES = $806D;
  /// <summary>glPixelStorei: GL_UNPACK_IMAGE_HEIGHT</summary>
  GLR_UNPACK_IMAGE_HEIGHT = $806E;
  /// <summary>The default value of GL_UNPACK_ALIGNMENT</summary>
  GLR_DEFAULT_UNPACK_ALIGNMENT = 4;

  /// <summary>glFogfv: GL_FOG_COLOR (four floats; the other parameters have one)</summary>
  GLR_FOG_COLOR = $0B66;
  /// <summary>glTexGenfv: GL_TEXTURE_GEN_MODE (one float; the planes have four)</summary>
  GLR_TEXTURE_GEN_MODE = $2500;

  /// <summary>glEnableClientState: GL_VERTEX_ARRAY</summary>
  GLR_VERTEX_ARRAY = $8074;
  /// <summary>glEnableClientState: GL_TEXTURE_COORD_ARRAY</summary>
  GLR_TEXTURE_COORD_ARRAY = $8078;

type
  /// <summary>Base class of the errors of the recorder</summary>
  EGlRecorderException = class(Exception);

  /// <summary>How an argument of a GL call is written in the stream</summary>
  TGlValueKind = (
    /// <summary>Integer, written in decimal</summary>
    vkInteger,
    /// <summary>GLenum, written in hexadecimal</summary>
    vkEnum,
    /// <summary>Single, written with its 32 bits</summary>
    vkSingle,
    /// <summary>Double, written with its 64 bits</summary>
    vkDouble,
    /// <summary>Pointer: the address is never written (it changes from a run to the next)</summary>
    vkPointer);

  /// <summary>One argument of a GL call, as the thunk of the function got it</summary>
  TGlValue = record
    Kind: TGlValueKind;
    /// <summary>The integer, the enum, or the bits of the Single (low 32) or of the Double</summary>
    Bits: Int64;
    PointerValue: Pointer;
    class function FromInteger(const AValue: Int64): TGlValue; static;
    class function FromEnum(const AValue: Cardinal): TGlValue; static;
    class function FromSingle(const AValue: Single): TGlValue; static;
    class function FromDouble(const AValue: Double): TGlValue; static;
    class function FromPointer(const AValue: Pointer): TGlValue; static;
    /// <summary>The value as an integer (a Single or Double is not converted: 0)</summary>
    function AsInteger: Int64;
    /// <summary>The value as a count that fits in a 32 bit integer (negative values are 0)</summary>
    function AsCount: Integer;
  end;

implementation

{ TGlValue }

class function TGlValue.FromInteger(const AValue: Int64): TGlValue;
begin
  Result.Kind := vkInteger;
  Result.Bits := AValue;
  Result.PointerValue := nil;
end;

class function TGlValue.FromEnum(const AValue: Cardinal): TGlValue;
begin
  Result.Kind := vkEnum;
  Result.Bits := AValue;
  Result.PointerValue := nil;
end;

class function TGlValue.FromSingle(const AValue: Single): TGlValue;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result.Kind := vkSingle;
  Result.Bits := LBits;
  Result.PointerValue := nil;
end;

class function TGlValue.FromDouble(const AValue: Double): TGlValue;
begin
  Result.Kind := vkDouble;
  Move(AValue, Result.Bits, SizeOf(Result.Bits));
  Result.PointerValue := nil;
end;

class function TGlValue.FromPointer(const AValue: Pointer): TGlValue;
begin
  Result.Kind := vkPointer;
  Result.Bits := 0;
  Result.PointerValue := AValue;
end;

function TGlValue.AsInteger: Int64;
begin
  if Kind in [vkInteger, vkEnum] then
    Result := Bits
  else
    Result := 0;
end;

function TGlValue.AsCount: Integer;
var
  LValue: Int64;
begin
  LValue := AsInteger;
  if (LValue < 0) or (LValue > High(Integer)) then
    Result := 0
  else
    Result := Integer(LValue);
end;

end.
