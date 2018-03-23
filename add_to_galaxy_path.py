#This is a shameful script which will modify the supervisord PATH settings
#for the galaxy web server, with the intent on adding tools to PATH for
#the local job runner inside our Galaxy containers.

import sys,os

args=sys.argv[1:]

input_config_file=args[0]
things_to_add_to_path=args[1:]

config_file=[]
section=False
with open(input_config_file,'rb') as config_reader:
    for each_line in config_reader:
        if section and each_line[0]=="[":
            section=False
        if "[program:galaxy_web]" in each_line:
            section=True
        if section and "environment" in each_line:
            each_line=each_line.rstrip()
            for each_item in things_to_add_to_path:
                each_line+=":{0}".format(each_item)
            each_line+="\n"
        config_file.append(each_line)

    
os.remove(input_config_file)
with open(input_config_file,'wb') as config_writer:
    for each_line in config_file:
        config_writer.write(each_line)

print "All done adding to $PATH!"
