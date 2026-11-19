{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the GL state     }
{                                                                              }
{  glState_t with GL_Bind, GL_SelectTexture, GL_TexEnv, GL_Cull and GL_State of }
{  renderer\tr_backend.c: only what changes is sent, so the stream has to       }
{  follow the state the way the C does. Based on the Quake III Arena GPL      }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Backend.State;

interface

uses
  System.SysUtils, DelphiDoom.Q3Render.Backend.Gl;

type
  /// <summary>
  ///   The state the backend believes the context is in, after GL_SetDefaultState: unit 0 selected, no texture bound,
  ///   GL_MODULATE on both units, the state bits GLS_DEPTHTEST_DISABLE or GLS_DEPTHMASK_TRUE and face culling unknown
  /// </summary>
  TQ3GlState = class
  strict private
    FSink: IQ3GlSink;
    FCurrentTextures: array[0..1] of Integer;
    FCurrentTmu: Integer;
    FTexEnv: array[0..1] of Integer;
    FFaceCulling: Integer;
    FStateBits: Cardinal;
  public
    constructor Create(const ASink: IQ3GlSink);
    /// <summary>A call that does not go through the state (the C calls qgl directly)</summary>
    procedure Call(const AName: string; const AArguments: array of TQ3GlArg);
    /// <summary>GL_Bind of the texture number (the image resolved by the caller)</summary>
    procedure Bind(ATextureNumber: Integer);
    /// <summary>GL_SelectTexture: the unit 0 or 1</summary>
    procedure SelectTexture(AUnit: Integer);
    /// <summary>GL_TexEnv: GL_MODULATE, GL_REPLACE, GL_DECAL or GL_ADD</summary>
    procedure TexEnv(AEnvironment: Integer);
    /// <summary>GL_Cull: 0 front sided, 1 back sided, 2 two sided (cullType_t); the view may be a mirror</summary>
    procedure Cull(ACullType: Integer; AIsMirror: Boolean);
    /// <summary>GL_State</summary>
    procedure State(AStateBits: Cardinal);
    /// <summary>glState.faceCulling = -1: the next GL_Cull sets it again</summary>
    procedure ForgetFaceCulling;
    property CurrentTmu: Integer read FCurrentTmu;
    property StateBits: Cardinal read FStateBits;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Q3Render.Scene.Types;

const
  GLS_ATEST_BITS = $70000000;

constructor TQ3GlState.Create(const ASink: IQ3GlSink);
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FSink := ASink;
  FTexEnv[0] := GL_MODULATE;
  FTexEnv[1] := GL_MODULATE;
  FFaceCulling := -1;
  FStateBits := GLS_DEPTHTEST_DISABLE or GLS_DEPTHMASK_TRUE;
end;

procedure TQ3GlState.Call(const AName: string; const AArguments: array of TQ3GlArg);
begin
  FSink.Call(AName, AArguments);
end;

procedure TQ3GlState.Bind(ATextureNumber: Integer);
begin
  if FCurrentTextures[FCurrentTmu] <> ATextureNumber then
  begin
    FCurrentTextures[FCurrentTmu] := ATextureNumber;
    FSink.Call('glBindTexture', [TQ3GlArg.FromEnum(GL_TEXTURE_2D), TQ3GlArg.FromInt(ATextureNumber)]);
  end;
end;

procedure TQ3GlState.SelectTexture(AUnit: Integer);
var
  LUnit: Cardinal;
begin
  if FCurrentTmu = AUnit then
    Exit;
  if AUnit = 0 then
    LUnit := GL_TEXTURE0_ARB
  else
    LUnit := GL_TEXTURE1_ARB;
  FSink.Call('glActiveTextureARB', [TQ3GlArg.FromEnum(LUnit)]);
  FSink.Call('glClientActiveTextureARB', [TQ3GlArg.FromEnum(LUnit)]);
  FCurrentTmu := AUnit;
end;

procedure TQ3GlState.TexEnv(AEnvironment: Integer);
begin
  if AEnvironment = FTexEnv[FCurrentTmu] then
    Exit;
  FTexEnv[FCurrentTmu] := AEnvironment;
  FSink.Call('glTexEnvf', [TQ3GlArg.FromEnum(GL_TEXTURE_ENV), TQ3GlArg.FromEnum(GL_TEXTURE_ENV_MODE),
    TQ3GlArg.FromSingle(AEnvironment)]);
end;

procedure TQ3GlState.ForgetFaceCulling;
begin
  FFaceCulling := -1;
end;

procedure TQ3GlState.Cull(ACullType: Integer; AIsMirror: Boolean);
var
  LFace: Cardinal;
begin
  if FFaceCulling = ACullType then
    Exit;
  FFaceCulling := ACullType;
  if ACullType = Ord(ctTwoSided) then
    FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_CULL_FACE)])
  else
  begin
    FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_CULL_FACE)]);
    if ACullType = Ord(ctBackSided) then
    begin
      if AIsMirror then
        LFace := GL_FRONT
      else
        LFace := GL_BACK;
    end
    else
    begin
      if AIsMirror then
        LFace := GL_BACK
      else
        LFace := GL_FRONT;
    end;
    FSink.Call('glCullFace', [TQ3GlArg.FromEnum(LFace)]);
  end;
end;

procedure TQ3GlState.State(AStateBits: Cardinal);
var
  LDifference: Cardinal;
  LSource, LDestination: Cardinal;
