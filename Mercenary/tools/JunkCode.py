# !/usr/bin/env python
# coding=utf-8
#
# JunkCode.py
# @author Jiessen
# @description
# @created Wed Nov 21 2018 12:26:24 GMT+0700 (东南亚标准时间)
# @last-modified Tue Nov 27 2018 14:01:05 GMT+0700 (东南亚标准时间)
#

import os
import random
import string
import shutil
import time

path = './Desktop/20190510/20190508/minigame/frameworks/cocos2d-x/cocos'
print(os.path.abspath(path))
tempPath = "./Desktop/20190510/20190508/minigame/frameworks/cocos2d-x/cocos/base"
curPath = "./Desktop/20190510/20190508/minigame/tools/__RefCode.h"
ocPath = './Desktop/20190510/20190508/minigame/frameworks/runtime-src/proj.ios_mac/ios'
curPath1 = "./Desktop/20190510/20190508/minigame/tools/__RefCodeEx.h"
curPath2 = "./Desktop/20190510/20190508/minigame/tools/__RefCodeEx.m"
curPath3 = "./Desktop/20190510/20190508/minigame/tools/__MainCall.h"
curPath4 = "./Desktop/20190510/20190508/minigame/tools/__MainCall.m"

print(os.path.abspath(curPath1))
print(os.path.abspath(curPath2))
print(os.path.abspath(curPath3))
print(os.path.abspath(curPath4))

ocClassPath = './Desktop/20190510/20190508/minigame/frameworks/runtime-src/proj.ios_mac/ios/AppController.mm'

className = ""
param = ""
COUNT = 200     #添加文件个数
COUNT_EX = 10   # 添加方法数量


def randomStr(lenth):
    return ''.join(random.sample(string.ascii_letters, lenth))


def alter(file, oldlist, newlist):
    file_data = ""
    with open(file, "r") as f:
        for line in f:
            for i in range(len(oldlist)):
                if oldlist[i] in line:
                    line = line.replace(oldlist[i], newlist[i])
            file_data += line

    with open(file, "w") as f:
        f.write(file_data)

def insert_C_Code(file):
    [_,filename]=os.path.split(file)
    [fname,_]=os.path.splitext(filename)

    file_data = ""
    flag = False
    curIdx = 0
    codeList = []
    with open(file, "r") as f:
        for line in f:
            if "NS_CC_BEGIN" in line:
                flag = True
                file_data += ("#include \"base/{0}.h\"\n".format(className))
                for i in range(COUNT_EX):
                    #define  __REFUSE_001  CRefuse01 _ref000001;
                    string = "#define {0}_{1}_{2} {0} _{3}{2};\n".format(className, fname, i, className.lower())
                    file_data += string
                    codeList.append("{0}_{1}_{2};\n".format(className, fname, i))

            if "{\n" == line:
                if curIdx < len(codeList):
                    line = line.replace('{\n',"{\n\t"+codeList[curIdx])
                    curIdx = curIdx + 1
            
            if flag:
                file_data += "\n"
                flag = False
                
            file_data += line

    with open(file, "w") as f:
        f.write(file_data)

    print(file + " 插入成功")
  
def create_C_class():
    newName = os.path.join(tempPath, className+".h")

    if os.path.exists(os.path.join(tempPath, "__RefCode.h")):
        os.rename(os.path.join(tempPath, "__RefCode.h"), newName)
    else:
        shutil.copyfile(curPath, newName)

    oldlist = ["__REF_CODE_H", "G_TEP_NUM", "__RefCode", "WriteTxt", "ReadTxt"]
    newlist = [className.upper()+"_H", param, className, randomStr(7), randomStr(8)]
    alter(newName, oldlist, newlist)
    print("创建C++ 类成功 "+newName)

def insert_OC_Code(path, name):
    newNameH = os.path.join(path, name+'.h')
    shutil.copyfile(os.path.abspath(curPath1), newNameH)
    newNameMM = os.path.join(path, name+'.m')
    shutil.copyfile(os.path.abspath(curPath2), newNameMM)

    ## 修改.h
    oldListH = ['__RefCodeEx', '_name', '_value', 'readTxt', 'writeTxt', 'newRefCodeEx']
    newListH = [name, '_'+randomStr(4), '_'+randomStr(5),randomStr(8).title(), randomStr(6).title(),'Call'+name]

    alter(newNameH, oldListH, newListH)

    ## 修改.m
    oldListMM = ['__RefCodeEx', 'G_Value','readTxt', 'AAA', 'BBB', 'CCC', 'writeTxt','newRefCodeEx']
    newListMM = [name, 'G_'+randomStr(4).capitalize(), newListH[3],randomStr(8), randomStr(10), randomStr(15),newListH[4],'Call'+name]
    alter(newNameMM, oldListMM, newListMM)

## 创建oc类的数量
def create_OC_class(count):
    dirName = randomStr(6).capitalize()
    dirPath = os.path.join(ocPath, dirName)

    classList = []
    os.mkdir(dirPath)

    for i in range(count):
        classList.append(randomStr(8).title())
        insert_OC_Code(dirPath, classList[i])

    ## 创建主类
    mainClass = ('__'+randomStr(5)+'Main').title()
    mainPathH = os.path.join(dirPath, mainClass + '.h')
    mainPathM = os.path.join(dirPath, mainClass + '.m')
    
    shutil.copyfile(os.path.abspath(curPath3), mainPathH)
    shutil.copyfile(os.path.abspath(curPath4), mainPathM)

    oldH = ['__RefCodeEx','IOSGame-mobile','newRefCodeEx']
    newH = [mainClass, 'Game'+mainClass,'new'+mainClass]
    alter(mainPathH, oldH, newH)

    allClass = ''
    allFunc = ''
    for i in range(len(classList)):
        allClass += "#import \""+classList[i]+".h\"\n"
        allFunc += "["+ classList[i] +" Call"+ classList[i] +"];\n\t"

    oldM = ['__RefCodeEx','IOSGame-mobile','newRefCodeEx','//AAA','//XXX']
    newM = [mainClass, 'Game'+mainClass,'new'+mainClass,allClass,allFunc]
    alter(mainPathM, oldM, newM)

    oldMApp = ['//#import "oc_classes.h"','//        [CoreToolsEx mainCall]']
    newMApp = ['#import "{}.h"'.format(dirName+"/"+mainClass),'[{0} new{0}]'.format(mainClass)]
    alter(ocClassPath, oldMApp, newMApp)

    print("创建oc类成功")

def detect_walk(dir_path):
    create_C_class()

    idx = 0
    for parent, dirnames, filenames in os.walk(dir_path,  followlinks=True):
        for filename in filenames:
            file_path = os.path.join(parent, filename)
            if parent != "base":
                if os.path.splitext(file_path)[1] == ".cpp":
                    # print('文件名：%s' % filename)
                    # print('文件完整路径：%s\n \n' % file_path)

                    if not ("-" in filename):
                        insert_C_Code(file_path)

                    if idx > COUNT:
                        break

    create_OC_class(200)

if __name__ == "__main__":
    className = "__"+randomStr(8)
    param = "G_"+randomStr(7)
    # print(className)
    # create_C_class()
    detect_walk(os.path.abspath(path))
    
