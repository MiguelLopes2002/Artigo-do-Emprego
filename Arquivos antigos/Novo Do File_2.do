* Script para Analisar Fatores que Influenciam a Permanência no Emprego usando Modelos Logit/Probit

* Limpar memória de trabalho
clear all
set more off

* Definir diretório de trabalho
cd "C:/Users/Miguel/Desktop/Trabalho do Tillmann/"

* Importar a base de dados da RAIS, mantendo apenas as variáveis necessárias
import delimited "D:/RAIS_VINC_PUB_SUL_2023.txt", delimiter(";") varnames(1) clear
keep idade escolaridadeapós2005 raçacor sexotrabalhador vlremunmédianom tipovínculo faixahoracontrat indtrabintermitente tamanhoestabelecimento cnae20classe indsimples tempoemprego cboocupação2002
***************************************************************************
gen tempo_ordinal = .
replace tempo_ordinal = 0 if tempoemprego_clean <= 12 // Menor igual a 1 ano
replace tempo_ordinal = 1 if tempoemprego_clean > 12 & tempoemprego_clean <= 60 // Maior que 1 ano e menor ou igual a 5 anos
replace tempo_ordinal = 2 if tempoemprego_clean > 60 & tempoemprego_clean != . // Maior que 5 anos
label define tempo_ordinal 0 "1 ano" 1 "1 a 5 anos" 2 "Mais de 5 anos"
label values tempo_ordinal tempo_ordinal

log using "LogitMultinomial.txt", text replace
tabulate tempo_ordinal
tabulate sexotrabalhador
tabulate estado
tabulate raçacor
tabulate escolaridade
tabulate cbo_agrup
tabulate cnae_agrup
tabulate nacionalidade
tabulate afastamento
tabulate porte
*mlogit tempo_ordinal ///
*       i.sexotrabalhador i.estado i.raçacor ///
*       i.escolaridade c.idade i.cbo_agrup ///
*	   i.cnae_agrup i.nacionalidade i.afastamento ///
*	   i.porte i.qtdhoracontr, vce(robust) rrr baseoutcome(0)
log close
gologit2 tempo_ordinal ///
         i.sexotrabalhador i.estado i.raça i.escolaridade c.idade ///
         i.cbo_agrup i.cnae_agrupado i.nacionalidade i.afastamento i.porte ///
	     i.horas i.tipovínculo i.natureza i.faixa_salario, or autofit lrforce
***************************************************************************
drop bairrosfortaleza bairrossp bairrosrj cnae95classe distritossp vínculoativo3112 ///
	 faixaetária faixahoracontrat faixaremundezemsm  faixaremunmédiasm faixatempoemprego ///
	 vlremjaneirosc vlremfevereirosc vlremmarçosc vlremabrilsc vlremmaiosc vlremjunhosc ///
	 vlremjulhosc vlremagostosc vlremsetembrosc vlremoutubrosc vlremnovembrosc ///
	 vlremundezembronom vlremundezembrosm vlremunmédiasm regiõesadmdf anochegadabrasil ///
	 ibgesubsetor indsimples  // Acho que são variáveis que assumem um único valor ou que não tenho intenções de retirar nada

drop if indtrabintermitente == 1 // Tirando trabalhador intermitente
drop indtrabintermitente

drop if indtrabparcial == 1 // Tirando trabalho parcial
drop indtrabparcial

drop if indceivinculado == 9 // Tirando categoria Cadastro Específico do INSS, que virou CNO, eu acho
drop indceivinculado

drop if inrange(tipodefic, 1, 5) // Dropei quem tinha deficiência, deixando apenas quem não tinha (zero) e quem foi reabilitado (seis), para tentar deixar mais homogênea as capacidades de cada indivíduo
drop tipodefic
drop if indportadordefic == 1
drop indportadordefic

keep if inlist(tipovínculo, 10, 20) // Deixando só Trabalhador urbano e rural vinculado a empregador pessoa jurídica por contrato de trabalho regido pela CLT, por prazo indeterminado
label define tipovínculo 10 "Urbano" 20 "Rural"
label values tipovínculo tipovínculo
label variable tipovínculo "Vínculo"

keep if inlist(tipoadmissão, 0, 1, 2, 3, 4, 8) // Tirando admissões específicas de servidor
drop tipoadmissão

gen nac = 0 if nacionalidade == "10"
replace nac = 1 if nacionalidade != "10"
label define nac 0 "Brasileiro" 1 "Estrangeiro"
label values nac nac
drop nacionalidade
rename nac nacionalidade
label variable nacionalidade "Nacionalidade"

drop if inlist(motivodesligamento, 10,20,30,31,40,60,62,63,64,70,71,72,73,74,75,76,77,78,79,80,89) // Excluindo falecidos, aposentados e demissões por justa causa, rescisão indireta
drop motivodesligamento
* Excluí transferências de funcionários porque poderia contar como demissão, sendo que ela de fato não ocorreu (30, 31)

