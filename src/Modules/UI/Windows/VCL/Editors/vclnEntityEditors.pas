﻿{ ---------------------------------------------------------------------------------
  X-Tend runtime

  Contributors:
  Vladimir Kustikov (kustikov@sensoft.pro)
  Sergey Arlamenkov (arlamenkov@sensoft.pro)

  You may retrieve the latest version of this file at the GitHub,
  located at https://github.com/sensoftpro/x-tend.git
  ---------------------------------------------------------------------------------
  MIT License

  Copyright © 2021 Sensoft

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  --------------------------------------------------------------------------------- }

unit vclnEntityEditors;

interface

uses
  Classes, Generics.Collections, StdCtrls, ExtCtrls, ActnList, Controls, Types, Forms, ComCtrls,

  Buttons, vclnArea, vclnPopupForm, uUIBuilder, uView, uEntity, uEntityList, uDefinition;

type
  TVCLEntitySelector = class(TVCLFieldArea)
  private
    FFlat: Boolean;
    FEntities: TEntityList;
    procedure FillList;
    procedure CBOnInitPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
  protected
    procedure DoCreateControl(const AParent: TUIArea; const ALayout: TObject); override;
    procedure DoBeforeFreeControl; override;
    procedure FillEditor; override;
    procedure DoOnChange; override;
    procedure SwitchChangeHandlers(const AHandler: TNotifyEvent); override;
  end;

  TVCLEntityFieldEditor = class(TVCLFieldArea)
  private
    FBasePanel: TPanel;
    FSelectButton: TComboBox;
    FEdit: TEdit;
    FbtnAdd: TButton;
    FEntities: TEntityList;
    FSelectPopup: TSelectEntityPopup;
    FButtonView: TView;
    procedure OnSelectClick(Sender: TObject);
    procedure OnAddClick(Sender: TObject);
    procedure ShowPopup(const AFilter: string);
    procedure DoOnClose(Sender: TObject);
    procedure ClosePopup;
    function PopupShowing: Boolean;
    procedure OnEntitySelected(const ANewEntity: TEntity);
    procedure OnWinControlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function GetDisabledBorderStyle: TBorderStyle;
    procedure OnActionMenuSelected(Sender: TObject);
  protected
    procedure UpdateVisibility; virtual;
  protected
    procedure DoAdd(const ACollectionIndex: Integer);
    procedure DoEdit;
    procedure DoCreateControl(const AParent: TUIArea; const ALayout: TObject); override;
    procedure DoBeforeFreeControl; override;
    procedure FillEditor; override;
    procedure SetFocused(const Value: Boolean); override;
    procedure FocusedChanged(const AFocused: Boolean); override;
    procedure DoDeinit; override;
  end;

  TRadioEntitySelector = class(TVCLFieldArea)
  private
    FEntities: TEntityList;
    procedure FillList;
  protected
    procedure DoCreateControl(const AParent: TUIArea; const ALayout: TObject); override;
    procedure DoBeforeFreeControl; override;
    procedure FillEditor; override;
    procedure DoOnChange; override;
    procedure SwitchChangeHandlers(const AHandler: TNotifyEvent); override;
  end;

  TVCLLinkedEntityFieldEditor = class(TVCLEntityFieldEditor)
  private
    FLabel: TLabel;
    procedure OnLabelClick(Sender: TObject);
  protected
    procedure DoBeforeFreeControl; override;
    procedure UpdateVisibility; override;
  end;

  TListEntityFieldEditor = class(TVCLFieldArea)
  private
    FGrid: TTreeView;
    FEntities: TEntityList;
    procedure OnDblClick(Sender: TObject);
    procedure DoOnFocusedNodeChanged(Sender: TObject);
    procedure Reload;
  protected
    procedure DoCreateControl(const AParent: TUIArea; const ALayout: TObject); override;
    procedure DoBeforeFreeControl; override;
    procedure FillEditor; override;
  end;

//  TEntityFieldListEditor = class(TVCLFieldArea) // редактор нескольких полей сущности одновременно
//  private
//    FEditor: TcxVerticalGrid;
//    FDomainObject: TEntity;
//    FChildViews: TList<TView>;
//    FDisplayFields: TStringList;
//    procedure CleanChildViews;
//    function CreateEditRow(const ARootEntity: TEntity; const AFieldDef: TFieldDef; const AViewPath: string;
//      const AOverriddenCaption: string = ''): TcxEditorRow;
//    function CreateCategoryRow(const ARootEntity: TEntity; const AFieldDef: TFieldDef): TcxCategoryRow;
//    procedure CreateRows(const ARootEntity: TEntity; const ARootRow: TcxCustomRow; const AViewPath: string;
//      const ARootEntityIndex: Integer = -1);
//    procedure OnFieldChange(Sender: TObject);
//    procedure FreeEditors;
//  protected
//    procedure DoCreateControl(const AParent: TUIArea; const ALayout: TObject); override;
//    procedure DoBeforeFreeControl; override;
//    procedure DoDisableContent; override;
//    procedure FillEditor; override;
//    procedure RefillArea(const AKind: Word); override;
//  end;

implementation

uses
  Graphics, SysUtils, Windows, Messages,
  Menus, uInteractor, uDomain, uChangeManager, uObjectField, uConsts, uSession, Variants,
  uPresenter, uVCLPresenter, StrUtils, uUtils, uCollection;

