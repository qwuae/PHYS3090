import os
import re
import datetime

pattern_d = re.compile("fit-(.*)-.*")
pattern_f = re.compile("out-April-(.*).txt")
pattern_s = re.compile("summary-(.*)")
pattern_o = re.compile(".* direction (.*)")
pattern_r = re.compile("r with traditional (.*)")

for d in os.listdir(os.getcwd()):
    match_d = pattern_d.match(d)
    if match_d:
        data_name = match_d.group(1)
        print 'opening data ' + data_name

        # get time
        now = datetime.datetime.now().strftime("%d%m%H%M%S")

        # write summary
        s_flag = False
        for f in os.listdir(d):
            if pattern_s.match(f):
                s_flag = True

        # make summary file
        if s_flag:
            print "  summary built already"
        else:
            fw = open(d + '/summary-' + now + '.out', 'w')
            fw.write('opening data: ' + data_name + '\n')
            fw.write('dir\tcorrcoef\n')
        
            # in each folder
            for f in os.listdir(d):
                if pattern_f.match(f):

                    # open file
                    fo = open(d + '/' + f, 'r')
                    fr = fo.read()
                    
                    # find direction
                    match_o = pattern_o.search(fr)
                    if match_o:
                        o = .group(1)
                    else:
                        print "  direction info. not found"
                    
                    # find coefficient
                    match_r = pattern_r.search(fr)
                    if match_r:
                        r = match_r.group(1)
                    else:
                        print "  corr-coef info. not found"
                    
                    # write back
                    fo.close()
                    fw.write(o + '\t' + r + '\n')

            fw.close();
                
