{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading an entity                            }
{                                                                              }
{  Port of idMapEntity::Parse (MapFile.cpp, idlib), Doom 3 GPL Source Code.    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.EntityReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Entity;

type
  /// <summary>Reads an entity: its key/value pairs, brushes and patches</summary>
  TMapEntityReader = class
  public
    /// <summary>
    ///   The next entity, from its opening brace to its closing brace (idMapEntity::Parse); nil
    ///   when the text has ended. A brush is recognised by a keyword that starts with "brush",
    ///   a patch by one that starts with "patch", anything else is a brush of Quake 3. The
    ///   brushes and patches of the worldspawn are not moved by the "origin" key, the ones of the
    ///   other entities are. The caller owns the entity; a text that is not valid raises
    /// </summary>
    class function Parse(const ASource: TIdLexer; const AVersion: Single): TMapEntity; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Str,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.MapFile.Brush,
  DelphiDoom.MapFile.BrushReader, DelphiDoom.MapFile.Patch, DelphiDoom.MapFile.PatchReader,
  DelphiDoom.MapFile.ParseFailure;

resourcestring
  SEntityOpen = 'idMapEntity::Parse: { not found, found %s';
  SEntityEof = 'idMapEntity::Parse: EOF without closing brace';
  SEntityPrimitiveEof = 'idMapEntity::Parse: unexpected EOF';

function StripTrailingWhitespace(const AText: AnsiString): AnsiString;
var
  LText: TIdStr;
begin
  LText := TIdStr.Create(AText);
  LText.StripTrailingWhitespace;
  Result := LText.Text;
end;

// scanf into doubles, then assign, so the value does not depend on the size of the vector
function ScanOrigin(const AValue: AnsiString): TGeoVec3;
var
  LValues: array[0..2] of Single;
begin
  LValues[0] := 0;
  LValues[1] := 0;
  LValues[2] := 0;
  TIdCNumbers.ScanFloats(AValue, LValues);
  Result.SetValues(LValues[0], LValues[1], LValues[2]);
end;

{ TMapEntityReader }

class function TMapEntityReader.Parse(const ASource: TIdLexer; const AVersion: Single): TMapEntity;
var
  LToken: TIdToken;
  LKey, LValue: AnsiString;
  LOrigin: TGeoVec3;
  LWorldEntity: Boolean;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
    Exit(nil);
  if not LToken.IsText('{') then
    TMapParseFailure.Fail(ASource, SEntityOpen, [string(LToken.Text)]);

  Result := TMapEntity.Create;
  try
    LOrigin.Zero;
    LWorldEntity := False;
    while True do
    begin
      if not ASource.ReadToken(LToken) then
        TMapParseFailure.Fail(ASource, SEntityEof, []);
      if LToken.IsText('}') then
        Break;

      if LToken.IsText('{') then
      begin
        // parse a brush or patch
        if not ASource.ReadToken(LToken) then
          TMapParseFailure.Fail(ASource, SEntityPrimitiveEof, []);
        if LWorldEntity then
          LOrigin.Zero;

        if TIdStrings.Icmpn(LToken.Text, 'brush', 5) = 0 then
        begin
          // brush, brushDef, brushDef2, brushDef3
          Result.AddPrimitive(TMapBrushReader.Parse(ASource, LOrigin,
            (TIdStrings.Icmp(LToken.Text, 'brushDef2') = 0) or (TIdStrings.Icmp(LToken.Text, 'brushDef3') = 0),
            AVersion));
        end
        else if TIdStrings.Icmpn(LToken.Text, 'patch', 5) = 0 then
        begin
          // patchDef2, patchDef3
          Result.AddPrimitive(TMapPatchReader.Parse(ASource, LOrigin,
            TIdStrings.Icmp(LToken.Text, 'patchDef3') = 0, AVersion));
        end
        else
        begin
          // assume it's a brush in Q3 or older style
          ASource.UnreadToken(LToken);
          Result.AddPrimitive(TMapBrushReader.ParseQ3(ASource, LOrigin));
        end;
      end
      else
      begin
        // parse a key / value pair; a missing value leaves the token as the lexer left it
        LKey := LToken.Text;
        ASource.ReadTokenOnLine(LToken);
        LValue := LToken.Text;

        // strip trailing spaces that sometimes get accidentally added in the editor
        LValue := StripTrailingWhitespace(LValue);
        LKey := StripTrailingWhitespace(LKey);

        Result.Epairs.SetValue(LKey, LValue);

        if TIdStrings.Icmp(LKey, 'origin') = 0 then
          LOrigin := ScanOrigin(LValue)
        else if (TIdStrings.Icmp(LKey, 'classname') = 0) and (TIdStrings.Icmp(LValue, 'worldspawn') = 0) then
          LWorldEntity := True;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
