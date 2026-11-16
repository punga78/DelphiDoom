{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the side functions of PS_GAME                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  TSide and the Get/Set functions of the offsets and textures of a side, its  }
{  sector, validity and count (the PS_*Side* of psi_game.pas).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.World.Sides;

interface

uses
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>The side functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptSides = class(TInterfacedObject, IScriptSides, IScriptFunctionSection)
  strict private
    FWorld: IScriptWorld;
  public
    /// <exception cref="EArgumentNilException">If the world is nil</exception>
    constructor Create(const AWorld: IScriptWorld);
    procedure Describe(const ATable: IScriptFunctionTable);
    function TSide(const AId: Integer): Integer;
    function GetOffset(const ASide: Integer; const AKind: TScriptSideOffset): Integer;
    procedure SetOffset(const ASide: Integer; const AKind: TScriptSideOffset; const AValue: Integer);
    function GetTexture(const ASide: Integer; const APart: TScriptSidePart): string;
    procedure SetTexture(const ASide: Integer; const APart: TScriptSidePart; const AName: string);
    function GetSideSector(const ASide: Integer): Integer;
    function IsValidSide(const ASide: Integer): Boolean;
    function GetSideCount: Integer;
    // the methods below are the ones that scripts call: the names of the scripts are in Describe
    function GetSideTextureOffset(const ASide: Integer): Integer;
    procedure SetSideTextureOffset(const ASide: Integer; const AValue: Integer);
    function GetSideTopTextureOffset(const ASide: Integer): Integer;
    procedure SetSideTopTextureOffset(const ASide: Integer; const AValue: Integer);
    function GetSideBottomTextureOffset(const ASide: Integer): Integer;
    procedure SetSideBottomTextureOffset(const ASide: Integer; const AValue: Integer);
    function GetSideMidTextureOffset(const ASide: Integer): Integer;
    procedure SetSideMidTextureOffset(const ASide: Integer; const AValue: Integer);
    function GetSideRowOffset(const ASide: Integer): Integer;
    procedure SetSideRowOffset(const ASide: Integer; const AValue: Integer);
    function GetSideTopRowOffset(const ASide: Integer): Integer;
    procedure SetSideTopRowOffset(const ASide: Integer; const AValue: Integer);
    function GetSideBottomRowOffset(const ASide: Integer): Integer;
    procedure SetSideBottomRowOffset(const ASide: Integer; const AValue: Integer);
    function GetSideMidRowOffset(const ASide: Integer): Integer;
    procedure SetSideMidRowOffset(const ASide: Integer; const AValue: Integer);
    function GetSideTopTexture(const ASide: Integer): string;
    procedure SetSideTopTexture(const ASide: Integer; const AName: string);
    function GetSideBottomTexture(const ASide: Integer): string;
    procedure SetSideBottomTexture(const ASide: Integer; const AName: string);
    function GetSideMiddleTexture(const ASide: Integer): string;
    procedure SetSideMiddleTexture(const ASide: Integer; const AName: string);
  end;

implementation

uses
  System.SysUtils;

{ TScriptSides }

constructor TScriptSides.Create(const AWorld: IScriptWorld);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  FWorld := AWorld;
end;

procedure TScriptSides.Describe(const ATable: IScriptFunctionTable);
begin
  ATable.AddMethodWithCustomResult('procedure TSide(const id: Integer);', '!TSide',
    'function TSide(const id: Integer): !TSide;', Self, @TScriptSides.TSide);
  ATable.AddMethod('function GetSideTextureOffset(const sd: Integer): fixed_t;', Self,
    @TScriptSides.GetSideTextureOffset);
  ATable.AddMethod('procedure SetSideTextureOffset(const sd: Integer; const offs: fixed_t);', Self,
    @TScriptSides.SetSideTextureOffset);
  ATable.AddMethod('function GetSideTopTextureOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideTopTextureOffset);
  ATable.AddMethod('procedure SetSideTopTextureOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideTopTextureOffset);
  ATable.AddMethod('function GetSideBottomTextureOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideBottomTextureOffset);
  ATable.AddMethod('procedure SetSideBottomTextureOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideBottomTextureOffset);
  ATable.AddMethod('function GetSideMidTextureOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideMidTextureOffset);
  ATable.AddMethod('procedure SetSideMidTextureOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideMidTextureOffset);
  ATable.AddMethod('function GetSideRowOffset(const sd: Integer): fixed_t;', Self,
    @TScriptSides.GetSideRowOffset);
  ATable.AddMethod('procedure SetSideRowOffset(const sd: Integer; const offs: fixed_t);', Self,
    @TScriptSides.SetSideRowOffset);
  ATable.AddMethod('function GetSideTopRowOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideTopRowOffset);
  ATable.AddMethod('procedure SetSideTopRowOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideTopRowOffset);
  ATable.AddMethod('function GetSideBottomRowOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideBottomRowOffset);
  ATable.AddMethod('procedure SetSideBottomRowOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideBottomRowOffset);
  ATable.AddMethod('function GetSideMidRowOffset(const sd: Integer): Integer;', Self,
    @TScriptSides.GetSideMidRowOffset);
  ATable.AddMethod('procedure SetSideMidRowOffset(const sd: Integer; const offs: Integer);', Self,
    @TScriptSides.SetSideMidRowOffset);
  ATable.AddMethod('function GetSideTopTexture(const sd: Integer): string;', Self,
    @TScriptSides.GetSideTopTexture);
  ATable.AddMethod('procedure SetSideTopTexture(const sd: Integer; const tex: string);', Self,
    @TScriptSides.SetSideTopTexture);
  ATable.AddMethod('function GetSideBottomTexture(const sd: Integer): string;', Self,
    @TScriptSides.GetSideBottomTexture);
  ATable.AddMethod('procedure SetSideBottomTexture(const sd: Integer; const tex: string);', Self,
    @TScriptSides.SetSideBottomTexture);
  ATable.AddMethod('function GetSideMiddleTexture(const sd: Integer): string;', Self,
    @TScriptSides.GetSideMiddleTexture);
  ATable.AddMethod('procedure SetSideMiddleTexture(const sd: Integer; const tex: string);', Self,
    @TScriptSides.SetSideMiddleTexture);
  ATable.AddMethod('function GetSideSector(const sd: Integer): integer;', Self,
    @TScriptSides.GetSideSector);
  ATable.AddMethod('function IsValidSide(const sd: Integer): boolean;', Self,
    @TScriptSides.IsValidSide);
  ATable.AddMethod('function GetSideCount: Integer;', Self, @TScriptSides.GetSideCount);
end;

function TScriptSides.TSide(const AId: Integer): Integer;
begin
  if IsValidSide(AId) then
    Result := AId + 1
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptSides.GetOffset(const ASide: Integer; const AKind: TScriptSideOffset): Integer;
var
  LKind: TScriptSideOffset;
begin
  LKind := AKind;
  // defect of the old code, kept: the "mid row offset" of a side is its bottom row offset
  if LKind = sofMidRow then
    LKind := sofBottomRow;
  if IsValidSide(ASide) then
    Result := FWorld.SideOffset(ASide, LKind)
  else
    Result := 0;
end;

procedure TScriptSides.SetOffset(const ASide: Integer; const AKind: TScriptSideOffset;
  const AValue: Integer);
var
  LKind: TScriptSideOffset;
begin
  LKind := AKind;
  // the same defect, on the write
  if LKind = sofMidRow then
    LKind := sofBottomRow;
  if IsValidSide(ASide) then
    FWorld.SetSideOffset(ASide, LKind, AValue);
end;

function TScriptSides.GetTexture(const ASide: Integer; const APart: TScriptSidePart): string;
begin
  if IsValidSide(ASide) then
    Result := FWorld.SideTexture(ASide, APart)
  else
    Result := '';
end;

procedure TScriptSides.SetTexture(const ASide: Integer; const APart: TScriptSidePart;
  const AName: string);
begin
  if IsValidSide(ASide) then
    FWorld.SetSideTexture(ASide, APart, AName);
end;

function TScriptSides.GetSideSector(const ASide: Integer): Integer;
begin
  if IsValidSide(ASide) then
    Result := FWorld.SideSectorId(ASide)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptSides.IsValidSide(const ASide: Integer): Boolean;
begin
  Result := (ASide >= 0) and (ASide < FWorld.SideCount);
end;

function TScriptSides.GetSideCount: Integer;
begin
  Result := FWorld.SideCount;
end;

function TScriptSides.GetSideTextureOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofTexture);
end;

procedure TScriptSides.SetSideTextureOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofTexture, AValue);
end;

function TScriptSides.GetSideTopTextureOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofTopTexture);
end;

procedure TScriptSides.SetSideTopTextureOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofTopTexture, AValue);
end;

function TScriptSides.GetSideBottomTextureOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofBottomTexture);
end;

procedure TScriptSides.SetSideBottomTextureOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofBottomTexture, AValue);
end;

function TScriptSides.GetSideMidTextureOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofMiddleTexture);
end;

procedure TScriptSides.SetSideMidTextureOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofMiddleTexture, AValue);
end;

function TScriptSides.GetSideRowOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofRow);
end;

procedure TScriptSides.SetSideRowOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofRow, AValue);
end;

function TScriptSides.GetSideTopRowOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofTopRow);
end;

