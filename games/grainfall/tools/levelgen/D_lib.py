import json, subprocess, sys
SIM = "/home/user/sample-repo/games/grainfall/.build/release/grainfall-sim"
D = "/home/user/sample-repo/games/grainfall/work/D"
def rect(m,x,y,w,h): return {"op":"rect","m":m,"x":x,"y":y,"w":w,"h":h}
def circle(m,cx,cy,r): return {"op":"circle","m":m,"cx":cx,"cy":cy,"r":r}
def line(m,x0,y0,x1,y1,t=3): return {"op":"line","m":m,"x0":x0,"y0":y0,"x1":x1,"y1":y1,"t":t}
def cupw(x,y,w,h,t=3): return {"op":"cup","x":x,"y":y,"w":w,"h":h,"t":t}
def gate(i,x,y,w,h): return {"op":"gate","id":i,"x":x,"y":y,"w":w,"h":h}
def goal(x,y,w,h,acc,req,forbids=()): return {"x":x,"y":y,"w":w,"h":h,"accepts":acc,"required":req,"forbids":list(forbids)}
def spout(x,y,m,rate,total,width=6,delay=60): return {"x":x,"y":y,"m":m,"rate":rate,"total":total,"width":width,"delay":delay}
def dig(t,*pts): return {"t":t,"dig":list(pts)}
def tap(t,x,y): return {"t":t,"gate":[x,y]}
def boom(t,x,y): return {"t":t,"blast":[x,y]}
def write(lid,name,seed,shapes,cups,solution,traps=(),spouts=(),hint=None,blasts=0,budget=9000):
    d={"id":lid,"name":name,"seed":seed,"digBudget":budget,"par":[9000,9000]}
    if blasts: d["blasts"]=blasts
    if hint: d["hint"]=hint
    d["shapes"]=shapes
    if spouts: d["spouts"]=list(spouts)
    d["cups"]=cups; d["solution"]=solution
    if traps: d["traps"]=[list(t) for t in traps]
    s=json.dumps(d,indent=None)
    # one shape per line for readability
    out='{\n'
    keys=list(d.keys())
    for i,k in enumerate(keys):
        v=d[k]; comma=',' if i<len(keys)-1 else ''
        if k in("shapes","spouts","cups","solution","traps") and isinstance(v,list):
            out+=f'  "{k}": [\n'+',\n'.join('    '+json.dumps(e) for e in v)+f'\n  ]{comma}\n'
        else:
            out+=f'  "{k}": {json.dumps(v)}{comma}\n'
    out+='}\n'
    open(f"{D}/{lid}.json","w").write(out)
