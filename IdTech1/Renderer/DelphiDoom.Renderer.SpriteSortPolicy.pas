{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - which sort for how many sprites              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SortVisSprites and R_SortVisSpritesMT of                          }
{  r_things_sortvissprites.pas                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.SpriteSortPolicy;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   More than 1024 sprites: radix sort; more than 512: merge sort; more than 32: quick sort;
  ///   else selection sort
  /// </summary>
  TRendererSpriteSortPolicy = class(TInterfacedObject, IRendererSpriteSortPolicy)
  strict private
    FSelection: IRendererSpriteSorter;
    FQuick: IRendererSpriteSorter;
    FMerge: IRendererSpriteSorter;
    FRadix: IRendererSpriteSorter;
  public
    constructor Create(const ASelection, AQuick, AMerge, ARadix: IRendererSpriteSorter);
    function Select(ACount: Integer): IRendererSpriteSorter;
    /// <summary>
    ///   Makes the room of the sorters that allocate, before the sorting runs in another thread
    ///   (the old R_SortVisSpritesMT: the allocation in a thread would slow the memory manager)
    /// </summary>
    procedure Reserve(ACount: Integer);
    procedure Release;
  end;

implementation

const
  RADIX_ABOVE = 1024;
  MERGE_ABOVE = 512;
  QUICK_ABOVE = 32;

{ TRendererSpriteSortPolicy }

constructor TRendererSpriteSortPolicy.Create(const ASelection, AQuick, AMerge,
  ARadix: IRendererSpriteSorter);
begin
  inherited Create;
  if not Assigned(ASelection) then
    raise EArgumentNilException.Create('ASelection');
  if not Assigned(AQuick) then
    raise EArgumentNilException.Create('AQuick');
  if not Assigned(AMerge) then
    raise EArgumentNilException.Create('AMerge');
  if not Assigned(ARadix) then
    raise EArgumentNilException.Create('ARadix');
  FSelection := ASelection;
  FQuick := AQuick;
  FMerge := AMerge;
  FRadix := ARadix;
end;

function TRendererSpriteSortPolicy.Select(ACount: Integer): IRendererSpriteSorter;
begin
  if ACount > RADIX_ABOVE then
    Result := FRadix
  else if ACount > MERGE_ABOVE then
    Result := FMerge
  else if ACount > QUICK_ABOVE then
    Result := FQuick
  else
    Result := FSelection;
end;

procedure TRendererSpriteSortPolicy.Reserve(ACount: Integer);
begin
  // the old MT call made room for the radix sort (two buffers); the merge sort made its own
  FRadix.Reserve(ACount);
  FMerge.Reserve(ACount);
end;

procedure TRendererSpriteSortPolicy.Release;
begin
  FSelection.Release;
  FQuick.Release;
  FMerge.Release;
  FRadix.Release;
end;

end.
