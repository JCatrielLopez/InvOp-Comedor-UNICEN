import simpy
import random
import pandas as pd
from simpy.util import start_delayed

RANDOM_SEED = 2019

# name | start_time | end_time | clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
dataframe = []
resources = []
listtotal = []

class MonitoredResource(simpy.Resource):

    def __init__(self, n, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.name = n
        self.data = []

    def request(self, *args, **kwargs):
        self.data.append([self._env.now, self.name, len(self.queue), self.count])
        return super().request(*args, **kwargs)

    def release(self, *args, **kwargs):
        self.data.append([self._env.now, self.name, len(self.queue), self.count])
        return super().release(*args, **kwargs)

def get_total():
    return listtotal

def get_resources():

    out = []
    # resource | avg_queue_length | max_queue_length | avg_count
    for i in resources:
        df = pd.DataFrame(i.data, columns=['time', 'name', 'length_queue', 'count'])
        out.append([i.name, df["length_queue"].mean(), df["length_queue"].max(), df["count"].mean()])

    return pd.DataFrame(out, columns=['resource', 'avg_queue_length', 'max_queue_length', 'avg_count'])

def student_trajectory(name, turno, env, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, facultad, mes):

    # print("({:06.2f} min) [{}] Entrada al comedor.".format(env.now / 60, name))
    arrival = env.now
    compra = 0
    queue_clerk = 0 # Las inicializo aca porque si te vas a la caja automatica, no existe queue_clerk, y lo mismo pasa al reves y despues tira error.
    automatic_clerk_queue = 0
    sentarse = 0
    third_queue = 0


    rand=random.random()

    if (rand<=0.65):
        with clerk.request() as req:
            #print("({:06.2f} min) [{}] Esta en la cola de la caja.".format(env.now / 60, name))
            yield req
            queue_clerk = env.now - arrival
            if env.now >= 14400:
                print("({:06.2f} min) [{}] Ya no se venden mas menus".format(env.now / 60, name))

            else:
                compra = 1
                #print("({:06.2f} min) [{}] Esta en la caja.".format(env.now / 60, name))
                #print("[{}] Estuvo en la cola de la caja {:06.2f} min".format(name, queue_clerk / 60))
                yield env.timeout(tiempoCaja)
    else:
        with automatic_clerk.request() as req:
            #print("({:06.2f} min) [{}] Esta en la cola de la caja con tarjeta.".format(env.now / 60, name))
            yield req
            automatic_clerk_queue = env.now - arrival
            if env.now >= 14400:
                print("({:06.2f} min) [{}] Ya no se venden mas menus".format(env.now / 60, name))


            else:
                compra = 1
                #print("({:06.2f} min) [{}] Esta en la caja con tarjeta.".format(env.now / 60, name))
                #print("[{}] Estuvo en la cola de la caja con tarjeta {:06.2f} min".format(name, automatic_clerk_queue / 60))
                yield env.timeout(random.randint(15,20))

    if (compra == 1):
        #print("({:06.2f} min) [{}] Esta en la cola de entrega.".format(env.now / 60, name))
        menu = env.now

        sentarse = env.now
        req_silla = seats.request()   #se sienta aunque no tiene menu porque es un forro

        yield req_silla
        #print("ocupa silla")

        third_queue = env.now - sentarse
        #print("[{}] Estuvo en la cola para sentarse {:06.2f} min".format(name, third_queue / 60))

        with server.request() as req:
            yield req
            yield delivery.get(1)
            second_queue = env.now - menu
            #print("({:06.2f}) [{}] Estuvo en la cola para retirar menu {:06.2f} min".format(env.now / 60, name, second_queue / 60))
            yield env.timeout(
                random.randint(3, 15))  # Tiempo hasta que se queda sin voz por gritar el numero: entre 3 y 15 seg

        #print("({:06.2f} min) [{}] Tiene menu. Solicita un asiento.".format(env.now / 60, name))

        yield env.timeout(random.randint(1800, 3600))  # entre 30min (1800 segundos) y 60 min (3600 segundos)
        yield seats.release(req_silla)


        #print("({:06.2f} min) [{}] Termina de comer, se va.".format(env.now / 60, name))

        # name | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        row = [name,
               turno,
               mes,
               facultad,
               arrival / 60,
               env.now / 60,
               queue_clerk / 60,
               automatic_clerk_queue / 60,
               second_queue / 60,
               third_queue / 60,
               (queue_clerk + max(second_queue, third_queue) + automatic_clerk_queue) / 60.0,
               ((env.now - arrival) - (queue_clerk + max(second_queue, third_queue) + automatic_clerk_queue)) / 60.0]
        dataframe.append(row)


