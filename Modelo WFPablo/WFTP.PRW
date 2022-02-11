#include "rwmake.ch"   
#include "Protheus.ch"     
#include "Topconn.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
/*
Programa.: WFTP.PRW 
Autor....: Pedro Augusto
Data.....: Dez/2015
Descricao: Rotina executada atraves de agendamento para envio de titulos a pagar bloqueados
Uso......: REPSOL
*/
User Function WFTP_99()
	Private _aMatriz  := {"99","01"}  
	Private _aEmpresa := {}  
	Conout('Inicio do processamento - TP() ' )
	RpcSetType(3)
	RpcSetEnv(_aMatriz[1],_aMatriz[2])
	Aadd(_aEmpresa, {_aMatriz[1],_aMatriz[2]})  
	U_TP({_aEmpresa[1]})
	RpcClearEnv()
	Conout('Final do processamento - TP() ' )
   	Return

User Function WFTP()
	Local _nEmp
	Private _aMatriz  := {"01","01"}  // para abrir a 1a empresa //
	Private _aEmpresa := {}  
//	Private _aNoEmp   := {}
	Conout('Inicio do processamento - TP() ' )
	RpcSetType(3)
	RpcSetEnv(_aMatriz[1],_aMatriz[2],,,'COM', "MATA103", , , , ,  )

	// Se o JOB ja estiver em execucao, nao continua            ³
	IF !LockByName("WFTP")
		Conout("JOB de aprovação de Contas a Pagar já estava em execução: Finalizado em " + DTOC(dDATABASE) + " - " + TIME() )
		RpcClearEnv()										// Limpa o ambiente, liberando a licença e fechando as conexões
    	RETURN
    ENDIF
	DBSelectArea("SM0")
	DBSetOrder(1)
	DBSeek(_aMatriz[1],.F.)
	
	WHILE !SM0->(EOF())                       
		Aadd(_aEmpresa, {SM0->M0_CODIGO,Alltrim(SM0->M0_CODFIL)})  
		SM0->(DBSkip())
	END
	RpcClearEnv()

    For _nEmp := 1 To Len(_aEmpresa)   
		U_TP({_aEmpresa[_nEmp]})  		
    Next 
	Conout('Final do processamento - TP() ' )
   	Return
                      
User Function TP( aParam )
	If aParam == Nil .OR. VALTYPE(aParam) == "U"
		Conout("Parametros nao recebidos => TP()")
		RETURN
	EndIf
	RpcSetType(3)
	RpcSetEnv(aParam[1][1],aParam[1][2])
	Conout('TP(aParam)inicio:' + aParam[1][1]   +'/'+ aParam[1][2])
	U_WKFTP()  		// 1 - ENVIO PC PARA APROVADORES
	RpcClearEnv()
	Conout('TP(aParam) final:' + aParam[1][1]   +'/'+ aParam[1][2])
	RETURN

/*
Rotina principal:
			- envio de e-mail de titulos para aprovacao 
			- Tratamento das respostas via HTTP
			- envio de e-mail de titulos aprovados / reprovados aos users do financeiro  
*/
		