type
  TRowData = class
    Entity: TEntity;
    FieldDef: TFieldDef;
    constructor Create(const AEntity: TEntity; const AFieldDef: TFieldDef);
  end;

function IsAlpha(c: Char): Boolean;
begin
  Result := ((c >= 'а') and (c <= 'я')) or ((c >= 'А') and (c <= 'Я')) or ((c >= 'a') and (c <= 'z')) or
    ((c >= 'A') and (c <= 'Z'));
end;

function VKeytoWideString(const AKey: Word): WideString;
var
  WBuff: array [0 .. 255] of WideChar;
  KeyboardState: TKeyboardState;
  UResult: Integer;
begin
  Result := '';
  GetKeyBoardState(KeyboardState);
  ZeroMemory(@WBuff[0], SizeOf(WBuff));
  UResult := ToUnicode(AKey, MapVirtualKey(AKey, 0), KeyboardState, WBuff, Length(WBuff), 0);
  if UResult > 0 then
    SetString(Result, WBuff, UResult)
  else if UResult = -1 then
    Result := WBuff;
end;

{ TVCLEntityFieldEditor }

procedure TVCLEntityFieldEditor.DoBeforeFreeControl;
begin
  inherited;

  if Assigned(FButtonView) then
    FButtonView.RemoveListener(Self);

  if Assigned(FSelectPopup) then
  begin
    FSelectPopup.Free;
    FSelectPopup := nil;
  end;
  FreeAndNil(FEntities);
  FreeAndNil(FEdit);
end;

procedure TVCLEntityFieldEditor.DoCreateControl(const AParent: TUIArea; const ALayout: TObject);
var
  vDefinitions: TList<TDefinition>;
  i: Integer;
  vMenuItem: TMenuItem;
  vDefinition: TDefinition;
begin
  if Assigned(FSelectPopup) then
  begin
    FSelectPopup.Free;
    FSelectPopup := nil;
  end;
  FEntities := nil;
  FButtonView := nil;
  FBasePanel := TPanel.Create(nil);
  FBasePanel.BevelOuter := bvNone;
  FBasePanel.ShowCaption := False;

  FSelectButton := TComboBox.Create(nil);
  with FSelectButton do
  begin
    Parent := FBasePanel;
    Align := alClient;
    Width := FBasePanel.Width;
    OnKeyDown := OnWinControlKeyDown;
    OnClick := OnSelectClick;
    Enabled := False;
    // AutoSelect := False;
    // IncrementalSearch := False;
    // style := csDrop;
    // Properties.ValidateOnEnter := False;
  end;

  // FSelectButton.Enabled := True;

  FEdit := TEdit.Create(nil);
  FEdit.Parent := FBasePanel;
  FEdit.Align := alClient;
  FEdit.Visible := False;
  FEdit.ReadOnly := True;
  FEdit.Text := '';
  FEdit.TabStop := False;
  FEdit.Color := clBtnFace;

  FControl := FBasePanel;

  FbtnAdd := TButton.Create(nil);
  FbtnAdd.Parent := FBasePanel;
  FbtnAdd.Hint := TInteractor(FView.Interactor).Translate('cptAddEntity', 'Добавить');
  FbtnAdd.Images := TDragImageList(TInteractor(Interactor).Images[16]);
  FbtnAdd.ImageIndex := 1;
  FbtnAdd.Align := alRight;
  FbtnAdd.TabStop := False;
  FButtonView := FView.BuildView('Create?place=embedded');
  FButtonView.AddListener(Self);

  vDefinitions := TEntityFieldDef(FFieldDef).ContentDefinitions;
  if vDefinitions.Count > 1 then
  begin
    FPopupMenu := TPopupMenu.Create(nil);
    FPopupMenu.Images := TDragImageList(TInteractor(Interactor).Images[16]);
    for i := 0 to vDefinitions.Count - 1 do
    begin
      vDefinition := TDefinition(vDefinitions[i]);
      vMenuItem := TMenuItem.Create(nil);
      vMenuItem.Caption := GetTranslation(vDefinition);
      vMenuItem.ImageIndex := GetImageID(vDefinition._ImageID);
      vMenuItem.Tag := NativeInt(FbtnAdd);
      vMenuItem.OnClick := OnActionMenuSelected;
      FPopupMenu.Items.Add(vMenuItem);
    end;
    FbtnAdd.DropDownMenu := FPopupMenu;
    FbtnAdd.ImageMargins.Left := 4;
    FbtnAdd.ImageMargins.Bottom := 4;
    FbtnAdd.ImageMargins.Right := 4;
    FbtnAdd.ImageMargins.Top := 4;
    FbtnAdd.Width := FbtnAdd.Height + 16;
  end
  else
  begin
    FbtnAdd.OnClick := OnAddClick;
    FbtnAdd.Width := FbtnAdd.Height;
  end;
end;

procedure TVCLEntityFieldEditor.DoDeinit;
begin
  inherited;
  FSelectButton.Text := '';
  FSelectButton.Enabled := False;
  FbtnAdd.Visible := True; // todo: create option
end;

type
  TWinControlAccess = class(TWinControl);