def kitchen(env, delivery, cantMenus, tiempoCocina):
    for i in range(100):
        #print("cant menus {}".format(delivery.level))

        yield delivery.put(cantMenus)

        #print('({:06.2f} min) Se cocinaron {} menus'.format(env.now / 60, cantMenus))
        yield env.timeout(tiempoCocina)



def door(env, pase, cantCapacidad):
    for i in range(5):
        x=pase.level
        if x>0:
            yield pase.get(x)
        yield pase.put(cantCapacidad)
        yield env.timeout(3600)


def student_generator(env, turno, fac, students, interval, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, month):
    for i in range(students):
        yield env.timeout(random.expovariate(1.0 / interval))
        for i in range(random.randint(1, 2)):
            if (env.now <= 14400):
                env.process(
                    student_trajectory('turno: {} : {} {}'.format(turno, fac, i), turno, env, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, fac, month))
            else:
                print("({:06.2f} min) [Alumno{}] Llegaste tarde".format(env.now / 60, i))



def student_capacity_generator(env, turno, fac, students, interval, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, pase, month):
    proximoturno={11:3600, 12:7200, 13:10800}
    for i in range(students):
        yield env.timeout(random.expovariate(1.0 / interval))
        if (env.now <= 14400):
            if pase.level>0:
                yield pase.get(1)
                env.process(
                    student_trajectory('turno: {} : {} {}'.format(turno, fac, i), turno, env, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, fac, month))
            else:
                print("comedor lleno")
                if turno!=14:
                    prox=proximoturno[turno]
                    espera=prox-env.now +1
                    if espera<=1200:
                        yield env.timeout(espera)
                        if pase.level>0:
                            yield pase.get(1)
                            env.process(student_trajectory('turno: {} : {} {}'.format(turno+1, fac, i), turno, env, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, fac, month))
        else:
            print("({:06.2f} min) [Alumno{}] Cerro el comedor".format(env.now / 60, i))

