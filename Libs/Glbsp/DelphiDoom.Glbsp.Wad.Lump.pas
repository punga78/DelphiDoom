{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - lump of a WAD and level information                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of lump_t / level_t of glBSP 2.24 (C) 2000-2007 Andrew Apted           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Wad.Lump;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.Glbsp.Wad.Types;

type
  TGlbspLump = class;

  /// <summary>
  ///   Information on a level: the lumps that belong to it, the GL level
  ///   that goes with it and the limits it overflowed
  /// </summary>
  TGlbspLevelInfo = class
  private
    FFlags: Integer;
    FChildren: TObjectList<TGlbspLump>;
    FBuddy: TGlbspLump;
    FSoftLimit: Integer;
    FHardLimit: Integer;
    FV5Switch: Integer;
  public
    constructor Create(const AFlags: Integer);
    destructor Destroy; override;

    /// <summary>Zero or LEVEL_IS_GL</summary>
    property Flags: Integer read FFlags;
    /// <summary>Lumps of the level; the list owns them</summary>
    property Children: TObjectList<TGlbspLump> read FChildren;
    /// <summary>For a normal level, the GL marker lump (not owned)</summary>
    property Buddy: TGlbspLump read FBuddy write FBuddy;
    property SoftLimit: Integer read FSoftLimit write FSoftLimit;
    property HardLimit: Integer read FHardLimit write FHardLimit;
    property V5Switch: Integer read FV5Switch write FV5Switch;
  end;

  /// <summary>
  ///   Entry of the directory of a WAD, with its data when it is in memory
  /// </summary>
  TGlbspLump = class
  private
    FName: AnsiString;
    FStart: Integer;
    FNewStart: Integer;
    FLength: Integer;
    FFlags: Integer;
    FData: TBytes;
    FLevelInfo: TGlbspLevelInfo;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;

    /// <summary>
    ///   Appends raw bytes at the end of the lump, as AppendLevelLump
    /// </summary>
    procedure Append(const AData; const ALength: Integer); overload;
    procedure Append(const AText: AnsiString); overload;
    /// <summary>Empties the lump (the name and the flags stay)</summary>
    procedure Truncate;
    /// <summary>True when the lump is empty or contains only zeros</summary>
    function IsAllZero: Boolean;
    /// <summary>Gives the lump its level information</summary>
    procedure AttachLevelInfo(const AFlags: Integer);

    property Name: AnsiString read FName;
    property Start: Integer read FStart write FStart;
    property NewStart: Integer read FNewStart write FNewStart;
    property Length: Integer read FLength write FLength;
    property Flags: Integer read FFlags write FFlags;
    property Data: TBytes read FData write FData;
    /// <summary>Level information, usually nil</summary>
    property LevelInfo: TGlbspLevelInfo read FLevelInfo;
  end;

implementation

{ TGlbspLevelInfo }

constructor TGlbspLevelInfo.Create(const AFlags: Integer);
begin
  inherited Create;
  FFlags := AFlags;
  FChildren := TObjectList<TGlbspLump>.Create(True);
end;

destructor TGlbspLevelInfo.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

{ TGlbspLump }

constructor TGlbspLump.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FStart := -1;
  FNewStart := -1;
  FFlags := LUMP_NEW;
end;

destructor TGlbspLump.Destroy;
begin
  FLevelInfo.Free;
  inherited Destroy;
end;

procedure TGlbspLump.Append(const AData; const ALength: Integer);
begin
  if ALength <= 0 then
    Exit;
  if System.Length(FData) < FLength + ALength then
    SetLength(FData, FLength + ALength + 256);
  Move(AData, FData[FLength], ALength);
  Inc(FLength, ALength);
end;

procedure TGlbspLump.Append(const AText: AnsiString);
begin
  if AText <> '' then
    Append(AText[1], System.Length(AText));
end;

procedure TGlbspLump.Truncate;
begin
  FData := nil;
  FLength := 0;
end;

function TGlbspLump.IsAllZero: Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to FLength - 1 do
  begin
    if FData[LIndex] <> 0 then
      Exit(False);
  end;
end;

procedure TGlbspLump.AttachLevelInfo(const AFlags: Integer);
begin
  FLevelInfo.Free;
  FLevelInfo := TGlbspLevelInfo.Create(AFlags);
end;

end.
