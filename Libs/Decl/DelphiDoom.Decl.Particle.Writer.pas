{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TParticleWriter, a particle declaration   }
{  as text                                                                     }
{                                                                              }
{  Port of the particle systems of Doom 3 (id Software, GPL v3):               }
{  framework\DeclParticle.cpp (idDeclParticle::RebuildTextSource, WriteStage,  }
{  WriteParticleParm). Copyright (C) 1999-2011 id Software LLC, a ZeniMax      }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.Writer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Particle.Types;

type
  /// <summary>
  ///   Writes the text the particle editor of Doom 3 writes. The numbers have three decimals (the depth hack as <c>%f</c> of the file class of Doom 3: up to ten, without trailing zeros), with
  ///   a point, whatever the locale. Like the original it does not write the ring fraction of a
  ///   <c>sphere</c> distribution (the description of the type says three parameters), and it writes the path
  ///   types <c>orbit</c> and <c>drip</c> by name although the parser reads only <c>spherical</c> for the first and
  ///   not the second.
  /// </summary>
  TParticleWriter = class sealed
  strict private
    class function Fixed(const AValue: Single; const ADecimals: Integer = 3): string; static;
    /// <summary>The "%f" of idFile::WriteFloatString: ten decimals with the trailing zeros and the point stripped</summary>
    class function Plain(const AValue: Single): string; static;
    class function TableName(const AParm: TParticleParm): string; static;
    class function WriteParm(const AParm: TParticleParm; const AName: string): string; static;
    class function WriteStage(const AStage: TParticleStage): string; static;
  public
    /// <summary>idDeclParticle::RebuildTextSource: the comment, <c>particle name {</c>, the stages and the closing brace</summary>
    class function RebuildText(const AName: AnsiString; const ADepthHack: Single;
      const AStages: TArray<TParticleStage>): AnsiString; static;
  end;

implementation

var
  GInvariant: TFormatSettings;

{ TParticleWriter }

class function TParticleWriter.Fixed(const AValue: Single; const ADecimals: Integer): string;
begin
  Result := Format('%.*f', [ADecimals, Double(AValue)], GInvariant);
end;

class function TParticleWriter.Plain(const AValue: Single): string;
begin
  Result := Format('%.10f', [Double(AValue)], GInvariant);
  while (Result <> '') and (Result[Length(Result)] = '0') do
    Delete(Result, Length(Result), 1);
  while (Result <> '') and (Result[Length(Result)] = '.') do
    Delete(Result, Length(Result), 1);
end;

class function TParticleWriter.TableName(const AParm: TParticleParm): string;
var
  LDecl: IDecl;
begin
  if Supports(AParm.Table, IDecl, LDecl) then
    Result := string(LDecl.GetName)
  else
    Result := '';
end;

class function TParticleWriter.WriteParm(const AParm: TParticleParm; const AName: string): string;
begin
  Result := #9#9 + AName + #9#9#9#9' ';
  if Assigned(AParm.Table) then
    // the table is a declaration too: its name is written (table->GetName())
    Result := Result + TableName(AParm) + #10
  else
  begin
    Result := Result + '"' + Fixed(AParm.FromValue) + '" ';
    if AParm.FromValue = AParm.ToValue then
      Result := Result + #10
    else
      Result := Result + ' to "' + Fixed(AParm.ToValue) + '"'#10;
  end;
end;

class function TParticleWriter.WriteStage(const AStage: TParticleStage): string;
var
  LIndex: Integer;
  LMaterialName: string;
