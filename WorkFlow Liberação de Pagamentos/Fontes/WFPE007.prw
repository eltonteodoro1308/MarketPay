#include 'totvs.ch'

User Function WFPE007()

	Local cHTML       := ''
	Local plSuccess   := ParamIXB[1]
	Local pcMessage   := ParamIXB[2]
	Local pcProcessID := ParamIXB[3]

	BeginContent var cHTML

	<!DOCTYPE html>
	<html lang="en">

	<head>
	<meta charset="WIN-1252" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<link rel="stylesheet" href="./assets/reset.css" />
	<link rel="stylesheet" href="./assets/bootstrap.min.css" />
	<link rel="stylesheet" href="./assets/styles.css" />
	<title>Retorno do Processamento</title>
	</head>

	<body>
	<div class="container">
	<div class="row justify-content-center">
	<div class="col-md-6 card mt-5 p-3 bg-light">
	<p>%titulo%</p>
	<p>%mensagem%</p>
	</div>
	</div>
	</div>
	</body>

	</html>

	endContent

	If ( plSuccess )

		cHTML := strTran( cHTML, '%titulo%', 'Processamento executado com sucesso!' )

	Else

		cHTML := strTran( cHTML, '%titulo%', 'Falha no processamento!' )

	EndIf

	cHTML := strTran( cHTML, '%mensagem%', pcMessage )

Return cHTML