procedure TVCLEntityFieldEditor.OnActionMenuSelected(Sender: TObject);
var
  vMenuItem: TMenuItem;
  vSelectedIndex: Integer;
begin
  vMenuItem := TMenuItem(Sender);

  vSelectedIndex := vMenuItem.MenuIndex;

  Assert(vSelectedIndex >= 0, 'Выбран неизвестный пункт меню');
  if Assigned(FButtonView) then
  begin
    TEntity(FButtonView.DomainObject)._SetFieldValue(nil, 'SelectedIndex', vSelectedIndex);
    FUIBuilder.LastArea := Self;
    ExecuteUIAction(FButtonView);
  end;
end;

procedure TVCLEntityFieldEditor.ClosePopup;
begin
  if PopupShowing and (not Focused) and (FSelectPopup.InvokedBy = FControl) then
    FSelectPopup.Close;
end;

procedure TVCLEntityFieldEditor.DoAdd(const ACollectionIndex: Integer);
var
  vSaved: Boolean;
  vInteractor: TInteractor;
begin
  vInteractor := TInteractor(FView.Interactor);
  vSaved := vInteractor.AtomicEditEntity(
    function(const AHolder: TObject): TView
    var
      vEntity: TEntity;
      vCollectionName: string;
    begin
      vCollectionName := TDefinition(TEntityFieldDef(FFieldDef).ContentDefinitions[ACollectionIndex]).Name;
      vEntity := TDomain(TInteractor(FView.Interactor).Domain).CreateNewEntity(AHolder, vCollectionName, cNewID,
        FView.ExtractEntityField);
      TEntity(FView.ParentDomainObject)._SetFieldEntity(TChangeHolder(AHolder), FFieldDef.Name, vEntity);
      Result := FView;
    end, nil { RETHINK: , Holder - это вызывало перенос изменений в родительский холдер } );

  if vSaved then
    PostMessage(TWinControl(FControl).Handle, WM_NEXTDLGCTL, 0, 0) // нам нужен именно переход к следующему
end;

procedure TVCLEntityFieldEditor.DoEdit;
var
  vEntity: TEntity;
begin
  vEntity := TEntity(FView.DomainObject);
  if not Assigned(vEntity) then
    Exit;

  SetFocused(True);

  TInteractor(Interactor).AtomicEditEntity(FView, Holder);
end;

procedure TVCLEntityFieldEditor.FillEditor;
var
  vEntity: TEntity;
  vDefinition: TDefinition;
begin
  inherited;

  vEntity := TEntity(FView.FieldEntity);
  vDefinition := TDefinition(TObjectFieldDef(FView.Definition).ContentDefinitions[0]);

  with FSelectButton do
  begin
    if not Assigned(vEntity) then
      Text := GetTranslation(vDefinition, tpEmptyValue)
    else
      Text := vEntity['Name'];
    Hint := Text;
  end;

  UpdateVisibility;

  FbtnAdd.Visible := (FView.State = vsFullAccess) and not Assigned(vEntity) and (not vDefinition.HasFlag(ccSystem));
  FbtnAdd.Enabled := FbtnAdd.Visible;
  // todo: create option
end;

procedure TVCLEntityFieldEditor.FocusedChanged(const AFocused: Boolean);
begin
  inherited;
  ClosePopup;
end;

function TVCLEntityFieldEditor.GetDisabledBorderStyle: TBorderStyle;
begin
  if StrToBoolDef(TDomain(TInteractor(FView.Interactor).Domain).UserSettings.GetValue('Core', 'ShowBordersForDisabled'), True) then
    Result := bsSingle
  else
    Result := bsNone;
end;

procedure TVCLEntityFieldEditor.OnAddClick(Sender: TObject);
begin
  SetFocused(True);
  if Assigned(FButtonView) then
  begin
    TEntity(FButtonView.DomainObject)._SetFieldValue(nil, 'SelectedIndex', 0);
    FUIBuilder.LastArea := Self;
    ExecuteUIAction(FButtonView);
  end;
end;

procedure TVCLEntityFieldEditor.OnEntitySelected(const ANewEntity: TEntity);
begin
  if PopupShowing then
    SetFieldEntity(ANewEntity);

  ClosePopup;
  PostMessage(TWinControl(TWinControl(FControl).Parent).Handle, WM_NEXTDLGCTL, 0, 0);
end;

procedure TVCLEntityFieldEditor.DoOnClose(Sender: TObject);
begin
  if FSelectButton.CanFocus then
    FSelectButton.SetFocus;
end;

procedure TVCLEntityFieldEditor.OnSelectClick(Sender: TObject);
begin
  if PopupShowing and (FSelectPopup.InvokedBy = FControl) then
    FSelectPopup.Close
  else
  begin
    SetFocused(True);
    ShowPopup('');
  end;
end;

procedure TVCLEntityFieldEditor.OnWinControlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
  begin
    if PopupShowing then
      // ClosePopup // иначе при поиске нельзя использовать пробел
    else
      ShowPopup('');
  end
  else if Key = VK_ESCAPE then
  begin
    if PopupShowing then
      ClosePopup
  end
  else if Key = VK_F2 then
  begin
    // if FbtnAdd.Enabled then
    // DoAdd(0);
  end
  else if Key = VK_F3 then
  begin
    // if FbtnEdit.Enabled then
    // DoEdit;
  end
  else if Key = VK_DOWN then
    ShowPopup('')
  else if IsAlpha(Char(Key)) then
    ShowPopup(VKeytoWideString(Key))
  else if Key = VK_RETURN then

  else if Key in [VK_PRIOR, VK_NEXT] then
    ClosePopup;