procedure TScriptSides.SetSideTopRowOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofTopRow, AValue);
end;

function TScriptSides.GetSideBottomRowOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofBottomRow);
end;

procedure TScriptSides.SetSideBottomRowOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofBottomRow, AValue);
end;

function TScriptSides.GetSideMidRowOffset(const ASide: Integer): Integer;
begin
  Result := GetOffset(ASide, sofMidRow);
end;

procedure TScriptSides.SetSideMidRowOffset(const ASide: Integer; const AValue: Integer);
begin
  SetOffset(ASide, sofMidRow, AValue);
end;

function TScriptSides.GetSideTopTexture(const ASide: Integer): string;
begin
  Result := GetTexture(ASide, sspTop);
end;

procedure TScriptSides.SetSideTopTexture(const ASide: Integer; const AName: string);
begin
  SetTexture(ASide, sspTop, AName);
end;

function TScriptSides.GetSideBottomTexture(const ASide: Integer): string;
begin
  Result := GetTexture(ASide, sspBottom);
end;

procedure TScriptSides.SetSideBottomTexture(const ASide: Integer; const AName: string);
begin
  SetTexture(ASide, sspBottom, AName);
end;

function TScriptSides.GetSideMiddleTexture(const ASide: Integer): string;
begin
  Result := GetTexture(ASide, sspMiddle);
end;

procedure TScriptSides.SetSideMiddleTexture(const ASide: Integer; const AName: string);
begin
  SetTexture(ASide, sspMiddle, AName);
end;

end.
