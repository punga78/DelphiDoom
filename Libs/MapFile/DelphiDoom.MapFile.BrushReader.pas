{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading a brush                              }
{                                                                              }
{  Port of idMapBrush::Parse and idMapBrush::ParseQ3 (MapFile.cpp, idlib),     }
{  Doom 3 GPL Source Code. Based on the Doom 3 GPL Source Code (id Software).  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.BrushReader;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Brush;

type
  /// <summary>Reads the text after "{ brushDef3" and the like, and the brushes of Quake 3 and older</summary>
  TMapBrushReader = class
  strict private
    class procedure SkipObsoleteFlags(const ASource: TIdLexer); static;
  public
    /// <summary>
    ///   The brush after its keyword up to its closing brace (idMapBrush::Parse). With
    ///   <c>ANewFormat</c> each side has a plane (a b c d), otherwise three points; the points
    ///   are moved by the origin of the entity, the planes of the new format are not. Before
    ///   version 2 the materials get the prefix "textures/". The caller owns the brush;
    ///   a text that is not valid raises
    /// </summary>
    class function Parse(const ASource: TIdLexer; const AOrigin: TGeoVec3; const ANewFormat: Boolean;
      const AVersion: Single): TMapBrush; static;
    /// <summary>
    ///   A brush of Quake 3: sides of three points with a material and shift, rotation and scale,
    ///   up to the closing brace (idMapBrush::ParseQ3). The shift, rotation and scale are read
    ///   and dropped, the texture matrix is the fixed scale 1/32
    /// </summary>
    class function ParseQ3(const ASource: TIdLexer; const AOrigin: TGeoVec3): TMapBrush; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.MapFile.Types, DelphiDoom.MapFile.BrushSide, DelphiDoom.MapFile.ParseFailure;

resourcestring
  SBrushEof = 'idMapBrush::Parse: unexpected EOF';
  SBrushUnexpected = 'idMapBrush::Parse: unexpected %s, expected ( or epair key string';
  SBrushValue = 'idMapBrush::Parse: expected epair value string not found';
  SBrushPlane = 'idMapBrush::Parse: unable to read brush side plane definition';
  SBrushTexMat = 'idMapBrush::Parse: unable to read brush side texture matrix';
  SBrushMaterial = 'idMapBrush::Parse: unable to read brush side material';
  SBrushOpen = 'idMapBrush::Parse: { not found';
  SBrushClose = 'idMapBrush::Parse: } not found';
  SBrushQ3Plane = 'idMapBrush::ParseQ3: unable to read brush side plane definition';
  SBrushQ3Material = 'idMapBrush::ParseQ3: unable to read brush side material';

const
  TEXTURES_PREFIX: AnsiString = 'textures/';
  Q3_TEXTURE_SCALE: Single = 0.03125;

function ReadPoint(const ASource: TIdLexer; out APoint: TGeoVec3): Boolean;
var
  LValues: array[0..2] of Single;
begin
  Result := ASource.Parse1DMatrix(3, LValues);
  APoint.SetValues(LValues[0], LValues[1], LValues[2]);
end;

{ TMapBrushReader }

class procedure TMapBrushReader.SkipObsoleteFlags(const ASource: TIdLexer);
var
  LToken: TIdToken;
begin
  // Q2 allowed override of default flags and values, but we don't any more
  LToken := TIdToken.Create;
  if ASource.ReadTokenOnLine(LToken) then
  begin
    if ASource.ReadTokenOnLine(LToken) then
      ASource.ReadTokenOnLine(LToken);
  end;
end;

class function TMapBrushReader.Parse(const ASource: TIdLexer; const AOrigin: TGeoVec3;
  const ANewFormat: Boolean; const AVersion: Single): TMapBrush;
var
  LToken: TIdToken;
  LSide: TMapBrushSide;
  LPoints: array[0..2] of TGeoVec3;
  LPlane: array[0..3] of Single;
  LMatrix: array[0..5] of Single;
  LKey: AnsiString;
  LPlaneValue: TGeoPlane;
  LVector: TGeoVec3;
begin
  LToken := TIdToken.Create;
  if not ASource.ExpectTokenString('{') then
    TMapParseFailure.Fail(ASource, SBrushOpen, []);
  Result := TMapBrush.Create;
  try
    while True do
    begin
      if not ASource.ReadToken(LToken) then
        TMapParseFailure.Fail(ASource, SBrushEof, []);
      if LToken.IsText('}') then
        Break;

      // here we may have to jump over brush epairs (only used in the editor)
      while not LToken.IsText('(') do
      begin
        // the token should be a key string for a key/value pair
        if LToken.TokenType <> TT_STRING then
          TMapParseFailure.Fail(ASource, SBrushUnexpected, [string(LToken.Text)]);
        LKey := LToken.Text;
        if not ASource.ReadTokenOnLine(LToken) or (LToken.TokenType <> TT_STRING) then
          TMapParseFailure.Fail(ASource, SBrushValue, []);
        Result.Epairs.SetValue(LKey, LToken.Text);
        // try to read the next key
        if not ASource.ReadToken(LToken) then
          TMapParseFailure.Fail(ASource, SBrushEof, []);
      end;

      ASource.UnreadToken(LToken);

      LSide := TMapBrushSide.Create;
      Result.AddSide(LSide);

      if ANewFormat then
      begin
        if not ASource.Parse1DMatrix(4, LPlane) then
          TMapParseFailure.Fail(ASource, SBrushPlane, []);
        LSide.Plane := TGeoPlane.Make(LPlane[0], LPlane[1], LPlane[2], LPlane[3]);
      end
      else
      begin
        // read the three point plane definition
        if not (ReadPoint(ASource, LPoints[0]) and ReadPoint(ASource, LPoints[1]) and
          ReadPoint(ASource, LPoints[2])) then
          TMapParseFailure.Fail(ASource, SBrushPlane, []);
        LPoints[0] := LPoints[0] - AOrigin;
        LPoints[1] := LPoints[1] - AOrigin;
        LPoints[2] := LPoints[2] - AOrigin;
        LPlaneValue := TGeoPlane.Make(0, 0, 0, 0);
        LPlaneValue.FromPoints(LPoints[0], LPoints[1], LPoints[2]);
        LSide.Plane := LPlaneValue;
      end;

      // read the texture matrix: it is 2D relative to the default planar texture axes
      if not ASource.Parse2DMatrix(2, 3, LMatrix) then
        TMapParseFailure.Fail(ASource, SBrushTexMat, []);
      LVector.SetValues(LMatrix[0], LMatrix[1], LMatrix[2]);
      LSide.TextureMatrix[0] := LVector;
      LVector.SetValues(LMatrix[3], LMatrix[4], LMatrix[5]);
      LSide.TextureMatrix[1] := LVector;
      LSide.Origin := AOrigin;

      // read the material
      if not ASource.ReadTokenOnLine(LToken) then
        TMapParseFailure.Fail(ASource, SBrushMaterial, []);
      // we had an implicit 'textures/' in the old format
      if AVersion < 2.0 then
        LSide.Material := TEXTURES_PREFIX + LToken.Text
      else
        LSide.Material := LToken.Text;

      SkipObsoleteFlags(ASource);
    end;

    if not ASource.ExpectTokenString('}') then
      TMapParseFailure.Fail(ASource, SBrushClose, []);
  except
    Result.Free;
    raise;
  end;
end;

class function TMapBrushReader.ParseQ3(const ASource: TIdLexer; const AOrigin: TGeoVec3): TMapBrush;
var
  LToken: TIdToken;
  LSide: TMapBrushSide;
  LPoints: array[0..2] of TGeoVec3;
  LPlane: TGeoPlane;
  LVector: TGeoVec3;
begin
  LToken := TIdToken.Create;
  Result := TMapBrush.Create;
  try
    while not ASource.CheckTokenString('}') do
    begin
      LSide := TMapBrushSide.Create;
      Result.AddSide(LSide);

      // read the three point plane definition
      if not (ReadPoint(ASource, LPoints[0]) and ReadPoint(ASource, LPoints[1]) and
        ReadPoint(ASource, LPoints[2])) then
        TMapParseFailure.Fail(ASource, SBrushQ3Plane, []);
      LPoints[0] := LPoints[0] - AOrigin;
      LPoints[1] := LPoints[1] - AOrigin;
      LPoints[2] := LPoints[2] - AOrigin;
      LPlane := TGeoPlane.Make(0, 0, 0, 0);
      LPlane.FromPoints(LPoints[0], LPoints[1], LPoints[2]);
      LSide.Plane := LPlane;

      // read the material
      if not ASource.ReadTokenOnLine(LToken) then
        TMapParseFailure.Fail(ASource, SBrushQ3Material, []);
      // we have an implicit 'textures/' in the old format
      LSide.Material := TEXTURES_PREFIX + LToken.Text;

      // the texture shift, rotate and scale are read and not kept
      ASource.ParseInt;
      ASource.ParseInt;
      ASource.ParseInt;
      ASource.ParseFloat;
      ASource.ParseFloat;
      LVector.SetValues(Q3_TEXTURE_SCALE, 0, 0);
      LSide.TextureMatrix[0] := LVector;
      LVector.SetValues(0, Q3_TEXTURE_SCALE, 0);
      LSide.TextureMatrix[1] := LVector;
      LSide.Origin := AOrigin;

      SkipObsoleteFlags(ASource);
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
