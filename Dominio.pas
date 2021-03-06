unit Dominio;

interface

uses
  System.SysUtils, System.Classes,REST.Authenticator.OAuth.WebForm.Win,IdMultipartFormData,
  IdSSLOpenSSL, System.JSON,
  IdIOHandlerSocket, IdIOHandlerStack, IdHTTP, IdIOHandler, IdSSL,system.dateutils;

type
  TAmbiente = (aProducao, aHomologacao);
  TRequestType = (rtLogin, rtGetToken, rtRefreshToken, rtSendFile, rtReadStatusFile);

  TonExecuteRequest = procedure (aRequestType : TRequestType; aResponse : String; aStatusCode : Integer) of object;

const
  URL_homolocacao      = 'https://api.onvio.com.br/dominio/invoice/v3/batches';
  URL_producao         = 'https://api.onvio.com.br/dominio/invoice/v3/batches';
  URL_Auth_homologacao = 'https://auth.thomsonreuters.com/oauth/token';
  URL_Auth_producao    = 'https://auth.thomsonreuters.com/oauth/token';
  URL_IntegrationKey   = 'https://api.onvio.com.br/dominio/integration/v1/activation/enable';

Type TRetornoPadrao = record
      Codigo:integer;
      Mensagem:string;
      Status:string;
      Id:string;
end;

type
  TDTDominio = class(TComponent)
  private
    FHTTP:TIdHTTP;
    FResponse: TJSONObject;
    FClientID: String;
    FClientSecret: String;
    FAmbiente: TAmbiente;
    FonExecuteRequest: TonExecuteRequest;
    FCaminhoArquivoToken: string;
    FDataToken: TDate;
    FHoraToken: TTime;
    FAccessToken: string;
    Fstatus: Boolean;
    FCaminhoLog: string;
    FGravarLog: Boolean;
    FAudience: string;
    FIntegrationKey: string;
    FKeyContabilidade: string;
    procedure SetAmbiente(const Value: TAmbiente);
    procedure SetClientID(const Value: String);
    procedure SetClientSecret(const Value: String);
    procedure SetToken(const Value: String);
    procedure setCaminhoArquivoToken(const Value: string);
    procedure SetDataToken(const Value: TDate);
    procedure SetHoraToken(const Value: TTime);
    procedure SetAccessToken(const Value: string);
    procedure setStatus(const Value: Boolean);
    procedure setCaminhoLog(const Value: string);
    procedure setGravarLog(const Value: Boolean);
    procedure setAuence(const Value: string);
    procedure setIntegrationKey(const Value: string);
    procedure setKeyContabilidade(const Value: string);

  protected

  public
    Retorno:TRetornoPadrao;
    property Response : TJSONObject read FResponse;
    property DataToken:TDate read FDataToken write SetDataToken;
    property HoraToken:TTime read FHoraToken write SetHoraToken;
    property AccessToken: string read FAccessToken write SetAccessToken;
    property Status:Boolean read Fstatus write setStatus;

    procedure OnvioOnRedirectURI(const AURL: string; var DoCloseWebView: boolean);
    function onExecuteRequest(const vEvent : TonExecuteRequest) : TRetornoPadrao;

    function Login : TRetornoPadrao;
    function GetToken:TRetornoPadrao;
    function GetKeyIntegracao:TRetornoPadrao;
    function EnviaXML(CaminhoXML:string;FileID:string):TRetornoPadrao;
    procedure Gravalog(Chave:string;ID:string);
    function StatusFile(const aFileID : String) : TRetornopadrao;
//    function GerarIntegrationKey:TRetornoPadrao;
  published
    property GravarLog:Boolean read FGravarLog write setGravarLog;
    property CaminhoArqLOG:string read FCaminhoLog write setCaminhoLog;
    property ClientSecret: String read FClientSecret write SetClientSecret;
    property ClientID: String read FClientID write SetClientID;
    property Ambiente: TAmbiente read FAmbiente write SetAmbiente;
    property CaminhoArquivoToken:string read FCaminhoArquivoToken write setCaminhoArquivoToken;
    property audience:string read FAudience write setAuence;
    property IntegrationKey:string read FIntegrationKey write setIntegrationKey;
    property KeyContabilidade:string read FKeyContabilidade write setKeyContabilidade;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('DT Inovacao', [TDTDominio]);
end;

{ TDTDominio }

