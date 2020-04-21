from flask import Flask, request, jsonify, url_for, redirect
from string import Template
import xlrd
#import check
import os

def zamchecker(usergroupname):
    zam = []
    
    date = ""
    
    para = ""
    group = ""
    disyakuzam = ""
    vykladachyakzam = ""
    dis = ""
    vikladach = ""
    
    wb = xlrd.open_workbook("zaminy.xls")
    ws = wb.sheet_by_index(0)
    total_rows = ws.nrows
    total_cols = ws.ncols
    tabel = list()
    record = list()
    group_zam = []
    #створення списку замін
    date = (ws.cell(0, 0).value)
    for x in range(total_rows):
        group_zam.append(ws.cell(x, 2).value)
        y = 2
        if usergroupname in group_zam[x]:
            para = (ws.cell(x, 0).value)
            group = (ws.cell(x, 2).value)
            disyakuzam = (ws.cell(x, 3).value)
            vykladachyakzam = (ws.cell(x, 4).value)
            dis = (ws.cell(x, 5).value)
            vikladach = (ws.cell(x, 6).value)
            for y in range(total_cols):
                zam.append(str(ws.cell(x, y+2).value)+"<br>")
                y += 1
                if y >=5:
                    break
        else:
            x+= 1
    if zam == []:
        print('Замін не знайдено')
    else:
        print(zam)#надсилання переліку замін
        return jsonify({"date":zam,"para":para,"group":group,"disyakuzam":disyakuzam,"vykladachyakzam":vykladachyakzam,"dis":dis,"vikladach":vikladach})


app = Flask(__name__)
@app.route("/", methods=['GET'])
def hello():
    usergroupname = request.json['group']
    zam=zamchecker(usergroupname)
    return zam
    
@app.route('/favicon.ico')
def favicon():
    return redirect(url_for('static', filename='favicon.ico'), code=302)

@app.route("/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

if __name__ == "__main__":
    app.run(host="217.76.201.219")
    print(hello())
