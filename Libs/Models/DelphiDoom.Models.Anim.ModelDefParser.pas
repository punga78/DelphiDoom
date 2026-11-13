{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the MODELDEF parser (idDeclModelDef::Parse) }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  (idDeclModelDef::Parse and ParseAnim). Copyright (C) 1999-2011 id Software  }
{  LLC, a ZeniMax Media company. This unit is derived from the Doom 3 GPL      }
{  source code and is therefore available under the GNU General Public         }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.ModelDefParser;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.ModelDef;

type
  /// <summary>
  ///   Reads the body of a <c>model</c> declaration: <c>inherit</c>, <c>skin</c>, <c>mesh</c>,
  ///   <c>remove</c>, <c>anim</c> (with its flags and frame commands), <c>offset</c> and
  ///   <c>channel</c>. The models, the definitions to inherit from and the md5anims come from
  ///   the services it receives; the game objects of the frame commands from the lookup.
  /// </summary>
  TModelDefParser = class(TInterfacedObject, IModelDefParser)
  strict private
    FSource: IModelDefSource;
    FAnims: IAnimManager;
    FLookup: IModelDefGameLookup;
    FLog: IIdLibLog;
    function ParseAnim(const ALexer: TIdLexer; const ADef: TModelDef; const ANumDefaultAnims: Integer): Boolean;
    function ParseFrameCommands(const ALexer: TIdLexer; const ADef: TModelDef; const AAnim: IAnim): Boolean;
    function ParseChannel(const ALexer: TIdLexer; const ADef: TModelDef): Boolean;
    function ParseMesh(const ALexer: TIdLexer; const ADef: TModelDef; const AFileName: AnsiString): Boolean;
    function ParseRemove(const ALexer: TIdLexer; const ADef: TModelDef; var ANumDefaultAnims: Integer): Boolean;
    procedure Warn(const AText: string);
  public
    /// <summary>The log is optional (nil is silent)</summary>
    constructor Create(const ASource: IModelDefSource; const AAnims: IAnimManager;
      const ALookup: IModelDefGameLookup; const ALog: IIdLibLog);
    function Parse(const AName, AText: AnsiString): IModelDef;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Text.Token,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Anim,
  DelphiDoom.Models.Anim.FrameCommandParser;

const
  MD5_MESH_EXT = 'md5mesh';

function ExtractExtension(const AName: AnsiString): AnsiString;
var
  LDot: Integer;
begin
  LDot := LastDelimiter('.', string(AName));
  if LDot = 0 then
    Result := ''
  else
    Result := Copy(AName, LDot + 1, MaxInt);
end;

{ TModelDefParser }