function TDTDominio.StatusFile(const aFileID : String) : TRetornopadrao;
var
aResult : String;
Bearer : String;
FPostFileStream : TIdMultiPartFormDataStream;
sshSocketHandler: TIdSSLIOHandlerSocketOpenSSL;
stat:TJSONObject;
Mensage:TJSONObject;
arq: TextFile;
linha,aResponse: string;
ExpiraData:TDateTime;
const
  USER_AGENT = 'User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36';
  KEEP_ALIVE = 'Keep-Alive';
begin
  if FileExists(FCaminhoArquivoToken + 'token.dm') then
  begin
      AssignFile(arq, FCaminhoArquivoToken + 'token.dm');
      Reset(arq);

      while (not eof(arq)) do
      begin
         readln(arq, linha);

         if Pos('data',linha)<>0 then
         FDataToken := StrToDate(Copy(linha,6));

         if Pos('hora',linha)<>0 then
         HoraToken := strtotime(Copy(linha,6));

         if Pos('audience',linha)<>0 then
         FAudience := Copy(linha,10);

         if Pos('ExpiraData',linha)<>0 then
         ExpiraData := StrToDateTime(Copy(linha,12));

         if Pos('access_token',linha)<>0 then
         FAccessToken := Copy(linha,14);

         if Pos('integrationkey',linha)<>0 then
         FIntegrationKey := Copy(linha,16);
      end;

      CloseFile(arq);
  end else begin
      ExpiraData := IncDay(Now,-5);
  end;

  if (ExpiraData) < (now) then
  begin
        // SE ACCESSTOKEN HOUVER EXPIRADO GERA UM NOVO ACCESSTOKEN
        GetToken;
  end;

  FPostFileStream := TIdMultiPartFormDataStream.Create;

  FHTTP     := TIdHTTP.Create(nil);
  FResponse := TJSONObject.Create;

  FHTTP.Request.Clear;
  FHTTP.Request.Accept      := '*/*';
  FHTTP.Request.ContentType := 'application/json';
  FHTTP.Request.CharSet     := 'utf-8';
  FHTTP.Request.UserAgent   := USER_AGENT;
  FHTTP.Request.Connection  := KEEP_ALIVE;
  FHTTP.Request.AcceptEncoding := 'gzip, deflate, br';
  FHTTP.Request.CustomHeaders.AddValue('x-integration-key',FIntegrationKey);
  FHTTP.Request.CustomHeaders.AddValue('Authorization' , 'Bearer ' + FAccessToken);
  FHTTP.response.CharSet := 'UTF-8';   //in test
  FHTTP.Response.ContentEncoding := 'UTF-8';  //in test
  FHTTP.Response.ContentType := 'text/plain';  //in test

  sshSocketHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
  sshSocketHandler.SSLOptions.SSLVersions := [sslvSSLv23, sslvTLSv1_2];
  FHTTP.IOHandler := sshSocketHandler;

  try
    aResponse := FHTTP.Get(URL_producao + '/'+aFileID);

    aResponse := Utf8ToAnsi(aResponse);
    aResponse := AnsiToUtf8(aResponse);
    aResponse := UTF8Decode(aResponse);
    aResponse := UTF8Encode(aResponse);

    FResponse      := TJSONObject.ParseJSONValue(aResponse) as TJSONObject;


    retorno.Status := TJSONObject(FResponse.GetValue('status')).GetValue('message').Value;
    FStatus        := (retorno.Status = 'Processado');

    if Assigned(FonExecuteRequest) then
      FonExecuteRequest(rtReadStatusFile, retorno.Status, FHTTP.ResponseCode);

    Retorno.Codigo   := FHTTP.ResponseCode;
    Retorno.Mensagem := aResponse;

    if FHTTP.ResponseCode = 401 then
      begin
        FonExecuteRequest(rtSendFile, 'Invalid access token', FHTTP.ResponseCode);

        StatusFile(aFileID);
      end;
  except
    on e : exception do
      begin
        if Assigned(FonExecuteRequest) then
          FonExecuteRequest(rtReadStatusFile, e.Message, FHTTP.ResponseCode)
        else
          raise Exception.Create(e.Message);
      end;
  end;

  FHTTP.Free;
end;

procedure TDTDominio.Gravalog(Chave:string;ID:string);
var
  NomeArquivo: string;
  Arquivo: TextFile;
