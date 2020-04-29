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
def w1bachelor(usergroupname):

    day = []
    para = []
    paranum = []
    group = []

    wb = xlrd.open_workbook("bachelor.xls")
    ws = wb.sheet_by_index(5)
    total_rows = ws.nrows
    total_cols = ws.ncols
    tabel = list()
    record = list()
    group_table = []
    #створення розкладу першого тижня
    for y in range(total_cols):
        group_table.append(ws.cell(8, y).value)
        if usergroupname in group_table[y]:
            day.append (ws.cell(1, y).value)
            group.append (ws.cell(8, y).value)
            para.append (ws.cell(3, y).value)
            paranum.append (ws.cell(2, y).value)

            for x in range(total_rows):
                zam.append(str(ws.cell(x, y+2).value))
                y += 1
                if y >= 5:
                    break
        else:
            x+= 1

    if group == []:
        return jsonify({"404":"Розклад не знайдено"})
    else:
        return jsonify({"para":para,"group":group,"paranum":paranum,"day":day})

app = Flask(__name__)
@app.route("/", methods=['GET'])
def hello():
    return "MyKTGG App Json Server"

@app.route('/favicon.ico')
def favicon():
    return redirect(url_for('static', filename='favicon.ico'), code=302)

@app.route("change/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml1/w1/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml1/w2/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml2/w1/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml2/w2/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml3/w1/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml3/w2/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml4/w1/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("ml4/w2/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)

@app.route("bachelor/w1/<some_group>")
def group(some_group):
    w1bachelor=w1bachelor(some_group)
    return (w1bachelor)

@app.route("bachelor/w2/<some_group>")
def group(some_group):
#    zam=check.zamch(some_group)
    zam=zamchecker(some_group)
    return (zam)


if __name__ == "__main__":
    app.run(host="217.76.201.219")
    print(hello())
