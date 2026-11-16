{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the factory of the editor classes               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.EditorFactory;

interface

uses
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The only place that knows the classes of the editable screen. It is not TEndoomFactory so that the game, which
  ///   uses that one, does not need the units of the editor to compile
  /// </summary>
  TEndoomEditorFactory = class
  public
    /// <summary>An empty text screen that a tool can edit</summary>
    class function CreateScreen: IEndoomScreen; static;
    /// <summary>The font of ENDEDIT, built into the program</summary>
    class function CreateEditorFontSource: IEndoomFontSource; static;
    /// <summary>The picture of a screen, drawn with a new renderer</summary>
    class function CreateScreenImage: IEndoomScreenImage; static;
  end;

implementation

uses
  DelphiDoom.Endoom.Factory, DelphiDoom.Endoom.Screen, DelphiDoom.Endoom.FontSource, DelphiDoom.Endoom.ScreenImage;

{ TEndoomEditorFactory }

class function TEndoomEditorFactory.CreateScreen: IEndoomScreen;
begin
  Result := TEndoomScreen.Create;
end;

class function TEndoomEditorFactory.CreateEditorFontSource: IEndoomFontSource;
begin
  Result := TEndoomEmbeddedFontSource.Create;
end;

class function TEndoomEditorFactory.CreateScreenImage: IEndoomScreenImage;
begin
  Result := TEndoomScreenImage.Create(TEndoomFactory.CreateRenderer);
end;

end.