begin
  if FGravarLog then
  begin
        if not DirectoryExists(ExtractFilePath(FCaminhoLog)) then
           ForceDirectories(ExtractFilePath(FCaminhoLog));

        NomeArquivo := FCaminhoLog;
        AssignFile(Arquivo, NomeArquivo);
        if FileExists(NomeArquivo) then
          Append(arquivo)
        else
          ReWrite(arquivo);
        try
          WriteLn(arquivo, 'Data: '+ DateTimeToStr(Now) + ' Chave: ' + Chave + ' ID: ' + ID);
        finally
          CloseFile(arquivo);
        end;
  end;
end;

function TDTDominio.EnviaXML(CaminhoXML, FileID: string): TRetornoPadrao;
var
  aResult : String;
  Bearer : String;
  FPostFileStream : TIdMultiPartFormDataStream;
  sshSocketHandler: TIdSSLIOHandlerSocketOpenSSL;
  stat:TJSONObject;
  Mensage:TJSONObject;
  arq: TextFile;
  linha: string;
  ExpiraData:TDateTime;
const
  USER_AGENT = 'User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36';
  KEEP_ALIVE = 'Keep-Alive';
begin
  if FileExists(FCaminhoArquivoToken + 'token.dm') then
  begin
      AssignFile(arq, FCaminhoArquivoToken + 'token.dm');
      Reset(arq);

      while (not eof(arq)) do
      begin
         readln(arq, linha);

         if Pos('data',linha)<>0 then
         FDataToken := StrToDate(Copy(linha,6));

         if Pos('hora',linha)<>0 then
         HoraToken := strtotime(Copy(linha,6));

         if Pos('audience',linha)<>0 then
         FAudience := Copy(linha,10);

         if Pos('ExpiraData',linha)<>0 then
         ExpiraData := StrToDateTime(Copy(linha,12));

         if Pos('access_token',linha)<>0 then
         FAccessToken := Copy(linha,14);

         if Pos('integrationkey',linha)<>0 then
         FIntegrationKey := Copy(linha,16);
      end;

      CloseFile(arq);
  end else begin
      ExpiraData := IncDay(Now,-5);
  end;

  if (ExpiraData) < (now) then
  begin
        // SE ACCESSTOKEN HOUVER EXPIRADO GERA UM NOVO ACCESSTOKEN
        GetToken;
  end;

  FPostFileStream := TIdMultiPartFormDataStream.Create;

  try
    FHTTP     := TIdHTTP.Create(nil);
    FResponse := TJSONObject.Create;

    FHTTP.Request.Clear;
    FHTTP.Request.Accept      := '*/*';
    FHTTP.Request.ContentType := 'multipart/form-data';
    FHTTP.Request.CharSet     := 'utf-8';
    FHTTP.Request.UserAgent   := USER_AGENT;
    FHTTP.Request.Connection  := KEEP_ALIVE;
    FHTTP.Request.AcceptEncoding := 'gzip, deflate, br';
    FHTTP.Request.CustomHeaders.AddValue('x-integration-key',FIntegrationKey);
    FHTTP.Request.CustomHeaders.AddValue('Authorization' , 'Bearer ' + FAccessToken);

    sshSocketHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
    sshSocketHandler.SSLOptions.SSLVersions := [sslvSSLv23, sslvTLSv1_2];
    FHTTP.IOHandler := sshSocketHandler;

    FPostFileStream := TIdMultiPartFormDataStream.Create;

    FPostFileStream.AddFile('file[]', CaminhoXML, 'application/xml');
    FPostFileStream.AddFormField('query', '{"boxe/File": true}', 'UTF-8', 'application/json');

    try
      try
        aResult   := FHTTP.Post(URL_producao, FPostFileStream);
        FResponse := TJSONObject.ParseJSONValue(aResult) as TJSONObject;
        stat      := FResponse.GetValue<TJSONObject>('status') as TJSONObject;

        case FHTTP.ResponseCode of
              201 :
              begin
                FileID           := FResponse.GetValue('id').Value;
                Retorno.Id       := FileID;
                Retorno.Codigo   := FHTTP.ResponseCode;
                Retorno.Mensagem := stat.GetValue('message').Value;

                Gravalog(ExtractFileName(CaminhoXML),FileID);

                FStatus := True;
              end;

              400 :
              begin
                  Retorno.Codigo   := FHTTP.ResponseCode;
                  Retorno.Mensagem := stat.GetValue('message').Value;
              end;

              401 :
              begin
                Retorno.Codigo   := FHTTP.ResponseCode;
                Retorno.Mensagem := stat.GetValue('message').Value;

                FStatus := false;
              end;

              404 :
              begin
                  Retorno.Codigo   := FHTTP.ResponseCode;
                  Retorno.Mensagem := stat.GetValue('message').Value;
              end;

              500 :
              begin
                  Retorno.Codigo   := FHTTP.ResponseCode;
                  Retorno.Mensagem := stat.GetValue('message').Value;
              end;

          end;
      except
        on e : exception do
          begin
              if E.InheritsFrom(EIdHTTPProtocolException) then
              begin
               Retorno.Mensagem := (E as EIdHTTPProtocolException).ErrorMessage;
               raise Exception.Create((E as EIdHTTPProtocolException).ErrorMessage);
              end else begin
                raise Exception.Create(e.Message);
              end;
          end;
      end;

    finally
      if FStatus = false then
        begin
         // EnviaXML(CaminhoXML, FileID);
        end;
      sshSocketHandler.Free;
    end;

  finally
    if FStatus = false then
    begin
     // EnviaXML(CaminhoXML, FileID);
    end;

    FPostFileStream.Free;
    FHTTP.Free;
  end;
