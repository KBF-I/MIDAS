#!/usr/bin/env python
import numpy as np
from os import environ, path
import sys
import struct
from argparse import ArgumentParser

def BinRead(filin, filout='', verbose=0):  #{{{

    print("reading binary file.")
    f = open(filin, 'rb')

    if filout:
        sys.stdout = open(filout, 'w')

    while True:
        try:
            #Step 1: read size of record name
            recordnamesize = struct.unpack('i', f.read(struct.calcsize('i')))[0]
        except struct.error as e:
            print("probable EOF: {}".format(e))
            break

        print("============================================================================ ")
        if verbose > 2:
            print("\n recordnamesize = {}".format(recordnamesize))
        recordname = struct.unpack('{}s'.format(recordnamesize), f.read(recordnamesize))[0]
        print("field: {}".format(recordname))

        #Step 2: read the data itself.
        #first read length of record
        #reclen = struct.unpack('i', f.read(struct.calcsize('i')))[0]
        reclen = struct.unpack('q', f.read(struct.calcsize('q')))[0]
        if verbose > 1:
            print("reclen = {}".format(reclen))

        #read data code:
        code = struct.unpack('i', f.read(struct.calcsize('i')))[0]
        print("Format = {} (code {})".format(CodeToFormat(code), code))

        if code == FormatToCode('Boolean'):
            bval = struct.unpack('i', f.read(reclen - struct.calcsize('i')))[0]
            print("value = {}".format(bval))

        elif code == FormatToCode('Integer'):
            ival = struct.unpack('i', f.read(reclen - struct.calcsize('i')))[0]
            print("value = {}".format(ival))

        elif code == FormatToCode('Double'):
            dval = struct.unpack('d', f.read(reclen - struct.calcsize('i')))[0]
            print("value = {}".format(dval))

        elif code == FormatToCode('String'):
            strlen = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            if verbose > 1:
                print("strlen = {}".format(strlen))
            sval = struct.unpack('{}s'.format(strlen), f.read(strlen))[0]
            print("value = '{}'".format(sval))

        elif code == FormatToCode('BooleanMat'):
            #read matrix type:
            mattype = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("mattype = {}".format(mattype))

            #now read matrix
            s = [0, 0]
            s[0] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            s[1] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("size = [{}x{}]".format(s[0], s[1]))
            data = np.zeros((s[0], s[1]))
            for i in range(s[0]):
                for j in range(s[1]):
                    data[i][j] = struct.unpack('d', f.read(struct.calcsize('d')))[0]    #get to the "c" convention, hence the transpose
                    if verbose > 2:
                        print("data[{}, {}] = {}".format(i, j, data[i][j]))

        elif code == FormatToCode('IntMat'):
            #read matrix type:
            mattype = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("mattype = {}".format(mattype))

            #now read matrix
            s = [0, 0]
            s[0] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            s[1] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("size = [{}x{}]".format(s[0], s[1]))
            data = np.zeros((s[0], s[1]))
            for i in range(s[0]):
                for j in range(s[1]):
                    data[i][j] = struct.unpack('d', f.read(struct.calcsize('d')))[0]    #get to the "c" convention, hence the transpose
                    if verbose > 2:
                        print("data[{}, {}] = {}".format(i, j, data[i][j]))

        elif code == FormatToCode('DoubleMat'):
            #read matrix type:
            mattype = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("mattype = {}".format(mattype))

            #now read matrix
            s = [0, 0]
            s[0] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            s[1] = struct.unpack('i', f.read(struct.calcsize('i')))[0]
            print("size = [{}x{}]".format(s[0], s[1]))
            data = np.zeros((s[0], s[1]))
            for i in range(s[0]):
                for j in range(s[1]):
                    data[i][j] = struct.unpack('d', f.read(struct.calcsize('d')))[0]    #get to the "c" convention, hence the transpose
                    if verbose > 2:
                        print("data[{}, {}] = {}".format(i, j, data[i][j]))

        elif code == FormatToCode('MatArray'):
            f.seek(reclen - 4, 1)
            print("skipping {} bytes for code {}.".format(code, reclen - 4))
        elif code == FormatToCode('StringArray'):
            f.seek(reclen - 4, 1)
            print("skipping {} bytes for code {}.".format(code, reclen - 4))

        else:
            raise TypeError('BinRead error message: data type: {} not supported yet! ({})'.format(code, recordname))

    f.close()
#}}}

def FormatToCode(format):  # {{{
    """
    This routine takes the format string, and hardcodes it into an integer, which
    is passed along the record, in order to identify the nature of the dataset being
    sent.
    """

    if format == 'Boolean':
        code = 1
    elif format == 'Integer':
        code = 2
    elif format == 'Double':
        code = 3
    elif format == 'String':
        code = 4
    elif format == 'BooleanMat':
        code = 5
    elif format == 'IntMat':
        code = 6
    elif format == 'DoubleMat':
        code = 7
    elif format == 'MatArray':
        code = 8
    elif format == 'StringArray':
        code = 9
    else:
        raise IOError('FormatToCode error message: data type not supported yet!')

    return code
# }}}

def CodeToFormat(code):  # {{{
    """
    This routine takes the format string, and hardcodes it into an integer, which
    is passed along the record, in order to identify the nature of the dataset being
    sent.
    """

    if code == 1:
        format = 'Boolean'
    elif code == 2:
        format = 'Integer'
    elif code == 3:
        format = 'Double'
    elif code == 4:
        format = 'String'
    elif code == 5:
        format = 'BooleanMat'
    elif code == 6:
        format = 'IntMat'
    elif code == 7:
        format = 'DoubleMat'
    elif code == 8:
        format = 'MatArray'
    elif code == 9:
        format = 'StringArray'
    else:
        raise TypeError('FormatToCode error message: code {} not supported yet!'.format(code))

    return format
# }}}

if __name__ == '__main__':  #{{{
    parser = ArgumentParser(description='BinRead - function to read binary input file.')
    parser.add_argument('-f', '--filin', help='name of binary input file', default='')
    parser.add_argument('-o', '--filout', help='optional name of text output file', default='')
    parser.add_argument('-v', '--verbose', help='optional level of output', default=0)
    args = parser.parse_args()

    BinRead(args.filin, args.filout, args.verbose)
#}}}
