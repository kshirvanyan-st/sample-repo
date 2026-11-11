from lib import *
import json
ids=[]
def L(fn): ids.append(fn()); return fn

@L
def l1():
    write("6-1","Drain First",61,
      shapes=[rect("dirt",0,70,128,110), circle("lava",64,100,14),
              rect("drain",100,158,24,6), cupw(40,200,48,36)],
      spouts=[spout(64,6,"sand",3,1000,6,60)],
      cups=[goal(43,200,42,33,"sand",450,["lava"])],
      hint="Get rid of the lava before the sand goes through",
      solution=[dig(0,64,112,108,158), dig(700,64,66,64,186)],
      traps=[[dig(0,64,66,64,186)]])
    return "6-1"

@L
def l2():
    write("6-2","Kindling",62,
      shapes=[rect("wall",40,14,3,66), rect("wall",122,14,3,66),
              rect("plant",8,80,116,16),
              rect("sand",43,30,79,50),
              rect("stone",8,56,32,24), rect("lava",11,59,26,17),
              rect("drain",4,224,36,4),
              rect("dirt",44,130,84,40), cupw(70,200,52,36)],
      cups=[goal(73,200,46,33,"sand",700,["lava"])],
      blasts=1, hint="Blasts break stone. Lava burns plants.",
      solution=[boom(0,24,80), dig(0,96,126,96,176)],
      traps=[[boom(0,80,84), dig(0,96,126,96,176)]])
    return "6-2"

@L
def l3():
    write("6-3","Hot Swap",63,
      shapes=[cupw(6,14,40,30), rect("lava",9,32,34,9), gate(1,18,41,16,3),
              cupw(66,14,40,40), rect("water",69,26,34,25), gate(2,78,51,16,3),
              rect("dirt",0,70,128,110), rect("wall",60,100,52,4),
              cupw(6,200,44,36), cupw(78,200,44,36)],
      cups=[goal(9,200,38,33,"stone",35), goal(81,200,38,33,"water",300,["lava"])],
      hint="One cup wants stone, the other wants water",
      solution=[tap(0,26,42), dig(0,26,66,26,186), dig(0,86,66,86,96),
                dig(0,86,96,116,96,116,186), dig(0,86,96,56,96,30,130), tap(150,86,52)],
      traps=[[tap(0,26,42), dig(0,26,66,26,186), dig(0,86,66,86,96), dig(0,86,96,116,96,116,186), tap(150,86,52)]])
    return "6-3"

@L
def l4():
    write("6-4","Lava Lamp",64,
      shapes=[rect("dirt",0,50,128,140), rect("wall",30,110,74,4), rect("drain",56,108,16,2),
              cupw(4,10,36,34), rect("lava",7,22,30,19), gate(1,14,41,16,3),
              cupw(78,200,44,36)],
      spouts=[spout(100,6,"water",3,1500,6,60)],
      cups=[goal(81,200,38,33,"lava",300,["water"])],
      hint="This cup wants lava. Keep the water out.",
      solution=[dig(0,100,46,100,104,60,104), tap(0,22,42), dig(0,22,46,22,118,100,168,100,196)],
      traps=[[tap(0,22,42), dig(0,22,46,22,118,100,168,100,196)]])
    return "6-4"

@L
def l5():
    write("6-5","Firebreak",65,
      shapes=[rect("wall",1,20,3,64), rect("wall",42,20,5,40), rect("wall",42,60,3,16),
              rect("wall",77,20,16,40), rect("wall",79,60,14,16), rect("wall",124,20,3,64),
              rect("plant",4,76,41,8), rect("plant",45,60,2,24), rect("plant",77,60,2,24), rect("plant",79,76,45,8),
              rect("sand",4,30,38,46), rect("lava",47,44,30,16), gate(1,47,60,30,4), rect("water",93,30,31,46),
              rect("dirt",0,100,60,90), rect("drain",43,96,52,2),
              cupw(54,200,44,36)],
      cups=[goal(57,200,38,33,"sand",500,["water","lava"])],
      blasts=1, hint="Fire spreads through every plant it touches",
      solution=[boom(0,85,80), tap(0,62,61), dig(0,22,98,62,150)],
      traps=[[tap(0,62,61), dig(0,22,98,62,150)]])
    return "6-5"

@L
def l6():
    write("6-6","Secret Garden",66,
      shapes=[rect("dirt",0,40,128,160), circle("lava",44,110,11), circle("lava",84,160,10),
              cupw(66,200,56,36), rect("plant",69,229,50,4)],
      spouts=[spout(24,6,"water",4,1400,6,60)],
      cups=[goal(69,200,50,29,"plant",120,["lava"])],
      hint="Water the seeds and the garden grows",
      solution=[dig(0,24,36,24,180,92,196)],
      traps=[[dig(0,24,36,92,196)]])
    return "6-6"

