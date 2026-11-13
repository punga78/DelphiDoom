{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - an animation of a definition (idAnim)       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  (idAnim). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Anim;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>
  ///   idAnim. The md5anims are counted in the manager: the animation counts them when it takes
  ///   them and gives them back when it is freed or set again.
  /// </summary>
  TAnim = class(TInterfacedObject, IAnim)
  strict private
    FManager: IAnimManager;
    FName: AnsiString;
    FFullName: AnsiString;
    FAnims: TArray<IMd5Anim>;
    FFlags: TAnimFlags;
    FFrameLookup: TArray<TAnimFrameLookup>;
    FFrameCommands: TArray<TAnimFrameCommand>;
    procedure ReleaseAnims;
  public
    /// <summary>
    ///   A new animation that plays the md5anims given (1 to ANIM_MAX_SYNCED_ANIMS: SetAnim);
    ///   AFullName is the name written in the definition, AName the one without the number
    /// </summary>
    constructor Create(const AManager: IAnimManager; const AFullName, AName: AnsiString;
      const AAnims: TArray<IMd5Anim>);
    destructor Destroy; override;
    function GetName: AnsiString;
    function GetFullName: AnsiString;
    function GetNumAnims: Integer;
    function GetFlags: TAnimFlags;
    procedure SetFlags(const AValue: TAnimFlags);
    function GetFrameCommandCount: Integer;
    function GetMd5Anim(const ANumber: Integer): IMd5Anim;
    function Length: Integer;
    function NumFrames: Integer;
    function TotalMovementDelta: TIdVec3;
    function GetOrigin(const AAnimNumber, ATime, ACycleCount: Integer; out AOffset: TIdVec3): Boolean;
    function GetOriginRotation(const AAnimNumber, ATime, ACycleCount: Integer; out ARotation: TIdQuat): Boolean;
    function GetBounds(const AAnimNumber, ATime, ACycleCount: Integer; out ABounds: TGeoBounds): Boolean;
    procedure AddFrameCommand(const AFrame: Integer; const ACommand: TAnimFrameCommand);
    function GetFrameCommands(const AFrame: Integer): TArray<TAnimFrameCommand>;
    function HasFrameCommands: Boolean;
    function FindFrameForFrameCommand(const AType: TAnimFrameCommandType;
      out ACommand: TAnimFrameCommand): Integer;
    function Clone: IAnim;
  end;

implementation

uses
  DelphiDoom.Models.Types;

{ TAnim }

constructor TAnim.Create(const AManager: IAnimManager; const AFullName, AName: AnsiString;
  const AAnims: TArray<IMd5Anim>);
var
  LAnim: IMd5Anim;
begin
  inherited Create;
  FManager := AManager;
  FFullName := AFullName;
  FName := AName;
  FAnims := Copy(AAnims);
  for LAnim in FAnims do
    FManager.IncreaseRefs(LAnim);
end;

procedure TAnim.ReleaseAnims;
var
  LAnim: IMd5Anim;
begin
  for LAnim in FAnims do
    FManager.DecreaseRefs(LAnim);
  FAnims := nil;
end;

destructor TAnim.Destroy;
begin
  ReleaseAnims;
  inherited Destroy;
end;

function TAnim.GetName: AnsiString;
begin
  Result := FName;
end;

function TAnim.GetFullName: AnsiString;
begin
  Result := FFullName;
end;

function TAnim.GetNumAnims: Integer;
begin
  Result := System.Length(FAnims);
end;

function TAnim.GetFlags: TAnimFlags;
begin
  Result := FFlags;
end;

procedure TAnim.SetFlags(const AValue: TAnimFlags);
begin
  FFlags := AValue;
end;

function TAnim.GetFrameCommandCount: Integer;
begin
  Result := System.Length(FFrameCommands);
end;

function TAnim.GetMd5Anim(const ANumber: Integer): IMd5Anim;
begin
  if (ANumber < 0) or (ANumber >= System.Length(FAnims)) then
    Result := nil
  else
    Result := FAnims[ANumber];
end;

function TAnim.Length: Integer;
begin
  if System.Length(FAnims) = 0 then
    Result := 0
  else
    Result := FAnims[0].Length;
end;

function TAnim.NumFrames: Integer;
begin
  if System.Length(FAnims) = 0 then
    Result := 0
  else
    Result := FAnims[0].NumFrames;
end;

function TAnim.TotalMovementDelta: TIdVec3;
begin
  if System.Length(FAnims) = 0 then
    Result.Zero
  else
    Result := FAnims[0].TotalMovementDelta;
end;

function TAnim.GetOrigin(const AAnimNumber, ATime, ACycleCount: Integer; out AOffset: TIdVec3): Boolean;
begin
  Result := GetMd5Anim(AAnimNumber) <> nil;
  if Result then
    AOffset := FAnims[AAnimNumber].GetOrigin(ATime, ACycleCount)
  else
    AOffset.Zero;
end;

function TAnim.GetOriginRotation(const AAnimNumber, ATime, ACycleCount: Integer; out ARotation: TIdQuat): Boolean;
begin
  Result := GetMd5Anim(AAnimNumber) <> nil;
  if Result then
    ARotation := FAnims[AAnimNumber].GetOriginRotation(ATime, ACycleCount)
  else
    ARotation.SetValues(0, 0, 0, 1);
end;

function TAnim.GetBounds(const AAnimNumber, ATime, ACycleCount: Integer; out ABounds: TGeoBounds): Boolean;
begin
  Result := GetMd5Anim(AAnimNumber) <> nil;
  if Result then
    ABounds := FAnims[AAnimNumber].GetBounds(ATime, ACycleCount);
end;

procedure TAnim.AddFrameCommand(const AFrame: Integer; const ACommand: TAnimFrameCommand);
var
  LIndex, LFrame: Integer;
begin
  if (AFrame < 0) or (AFrame >= NumFrames) then
    raise EModelsException.CreateFmt(SAnimFrameRange, [AFrame + 1]);
  // check if we've initialized the frame lookup table
  if System.Length(FFrameLookup) = 0 then
    SetLength(FFrameLookup, NumFrames);
  // allocate space for a new command and move the later ones up
  SetLength(FFrameCommands, System.Length(FFrameCommands) + 1);
  LIndex := FFrameLookup[AFrame].FirstCommand + FFrameLookup[AFrame].Num;
  for LFrame := High(FFrameCommands) downto LIndex + 1 do
    FFrameCommands[LFrame] := FFrameCommands[LFrame - 1];
  for LFrame := AFrame + 1 to High(FFrameLookup) do
    Inc(FFrameLookup[LFrame].FirstCommand);
  FFrameCommands[LIndex] := ACommand;
  Inc(FFrameLookup[AFrame].Num);
end;

function TAnim.GetFrameCommands(const AFrame: Integer): TArray<TAnimFrameCommand>;
var
  LIndex: Integer;
begin
  Result := nil;
  if (AFrame < 0) or (AFrame >= System.Length(FFrameLookup)) then
    Exit;
  SetLength(Result, FFrameLookup[AFrame].Num);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := FFrameCommands[FFrameLookup[AFrame].FirstCommand + LIndex];
end;

function TAnim.HasFrameCommands: Boolean;
begin
  Result := System.Length(FFrameCommands) > 0;
end;

function TAnim.FindFrameForFrameCommand(const AType: TAnimFrameCommandType;
  out ACommand: TAnimFrameCommand): Integer;
var
  LFrame, LIndex, LEnd: Integer;
begin
  ACommand := Default(TAnimFrameCommand);
  Result := -1;
  if System.Length(FFrameCommands) = 0 then
    Exit;
  for LFrame := 0 to NumFrames - 1 do
  begin
    LEnd := FFrameLookup[LFrame].FirstCommand + FFrameLookup[LFrame].Num;
    for LIndex := FFrameLookup[LFrame].FirstCommand to LEnd - 1 do
      if FFrameCommands[LIndex].CommandType = AType then
      begin
        ACommand := FFrameCommands[LIndex];
        Exit(LFrame);
      end;
  end;
end;

function TAnim.Clone: IAnim;
var
  LCopy: TAnim;
begin
  LCopy := TAnim.Create(FManager, FFullName, FName, FAnims);
  LCopy.FFlags := FFlags;
  LCopy.FFrameLookup := Copy(FFrameLookup);
  LCopy.FFrameCommands := Copy(FFrameCommands);
  Result := LCopy;
end;

end.
