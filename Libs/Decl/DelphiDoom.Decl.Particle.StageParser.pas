{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TParticleStageParser, one stage of a      }
{  particle declaration                                                        }
{                                                                              }
{  Port of the particle systems of Doom 3 (id Software, GPL v3):               }
{  framework\DeclParticle.cpp (idDeclParticle::ParseParticleStage, ParseParms, }
{  ParseParametric). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.StageParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Particle.Types;

type
  /// <summary>
  ///   Reads the text between the braces of one stage (<c>count 100 / material x / ...</c>). The materials and the
  ///   tables it names are found through the finder it is given; a syntax error is a warning of the lexer (and
  ///   stops the stage), never an exception.
  /// </summary>
  TParticleStageParser = class
  strict private
    FFinder: IDeclFinder;
    procedure ParseParms(const ASource: TIdLexer; var AParms: array of Single);
    procedure ParseParametric(const ASource: TIdLexer; var AParm: TParticleParm);
  public
    constructor Create(const AFinder: IDeclFinder);
    /// <summary>
    ///   idDeclParticle::ParseParticleStage: <c>ASource</c> is just after the opening brace; reads up to the closing
    ///   one. The stage starts from <c>SetDefault</c>.
    /// </summary>
    function ParseStage(const ASource: TIdLexer): TParticleStage;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Table;

{ TParticleStageParser }

constructor TParticleStageParser.Create(const AFinder: IDeclFinder);
begin
  inherited Create;
  if not Assigned(AFinder) then
    raise EDeclParticleException.Create('a particle stage parser needs a finder of declarations');
  FFinder := AFinder;
end;

// idStr::StripQuotes
function StripQuotes(const AText: AnsiString): AnsiString;
begin
  Result := AText;
  if (Result = '') or (Result[1] <> '"') then
    Exit;
  // remove the trailing quote first
  if Result[Length(Result)] = '"' then
    Delete(Result, Length(Result), 1);
  // remove the leading quote now
  Delete(Result, 1, 1);
end;

procedure TParticleStageParser.ParseParms(const ASource: TIdLexer; var AParms: array of Single);
var
  LToken: TIdToken;
  LCount, LIndex: Integer;
begin
  // parses a variable length list of parms on one line
  for LIndex := 0 to High(AParms) do
    AParms[LIndex] := 0.0;
  LCount := 0;
  LToken := TIdToken.Create;
  while True do
  begin
    if not ASource.ReadTokenOnLine(LToken) then
      Exit;
    if LCount = Length(AParms) then
    begin
      ASource.Error('too many parms on line', []);
      Exit;
    end;
    LToken.Text := StripQuotes(LToken.Text);
    AParms[LCount] := TIdCNumbers.Atof(LToken.Text);
    Inc(LCount);
  end;
end;

procedure TParticleStageParser.ParseParametric(const ASource: TIdLexer; var AParm: TParticleParm);
var
  LToken: TIdToken;
  LTable: IDeclTable;
  LDecl: IDecl;
begin
  LToken := TIdToken.Create;
  AParm.Table := nil;
  AParm.FromValue := 0.0;
  AParm.ToValue := 0.0;

  if not ASource.ReadToken(LToken) then
  begin
    ASource.Error('not enough parameters', []);
    Exit;
  end;

  if TIdStrings.IsNumeric(LToken.Text) then
  begin
    // can have a to + 2nd parm
    AParm.FromValue := TIdCNumbers.Atof(LToken.Text);
    AParm.ToValue := AParm.FromValue;
    if ASource.ReadToken(LToken) then
    begin
      if TIdStrings.Icmp(LToken.Text, 'to') = 0 then
      begin
        if not ASource.ReadToken(LToken) then
        begin
          ASource.Error('missing second parameter', []);
          Exit;
        end;
        AParm.ToValue := TIdCNumbers.Atof(LToken.Text);
      end
      else
        ASource.UnreadToken(LToken);
    end;
  end
  else
  begin
    // table
    LDecl := FFinder.FindType(DECL_TABLE, LToken.Text, False);
    if Assigned(LDecl) and Supports(LDecl, IDeclTable, LTable) then
      AParm.Table := LTable;
  end;
end;

function TParticleStageParser.ParseStage(const ASource: TIdLexer): TParticleStage;
var
  LToken: TIdToken;
  LKeyword: AnsiString;
  LLife: Single;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LKeyword, AName) = 0;
  end;

  procedure ReadKind(const ANames: array of AnsiString; const AWhat: string; out AIndex: Integer);
  var
    LNameIndex: Integer;
  begin
    ASource.ReadToken(LToken);
    AIndex := -1;
    for LNameIndex := 0 to High(ANames) do
      if TIdStrings.Icmp(LToken.Text, ANames[LNameIndex]) = 0 then
      begin
        AIndex := LNameIndex;
        Break;
      end;
    if AIndex < 0 then
      ASource.Error('bad %s type: %s'#10, [AWhat, string(LToken.Text)]);
  end;

var
  LKind: Integer;
begin
  LToken := TIdToken.Create;
  Result := TParticleStage.Create;
  Result.SetDefault(FFinder.FindType(DECL_MATERIAL, '_default'));

  while True do
  begin
    if ASource.HadError then
      Break;
    if not ASource.ReadToken(LToken) then
      Break;
    LKeyword := LToken.Text;
    if Keyword('}') then
      Break;
    if Keyword('material') then
    begin
      ASource.ReadToken(LToken);
      Result.Material := FFinder.FindType(DECL_MATERIAL, LToken.Text);
      Continue;
    end;
    if Keyword('count') then
    begin
      Result.TotalParticles := ASource.ParseInt;
      Continue;
    end;
    if Keyword('time') then
    begin
      Result.ParticleLife := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('cycles') then
    begin
      Result.Cycles := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('timeOffset') then
    begin
      Result.TimeOffset := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('deadTime') then
    begin
      Result.DeadTime := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('randomDistribution') then
    begin
      Result.RandomDistribution := ASource.ParseBool;
      Continue;
    end;
    if Keyword('bunching') then
    begin
      Result.SpawnBunching := ASource.ParseFloat;
      Continue;
    end;

    if Keyword('distribution') then
    begin
      ReadKind(['rect', 'cylinder', 'sphere'], 'distribution', LKind);
      if LKind >= 0 then
        Result.DistributionType := TParticleDistribution(LKind);
      ParseParms(ASource, Result.DistributionParms);
      Continue;
    end;

    if Keyword('direction') then
    begin
      ReadKind(['cone', 'outward'], 'direction', LKind);
      if LKind >= 0 then
        Result.DirectionType := TParticleDirection(LKind);
      ParseParms(ASource, Result.DirectionParms);
      Continue;
    end;

    if Keyword('orientation') then
    begin
      ReadKind(['view', 'aimed', 'x', 'y', 'z'], 'orientation', LKind);
      if LKind >= 0 then
        Result.Orientation := TParticleOrientation(LKind);
      ParseParms(ASource, Result.OrientationParms);
      Continue;
    end;

    if Keyword('customPath') then
    begin
      // "spherical" is the word of the original for the orbit path; "orbit" and "drip" are not accepted
      ReadKind(['standard', 'helix', 'flies', 'spherical'], 'path', LKind);
      if LKind >= 0 then
        Result.CustomPathType := TParticleCustomPath(LKind);
      ParseParms(ASource, Result.CustomPathParms);
      Continue;
    end;

    if Keyword('speed') then
    begin
      ParseParametric(ASource, Result.Speed);
      Continue;
    end;
    if Keyword('rotation') then
    begin
      ParseParametric(ASource, Result.RotationSpeed);
      Continue;
    end;
    if Keyword('angle') then
    begin
      Result.InitialAngle := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('entityColor') then
    begin
      Result.EntityColor := ASource.ParseBool;
      Continue;
    end;
    if Keyword('size') then
    begin
      ParseParametric(ASource, Result.Size);
      Continue;
    end;
    if Keyword('aspect') then
    begin
      ParseParametric(ASource, Result.Aspect);
      Continue;
    end;
    if Keyword('fadeIn') then
    begin
      Result.FadeInFraction := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('fadeOut') then
    begin
      Result.FadeOutFraction := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('fadeIndex') then
    begin
      Result.FadeIndexFraction := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('color') then
    begin
      Result.Color.X := ASource.ParseFloat;
      Result.Color.Y := ASource.ParseFloat;
      Result.Color.Z := ASource.ParseFloat;
      Result.Color.W := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('fadeColor') then
    begin
      Result.FadeColor.X := ASource.ParseFloat;
      Result.FadeColor.Y := ASource.ParseFloat;
      Result.FadeColor.Z := ASource.ParseFloat;
      Result.FadeColor.W := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('offset') then
    begin
      Result.Offset.X := ASource.ParseFloat;
      Result.Offset.Y := ASource.ParseFloat;
      Result.Offset.Z := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('animationFrames') then
    begin
      Result.AnimationFrames := ASource.ParseInt;
      Continue;
    end;
    if Keyword('animationRate') then
    begin
      Result.AnimationRate := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('boundsExpansion') then
    begin
      Result.BoundsExpansion := ASource.ParseFloat;
      Continue;
    end;
    if Keyword('gravity') then
    begin
      ASource.ReadToken(LToken);
      if TIdStrings.Icmp(LToken.Text, 'world') = 0 then
        Result.WorldGravity := True
      else
        ASource.UnreadToken(LToken);
      Result.Gravity := ASource.ParseFloat;
      Continue;
    end;

    ASource.Error('unknown token %s'#10, [string(LToken.Text)]);
  end;

  // derive values
  LLife := (Result.ParticleLife + Result.DeadTime) * 1000;
  Result.CycleMsec := Trunc(LLife);
end;

end.
