{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading the areas of an .aas file            }
{                                                                              }
{  Port of ParseAreas, ParseReachabilities, LinkReversedReachability and       }
{  Reachability_Read / Reachability_Special_Read of idAASFileLocal             }
{  (AASFile.cpp), Doom 3 GPL Source Code.                                      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.AreaReader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Reachability;

type
  /// <summary>
  ///   Reads what follows "areas": for each area "N ( flags contents firstFace numFaces cluster
  ///   clusterAreaNum ) COUNT {", the reachabilities and "}". The reachabilities are put in the
  ///   chain order of the original (the reverse of the file) and linked to the areas they lead
  ///   to; a reachability to an area that does not exist is an error (the original would index
  ///   out of its array)
  /// </summary>
  TAasAreaReader = class
  strict private
    class procedure ReadSpecial(const ALexer: TIdLexer; const AReach: TAasReachability); static;
    class function ReadReachability(const ALexer: TIdLexer; const AAreaNum: Integer): TAasReachability; static;
    class procedure ReadReachabilities(const ALexer: TIdLexer; const AArea: TAasArea;
      const AAreaNum: Integer); static;
    class procedure LinkReversedReachability(const ALexer: TIdLexer; const AFile: TAasFile); static;
  public
    /// <summary>Adds the areas to the file</summary>
    class procedure Parse(const ALexer: TIdLexer; const AFile: TAasFile); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Geometry, DelphiDoom.MapFile.Aas.Parse;

resourcestring
  SBadReachabilityCount = 'bad number of reachabilities';
  SSpecialNotClosed = 'unexpected end of file in a special reachability';
  SReachabilityTarget = 'reachability of area %d leads to area %d, which is not in 0..%d';

{ TAasAreaReader }

class procedure TAasAreaReader.ReadSpecial(const ALexer: TIdLexer; const AReach: TAasReachability);
var
  LKey, LValue: TIdToken;
begin
  ALexer.ExpectTokenString('{');
  LKey := TIdToken.Create;
  LValue := TIdToken.Create;
  while ALexer.ReadToken(LKey) do
  begin
    if LKey.IsText('}') then
      Exit;
    ALexer.ExpectTokenType(TT_STRING, 0, LValue);
    AReach.EnsureSpecial.SetValue(LKey.Text, LValue.Text);
  end;
  ALexer.Error('%s', [SSpecialNotClosed]);
end;

class function TAasAreaReader.ReadReachability(const ALexer: TIdLexer;
  const AAreaNum: Integer): TAasReachability;
var
  LValues: array[0..2] of Single;
begin
  Result := TAasReachability.Create;
  try
    Result.TravelType := ALexer.ParseInt;
    Result.ToAreaNum := SmallInt(ALexer.ParseInt);
    ALexer.Parse1DMatrix(3, LValues);
    Result.StartPoint := TGeoVec3.Make(LValues[0], LValues[1], LValues[2]);
    ALexer.Parse1DMatrix(3, LValues);
    Result.EndPoint := TGeoVec3.Make(LValues[0], LValues[1], LValues[2]);
    Result.EdgeNum := ALexer.ParseInt;
    Result.TravelTime := Word(ALexer.ParseInt);
    if Result.TravelType = TFL_SPECIAL then
      ReadSpecial(ALexer, Result);
    Result.FromAreaNum := SmallInt(AAreaNum);
  except
    Result.Free;
    raise;
  end;
end;

class procedure TAasAreaReader.ReadReachabilities(const ALexer: TIdLexer; const AArea: TAasArea;
  const AAreaNum: Integer);
var
  LCount, LIndex: Integer;
begin
  LCount := ALexer.ParseInt;
  if (LCount < 0) or (LCount > MAX_AAS_ELEMENTS) then
    ALexer.Error('%s', [SBadReachabilityCount]);
  ALexer.ExpectTokenString('{');
  AArea.TravelFlags := TAasGeometry.AreaContentsTravelFlags(AArea.Contents);
  for LIndex := 0 to LCount - 1 do
    AArea.Reach.Add(ReadReachability(ALexer, AAreaNum));
  // the original pushes each new reachability on the front of a chain
  AArea.Reach.Reverse;
  ALexer.ExpectTokenString('}');
end;

class procedure TAasAreaReader.LinkReversedReachability(const ALexer: TIdLexer; const AFile: TAasFile);
var
  LIndex: Integer;
  LReach: TAasReachability;
begin
  for LIndex := 0 to AFile.NumAreas - 1 do
    for LReach in AFile.Areas[LIndex].Reach do
    begin
      if (LReach.ToAreaNum < 0) or (LReach.ToAreaNum >= AFile.NumAreas) then
        ALexer.Error(SReachabilityTarget, [LIndex, LReach.ToAreaNum, AFile.NumAreas - 1]);
      AFile.Areas[LReach.ToAreaNum].ReverseReach.Add(LReach);
    end;
  // each one was pushed on the front of the chain of the area it leads to
  for LIndex := 0 to AFile.NumAreas - 1 do
    AFile.Areas[LIndex].ReverseReach.Reverse;
end;

class procedure TAasAreaReader.Parse(const ALexer: TIdLexer; const AFile: TAasFile);
var
  LCount, LIndex: Integer;
  LArea: TAasArea;
begin
  LCount := TAasParse.BeginSection(ALexer, 'areas');
  AFile.Areas.Clear;
  for LIndex := 0 to LCount - 1 do
  begin
    LArea := TAasArea.Create;
    AFile.Areas.Add(LArea);
    TAasParse.BeginElement(ALexer);
    LArea.Flags := Word(ALexer.ParseInt);
    LArea.Contents := Word(ALexer.ParseInt);
    LArea.FirstFace := ALexer.ParseInt;
    LArea.NumFaces := ALexer.ParseInt;
    LArea.Cluster := SmallInt(ALexer.ParseInt);
    LArea.ClusterAreaNum := SmallInt(ALexer.ParseInt);
    TAasParse.EndElement(ALexer);
    ReadReachabilities(ALexer, LArea, LIndex);
  end;
  TAasParse.EndSection(ALexer);
  LinkReversedReachability(ALexer, AFile);
end;

end.
