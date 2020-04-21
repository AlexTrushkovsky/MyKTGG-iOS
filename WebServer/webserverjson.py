from flask import Flask, request, jsonify, url_for, redirect
from string import Template
import xlrd
#import check
import os

def zamchecker(usergroupname):
    zam = []

    date = ""
    para = []
    group = []
    disyakuzam = []
    vykladachyakzam = []
    dis = []
    vikladach = []

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
            para.append (ws.cell(x, 0).value)
            group.append (ws.cell(x, 2).value)
            disyakuzam.append (ws.cell(x, 3).value)
            vykladachyakzam.append (ws.cell(x, 4).value)
            dis.append (ws.cell(x, 5).value)
            vikladach.append (ws.cell(x, 6).value)
            for y in range(total_cols):
                zam.append(str(ws.cell(x, y+2).value))
                y += 1
                if y >= 5:
                    break
        else:
            x+= 1

    if zam == []:
        return jsonify({"date":date,"noChange":"Замін немає"})
    else:
        return jsonify({"date":date,"para":para,"group":group,"dis":disyakuzam,"disChange":dis,"teacher":vykladachyakzam,"teacherChange":vikladach})


app = Flask(__name__)
@app.route("/", methods=['GET'])
def hello():
    return "MyKTGG App Json Server"

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
