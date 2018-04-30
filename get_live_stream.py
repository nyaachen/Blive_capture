#coding=utf-8

import urllib
import urllib2
import json

def get_addr(roomid):
    response = urllib2.urlopen("https://api.live.bilibili.com/room/v1/Room/playUrl?cid={cid}&quality=4&platform=web".format(cid=roomid))
    string = response.read()
    response.close()
    js = json.loads(string)
    m = {
        '1': js['data']['durl'][0]['url'],
        '2': js['data']['durl'][1]['url'],
        '3': js['data']['durl'][2]['url'],
        '4': js['data']['durl'][3]['url']
    }
    return m


if __name__ == '__main__':
    roomid, i = input()
    d = get_addr(roomid)
    print d[str(i)]