* tipoestab = v43
keep if tipoestab == 1 // Mantenho só quem trabalha pra CNPJ, excluindo CNO e CAEPF. Quem trabalha por CNO pode sofrer sazonalidade, ou até serviços não rotineiros, sei lá
drop tipoestab
drop v43

gen afastamento = .
replace afastamento = 0 if causaafastamento1==99 ///
                        & causaafastamento2==99 ///
                        & causaafastamento3==99
replace afastamento = 1 if afastamento==. & ( ///
    causaafastamento1==50 | ///
    causaafastamento2==50 | ///
    causaafastamento3==50 )
replace afastamento = 2 if afastamento==. & ( ///
    inlist(causaafastamento1,10,20) | ///
    inlist(causaafastamento2,10,20) | ///
    inlist(causaafastamento3,10,20) )
replace afastamento = 3 if afastamento==. & ( ///
    inlist(causaafastamento1,30,40) | ///
    inlist(causaafastamento2,30,40) | ///
    inlist(causaafastamento3,30,40) )
replace afastamento = 4 if afastamento == .
label define afalbl 0 "Nenhum (99)" ///
					1 "Licença-maternidade" ///
					2 "Acidente"           ///
					3 "Doença"             ///
					4 "Outros"
label values afastamento afalbl
drop causaafastamento1 causaafastamento2 causaafastamento3
label variable afastamento "Afastamento"

label define sexotrabalhador 1 "Masculino" 2 "Feminino"
label values sexotrabalhador sexotrabalhador
label variable sexotrabalhador "Sexo"