end;

function TVCLEntityFieldEditor.PopupShowing: Boolean;
begin
  Result := Assigned(FSelectPopup) and FSelectPopup.Form.Visible;
end;

procedure TVCLEntityFieldEditor.SetFocused(const Value: Boolean);
begin
  inherited;
  if Value and FSelectButton.CanFocus then
    FSelectButton.SetFocus;
end;

procedure TVCLEntityFieldEditor.ShowPopup(const AFilter: string);
var
  vInteractor: TInteractor;
  vPrevCursor: TCursorType;
  vField: TEntityField;
  vEntity: TEntity;
begin
  vEntity := TEntity(FView.FieldEntity);
  vInteractor := TInteractor(FView.Interactor);

  if FEntities = nil then
    FEntities := TEntityList.Create(vInteractor.Domain, vInteractor.Session);

  vPrevCursor := TVCLPresenter(vInteractor.Presenter).SetCursor(crtHourGlass);
  try
    vField := FView.ExtractEntityField;
    vField.GetEntitiesForSelect(TInteractor(FView.Interactor).Session, FEntities);

    if FSelectPopup = nil then
    begin
      FSelectPopup := TSelectEntityPopup.Create(TInteractor(FView.Interactor));
      FSelectPopup.OnClose := DoOnClose;
      FSelectPopup.OnEntitySelected := OnEntitySelected;
    end;

    FSelectPopup.Init(FEntities, True, vEntity, AFilter);
    FSelectPopup.ShowFor(TWinControl(FControl), '');
  finally
    TVCLPresenter(vInteractor.Presenter).SetCursor(vPrevCursor)
  end;
end;

procedure TVCLEntityFieldEditor.UpdateVisibility;
begin
  if (FView.State < vsSelectOnly) then
  begin
    FSelectButton.Visible := False;

    FEdit.Visible := True;
    FEdit.Text := FSelectButton.Text;
    FEdit.BorderStyle := GetDisabledBorderStyle;
  end
  else
  begin
    FEdit.Visible := False;

    FSelectButton.OnClick := OnSelectClick;
    FSelectButton.Visible := True;
  end;
end;

{ TListEntityFieldEditor }

procedure TListEntityFieldEditor.DoBeforeFreeControl;
begin
  inherited;
  FreeAndNil(FEntities);
end;

procedure TListEntityFieldEditor.DoCreateControl(const AParent: TUIArea; const ALayout: TObject);
begin
  FGrid := TTreeView.Create(nil);
  FGrid.OnDblClick := OnDblClick;
  FGrid.OnClick := DoOnFocusedNodeChanged;
  FGrid.ShowRoot := False;
  FGrid.HideSelection := False;
  FGrid.MultiSelect := False;

  FControl := FGrid;
end;

procedure TListEntityFieldEditor.DoOnFocusedNodeChanged(Sender: TObject);
begin
  if Assigned(FGrid.Selected) then
    SetFieldEntity(TEntity(FGrid.Selected.Data));
end;

procedure TListEntityFieldEditor.FillEditor;
var
  vField: TEntityField;
  vPrevCursor: TCursor;
  vInteractor: TInteractor;
begin
  if not Assigned(FView.FieldEntity) then
    Exit;

  if Assigned(FEntities) then
    Exit;

  vInteractor := TInteractor(FView.Interactor);
  FEntities := TEntityList.Create(vInteractor.Domain, vInteractor.Session);

  vPrevCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    vField := FView.ExtractEntityField;
    vField.GetEntitiesForSelect(vInteractor.Session, FEntities);
    Reload;
  finally
    Screen.Cursor := vPrevCursor;
  end;
end;

procedure TListEntityFieldEditor.OnDblClick(Sender: TObject);
begin

end;

procedure TListEntityFieldEditor.Reload;
var
  i: Integer;
  vNode, vSelectedNode: TTreeNode;
  vCurrEntity: TEntity;
begin
  vCurrEntity := nil;
  vSelectedNode := nil;
  if Assigned(FGrid.Selected) then
    vCurrEntity := TEntity(FGrid.Selected.Data);

  FGrid.Items.BeginUpdate;
  try
    FGrid.Items.Clear;
    for i := 0 to FEntities.Count - 1 do
    begin
      vNode := TTreeNode.Create(FGrid.Items);
      vNode.Data := FEntities[i];
      vNode.Text := SafeDisplayName(FEntities[i]);
      if vNode.Data = vCurrEntity then
      begin
        vNode.Selected := True;
        vNode.Focused := True;
        vSelectedNode := vNode;
      end;
    end;
  finally
    FGrid.Items.EndUpdate;
    if Assigned(vSelectedNode) then
      vSelectedNode.MakeVisible;
  end;
end;

{ TVCLLinkedEntityFieldEditor }

procedure TVCLLinkedEntityFieldEditor.DoBeforeFreeControl;
begin
  inherited DoBeforeFreeControl;
  FreeAndNil(FLabel);