constructor TModelDefParser.Create(const ASource: IModelDefSource; const AAnims: IAnimManager;
  const ALookup: IModelDefGameLookup; const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FAnims := AAnims;
  FLookup := ALookup;
  FLog := ALog;
end;

procedure TModelDefParser.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TModelDefParser.ParseMesh(const ALexer: TIdLexer; const ADef: TModelDef;
  const AFileName: AnsiString): Boolean;
var
  LModel: IMd5Model;
  LDefaulted: Boolean;
begin
  Result := False;
  if ExtractExtension(AFileName) <> MD5_MESH_EXT then
  begin
    ALexer.Warning('Invalid model for MD5 mesh', []);
    Exit;
  end;
  LModel := FSource.FindMd5Model(AFileName, LDefaulted);
  // the manager gives the default model for a file it cannot load: that is a defaulted model, not a missing one
  if LDefaulted then
  begin
    ALexer.Warning('Model ''%s'' defaulted', [string(AFileName)]);
    Exit;
  end;
  if LModel = nil then
  begin
    ALexer.Warning('Model ''%s'' not found', [string(AFileName)]);
    Exit;
  end;
  if LModel.NumJoints = 0 then
    ALexer.Warning('Model ''%s'' has no joints', [string(AFileName)]);
  ADef.SetModel(LModel);
  Result := True;
end;

function TModelDefParser.ParseRemove(const ALexer: TIdLexer; const ADef: TModelDef;
  var ANumDefaultAnims: Integer): Boolean;
var
  LToken: TIdToken;
  LIndex, LCount: Integer;
begin
  Result := False;
  LToken := TIdToken.Create;
  if not ALexer.ReadToken(LToken) then
  begin
    ALexer.Warning('Unexpected end of file', []);
    Exit;
  end;
  LCount := 0;
  LIndex := 0;
  while LIndex < ADef.AnimCount do
  begin
    if (LToken.Text = ADef.GetAnimAt(LIndex).Name) or (LToken.Text = ADef.GetAnimAt(LIndex).FullName) then
    begin
      ADef.RemoveAnimAt(LIndex);
      if LIndex >= ANumDefaultAnims then
      begin
        ALexer.Warning('Anim ''%s'' was not inherited.  Anim should be removed from the model def.',
          [string(LToken.Text)]);
        Exit;
      end;
      Dec(ANumDefaultAnims);
      Inc(LCount);
      Continue;
    end;
    Inc(LIndex);
  end;
  if LCount = 0 then
  begin
    ALexer.Warning('Couldn''t find anim ''%s'' to remove', [string(LToken.Text)]);
    Exit;
  end;
  Result := True;
end;

function TModelDefParser.ParseChannel(const ALexer: TIdLexer; const ADef: TModelDef): Boolean;
var
  LName, LToken: TIdToken;
  LChannel, LIndex, LCount: Integer;
  LJointNames: AnsiString;
  LList, LKept: TArray<Integer>;
begin
  Result := False;
  if not Assigned(ADef.Model) then
  begin
    ALexer.Warning('Must specify mesh before defining channels', []);
    Exit;
  end;
  LName := TIdToken.Create;
  LToken := TIdToken.Create;
  // set the channel for a group of joints
  if not ALexer.ReadToken(LName) then
  begin
    ALexer.Warning('Unexpected end of file', []);
    Exit;
  end;
  if not ALexer.CheckTokenString('(') then
  begin
    ALexer.Warning('Expected { after ''%s''' + #10, [string(LName.Text)]);
    Exit;
  end;
  LChannel := ANIMCHANNEL_ALL + 1;
  while (LChannel < ANIM_NUM_ANIM_CHANNELS) and not SameText(ANIM_CHANNEL_NAMES[LChannel], string(LName.Text)) do
    Inc(LChannel);
  if LChannel >= ANIM_NUM_ANIM_CHANNELS then
  begin
    ALexer.Warning('Unknown channel ''%s''', [string(LName.Text)]);
    Exit;
  end;
  LJointNames := '';
  while not ALexer.CheckTokenString(')') do
  begin
    if not ALexer.ReadToken(LToken) then
    begin
      ALexer.Warning('Unexpected end of file', []);
      Exit;
    end;
    LJointNames := LJointNames + LToken.Text;
    if (LToken.Text <> '*') and (LToken.Text <> '-') then
      LJointNames := LJointNames + ' ';
  end;
  LList := ADef.GetJointList(LJointNames, FLog);
  LKept := nil;
  LCount := 0;
  SetLength(LKept, Length(LList));
  for LIndex := 0 to High(LList) do
  begin
    if ADef.JointInfo[LList[LIndex]].Channel <> ANIMCHANNEL_ALL then
    begin
      ALexer.Warning('Joint ''%s'' assigned to multiple channels', [string(ADef.GetJointName(LList[LIndex]))]);
      Continue;
    end;
    ADef.SetJointChannel(LList[LIndex], LChannel);
    LKept[LCount] := LList[LIndex];
    Inc(LCount);
  end;
  SetLength(LKept, LCount);
  ADef.SetChannelJoints(LChannel, LKept);
  Result := True;
end;

function TModelDefParser.ParseFrameCommands(const ALexer: TIdLexer; const ADef: TModelDef;
  const AAnim: IAnim): Boolean;
var
  LToken: TIdToken;
  LFlags: TAnimFlags;
  LFrame: Integer;
  LCommand: TAnimFrameCommand;
  LError: string;
  LCommandParser: TAnimFrameCommandParser;
begin
  Result := False;
  LToken := TIdToken.Create;
  LFlags := Default(TAnimFlags);
  LCommandParser := TAnimFrameCommandParser.Create(FLookup, FLog);
  try
    while True do
    begin
      if not ALexer.ReadToken(LToken) then
      begin
        ALexer.Warning('Unexpected end of file', []);
        Exit;
      end;
      if LToken.IsText('}') then
        Break
      else if LToken.IsText('prevent_idle_override') then
        LFlags.PreventIdleOverride := True
      else if LToken.IsText('random_cycle_start') then
        LFlags.RandomCycleStart := True
      else if LToken.IsText('ai_no_turn') then
        LFlags.AiNoTurn := True
      else if LToken.IsText('anim_turn') then
        LFlags.AnimTurn := True
      else if LToken.IsText('frame') then
      begin
        // make sure we don't have any line breaks while reading the frame command
        if not ALexer.ReadTokenOnLine(LToken) then
        begin
          ALexer.Warning('Missing frame # after ''frame''', []);
          Exit;
        end;
        if (LToken.TokenType = TT_PUNCTUATION) and LToken.IsText('-') then
        begin
          ALexer.Warning('Invalid frame # after ''frame''', []);
          Exit;
        end
        else if (LToken.TokenType <> TT_NUMBER) or ((LToken.SubType and TT_FLOAT) <> 0) then
          ALexer.Error('expected integer value, found ''%s''', [string(LToken.Text)]);
        LFrame := LToken.GetIntValue;
        // frame numbers are 1 based in .def files, but 0 based internally
        if (LFrame < 1) or (LFrame > AAnim.NumFrames) then
          LError := Format(SAnimFrameRange, [LFrame])
        else
          LError := LCommandParser.Parse(ALexer, ADef, LCommand);
        if LError = '' then
          AAnim.AddFrameCommand(LFrame - 1, LCommand)
        else
        begin
          Warn(LError);
          Exit;
        end;
      end
      else
      begin
        ALexer.Warning('Unknown command ''%s''', [string(LToken.Text)]);
        Exit;
      end;
    end;
  finally
    LCommandParser.Free;
  end;
  AAnim.Flags := LFlags;
  Result := True;
end;

function TModelDefParser.ParseAnim(const ALexer: TIdLexer; const ADef: TModelDef;
  const ANumDefaultAnims: Integer): Boolean;
var
  LRealName, LToken: TIdToken;
  LAlias: AnsiString;
  LIndex, LLength: Integer;
  LMd5Anims: TArray<IMd5Anim>;
  LMd5Anim: IMd5Anim;
  LAnim: IAnim;
begin
  Result := False;
  LRealName := TIdToken.Create;
  LToken := TIdToken.Create;
  if not ALexer.ReadToken(LRealName) then
  begin
    ALexer.Warning('Unexpected end of file', []);
    Exit;
  end;
  LAlias := LRealName.Text;
  LIndex := 0;
  while (LIndex < ADef.AnimCount) and (ADef.GetAnimAt(LIndex).FullName <> LRealName.Text) do
    Inc(LIndex);
  if (LIndex < ADef.AnimCount) and (LIndex >= ANumDefaultAnims) then
  begin
    ALexer.Warning('Duplicate anim ''%s''', [string(LRealName.Text)]);
    Exit;
  end;
  // random anims end with a number: find the numeric suffix of the animation
  LLength := Length(LAlias);
  LIndex := LLength - 1;
  while (LIndex > 0) and (LAlias[LIndex + 1] in ['0'..'9']) do
    Dec(LIndex);
  // check for zero length name, or a purely numeric name
  if LIndex <= 0 then
  begin
    ALexer.Warning('Invalid animation name ''%s''', [string(LAlias)]);
    Exit;
  end;
  // remove the numeric suffix
  LAlias := Copy(LAlias, 1, LIndex + 1);
  // parse the anims from the string
  repeat
    if not ALexer.ReadToken(LToken) then
    begin
      ALexer.Warning('Unexpected end of file', []);
      Exit;
    end;
    LMd5Anim := FAnims.GetAnim(LToken.Text);
    if LMd5Anim = nil then
    begin
      ALexer.Warning('Couldn''t load anim ''%s''', [string(LToken.Text)]);
      Exit;
    end;
    FAnims.CheckModelHierarchy(LMd5Anim, ADef.Model);
    if Length(LMd5Anims) > 0 then
      // make sure it's the same length as the other anims
      if LMd5Anim.Length <> LMd5Anims[0].Length then
      begin
        ALexer.Warning('Anim ''%s'' does not match length of anim ''%s''',
          [string(LMd5Anim.Name), string(LMd5Anims[0].Name)]);
        Exit;
      end;
    if Length(LMd5Anims) >= ANIM_MAX_SYNCED_ANIMS then
    begin
      ALexer.Warning('Exceeded max synced anims (%d)', [ANIM_MAX_SYNCED_ANIMS]);
      Exit;
    end;
    LMd5Anims := LMd5Anims + [LMd5Anim];
  until not ALexer.CheckTokenString(',');
  LAnim := TAnim.Create(FAnims, LRealName.Text, LAlias, LMd5Anims);
  // parse any frame commands or animflags
  if ALexer.CheckTokenString('{') then
    if not ParseFrameCommands(ALexer, ADef, LAnim) then
      Exit;
  // an inherited anim with the same name is replaced
  LIndex := 0;
  while (LIndex < ANumDefaultAnims) and (ADef.GetAnimAt(LIndex).FullName <> LRealName.Text) do
    Inc(LIndex);
  if LIndex < ANumDefaultAnims then
    ADef.ReplaceAnim(LIndex, LAnim)
  else
    ADef.AddAnim(LAnim);
  Result := True;
end;

function TModelDefParser.Parse(const AName, AText: AnsiString): IModelDef;
var
  LDef: TModelDef;
  LLexer: TIdLexer;
  LToken, LToken2: TIdToken;
  LNumDefaultAnims: Integer;
  LCopy: IModelDef;
  LDefaulted: Boolean;
  LOffset: array[0..2] of Single;
  LVector: TIdVec3;
  LOk: Boolean;

  function Fail: Boolean;
  begin
    LDef.MakeDefault;
    Result := False;
  end;

begin
  LDef := TModelDef.Create(AName);
  Result := LDef;
  LLexer := TIdLexer.Create(MODELDEF_LEXER_FLAGS, FLog);
  try
    LLexer.LoadMemory(AText, Length(AText), AName, 1);
    LLexer.SkipUntilString('{');
    LToken := TIdToken.Create;
    LToken2 := TIdToken.Create;
    LNumDefaultAnims := 0;
    LOk := True;
    while LOk do
    begin
      if not LLexer.ReadToken(LToken) then
        Break;
      if SameText(string(LToken.Text), '}') then
        Break;
      if LToken.IsText('inherit') then
      begin
        if not LLexer.ReadToken(LToken2) then
        begin
          LLexer.Warning('Unexpected end of file', []);
          LOk := Fail;
        end
        else
        begin
          LCopy := FSource.FindModelDef(LToken2.Text, LDefaulted);
          if LCopy = nil then
            Warn(Format('Unknown model definition ''%s''', [string(LToken2.Text)]))
          else if LDefaulted then
          begin
            Warn(Format('inherited model definition ''%s'' defaulted', [string(LToken2.Text)]));
            LOk := Fail;
          end
          else
          begin
            LDef.CopyFrom(LCopy);
            LNumDefaultAnims := LDef.AnimCount;
          end;
        end;
      end
      else if LToken.IsText('skin') then
      begin
        if not LLexer.ReadToken(LToken2) then
        begin
          LLexer.Warning('Unexpected end of file', []);
          LOk := Fail;
        end
        else if not FLookup.FindSkin(LToken2.Text) then
        begin
          LLexer.Warning('Skin ''%s'' not found', [string(LToken2.Text)]);
          LOk := Fail;
        end
        else
          LDef.SetSkinName(LToken2.Text);
      end
      else if LToken.IsText('mesh') then
      begin
        if not LLexer.ReadToken(LToken2) then
        begin
          LLexer.Warning('Unexpected end of file', []);
          LOk := Fail;
        end
        else if not ParseMesh(LLexer, LDef, LToken2.Text) then
          LOk := Fail;
      end
      else if LToken.IsText('remove') then
      begin
        if not ParseRemove(LLexer, LDef, LNumDefaultAnims) then
          LOk := Fail;
      end
      else if LToken.IsText('anim') then
      begin
        if not Assigned(LDef.Model) then
        begin
          LLexer.Warning('Must specify mesh before defining anims', []);
          LOk := Fail;
        end
        else if not ParseAnim(LLexer, LDef, LNumDefaultAnims) then
          LOk := Fail;
      end
      else if LToken.IsText('offset') then
      begin
        if not LLexer.Parse1DMatrix(3, LOffset) then
        begin
          LLexer.Warning('Expected vector following ''offset''', []);
          LOk := Fail;
        end
        else
        begin
          LVector := TIdVec3.Create(LOffset[0], LOffset[1], LOffset[2]);
          LDef.SetOffset(LVector);
        end;
      end
      else if LToken.IsText('channel') then
      begin
        if not ParseChannel(LLexer, LDef) then
          LOk := Fail;
      end
      else
      begin
        LLexer.Warning('unknown token ''%s''', [string(LToken.Text)]);
        LOk := Fail;
      end;
    end;
  finally
    LLexer.Free;
  end;
end;

end.
