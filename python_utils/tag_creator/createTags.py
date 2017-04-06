import os, sys, ConfigParser, subprocess



# Global Varibles

parser = ConfigParser.ConfigParser()
parser.readfp(open("tags.ini"))
tagname = parser.get("tag1", "tagname")
bam = parser.get("tag1", "bam")
bami = parser.get("tag1", "bami")

def construct_tag():
    myString = "vp-add-dataset --tag-name={} {} {}".format(tagname, bam, bami)
    return myString

if __name__ == '__main__':
    tagCmd = construct_tag()
    # server = raw_input("Enter Server: ")
    # target = "root@pgdx-pr{}".format(server)
    # cmd = ["ssh", target, tagCmd]
    # proc = subprocess.Popen(cmd).communicate()
    print tagCmd