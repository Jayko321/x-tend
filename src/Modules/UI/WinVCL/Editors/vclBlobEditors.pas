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

unit vclBlobEditors;

interface

uses
  uUIBuilder, vclArea, uScene, uSimpleChart;

type
  TFieldSceneArea = class(TVCLFieldArea)
  protected
    FScene: TScene;
    function DoCreateControl(const AParent: TUIArea; const ALayout: TObject): TObject; override;
    procedure DoDisableContent; override;
    procedure DoBeforeFreeControl; override;
    procedure FillEditor; override;
    procedure RefillArea(const AKind: Word); override;
  end;

  TFieldChartArea = class(TFieldSceneArea)
  protected
    FChart: TSimpleChart;
    function DoCreateControl(const AParent: TUIArea; const ALayout: TObject): TObject; override;
  end;

implementation

uses
  uPLatform, uDomain, uDrawStyles, uWinScene, uPresenter, uConfiguration, uConsts;

{ TFieldSceneArea }

procedure TFieldSceneArea.DoBeforeFreeControl;
begin
  FScene.Free;
end;

function TFieldSceneArea.DoCreateControl(const AParent: TUIArea; const ALayout: TObject): TObject;
var
  vDomain: TDomain;
  vSceneClass: TSceneClass;
  vModuleName: string;
begin
  vDomain := TDomain(FView.Domain);
  vSceneClass := TSceneClass(_Platform.ResolveModuleClass(vDomain.Settings, 'ChartPainter', 'Painting', vModuleName));
  FScene := vSceneClass.Create(TVCLArea(Parent).Control);
  Result := TWinScene(FScene).Panel;
end;

procedure TFieldSceneArea.DoDisableContent;
begin
  FScene.Disable;
end;

procedure TFieldSceneArea.FillEditor;
begin
  inherited;
  // FView
  // FFieldDef
  // FControl
end;

procedure TFieldSceneArea.RefillArea(const AKind: Word);
begin
  if AKind <> dckNameChanged then
    FScene.Repaint;
end;

{ TFieldChartArea }

function TFieldChartArea.DoCreateControl(const AParent: TUIArea; const ALayout: TObject): TObject;
begin
  Result := inherited DoCreateControl(AParent, ALayout);
  FId := 'Chart';
  FChart := TDataChart.Create(FScene, nil);
end;

initialization

TPresenter.RegisterUIClass('Windows.DevExpress', uiComplexEdit, 'chart', TFieldChartArea);

end.
