{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the display of the menus, without the drawing     }
{                                                                              }
{  The set of the classes that port the stack of the open menus, the focus,    }
{  the pointer and the keys of ui_shared.c (Quake III Arena, id Software, GPL  }
{  v2 or later), made and wired together. Based on the Quake III Arena GPL     }
{  Source Code (id Software).                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display;

interface

uses
  DelphiDoom.Gui.Intf, DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.ScriptRunner, DelphiDoom.Gui.Display.Intf,
  DelphiDoom.Gui.Display.State, DelphiDoom.Gui.Display.ListBox, DelphiDoom.Gui.Display.Slider,
  DelphiDoom.Gui.Display.CvarItems, DelphiDoom.Gui.Display.Stack, DelphiDoom.Gui.Display.Pointer,
  DelphiDoom.Gui.Display.TextField, DelphiDoom.Gui.Display.ItemKeys, DelphiDoom.Gui.Display.MenuKeys;

type
  /// <summary>
  ///   What a host needs to run the menus of Team Arena without drawing them: the open menus
  ///   (<c>Menus_OpenByName</c>, <c>Menus_CloseAll</c> ...), the focus, the pointer
  ///   (<c>Display_MouseMove</c>) and the keys (<c>Display_HandleKey</c>). The menu set, the script runner and
  ///   the hosts are the caller's; the parts are the display's. The commands <c>open</c>, <c>close</c> and
  ///   <c>conditionalopen</c> of a script reach <c>IGuiScriptHost</c>: its implementation calls
  ///   <c>Stack.OpenByName</c> and <c>Stack.CloseByName</c>.
  /// </summary>
  TGuiDisplay = class
  strict private
    FState: TGuiDisplayState;
    FListBoxes: TGuiListBoxLogic;
    FSliders: TGuiSliderLogic;
    FCvarItems: TGuiCvarItems;
    FStack: TGuiMenuStack;
    FPointer: TGuiPointer;
    FTextFields: TGuiTextFieldKeys;
    FItemKeys: TGuiItemKeys;
    FMenuKeys: TGuiMenuKeys;
  public
    /// <summary>The script and media hosts may be nil: the commands that need them then do nothing</summary>
    constructor Create(const AMenus: TGuiMenuSet; const ARunner: TGuiScriptRunner; const AInput: IGuiInputHost;
      const AScript: IGuiScriptHost; const AMedia: IGuiMediaHost);
    destructor Destroy; override;
    property State: TGuiDisplayState read FState;
    property ListBoxes: TGuiListBoxLogic read FListBoxes;
    property Sliders: TGuiSliderLogic read FSliders;
    property CvarItems: TGuiCvarItems read FCvarItems;
    property Stack: TGuiMenuStack read FStack;
    property Pointer: TGuiPointer read FPointer;
    property ItemKeys: TGuiItemKeys read FItemKeys;
    property MenuKeys: TGuiMenuKeys read FMenuKeys;
  end;

implementation

constructor TGuiDisplay.Create(const AMenus: TGuiMenuSet; const ARunner: TGuiScriptRunner;
  const AInput: IGuiInputHost; const AScript: IGuiScriptHost; const AMedia: IGuiMediaHost);
begin
  inherited Create;
  FState := TGuiDisplayState.Create(AMenus, ARunner, AInput, AScript, AMedia);
  FListBoxes := TGuiListBoxLogic.Create(FState);
  FSliders := TGuiSliderLogic.Create(FState);
  FCvarItems := TGuiCvarItems.Create(FState);
  FStack := TGuiMenuStack.Create(FState);
  FPointer := TGuiPointer.Create(FState, FListBoxes, FCvarItems, FStack);
  FTextFields := TGuiTextFieldKeys.Create(FState, FPointer);
  FItemKeys := TGuiItemKeys.Create(FState, FListBoxes, FSliders, FCvarItems);
  FMenuKeys := TGuiMenuKeys.Create(FState, FStack, FPointer, FItemKeys, FTextFields);
end;

destructor TGuiDisplay.Destroy;
begin
  FMenuKeys.Free;
  FItemKeys.Free;
  FTextFields.Free;
  FPointer.Free;
  FStack.Free;
  FCvarItems.Free;
  FSliders.Free;
  FListBoxes.Free;
  FState.Free;
  inherited Destroy;
end;

end.