begin
  if Assigned(AStage.Material) then
    LMaterialName := string(AStage.Material.GetName)
  else
    LMaterialName := '';
  Result := #9'{'#10;
  Result := Result + #9#9'count'#9#9#9#9 + IntToStr(AStage.TotalParticles) + #10;
  Result := Result + #9#9'material'#9#9#9 + LMaterialName + #10;
  if AStage.AnimationFrames <> 0 then
    Result := Result + #9#9'animationFrames '#9 + IntToStr(AStage.AnimationFrames) + #10;
  if AStage.AnimationRate <> 0 then
    Result := Result + #9#9'animationRate '#9#9 + Fixed(AStage.AnimationRate) + #10;
  Result := Result + #9#9'time'#9#9#9#9 + Fixed(AStage.ParticleLife) + #10;
  Result := Result + #9#9'cycles'#9#9#9#9 + Fixed(AStage.Cycles) + #10;
  if AStage.TimeOffset <> 0 then
    Result := Result + #9#9'timeOffset'#9#9#9 + Fixed(AStage.TimeOffset) + #10;
  if AStage.DeadTime <> 0 then
    Result := Result + #9#9'deadTime'#9#9#9 + Fixed(AStage.DeadTime) + #10;
  Result := Result + #9#9'bunching'#9#9#9 + Fixed(AStage.SpawnBunching) + #10;

  Result := Result + #9#9'distribution'#9#9 + string(PARTICLE_DISTRIBUTION_NAMES[AStage.DistributionType]) + ' ';
  for LIndex := 0 to PARTICLE_DISTRIBUTION_PARMS[AStage.DistributionType] - 1 do
    Result := Result + Fixed(AStage.DistributionParms[LIndex]) + ' ';
  Result := Result + #10;

  Result := Result + #9#9'direction'#9#9#9 + string(PARTICLE_DIRECTION_NAMES[AStage.DirectionType]) + ' ';
  for LIndex := 0 to PARTICLE_DIRECTION_PARMS[AStage.DirectionType] - 1 do
    Result := Result + '"' + Fixed(AStage.DirectionParms[LIndex]) + '" ';
  Result := Result + #10;

  Result := Result + #9#9'orientation'#9#9#9 + string(PARTICLE_ORIENTATION_NAMES[AStage.Orientation]) + ' ';
  for LIndex := 0 to PARTICLE_ORIENTATION_PARMS[AStage.Orientation] - 1 do
    Result := Result + Fixed(AStage.OrientationParms[LIndex]) + ' ';
  Result := Result + #10;

  if AStage.CustomPathType <> TParticleCustomPath.Standard then
  begin
    Result := Result + #9#9'customPath ' + string(PARTICLE_CUSTOM_NAMES[AStage.CustomPathType]) + ' ';
    for LIndex := 0 to PARTICLE_CUSTOM_PARMS[AStage.CustomPathType] - 1 do
      Result := Result + Fixed(AStage.CustomPathParms[LIndex]) + ' ';
    Result := Result + #10;
  end;

  if AStage.EntityColor then
    Result := Result + #9#9'entityColor'#9#9#9'1'#10;

  Result := Result + WriteParm(AStage.Speed, 'speed');
  Result := Result + WriteParm(AStage.Size, 'size');
  Result := Result + WriteParm(AStage.Aspect, 'aspect');

  if AStage.RotationSpeed.FromValue <> 0 then
    Result := Result + WriteParm(AStage.RotationSpeed, 'rotation');

  if AStage.InitialAngle <> 0 then
    Result := Result + #9#9'angle'#9#9#9#9 + Fixed(AStage.InitialAngle) + #10;

  Result := Result + #9#9'randomDistribution'#9#9#9#9 + IntToStr(Ord(AStage.RandomDistribution)) + #10;
  Result := Result + #9#9'boundsExpansion'#9#9#9#9 + Fixed(AStage.BoundsExpansion) + #10;

  Result := Result + #9#9'fadeIn'#9#9#9#9 + Fixed(AStage.FadeInFraction) + #10;
  Result := Result + #9#9'fadeOut'#9#9#9#9 + Fixed(AStage.FadeOutFraction) + #10;
  Result := Result + #9#9'fadeIndex'#9#9#9#9 + Fixed(AStage.FadeIndexFraction) + #10;

  Result := Result + #9#9'color '#9#9#9#9 + Fixed(AStage.Color.X) + ' ' + Fixed(AStage.Color.Y) + ' ' +
    Fixed(AStage.Color.Z) + ' ' + Fixed(AStage.Color.W) + #10;
  Result := Result + #9#9'fadeColor '#9#9#9 + Fixed(AStage.FadeColor.X) + ' ' + Fixed(AStage.FadeColor.Y) + ' ' +
    Fixed(AStage.FadeColor.Z) + ' ' + Fixed(AStage.FadeColor.W) + #10;

  Result := Result + #9#9'offset '#9#9#9#9 + Fixed(AStage.Offset.X) + ' ' + Fixed(AStage.Offset.Y) + ' ' +
    Fixed(AStage.Offset.Z) + #10;
  Result := Result + #9#9'gravity '#9#9#9;
  if AStage.WorldGravity then
    Result := Result + 'world ';
  Result := Result + Fixed(AStage.Gravity) + #10;
  Result := Result + #9'}'#10;
end;

class function TParticleWriter.RebuildText(const AName: AnsiString; const ADepthHack: Single;
  const AStages: TArray<TParticleStage>): AnsiString;
var
  LText: string;
  LIndex: Integer;
begin
  LText := #10#10'/*'#10#9'Generated by the Particle Editor.'#10 +
    #9'To use the particle editor, launch the game and type ''editParticles'' on the console.'#10'*/'#10;
  LText := LText + 'particle ' + string(AName) + ' {'#10;
  if ADepthHack <> 0 then
    LText := LText + #9'depthHack'#9 + Plain(ADepthHack) + #10;
  for LIndex := 0 to High(AStages) do
    LText := LText + WriteStage(AStages[LIndex]);
  LText := LText + '}';
  Result := AnsiString(LText);
end;

initialization
  GInvariant := TFormatSettings.Invariant;

end.
