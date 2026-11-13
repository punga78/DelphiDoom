{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the shader being read                       }
{                                                                              }
{  The static variables of renderer\tr_shader.c (shader, stages, texMods) and  }
{  ri.Printf as an object, so that two readings share nothing. Quake III Arena }
{  (id Software, GPL v2 or later). Based on the Quake III Arena GPL Source     }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Context;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Q3Shader.Types;

type
  PQ3ShaderData = ^TQ3ShaderData;
  PQ3ShaderStage = ^TQ3ShaderStage;

  /// <summary>
  ///   The working shader of one reading: the data the parse functions fill, the name they quote in their
  ///   warnings, and where the warnings go. A new object is the <c>Com_Memset(&amp;shader, 0)</c> of
  ///   <c>R_FindShader</c>.
  /// </summary>
  TQ3ShaderContext = class
  strict private
    FData: TQ3ShaderData;
    FLog: IIdLibLog;
    FOptions: TQ3ShaderOptions;
  public
    constructor Create(const AName: AnsiString; const ALog: IIdLibLog; const AOptions: TQ3ShaderOptions);
    /// <summary>The data; the parse functions write to it</summary>
    function Data: PQ3ShaderData;
    property Options: TQ3ShaderOptions read FOptions;
    /// <summary>
    ///   ri.Printf(PRINT_WARNING, "WARNING: ..."): the message as in the original, without the "WARNING: "
    ///   that the log adds
    /// </summary>
    procedure Warn(const AFormat: string; const AArgs: array of const);
    /// <summary>
    ///   The conversion of a float to a byte of the original (<c>constantColor[i] = 255 * f</c>): truncation to an
    ///   int, then the low byte; a value out of the range of an int gives the x86 "integer indefinite"
    /// </summary>
    class function FloatToByte(const AValue: Double): Byte; static;
  end;

implementation

constructor TQ3ShaderContext.Create(const AName: AnsiString; const ALog: IIdLibLog; const AOptions: TQ3ShaderOptions);
begin
  inherited Create;
  FLog := ALog;
  FOptions := AOptions;
  // the fields of a new object are zero: the Com_Memset of R_FindShader
  FData.Name := AName;
end;

function TQ3ShaderContext.Data: PQ3ShaderData;
begin
  Result := @FData;
end;

procedure TQ3ShaderContext.Warn(const AFormat: string; const AArgs: array of const);
begin
  if Assigned(FLog) then
    FLog.Warning(Format(AFormat, AArgs));
end;

class function TQ3ShaderContext.FloatToByte(const AValue: Double): Byte;
var
  LInteger: Integer;
begin
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    LInteger := Integer($80000000)
  else
    LInteger := Trunc(AValue);
  Result := Byte(LInteger and $FF);
end;

end.
