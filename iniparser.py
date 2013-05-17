import ConfigParser
import os
import sys
import optparse
import shutil
import subprocess
import re

SECTION = 'info'
APP_NAME = 'app_name'
PACKAGE_NAME = 'package'
APP_ID = 'app_id'
APP_SECRECT = 'app_secrect'
VERSION_CODE = 'version_code'
VERSION_NAME = 'version_name'
CONFIG_FILE = "app_id_file"

MENIFEST = 'AndroidManifest.xml'
SRC_DIR = 'src'
RES_DIR = 'res'

CLEAN_CMD = ['ant', 'clean']
BUILD_CMD = ['ant', 'release']

GIT_ADD_ALL = ['git', 'add', '.']
GIT_RESET = ['git', 'reset', '--hard', 'HEAD']

PROPERTYS = [APP_NAME, PACKAGE_NAME, APP_ID, APP_SECRECT, VERSION_CODE, VERSION_NAME, CONFIG_FILE]

init_optparse = optparse.OptionParser(usage='python iniparser.py -f your_file_full_path')

init_optparse.add_option('-f', '--file', dest='file')

class FILE_NOT_EXISTS(Exception):
    """ file Not Exists
    """

class PROPERTY_NOT_EXISTS(Exception):
    """ property not find
    """

class CMD_EXEC_FAILURE(Exception):
    """ exec cmd failure
    """

class REPLACE_TEXT_FAILURE(Exception):
    """ replace text failure
    """

def _dump_file(filename):
    print '='*10, 'begin dump ', filename, '='*10
    f = open(filename)
    for line in f:
        print line
    print '='*50

def readOneProperty(config, sectionName, propertyName):
    if config != None:
        ret = config.get(sectionName, propertyName)
        print '[[readOneProperty]] {0} = {1}'.format(propertyName, ret)
        if ret == None:
            raise PROPERTY_NOT_EXISTS()
        return ret

def _ini_parse(fileFullPath):
    if os.path.exists(fileFullPath):
        config = ConfigParser.ConfigParser()
        config.readfp(open(fileFullPath))

        ret = {}
        for p in PROPERTYS:
            ret[p] = readOneProperty(config, SECTION, p)
        print 'property dict : ', ret

        if len(ret) == len(PROPERTYS):
            return ret

    return FILE_NOT_EXIST()

def _execCmd(cmd, exec_dir):
    print ' try to exc cmd : ', cmd, " under Foler : ", exec_dir
    try :
        proc = subprocess.Popen(cmd, cwd=exec_dir)
        if proc.wait() != 0:
            raise CMD_EXEC_FAILURE()

    except OSError, e:
        print >>sys.stderr, 'fatal : {0} exec error'.format(cmd), e

def _replce_text_in_file(filename, oldText, newText):
    if os.path.exists(filename):
        #print '_replce_text_in_file : {0} oldText : {1} newText : {2}'.format(filename, oldText, newText)
        tmp = filename + '_tmp'
        file = open(filename)
        tmpFile = open(tmp, 'w+')
        for line in file:
            m = re.search(oldText, line)
            if m :
                rText = re.sub(oldText, newText, line)
                #print 'find match ', m.group(0), ' for oldText : ', oldText
                tmpFile.write(rText)
            else:
                tmpFile.write(line)

        tmpFile.flush()
        tmpFile.close()

        #print 'replace text success :  try to dump the {0}'.format(tmp)
        #_dump_file(tmp)

        shutil.move(tmp, filename)

    return REPLACE_TEXT_FAILURE()

