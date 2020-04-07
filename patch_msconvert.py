from bioblend import galaxy
import argparse
import os,sys
import json #Galaxy workflows are JSON files.
import subprocess

#ARGUMENT PARSING#

parser = argparse.ArgumentParser(description='Take in login information for galaxy...')
parser.add_argument('--apikey',dest="apikey",help="Galaxy user password",default="admin")
parser.add_argument('--galaxy_address',dest="galaxy_address",help="Galaxy IP Address",default="127.0.0.1")
parser.add_argument('--tool_string',dest="tool_string",help="Tool to operate on")
args = parser.parse_args()


if args.tool_string is None:
    print "You need to provide an old tool string to be replaced!!"
    sys.exit(2)

gi = galaxy.GalaxyInstance(url='http://'+args.galaxy_address,key=args.apikey)

all_tools=gi.tools.get_tools()

target_id=None
for each_tool in all_tools:
    if args.tool_string in each_tool['id']:
        print "this is probably it...",each_tool
        target_id=each_tool['id']
        target_version=each_tool['version']
        target_tool_directory=each_tool['config_file'].rsplit("/",1)[0]+"/"
        print target_tool_directory
        break
os.chdir(target_tool_directory)

with open("msconvert_wrapper.py",'rb') as openfile:
    content=openfile.read()
os.remove("msconvert_wrapper.py")

new_file=[]
for each_line in content.split("\n"):
    if "cmd = \"msconvert --%s %s\" % (to_extension, to_params)" in each_line":
        new_file.append(each_line.replace("msconvert","wine msconvert"))
        continue
    new_file.append(each_line)
    if "    if args:"==each_line:
        new_file.append("        temp=[]")
        new_file.append("        for arg in args:")
        new_file.append("            if \";\"==arg[-1]:")
        new_file.append("                arg=arg[:-1]")
        new_file.append("                temp.append(arg)")
        new_file.append("                break")
        new_file.append("            temp.append(arg)")
        new_file.append("        args=temp")
with open("msconvert_wrapper.py",'wb') as openfile:
    for each_line in new_file:
        openfile.write(each_line+"\n")

