{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading the "settings" of an .aas file       }
{                                                                              }
{  Port of idAASSettings::FromParser and its Parse functions (AASFile.cpp),    }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.SettingsReader;

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Aas.Settings;

type
  /// <summary>
  ///   Reads what follows the keyword "settings": a block in braces of "name = value" lines
  ///   (and the "bboxes" block). The original is run with errors that do not stop it (a
  ///   misspelled name is a warning and the loop goes on); here every error of the lexer is
  ///   an error of the file
  /// </summary>
  TAasSettingsReader = class
  strict private
    class procedure ReadBoundingBoxes(const ALexer: TIdLexer; const ASettings: TAasSettings); static;
    class function ReadBool(const ALexer: TIdLexer): Boolean; static;
    class function ReadFloat(const ALexer: TIdLexer): Single; static;
    class function ReadInt(const ALexer: TIdLexer): Integer; static;
  public
    class procedure Parse(const ALexer: TIdLexer; const ASettings: TAasSettings); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.IdLib.Text.Token,
  DelphiDoom.IdLib.Text.Types;

resourcestring
  SInvalidToken = 'invalid token ''%s''';
  SNoBoundingBox = 'no valid bounding box';
  SEndOfFile = 'unexpected end of file in the settings';

{ TAasSettingsReader }

class function TAasSettingsReader.ReadBool(const ALexer: TIdLexer): Boolean;
begin
  ALexer.ExpectTokenString('=');
  Result := ALexer.ParseBool;
end;

class function TAasSettingsReader.ReadFloat(const ALexer: TIdLexer): Single;
begin
  ALexer.ExpectTokenString('=');
  Result := ALexer.ParseFloat;
end;

class function TAasSettingsReader.ReadInt(const ALexer: TIdLexer): Integer;
begin
  ALexer.ExpectTokenString('=');
  Result := ALexer.ParseInt;
end;

class procedure TAasSettingsReader.ReadBoundingBoxes(const ALexer: TIdLexer;
  const ASettings: TAasSettings);
var
  LToken: TIdToken;
  LMins, LMaxs: array[0..2] of Single;
begin
  ASettings.ClearBoundingBoxes;
  ALexer.ExpectTokenString('{');
  LToken := TIdToken.Create;
  while ALexer.ReadToken(LToken) do
  begin
    if LToken.IsText('}') then
      Exit;
    ALexer.UnreadToken(LToken);
    ALexer.Parse1DMatrix(3, LMins);
    ALexer.ExpectTokenString('-');
    ALexer.Parse1DMatrix(3, LMaxs);
    ASettings.AddBoundingBox(TGeoBounds.Make(TGeoVec3.Make(LMins[0], LMins[1], LMins[2]),
      TGeoVec3.Make(LMaxs[0], LMaxs[1], LMaxs[2])));
  end;
  ALexer.Error('%s', [SEndOfFile]);
end;

class procedure TAasSettingsReader.Parse(const ALexer: TIdLexer; const ASettings: TAasSettings);
var
  LToken: TIdToken;
  LGravity: array[0..2] of Single;
begin
  ALexer.ExpectTokenString('{');
  LToken := TIdToken.Create;
  while ALexer.ReadToken(LToken) do
  begin
    if LToken.IsText('}') then
      Break;
    if LToken.IsText('bboxes') then
      ReadBoundingBoxes(ALexer, ASettings)
    else if LToken.IsText('usePatches') then
      ASettings.UsePatches := ReadBool(ALexer)
    else if LToken.IsText('writeBrushMap') then
      ASettings.WriteBrushMap := ReadBool(ALexer)
    else if LToken.IsText('playerFlood') then
      ASettings.PlayerFlood := ReadBool(ALexer)
    else if LToken.IsText('allowSwimReachabilities') then
      ASettings.AllowSwimReachabilities := ReadBool(ALexer)
    else if LToken.IsText('allowFlyReachabilities') then
      ASettings.AllowFlyReachabilities := ReadBool(ALexer)
    else if LToken.IsText('fileExtension') then
    begin
      ALexer.ExpectTokenString('=');
      ALexer.ExpectTokenType(TT_STRING, 0, LToken);
      ASettings.FileExtension := LToken.Text;
    end
    else if LToken.IsText('gravity') then
    begin
      ALexer.ExpectTokenString('=');
      ALexer.Parse1DMatrix(3, LGravity);
      ASettings.Gravity := TGeoVec3.Make(LGravity[0], LGravity[1], LGravity[2]);
    end
    else if LToken.IsText('maxStepHeight') then
      ASettings.MaxStepHeight := ReadFloat(ALexer)
    else if LToken.IsText('maxBarrierHeight') then
      ASettings.MaxBarrierHeight := ReadFloat(ALexer)
    else if LToken.IsText('maxWaterJumpHeight') then
      ASettings.MaxWaterJumpHeight := ReadFloat(ALexer)
    else if LToken.IsText('maxFallHeight') then
      ASettings.MaxFallHeight := ReadFloat(ALexer)
    else if LToken.IsText('minFloorCos') then
      ASettings.MinFloorCos := ReadFloat(ALexer)
    else if LToken.IsText('tt_barrierJump') then
      ASettings.BarrierJumpTime := ReadInt(ALexer)
    else if LToken.IsText('tt_startCrouching') then
      ASettings.StartCrouchingTime := ReadInt(ALexer)
    else if LToken.IsText('tt_waterJump') then
      ASettings.WaterJumpTime := ReadInt(ALexer)
    else if LToken.IsText('tt_startWalkOffLedge') then
      ASettings.StartWalkOffLedgeTime := ReadInt(ALexer)
    else
      ALexer.Error(SInvalidToken, [string(LToken.Text)]);
  end;
  if ASettings.NumBoundingBoxes <= 0 then
    ALexer.Error('%s', [SNoBoundingBox]);
end;

end.