end;

function TDTDominio.GetKeyIntegracao: TRetornoPadrao;
var
vResult : String;
vIntegrationKey, vRefreshToken, vGrant_type, vAudience, vCode : String;
FReqAuthParams : TStringList;
sshSocketHandler: TIdSSLIOHandlerSocketOpenSSL;
arq: TextFile;
linha: string;
ExpiraData:TDateTime;
ExpiraHora:TDateTime;
Data,Hora:string;
SaveStrings: TStringList;
Passou:Boolean;
JsonToSend: TStringStream;
const
  USER_AGENT = 'User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.96 Safari/537.36';
  KEEP_ALIVE = 'Keep-Alive';
begin
  Passou := false;
  if FileExists(FCaminhoArquivoToken + 'token.dm') then
  begin
      AssignFile(arq, FCaminhoArquivoToken + 'token.dm');
      Reset(arq);

      while (not eof(arq)) do
      begin
         readln(arq, linha);

         if Pos('data',linha)<>0 then
         FDataToken := StrToDate(Copy(linha,6));

         if Pos('hora',linha)<>0 then
         HoraToken := strtotime(Copy(linha,6));

         if Pos('audience',linha)<>0 then
         FAudience := Copy(linha,10);

         if Pos('ExpiraData',linha)<>0 then
         ExpiraData := StrToDateTime(Copy(linha,12));

         if Pos('access_token',linha)<>0 then
         FAccessToken := Copy(linha,14);

         if Pos('integrationKey',linha)<>0 then
         FIntegrationKey := Copy(linha,16);
      end;

      CloseFile(arq);
  end else begin
      ExpiraData := IncDay(Now,-5);
  end;

  if (ExpiraData) < (now) then
  begin
        // SE ACCESSTOKEN HOUVER EXPIRADO GERA UM NOVO ACCESSTOKEN
        GetToken;
  end;

  FReqAuthParams := TStringList.Create;

  try
    FHTTP     := TIdHTTP.Create(nil);
    FResponse := TJSONObject.Create;

    FHTTP.Request.Clear;
    FHTTP.Request.ContentType := '*/*';
    FHTTP.Request.CharSet     := 'utf-8';
    FHTTP.Request.UserAgent   := USER_AGENT;
    FHTTP.Request.Connection  := KEEP_ALIVE;
    FHTTP.Request.AcceptEncoding := 'gzip, deflate, br';
    FHTTP.Request.CustomHeaders.AddValue('x-integration-key',FKeyContabilidade);
    FHTTP.Request.CustomHeaders.AddValue('Authorization' , 'Bearer ' + FAccessToken);

    sshSocketHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
    sshSocketHandler.SSLOptions.SSLVersions := [sslvSSLv23, sslvTLSv1_2];
    FHTTP.IOHandler := sshSocketHandler;
    try
        JsonToSend := TStringStream.Create('', TEncoding.UTF8);
        vResult   := FHTTP.Post(URL_IntegrationKey,JsonToSend);
        FResponse := TJSONObject.ParseJSONValue(vResult) as TJSONObject;

        vIntegrationKey := FResponse.GetValue('integrationKey').Value;
        FIntegrationKey := vIntegrationKey;

        Retorno.Codigo   := FHTTP.ResponseCode;
        Retorno.Mensagem := FHTTP.ResponseText;

        try
          SaveStrings := TStringList.Create;

          if FileExists(FCaminhoArquivoToken + 'token.dm') then
          begin
             DeleteFile(FCaminhoArquivoToken + 'token.dm');
          end;

          SaveStrings.Add('access_token='   + FAccessToken);
          SaveStrings.Add('data='           + DateToStr( FDataToken ));
          SaveStrings.Add('ExpiraData='     + DateToStr( ExpiraData ));
          SaveStrings.Add('hora='           + TimeToStr( fhoratoken ));
          SaveStrings.Add('integrationkey=' + FIntegrationKey);

          SaveStrings.SaveToFile(FCaminhoArquivoToken + 'token.dm');
        finally
          FreeAndNil(SaveStrings);
          Passou := True;
        end;
        except on e:Exception do
        begin
          Passou := False;
          Retorno.Codigo   := FHTTP.ResponseCode;
          Retorno.Mensagem := FHTTP.ResponseText;
          if E.InheritsFrom(EIdHTTPProtocolException) then
          begin
           Retorno.Mensagem := (E as EIdHTTPProtocolException).ErrorMessage;
           raise Exception.Create((E as EIdHTTPProtocolException).ErrorMessage);
          end else begin
            raise Exception.Create(e.Message);
          end;
        end;
    end;
  finally
    FReqAuthParams.Free;
    FHTTP.Free;
    JsonToSend.Free;
    if Passou then
    GetToken;
    if Retorno.Codigo = 403 then
    begin

    end;
  end;

