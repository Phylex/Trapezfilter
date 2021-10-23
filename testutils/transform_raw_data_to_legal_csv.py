if __name__ == "__main__":
    import sys
    dfile = open(sys.argv[1], 'r')
    outfile = open(sys.argv[2], 'w+')
    for line in dfile.readlines():
        line = line.replace(',', '.')
        line = line.replace(';',',')
        outfile.write(line)
    dfile.close()
    outfile.close()
