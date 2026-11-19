{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the GL calls of  }
{  the backend as text                                                         }
{                                                                              }
{  The backend (tr_backend.c, tr_shade.c) makes its qgl* calls through this    }
{  small sink. The sink of the library writes each call as a line to the      }
{  frame of an IGlCallRecorder (Framework\OpenGlBinding\Recorder): the name    }
{  and the arguments, integers in decimal, enums as $XXXX, floats as # and     }
{  their 32 bits, arrays as h:HASH/SIZE (FNV-1a of the bytes the C would read   }
{  through the pointer). No OpenGL context is ever made.                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.Gl;

interface

uses
  System.SysUtils, DelphiDoom.OpenGl.Recorder.Intf;

const
  GL_DEPTH_BUFFER_BIT = $00000100;
  GL_STENCIL_BUFFER_BIT = $00000400;
  GL_COLOR_BUFFER_BIT = $00004000;
  GL_TRIANGLES = $0004;
  GL_UNSIGNED_BYTE = $1401;
  GL_UNSIGNED_INT = $1405;
  GL_FLOAT = $1406;
  GL_FRONT = $0404;
  GL_BACK = $0405;
  GL_FRONT_AND_BACK = $0408;
  GL_CULL_FACE = $0B44;
  GL_DEPTH_TEST = $0B71;
  GL_BLEND = $0BE2;
  GL_ALPHA_TEST = $0BC0;
  GL_TEXTURE_2D = $0DE1;
  GL_CLIP_PLANE0 = $3000;
  GL_POLYGON_OFFSET_FILL = $8037;
  GL_MODELVIEW = $1700;
  GL_PROJECTION = $1701;
  GL_FILL = $1B02;
  GL_LINE = $1B01;
  GL_LEQUAL = $0203;
  GL_EQUAL = $0202;
  GL_GREATER = $0204;
  GL_LESS = $0201;
  GL_GEQUAL = $0206;
  GL_ZERO = 0;
  GL_ONE = 1;
  GL_SRC_COLOR = $0300;
  GL_ONE_MINUS_SRC_COLOR = $0301;
  GL_SRC_ALPHA = $0302;
  GL_ONE_MINUS_SRC_ALPHA = $0303;
  GL_DST_ALPHA = $0304;
  GL_ONE_MINUS_DST_ALPHA = $0305;
  GL_DST_COLOR = $0306;
  GL_ONE_MINUS_DST_COLOR = $0307;
  GL_SRC_ALPHA_SATURATE = $0308;
  GL_TEXTURE_ENV = $2300;
  GL_TEXTURE_ENV_MODE = $2200;
  GL_MODULATE = $2100;
  GL_REPLACE = $1E01;
  GL_DECAL = $2101;
  GL_ADD = $0104;
  GL_VERTEX_ARRAY = $8074;
  GL_COLOR_ARRAY = $8076;
  GL_TEXTURE_COORD_ARRAY = $8078;
  GL_TEXTURE0_ARB = $84C0;
  GL_TEXTURE1_ARB = $84C1;

type
  TQ3GlArgKind = (gaInteger, gaEnum, gaFloat, gaDouble, gaBlock);

  /// <summary>An argument of a GL call: a number, an enum, a float, a double or the bytes behind a pointer</summary>
  TQ3GlArg = record
    Kind: TQ3GlArgKind;
    IntValue: Int64;
    FloatValue: Double;
    Block: TBytes;
    class function FromInt(AValue: Int64): TQ3GlArg; static;
    class function FromEnum(AValue: Cardinal): TQ3GlArg; static;
    class function FromSingle(AValue: Single): TQ3GlArg; static;
    class function FromDouble(AValue: Double): TQ3GlArg; static;
    /// <summary>A pointer: the bytes it points to (as many as the C reads), kept as a hash in the line</summary>
    class function FromBytes(const AValue: TBytes): TQ3GlArg; static;
  end;

  /// <summary>Where the backend sends its qgl* calls</summary>
  IQ3GlSink = interface
    ['{4C92D07E-B15A-4E38-A6F4-8D03E5C1B972}']
    procedure Call(const AName: string; const AArguments: array of TQ3GlArg);
  end;

  /// <summary>
  ///   Writes the calls to the open frame of a recorder (calls made out of a frame are dropped by the recorder, as the
  ///   ones of the setup of the context are)
  /// </summary>
  TQ3GlRecordingSink = class(TInterfacedObject, IQ3GlSink)
  strict private
    FRecorder: IGlCallRecorder;
    class function Format(const AArgument: TQ3GlArg): string; static;
  public
    constructor Create(const ARecorder: IGlCallRecorder);
    procedure Call(const AName: string; const AArguments: array of TQ3GlArg);
  end;

implementation

uses
  DelphiDoom.OpenGl.Recorder.Fnv;

class function TQ3GlArg.FromInt(AValue: Int64): TQ3GlArg;
begin
  Result := Default(TQ3GlArg);
  Result.Kind := gaInteger;
  Result.IntValue := AValue;
end;

class function TQ3GlArg.FromEnum(AValue: Cardinal): TQ3GlArg;
begin
  Result := Default(TQ3GlArg);
  Result.Kind := gaEnum;
  Result.IntValue := AValue;
end;

class function TQ3GlArg.FromSingle(AValue: Single): TQ3GlArg;
begin
  Result := Default(TQ3GlArg);
  Result.Kind := gaFloat;
  Result.FloatValue := AValue;
end;

class function TQ3GlArg.FromDouble(AValue: Double): TQ3GlArg;
begin
  Result := Default(TQ3GlArg);
  Result.Kind := gaDouble;
  Result.FloatValue := AValue;
end;

class function TQ3GlArg.FromBytes(const AValue: TBytes): TQ3GlArg;
begin
  Result := Default(TQ3GlArg);
  Result.Kind := gaBlock;
  Result.Block := AValue;
end;

constructor TQ3GlRecordingSink.Create(const ARecorder: IGlCallRecorder);
begin
  inherited Create;
  if not Assigned(ARecorder) then
    raise EArgumentNilException.Create('ARecorder');
  FRecorder := ARecorder;
end;

class function TQ3GlRecordingSink.Format(const AArgument: TQ3GlArg): string;
var
  LSingle: Single;
  LDouble: Double;
  LHash: UInt64;
begin
  case AArgument.Kind of
    gaInteger:
      Result := IntToStr(AArgument.IntValue);
    gaEnum:
      Result := '$' + IntToHex(AArgument.IntValue, 4);
    gaFloat:
      begin
        LSingle := AArgument.FloatValue;
        Result := '#' + IntToHex(PCardinal(@LSingle)^, 8);
      end;
    gaDouble:
      begin
        LDouble := AArgument.FloatValue;
        Result := '#' + IntToHex(PInt64(@LDouble)^, 16);
      end;
  else
    LHash := TGlFnv.Start;
    if Length(AArgument.Block) > 0 then
      LHash := TGlFnv.UpdateBuffer(LHash, @AArgument.Block[0], Length(AArgument.Block));
    Result := 'h:' + TGlFnv.ToHex(LHash) + '/' + IntToStr(Length(AArgument.Block));
  end;
end;

procedure TQ3GlRecordingSink.Call(const AName: string; const AArguments: array of TQ3GlArg);
var
  LLine: string;
  LIndex: Integer;
begin
  LLine := AName + '(';
  for LIndex := 0 to High(AArguments) do
  begin
    if LIndex > 0 then
      LLine := LLine + ',';
    LLine := LLine + Format(AArguments[LIndex]);
  end;
  FRecorder.Call(LLine + ')');
end;

end.
