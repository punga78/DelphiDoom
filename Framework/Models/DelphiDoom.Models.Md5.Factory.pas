{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the factory                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Factory;

interface

uses
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the MD5 models</summary>
  TMd5Factory = class
  public
    /// <summary>The reader of md5mesh files</summary>
    class function CreateModelParser: IMd5ModelParser; static;
    /// <summary>The reader of md5anim files</summary>
    class function CreateAnimParser: IMd5AnimParser; static;
    /// <summary>The skeleton of a hierarchy of parents (-1 for the root, parents before children)</summary>
    class function CreateSkeleton(const AParents: TArray<Integer>): IMd5Skeleton; static;
  end;

implementation

uses
  DelphiDoom.Models.Md5.ModelParser,
  DelphiDoom.Models.Md5.AnimParser,
  DelphiDoom.Models.Md5.Skeleton;

{ TMd5Factory }

class function TMd5Factory.CreateModelParser: IMd5ModelParser;
begin
  Result := TMd5ModelParser.Create;
end;

class function TMd5Factory.CreateAnimParser: IMd5AnimParser;
begin
  Result := TMd5AnimParser.Create;
end;

class function TMd5Factory.CreateSkeleton(const AParents: TArray<Integer>): IMd5Skeleton;
begin
  Result := TMd5Skeleton.Create(AParents);
end;

end.
