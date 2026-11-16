{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - the table of the decoders                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of the list of texture managers of t_main.pas (GetImageFormat)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.Formats;

interface

uses
  System.SysUtils, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf;

type
  /// <summary>The decoders that the engine has, found by extension</summary>
  TTextureFormats = class(TInterfacedObject, ITextureFormats)
  strict private
    FDecoders: TArray<ITextureDecoder>;
  public
    /// <param name="ADecoders">The decoders in the order of their registration</param>
    constructor Create(const ADecoders: TArray<ITextureDecoder>);
    function FindDecoder(const AExtension: string): ITextureDecoder;
    function IsKnownExtension(const AExtension: string): Boolean;
    function Extensions: TArray<string>;
    function Decode(const AExtension: string; const ASource: TBytes;
      const AImage: TTextureImage): Boolean;
  end;

implementation

{ TTextureFormats }

constructor TTextureFormats.Create(const ADecoders: TArray<ITextureDecoder>);
var
  LDecoder: ITextureDecoder;
begin
  inherited Create;
  for LDecoder in ADecoders do
    if not Assigned(LDecoder) then
      raise EArgumentNilException.Create('ADecoders');
  FDecoders := Copy(ADecoders);
end;

function TTextureFormats.FindDecoder(const AExtension: string): ITextureDecoder;
var
  LExtension: string;
  LIndex: Integer;
begin
  LExtension := UpperCase(AExtension);
  // the last decoder that was added is the first one asked, and it is enough that its
  // extension contains the text: it is what the old linked list did
  for LIndex := High(FDecoders) downto 0 do
    if Pos(LExtension, FDecoders[LIndex].Extension) > 0 then
      Exit(FDecoders[LIndex]);
  Result := nil;
end;

function TTextureFormats.IsKnownExtension(const AExtension: string): Boolean;
var
  LDecoder: ITextureDecoder;
begin
  for LDecoder in FDecoders do
    if SameText(LDecoder.Extension, AExtension) then
      Exit(True);
  Result := False;
end;

function TTextureFormats.Extensions: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(FDecoders));
  for LIndex := 0 to High(FDecoders) do
    Result[LIndex] := FDecoders[LIndex].Extension;
end;

function TTextureFormats.Decode(const AExtension: string; const ASource: TBytes;
  const AImage: TTextureImage): Boolean;
var
  LDecoder: ITextureDecoder;
begin
  LDecoder := FindDecoder(AExtension);
  Result := Assigned(LDecoder) and LDecoder.Decode(ASource, AImage);
end;

end.
