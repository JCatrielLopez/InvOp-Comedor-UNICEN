# ANÁLISIS Y SIMULACIÓN DE COLAS DEL COMEDOR
 
* JORGE CATRIEL LÓPEZ   jlopez@alumnos.exa.unicen.edu.ar
* NATALIA SEVERINO   nseverino@alumnos.exa.unicen.edu.ar
 
Facultad de Ciencias Exactas - Universidad del Centro de la Provincia de Buenos Aires
______________________________________________________________________________________________

 
# 1. RESUMEN
A lo largo de los años se ha observado que en el comedor de la universidad en Tandil los tiempos de espera para la compra de menús han ido aumentando, llegando a casos donde un alumno puede estar esperando durante más de una hora para poder almorzar.         
A su vez, la gran congestión de gente genera una presión adicional sobre el personal encargado de producir y distribuir los menús, provocando muchas veces resultados en la cocina poco favorables. 

Mediante el siguiente trabajo se analizan los resultados de proponer dos soluciones: la implementación de turnos para almorzar por facultad, y turnos por cantidad de personas en un determinado intervalo. Estos dos escenarios más la situación actual fueron simulados. En los tres casos se pueden modificar distintos parámetros y luego ver gráficamente una comparación entre las simulaciones efectuadas.
 
# 2.PALABRAS CLAVE
Colas - Simulación - Comedor - Tiempo  de espera - Optimización - Turnos

# 3.ABSTRACT 
Over the years it has been noted that the waiting times for the purchase of a meal in the dining hall of the university in Tandil has gone up significantly, having cases where a student may be waiting for over an hour to be able to have lunch. At the same time, the large congestion of people results in an additional pressure to the staff in charge of the cooking and distribution of the meals, which generates less than favorable results in the kitchen. 
Through the next work the results of two potential solutions are analyzed: the implementation of shifts by departments of the university, and shifts by an amount of people in a certain interval of time. These scenarios plus the current situation were simulated. In the three cases is possible to modify differents parameters and then get a graphically comparison between the simulations made.
 
# 4.KEY WORDS
Queue - Waiting time - Simulation -   Optimization - Dining Hall 
 
# 5.INTRODUCCION
Para el desarrollo del trabajo se planteó la implementación de tres simulaciones de eventos discretos:

Una simulación reflejando el comportamiento del comedor normalmente. Esto implica la generación de alumnos según una distribución que se ajuste a lo que vemos reflejado en las transacciones del dia a dia durante los horarios de 11:00hs a 15:00hs.
Una simulación donde se implementen turnos por facultad. Esto significa que, en un determinado horario, solamente habrá en el comedor alumnos de una determinada facultad.

Una simulación donde los turnos se implementar por cantidad de personas. Esto significa que se determina un tope de personas a las cuales se les puede servir el almuerzo en un tiempo determinado.

Estas simulaciones fueron implementadas en Python, y se presentan los resultados en un dashboard implementado en R.
Para poder desarrollar el estudio, se debe primero definir algunos conceptos claves:

## 5.1 Modelo de colas
La teoría de colas es el estudio de la espera en las distintas modalidades. Utilizan los modelos de colas para representar los tipos de sistemas de líneas de espera que surgen en la práctica (Hillier et al., 2011). Es decir, un modelo de colas es una representación de una fila de espera, y la teoría de colas estudia el comportamiento de estas. En un proceso básico, los clientes que requieren un servicio se generan en una fuente de entrada. La ocurrencia de un evento es independiente de la ocurrencia de otro.   Entran al sistema y se unen a una cola. En determinado momento se selecciona un miembro de la cola para proporcionarle el servicio mediante alguna regla conocida como disciplina de la cola. Algunas de estas disciplinas pueden ser first-come-first-serve (FCFS), aleatoria o por prioridad.  Se lleva a cabo el servicio que el cliente requiere mediante un mecanismo de servicio, durante el cual se consume alguno de los recursos del sistema por parte del cliente, y después el cliente sale del sistema. (Hillier et al., 2011).
En el trabajo se estudian las tres colas que se producen en el comedor:

La primer cola se produce desde la entrada hasta que el cliente interactúa con el personal en una de las cajas disponibles. En ese momento el cliente solicita su producto, y se dirige a la siguiente cola.
En la segunda cola, la cual inicia inmediatamente al final de la primera, dura hasta que el cliente recibe su compra de manos del personal de la zona de servicio.

