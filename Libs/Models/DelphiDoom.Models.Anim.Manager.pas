{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the cache of the md5anims (idAnimManager)   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.cpp       }
{  (idAnimManager, idMD5Anim::CheckModelHierarchy). Copyright (C) 1999-2011    }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Manager;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>
  ///   The md5anims by file name, loaded on the first request, and the pool of joint names.
  ///   Replaces the global <c>animationLib</c>: whoever needs it receives the interface. A
  ///   failed load is remembered (the entry is empty): the next request answers nil without a
  ///   new warning, as the original does. Only names that end with ".md5anim" are loaded.
  /// </summary>
  TAnimManager = class(TInterfacedObject, IAnimManager)
  strict private
    type
      TEntry = class
        Anim: IMd5Anim;
        Refs: Integer;
      end;
  strict private
    FSource: IModelFileSource;
    FParser: IMd5AnimParser;
    FLog: IIdLibLog;
    FAnims: TObjectDictionary<string, TEntry>;
    FJointNames: TList<AnsiString>;
    FJointIndexes: TDictionary<AnsiString, Integer>;
    function Load(const AName: AnsiString): IMd5Anim;
    function FindEntry(const AAnim: IMd5Anim): TEntry;
    procedure Warn(const AText: string);
  public
    /// <summary>The log is optional (nil is silent)</summary>
    constructor Create(const ASource: IModelFileSource; const AParser: IMd5AnimParser; const ALog: IIdLibLog);
    destructor Destroy; override;
    function GetAnim(const AName: AnsiString): IMd5Anim;
    procedure ReloadAnims;
    function JointIndex(const AName: AnsiString): Integer;
    function JointName(const AIndex: Integer): AnsiString;
    function NumJointNames: Integer;
    function NumRefs(const AAnim: IMd5Anim): Integer;
    procedure IncreaseRefs(const AAnim: IMd5Anim);
    procedure DecreaseRefs(const AAnim: IMd5Anim);
    function FlushUnusedAnims: Boolean;
    function NumAnims: Integer;
    procedure Shutdown;
    procedure CheckModelHierarchy(const AAnim: IMd5Anim; const AModel: IMd5Model);
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Anim.Types;

const
  MD5_ANIM_EXT = 'md5anim';

function ExtractExtension(const AName: AnsiString): AnsiString;
var
  LDot: Integer;
begin
  // idStr::ExtractFileExtension: what follows the last dot, case sensitive in the comparison
  LDot := LastDelimiter('.', string(AName));
  if LDot = 0 then
    Result := ''
  else
    Result := Copy(AName, LDot + 1, MaxInt);
end;

{ TAnimManager }

