{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclTypeInfo, a registered type          }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.cpp (idDeclType). Copyright (C) 1999-2011 id          }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.TypeInfo;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf;

type
  /// <summary>
  ///   The type of <c>RegisterDeclType(name, number, allocator)</c>: a name, a number and the function
  ///   that makes the objects. A library with a richer type implements <c>IDeclType</c> itself.
  /// </summary>
  TDeclTypeInfo = class(TInterfacedObject, IDeclType)
  strict private
    FTypeName: AnsiString;
    FTypeId: Integer;
    FAllocator: TDeclAllocator;
  public
    constructor Create(const ATypeName: AnsiString; const ATypeId: Integer; const AAllocator: TDeclAllocator);
    function GetTypeName: AnsiString;
    function GetTypeId: Integer;
    function CreateDecl: IDecl;
  end;

implementation

uses
  DelphiDoom.Decl.Types;

const
  SNoAllocator = 'The declaration type "%s" has no allocator';

{ TDeclTypeInfo }

constructor TDeclTypeInfo.Create(const ATypeName: AnsiString; const ATypeId: Integer;
  const AAllocator: TDeclAllocator);
begin
  inherited Create;
  FTypeName := ATypeName;
  FTypeId := ATypeId;
  FAllocator := AAllocator;
end;

function TDeclTypeInfo.GetTypeName: AnsiString;
begin
  Result := FTypeName;
end;

function TDeclTypeInfo.GetTypeId: Integer;
begin
  Result := FTypeId;
end;

function TDeclTypeInfo.CreateDecl: IDecl;
begin
  if not Assigned(FAllocator) then
    raise EDeclException.CreateFmt(SNoAllocator, [string(FTypeName)]);
  Result := FAllocator();
end;

end.
