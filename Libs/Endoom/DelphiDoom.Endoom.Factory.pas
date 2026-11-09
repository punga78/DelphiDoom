{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Factory;

interface

uses
  DelphiDoom.Endoom.Intf;

type
  /// <summary>The only place that knows the class behind IEndoomRenderer</summary>
  TEndoomFactory = class
  public
    class function CreateRenderer: IEndoomRenderer; static;
    /// <summary>An empty text screen that a tool can edit</summary>
    class function CreateScreen: IEndoomScreen; static;
    /// <summary>The font of ENDEDIT, built into the program</summary>
    class function CreateEditorFontSource: IEndoomFontSource; static;
    /// <summary>The picture of a screen, drawn with a new renderer</summary>
    class function CreateScreenImage: IEndoomScreenImage; static;
    /// <param name="ATicRate">The tics in a second</param>
    class function CreateSession(ATicRate: Integer): IEndoomSession; static;
  end;

implementation

uses
  DelphiDoom.Endoom.Renderer, DelphiDoom.Endoom.Session, DelphiDoom.Endoom.Screen,
  DelphiDoom.Endoom.FontSource, DelphiDoom.Endoom.ScreenImage;

{ TEndoomFactory }

class function TEndoomFactory.CreateRenderer: IEndoomRenderer;
begin
  Result := TEndoomRenderer.Create;
end;

class function TEndoomFactory.CreateScreen: IEndoomScreen;
begin
  Result := TEndoomScreen.Create;
end;

class function TEndoomFactory.CreateEditorFontSource: IEndoomFontSource;
begin
  Result := TEndoomEmbeddedFontSource.Create;
end;

class function TEndoomFactory.CreateScreenImage: IEndoomScreenImage;
begin
  Result := TEndoomScreenImage.Create(CreateRenderer);
end;

class function TEndoomFactory.CreateSession(ATicRate: Integer): IEndoomSession;
begin
  Result := TEndoomSession.Create(ATicRate);
end;

end.
