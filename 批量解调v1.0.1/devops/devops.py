# coding=utf-8
import os
import re
import datetime
# import xlrd, xlwt

import matlab
import matlab as matlab1
import matlab.engine

import multiprocessing
from multiprocessing import Pool, Value, Array, Manager
import time

class AISSig():
    def createAISSig(self):
        path = "../devops/AISSig"
        # latList = [31.8029, 28.3044, 14.9448, 37.44, 37.1603, 39.3683, 37.9962]
        # lonList = [102, 120.2344, 112.1484, 164.8828, 44.6484, -76.9922, -125.1563]
        latList = [31.8029, 30.6, 16.3, 34.59, 8, 35.74, 39.63]
        lonList = [102, 124.45, 113.55, 137, 75.76, -82.9688, -132.9]
        heightList = [600, 700]
        modeList = [0] # 0 代表均匀分布， 1~6 分别代表六个实际分布
        # thriftAngleList = [20, 48]                                                                        # 2016年6月初
        thriftAngleList = [0]                                                                               # 2016年6月24
        # vesnumList = [1, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000]                       # 2016年6月初
        vesnumList = [500, 1000, 1500, 2000, 2500, 3000, 3500, 4000]
        distri_ratio = 1                                                                                                                                                                                             # 2016年6月24
        # obtimeList = [320]                                                                                # 2016年6月初
        obtimeList = [60]                                                                                   # 2016年6月24
        snr = 10                                                                                            # 2016年6月24
        os.chdir('../genAISSig_model')
        ant_list = os.listdir('./recAnt')
        # print ant_list
        current = os.getcwd()
        recAnt = os.path.join(current, './recAnt')
        # print recAnt
        eng = matlab.engine.start_matlab()
        for height in heightList:
          for mode in modeList: 
            for ant in ant_list:
                for thriftAngle in thriftAngleList:
                  for vesnum in vesnumList:
                    for obtime in obtimeList:
                      try:
                        rec_ant = os.path.join(recAnt, ant)
                        eng.Main(float(mode), float(height), float(lonList[mode]), float(latList[mode]), rec_ant,\
                        float(thriftAngle), float(vesnum), float(obtime), float(snr), path, float(distri_ratio))
                      except Exception as exp:
                        msg = "height_%dmode_%dtriftangel_%dobtime_%dvesnum_%dsnr_%d:\n%s" %\
                        (height, mode, thriftAngle, obtime, vesnum, snr, str(exp))
                        print ('create signal failed')
                        error.add_error_msg(msg)
        eng.quit()
        os.chdir('../devops/')
sig = AISSig()

class Demo():
    def antDemo(self, lock, alive, ready):
        current = os.getcwd()
        aissig = os.path.join(current, './AISSig')
        os.chdir('../singleantv2.0.1/') # 切换单天线解调
        # os.chdir('../doubleantv2.0.1/') # 切换双天线解调
        print ("current pwd is %s" % os.getcwd())
        eng = matlab.engine.start_matlab()
        while(alive):
            lock.acquire()
            file_name = alive[0]
            del alive[0]
            print (file_name)
            print ("cur ready is ", ready)
            if file_name == '.' or file_name == '..' or file_name == '.DS_Store':
                lock.release()
                continue
            sigpath = os.path.join(aissig, file_name)
            if not os.path.exists(sigpath):
                lock.release()
                continue
            ready.append(file_name)
            lock.release()
            eng.Main(sigpath)
        eng.quit()
        os.chdir('../devops/')

demo = Demo()
    
def multiproc():
    print ("demo begin")
    manager = Manager()
    # proc = multiprocessing.Process(target = sig.createAISSig)
    # proc.daemon = True
    # proc.start()
    # proc.join()
    file_list = os.listdir('./AISSig')
    alive = manager.list(file_list)
    ready = manager.list([])
    lock = multiprocessing.Lock()
    proc1 = multiprocessing.Process(target = demo.antDemo, args = (lock, alive, ready))
    proc1.daemon = True
    proc2 = multiprocessing.Process(target = demo.antDemo, args = (lock, alive, ready))
    proc2.daemon = True
    proc1.start()
    proc2.start()
    proc1.join()
    proc2.join()

    print ("demo end")
        

def getdataparam(filename):
    pattern = re.compile(r'^AIS(Data)_h\d+_t\d+_v(\d+)_e\d+')
    match = pattern.match(filename)
    print (filename)
    if match:
        return match.groups()
    return None

class Analysis():
    def check(self):
        res = {}
        file_list = os.listdir('./AISSig')
        current = os.getcwd()
        aissig = os.path.join(current, './AISSig')
        os.chdir('../checkprob/conflictcheck')
        eng = matlab.engine.start_matlab()
        for file_name in file_list:
            if file_name == '.' or file_name == '..' or file_name == '.DS_Store':
                continue
            sigpath = os.path.join(aissig, file_name) + '/'
            resultpath = os.path.join(sigpath, 'demodResult_1ant/')
            filename = os.listdir(sigpath)
            for k in filename:
                data = getdataparam(k)
                print (data)
                if not data or not data[0]:
                    continue
                dataname = os.path.join(sigpath, k)
                print (resultpath + k + sigpath)
                prob = eng.detectProbability(resultpath, k, sigpath)
                if not res.has_key(int(data[1])):
                    res[int(data[1])] = prob
                # if not res[int(data[1])].has_key(int(data[2])):
                #     res[int(data[1])][int(data[2])] = {}
                # if not res[int(data[1])][int(data[2])].has_key(int(data[3])):
                #     res[int(data[1])][int(data[2])][int(data[3])] = prob
        eng.quit()
        os.chdir('../../devops/')
        print (res)
        return (res)
anay = Analysis()

def genXlsFormat(result):
    """
    TODO: from txt gen xls
    """
    ft = open('./result.txt', 'w+')
    #for eb, value in result.iteritems():
    #    for po, pr in value.iteritems():
    items = result.items()
    items.sort()
    for v, p in items:
        context = str(v) + " " + str(p) + '\n'
        ft.write(context)
        print (v, p)
            

class error_msg():
    def add_error_msg(self, msg, *args, **kwargs):
        if not os.path.exists('./error_log.txt'):
            fe = open('./error_log.txt', 'w')
            fe.close()
        fe = open('./error_log.txt', 'a')
        now = str(datetime.datetime.now())[0: 19]
        context = now + '\n' +str(msg) + '\r\n'
        fe.write(context)
        for item in args:
            context_item = str(item) + '\r\n'
            fe.write(context_item)
        fe.close()
error = error_msg()


if __name__ == '__main__':
    #sig.createAISSig()
     multiproc()
     #res = anay.check()
     #genXlsFormat(res)
