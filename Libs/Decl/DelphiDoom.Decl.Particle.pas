{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclParticle, the "particle"             }
{  declaration                                                                 }
{                                                                              }
{  Port of the particle systems of Doom 3 (id Software, GPL v3):               }
{  framework\DeclParticle.h, DeclParticle.cpp. Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Geometry.Bounds, DelphiDoom.Decl.Base,
  DelphiDoom.Decl.Particle.Types, DelphiDoom.Decl.Particle.Intf;

type
  /// <summary>Makes the calculator of the particles that works with the log of the declaration (the message of a table that cannot be integrated)</summary>
  TParticleGeneratorFactory = reference to function(const ALog: IIdLibLog): IParticleGenerator;

  /// <summary>
  ///   <c>particle name { depthHack 1  { count 100 ... } { ... } }</c>: the stages of a particle system. The
  ///   bounds of each stage and of the whole are calculated while it parses. A syntax error outside a stage
  ///   (an unknown word) is a warning and the declaration becomes the default one (one stage of 20 particles).
  ///   <para>Not ported: <c>Save</c> with a file name (create the declaration with the manager, then <c>Save</c>).</para>
  /// </summary>
  TDeclParticle = class(TDecl, IDeclParticle, IDeclParticleWriter)
  strict private
    FGeneratorFactory: TParticleGeneratorFactory;
    FStages: TArray<TParticleStage>;
    FBounds: TGeoBounds;
    FDepthHack: Single;
  public
    constructor Create(const AGeneratorFactory: TParticleGeneratorFactory);
    function GetNumStages: Integer;
    function GetStage(const AIndex: Integer): TParticleStage;
    function GetBounds: TGeoBounds;
    function GetDepthHack: Single;
    function RebuildTextSource: AnsiString;
    function Save: Boolean;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.Particle.StageParser, DelphiDoom.Decl.Particle.Writer, DelphiDoom.Geometry.Vec3;

{ TDeclParticle }

constructor TDeclParticle.Create(const AGeneratorFactory: TParticleGeneratorFactory);
begin
  inherited Create;
  if not Assigned(AGeneratorFactory) then
    raise EDeclParticleException.Create('a particle declaration needs a factory of generators');
  FGeneratorFactory := AGeneratorFactory;
  FBounds.Clear;
end;

function TDeclParticle.GetNumStages: Integer;
begin
  Result := Length(FStages);
end;

function TDeclParticle.GetStage(const AIndex: Integer): TParticleStage;
begin
  if (AIndex < 0) or (AIndex >= Length(FStages)) then
    raise EDeclParticleException.CreateFmt('particle stage %d out of range', [AIndex]);
  Result := FStages[AIndex];
end;

function TDeclParticle.GetBounds: TGeoBounds;
begin
  Result := FBounds;
end;

function TDeclParticle.GetDepthHack: Single;
begin
  Result := FDepthHack;
end;

function TDeclParticle.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclParticle.FreeData;
begin
  FStages := nil;
end;

function TDeclParticle.DefaultDefinition: AnsiString;
begin
  Result := '{'#10 +
    #9'{'#10 +
    #9#9'material'#9'_default'#10 +
    #9#9'count'#9'20'#10 +
    #9#9'time'#9#9'1.0'#10 +
    #9'}'#10 +
    '}';
end;

function TDeclParticle.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LParser: TParticleStageParser;
  LGenerator: IParticleGenerator;
  LIndex: Integer;
begin
  LToken := TIdToken.Create;
  LSource := OpenLexer(AText);
  try
    LParser := TParticleStageParser.Create(GetFinder);
    try
      FDepthHack := 0.0;

      while True do
      begin
        if not LSource.ReadToken(LToken) then
          Break;

        if TIdStrings.Icmp(LToken.Text, '}') = 0 then
          Break;

        if TIdStrings.Icmp(LToken.Text, '{') = 0 then
        begin
          SetLength(FStages, Length(FStages) + 1);
          FStages[High(FStages)] := LParser.ParseStage(LSource);
          Continue;
        end;

        if TIdStrings.Icmp(LToken.Text, 'depthHack') = 0 then
        begin
          FDepthHack := LSource.ParseFloat;
          Continue;
        end;

        LSource.Warning('bad token %s', [string(LToken.Text)]);
        MakeDefault;
        Exit(False);
      end;
    finally
      LParser.Free;
    end;
  finally
    LSource.Free;
  end;

  // calculate the bounds
  LGenerator := FGeneratorFactory(GetLog);
  FBounds.Clear;
  for LIndex := 0 to High(FStages) do
  begin
    LGenerator.CalculateStageBounds(FStages[LIndex]);
    FBounds.AddBounds(FStages[LIndex].Bounds);
  end;

  if FBounds.GetVolume <= 0.1 then
    FBounds := TGeoBounds.Make(TGeoVec3.Origin, TGeoVec3.Origin).Expand(8.0);

  Result := True;
end;

function TDeclParticle.RebuildTextSource: AnsiString;
begin
  Result := TParticleWriter.RebuildText(GetName, FDepthHack, FStages);
  SetText(Result);
end;

function TDeclParticle.Save: Boolean;
begin
  RebuildTextSource;
  ReplaceSourceFileText;
  Result := True;
end;

end.