def simular(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantCajasTarjeta):

    TOTAL=0
    tiempoCocina=tiempoCocina*60
    tiempoCaja=tiempoCaja*60

    mes={2 : "FEBRERO", 3: "MARZO", 4: "ABRIL", 5: "MAYO", 6:"JUNIO", 7:"JULIO", 8:"AGOSTO",9:"SEPTIEMBRE",10:"OCTUBRE",11:"NOVIEMBRE", 12:"DICIEMBRE"}

    for i in range(2,13):
        print("MES {}".format(i))

        d = pd.read_csv("data/CSVs/tablas_simulacion/{}.csv".format(mes[i]), sep =",")
        dato=d.set_index("fac", drop=False)

        VETE11 = dato.loc["VETERINARIA","11"]
        INTERVALVETE11 = (3600/VETE11)
        EXA11 = dato.loc["EXACTAS","11"]
        INTERVALEXA11 = (3600/EXA11)
        ECON11 = dato.loc["ECONOMICAS","11"]
        INTERVALECON11 = (3600/ECON11)
        HUM11 = dato.loc["HUMANAS","11"]
        INTERVALHUM11 = (3600/HUM11)

        VETE12 = dato.loc["VETERINARIA","12"]
        INTERVALVETE12 = (3600/VETE12)
        EXA12 = dato.loc["EXACTAS","12"]
        INTERVALEXA12 = (3600/EXA12)
        ECON12 = dato.loc["ECONOMICAS","12"]
        INTERVALECON12 = (3600/ECON12)
        HUM12 = dato.loc["HUMANAS","12"]
        INTERVALHUM12 = (3600/HUM12)

        VETE13 = dato.loc["VETERINARIA","13"]
        INTERVALVETE13 = (3600/VETE13)
        EXA13 = dato.loc["EXACTAS","13"]
        INTERVALEXA13 = (3600/EXA13)
        ECON13 = dato.loc["ECONOMICAS","13"]
        INTERVALECON13 = (3600/ECON13)
        HUM13 = dato.loc["HUMANAS","13"]
        INTERVALHUM13 = (3600/HUM13)

        VETE14 = dato.loc["VETERINARIA","14"]
        INTERVALVETE14 = (3600/VETE14)
        EXA14 = dato.loc["EXACTAS","14"]
        INTERVALEXA14 = (3600/EXA14)
        ECON14 = dato.loc["ECONOMICAS","14"]
        INTERVALECON14 = (3600/ECON14)
        HUM14 = dato.loc["HUMANAS","14"]
        INTERVALHUM14 = (3600/HUM14)


        random.seed(RANDOM_SEED)
        env = simpy.Environment()



        automatic_clerk= MonitoredResource("automatic clerk", env, capacity=cantCajasTarjeta)
        clerk = MonitoredResource("clerk", env, capacity=cantCajas)
        seats = MonitoredResource("seats", env, capacity=cantAsientos)
        server = MonitoredResource("server", env, capacity=cantServidores*2) #cada uno agarra dos bandejas
        delivery = simpy.Container(env, capacity=150)

        # de 11.00 a 11.59 (0 a 59 min)
        env.process(student_generator(env, 11, "VETE", VETE11, INTERVALVETE11, clerk, automatic_clerk, server, delivery, seats, tiempoCaja,i))
        env.process(student_generator(env, 11, "EXA", EXA11, INTERVALEXA11, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i))
        env.process(student_generator(env, 11, "ECON", ECON11, INTERVALECON11, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i))
        env.process(student_generator(env, 11, "HUM", HUM11, INTERVALHUM11, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i))

        # de 12.00 a 12.59 (60 a 119 min)
        start_delayed(env, student_generator(env, 12, "VETE", VETE12, INTERVALVETE12, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 3600)
        start_delayed(env, student_generator(env, 12, "EXA", EXA12, INTERVALEXA12, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 3600)
        start_delayed(env, student_generator(env, 12, "ECON", ECON12, INTERVALECON12, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 3600)
        start_delayed(env, student_generator(env, 12, "HUM", HUM12, INTERVALHUM12, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 3600)

        # de 13.00 a 13.59 (120 a 179 min)
        start_delayed(env, student_generator(env, 13, "VETE", VETE13, INTERVALVETE13, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 7200)
        start_delayed(env, student_generator(env, 13, "EXA", EXA13, INTERVALEXA13, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 7200)
        start_delayed(env, student_generator(env, 13, "ECON", ECON13, INTERVALECON13, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 7200)
        start_delayed(env, student_generator(env, 13, "HUM", HUM13, INTERVALHUM13, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 7200)

        # de 14.00 a 14.59 (180 a 239 min)
        start_delayed(env, student_generator(env, 14, "VETE", VETE14, INTERVALVETE14, clerk, automatic_clerk,server, delivery, seats, tiempoCaja, i),
                      10800)
        start_delayed(env, student_generator(env, 14, "EXA", EXA14, INTERVALEXA14, clerk, automatic_clerk,server, delivery, seats, tiempoCaja, i), 10800)
        start_delayed(env, student_generator(env, 14, "ECON", ECON14, INTERVALECON14, clerk, automatic_clerk,server, delivery, seats, tiempoCaja, i),
                      10800)
        start_delayed(env, student_generator(env, 14, "HUM", HUM14, INTERVALHUM14, clerk, automatic_clerk,server, delivery, seats, tiempoCaja, i), 10800)

        env.process(kitchen(env, delivery, cantMenus, tiempoCocina))
        env.run(until=25200)

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        df = None
        df = pd.DataFrame(dataframe, columns=['name', 'turno', 'month', 'facultad', 'start_time', 'end_time', 'clerk_queue', 'automatic_clerk_queue','delivery_queue',
                                              'seating_queue', 'total_waiting_time', 'activity_time'])

        resources.extend([clerk, automatic_clerk, server, seats])
    listtotal.append(TOTAL)
    return df




def simular_conturnos(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantCajasTarjeta, facultad1, facultad2, facultad3, facultad4):

    mes={2 : "FEBRERO", 3: "MARZO", 4: "ABRIL", 5: "MAYO", 6:"JUNIO", 7:"JULIO", 8:"AGOSTO",9:"SEPTIEMBRE",10:"OCTUBRE",11:"NOVIEMBRE", 12:"DICIEMBRE"}
    TOTAL=0

    tiempoCocina=tiempoCocina*60
    tiempoCaja=tiempoCaja*60

    for i in range(2,13):
        d = pd.read_csv("data/CSVs/tablas_simulacion/{}.csv".format(mes[i]), sep =",")
        dato=d.set_index("fac", drop=True)
        print(dato)


        ECON_TOTAL = dato.loc["ECONOMICAS"].sum(axis=0, skipna=True)
        print(ECON_TOTAL)
        EXA_TOTAL = dato.loc["EXACTAS"].sum(axis=0, skipna=True)
        VETE_TOTAL = dato.loc["VETERINARIA"].sum(axis=0, skipna=True)
        HUM_TOTAL = dato.loc["HUMANAS"].sum(axis=0, skipna=True)

        cantidad_alumnos = {"Veterinarias" : VETE_TOTAL, "Exactas": EXA_TOTAL, "Economicas": ECON_TOTAL, "Humanas": HUM_TOTAL}

        TURNO1 = cantidad_alumnos[facultad1]
        TURNO2 = cantidad_alumnos[facultad2]
        TURNO3 = cantidad_alumnos[facultad3]
        TURNO4 = cantidad_alumnos[facultad4]


        INTERVALTURNO1 =  (3600 / TURNO1)
        INTERVALTURNO2 = (3600 / TURNO2)
        INTERVALTURNO3 = (3600 / TURNO3)
        INTERVALTURNO4 = (3600 / TURNO4)

        TOTAL+=TURNO1+TURNO2+TURNO3+TURNO4

        random.seed(RANDOM_SEED)
        env = simpy.Environment()

        automatic_clerk= MonitoredResource("automatic clerk", env, capacity=cantCajasTarjeta)

        clerk = MonitoredResource("clerk", env, capacity=cantCajas)  # pasar de 2 a 3 cajas mejora muchisimo
        seats = MonitoredResource("seats", env, capacity=cantAsientos)
        server = MonitoredResource("server", env, capacity=cantServidores*2)
        delivery = simpy.Container(env, capacity=150)

        env.process(student_generator(env, 11, facultad1, TURNO1, INTERVALTURNO1, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i))

        start_delayed(env, student_generator(env, 12, facultad2, TURNO2, INTERVALTURNO2, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 3600)

        start_delayed(env, student_generator(env, 13, facultad3, TURNO3, INTERVALTURNO3, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 7200)

        start_delayed(env, student_generator(env, 14, facultad4, TURNO4, INTERVALTURNO4, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, i), 10800)

        env.process(kitchen(env, delivery, cantMenus, tiempoCocina))
        env.run(until=25200)

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        df = None
        df = pd.DataFrame(dataframe, columns=['name', 'turno', 'month', 'facultad', 'start_time', 'end_time', 'clerk_queue', 'automatic_clerk_queue','delivery_queue',
                                              'seating_queue', 'total_waiting_time', 'activity_time'])

        resources.extend([clerk, automatic_clerk, server, seats])
    return df



def simular_turnoscapacidad(cantCajas, tiempoCaja, cantServidores, cantAsientos, tiempoCocina, cantMenus, cantCajasTarjeta, cantCapacidad):

    mes={2 : "FEBRERO", 3: "MARZO", 4: "ABRIL", 5: "MAYO", 6:"JUNIO", 7:"JULIO", 8:"AGOSTO",9:"SEPTIEMBRE",10:"OCTUBRE",11:"NOVIEMBRE", 12:"DICIEMBRE"}

    TOTAL=0

    tiempoCocina=tiempoCocina*60
    tiempoCaja=tiempoCaja*60

    for i in range(2,13):
        d = pd.read_csv("data/CSVs/tablas_simulacion/{}.csv".format(mes[i]), sep =",")
        dato = d.transpose()

        TOTAL11 = dato.loc['11'].sum()
        TOTAL12 = dato.loc['12'].sum()
        TOTAL13 = dato.loc['13'].sum()
        TOTAL14 = dato.loc['14'].sum()

        INTERVALTURNO11 =  (3600 / TOTAL11)
        INTERVALTURNO12 = (3600 / TOTAL12)
        INTERVALTURNO13 = (3600 / TOTAL13)
        INTERVALTURNO14 = (3600 / TOTAL14)

        TOTAL+=TOTAL11+TOTAL12+TOTAL13+TOTAL14

        random.seed(RANDOM_SEED)
        env = simpy.Environment()

        automatic_clerk= MonitoredResource("automatic clerk", env, capacity=cantCajasTarjeta)
        clerk = MonitoredResource("clerk", env, capacity=cantCajas)  # pasar de 2 a 3 cajas mejora muchisimo
        seats = MonitoredResource("seats", env, capacity=cantAsientos)
        server = MonitoredResource("server", env, capacity=cantServidores*2)
        delivery = simpy.Container(env, capacity=150)
        pase=simpy.Container(env, capacity=cantCapacidad)


        env.process(student_capacity_generator(env, 11, "", TOTAL11, INTERVALTURNO11, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, pase, i))

        start_delayed(env, student_capacity_generator(env, 12, "", TOTAL12, INTERVALTURNO12, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, pase, i), 3600)

        start_delayed(env, student_capacity_generator(env, 13, "", TOTAL13, INTERVALTURNO13, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, pase, i), 7200)

        start_delayed(env, student_capacity_generator(env, 14, "", TOTAL14, INTERVALTURNO14, clerk, automatic_clerk, server, delivery, seats, tiempoCaja, pase, i), 10800)

        env.process(door(env,pase,cantCapacidad))
        env.process(kitchen(env, delivery, cantMenus, tiempoCocina))
        env.run(until=25200)

        # name | month | facultad | start_time | end_time | clerk_queue | automatic_clerk_queue | delivery_queue | seating_queue | total_waiting_time | activity_time
        df = None
        df = pd.DataFrame(dataframe, columns=['name', 'turno', 'month', 'facultad', 'start_time', 'end_time', 'clerk_queue', 'automatic_clerk_queue','delivery_queue',
                                              'seating_queue', 'total_waiting_time', 'activity_time'])

        resources.extend([clerk, automatic_clerk, server, seats])

    return df



if __name__ == '__main__':
    print("Sourcing file..")
    pass
