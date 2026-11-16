{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the layouts on disk of the raw records     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.DiskLayouts;

interface

uses
  System.Generics.Collections,
  System.TypInfo,
  DelphiDoom.Serializer.DiskLayoutBuilder,
  DelphiDoom.Serializer.Intf;

type
  /// <summary>
  ///   The layouts of the records of the saved games: each one is worked out the first time that it is
  ///   asked for and then kept. A description of a field given later throws away what was worked out
  /// </summary>
  TDiskLayouts = class(TInterfacedObject, IDiskLayouts)
  strict private
    FBuilder: TDiskLayoutBuilder;
    FLayouts: TDictionary<Pointer, IDiskLayout>;
    FDeclared: TList<Pointer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DescribeArray(const ARecord: Pointer; const AField: string; const AElement: Pointer;
      ACount: Integer);
    procedure Declare(const ATypeInfo: Pointer);
    function LayoutOf(const ATypeInfo: Pointer): IDiskLayout;
    function DescribeAll: TArray<string>;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Serializer.Types;

{ TDiskLayouts }

constructor TDiskLayouts.Create;
begin
  inherited Create;
  FBuilder := TDiskLayoutBuilder.Create;
  FLayouts := TDictionary<Pointer, IDiskLayout>.Create;
  FDeclared := TList<Pointer>.Create;
end;

destructor TDiskLayouts.Destroy;
begin
  FDeclared.Free;
  FLayouts.Free;
  FBuilder.Free;
  inherited Destroy;
end;

procedure TDiskLayouts.DescribeArray(const ARecord: Pointer; const AField: string; const AElement: Pointer;
  ACount: Integer);
begin
  FBuilder.DescribeArray(PTypeInfo(ARecord), AField, PTypeInfo(AElement), ACount);
  FLayouts.Clear;
end;

procedure TDiskLayouts.Declare(const ATypeInfo: Pointer);
begin
  if not Assigned(ATypeInfo) then
    raise EArgumentNilException.Create('ATypeInfo');
  if not FDeclared.Contains(ATypeInfo) then
    FDeclared.Add(ATypeInfo);
end;

function TDiskLayouts.LayoutOf(const ATypeInfo: Pointer): IDiskLayout;
begin
  if FLayouts.TryGetValue(ATypeInfo, Result) then
    Exit;
  Result := FBuilder.Build(PTypeInfo(ATypeInfo));
  FLayouts.Add(ATypeInfo, Result);
end;

function TDiskLayouts.DescribeAll: TArray<string>;
var
  LTypeInfo: Pointer;
  LLines: TArray<string>;
begin
  Result := nil;
  for LTypeInfo in FDeclared do
  begin
    // a record that is not understood is told and the others follow: the list is read by a person
    try
      LLines := LayoutOf(LTypeInfo).Describe;
    except
      on E: ESerializerException do
        LLines := [Format('ERROR %s: %s', [string(PTypeInfo(LTypeInfo).Name), E.Message])];
    end;
    Result := Result + LLines;
  end;
end;

end.