end;

procedure TVCLLinkedEntityFieldEditor.OnLabelClick(Sender: TObject);
var
  vInteractor: TInteractor;
begin
  vInteractor := TInteractor(FView.Interactor);
  vInteractor.ViewEntity(FView);
end;

procedure TVCLLinkedEntityFieldEditor.UpdateVisibility;
var
  vEntity: TEntity;
begin
  vEntity := TEntity(FView.FieldEntity);

  if (FView.State = vsSelectOnly) and Assigned(vEntity) and not vEntity.IsNew then
  begin
    FSelectButton.Visible := False;
    FEdit.Visible := False;

    if not Assigned(FLabel) then
    begin
      FLabel := TLabel.Create(nil);
      FLabel.Align := alClient;
      FLabel.Parent := FBasePanel;
      FLabel.Font.Color := clBlue;
      FLabel.Font.Style := [fsUnderline];
      FLabel.Cursor := crHandPoint;
      FLabel.Transparent := True;
      FLabel.OnClick := OnLabelClick;
    end
    else
      FLabel.Visible := True;
    FLabel.Caption := FSelectButton.Text;
  end
  else if (FView.State < vsSelectOnly) then
  begin
    FSelectButton.Visible := False;
    if Assigned(FLabel) then
      FLabel.Visible := False;

    FEdit.Visible := True;
    FEdit.Text := FSelectButton.Text;
  end
  else
  begin
    FEdit.Visible := False;
    if Assigned(FLabel) then
      FLabel.Visible := False;

    FSelectButton.Visible := True;
    FSelectButton.OnClick := OnSelectClick;
  end;
end;

{ TVCLEntitySelector }

procedure TVCLEntitySelector.CBOnInitPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  FillList;
end;

procedure TVCLEntitySelector.DoBeforeFreeControl;
begin
  FreeAndNil(FEntities);
end;

procedure TVCLEntitySelector.DoCreateControl(const AParent: TUIArea; const ALayout: TObject);
var
  vInteractor: TInteractor;
begin
  vInteractor := TInteractor(FView.Interactor);
  FEntities := TEntityList.Create(vInteractor.Domain, vInteractor.Session);

  FControl := TComboBox.Create(nil);
  TComboBox(FControl).Style := csDropDownList;
  TComboBox(FControl).OnContextPopup := CBOnInitPopup;

  if Assigned(ALayout) then
    FFlat := (TPanel(ALayout).BevelOuter = bvNone) and (TPanel(ALayout).BevelInner = bvNone) and
      (TPanel(ALayout).BevelKind = TBevelKind.bkNone);
end;

procedure TVCLEntitySelector.DoOnChange;
var
  vEntity: TEntity;
begin
  vEntity := TEntity(TComboBox(FControl).Items.Objects[TComboBox(FControl).ItemIndex]);
  if Assigned(vEntity) then
    SetFieldEntity(vEntity);
end;

procedure TVCLEntitySelector.FillEditor;
var
  vEdit: TComboBox;
  vEntity: TEntity;
begin
  FillList;

  vEdit := TComboBox(FControl);
  vEntity := FView.FieldEntity;
  if Assigned(vEntity) then
  begin
    vEdit.Text := vEntity['Name'];
    vEdit.Enabled := True;
    // vEdit.ReadOnly := FView.State < vsSelectOnly;
    //
    // if vEdit.Properties.ReadOnly then
    // begin
    // vEdit.TabStop := False;
    // end
    // else begin
    // if FFlat then begin
    // vEdit.ParentColor := True;
    // end
    // else
    // vEdit.TabStop := True;
    // end;
  end
  else
  begin
    vEdit.Text := '';
    vEdit.Enabled := False;
  end;
end;

procedure TVCLEntitySelector.FillList;
var
  vField: TEntityField;
  vEntity: TEntity;
begin
  TComboBox(FControl).Items.BeginUpdate;
  try
    TComboBox(FControl).Items.Clear;
    vField := FView.ExtractEntityField;
    vField.GetEntitiesForSelect(TInteractor(FView.Interactor).Session, FEntities);
    for vEntity in FEntities do
      TComboBox(FControl).Items.AddObject(SafeDisplayName(vEntity), vEntity);
  finally
    TComboBox(FControl).Items.EndUpdate;
  end;
end;

procedure TVCLEntitySelector.SwitchChangeHandlers(const AHandler: TNotifyEvent);
begin
  inherited;
  if Assigned(TComboBox(FControl)) then
    TComboBox(FControl).OnChange := AHandler;
end;

{ TEntityFieldListEditor }