Al recibir su compra, el cliente se dirige a un asiento disponible, teniendo que esperar si no se encuentra ninguno disponible. En general, esta cola de espera es inexistente, no suele ocurrir que no haya un asiento disponible. Si pasa en la realidad que se vean clientes esperando para sentarse: esto se debe a que muchos clientes llegan y almuerzan en grupo, lo cual hace que encontrar varios asientos contiguos disponibles sea más complejo. Como esta cola es la menos influyente en el problema estudiado, se tuvo en cuenta un modelo más simple donde cada cliente almuerza individualmente.

## 5.2 Simulación
Farahmand y Martínez definen la simulación como “el proceso de diseñar un modelo lógico-matemático de un sistema real y experimentar con el mismo en una computadora” (Farahmand, Martínez; 1996). La fase de experimentación permite obtener información sobre distintos comportamientos del sistema que no podrían medirse en la realidad, o por lo menos no podrían medirse sin caer en costos excesivos. Simular un ambiente virtual permite las variaciones del modelo de manera rápida y eficiente. 

Los modelos de simulación pueden describirse en varias categorías (Jordan, 1977). Estas categorías no son mutuamente exclusivas:
Los modelos empíricos o racionales, diferenciados en que los primeros son descripciones matemáticos cuyas distribuciones se ajustan a información observable, mientras que los modelos racionales son modelos matemáticos causales obtenidos mediante el razonamiento de la estructura y comportamiento del sistema. Es decir, estos últimos incluyen las fuerzas y mecanismos internos del sistema para definir la interpretación de sus parámetros (Jordan, 1977).

Los modelos estocásticos o determinísticos. En un modelo determinístico, los resultados se expresan como funciones de variables particulares identificadas y parámetros asociados. Es un modelo donde las mismas entradas producirán invariablemente las mismas salidas, no contemplándose la existencia del azar ni el principio de incertidumbre. Es decir, solamente se incluyen los aspectos que pueden ser explicados en el modelo. En un modelo estocástico se tienen en cuenta aquellos aspectos que no pueden explicarse. (Jordan, 1977) Esto significa que subsiguiente estado del sistema está determinado tanto por las acciones predecibles del proceso como por elementos aleatorios. El término estocástico se aplica a modelos en los que existe una secuencia cambiante de eventos a medida que pasa el tiempo.

## 5.3 Point of Sale data
El punto de venta (POS, por sus siglas en inglés) es el tiempo y lugar donde ocurre la transacción. En este caso, analizamos las transacciones registradas en las cajas del comedor. Esta información consiste en la fecha de la venta, el tipo de cliente y su facultad, el producto en cuestión y el monto correspondiente. 

## 5.4 Medidas de performance
Al proponer dos posibles soluciones a la problemática del comedor, se deben definir ciertas métricas de comparación para poder definir si las soluciones son efectivas, y en qué medida. Estas son:

Tiempo de espera por persona: Tiempo promedio en minutos en el que un cliente esta haciendo cola para cada servicio requerido.
Cantidad promedio de clientes atendidos por hora: Cuántos clientes se atendieron en una hora.
Tiempo de respuesta: Tiempo que un cliente estuvo en el sistema, desde que ingresa a este hasta su salida.
Porcentaje de tiempo útil: Fracción de tiempo en la que el usuario no se encuentra esperando dentro del sistema.

Finalmente, los autores de este trabajo quieren destacar la ayuda recibida de parte de Sandra González Cisaro, Rafael Curtoni, Oscar Nigro, Leandro Gomes, Bernardo Troffer y Ariel Borthiry.


# REFERENCIAS

CANAVOS G. C. (1988): Probabilidad y Estadística Aplicaciones y métodos. McGraw-Hill.

FARAHMAND K., MARTINEZ A. F. G. (1996): “Simulation and Animation of the Operation of a Fast Food Restaurant”. Proceedings of the 1996 Winter Simulation Conference. Versión obtenida el 11/01/19.
https://www.informs-sim.org/wsc96papers/181.pdf

HILLIER F. (2011): Introducción a la investigación de operaciones. McGraw-Hill.

JORDAN S. R. (1977): "A Computer Simulation Model of the Service Component of a Fast Food Operation: Development, Validation,and Use.” PhD diss., University of Tennessee. Versión obtenida el 11/01/19.
https://trace.tennessee.edu/cgi/viewcontent.cgi?&article=5526&context=utk_graddiss

TAHA H. (2012) Investigación de Operaciones. Pearson.    

---

## Para instalarlo:

* En Ubuntu: sudo apt-get install libpq-dev
* En R-Studio: install.packages(c("shiny", "DT", "data.table", "RPostgreSQL", "ggplot2", "scales", "ggcorrplot", "radarchart", "reshape", "shinydashboard", "shinyjs"))