end;

function TDTDominio.GetToken: TRetornoPadrao;
var
vResult : String;
vToken, vRefreshToken, vGrant_type, vAudience, vCode : String;

FReqAuthParams : TStringList;
sshSocketHandler: TIdSSLIOHandlerSocketOpenSSL;
arq: TextFile;
linha: string;
ExpiraData:TDateTime;
ExpiraHora:TDateTime;
Data,Hora:string;
SaveStrings: TStringList;
Passou:Boolean;
begin
  Passou := false;
  if FileExists(FCaminhoArquivoToken+ 'token.dm') then
  begin
      AssignFile(arq, FCaminhoArquivoToken + 'token.dm');
      Reset(arq);

      while (not eof(arq)) do
      begin
         readln(arq, linha);

         if Pos('data',linha)<>0 then
         FDataToken := StrToDate(Copy(linha,6));

         if Pos('hora',linha)<>0 then
         HoraToken := strtotime(Copy(linha,6));

         if Pos('audience',linha)<>0 then
         FAudience := Copy(linha,10);

         if Pos('ExpiraData',linha)<>0 then
         ExpiraData := StrToDateTime(Copy(linha,12));

         if Pos('access_token',linha)<>0 then
         FAccessToken := Copy(linha,14);

         if Pos('integrationKey',linha)<>0 then
         FIntegrationKey := Copy(linha,14);
      end;

      CloseFile(arq);
  end else begin
      ExpiraData := IncDay(Now,-5);
  end;

  if (ExpiraData) < (now) then
  begin
        vGrant_type    := 'grant_type=client_credentials' ;
        vAudience      := Concat('audience=',FAudience );

        FReqAuthParams := TStringList.Create;

        try
          FReqAuthParams.Clear;
          FReqAuthParams.Add(vGrant_type);
          FReqAuthParams.Add(vAudience);

          FHTTP     := TIdHTTP.Create(nil);
          FResponse := TJSONObject.Create;

          FHTTP.Request.Clear;
          FHTTP.Request.ContentType         := 'application/x-www-form-urlencoded';
          FHTTP.Request.BasicAuthentication := True;
          FHTTP.Request.Username            := FClientID;
          FHTTP.Request.Password            := FClientSecret;

          sshSocketHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
          sshSocketHandler.SSLOptions.SSLVersions := [sslvSSLv23, sslvTLSv1_2];
          FHTTP.IOHandler := sshSocketHandler;
          try
              vResult   := FHTTP.Post(URL_Auth_producao, FReqAuthParams);
              FResponse := TJSONObject.ParseJSONValue(vResult) as TJSONObject;

              if Assigned(FonExecuteRequest) then
                FonExecuteRequest(rtGetToken, 'Token created', FHTTP.ResponseCode);

              vToken := FResponse.GetValue('access_token').Value;
              FAccessToken := vToken;

              Retorno.Codigo   := FHTTP.ResponseCode;
              Retorno.Mensagem := FHTTP.ResponseText;

              try
                SaveStrings := TStringList.Create;

                if FileExists(FCaminhoArquivoToken + 'token.dm') then
                begin
                   DeleteFile(FCaminhoArquivoToken + 'token.dm');
                end;

                SaveStrings.Add('access_token='   + vToken);
                SaveStrings.Add('data='           + DateToStr(date));
                SaveStrings.Add('ExpiraData='     + DateTimeToStr(IncHour(now,23)));
                SaveStrings.Add('hora='           + TimeToStr( IncHour(now,23)));
                SaveStrings.Add('integrationkey=' + '');

                SaveStrings.SaveToFile(FCaminhoArquivoToken + 'token.dm');
              finally
                FreeAndNil(SaveStrings);
                Passou := True;
              end;
              except on e:Exception do
              begin
                Passou := False;
                Retorno.Codigo   := FHTTP.ResponseCode;
                Retorno.Mensagem := FHTTP.ResponseText;
                raise Exception.Create(e.Message);
              end;
          end;
        finally
          FReqAuthParams.Free;
          FHTTP.Free;
          if Passou then
          GetToken;
          if Retorno.Codigo = 403 then
          begin

          end;
        end;
  end;