User Function WKFTP()      
	Local _aAprovs := {}
	ChkFile("SE2")
		
   	Conout("1 - Prepara os títulos a serem enviados para aprovação")
	Conout("1 - EmpFil:" + cEmpAnt + cFilAnt)
	/*
	SELECT E2_FILIAL, E2_NATUREZ, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, E2_XGRPCOM  
	FROM SE2010 SE2 
	WHERE (E2_FILIAL = '01' OR E2_FILIAL = '02') AND 		
	E2_CODAPRO  = '      ' AND 		
	E2_SALDO    > 0							
	AND E2_XBLQNF 	<> 'S' 						
	AND E2_XWF 	  	= ' ' 						
	AND D_E_L_E_T_	= ' '
	*/
	_cQuery := " SELECT E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, E2_XGRPCOM "
	_cQuery += " FROM "+RetSqlName('SE2')+" SE2"
	_cQuery += " WHERE 	E2_FILIAL 	= '" + xFilial("SE2")  + "' AND"
	_cQuery += " 		E2_CODAPRO  = '      '					AND"
	_cQuery += " 		E2_SALDO    > 0							AND"
	_cQuery += " 		E2_XBLQNF 	<> 'S' 						AND"
	_cQuery += " 		E2_XWF 	  	= ' ' 						AND"
	_cQuery += " 		D_E_L_E_T_	= ' '"

	TcQuery _cQuery New Alias "TMP"
	
	dbGotop()
	While !TMP->(Eof()) 
		_aAprovs := {}                                  
		_cMailAprovs := ""
		_cMailccs	 := ""
        _cChaveSE2 :=  TMP->(E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA)
        _cChaveSF1 :=  TMP->(E2_FILIAL + E2_NUM + E2_PREFIXO + E2_FORNECE + E2_LOJA)

		DbSelectArea("SE2")
		DbSetOrder(1)
		DbSeek(_cChaveSE2)                                          
  		/**************************************************/		
		// Titulos gerados atraves de um fluxo de compras //
  		/**************************************************/		
		If Alltrim(SE2->E2_XGRPCOM) <> "" 
			DbSelectArea("SZC")
			DbSetOrder(1)
			DbSeek(xFilial("SZC")+SE2->E2_XGRPCOM)
			
			DbSelectArea("SAL")
			DbSetOrder(1)
			DbSeek(xFilial("SAL")+SZC->ZC_GRTP)

			While SAL->AL_COD == SZC->ZC_GRTP .and. !SAL->(Eof())
				If Alltrim(UsrRetmail(SAL->AL_USER)) <> ""
					aAdd(_aAprovs,{;
					Alltrim(UsrRetName(SAL->AL_USER)),; 
					Alltrim(UsrRetmail(SAL->AL_USER)),;
					Alltrim(UsrCargo(SAL->AL_USER  )) ;
					})
				Endif
				SAL->(DbSkip())  
			Enddo 
			If Len(_aAprovs)   > 0 // Achou aprovadores
				DbSelectArea("SX6")
				DbSetOrder(1)
				If DbSeek( "  " + "MV_XCCTC" )
		        	While Substr(SX6->X6_VAR,1,8) = "MV_XCCTC" .and. !SX6->(Eof())
		       			_cmailccs+= Iif(_cMailccs=="","",";")+Alltrim(SX6->X6_CONTEUD) // e-mails CC para tipo <> ""
		        		SX6->(DbSkip())
		        	Enddo	
				Endif
	
				DbSelectArea("SE2")
				// SE2 está posicionado
			   	WFMT100c(_cChaveSE2, _cChaveSF1, _aAprovs, _cmailccs) //E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA
//				Conout("Uma notificacao (Titulo: "+_cChaveSE2+")foi enviada para os envolvidos: "+CHR(10)+CHR(13)+_cMailAprovs)
				Reclock("SE2",.F.)
				SE2->E2_XWF = 'E'
				MsUnlock()                                                          
			Else
		  		/***************************************/		
				// Mandar aviso para pessoa a designar //
		  		/***************************************/		
			Endif	
		Else 
  		/******************************************************/		
		// Titulos gerados SEM um fluxo de compras (NATUREZA) //
  		/******************************************************/		
			DbSelectArea("SZB")
			DbSetOrder(1)
			DbSeek(xFilial("SZB")+SE2->E2_NATUREZ)
			While SZB->ZB_NATUREZ == SE2->E2_NATUREZ .and. !SZB->(Eof())
				aAdd(_aAprovs,{SZB->ZB_APROV,SZB->ZB_EMAIL, SZB->ZB_CARGO})
				SZB->(DbSkip())  
			Enddo 
			
			If Len(_aAprovs)   > 0 // Achou aprovadores
			
				DbSelectArea("SX6")
				DbSetOrder(1)
				If DbSeek( "  " + "MV_XCCNT" )
		        	While Substr(SX6->X6_VAR,1,8) = "MV_XCCNT" .and. !SX6->(Eof())
		       			_cmailccs+= Iif(_cMailccs=="","",";")+Alltrim(SX6->X6_CONTEUD) // e-mails CC para tipo <> ""
		        		SX6->(DbSkip())
		        	Enddo	
				Endif
	
				DbSelectArea("SE2")
				// SE2 está posicionado
			   	WFMT100c(_cChaveSE2, _cChaveSF1, _aAprovs, _cmailccs) //E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA
