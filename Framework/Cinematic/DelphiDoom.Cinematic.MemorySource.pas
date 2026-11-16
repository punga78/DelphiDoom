{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - a RoQ file in memory                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.MemorySource;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Intf;

type
  /// <summary>The bytes of a RoQ file in a buffer (a lump, a file that was read, a test)</summary>
  TRoqMemorySource = class(TInterfacedObject, IRoqSource)
  strict private
    FBytes: TBytes;
    FPosition: Int64;
    function GetSize: Int64;
    function GetPosition: Int64;
  public
    constructor Create(const ABytes: TBytes);
    function Read(var ABuffer; ACount: Integer): Integer;
    procedure Seek(APosition: Int64);
  end;

implementation

{ TRoqMemorySource }

constructor TRoqMemorySource.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
end;

function TRoqMemorySource.GetSize: Int64;
begin
  Result := Length(FBytes);
end;

function TRoqMemorySource.GetPosition: Int64;
begin
  Result := FPosition;
end;

function TRoqMemorySource.Read(var ABuffer; ACount: Integer): Integer;
begin
  Result := Length(FBytes) - FPosition;
  if Result > ACount then
    Result := ACount;
  if Result <= 0 then
  begin
    Result := 0;
    Exit;
  end;
  Move(FBytes[FPosition], ABuffer, Result);
  Inc(FPosition, Result);
end;

procedure TRoqMemorySource.Seek(APosition: Int64);
begin
  if APosition < 0 then
    APosition := 0;
  if APosition > Length(FBytes) then
    APosition := Length(FBytes);
  FPosition := APosition;
end;

end.
