{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - what the lines of all the games have            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.LineFormat.Base;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.BinaryWriter;

type
  /// <summary>
  ///   The keys of a line that are in every game: the vertexes, the special, the sides, the ids
  ///   and the flags that the game has. A flag is a key with a value: the table of the flags
  ///   has only the ones that the game has. What a game does with the id, the arguments and what
  ///   activates a line is in the format of the game
  /// </summary>
  TUdmfLineFormatBase = class(TInterfacedObject, IUdmfLineFormat)
  private
    FFlagKeys: TDictionary<string, Integer>;
    procedure AddFlag(const AKey: string; AValue: Integer);
  protected
    /// <summary>The line has this id: its first one, the others are in the moreids</summary>
    procedure ApplyId(AId: Integer; var ALine: TUdmfLine); virtual; abstract;
    procedure ApplyArgument(AIndex, AValue: Integer; var ALine: TUdmfLine); virtual; abstract;
    /// <summary>The keys that depend on the game; false if the game does not know the key</summary>
    function ApplyGameKey(const AKey: string; const AReader: IUdmfValueReader;
      var ALine: TUdmfLine): Boolean; virtual; abstract;
  public
    constructor Create(const AFlags: TUdmfLineFlags);
    destructor Destroy; override;
    procedure Reset(var ALine: TUdmfLine); virtual;
    function Apply(const AKey: string; const AReader: IUdmfValueReader;
      var ALine: TUdmfLine): Boolean;
    function GetBaseSize: Integer; virtual; abstract;
    function GetExtraSize: Integer; virtual; abstract;
    procedure WriteBase(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); virtual; abstract;
    procedure WriteExtra(const ALine: TUdmfLine; const AWriter: TUdmfBinaryWriter); virtual; abstract;
  end;

implementation

{ TUdmfLineFormatBase }

constructor TUdmfLineFormatBase.Create(const AFlags: TUdmfLineFlags);
begin
  inherited Create;
  FFlagKeys := TDictionary<string, Integer>.Create;
  AddFlag('BLOCKING', AFlags.Blocking);
  AddFlag('BLOCKEVERYTHING', AFlags.Blocking);
  AddFlag('BLOCKMONSTERS', AFlags.BlockMonsters);
  AddFlag('TWOSIDED', AFlags.TwoSided);
  AddFlag('DONTPEGTOP', AFlags.DontPegTop);
  AddFlag('DONTPEGBOTTOM', AFlags.DontPegBottom);
  AddFlag('SECRET', AFlags.Secret);
  AddFlag('BLOCKSOUND', AFlags.SoundBlock);
  AddFlag('DONTDRAW', AFlags.DontDraw);
  // the old code sets the flag of secret for mapped, too
  AddFlag('MAPPED', AFlags.Secret);
  AddFlag('TRIGGERSCRIPTS', AFlags.TriggerScripts);
  AddFlag('NOCLIPPING', AFlags.NoClip);
  AddFlag('BLOCKLANDMONSTERS', AFlags.BlockLandMonsters);
  AddFlag('BLOCKPLAYERS', AFlags.BlockPlayers);
  AddFlag('PASSUSE', AFlags.PassUse);
  AddFlag('TRANSLUCENT', AFlags.Transparent1);
  AddFlag('TRANSLUCENT2', AFlags.Transparent2);
  AddFlag('JUMPOVER', AFlags.JumpOver);
  AddFlag('BLOCKFLOATERS', AFlags.BlockFloaters);
end;

destructor TUdmfLineFormatBase.Destroy;
begin
  FFlagKeys.Free;
  inherited Destroy;
end;

procedure TUdmfLineFormatBase.AddFlag(const AKey: string; AValue: Integer);
begin
  if AValue <> 0 then
    FFlagKeys.Add(AKey, AValue);
end;

procedure TUdmfLineFormatBase.Reset(var ALine: TUdmfLine);
begin
  ALine := Default(TUdmfLine);
  ALine.SideFront := -1;
  ALine.SideBack := -1;
end;

function TUdmfLineFormatBase.Apply(const AKey: string; const AReader: IUdmfValueReader;
  var ALine: TUdmfLine): Boolean;
var
  LFlag: Integer;
  LValue: Integer;
  LIds: TArray<Integer>;
  LId: Integer;
begin
  Result := True;
  if AKey = 'ID' then
  begin
    LValue := AReader.ReadInteger;
    ApplyId(LValue, ALine);
    if (LValue >= 0) and (LValue <= 255) then
      Include(ALine.MoreIds, Byte(LValue));
  end
  else if AKey = 'MOREIDS' then
  begin
    LIds := AReader.ReadIntegerList;
    for LId in LIds do
      if (LId >= 0) and (LId <= 255) then
        Include(ALine.MoreIds, Byte(LId));
  end
  else if AKey = 'V1' then
    ALine.V1 := AReader.ReadInteger
  else if AKey = 'V2' then
    ALine.V2 := AReader.ReadInteger
  else if AKey = 'SPECIAL' then
    ALine.Special := AReader.ReadInteger
  else if FFlagKeys.TryGetValue(AKey, LFlag) then
  begin
    if AReader.ReadIsTrue then
      ALine.Flags := ALine.Flags or LFlag;
  end
  else if AKey = 'ARG0' then
    ApplyArgument(0, AReader.ReadInteger, ALine)
  else if AKey = 'ARG1' then
    ApplyArgument(1, AReader.ReadInteger, ALine)
  else if AKey = 'ARG2' then
    ApplyArgument(2, AReader.ReadInteger, ALine)
  else if AKey = 'ARG3' then
    ApplyArgument(3, AReader.ReadInteger, ALine)
  else if AKey = 'ARG4' then
    ApplyArgument(4, AReader.ReadInteger, ALine)
  else if AKey = 'SIDEFRONT' then
  begin
    LValue := AReader.ReadInteger;
    if LValue > 32768 then
      ALine.SideFront := -1
    else
      ALine.SideFront := LValue;
  end
  else if AKey = 'SIDEBACK' then
  begin
    LValue := AReader.ReadInteger;
    if LValue > 32768 then
      ALine.SideBack := -1
    else
      ALine.SideBack := LValue;
  end
  else if AKey = 'COMMENT' then
    AReader.ReadToken
  else
    Result := ApplyGameKey(AKey, AReader, ALine);
end;

end.