//procedure TEntityFieldListEditor.CleanChildViews;
//var
//  vChildView: TView;
//begin
//  if Assigned(FView) then
//    for vChildView in FChildViews do
//      vChildView.RemoveListener(Self);
//end;
//
//function TEntityFieldListEditor.CreateCategoryRow(const ARootEntity: TEntity; const AFieldDef: TFieldDef)
//  : TcxCategoryRow;
//begin
//  Result := TcxCategoryRow(FEditor.Add(TcxCategoryRow));
//  Result.Properties.Caption := GetFieldTranslation(AFieldDef);
//  Result.Tag := Integer(TRowData.Create(ARootEntity, AFieldDef));
//end;
//
//function TEntityFieldListEditor.CreateEditRow(const ARootEntity: TEntity; const AFieldDef: TFieldDef;
//const AViewPath: string; const AOverriddenCaption: string = ''): TcxEditorRow;
//var
//  vFieldView: TView;
//  vStyleName: string;
//begin
//  Result := TcxEditorRow(FEditor.Add(TcxEditorRow));
//  vStyleName := GetUrlCommand(AFieldDef.StyleName);
//  if AOverriddenCaption = '' then
//    Result.Properties.Caption := GetFieldTranslation(AFieldDef)
//  else
//    Result.Properties.Caption := AOverriddenCaption;
//
//  Result.Tag := Integer(TRowData.Create(ARootEntity, AFieldDef));
//
//  Result.Properties.EditPropertiesClassName := 'TcxTextEditProperties';
//  case AFieldDef.Kind of
//    fkNotDefined:
//      ;
//    fkString:
//      ;
//    fkInteger:
//      Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
//    fkEnum:
//      ;
//    fkFlag:
//      ;
//    fkFloat:
//      begin
//        Result.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
//        TcxSpinEditProperties(Result.Properties.EditProperties).ValueType := vtFloat;
//        if vStyleName = 'formatted' then
//          TcxSpinEditProperties(Result.Properties.EditProperties).DisplayFormat :=
//            GetUrlParam(AFieldDef.StyleName, 'format');
//      end;
//    fkDateTime:
//      begin
//        Result.Properties.EditPropertiesClassName := 'TcxDateEditProperties';
//        if AFieldDef.StyleName = 'datetime' then
//          TcxDateEditProperties(Result.Properties.EditProperties).Kind := ckDateTime;
//      end;
//    fkBoolean:
//      Result.Properties.EditPropertiesClassName := 'TcxCheckBoxProperties';
//    fkColor:
//      Result.Properties.EditPropertiesClassName := 'TdxColorEditProperties';
//    fkCurrency:
//      ;
//    fkObject:
//      Result.Properties.EditPropertiesClassName := 'TcxComboBoxProperties';
//    fkList:
//      ;
//    fkBlob:
//      ;
//    fkComplex:
//      ;
//  end;
//
//  vFieldView := FView.BuildView(AViewPath + AFieldDef.Name);
//  vFieldView.AddListener(Self);
//  FChildViews.Add(vFieldView);
//  Result.Properties.EditProperties.ReadOnly := vFieldView.State < vsSelectOnly;
//
//  if Result.Properties.EditProperties.ReadOnly then
//    Result.Properties.Options.ShowEditButtons := eisbNever
//  else
//    Result.Properties.EditProperties.OnChange := OnFieldChange;
//
//end;
//
//procedure TEntityFieldListEditor.CreateRows(const ARootEntity: TEntity; const ARootRow: TcxCustomRow;
//const AViewPath: string; const ARootEntityIndex: Integer = -1);
//var
//  vFieldDef: TFieldDef;
//  vListField: TListField;
//  vCategory: TcxCategoryRow;
//  i: Integer;
//begin
//  if ARootEntity = nil then
//    Exit;
//
//  for vFieldDef in ARootEntity.Definition.Fields do
//  begin
//    if Assigned(FDisplayFields) then
//    begin
//      if FDisplayFields.IndexOf(vFieldDef.Name) < 0 then
//        Continue;
//    end;
//
//    if vFieldDef.Kind = fkList then
//    begin
//      vListField := TListField(ARootEntity.FieldByName(vFieldDef.Name));
//      if vListField.Count > 0 then
//      begin
//        vCategory := CreateCategoryRow(ARootEntity, vFieldDef);
//        vCategory.Parent := ARootRow;
//        for i := 0 to vListField.Count - 1 do
//          CreateRows(vListField[i], vCategory, vFieldDef.Name + '/' + IntToStr(i) + '/', i);
//      end;
//    end
//    else
//    begin
//      if TInteractor(FView.Interactor).NeedSkipColumn(ARootEntity, vFieldDef) or vFieldDef.HasFlag(cHideInEdit) then
//        Continue;
//      CreateEditRow(ARootEntity, vFieldDef, AViewPath, GetFieldTranslation(vFieldDef) + ' ' +
//        IfThen(ARootEntityIndex > -1, IntToStr(ARootEntityIndex + 1))).Parent := ARootRow;
//    end;
//  end;
//end;
//
//procedure TEntityFieldListEditor.DoBeforeFreeControl;
//begin
//  inherited;
//  FreeAndNil(FDisplayFields);
//  FreeEditors;
//  FreeAndNil(FChildViews);
//end;
//
//procedure TEntityFieldListEditor.DoCreateControl(const AParent: TUIArea; const ALayout: TObject);
//begin
//  FEditor := TcxVerticalGrid.Create(nil);
//  FEditor.OptionsView.ShowEditButtons := ecsbFocused;
//  FEditor.OptionsView.PaintStyle := psDelphi;
//  FEditor.BorderStyle := cxcbsNone;
//
//  FControl := FEditor;
//
//  FChildViews := TList<TView>.Create;
//
//  if Assigned(FCreateParams) then
//    FEditor.OptionsView.RowHeaderWidth := StrToIntDef(FCreateParams.Values['headerWidth'], 150)
//  else
//    FEditor.OptionsView.RowHeaderWidth := 150;
//
//  if FCreateParams.IndexOfName('Fields') > 0 then
//  begin
//    FDisplayFields := TStringList.Create;
//    FDisplayFields.StrictDelimiter := True;
//    FDisplayFields.Delimiter := ',';
//    FDisplayFields.DelimitedText := FCreateParams.Values['Fields'];
//  end;
//end;
//
//procedure TEntityFieldListEditor.DoDisableContent;
//begin
//  CleanChildViews;
//end;
//
//procedure TEntityFieldListEditor.FillEditor;
//var
//  i, j: Integer;
//  vRow: TcxEditorRow;
//  vFieldDef: TFieldDef;
//  vEntityField: TEntityField;
//  vEntities: TEntityList;
//  vInteractor: TInteractor;
//  vLevelEntity: TEntity;
//begin
//  FEditor.BeginUpdate;
//
//  try
//    FDomainObject := TEntity(FView.DomainObject);
//    FreeEditors;
//    CreateRows(FDomainObject, nil, '');
//
//    vInteractor := TInteractor(FView.Interactor);
//    for i := 0 to FEditor.Rows.Count - 1 do
//    begin
//      if FEditor.Rows[i] is TcxCategoryRow then
//        Continue;
//
//      vRow := TcxEditorRow(FEditor.Rows[i]);
//      vFieldDef := TRowData(vRow.Tag).FieldDef;
//      vLevelEntity := TRowData(vRow.Tag).Entity;
//
//      case vFieldDef.Kind of
//        { fkNotDefined: ;
//          fkString: ;
//          fkInteger: vRow.Properties.EditPropertiesClassName := 'TcxSpinEditProperties';
//          fkEnum: ;
//          fkFlag: ;
//          fkFloat: ;
//          fkDateTime: vRow.Properties.EditPropertiesClassName := 'TcxDateEditProperties';
//          fkBoolean: vRow.Properties.EditPropertiesClassName := 'TcxCheckBoxProperties';
//          fkColor: vRow.Properties.EditPropertiesClassName := 'TdxColorEditProperties';
//          fkCurrency: ; }
//        fkObject:
//          begin
//            if vRow.Properties.DataBinding.Data = nil then
//            begin
//              vEntities := TEntityList.Create(vInteractor.Domain, vInteractor.Session);
//              vRow.Properties.DataBinding.Data := vEntities;
//            end
//            else
//              vEntities := TEntityList(vRow.Properties.DataBinding.Data);
//
//            vEntityField := TEntityField(vLevelEntity.FieldByName(vFieldDef.Name));
//
//            vEntityField.GetEntitiesForSelect(vInteractor.Session, vEntities);
//
//            TcxComboBoxProperties(vRow.Properties.EditProperties).Items.Clear;
//            for j := 0 to vEntities.Count - 1 do
//            begin
//              TcxComboBoxProperties(vRow.Properties.EditProperties).Items.AddObject(SafeDisplayName(vEntities[j]),
//                vEntities[j]);
//              if vEntities[j] = vEntityField.Entity then
//                vRow.Properties.Value := vEntityField.Entity.DisplayName;
//            end;
//          end;
//        fkList:
//          begin
//            // vList := vLevelEntity.GetFieldList(vFieldDef.Name);
//          end;
//        { fkBlob: ;
//          fkComplex: ; }
//      else
//        vRow.Properties.Value := vLevelEntity.FieldByName(vFieldDef.Name).Value;
//      end;
//    end;
//  finally
//    FEditor.EndUpdate;
//  end;
//end;
//
//procedure TEntityFieldListEditor.FreeEditors;
//var
//  i: Integer;
//  vRow: TcxEditorRow;
//begin
//  for i := 0 to FEditor.Rows.Count - 1 do
//  begin
//    if FEditor.Rows[i] is TcxEditorRow then
//    begin
//      vRow := TcxEditorRow(FEditor.Rows[i]);
//      if TRowData(vRow.Tag).FieldDef.Kind = fkObject then
//      begin
//        TEntityList(vRow.Properties.DataBinding.Data).Free;
//        vRow.Properties.DataBinding.Data := nil;
//      end;
//      TcxEditorRow(FEditor.Rows[i]).Properties.EditProperties.OnChange := nil;
//    end;
//    TRowData(TcxCustomRow(FEditor.Rows[i]).Tag).Free;
//  end;
//  FEditor.ClearRows;
//end;
//
//procedure TEntityFieldListEditor.RefillArea(const AKind: Word);
//var
//  vEntity: TEntity;
//begin
//  vEntity := TEntity(FView.ParentDomainObject);
//  if not Assigned(vEntity) then
//    Exit;
//
//  try
//    SwitchChangeHandlers(nil);
//    if not Assigned(FView.ParentDomainObject) then
//      DoDeinit
//    else if (AKind <> dckViewStateChanged) and (AKind <> dckNameChanged) then
//      FillEditor;
//
//    SwitchChangeHandlers(OnChange);
//  except
//    TInteractor(FView.Interactor).ShowMessage('Error in FillEditorFromModel, Field: ' + FFieldDef.Name);
//  end;
//end;
//
//procedure TEntityFieldListEditor.OnFieldChange(Sender: TObject);
//var
//  vEditor: TCustomEdit;
//  vRow: TcxCustomRow;
//  vFieldDef: TFieldDef;
//  vValue: Variant;
//  vEntity, vLevelEntity: TEntity;
//  vIndex: Integer;
//begin
//  vEditor := TCustomEdit(Sender);
//  vRow := TcxCustomVerticalGrid(vEditor.Parent).FocusedRow;
//  if vRow is TcxEditorRow then
//  begin
//    vFieldDef := TRowData(TcxEditorRow(vRow).Tag).FieldDef;
//    vLevelEntity := TRowData(TcxEditorRow(vRow).Tag).Entity;
//
//    vValue := Variant(vEditor.Text);
//    case vFieldDef.Kind of
//      fkNotDefined:
//        ;
//      fkString:
//        ;
//      fkInteger:
//        ;
//      fkEnum:
//        ;
//      fkFlag:
//        ;
//      fkFloat:
//        vValue := Double(vValue);
//      fkDateTime:
//        ;
//      fkBoolean:
//        ;
//      fkColor:
//        vValue := Integer(vValue);
//      fkCurrency:
//        ;
//      fkObject:
//        begin
//          vIndex := TcxComboBoxProperties(TcxEditorRow(vRow).Properties.EditProperties).Items.IndexOf(vValue);
//          if vIndex > -1 then
//          begin
//            vEntity := TEntity(TcxComboBoxProperties(TcxEditorRow(vRow).Properties.EditProperties)
//              .Items.Objects[vIndex]);
//
//            TUserSession(FView.Session).DomainWrite(
//              procedure
//              begin
//                vLevelEntity._SetFieldEntity(TChangeHolder(Holder), vFieldDef.Name, vEntity);
//              end);
//          end;
//
//          Exit;
//        end;
//      fkList:
//        ;
//      fkBlob:
//        ;
//      fkComplex:
//        ;
//    end;
//
//    TUserSession(FView.Session).DomainWrite(
//      procedure
//      begin
//        vLevelEntity._SetFieldValue(TChangeHolder(Holder), vFieldDef.Name, vValue);
//      end);
//  end;
//end;

