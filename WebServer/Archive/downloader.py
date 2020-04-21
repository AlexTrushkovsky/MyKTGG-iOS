import wget
import pandas as pd
import os
import time

def foo():
  print (time.ctime())


def zamDownload():
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), '/usr/home/alex/WebServer4App/zaminy.xls')
    os.remove(path)
    url = "https://www.dropbox.com/s/dl/xpkq32gpd0xztjg/заміни%201%20семестр%202019-2020.xls?dl=0"
    wget.download(url, '/usr/home/alex/WebServer4App/zaminy.xls')
    print("\n")

foo()
zamDownload()
