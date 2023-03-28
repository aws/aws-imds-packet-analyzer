# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

import ctypes as ct

class Event(object):
    #namespace variables
    arr = [1,2,3,4]
    pid = (ct.c_uint32 * 4)(*arr)
    comm = "curl".encode()
    parent_comm = "zsh".encode()
    gparent_comm = "sshd".encode()
    ggparent_comm = "sshd".encode()
    pkt_size = 96
    pkt = "GET /latest/meta-data/ HTTP/1.1\r\nHost: 169.254.169.254\r\nUser-Agent: curl/7.79.1\r\nAccept: */*\r\nX-aws-ec2-metadata-token: AQAEAN2Tw3oWq21W6D3AkC5KA6zMf43zRt6voF04K-2I-jLxiu1E-A==\r\n\r\n".encode()
    
    def __init__(self) -> None:
       pass

if(__name__ == '__main__'):
    event = Event()
    print('\n =============================Debug Info=============================')
    print('event obj: ', end=" ")
    print(event, end=" -> type: ")
    print(type(event))
    print('event pid obj: ', end=" ")
    print(event.pid, end=" -> type: ")
    print(type(event.pid))
    for i in range(4):
      print('\t pid ' + str(i), end=": ")
      print(event.pid[i], end=" -> type: ")
      print(type(event.pid[i]))
    print('event comm: ', end=" ")
    print(event.comm, end=" -> type: ")
    print(type(event.comm))
    print('event parent_comm: ', end=" ")
    print(event.parent_comm, end=" -> type: ")
    print(type(event.parent_comm))
    print('event gparent_comm: ', end=" ")
    print(event.gparent_comm, end=" -> type: ")
    print(type(event.gparent_comm))
    print('event ggparent_comm: ', end=" ")
    print(event.ggparent_comm, end=" -> type: ")
    print(type(event.ggparent_comm))
    print('event pkt_size: ', end=" ")
    print(event.pkt_size, end=" -> type: ")
    print(type(event.pkt_size))
    print('event pkt: ', end=" ") 
    print(event.pkt, end=" -> type: ")
    print(type(event.pkt))
    print('=============================End Debug Info============================= \n')