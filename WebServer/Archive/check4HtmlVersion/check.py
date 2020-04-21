import xlrd
def zamch(groupname):
    zam = []
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
    for x in range(total_rows):
        group_zam.append(ws.cell(x, 2).value)
        y = 2
        if groupname in group_zam[x]:
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
        return '<h1><b>Замін не знайдено</b></h1>'
    else:
        print(zam)#надсилання переліку замін
        return "<br>".join(zam)
