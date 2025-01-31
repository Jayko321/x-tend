﻿{---------------------------------------------------------------------------------
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
 ---------------------------------------------------------------------------------}

unit DebugInfoVclForm;

interface

uses
  Winapi.Windows, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls, uInteractor, Vcl.Buttons, Vcl.ComCtrls;

type
  TDebugVclFm = class(TForm)
    pcTabs: TPageControl;
    TabSheet1: TTabSheet;
    memArea: TMemo;
    pnlView: TPanel;
    memView: TMemo;
    spltCommon: TSplitter;
    TabSheet2: TTabSheet;
    memHolders: TMemo;
    memLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UpdateDebugInfo(Sender: TObject);
  private
    FInteractors: TStrings;
  public
    procedure AddInteractor(const AInteractor: TInteractor);
    procedure RemoveInteractor(const AInteractor: TInteractor);

    procedure UpdateHoldersInfo;
    function HoldersInfo(const AInteractor: TInteractor): string;
  end;

implementation

uses
  SysUtils, uConfiguration, uDomain, uSession, uChangeManager;

{$R *.dfm}

{ TForm1 }

procedure TDebugVclFm.AddInteractor(const AInteractor: TInteractor);
begin
  if FInteractors.IndexOfObject(AInteractor) < 0 then
    FInteractors.AddObject(TConfiguration(AInteractor.Configuration).Name, AInteractor);
  UpdateHoldersInfo;
end;

procedure TDebugVclFm.RemoveInteractor(const AInteractor: TInteractor);
var
  vIndex: Integer;
begin
  vIndex := FInteractors.IndexOfObject(AInteractor);
  if vIndex >= 0 then
    FInteractors.Delete(vIndex);
  UpdateHoldersInfo;
end;

procedure TDebugVclFm.FormCreate(Sender: TObject);
begin
  FInteractors := TStringList.Create;
end;

procedure TDebugVclFm.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FInteractors);
end;

procedure TDebugVclFm.UpdateDebugInfo(Sender: TObject);
var
  vInteractor: TInteractor;
  i: Integer;
begin
//if key = VK_F1 then
begin
  memArea.Lines.BeginUpdate;
  memView.Lines.BeginUpdate;
  memHolders.Lines.BeginUpdate;
  memLog.Lines.BeginUpdate;

  try
    memArea.Lines.Text := '';
    memView.Lines.Text := '';
    memHolders.Lines.Text := '';

    for i := 0 to FInteractors.Count - 1 do
    begin
      vInteractor := TInteractor(FInteractors.Objects[i]);
      memArea.Lines.Text := memArea.Lines.Text + AnsiUpperCase(FInteractors[i]) + #13#10#13#10 +
        vInteractor.UIBuilder.RootArea.TextHierarchy('') + #13#10#13#10;

      memView.Lines.Text := memView.Lines.Text + AnsiUpperCase(FInteractors[i]) + #13#10#13#10 +
        vInteractor.UIBuilder.RootView.TextHierarchy('') + #13#10#13#10;

      memHolders.Lines.Text := memHolders.Lines.Text + AnsiUpperCase(FInteractors[i]) + #13#10#13#10 +
        HoldersInfo(vInteractor) + #13#10#13#10;
    end;

    if FInteractors.Count > 0 then
    begin
      memLog.Lines.Assign(TDomain(TInteractor(FInteractors.Objects[0]).Domain).Logger.Lines);
      memLog.SelStart := Length(memLog.Lines.Text);
      memLog.SelLength := 0;
    end
    else
      memLog.Text := '';
  finally
    memArea.Lines.EndUpdate;
    memView.Lines.EndUpdate;
    memHolders.Lines.EndUpdate;
    memLog.Lines.EndUpdate;
  end;

end;
end;

procedure TDebugVclFm.UpdateHoldersInfo;
var
  vInteractor: TInteractor;
  i: Integer;
begin
  memHolders.Lines.BeginUpdate;
  try
    memHolders.Lines.Text := '';
    for i := 0 to FInteractors.Count - 1 do
    begin
      vInteractor := TInteractor(FInteractors.Objects[i]);
      memHolders.Lines.Text := memHolders.Lines.Text + AnsiUpperCase(FInteractors[i]) + #13#10#13#10 +
        HoldersInfo(vInteractor) + #13#10#13#10;
    end;
  finally
    memHolders.Lines.EndUpdate;
  end;
end;

function TDebugVclFm.HoldersInfo(const AInteractor: TInteractor): string;
var
  vSession: TUserSession;
  vHolder: TChangeHolder;
begin
  Result := '';
  vSession := TUserSession(AInteractor.Session);
  try
    for vHolder in vSession.Holders do
    begin
      Result := Result + #13#10#13#10 + 'HOLDER: $' + IntToHex(Integer(vHolder));
      if Assigned(vHolder.ParentHolder) then
        Result := Result + ', parent: $' + IntToHex(Integer(vHolder.ParentHolder));
      Result := Result + vHolder.GetDebugInfo;
    end;
  except
  end;
end;

end.
