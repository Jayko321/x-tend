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

unit AboutVclForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Menus, StdCtrls, ImgList, CheckLst, uInteractor,
  Vcl.ExtCtrls;

type
  TAboutVclFm = class(TForm)
    lblVersion: TLabel;
    btnOk: TButton;
    btnFeedback: TButton;
    lblCopyright: TLabel;
    Image1: TImage;
    lblName: TLabel;
    lblEmail: TLabel;
    lblWeb: TLabel;
    lblAllRightsReserved: TLabel;
    lblSite: TLabel;
    lblMail: TLabel;
    procedure lblSiteClick(Sender: TObject);
    procedure lblMailClick(Sender: TObject);
  private
    FInteractor: TInteractor;
    procedure Init(const AInteractor: TInteractor);
  public
    class procedure ShowAbout(const AInteractor: TInteractor);
  end;

implementation

{$R *.dfm}

uses
  uConfiguration, uPresenter;

procedure TAboutVclFm.Init(const AInteractor: TInteractor);
begin
  FInteractor := AInteractor;
  if not Assigned(FInteractor) then
    Exit;
  Caption := AInteractor.Translate('@' + Self.ClassName + '@Caption', 'О программе');
  lblName.Caption := AInteractor.AppTitle;
  lblVersion.Caption := AInteractor.Translate('@' + Self.ClassName + '.lblVersion@Caption', 'Версия') + ': ' +
    TConfiguration(AInteractor.Configuration).Version;
  lblWeb.Caption := AInteractor.Translate('@' + Self.ClassName + '.lblWeb@Caption', 'Сайт') + ': ';
  lblAllRightsReserved.Caption := AInteractor.Translate('@' + Self.ClassName + '.lblAllRightsReserved@Caption',
    'Все права защищены') + '.';
  btnFeedback.Caption := AInteractor.Translate('@' + Self.ClassName + '.btnFeedback@Caption', 'Обратная связь');
  btnOk.Caption := AInteractor.Translate('@btnOk@Caption', 'Ок');
end;

procedure TAboutVclFm.lblMailClick(Sender: TObject);
begin
  TPresenter(FInteractor.Presenter).OpenFile('mailto:' + lblMail.Caption);
end;

procedure TAboutVclFm.lblSiteClick(Sender: TObject);
begin
  TPresenter(FInteractor.Presenter).OpenFile(lblSite.Caption);
end;

class procedure TAboutVclFm.ShowAbout(const AInteractor: TInteractor);
var
  vForm: TAboutVclFm;
begin
  Application.CreateForm(TAboutVclFm, vForm);
  vForm.Init(AInteractor);
  vForm.ShowModal;
  vForm.Free;
end;

end.