{ TRowData }

constructor TRowData.Create(const AEntity: TEntity; const AFieldDef: TFieldDef);
begin
  Entity := AEntity;
  FieldDef := AFieldDef;
end;

{ TRadioEntitySelector }

procedure TRadioEntitySelector.DoBeforeFreeControl;
begin
  inherited;
  FreeAndNil(FEntities);
end;

procedure TRadioEntitySelector.DoCreateControl(const AParent: TUIArea; const ALayout: TObject);
begin
  FControl := TRadioGroup.Create(nil);
  TRadioGroup(FControl).Name := 'radio';
  TRadioGroup(FControl).Caption := '';
  FNeedCreateCaption := False;

  FEntities := TEntityList.Create(TInteractor(FView.Interactor).Domain, TInteractor(FView.Interactor).Session);
end;

procedure TRadioEntitySelector.DoOnChange;
var
  vIndex: Integer;
begin
  vIndex := TRadioGroup(FControl).ItemIndex;
  SetFieldEntity(FEntities[vIndex]);
end;

procedure TRadioEntitySelector.FillEditor;
var
  vRadioEdit: TRadioGroup;
begin
  FillList;

  vRadioEdit := TRadioGroup(FControl);
  if VarIsNull(FView.FieldValue) or (FView.FieldValue = 0) then
  begin
    // do nothing
  end
  else
  begin
    vRadioEdit.Enabled := not(FView.State < vsSelectOnly);

    if not vRadioEdit.Enabled then
      vRadioEdit.TabStop := False
    else
      vRadioEdit.TabStop := True;
  end;
