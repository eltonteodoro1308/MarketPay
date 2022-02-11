#include 'protheus.ch'

USER Function ASPConn()

	Local cReturn  := ''
	Local cAspPage := ''
	Local nTimer   := 0

	Private cMensagem := ''
	Private cRedirect := ''

	cAspPage := HTTPHEADIN->MAIN

	If !empty( cAspPage )

		nTimer := seconds()
		cAspPage := LOWER(cAspPage)

		conout("ASPCONN - Thread Advpl ASP ["+cValToChar(ThreadID())+"] "+;
			"Processando ["+cAspPage+"]")

		do case

		case cAspPage == 'wflof580'

			conout(HTTPPOST->LOGIN)
			conout(HTTPPOST->SENHA)

			if ! Empty( HTTPPOST->LOGIN ) .And. ! Empty( HTTPPOST->SENHA ) .And.;
					RpcSetEnv( '99', '01', HTTPPOST->LOGIN, HTTPPOST->SENHA )

				cMensagem := 'Login executado com sucesso.'

				cRedirect := HTTPPOST->URL_WF_APROVACAO

				RpcClearEnv()

			else

				cRedirect := HTTPPOST->URL_WF_LOGIN

				cMensagem := 'Erro ao executar o Login'

			end if

			cReturn := h_wflof580()

		otherwise

			cReturn := "<html><body><center><b>"+;
				"Página AdvPL ASP não encontrada."+;
				"</b></body></html>"
		Endcase

		nTimer := seconds() - nTimer
		conout("ASPCONN - Thread Advpl ASP ["+cValToChar(ThreadID())+"] "+;
			"Processamento realizado em "+ alltrim(str(nTimer,8,3))+ "s.")
	Endif

Return cReturn
