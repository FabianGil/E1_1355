
/* Para que este codigo es neceario tener los archivos Base1.xls, Base2.csv, Base3.dta en su carpeta de trabajo de Stata*/

* La linea siguiente establece el espacio de trabajo, puede descomentarla quitando el * y cambiar la ruta a su comveniencia

*cd "/home/stata/1 trabajo"

log using "logdeltrabajo.smcl", replace
set more off
clear all



/* Lectura de data y exportacion a .dta*/
import excel "Base1.xls", sheet("base1") firstrow clear
desc
save base1.dta, replace

clear all
insheet using "Base2.csv", comma
desc
save base2.dta, replace

/* Mezcla de datos */
clear all
use base1.dta

append using "base2.dta"
desc
save base1y2, replace

use Base3.dta, clear
desc

use base1y2, clear
merge m:m var1 using "Base3.dta"

save base, replace
desc

/* Dar formato y fecha a las variables*/

* ID (Var1)
label variable var1 `"Identificador del paciente"'
rename var1 id_paciente

* Sexo (var2)
label variable var2 `"Sexo del paciente"'
rename var2 sexo
label define sexo 1 "Hombre" 0 "Mujer" 
label values sexo sexo
note sexo : Sexo del paciente: 1=Hombre, 0=Mujer

* Tipo de dolor de pecho (var3)
label variable var3 `"Tipo de dolor de pecho"'
rename var3 dolor_pecho
label define dolor_pecho 1 "Angina ti­pica" 2 "Angina atipica" 3 "Dolor no anginal" 4 "Asintomatico" , replace
label values dolor_pecho dolor_pecho
note dolor_pecho : "1 = Angina ti­pica, 2 = Angina atipica, 3 = dolor no anginal, 4 = Asintomatico"

* Presion Sistolica y colesterol (var4 y var5)
destring var4 var5, generate(pres_sistol coles_ser) force

// Alunos missing se generaron podemos ver los valores originales
// pero no tememos informacion para inputarlos

list var4 pres_sistol if pres_sistol==.
list var5 coles_ser if coles_ser==.

label variable pres_sistol `"Presion sanguinea sistolica"'
note pres_sistol : mmHg
label variable coles_ser `"Colesterol serico"'
note coles_ser : mg/dl

*Electrocardiograma en reposo (var6)
label variable var6 `"Electrocardios en reposo"'
rename var6 elec_repo
label define elec_repo 0 "Normal" 1 "Onda ST-T anomala" 2 "Hipertrofia ventr. izq." 
label values elec_repo elec_repo
note elec_repo : "0  normal; 1  con anomalia de la onda ST-T; 2 Mostrando hipertrofia ventricular izquierda probable o definida"

* Fecha de nacimiento (var7)
gen nacimiento=date(var7, "MDY")
format nacimiento %d
list var7 nacimiento if nacimiento==.
label variable nacimiento `"Fecha nacimiento"'

* Estado de la enfermedad (var8)
label variable var8 `"Estado angiografico"'
rename var8 angio
label define angio 0 "<50% reduccion" 1 ">50% reduccion" 
label values angio angio
note angio : "0 es <50% de reduccion de diametro, 1 es > 50% de reduccion de diametro"

* Fecha de angiografia coronaria (var9)
gen fecha_angio=date(var9, "DMY")
format fecha_angio %d
list var9 fecha_angio if fecha_angio==.
label variable fecha_angio `"Fecha angiografia coronaria"'

/* Eliminar variables y guardar base rotulada*/
drop var4 var5 var7 var9 _merge
save base_v3, replace

/*Corte de la variable presion sistolica*/
sum pres_sistol, d
egen float cut_pres_sist = cut(pres_sistol), at(0 90 120 140 160 180 300) icodes
label variable cut_pres_sist `"Niveles de presion sitolica"'
label define cut_pres_sit 0 "Hipotension" 1 "Deseada/Normal" 2 "Prehipertension" 3 "Hipertension grado 1" 4 "Hipertension grado 2" 5 "Crisis hipertensiva" , replace
label values cut_pres_sist cut_pres_sit

list pres_sistol cut_pres_sist if pres_sistol==.

/* Edad a la fecha de angiografia coronaria (var9) */
generate double edad_angio = (fecha_angio - nacimiento)/365.25
list nacimiento fecha_angio edad_angio if edad_angio==.
label variable edad_angio `"Edad a la angiografia"'

/*Base final*/
save base_vf, replace
/*Plot*/


/*plot edad vs sexo*/
egen int edad_cut = cut(edad_angio), at(29 40 45 50 55 60 1000) icodes
label define edad_cut 0 "29 a 39" 1"40 a 44" 2 "45 a 49" 3 "50 a 54" 4 "55 a 59" 5 "60 a 80" , replace
label values edad_cut edad_cut

graph hbar (count) id_paciente, over(sexo) over(edad_cut) asyvars bar(1, fcolor(cranberry)) bar(2, fcolor(navy)) ytitle("# Pacientes") title("Pacientes distribuidos por sexo y edad")
graph export sexo_edad.tif, replace


/*Enfermedad coronaria vs tipo de dolor toracico*/
tab dolor angio, row col


log close
