import argparse
import jenkins
import os
import sys

from subprocess import PIPE, Popen


def get_iso_name(iso_dir):
    try:
        # get number of files in directory
        p = Popen('sudo ls -1 {0} | wc -l'.format(iso_dir),
                  stderr=PIPE,
                  stdout=PIPE,
                  shell=True)
    except Exception as e:
        print 'Error while trying get ' \
              'number of files in path {0}'.format(iso_dir)
        print e
        sys.exit(1)

    out, err = p.communicate()

    # if error occured while getting number of files,
    # or there is no files, or there is more than one file
    # then exit
    if err != '':
        print 'Error occured: {0}'.format(err)
    elif int(out) > 1:
        print 'Error: There is more than 1 file in path {0}'.format(iso_dir)
        sys.exit(1)
    elif int(out) == 0:
        print 'Error: There is no files in path {0}'.format(iso_dir)
        sys.exit(1)
    elif int(out) == 1:
        try:
            # now get file name for fuel iso
            p = Popen('sudo ls -1 {0}'.format(iso_dir),
                      stderr=PIPE,
                      stdout=PIPE,
                      shell=True)
        except Exception as e:
            print 'Error while trying get ' \
                  'file name from path {0}'.format(iso_dir)
            print e
            sys.exit(1)

        out, err = p.communicate()
        if err != '':
            print 'Error while trying to get ' \
                  'list of files in {0}'.format(iso_dir)
        else:
            return out


def get_iso_download_link_with_passed_ubuntubvt2(jenkins_server,
                                                     ubuntu_bvt2):
    server = jenkins.Jenkins(jenkins_server)

    # Get last successful job ubuntu_bvt2 tests, and then get it's
    # last build info
    ubuntu_bvt2_job_info = server.get_job_info(ubuntu_bvt2)
    last_success_number = ubuntu_bvt2_job_info['lastSuccessfulBuild']['number']
    ubuntu_bvt2_build_info = server.get_build_info(ubuntu_bvt2,
                                                   last_success_number)

    # Define upstream job - test_all and it's last successful build
    test_all_project = (
        ubuntu_bvt2_build_info['actions'][1]['causes'][0]['upstreamProject'])
    test_all_build = (
        ubuntu_bvt2_build_info['actions'][1]['causes'][0]['upstreamBuild'])

    test_all_build_info = server.get_build_info(test_all_project,
                                                test_all_build)

    all_project = (
        test_all_build_info['actions'][1]['causes'][0]['upstreamProject'])
    all_build = (
        test_all_build_info['actions'][1]['causes'][0]['upstreamBuild'])

    all_build_info = server.get_build_info(all_project, all_build)

    # Get download link from job description
    iso_download_link = (
        all_build_info['description'].split('=', 1)[1].split('>', 1)[0])

    return iso_download_link


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--jenkins-server-link', help='Link to jenkins'
                                                      'server')
    parser.add_argument('--ubuntubvt2-job-name', help='Name of job,'
                                                      'that tests '
                                                      'main project')
    args = parser.parse_args()
    return args.jenkins_server_link, args.ubuntubvt2_job_name


def erase_env(env):
    try:
        p = Popen('sudo dos.py erase {0}'.format(env),
                  stderr=PIPE,
                  stdout=PIPE,
                  shell=True)
    except Exception as e:
        print 'Error while erasing environment {0}'.format(env)
        print e
        return 1
    else:
        out, error = p.communicate()
        if error != '':
            print 'Error while erasing env {0}'.format(env)
            return 1
        else:
            print out
            return 0


def erase_all_except_required_env(req_env_name):
    # Get list on environments
    try:
        p = Popen('sudo dos.py list', stderr=PIPE, stdout=PIPE, shell=True)
    except Exception as e:
        print 'Error while executing command "dos.py list"'
        print e
        sys.exit(1)

    out, error = p.communicate()
    if error != '':
        print 'Error while executing dos.py: {0}'.format(error)
        sys.exit(1)

    # Create list of envs without system additional info
    env_list = out.split('\n')
    try:
        env_list.remove('NAME')
        env_list.remove('----------------------------')
        env_list.remove('k    e    y    s')
        env_list.remove('---  ---  ---  ---')
    except Exception as e:
        print e

    for env in env_list:
        if env != req_env_name:
            erase_env(env)
            env_list.remove(env)

    return env_list


def check_if_req_snapshot_is_in_env(env, snapshot):
    try:
        p = Popen('dos.py snapshot-list {0} | grep snapshot'.format(env),
                  stdout=PIPE,
                  stderr=PIPE,
                  shell=True)
    except Exception as e:
        print "Error while executing command dos.py snapshot-list"
        print e
        return 1
    else:
        out, error = p.communicate()
        if error != '':
            print "Error while executing command " \
                  "dos.py snapshot-list: {0}".format(error)
            return 1
        else:
            print out
            if out == '':
                return 1
            else:
                return 0


def wget_iso(dir, link):
    wget_command = 'sudo wget {0} -P {1}'.format(link, dir)
    print 'Executing wget command: {}'.format(wget_command)
    p = Popen(wget_command, stderr=PIPE, stdout=PIPE, shell=True)
    while True:
        line = p.stderr.readline()
        if not line:
            break
        print line

    out, err = p.communicate()
    if out:
        print 'wget command output is: {0}'.format(out)


def main():
    iso_dir = os.environ.get('ISO_DIR', '/var/www/fuelweb-iso')
    snapshot_name = os.environ.get('SNAPSHOT_NAME', 'ha_deploy_VLAN_CINDER')
    # Get link to jenkins build, that contain iso download link
    # and test results
    jenkins_server = os.environ.get('JENKINS_SERVER',
                                    'https://product-ci.infra.mirantis.net')
    ubuntu_bvt2 =os.environ.get('BVT2_JOB_NAME', '9.0.main.ubuntu.bvt_2')

    # Get last iso download link
    iso_download_link = (
        get_iso_download_link_with_passed_ubuntubvt2(jenkins_server,
                                                     ubuntu_bvt2))
    # environment name is combination of some const string,
    # like MOS_CI_ and name of iso file
    iso_name = iso_download_link.split('/')[-1]
    required_env_name = 'MOS_CI_{0}'.format(iso_name)

    # env_list is empty, if there is no required env
    env_list = erase_all_except_required_env(required_env_name)

    if not env_list or env_list == '':
        # if env there is no required env, then download iso and exit
        wget_iso(iso_dir, iso_download_link)
        sys.exit(0)
    else:
        # if env_list is not empty, then we already have such env
        # and we can use it's snapshots, but we must check
        # that there is an iso in iso_path
        if os.path.isfile(os.path.join(iso_dir, iso_name)):
            sys.exit(0)
        else:
            wget_iso(iso_dir, iso_download_link)

if __name__ == '__main__':
    main()