begin
  LDifference := AStateBits xor FStateBits;
  if LDifference = 0 then
    Exit;
  // the depth function
  if (LDifference and GLS_DEPTHFUNC_EQUAL) <> 0 then
  begin
    if (AStateBits and GLS_DEPTHFUNC_EQUAL) <> 0 then
      FSink.Call('glDepthFunc', [TQ3GlArg.FromEnum(GL_EQUAL)])
    else
      FSink.Call('glDepthFunc', [TQ3GlArg.FromEnum(GL_LEQUAL)]);
  end;
  // the blend function
  if (LDifference and (GLS_SRCBLEND_BITS or GLS_DSTBLEND_BITS)) <> 0 then
  begin
    if (AStateBits and (GLS_SRCBLEND_BITS or GLS_DSTBLEND_BITS)) <> 0 then
    begin
      case AStateBits and GLS_SRCBLEND_BITS of
        GLS_SRCBLEND_ZERO:
          LSource := GL_ZERO;
        GLS_SRCBLEND_ONE:
          LSource := GL_ONE;
        GLS_SRCBLEND_DST_COLOR:
          LSource := GL_DST_COLOR;
        GLS_SRCBLEND_ONE_MINUS_DST_COLOR:
          LSource := GL_ONE_MINUS_DST_COLOR;
        GLS_SRCBLEND_SRC_ALPHA:
          LSource := GL_SRC_ALPHA;
        GLS_SRCBLEND_ONE_MINUS_SRC_ALPHA:
          LSource := GL_ONE_MINUS_SRC_ALPHA;
        GLS_SRCBLEND_DST_ALPHA:
          LSource := GL_DST_ALPHA;
        GLS_SRCBLEND_ONE_MINUS_DST_ALPHA:
          LSource := GL_ONE_MINUS_DST_ALPHA;
        GLS_SRCBLEND_ALPHA_SATURATE:
          LSource := GL_SRC_ALPHA_SATURATE;
      else
        raise EArgumentException.Create('GL_State: invalid src blend state bits');
      end;
      case AStateBits and GLS_DSTBLEND_BITS of
        GLS_DSTBLEND_ZERO:
          LDestination := GL_ZERO;
        GLS_DSTBLEND_ONE:
          LDestination := GL_ONE;
        GLS_DSTBLEND_SRC_COLOR:
          LDestination := GL_SRC_COLOR;
        GLS_DSTBLEND_ONE_MINUS_SRC_COLOR:
          LDestination := GL_ONE_MINUS_SRC_COLOR;
        GLS_DSTBLEND_SRC_ALPHA:
          LDestination := GL_SRC_ALPHA;
        GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA:
          LDestination := GL_ONE_MINUS_SRC_ALPHA;
        GLS_DSTBLEND_DST_ALPHA:
          LDestination := GL_DST_ALPHA;
        GLS_DSTBLEND_ONE_MINUS_DST_ALPHA:
          LDestination := GL_ONE_MINUS_DST_ALPHA;
      else
        raise EArgumentException.Create('GL_State: invalid dst blend state bits');
      end;
      FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_BLEND)]);
      FSink.Call('glBlendFunc', [TQ3GlArg.FromEnum(LSource), TQ3GlArg.FromEnum(LDestination)]);
    end
    else
      FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_BLEND)]);
  end;
  // the depth mask
  if (LDifference and GLS_DEPTHMASK_TRUE) <> 0 then
  begin
    if (AStateBits and GLS_DEPTHMASK_TRUE) <> 0 then
      FSink.Call('glDepthMask', [TQ3GlArg.FromInt(1)])
    else
      FSink.Call('glDepthMask', [TQ3GlArg.FromInt(0)]);
  end;
  // fill or line mode
  if (LDifference and GLS_POLYMODE_LINE) <> 0 then
  begin
    if (AStateBits and GLS_POLYMODE_LINE) <> 0 then
      FSink.Call('glPolygonMode', [TQ3GlArg.FromEnum(GL_FRONT_AND_BACK), TQ3GlArg.FromEnum(GL_LINE)])
    else
      FSink.Call('glPolygonMode', [TQ3GlArg.FromEnum(GL_FRONT_AND_BACK), TQ3GlArg.FromEnum(GL_FILL)]);
  end;
  // the depth test
  if (LDifference and GLS_DEPTHTEST_DISABLE) <> 0 then
  begin
    if (AStateBits and GLS_DEPTHTEST_DISABLE) <> 0 then
      FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_DEPTH_TEST)])
    else
      FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_DEPTH_TEST)]);
  end;
  // the alpha test
  if (LDifference and GLS_ATEST_BITS) <> 0 then
  begin
    case AStateBits and GLS_ATEST_BITS of
      0:
        FSink.Call('glDisable', [TQ3GlArg.FromEnum(GL_ALPHA_TEST)]);
      GLS_ATEST_GT_0:
        begin
          FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_ALPHA_TEST)]);
          FSink.Call('glAlphaFunc', [TQ3GlArg.FromEnum(GL_GREATER), TQ3GlArg.FromSingle(0.0)]);
        end;
      GLS_ATEST_LT_80:
        begin
          FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_ALPHA_TEST)]);
          FSink.Call('glAlphaFunc', [TQ3GlArg.FromEnum(GL_LESS), TQ3GlArg.FromSingle(0.5)]);
        end;
      GLS_ATEST_GE_80:
        begin
          FSink.Call('glEnable', [TQ3GlArg.FromEnum(GL_ALPHA_TEST)]);
          FSink.Call('glAlphaFunc', [TQ3GlArg.FromEnum(GL_GEQUAL), TQ3GlArg.FromSingle(0.5)]);
        end;
    end;
  end;
  FStateBits := AStateBits;
end;

end.
