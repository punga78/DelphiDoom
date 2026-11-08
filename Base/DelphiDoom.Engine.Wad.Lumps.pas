{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps for the classes of the engine                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Wad.Lumps;

interface

uses
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   IEngineLumps over w_wad.pas: the directory, the finder and the lump cache stay in that unit
  ///   (lumpcache[] and the PU_* tags belong to the engine), this class is the only place
  ///   where the classes of the engine reach them
  /// </summary>
  TEngineLumps = class(TInterfacedObject, IEngineLumps)
  public
    function Count: Integer;
    function CheckNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    function GetNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    function NameOf(ALump: Integer): string;
    function LengthOf(ALump: Integer): Integer;
    function Crc32Of(ALump: Integer): string;
    function TextOf(ALump: Integer): string;
    procedure Read(ALump: Integer; ADestination: Pointer);
    function Cache(ALump: Integer; ATag: Integer): Pointer;
    procedure RuntimeLoadFile(const AFileName: string);
    procedure Reload;
  end;

implementation

uses
  w_wad;

{ TEngineLumps }

function TEngineLumps.Count: Integer;
begin
  Result := W_NumLumps;
end;

function TEngineLumps.CheckNumForName(const AName: string; AFlags: LongWord): Integer;
begin
  Result := W_CheckNumForName(AName, AFlags);
end;

function TEngineLumps.GetNumForName(const AName: string; AFlags: LongWord): Integer;
begin
  Result := W_GetNumForName(AName, AFlags);
end;

function TEngineLumps.NameOf(ALump: Integer): string;
begin
  Result := char8tostring(W_GetNameForNum(ALump));
end;

function TEngineLumps.LengthOf(ALump: Integer): Integer;
begin
  Result := W_LumpLength(ALump);
end;

function TEngineLumps.Crc32Of(ALump: Integer): string;
begin
  Result := W_LumpCRC32(ALump);
end;

function TEngineLumps.TextOf(ALump: Integer): string;
begin
  Result := W_TextLumpNum(ALump);
end;

procedure TEngineLumps.Read(ALump: Integer; ADestination: Pointer);
begin
  W_ReadLump(ALump, ADestination);
end;

function TEngineLumps.Cache(ALump: Integer; ATag: Integer): Pointer;
begin
  Result := W_CacheLumpNum(ALump, ATag);
end;

procedure TEngineLumps.RuntimeLoadFile(const AFileName: string);
begin
  W_RuntimeLoad(AFileName, F_ORIGIN_WAD);
end;

procedure TEngineLumps.Reload;
begin
  W_Reload;
end;

end.