end;

function TDTDominio.Login: TRetornoPadrao;
var
  wv: Tfrm_OAuthWebForm;
begin
//  wv                 := Tfrm_OAuthWebForm.Create(nil);
//  wv.Caption         := 'Login';
//  wv.OnAfterRedirect := OnvioOnRedirectURI;
//
//  case FAmbiente of
//    aProducao:    wv.ShowModalWithURL('https://auth.thomsonreuters.com/authorize?client_id='+FClientID+'&response_type=code&audience=409f91f6-dc17-44c8-a5d8-e0a1bafd8b67&redirect_uri='+FcallbackURI+'&scope=openid+profile+email+offline_acces');
//    aHomologacao: wv.ShowModalWithURL('https://auth.thomsonreuters.com/authorize?client_id='+FClientID+'&response_type=code&audience=409f91f6-dc17-44c8-a5d8-e0a1bafd8b67&redirect_uri='+FcallbackURI+'&scope=openid+profile+email+offline_acces');
//  end;
//  Retorno.Codigo   := 200;
//  Retorno.Mensagem := Fcode;
//
//  wv.Release;
end;

function TDTDominio.onExecuteRequest(
  const vEvent: TonExecuteRequest): TRetornoPadrao;
begin
  //Result := Self;

  FonExecuteRequest := vEvent;
end;

procedure TDTDominio.OnvioOnRedirectURI(const AURL: string;
  var DoCloseWebView: boolean);
var
  LATPos: integer;
  LToken: string;
begin
  LATPos := Pos('code=', AURL);

  if (LATPos > 0) then
    begin
//      LToken := Copy(AURL, LATPos + 5, Length(AURL));
//
//      if (Pos('&', LToken) > 0) then
//        begin
//          LToken := Copy(LToken, 1, Pos('&', LToken) - 1);
//        end;
//
//      Fcode := LToken;
//
//      if Assigned(FonExecuteRequest) then
//        FonExecuteRequest(rtLogin, FCode, 200);
//
//      if (LToken <> '') then
//        DoCloseWebView := TRUE;
    end;
end;

procedure TDTDominio.SetAccessToken(const Value: string);
begin
  FAccessToken := Value;
end;

procedure TDTDominio.SetAmbiente(const Value: TAmbiente);
begin
  FAmbiente := Value;
end;

procedure TDTDominio.setAuence(const Value: string);
begin
  FAudience := Value;
end;

procedure TDTDominio.setCaminhoArquivoToken(const Value: string);
begin
  FCaminhoArquivoToken := Value;
end;

procedure TDTDominio.setCaminhoLog(const Value: string);
begin
  FCaminhoLog := Value;
end;

procedure TDTDominio.SetClientID(const Value: String);
begin
  FClientID := Value;
end;

procedure TDTDominio.SetClientSecret(const Value: String);
begin
  FClientSecret := Value;
end;


procedure TDTDominio.SetDataToken(const Value: TDate);
begin
  FDataToken := Value;
end;

procedure TDTDominio.setGravarLog(const Value: Boolean);
begin
  FGravarLog := Value;
end;

procedure TDTDominio.SetHoraToken(const Value: TTime);
begin
  FHoraToken := Value;
end;

procedure TDTDominio.setIntegrationKey(const Value: string);
begin
  FIntegrationKey := Value;
end;

procedure TDTDominio.setKeyContabilidade(const Value: string);
begin
  FKeyContabilidade := Value;
end;

procedure TDTDominio.setStatus(const Value: Boolean);
begin
  Fstatus := Value;
end;

procedure TDTDominio.SetToken(const Value: String);
begin
  FAccessToken := Value;
end;

end.