@L
def l7():
    write("6-7","Sluice",67,
      shapes=[cupw(4,10,46,40), rect("sand",7,12,40,35), gate(1,18,47,18,3),
              rect("water",50,100,28,26),
              line("wall",8,70,52,130,3), line("wall",119,70,76,130,3),
              rect("dirt",30,131,68,40), rect("drain",76,163,18,5),
              cupw(40,196,48,40)],
      cups=[goal(43,196,42,33,"sand",600,["water"])],
      hint="Deal with the water before the sand comes down",
      solution=[dig(0,72,133,86,160), tap(400,27,48), dig(400,64,134,64,190)],
      traps=[[tap(0,27,48), dig(0,64,134,64,190)], [dig(0,72,133,86,160), tap(0,27,48), dig(0,64,134,64,190)]])
    return "6-7"

@L
def l8():
    write("6-8","Quarry",68,
      shapes=[rect("dirt",0,50,128,60), rect("stone",0,110,128,14),
              circle("lava",64,117,5), circle("lava",100,117,5),
              rect("dirt",0,124,128,56), cupw(40,200,48,36)],
      spouts=[spout(64,6,"sand",3,1000,6,60)],
      cups=[goal(43,200,42,33,"sand",500,["lava"])],
      blasts=1, hint="One blast. Choose the spot carefully.",
      solution=[dig(0,64,46,24,106), boom(0,24,117), dig(0,24,128,56,196)],
      traps=[[dig(0,64,46,64,106), boom(0,64,108), dig(0,64,126,64,196)],
             [dig(0,64,46,100,106), boom(0,100,108), dig(0,100,128,72,196)]])
    return "6-8"

@L
def l9():
    write("6-9","Trinity",69,
      shapes=[cupw(4,4,36,40), rect("sand",7,14,30,27), gate(1,13,41,18,3),
              cupw(46,4,36,36), rect("lava",49,27,30,10), gate(2,55,37,18,3),
              rect("dirt",0,56,128,124), rect("wall",80,100,34,4),
              cupw(2,200,38,36), cupw(45,200,38,36), cupw(88,200,38,36)],
      spouts=[spout(96,6,"water",3,1100,6,60)],
      cups=[goal(5,200,32,33,"sand",400,["water","lava"]), goal(48,200,32,33,"stone",30),
            goal(91,200,32,33,"water",300,["sand","lava"])],
      hint="Three cups, three treasures",
      solution=[tap(0,21,42), dig(0,22,52,22,186), tap(0,63,38), dig(0,64,52,64,186),
                dig(0,96,52,96,96), dig(0,96,96,118,96,118,186), dig(0,96,96,76,96,66,128)],
      traps=[[tap(0,21,42), dig(0,22,52,22,186), tap(0,63,38), dig(0,64,52,64,186),
              dig(0,96,52,96,96), dig(0,96,96,118,96,118,186)]])
    return "6-9"

@L
def l10():
    write("6-10","The Alchemist",610,
      shapes=[rect("wall",2,10,3,50), rect("wall",36,10,3,50),
              rect("plant",5,60,52,16), rect("plant",55,40,2,20),
              rect("sand",5,20,31,40),
              cupw(48,4,34,36), rect("lava",51,24,28,13), gate(2,57,37,18,3),
              cupw(86,4,40,40), rect("water",89,16,34,25), gate(3,98,41,16,3),
              rect("dirt",0,90,56,90), rect("dirt",86,56,42,124), rect("wall",92,100,26,4),
              cupw(42,180,44,56), rect("stone",45,186,38,4),
              cupw(2,200,38,36), cupw(88,200,38,36)],
      cups=[goal(5,200,32,33,"sand",500,["water","lava"]), goal(45,196,38,37,"stone",30),
            goal(91,200,32,33,"water",250,["sand","lava"])],
      blasts=1, hint="Fire frees the sand. Water and lava make stone.",
      solution=[boom(0,64,188), tap(0,65,38), dig(0,20,86,20,186),
                dig(0,106,52,106,96), dig(0,106,96,120,96,120,186), dig(0,106,96,88,96,86,110), tap(120,106,42)],
      traps=[[boom(0,20,66), tap(0,65,38), dig(0,20,86,20,186), dig(0,106,52,106,96),
              dig(0,106,96,120,96,120,186), dig(0,106,96,88,96,86,110), tap(120,106,42)],
             [boom(0,64,188), tap(0,65,38), dig(0,20,86,20,186), dig(0,106,52,106,96),
              dig(0,106,96,120,96,120,186), tap(120,106,42)]])
    return "6-10"

json.dump([{"id":6,"name":"Alchemy","free":False,"levels":ids}],open(D+"/chapters.json","w"))
