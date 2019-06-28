FROM bgruening/galaxy-stable:latest

MAINTAINER William Barshop, wbarshop@ucla.edu

#and installing python packages...

#INSTALL SOME PYTHON PACKAGES INTO VENV
RUN . "$GALAXY_VIRTUAL_ENV/bin/activate" && pip install cython && pip install https://pypi.python.org/packages/de/db/7df2929ee9fad94aa9e57071bbca246a42069c0307305e00ce3f2c5e0c1d/pyopenms-2.1.0-cp27-none-manylinux1_x86_64.whl#md5=3c886f9bb4a2569c0d3c8fe29fbff5e1 && pip install numpy==1.13.0 uniprot_tools h5py==2.7.0 ephemeris futures tqdm joblib multiprocessing pandas argparse pyteomics==3.2 natsort tqdm biopython lxml plotly Orange-Bioinformatics -U && \
    pip install pymzml==0.7.8 
RUN ls /galaxy_venv/lib/python2.7/site-packages/ && curl -L http://ontologies.berkeleybop.org/ms.obo > /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo && cp /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-23:06:2017.0.0.obo && cp /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.1.1.obo


#Now let's move all the tool data from our local machine into the docker image.
#After that's done, we'll have to take care of a few galaxy configuration XML files...
#The first is going to be the job_conf xml
#and COPY DOCKER_JOB_CONF.XML $GALAXY_CONFIG_DIR/job_conf.xml


## INSTALL WORKFLOWS AND TOOLBOX TOOLS INTO GALAXY ##

    
# PATCHES AND FIXES BASED ON HARD REVISIONED PACKAGES
#
#
#Patch listed in https://github.com/galaxyproject/pulsar/issues/125 for directory issues...
RUN sed -i "s#        pattern = r\"(#        directory = directory.replace('\\\\\\\\','\\\\\\\\\\\\\\\\')\n        pattern = r\"(#g" /galaxy_venv/lib/python2.7/site-packages/pulsar/client/staging/up.py

#Modify galaxy.ini to always cleanup...
RUN sed -i 's/#cleanup_job = always/cleanup_job = always/' /etc/galaxy/galaxy.yml

#Let's install a few galaxy tools....
ADD proteomics_toolshed.yml $GALAXY_ROOT/proteomics_toolshed.yml
RUN cp /galaxy-central/config/dependency_resolvers_conf.xml.sample /galaxy-central/config/dependency_resolvers_conf.xml && \
    startup_lite && \
    sleep 25 && \
    install-tools $GALAXY_ROOT/proteomics_toolshed.yml

#Installing Milkyway tools/configurations...
#The wohl tool conf will be appended with some extras at the end of the docker image build.
RUN echo "The milkyway toolset was cloned auotmatically after a triggered pull from commit_rev-CI_job_ID on DATE-REPLACE"  && git clone https://github.com/wohllab/milkyway_proteomics.git --branch master && \
    mv milkyway_proteomics/galaxy_milkyway_files/tool-data/msgfplus_mods.loc $GALAXY_ROOT/tool-data/msgfplus_mods.loc;mv milkyway_proteomics/galaxy_milkyway_files/tool-data/silac_mods.loc $GALAXY_ROOT/tool-data/silac_mods.loc && \
    apt-get update && \
    apt-get install rsync -y && \                                                                                                                                                                                                                rsync -avzh milkyway_proteomics/galaxy_milkyway_files/tools/wohl-proteomics/ $GALAXY_ROOT/tools/wohl-proteomics/ && \
    mv milkyway_proteomics/galaxy_milkyway_files/config/wohl_tool_conf.xml /home/galaxy/wohl_tool_conf.xml            


COPY replace_workflow_id.py /galaxy-central/replace_workflow_id.py
COPY patch_msconvert.py /galaxy-central/patch_msconvert.py
RUN startup_lite && \
    sleep 60 && \
    pip install ephemeris && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string msconvert_win --job_conf $GALAXY_CONFIG_DIR/job_conf.xml && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string DecoyDatabase && \
    python /galaxy-central/patch_msconvert.py --apikey admin --galaxy_address 127.0.0.1:8080 --tool_string msconvert_win && \
    workflow-install --workflow_path /galaxy-central/milkyway_proteomics/workflows/ -g http://localhost:8080 -u admin@galaxy.org -p admin

#The second is the tool_conf xml
RUN cp milkyway_proteomics/galaxy_milkyway_files/config/job_conf.xml $GALAXY_CONFIG_DIR/job_conf.xml && \
    head -n -1 $GALAXY_ROOT/config/tool_conf.xml.sample > /home/galaxy/milkyway_tool_conf.xml; head -n -1 /home/galaxy/wohl_tool_conf.xml > /home/galaxy/wohl_tool_tmp.xml; sed -e "1d" /home/galaxy/wohl_tool_tmp.xml > /home/galaxy/wohl_tool_tmp_final.xml; cat /home/galaxy/wohl_tool_tmp_final.xml >> /home/galaxy/milkyway_tool_conf.xml; echo "</toolbox>" >> /home/galaxy/milkyway_tool_conf.xml; rm /home/galaxy/wohl_tool_tmp.xml; rm /home/galaxy/wohl_tool_tmp_final.xml

ADD welcome.html /etc/galaxy/web/welcome.html
#Set up environment variables for galaxy docker...
ENV GALAXY_CONFIG_BRAND='MilkyWay' \
GALAXY_VIRTUAL_ENV=/galaxy_venv \
GALAXY_CONFIG_TOOL_CONFIG_FILE=/home/galaxy/milkyway_tool_conf.xml,$GALAXY_ROOT/config/shed_tool_conf.xml
#l_no_container
#GALAXY_DESTINATIONS_DEFAULT=local_no_container \
#NONUSE=slurmd,slurmctld
#GALAXY_HANDLER_NUMPROCS=4 \
#UWSGI_PROCESSES=4 \
#UWSGI_THREADS=2 \
#GALAXY_ROOT=/galaxy-central \
#GALAXY_CONFIG_DIR=/etc/galaxy \

VOLUME ["/export/","/data/","/var/lib/docker"]

EXPOSE :80
EXPOSE :21
EXPOSE :8800


CMD ["/usr/bin/startup"]