* Tamanho por número de empregados
label define tamanhoestabelecimento 1 "Zero" 2 "De 1 a 4" 3 "De 5 a 9" 4 "De 10 a 19" 5 "De 20 a 49" 6 "De 50 a 99" 7 "De 100 a 249" 8 "De 250 a 499" 9 "De 500 a 999" 10 "1000 ou Mais"
label values tamanhoestabelecimento tamanhoestabelecimento
gen porte = .
replace porte = 1 if inlist(tamanhoestabelecimento,1,2,3) ///
				   & inlist(cnae_agrup,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
replace porte = 2 if inlist(tamanhoestabelecimento,4,5) ///
				   & inlist(cnae_agrup,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
replace porte = 3 if inlist(tamanhoestabelecimento,6) ///
				   & inlist(cnae_agrup,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
replace porte = 4 if inlist(tamanhoestabelecimento,7,8,9,10) ///
				   & inlist(cnae_agrup,0,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)
replace porte = 1 if inlist(tamanhoestabelecimento,1,2,3,4) ///
				   & inlist(cnae_agrup,1,2,3,4,5)
replace porte = 2 if inlist(tamanhoestabelecimento,5,6) ///
				   & inlist(cnae_agrup,1,2,3,4,5)
replace porte = 3 if inlist(tamanhoestabelecimento,7,8) ///
				   & inlist(cnae_agrup,1,2,3,4,5)
replace porte = 4 if inlist(tamanhoestabelecimento,9,10) ///
				   & inlist(cnae_agrup,1,2,3,4,5)
label define portelbl 1 "Micro" 2 "Pequeno" 3 "Médio" 4 "Grande"
label values porte portelbl
label variable porte "Porte do estabelecimento"

label define raçacor 1 "Indígena" 2 "Branca" 4 "Preta" 6 "Amarela" 8 "Parda" 9 "Não informado"
label values raçacor raçacor
recode raçacor (2=99)
recode raçacor (1=2)
recode raçacor (99=1)
label define raçacor 1 "Branca" 2 "Indígena" 4 "Preta" 6 "Amarela" 8 "Parda" 9 "Não informado", modify
label values raçacor raçacor
drop if raçacor == 9
tab raçacor
label variable raçacor "Raça"

drop if inlist(naturezajurídica, 1015,1023,1031,1058,1066,1082,1104,1112,1120, ///
		1147,1155,1210,1228,1236,1244,1260,1279,1325,1333) // Tirando administração pública
drop if inlist(naturezajurídica, 2135) // Retirando Empresário (Individual)

gen esc9 = .
replace esc9 = 1 if inlist(escolaridadeapós2005,1)
replace esc9 = 2 if inlist(escolaridadeapós2005,2,3,4)
replace esc9 = 3 if inlist(escolaridadeapós2005,5)
replace esc9 = 4 if inlist(escolaridadeapós2005,6)
replace esc9 = 5 if inlist(escolaridadeapós2005,7)
replace esc9 = 6 if inlist(escolaridadeapós2005,8)
replace esc9 = 7 if inlist(escolaridadeapós2005,9)
replace esc9 = 8 if inlist(escolaridadeapós2005,10)
replace esc9 = 9 if inlist(escolaridadeapós2005,11)
label define esc9lbl ///
1 "Analfabeto" ///
2 "Ensino Fundamental Incompleto" ///
3 "Ensino Fundamental Completo" ///
4 "Ensino Médio Incompleto" ///
5 "Ensino Médio Completo" ///
6 "Ensino Superior Incompleto" ///
7 "Ensino Superior Completo" ///
8 "Mestrado" ///
9 "Doutorado"
label values esc9 esc9lbl
rename esc9 escolaridade
label variable escolaridade "Escolaridade"
drop escolaridadeapós2005

keep if inlist(qtdhoracontr, 44,40,36,30) // Mantendo só o pessoal que trabalha nessas horas aí, 6 horas por dia ou 8 por dia, até sexta ou sábado (+4 anso sábado para 8 horas)

drop if vlremunmédianom_clean == 0

clonevar vlremunmédianom_clean = vlremunmédianom
replace vlremunmédianom_clean = subinstr(vlremunmédianom_clean, ",", ".", .)
replace vlremunmédianom_clean = regexr(vlremunmédianom_clean, "^0+", "")
destring vlremunmédianom_clean, replace force
drop vlremunmédianom

clonevar tempoemprego_clean = tempoemprego
replace tempoemprego_clean = subinstr(tempoemprego_clean, ",", ".", .)
destring tempoemprego_clean, replace force
drop tempoemprego
***************************************************************************

* Limpeza e conversão da variável 'vlremunmédianom'
* Criar uma nova variável 'vlremunmédianom_clean' para preservar o valor original
clonevar vlremunmédianom_clean = vlremunmédianom
* Substituir vírgulas por pontos, para padronização de separadores decimais
replace vlremunmédianom_clean = subinstr(vlremunmédianom_clean, ",", ".", .)
* Remover zeros à esquerda, que podem causar problemas de conversão
replace vlremunmédianom_clean = regexr(vlremunmédianom_clean, "^0+", "")
* Converter a variável de string para numérica, forçando a conversão
destring vlremunmédianom_clean, replace force
drop vlremunmédianom

* Limpeza e conversão da variável 'tempoemprego'
* Criar uma cópia 'tempoemprego_clean' para preservar o original
clonevar tempoemprego_clean = tempoemprego
* Substituir vírgulas por pontos
replace tempoemprego_clean = subinstr(tempoemprego_clean, ",", ".", .)
* Converter a variável de string para numérica
destring tempoemprego_clean, replace force
drop tempoemprego

* Verificar se as conversões foram bem-sucedidas
summarize vlremunmédianom_clean tempoemprego_clean

* Criar a variável dependente binária 'permanencia' para indicar se o trabalhador permaneceu no emprego por mais de 2 anos
gen permanencia = 0
replace permanencia = 1 if tempoemprego_clean > 24

* Criar faixas etárias (arredondadas a cada 5 anos) para análise de efeitos marginais
* A multiplicação por 5 permite que as variáveis fiquem de 5 em 5 anos
gen idade_grupo = round(idade/5)*5

* Criar faixas de remuneração para facilitar a análise
gen vlremun_faixa = ceil(vlremunmédianom_clean / 500)

* Calcular a frequência de cada valor de cnae20classe
tab cnae_agrup, sort
log using "frequencia_cnae.txt", text replace
tabulate cnae20subclasse, sort
log close
* Iniciar o log para salvar a saída, já que não tem como ver o tabulate completo no Stata
log using "frequencia_cbo.txt", text replace
* Executar o comando
tabulate cboocupação2002, sort
* Fechar o log
log close

* Definir variáveis dependente e independentes como globais
global ylist permanencia
global xlist idade_grupo escolaridadeapós2005 raçacor sexotrabalhador indtrabintermitente tamanhoestabelecimento vlremun_faixa

* Estatísticas descritivas
describe $ylist $xlist
summarize $ylist $xlist
tabulate $ylist

* Regressão linear como comparação inicial
reg $ylist $xlist

* Modelos Logit e Probit
logit $ylist $xlist
probit $ylist $xlist

* Marginal effects (margens ao redor da média e médias marginais)
quietly logit $ylist $xlist
margins, dydx(*) atmeans
margins, dydx(*)

quietly probit $ylist $xlist
margins, dydx(*) atmeans
margins, dydx(*)

* Exibir odds ratios usando modelo logístico
logistic $ylist $xlist

* Predição de probabilidades
quietly logit $ylist $xlist
predict plogit, pr

quietly probit $ylist $xlist
predict pprobit, pr

quietly reg $ylist $xlist
predict pols, xb

summarize $ylist plogit pprobit pols

* Classificação percentual correta
quietly logit $ylist $xlist
estat classification

quietly probit $ylist $xlist
estat classification

* Análise gráfica de efeitos marginais
* Probabilidade por faixa etária
margins, at(idade_grupo=(20(5)60)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Idade")

* Probabilidade por faixa de remuneração
margins, at(vlremun_faixa=(1(1)10)) predict(pr)
marginsplot, title("Probabilidade Predita de Permanência no Emprego por Faixa de Remuneração")

* Modelo com interação para análise adicional
logit $ylist c.idade##c.escolaridadeapós2005 $xlist

* Estimar modelos com robustez
logit $ylist $xlist, vce(robust)
probit $ylist $xlist, vce(robust)

* Salvar os resultados em log
log using "analise_permanencia_emprego.log", replace
log close