def _Main(args):
    opt, arg = init_optparse.parse_args(args)

    pos = opt.file.rindex('/')
    work_dir = opt.file[0:pos] + '/'

    if os.path.exists(work_dir + 'book.epub') == False or os.path.exists(work_dir + 'icon.png') == False:
        raise RuntimeError()

    iniDict = _ini_parse(opt.file)
    if iniDict != None:
        _replce_text_in_file(iniDict[CONFIG_FILE], 'APP_ID.*', 'APP_ID = \"{0}\";'.format(iniDict[APP_ID]))
        _replce_text_in_file(iniDict[CONFIG_FILE], 'APP_SECRET_KEY.*', 'APP_SECRET_KEY = \"{0}\";'.format(iniDict[APP_SECRECT]))
        _replce_text_in_file('res/values/strings.xml', 'app_name.*>', 'app_name">{0}</string>'.format(iniDict[APP_NAME]))
        _replce_text_in_file(MENIFEST, 'android:versionCode=\".*\"', 'android:versionCode=\"{0}\"'.format(iniDict[VERSION_CODE]))
        _replce_text_in_file(MENIFEST, 'android:versionName=\"[0-9].[0-9]\"', 'android:versionName=\"{0}\"'.format(iniDict[VERSION_NAME]))
        
        package_replace_from = ''
        f = open(MENIFEST)
        for line in f:
            m = re.search('com.michael.manhua.[a-z0-9A-Z]*', line)
            if m:
                package_replace_from = m.group(0)
                print 'package replace is {0}'.format(package_replace_from)
        _replce_text_in_file(MENIFEST, 'package=\".*\"', 'package=\"{0}\"'.format(iniDict[PACKAGE_NAME]))

        package_replace_to = iniDict[PACKAGE_NAME]

        print 'replace from {0} to {1}'.format(package_replace_from, package_replace_to)

        if package_replace_from == None or package_replace_to == None:
            raise RuntimeError()

        #replace file down dir
        for root, dirs, files in os.walk(SRC_DIR):
            #print '>'*10, 'begin operate the file dir {0}'.format(root), '>'*10
            for file in files:
                #print 'check file ', file
                _replce_text_in_file('{0}/{1}'.format(root, file), package_replace_from, package_replace_to)
        #print '<'*10, 'end repalce under {0}'.format(SRC_DIR), '<'*10


        #replace file down dir
        for root, dirs, files in os.walk(RES_DIR):
            #print '>'*10, 'begin operate the file dir {0}'.format(root), '>'*10
            for file in files:
                _replce_text_in_file('{0}/{1}'.format(root, file), package_replace_from, package_replace_to)
        #print '<'*10, 'end repalce under {0}'.format(RES_DIR), '<'*10

        #move src dir
        oldPackageName = package_replace_from.split('.')[-1]
        newPackageName = package_replace_to.split('.')[-1]
        if os.path.exists('{0}/{1}'.format('src/org/geometerplus/zlibrary/ui', newPackageName)):
            shutil.rmtree('{0}/{1}'.format('src/org/geometerplus/zlibrary/ui', newPackageName))
        shutil.move('{0}/{1}'.format('src/org/geometerplus/zlibrary/ui', oldPackageName), '{0}/{1}'.format('src/org/geometerplus/zlibrary/ui', newPackageName))
        if os.path.exists('{0}/{1}'.format('src/org/geometerplus/zlibrary/ui', newPackageName)):
            copy = 'cp -rf {0}book.epub assets/book/book.epub ; cp -rf {1}icon.jpg res/drawable/icon.jpg'.format(work_dir, work_dir)
            print 'copy book : ', copy
            os.system(copy)

            _execCmd(CLEAN_CMD, './')
            _execCmd(BUILD_CMD, './')
            if pos != -1:
                target = work_dir + 'Book_{0}.apk'.format(iniDict[VERSION_NAME])
                print 'remove old apk {0}*.apk'.format(work_dir)
                print 'new apk : ', target
                cmd = 'rm -rf ' + work_dir + '*.apk' + ' ; cp -rf bin/Book-release.apk ' + target
                print 'exec cm : ', cmd
                os.system(cmd)
        else:
            raise RuntimeError()
    
#clean
    _execCmd(GIT_ADD_ALL, './')
    _execCmd(GIT_RESET, './')

if __name__ == '__main__':
    _Main(sys.argv[1:])