end;

procedure TRadioEntitySelector.FillList;
var
  vRadioItems: TStrings;
  vField: TEntityField;
  i: Integer;
  vEnt: TEntity;
begin
  vField := FView.ExtractEntityField;
  vField.GetEntitiesForSelect(TInteractor(FView.Interactor).Session, FEntities);

  vRadioItems := TRadioGroup(FControl).Items;
  vRadioItems.BeginUpdate;
  try
    vRadioItems.Clear;
    for i := 0 to FEntities.Count - 1 do
    begin
      vEnt := FEntities[i];
      if Assigned(vEnt) then
      begin
        vRadioItems.AddObject(vEnt.DisplayName, vEnt);
        if vEnt = TEntity(Integer(FView.FieldValue)) then
          TRadioGroup(FControl).ItemIndex := TRadioGroup(FControl).Items.Count - 1;
      end;
      // todo: обработать <не задано> если нужно
    end;
  finally
    vRadioItems.EndUpdate;
  end;
end;

procedure TRadioEntitySelector.SwitchChangeHandlers(const AHandler: TNotifyEvent);
begin
  TRadioGroup(FControl).OnClick := AHandler;
end;

initialization

TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, '', TVCLEntityFieldEditor);
TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, 'list', TListEntityFieldEditor);
TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, 'link', TVCLLinkedEntityFieldEditor);
TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, 'select', TVCLEntitySelector);
// TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, 'fieldlist', TEntityFieldListEditor);
TPresenter.RegisterUIClass('Windows.VCL', uiEntityEdit, 'radio', TRadioEntitySelector);

end.
