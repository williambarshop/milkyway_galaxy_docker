from bioblend import galaxy
import argparse
import os,sys
import json #Galaxy workflows are JSON files.

#ARGUMENT PARSING#

parser = argparse.ArgumentParser(description='Take in login information for galaxy...')
#parser.add_argument('--user',dest="user",help="Galaxy user login name",default="admin@galaxy.org")
parser.add_argument('--apikey',dest="apikey",help="Galaxy user password",default="admin")
parser.add_argument('--galaxy_address',dest="galaxy_address",help="Galaxy IP Address",default="127.0.0.1")
parser.add_argument('--workflow_folder',dest="workflow_folder",help="folder containing galaxy workflow .ga files",default=".")
parser.add_argument('--old_tool_string',dest="old_tool_string",help="old string to be replaced")
parser.add_argument('--job_conf',dest="job_conf",help="Job Conf XML to do the replacement on so that pulsar gets the MSconvert RAW calls!")
args = parser.parse_args()


if args.old_tool_string is None:
    print "You need to provide an old tool string to be replaced!!"
    sys.exit(2)
# This script will connect to the docker instance and check what the actual ID is for the version of msconvert that got installed when the galaxy instance was set up!

gi = galaxy.GalaxyInstance(url='http://'+args.galaxy_address,key=args.apikey)


all_tools=gi.tools.get_tools()

target_id=None
for each_tool in all_tools:
    if args.old_tool_string in each_tool['id']:
        print "this is probably it...",each_tool
        target_id=each_tool['id']
        target_version=each_tool['version']
        break
    #else:
    #    print "NOPE!",each_tool['id']

#If the target ID isn't none, we're going to take the ID and replace out the old data from the workflows...
if target_id is not None:
    os.chdir(args.workflow_folder)
    for each_file in os.listdir(os.getcwd()):
        if each_file.endswith(".ga"):
            with open(each_file,'r') as open_json_file:
                json_file = json.load(open_json_file)
                #print json_file
            for each_step in json_file["steps"]:
                #print each_step
                this_step=json_file["steps"][each_step]
                #print this_step
                if this_step['tool_id'] is not None and args.old_tool_string in this_step['tool_id']:
                    json_file["steps"][each_step]['tool_id']=target_id
                    json_file["steps"][each_step]['content_id']=target_id
                    json_file["steps"][each_step]['version']=target_version
            os.remove(each_file)
            with open(each_file,'w') as writer:
                json.dump(json_file,writer)
            #print "Replacing "+args.old_tool_string+" through workflow file:",each_file
            #print "command is", 'sed -i \':{0}:{1}:g\' {2}'.format(args.old_tool_string,target_id,each_file)
            #os.system('sed -i \'s:{0}:{1}:g\' {2}'.format(args.old_tool_string,target_id,each_file))
    if args.job_conf is not None:
        print "replacing "+args.old_tool_string+" through job_conf file at ",args.job_conf
        os.system('sed -i \'s:{0}:{1}:g\' {2}'.format(args.old_tool_string,target_id,args.job_conf))
else:
    print "Didn't find it..."