constructor TAnimManager.Create(const ASource: IModelFileSource; const AParser: IMd5AnimParser;
  const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FParser := AParser;
  FLog := ALog;
  FAnims := TObjectDictionary<string, TEntry>.Create([doOwnsValues]);
  FJointNames := TList<AnsiString>.Create;
  FJointIndexes := TDictionary<AnsiString, Integer>.Create;
end;

destructor TAnimManager.Destroy;
begin
  FJointIndexes.Free;
  FJointNames.Free;
  FAnims.Free;
  inherited Destroy;
end;

procedure TAnimManager.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TAnimManager.Load(const AName: AnsiString): IMd5Anim;
var
  LData: AnsiString;
  LTimeStamp: Int64;
begin
  Result := nil;
  if not FSource.ReadFile(AName, LData, LTimeStamp) then
    Exit;
  try
    Result := FParser.Parse(LData, AName);
  except
    on E: EIdLibException do
      Result := nil;
    on E: EModelsException do
      Result := nil;
  end;
end;

function TAnimManager.GetAnim(const AName: AnsiString): IMd5Anim;
var
  LEntry: TEntry;
begin
  if FAnims.TryGetValue(string(AName), LEntry) then
    Exit(LEntry.Anim);
  if ExtractExtension(AName) <> MD5_ANIM_EXT then
    Exit(nil);
  Result := Load(AName);
  if Result = nil then
    Warn(Format('Couldn''t load anim: ''%s''', [string(AName)]));
  LEntry := TEntry.Create;
  LEntry.Anim := Result;
  FAnims.Add(string(AName), LEntry);
end;

procedure TAnimManager.ReloadAnims;
var
  LName: string;
  LEntry: TEntry;
  LNew: IMd5Anim;
begin
  for LName in FAnims.Keys.ToArray do
  begin
    LEntry := FAnims[LName];
    if LEntry.Anim = nil then
      Continue;
    LNew := Load(AnsiString(LName));
    if LNew <> nil then
      LEntry.Anim := LNew;
  end;
end;

function TAnimManager.JointIndex(const AName: AnsiString): Integer;
begin
  if FJointIndexes.TryGetValue(AName, Result) then
    Exit;
  Result := FJointNames.Add(AName);
  FJointIndexes.Add(AName, Result);
end;

function TAnimManager.JointName(const AIndex: Integer): AnsiString;
begin
  if (AIndex < 0) or (AIndex >= FJointNames.Count) then
    raise EAnimException.CreateFmt(SAnimJointHandle, [AIndex, FJointNames.Count]);
  Result := FJointNames[AIndex];
end;

function TAnimManager.NumJointNames: Integer;
begin
  Result := FJointNames.Count;
end;

function TAnimManager.FindEntry(const AAnim: IMd5Anim): TEntry;
begin
  if (AAnim = nil) or not FAnims.TryGetValue(string(AAnim.Name), Result) then
    Result := nil;
end;

function TAnimManager.NumRefs(const AAnim: IMd5Anim): Integer;
var
  LEntry: TEntry;
begin
  LEntry := FindEntry(AAnim);
  if Assigned(LEntry) then
    Result := LEntry.Refs
  else
    Result := 0;
end;

procedure TAnimManager.IncreaseRefs(const AAnim: IMd5Anim);
var
  LEntry: TEntry;
begin
  LEntry := FindEntry(AAnim);
  if Assigned(LEntry) then
    Inc(LEntry.Refs);
end;

procedure TAnimManager.DecreaseRefs(const AAnim: IMd5Anim);
var
  LEntry: TEntry;
begin
  LEntry := FindEntry(AAnim);
  if Assigned(LEntry) then
    Dec(LEntry.Refs);
end;

function TAnimManager.FlushUnusedAnims: Boolean;
var
  LName: string;
  LRemove: TArray<string>;
begin
  LRemove := nil;
  for LName in FAnims.Keys do
    if Assigned(FAnims[LName].Anim) and (FAnims[LName].Refs <= 0) then
      LRemove := LRemove + [LName];
  for LName in LRemove do
    FAnims.Remove(LName);
  Result := Length(LRemove) > 0;
end;

function TAnimManager.NumAnims: Integer;
var
  LEntry: TEntry;
begin
  Result := 0;
  for LEntry in FAnims.Values do
    if Assigned(LEntry.Anim) then
      Inc(Result);
end;

procedure TAnimManager.Shutdown;
begin
  FAnims.Clear;
  FJointNames.Clear;
  FJointIndexes.Clear;
end;

procedure TAnimManager.CheckModelHierarchy(const AAnim: IMd5Anim; const AModel: IMd5Model);
var
  LJoint: Integer;
begin
  if AAnim.NumJoints <> AModel.NumJoints then
    raise EAnimException.CreateFmt(SAnimModelJointCount, [string(AModel.Name), string(AAnim.Name)]);
  for LJoint := 0 to AAnim.NumJoints - 1 do
  begin
    if AModel.Joints[LJoint].Name <> AAnim.JointInfo[LJoint].Name then
      raise EAnimException.CreateFmt(SAnimModelJointNames, [string(AModel.Name), string(AAnim.Name)]);
    if AModel.Joints[LJoint].Parent <> AAnim.JointInfo[LJoint].ParentNum then
      raise EAnimException.CreateFmt(SAnimModelHierarchy, [string(AModel.Name), string(AAnim.Name)]);
  end;
end;

end.