//				Conout("Uma notificacao (Titulo: "+_cChaveSE2+")foi enviada para os envolvidos: "+CHR(10)+CHR(13)+_cMailAprovs)
				Reclock("SE2",.F.)
				SE2->E2_XWF = 'E'
				MsUnlock()                                                          
			Else
		  		/***************************************/		
				// Mandar aviso para pessoa a designar //
		  		/***************************************/		
			Endif	
		
		Endif
		TMP->(DBSkip())           
	End

	dbSelectArea("TMP")
	dbCloseArea()
	Return
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±ºPrograma  ³WFMT100c  ºAutor  ³Pedro Augusto       º Data ³  01/12/15   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Envia notificacao de TITULO A PAGAR                         º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ REPSOL					                                  º±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function WFMT100c(_cChaveE2, _cChaveF1, _aAprov, _cCC) //E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA

	Local _aReturn 	:= {}
    Local _aAnexos 	:= {}
    Local _cEmail   := ""
	Local _cTpCom	:= ""
	Local _cDTpCom	:= ""
    Local i  
    
    Private _aNF 	:= {}
                                                                                               
    _cNomeFor 	:= Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_NREDUZ")  
    _cFatura  	:= Alltrim(SE2->E2_PREFIXO) +"-"+ Alltrim(SE2->E2_NUM) +"-"+ Alltrim(SE2->E2_PARCELA) +"-"+ Alltrim(SE2->E2_TIPO) 
    _cMoeda  	:= Iif(SE2->E2_MOEDA == 1,"REAL",Iif(SE2->E2_MOEDA == 2,"DOLAR",Iif(SE2->E2_MOEDA == 3,"UFIR",Iif(SE2->E2_MOEDA == 4,"EURO","-"))))
    _cCNPJ    	:= Posicione("SA2",1,xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA,"A2_CGC")
// 	_nTitulo  	:= SE2->(E2_VALOR+E2_ISS+E2_IRRF+E2_DECRESC)-SE2->E2_ACRESC                 
   	_nTitulo  	:= SE2->(E2_VLCRUZ)                 
