{******************************************************************************}
{                                                                              }
{  DD_Tools: the clipboard of Windows for the endoom editor                     }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.EndoomClipboard;

interface

uses
  System.SysUtils,
  DelphiDoom.EndoomEditor.Intf;

type
  /// <summary>IEndoomEditorClipboard on the clipboard of the VCL: pictures (CF_BITMAP) and text (CF_TEXT)</summary>
  TVclEndoomEditorClipboard = class(TInterfacedObject, IEndoomEditorClipboard)
  public
    function HasText: Boolean;
    function HasImage: Boolean;
    function GetText: string;
    function TryGetImage(out APixels: TArray<Cardinal>; out AWidth, AHeight: Integer): Boolean;
    procedure SetImage(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Graphics, Vcl.Clipbrd,
  DelphiDoom.Tools.Win.Bitmaps;

{ TVclEndoomEditorClipboard }

function TVclEndoomEditorClipboard.HasText: Boolean;
begin
  Result := Clipboard.HasFormat(CF_TEXT) or Clipboard.HasFormat(CF_UNICODETEXT);
end;

function TVclEndoomEditorClipboard.HasImage: Boolean;
begin
  Result := Clipboard.HasFormat(CF_BITMAP);
end;

function TVclEndoomEditorClipboard.GetText: string;
begin
  Result := Clipboard.AsText;
end;

function TVclEndoomEditorClipboard.TryGetImage(out APixels: TArray<Cardinal>; out AWidth, AHeight: Integer): Boolean;
var
  LBitmap: TBitmap;
begin
  APixels := nil;
  AWidth := 0;
  AHeight := 0;
  Result := Clipboard.HasFormat(CF_BITMAP);
  if not Result then
    Exit;
  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromClipboardFormat(CF_BITMAP, Clipboard.GetAsHandle(CF_BITMAP), 0);
    APixels := TToolsBitmapPixels.FromBitmap(LBitmap, AWidth, AHeight);
    Result := Length(APixels) > 0;
  finally
    LBitmap.Free;
  end;
end;

procedure TVclEndoomEditorClipboard.SetImage(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
var
  LBitmap: TBitmap;
begin
  LBitmap := TToolsBitmapPixels.ToBitmap(APixels, AWidth, AHeight);
  try
    Clipboard.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

end.
