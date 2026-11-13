{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclArticulatedFigure, the               }
{  "articulatedFigure" declaration                                             }
{                                                                              }
{  Port of the articulated figures of Doom 3 (id Software, GPL v3):            }
{  framework\DeclAF.h, DeclAF.cpp (idDeclAF). Copyright (C) 1999-2011 id       }
{  Software LLC, a ZeniMax Media company. Based on the Doom 3 GPL Source Code  }
{  (id Software).                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base, DelphiDoom.Decl.ArticulatedFigure.Types,
  DelphiDoom.Decl.ArticulatedFigure.Intf;

type
  /// <summary>
  ///   <c>articulatedFigure name { settings { } body "b" { } hinge "h" { } ... }</c>: a ragdoll for the physics of the game.
  ///   Like the original, a body or a constraint that fails to parse stays in the list with what was read and the parse
  ///   says false; the declaration is <b>not</b> made default (the manager ignores the result of <c>Parse</c> and
  ///   <c>idDeclAF::Parse</c> never calls <c>MakeDefault</c>), so a figure with an error keeps what was read before it.
  ///   Two bodies or two constraints with the same name, or a constraint without a body, are only warnings. The body of the joint <c>origin</c> is moved to the first place.
  ///   The declaration does not build collision models: it keeps the kind and the sizes of the shape of each body.
  /// </summary>
  TDeclArticulatedFigure = class(TDecl, IDeclArticulatedFigure, IDeclArticulatedFigureEditor)
  strict private
    FSettings: TAfSettings;
    FBodies: TArray<TAfBody>;
    FConstraints: TArray<TAfConstraint>;
  public
    constructor Create;
    function GetSettings: TAfSettings;
    procedure SetSettings(const ASettings: TAfSettings);
    function GetNumBodies: Integer;
    function GetBody(const AIndex: Integer): TAfBody;
    procedure SetBody(const AIndex: Integer; const ABody: TAfBody);
    function GetNumConstraints: Integer;
    function GetConstraint(const AIndex: Integer): TAfConstraint;
    procedure SetConstraint(const AIndex: Integer; const AConstraint: TAfConstraint);
    procedure Finish(const AResolver: IAfJointResolver);
    procedure NewBody(const AName: AnsiString);
    procedure RenameBody(const AOldName, ANewName: AnsiString);
    procedure DeleteBody(const AName: AnsiString);
    procedure NewConstraint(const AName: AnsiString);
    procedure RenameConstraint(const AOldName, ANewName: AnsiString);
    procedure DeleteConstraint(const AName: AnsiString);
    function RebuildTextSource: AnsiString;
    function Save: Boolean;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    /// <summary>
    ///   idDeclAF::FreeData: the numbers and masks go back to their defaults and the lists are emptied; as in the original
    ///   <c>Model</c> and <c>Skin</c> keep what they had
    /// </summary>
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.ArticulatedFigure.SettingsParser, DelphiDoom.Decl.ArticulatedFigure.BodyParser,
  DelphiDoom.Decl.ArticulatedFigure.ConstraintParser, DelphiDoom.Decl.ArticulatedFigure.Writer,
  DelphiDoom.Decl.ArticulatedFigure.Finisher;

{ TDeclArticulatedFigure }

constructor TDeclArticulatedFigure.Create;
begin
  inherited Create;
  FreeData;
end;

function TDeclArticulatedFigure.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclArticulatedFigure.FreeData;
begin
  FSettings.ResetNumbers;
  FBodies := nil;
  FConstraints := nil;
end;

function TDeclArticulatedFigure.DefaultDefinition: AnsiString;
begin
  Result := '{'#10 +
    #9'settings {'#10 +
    #9#9'model ""'#10 +
    #9#9'skin ""'#10 +
    #9#9'friction 0.01, 0.01, 0.8, 0.5'#10 +
    #9#9'suspendSpeed 20, 30, 40, 60'#10 +
    #9#9'noMoveTime 1'#10 +
    #9#9'noMoveTranslation 10'#10 +
    #9#9'noMoveRotation 10'#10 +
    #9#9'minMoveTime -1'#10 +
    #9#9'maxMoveTime -1'#10 +
    #9#9'totalMass -1'#10 +
    #9#9'contents corpse'#10 +
    #9#9'clipMask solid, corpse'#10 +
    #9#9'selfCollision 1'#10 +
    #9'}'#10 +
    #9'body "body" {'#10 +
    #9#9'joint "origin"'#10 +
    #9#9'mod orientation'#10 +
    #9#9'model box( ( -10, -10, -10 ), ( 10, 10, 10 ) )'#10 +
    #9#9'origin ( 0, 0, 0 )'#10 +
    #9#9'density 0.2'#10 +
    #9#9'friction 0.01, 0.01, 0.8'#10 +
    #9#9'contents corpse'#10 +
    #9#9'clipMask solid, corpse'#10 +
    #9#9'selfCollision 1'#10 +
    #9#9'containedJoints "*origin"'#10 +
    #9'}'#10 +
    '}'#10;
end;

function TDeclArticulatedFigure.GetSettings: TAfSettings;
begin
  Result := FSettings;
end;

procedure TDeclArticulatedFigure.SetSettings(const ASettings: TAfSettings);
begin
  FSettings := ASettings;
end;

function TDeclArticulatedFigure.GetNumBodies: Integer;
begin
  Result := Length(FBodies);
end;

function TDeclArticulatedFigure.GetBody(const AIndex: Integer): TAfBody;
begin
  if (AIndex < 0) or (AIndex >= Length(FBodies)) then
    raise EDeclArticulatedFigureException.CreateFmt('body %d out of range', [AIndex]);
  Result := FBodies[AIndex];
end;

procedure TDeclArticulatedFigure.SetBody(const AIndex: Integer; const ABody: TAfBody);
begin
  if (AIndex < 0) or (AIndex >= Length(FBodies)) then
    raise EDeclArticulatedFigureException.CreateFmt('body %d out of range', [AIndex]);
  FBodies[AIndex] := ABody;
end;

function TDeclArticulatedFigure.GetNumConstraints: Integer;
begin
  Result := Length(FConstraints);
end;

function TDeclArticulatedFigure.GetConstraint(const AIndex: Integer): TAfConstraint;
begin
  if (AIndex < 0) or (AIndex >= Length(FConstraints)) then
    raise EDeclArticulatedFigureException.CreateFmt('constraint %d out of range', [AIndex]);
  Result := FConstraints[AIndex];
end;

procedure TDeclArticulatedFigure.SetConstraint(const AIndex: Integer; const AConstraint: TAfConstraint);
begin
  if (AIndex < 0) or (AIndex >= Length(FConstraints)) then
    raise EDeclArticulatedFigureException.CreateFmt('constraint %d out of range', [AIndex]);
  FConstraints[AIndex] := AConstraint;
end;

procedure TDeclArticulatedFigure.Finish(const AResolver: IAfJointResolver);
begin
  TAfFinisher.Finish(GetName, FBodies, FConstraints, AResolver, GetLog);
end;

procedure TDeclArticulatedFigure.NewBody(const AName: AnsiString);
var
  LBody: TAfBody;
begin
  LBody.SetDefault(FSettings);
  LBody.Name := AName;
  SetLength(FBodies, Length(FBodies) + 1);
  FBodies[High(FBodies)] := LBody;
end;

procedure TDeclArticulatedFigure.RenameBody(const AOldName, ANewName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FBodies) do
    if TIdStrings.Icmp(FBodies[LIndex].Name, AOldName) = 0 then
    begin
      FBodies[LIndex].Name := ANewName;
      Break;
    end;
  for LIndex := 0 to High(FConstraints) do
    if TIdStrings.Icmp(FConstraints[LIndex].Body1, AOldName) = 0 then
      FConstraints[LIndex].Body1 := ANewName
    else if TIdStrings.Icmp(FConstraints[LIndex].Body2, AOldName) = 0 then
      FConstraints[LIndex].Body2 := ANewName;
end;

procedure TDeclArticulatedFigure.DeleteBody(const AName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FBodies) do
    if TIdStrings.Icmp(FBodies[LIndex].Name, AName) = 0 then
    begin
      Delete(FBodies, LIndex, 1);
      Break;
    end;
  LIndex := 0;
  while LIndex < Length(FConstraints) do
    if (TIdStrings.Icmp(FConstraints[LIndex].Body1, AName) = 0) or
      (TIdStrings.Icmp(FConstraints[LIndex].Body2, AName) = 0) then
      Delete(FConstraints, LIndex, 1)
    else
      Inc(LIndex);
end;

procedure TDeclArticulatedFigure.NewConstraint(const AName: AnsiString);
var
  LConstraint: TAfConstraint;
begin
  LConstraint.SetDefault(FSettings, FBodies);
  LConstraint.Name := AName;
  SetLength(FConstraints, Length(FConstraints) + 1);
  FConstraints[High(FConstraints)] := LConstraint;
end;

procedure TDeclArticulatedFigure.RenameConstraint(const AOldName, ANewName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FConstraints) do
    if TIdStrings.Icmp(FConstraints[LIndex].Name, AOldName) = 0 then
    begin
      FConstraints[LIndex].Name := ANewName;
      Exit;
    end;
end;

procedure TDeclArticulatedFigure.DeleteConstraint(const AName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FConstraints) do
    if TIdStrings.Icmp(FConstraints[LIndex].Name, AName) = 0 then
    begin
      Delete(FConstraints, LIndex, 1);
      Exit;
    end;
end;

function TDeclArticulatedFigure.RebuildTextSource: AnsiString;
begin
  if TAfWriter.RebuildText(GetName, FSettings, FBodies, FConstraints, Result) then
    SetText(Result)
  else
    Result := '';
end;

function TDeclArticulatedFigure.Save: Boolean;
begin
  // the result of the two calls is not looked at in the original
  RebuildTextSource;
  ReplaceSourceFileText;
  FSettings.Modified := False;
  Result := True;
end;


function TDeclArticulatedFigure.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LConstraint: TAfConstraint;
  LKind: TAfConstraintType;
  LIndex, LOther: Integer;
  LSwap: TAfBody;

  function Keyword(const AName: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AName) = 0;
  end;

  function ParseBody: Boolean;
  var
    LBody: TAfBody;
  begin
    LBody.SetDefault(FSettings);
    Result := TAfBodyParser.Parse(LSource, LBody);
    // the body is in the list before it is read in the original: a failed one stays
    SetLength(FBodies, Length(FBodies) + 1);
    FBodies[High(FBodies)] := LBody;
  end;

  function ParseConstraint: Boolean;
  begin
    LConstraint.SetDefault(FSettings, FBodies);
    Result := TAfConstraintParser.Parse(LSource, LConstraint, LKind);
    SetLength(FConstraints, Length(FConstraints) + 1);
    FConstraints[High(FConstraints)] := LConstraint;
  end;

begin
  LToken := TIdToken.Create;
  LSource := OpenLexer(AText);
  try
    while LSource.ReadToken(LToken) do
    begin
      if Keyword('settings') then
      begin
        if not TAfSettingsParser.Parse(LSource, FSettings) then
          Exit(False);
      end
      else if Keyword('body') then
      begin
        if not ParseBody then
          Exit(False);
      end
      else if Keyword('fixed') or Keyword('ballAndSocketJoint') or Keyword('universalJoint') or Keyword('hinge') or
        Keyword('slider') or Keyword('spring') then
      begin
        if Keyword('fixed') then
          LKind := actFixed
        else if Keyword('ballAndSocketJoint') then
          LKind := actBallAndSocketJoint
        else if Keyword('universalJoint') then
          LKind := actUniversalJoint
        else if Keyword('hinge') then
          LKind := actHinge
        else if Keyword('slider') then
          LKind := actSlider
        else
          LKind := actSpring;
        if not ParseConstraint then
          Exit(False);
      end
      else if LToken.IsText('}') then
        Break
      else
      begin
        LSource.Error('unknown keyword %s', [string(LToken.Text)]);
        Exit(False);
      end;
    end;

    for LIndex := 0 to High(FBodies) do
      // check for multiple bodies with the same name
      for LOther := LIndex + 1 to High(FBodies) do
        if FBodies[LIndex].Name = FBodies[LOther].Name then
          LSource.Error('two bodies with the same name "%s"', [string(FBodies[LIndex].Name)]);

    for LIndex := 0 to High(FConstraints) do
    begin
      // check for multiple constraints with the same name
      for LOther := LIndex + 1 to High(FConstraints) do
        if FConstraints[LIndex].Name = FConstraints[LOther].Name then
          LSource.Error('two constraints with the same name "%s"', [string(FConstraints[LIndex].Name)]);
      // check if there are two valid bodies set
      if FConstraints[LIndex].Body1 = '' then
        LSource.Error('no valid body1 specified for constraint ''%s''', [string(FConstraints[LIndex].Name)]);
      if FConstraints[LIndex].Body2 = '' then
        LSource.Error('no valid body2 specified for constraint ''%s''', [string(FConstraints[LIndex].Name)]);
    end;
  finally
    LSource.Free;
  end;

  // make sure the body which modifies the origin comes first
  for LIndex := 0 to High(FBodies) do
    if FBodies[LIndex].JointName = 'origin' then
    begin
      if LIndex <> 0 then
      begin
        LSwap := FBodies[0];
        FBodies[0] := FBodies[LIndex];
        FBodies[LIndex] := LSwap;
      end;
      Break;
    end;

  Result := True;
end;

end.
