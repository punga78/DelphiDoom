{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a patch                              }
{                                                                              }
{  Port of idMapPatch::Parse (MapFile.cpp, idlib), Doom 3 GPL Source Code.     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.PatchReader;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Patch;

type
  /// <summary>Reads the text after "{ patchDef2" or "{ patchDef3"</summary>
  TMapPatchReader = class
  public
    /// <summary>
    ///   The patch after its keyword up to its closing brace (idMapPatch::Parse). The points
    ///   are moved by the origin of the entity. patchDef3 has the subdivisions in its header.
    ///   Before version 2 the material gets the prefix "textures/". The caller owns the patch;
    ///   a text that is not valid raises
    /// </summary>
    class function Parse(const ASource: TIdLexer; const AOrigin: TGeoVec3; const APatchDef3: Boolean;
      const AVersion: Single): TMapPatch; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.MapFile.Types,
  DelphiDoom.MapFile.ParseFailure;

resourcestring
  SPatchEof = 'idMapPatch::Parse: unexpected EOF';
  SPatchInfo3 = 'idMapPatch::Parse: unable to Parse patchDef3 info';
  SPatchInfo2 = 'idMapPatch::Parse: unable to parse patchDef2 info';
  SPatchSize = 'idMapPatch::Parse: bad size';
  SPatchData = 'idMapPatch::Parse: bad patch vertex data';
  SPatchRow = 'idMapPatch::Parse: bad vertex row data';
  SPatchColumn = 'idMapPatch::Parse: bad vertex column data';
  SPatchPoints = 'idMapPatch::Parse: unable to parse patch control points';
  SPatchClosure = 'idMapPatch::Parse: unable to parse patch control points, no closure';
  SPatchInvalidWidth = 'idSurface_Patch::SetSize: invalid patchWidth';
  SPatchInvalidHeight = 'idSurface_Patch::SetSize: invalid patchHeight';
  SPatchOpen ='idMapPatch::Parse: { not found';

const
  TEXTURES_PREFIX: AnsiString = 'textures/';

// the C conversion of a float to int truncates; the values the original cannot hold are errors here
function HeaderToInteger(const AValue: Single; const ASource: TIdLexer): Integer;
begin
  if not (AValue > -1.0) or (AValue > MAX_PATCH_VERTICES) then
    TMapParseFailure.Fail(ASource, SPatchSize, []);
  Result := Trunc(AValue);
end;

// the subdivisions are any integer; a value that does not fit (or not a number) is clamped (C: undefined)
function ClampToInteger(const AValue: Single): Integer;
begin
  if not (AValue = AValue) then
    Exit(0);
  if AValue >= 1073741824.0 then
    Exit(1073741824);
  if AValue <= -1073741824.0 then
    Exit(-1073741824);
  Result := Trunc(AValue);
end;

{ TMapPatchReader }

class function TMapPatchReader.Parse(const ASource: TIdLexer; const AOrigin: TGeoVec3;
  const APatchDef3: Boolean; const AVersion: Single): TMapPatch;
var
  LToken: TIdToken;
  LInfo: array[0..6] of Single;
  LValues: array[0..4] of Single;
  LMaterial: AnsiString;
  LWidth, LHeight, LRow, LColumn: Integer;
  LVertex: TMapPatchVertex;
  LKey: AnsiString;
begin
  LToken := TIdToken.Create;
  if not ASource.ExpectTokenString('{') then
    TMapParseFailure.Fail(ASource, SPatchOpen, []);

  // read the material (we had an implicit 'textures/' in the old format...)
  if not ASource.ReadToken(LToken) then
    TMapParseFailure.Fail(ASource, SPatchEof, []);

  if APatchDef3 then
  begin
    if not ASource.Parse1DMatrix(7, LInfo) then
      TMapParseFailure.Fail(ASource, SPatchInfo3, []);
  end
  else
  begin
    if not ASource.Parse1DMatrix(5, LInfo) then
      TMapParseFailure.Fail(ASource, SPatchInfo2, []);
  end;

  LWidth := HeaderToInteger(LInfo[0], ASource);
  LHeight := HeaderToInteger(LInfo[1], ASource);
  if Int64(LWidth) * LHeight > MAX_PATCH_VERTICES then
    TMapParseFailure.Fail(ASource, SPatchSize, []);
  // idSurface_Patch::SetSize: common->FatalError (no file and line in the message)
  if LWidth < 1 then
    raise EMapFileException.Create(SPatchInvalidWidth, ASource.LineNum);
  if LHeight < 1 then
    raise EMapFileException.Create(SPatchInvalidHeight, ASource.LineNum);

  if AVersion < 2.0 then
    LMaterial := TEXTURES_PREFIX + LToken.Text
  else
    LMaterial := LToken.Text;

  Result := TMapPatch.Create(LWidth, LHeight);
  try
    Result.Material := LMaterial;
    if APatchDef3 then
    begin
      Result.HorzSubdivisions := ClampToInteger(LInfo[2]);
      Result.VertSubdivisions := ClampToInteger(LInfo[3]);
      Result.ExplicitlySubdivided := True;
    end;

    // these were written out in the wrong order, IMHO
    if not ASource.ExpectTokenString('(') then
      TMapParseFailure.Fail(ASource, SPatchData, []);
    for LColumn := 0 to LWidth - 1 do
    begin
      if not ASource.ExpectTokenString('(') then
        TMapParseFailure.Fail(ASource, SPatchRow, []);
      for LRow := 0 to LHeight - 1 do
      begin
        if not ASource.Parse1DMatrix(5, LValues) then
          TMapParseFailure.Fail(ASource, SPatchColumn, []);
        LVertex.Position.SetValues(LValues[0] - AOrigin.X, LValues[1] - AOrigin.Y, LValues[2] - AOrigin.Z);
        LVertex.S := LValues[3];
        LVertex.T := LValues[4];
        Result.Vertices[LRow * LWidth + LColumn] := LVertex;
      end;
      if not ASource.ExpectTokenString(')') then
        TMapParseFailure.Fail(ASource, SPatchPoints, []);
    end;
    if not ASource.ExpectTokenString(')') then
      TMapParseFailure.Fail(ASource, SPatchClosure, []);

    // read any key/value pairs
    while ASource.ReadToken(LToken) do
    begin
      if LToken.IsText('}') then
      begin
        ASource.ExpectTokenString('}');
        Break;
      end;
      if LToken.TokenType = TT_STRING then
      begin
        LKey := LToken.Text;
        ASource.ExpectTokenType(TT_STRING, 0, LToken);
        Result.Epairs.SetValue(LKey, LToken.Text);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
