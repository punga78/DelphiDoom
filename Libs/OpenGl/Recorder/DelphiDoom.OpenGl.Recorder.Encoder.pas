{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the text of a call                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Encoder;

interface

uses
  System.Generics.Collections,
  DelphiDoom.OpenGl.Recorder.ClientArrays,
  DelphiDoom.OpenGl.Recorder.Types;

type
  /// <summary>
  ///   Writes a call as a line of text: name(argument,argument,...). Integers are decimal, a GLenum
  ///   is $XXXX, a Single is # and its 32 bits, a Double is # and its 64 bits. A pointer is never
  ///   written as an address (it changes from a run to the next): it is nil, ptr (not nil, and the
  ///   function does not say how many bytes) or h:HASH/SIZE (the FNV-1a of the bytes it points to
  ///   and their number), when the number is known from the other arguments.
  /// </summary>
  /// <remarks>
  ///   Covered (content hashed): the vectors of glColor4fv, glTexCoord2fv, glVertex3fv, glMultMatrixf/d,
  ///   glFogfv, glTexGenfv, glDeleteTextures, the pixels of glTexImage2D/3D, glTexSubImage2D/3D,
  ///   gluBuild2DMipmaps (rows without padding, with the unpack alignment that glPixelStorei set; only
  ///   for the plain formats and types of OpenGL 1.1), the palette of glColorTableEXT, and the elements
  ///   glDrawArrays draws from the arrays of glVertexPointer and glTexCoordPointer.
  ///   Not covered (only nil/ptr): output pointers (glGet*, glGenTextures, glReadPixels) and the
  ///   pixels of packed types, or when GL_UNPACK_ROW_LENGTH and the skip parameters are not 0.
  /// </remarks>
  TGlCallEncoder = class
  strict private
    type
      TGlRule = (
        grNone, grPixelStore, grTexImage2D, grTexSubImage2D, grTexImage3D, grTexSubImage3D, grBuild2DMipmaps,
        grColorTable, grDeleteTextures, grColor4fv, grTexCoord2fv, grVertex3fv, grMultMatrixf, grMultMatrixd,
        grFogfv, grTexGenfv, grVertexPointer, grTexCoordPointer, grEnableClientState, grDisableClientState,
        grDrawArrays);
  strict private
    FRules: TDictionary<string, TGlRule>;
    FArrays: TGlClientArrays;
    FAlignment: Integer;
    FUnpackIsPlain: Boolean;
    FUnpackOthers: array[0..4] of Integer;
    class function FormatValue(const AValue: TGlValue): string; static;
    class function FormatBlock(const AData: Pointer; const ASize: Int64): string; static;
    function FormatImage(const AValues: array of TGlValue; const AWidthIndex, AHeightIndex, ADepthIndex,
      AFormatIndex, ATypeIndex, ADataIndex: Integer): string;
    function FormatPalette(const AValues: array of TGlValue): string;
    procedure SetUnpack(const AName, AValue: Integer);
    procedure ApplyRule(const ARule: TGlRule; const AValues: array of TGlValue; var AArguments: TArray<string>);
    procedure SetArgument(var AArguments: TArray<string>; const AIndex: Integer; const AText: string);
    procedure AddArgument(var AArguments: TArray<string>; const AText: string);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The line of a call: the name and its arguments written as described above</summary>
    function Encode(const AName: string; const AValues: array of TGlValue): string;
    /// <summary>The names of the functions that have a special rule (for the tests)</summary>
    function RuleNames: TArray<string>;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Fnv,
  DelphiDoom.OpenGl.Recorder.PixelFormats;

{ TGlCallEncoder }

constructor TGlCallEncoder.Create;
begin
  inherited Create;
  FRules := TDictionary<string, TGlRule>.Create;
  FArrays := TGlClientArrays.Create;
  FAlignment := GLR_DEFAULT_UNPACK_ALIGNMENT;
  FUnpackIsPlain := True;
  FRules.Add('glPixelStorei', grPixelStore);
  FRules.Add('glTexImage2D', grTexImage2D);
  FRules.Add('glTexSubImage2D', grTexSubImage2D);
  FRules.Add('glTexImage3D', grTexImage3D);
  FRules.Add('glTexSubImage3D', grTexSubImage3D);
  FRules.Add('gluBuild2DMipmaps', grBuild2DMipmaps);
  FRules.Add('glColorTableEXT', grColorTable);
  FRules.Add('glDeleteTextures', grDeleteTextures);
  FRules.Add('glColor4fv', grColor4fv);
  FRules.Add('glTexCoord2fv', grTexCoord2fv);
  FRules.Add('glVertex3fv', grVertex3fv);
  FRules.Add('glMultMatrixf', grMultMatrixf);
  FRules.Add('glMultMatrixd', grMultMatrixd);
  FRules.Add('glFogfv', grFogfv);
  FRules.Add('glTexGenfv', grTexGenfv);
  FRules.Add('glVertexPointer', grVertexPointer);
  FRules.Add('glTexCoordPointer', grTexCoordPointer);
  FRules.Add('glEnableClientState', grEnableClientState);
  FRules.Add('glDisableClientState', grDisableClientState);
  FRules.Add('glDrawArrays', grDrawArrays);
end;

destructor TGlCallEncoder.Destroy;
begin
  FArrays.Free;
  FRules.Free;
  inherited Destroy;
end;

class function TGlCallEncoder.FormatValue(const AValue: TGlValue): string;
begin
  case AValue.Kind of
    vkInteger: Result := IntToStr(AValue.Bits);
    vkEnum: Result := '$' + IntToHex(AValue.Bits, 4);
    vkSingle: Result := '#' + IntToHex(AValue.Bits, 8);
    vkDouble: Result := '#' + IntToHex(AValue.Bits, 16);
    vkPointer:
      if AValue.PointerValue = nil then
        Result := 'nil'
      else
        Result := 'ptr';
  else
    Result := '?';
  end;
end;

class function TGlCallEncoder.FormatBlock(const AData: Pointer; const ASize: Int64): string;
begin
  if AData = nil then
    Exit('nil');
  if (ASize <= 0) or (ASize > 268435456) then
    Exit('ptr');
  Result := 'h:' + TGlFnv.ToHex(TGlFnv.UpdateBuffer(TGlFnv.Start, AData, ASize)) + '/' + IntToStr(ASize);
end;

function TGlCallEncoder.FormatImage(const AValues: array of TGlValue; const AWidthIndex, AHeightIndex,
  ADepthIndex, AFormatIndex, ATypeIndex, ADataIndex: Integer): string;
var
  LData: Pointer;
  LRowBytes: Int64;
  LStride: Int64;
  LHeight: Integer;
  LDepth: Integer;
  LRows: Int64;
  LRow: Int64;
  LHash: UInt64;
begin
  LData := AValues[ADataIndex].PointerValue;
  if LData = nil then
    Exit('nil');
  Result := 'ptr';
  if not FUnpackIsPlain then
    Exit;
  LHeight := 1;
  if AHeightIndex >= 0 then
    LHeight := AValues[AHeightIndex].AsCount;
  LDepth := 1;
  if ADepthIndex >= 0 then
    LDepth := AValues[ADepthIndex].AsCount;
  if not TGlPixelFormats.MeasureRow(AValues[AWidthIndex].AsCount, Cardinal(AValues[AFormatIndex].AsInteger),
    Cardinal(AValues[ATypeIndex].AsInteger), FAlignment, LRowBytes, LStride) then
    Exit;
  LRows := Int64(LHeight) * LDepth;
  if (LRows <= 0) or (LRows * LRowBytes > 268435456) then
    Exit;
  LHash := TGlFnv.Start;
  for LRow := 0 to LRows - 1 do
    LHash := TGlFnv.UpdateBuffer(LHash, PByte(LData) + LRow * LStride, LRowBytes);
  Result := 'h:' + TGlFnv.ToHex(LHash) + '/' + IntToStr(LRowBytes * LRows);
end;

function TGlCallEncoder.FormatPalette(const AValues: array of TGlValue): string;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  // glColorTableEXT(target, internalFormat, width, format, type, table): a table is one row, never padded
  if AValues[5].PointerValue = nil then
    Exit('nil');
  if TGlPixelFormats.MeasureRow(AValues[2].AsCount, Cardinal(AValues[3].AsInteger), Cardinal(AValues[4].AsInteger),
    1, LRowBytes, LStride) then
    Result := FormatBlock(AValues[5].PointerValue, LRowBytes)
  else
    Result := 'ptr';
end;

procedure TGlCallEncoder.SetUnpack(const AName, AValue: Integer);
var
  LIndex: Integer;
begin
  case Cardinal(AName) of
    GLR_UNPACK_ALIGNMENT: FAlignment := AValue;
    GLR_UNPACK_ROW_LENGTH: FUnpackOthers[0] := AValue;
    GLR_UNPACK_SKIP_ROWS: FUnpackOthers[1] := AValue;
    GLR_UNPACK_SKIP_PIXELS: FUnpackOthers[2] := AValue;
    GLR_UNPACK_SKIP_IMAGES: FUnpackOthers[3] := AValue;
    GLR_UNPACK_IMAGE_HEIGHT: FUnpackOthers[4] := AValue;
  else
    Exit;
  end;
  // with a row length, a skip or an image height the pixels are not a plain block: they are not hashed
  FUnpackIsPlain := True;
  for LIndex := Low(FUnpackOthers) to High(FUnpackOthers) do
    if FUnpackOthers[LIndex] <> 0 then
      FUnpackIsPlain := False;
end;

procedure TGlCallEncoder.SetArgument(var AArguments: TArray<string>; const AIndex: Integer; const AText: string);
begin
  if (AIndex >= 0) and (AIndex < Length(AArguments)) then
    AArguments[AIndex] := AText;
end;

procedure TGlCallEncoder.AddArgument(var AArguments: TArray<string>; const AText: string);
begin
  SetLength(AArguments, Length(AArguments) + 1);
  AArguments[High(AArguments)] := AText;
end;

procedure TGlCallEncoder.ApplyRule(const ARule: TGlRule; const AValues: array of TGlValue;
  var AArguments: TArray<string>);
var
  LCount: Integer;
  LDescription: string;
begin
  case ARule of
    grPixelStore:
      if Length(AValues) = 2 then
        SetUnpack(Integer(AValues[0].AsInteger), Integer(AValues[1].AsInteger));
    grTexImage2D:
      if Length(AValues) = 9 then
        SetArgument(AArguments, 8, FormatImage(AValues, 3, 4, -1, 6, 7, 8));
    grTexSubImage2D:
      if Length(AValues) = 9 then
        SetArgument(AArguments, 8, FormatImage(AValues, 4, 5, -1, 6, 7, 8));
    grTexImage3D:
      if Length(AValues) = 10 then
        SetArgument(AArguments, 9, FormatImage(AValues, 3, 4, 5, 7, 8, 9));
    grTexSubImage3D:
      if Length(AValues) = 11 then
        SetArgument(AArguments, 10, FormatImage(AValues, 5, 6, 7, 8, 9, 10));
    grBuild2DMipmaps:
      if Length(AValues) = 7 then
        SetArgument(AArguments, 6, FormatImage(AValues, 2, 3, -1, 4, 5, 6));
    grColorTable:
      if Length(AValues) = 6 then
        SetArgument(AArguments, 5, FormatPalette(AValues));
    grDeleteTextures:
      if Length(AValues) = 2 then
      begin
        LCount := AValues[0].AsCount;
        SetArgument(AArguments, 1, FormatBlock(AValues[1].PointerValue, Int64(LCount) * 4));
      end;
    grColor4fv:
      if Length(AValues) = 1 then
        SetArgument(AArguments, 0, FormatBlock(AValues[0].PointerValue, 16));
    grTexCoord2fv:
      if Length(AValues) = 1 then
        SetArgument(AArguments, 0, FormatBlock(AValues[0].PointerValue, 8));
    grVertex3fv:
      if Length(AValues) = 1 then
        SetArgument(AArguments, 0, FormatBlock(AValues[0].PointerValue, 12));
    grMultMatrixf:
      if Length(AValues) = 1 then
        SetArgument(AArguments, 0, FormatBlock(AValues[0].PointerValue, 64));
    grMultMatrixd:
      if Length(AValues) = 1 then
        SetArgument(AArguments, 0, FormatBlock(AValues[0].PointerValue, 128));
    grFogfv:
      if Length(AValues) = 2 then
      begin
        if AValues[0].AsInteger = GLR_FOG_COLOR then
          LCount := 16
        else
          LCount := 4;
        SetArgument(AArguments, 1, FormatBlock(AValues[1].PointerValue, LCount));
      end;
    grTexGenfv:
      if Length(AValues) = 3 then
      begin
        if AValues[1].AsInteger = GLR_TEXTURE_GEN_MODE then
          LCount := 4
        else
          LCount := 16;
        SetArgument(AArguments, 2, FormatBlock(AValues[2].PointerValue, LCount));
      end;
    grVertexPointer:
      if Length(AValues) = 4 then
        FArrays.SetPointer(cakVertex, AValues[0].AsCount, Cardinal(AValues[1].AsInteger), AValues[2].AsCount,
          AValues[3].PointerValue);
    grTexCoordPointer:
      if Length(AValues) = 4 then
        FArrays.SetPointer(cakTexCoord, AValues[0].AsCount, Cardinal(AValues[1].AsInteger), AValues[2].AsCount,
          AValues[3].PointerValue);
    grEnableClientState:
      if Length(AValues) = 1 then
        FArrays.SetCapability(Cardinal(AValues[0].AsInteger), True);
    grDisableClientState:
      if Length(AValues) = 1 then
        FArrays.SetCapability(Cardinal(AValues[0].AsInteger), False);
    grDrawArrays:
      if Length(AValues) = 3 then
      begin
        LDescription := FArrays.Describe(cakVertex, Integer(AValues[1].AsInteger), AValues[2].AsCount);
        if LDescription <> '' then
          AddArgument(AArguments, 'vertex=' + LDescription);
        LDescription := FArrays.Describe(cakTexCoord, Integer(AValues[1].AsInteger), AValues[2].AsCount);
        if LDescription <> '' then
          AddArgument(AArguments, 'texcoord=' + LDescription);
      end;
  end;
end;

function TGlCallEncoder.Encode(const AName: string; const AValues: array of TGlValue): string;
var
  LArguments: TArray<string>;
  LRule: TGlRule;
  LIndex: Integer;
begin
  SetLength(LArguments, Length(AValues));
  for LIndex := 0 to High(AValues) do
    LArguments[LIndex] := FormatValue(AValues[LIndex]);
  if FRules.TryGetValue(AName, LRule) then
    ApplyRule(LRule, AValues, LArguments);
  Result := AName + '(' + string.Join(',', LArguments) + ')';
end;

function TGlCallEncoder.RuleNames: TArray<string>;
begin
  Result := FRules.Keys.ToArray;
  TArray.Sort<string>(Result);
end;

end.