//	_nTitEuro	:= Round(xMoeda(SE2->E2_VLCRUZ,SE2->E2_MOEDA,4,SE2->E2_EMISSAO,MsDecimais(1)+1,SE2->E2_TXMOEDA),MsDecimais(1))

    Conout("Notificacao: Propuesta de pago dirección de administración - 0204-PAGOS "+_cNomeFor+" FACTURA: "+_cFatura)
	oProcess          	:= TWFProcess():New( "NotifTP", "Propuesta de pago dirección de administración")  // 0204-PAGOS Nombre PROVEEDOR + Nº FACTURA
	oProcess          	:NewTask( "Envio Notif : "+cFilant , "\workflow\HTML\NotifTP.htm" )
	oProcess:cSubject 	:= "0204-PAGOS "+_cNomeFor+" FACTURA: "+_cFatura
	oProcess:bReturn  	:= ""
	
	_aAnexos:= AddAnexo(_cChaveE2, _cChaveF1)
	If Len(_aAnexos) > 0
		For i:= 1 to Len(_aAnexos)
			cAttachFile := "\dirdoc\co"+cEmpAnt+"\shared\"+ alltrim(_aAnexos[i])
			oProcess:attachfile(cAttachFile)
		Next i
	Endif

	oProcess:NewVersion(.T.)
 	oHtml     := oProcess:oHTML

	DbSelectArea("SF1")
	DbSetOrder(1)
	DbSeek(_cChaveF1)

	If !Empty(SE2->E2_XGRPCOM) // Provenientes de um fluxo de compras
		DbSelectArea("SD1")
		DbSetOrder(1)
		DbSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA))
		_cTpCom := Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_TIPO")
		_cDTpcom:= Posicione("SX5",1,xFilial("SX5")+"02"+_cTpCom,"X5_DESCRI")
	
		While SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) .and. !SD1->(Eof()) 
			_cProduto := Alltrim(Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC"))
			_cObsProd := Alltrim(Posicione("SC7",1,xFilial("SC7")+SD1->D1_PEDIDO+SD1->D1_ITEMPC,"C7_OBS"))
			Aadd(_aNF,{SD1->D1_DOC+" / "+SD1->D1_SERIE, SD1->D1_ITEM, SD1->D1_PEDIDO, SD1->D1_ITEMPC,"["+Alltrim(SD1->D1_COD) +"] "+_cProduto, _cObsProd})	
			SD1->(DbSkip())
		Enddo	 
		If Len(_aNF) > 0
			For i:= 1 to Len(_aNF)
				AAdd( (oHtml:ValByName( "t.1" )), _aNF[i][1])
				AAdd( (oHtml:ValByName( "t.2" )), _aNF[i][2])
				AAdd( (oHtml:ValByName( "t.3" )), _aNF[i][3])
				AAdd( (oHtml:ValByName( "t.4" )), _aNF[i][4])
				AAdd( (oHtml:ValByName( "t.5" )), _aNF[i][5] + Iif(_aNF[i][6] <> ""     ," - Obs: "  + _aNF[i][6],""))
			Next
		Else
			AAdd( (oHtml:ValByName( "t.1" )), " ")
			AAdd( (oHtml:ValByName( "t.2" )), " ")
			AAdd( (oHtml:ValByName( "t.3" )), " ")
			AAdd( (oHtml:ValByName( "t.4" )), " ")
			AAdd( (oHtml:ValByName( "t.5" )), " ")
		Endif			
	Else
		oHtml:ValByName( "E2_HIST"  	, SE2->E2_HIST)
		AAdd( (oHtml:ValByName( "t.1" )), " ")
		AAdd( (oHtml:ValByName( "t.2" )), " ")
		AAdd( (oHtml:ValByName( "t.3" )), " ")
		AAdd( (oHtml:ValByName( "t.4" )), " ")
		AAdd( (oHtml:ValByName( "t.5" )), " ")
	//	oHtml:ValByName( "TIPCOM"  		, Posicione("SED",1,xFilial("SED")+SE2->E2_NATUREZ,"ED_DESCRIC") ) // EXIBE NATUREZA
	Endif	


	oHtml:ValByName( "FORNECE"  	, _cNomeFor )
	oHtml:ValByName( "NUMDOC"  		, _cFatura	)
	oHtml:ValByName( "NUMNF"  		, Alltrim(SF1->F1_DOC)+Alltrim(SF1->F1_SERIE))

//  Alteracao: 19/abr/2017 - Alterado para contemplar caso do titulo 134908010 (PA)
//     inicio:
	If Alltrim(SE2->E2_TIPO) == "PA"
		oHtml:ValByName( "VRBRUTO"  	, Alltrim(TRANSFORM(SE2->E2_VLCRUZ +(SE2->E2_PIS+SE2->E2_COFINS+SE2->E2_CSLL +SE2->E2_IRRF)	,'@E 9,999,999,999.99')))
		oHtml:ValByName( "VRLIQUIDO"  	, Alltrim(TRANSFORM(SE2->E2_VLCRUZ	,'@E 9,999,999,999.99')))

		If SE2->E2_MOEDA == 4
			_nTitEuro	:= Round(xMoeda(SE2->E2_VLCRUZ,1,SE2->E2_MOEDA,SE2->E2_EMISSAO,MsDecimais(1)+1,SE2->E2_TXMOEDA),MsDecimais(1))
	    Else
			_nTitEuro	:= Round(xMoeda(SE2->E2_VLCRUZ,1,4,SE2->E2_EMISSAO,MsDecimais(1)+1,SE2->E2_TXMOEDA),MsDecimais(1))
	    Endif

	Else
		oHtml:ValByName( "VRBRUTO"  	, Alltrim(TRANSFORM(SE2->E2_VLCRUZ+SE2->E2_IRRF	,'@E 9,999,999,999.99')))
		oHtml:ValByName( "VRLIQUIDO"  	, Alltrim(TRANSFORM(SE2->E2_VLCRUZ-(SE2->E2_PIS+SE2->E2_COFINS+SE2->E2_CSLL)	,'@E 9,999,999,999.99')))

		If SE2->E2_MOEDA == 4
			_nTitEuro	:= Round(xMoeda(SE2->E2_VLCRUZ-(SE2->E2_PIS+SE2->E2_COFINS+SE2->E2_CSLL),1,SE2->E2_MOEDA,SE2->E2_EMISSAO,MsDecimais(1)+1,SE2->E2_TXMOEDA),MsDecimais(1))
	    Else
			_nTitEuro	:= Round(xMoeda(SE2->E2_VLCRUZ-(SE2->E2_PIS+SE2->E2_COFINS+SE2->E2_CSLL),1,4,SE2->E2_EMISSAO,MsDecimais(1)+1,SE2->E2_TXMOEDA),MsDecimais(1))
	    Endif
	
    Endif

//  Final                                                        
	oHtml:ValByName( "DTREGISTRO"  	, DTOC(SE2->E2_EMISSAO))
	oHtml:ValByName( "CENTRO"  		, SE2->E2_CCD )

	oHtml:ValByName( "CODFORN"  	, SE2->E2_FORNECE+"-"+SE2->E2_LOJA  )
	oHtml:ValByName( "CLASE"  		, SE2->E2_CLVLDB )
	oHtml:ValByName( "DTNF"  		, DTOC(SE2->E2_EMISSAO))
	oHtml:ValByName( "MOEDA" 	 	, _cMoeda)
	oHtml:ValByName( "DTBASE"  		, dDATABASE)

	oHtml:ValByName( "CNPJ"  		, Transform(_cCNPJ,PesqPict("SA2","A2_CGC")))
	oHtml:ValByName( "CHAVECTB"  	, SE2->E2_CONTAD )
//	oHtml:ValByName( "VREURO"  		, Alltrim(TRANSFORM(SE2->E2_VALOR ,'@E 9,999,999,999.99')))
	oHtml:ValByName( "VREURO"  		, Alltrim(TRANSFORM(_nTitEuro    	,'@E 9,999,999,999.99')))
	oHtml:ValByName( "DTVENC"  		, DTOC(SE2->E2_VENCTO))

	// Melhoria solicitada por Miriam em 10/05/2016
	_cInversion := Iif(Empty(SE2->E2_XGRPCOM),"",Iif(Alltrim(SE2->E2_XGRPCOM) == '147','SÍ','NO'))
	_cGasto 	:= Iif(Empty(SE2->E2_XGRPCOM),"",Iif(Alltrim(SE2->E2_XGRPCOM) == '147','NO','SÍ'))
	_cAsesoria  := Iif(Empty(SE2->E2_XGRPCOM),"",Iif(Alltrim(SE2->E2_XGRPCOM) == '163','X',' '  ))

	oHtml:ValByName( "INVERSION"	, _cInversion)
	oHtml:ValByName( "GASTO"  		, _cGasto)
	oHtml:ValByName( "ASESORIA"  	, _cAsesoria)

	For i:= 1 to Len(_aAprov)
		_cEmail+= Iif(i==1,"",";")+Alltrim(_aAprov[i][2])
		AAdd( (oHtml:ValByName( "t1.1"   )), _aAprov[i,1]  )
		AAdd( (oHtml:ValByName( "t1.2"   )), _aAprov[i,2]  )
		AAdd( (oHtml:ValByName( "t1.3"   )), _aAprov[i,3]  )
	Next i
	If Alltrim(_cEmail) == "" 
		_cEmail:= Alltrim(GetNewPar("MV_WFADMIN","mabadp@repsol.com"))
	Endif

	If !Empty(SE2->E2_XGRPCOM) 
		oHtml:ValByName( "TIPCOM"  		, Alltrim(_cDTpCom) )   // EXIBE TIPO DE COMPRA
	Else
		oHtml:ValByName( "TIPCOM"  		, Posicione("SED",1,xFilial("SED")+SE2->E2_NATUREZ,"ED_DESCRIC") ) // EXIBE NATUREZA
	Endif	

	oProcess:cTo      	:= _cEmail   
	oProcess:cCC      	:= _cCC
// 	oProcess:cTo      	:= "pedroaugustoc.pac@gmail.com"
	
	AADD(_aReturn, oProcess:fProcessId)
	oProcess:nEncodeMime := 0
	cProcess:= oProcess:Start()	// start workflow
	return _aReturn
	

//////////////////////////////////////////////////////////////////////////////////////////
// Funcao AddAnexo()                                         					       	//
// Autor : Pedro Augusto   Data : 05/12/2015             						       	//
// Verifica no banco de conhecimento se há                        						// 
// objetos associados ao SF1 e ao SE2                             						// 
// Recebe chaves:                                                 						//
// SF1: E2_FILIAL + E2_NUM + E2_PREFIXO + E2_FORNECE + E2_LOJA    						//
// SE2: E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA   //
//////////////////////////////////////////////////////////////////////////////////////////

Static Function AddAnexo(_cSE2, _cSF1)                                                                      
    Local _aDoc := {}
    Local _lDoc := .F.
    
	_cSelDoc := " select F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, AC9_CODOBJ, ACB_OBJETO, ACB_DESCRI"
	_cSelDoc += " from   "+RetSqlName('SF1')+" SF1, "+RetSqlName('AC9')+" AC9, "+RetSqlName('ACB')+" ACB" 
	_cSelDoc += " where  (F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) = '"+ Alltrim(_cSF1) + "'"     
	_cSelDoc += "   and  F1_FILIAL  = AC9_FILENT and (F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) = AC9_CODENT"
	_cSelDoc += "   and  ACB_FILIAL = AC9_FILIAL and ACB_CODOBJ = AC9_CODOBJ"
	_cSelDoc += "   and  SF1.D_E_L_E_T_ = ' '"
	_cSelDoc += "   and  AC9.D_E_L_E_T_ = ' '"
	_cSelDoc += "   and  ACB.D_E_L_E_T_ = ' '"
	_cSelDoc := ChangeQuery(_cSelDoc)
	TCQUERY _cSelDoc NEW ALIAS "F1DOC"
	DBSELECTAREA("F1DOC")
	dbGoTop()
	
	While !Eof()
	    Aadd( _aDoc,   F1DOC->ACB_OBJETO )
		_lDoc := .t.
		DbSelectArea('F1DOC')
		DbSkip()	
	EndDo
	dbSelectArea("F1DOC")
	dbCloseArea()   

	// query para buscar o OBJETO associado ao TÃ­tulo do Contas a Pagar atravÃ©s do Banco de Conhecimento
	//ATENCAO: VERIFICAR COMPARTILHAMENTO DA SE2, AC9 e ACB//
	_cSelDoc := " select E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, AC9_CODOBJ, ACB_OBJETO, ACB_DESCRI"
	_cSelDoc += " from   "+RetSqlName('SE2')+" SE2, "+RetSqlName('AC9')+" AC9, "+RetSqlName('ACB')+" ACB" 
	_cSelDoc += " where  (E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA) = '"+ Alltrim(_cSE2) + "'"
	_cSelDoc += "   and  E2_FILIAL  = AC9_FILENT and (E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA) = AC9_CODENT"
	_cSelDoc += "   and  ACB_FILIAL = AC9_FILIAL and ACB_CODOBJ = AC9_CODOBJ"
	_cSelDoc += "   and  SE2.D_E_L_E_T_ = ' '"
	_cSelDoc += "   and  AC9.D_E_L_E_T_ = ' '"
	_cSelDoc += "   and  ACB.D_E_L_E_T_ = ' '"
	_cSelDoc := ChangeQuery(_cSelDoc)
	TCQUERY _cSelDoc NEW ALIAS "E2DOC"
	DBSELECTAREA("E2DOC")
	dbGoTop()
	
	While !Eof()
	    Aadd( _aDoc, E2DOC->ACB_OBJETO)
		_lDoc := .t.
		DbSelectArea('E2DOC')
		DbSkip()	
	EndDo
	dbSelectArea("E2DOC")
	dbCloseArea()   

	Return _aDoc


Static Function UsrCargo(_cUser)
	Local _cAlias := Alias()
	Local _cSavOrd := IndexOrd()
	Local _cCargo
	If _cUser == Nil
		_cUser := CUSERNAME
	EndIf
	PswOrder(1)
	If	PswSeek(_cUser)
		_cCargo := PswRet(1)[1][13]
	Else
		_cCargo := SPACE(15)
	EndIf
	dbSelectArea(_cAlias)
	dbSetOrder(_cSavOrd)
	Return _cCargo

//------------------------------------------------------------------------
// ENVIO DE EMAIL
//------------------------------------------------------------------------

User Function Send
	U_SENDMAIL({'01'})

USER FUNCTION SENDMAIL(aParam)
	If aParam == Nil .OR. VALTYPE(aParam) == "U"
		U_CONSOLE("Parametros nao recebidos => SENDMAIL(cEmp)" )
		RETURN
	EndIf
	
	U_CONSOLE('SENDMAIL() /' + aParam[1] )
	
	WFSENDMAIL({aParam[1],"01"})
	RETURN
