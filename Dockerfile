FROM bgruening/galaxy-stable:latest

MAINTAINER William Barshop, wbarshop@ucla.edu

#Updating packages and installing R...
RUN apt-get update --yes --force-yes && apt-get --yes --force-yes install libpango-1.0-0 libbz2-dev;apt-get -f install -y;apt-get --yes --force-yes remove r-base-core r-base
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb http://download.mono-project.com/repo/debian wheezy main" | sudo tee /etc/apt/sources.list.d/mono-xamarin.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9;sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list';apt-get update --yes --force-yes; \
    apt-get install software-properties-common; add-apt-repository ppa:george-edison55/cmake-3.x ; apt-get update --yes

RUN apt-get update --yes && \
    apt-get install -y \
    pigz \
    git \
    ed \
    netcdf-bin \
    nco \
    libnetcdf-dev \
    libnetcdfc7 \
    udunits-bin \
    libudunits2-dev \
    libcairo2-dev \
    libxml2-dev \
    mono-complete \
    unzip \
    nano \
    screen \
    build-essential \
    autoconf \
    patch \
    libtool \
    automake \
    cmake3 \
    python-software-properties \
    software-properties-common

#Installing wine....
RUN mv /etc/apt/sources.list.d/htcondor.list temporary_file && \
dpkg --add-architecture i386 && \
wget https://dl.winehq.org/wine-builds/Release.key && \
sudo apt-key add Release.key && \
sudo apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/ && \
apt-get update && \
sudo apt-get install --install-recommends winehq-stable -y


#Let's handle rvm and protk installation
RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | grep -v __rvm_print_headline | sudo bash -s stable --ruby=2.5.1 && \
    /bin/bash -c "source /usr/local/rvm/scripts/rvm && gem install protk -v 1.4.2" && \
    sudo usermod -a -G rvm galaxy


#scripts to handle galaxy supervisor paths and env values
ADD add_to_galaxy_path.py /galaxy-central/add_to_galaxy_path.py
ADD add_to_galaxy_env.py /galaxy-central/add_to_galaxy_env.py
RUN python /galaxy-central/add_to_galaxy_path.py /etc/supervisor/conf.d/galaxy.conf /usr/local/rvm/rubies/ruby-2.5.1/bin/ /OpenMS-build/bin/ /home/galaxy/crux/bin/


#installation of OpenMS 2.2.0.
RUN apt-get install build-essential autoconf patch libtool automake qt4-default libqtwebkit-dev libeigen3-dev libxerces-c-dev libboost-all-dev libsvn-dev libbz2-dev cmake3 -y
RUN curl -L https://github.com/OpenMS/OpenMS/releases/download/Release2.2.0/OpenMS-2.2.0-src.zip > OpenMS-2.2.0-src.zip && unzip OpenMS-2.2.0-src.zip && rm OpenMS-2.2.0-src.zip && mv archive/* . && rm -rf archive/ && cd OpenMS-2.2.0/ && mkdir contrib-build && cd contrib-build && \
    cmake -DBUILD_TYPE=ALL -DNUMBER_OF_JOBS=8 ../contrib && \
    cd / && mkdir OpenMS-build && cd OpenMS-build && cmake -DCMAKE_PREFIX_PATH="/galaxy-central/OpenMS-2.2.0/contrib-build;/usr;/usr/local" -DBOOST_USE_STATIC=OFF -DOPENMS_CONTRIB_LIBS=/galaxy-central/OpenMS-2.2.0/contrib-build /galaxy-central/OpenMS-2.2.0/ && \
    make && echo "export LD_LIBRARY_PATH='/OpenMS-build/lib:$LD_LIBRARY_PATH'" >> $HOME/.bashrc && mv /OpenMS-build/bin/* /galaxy_venv/bin/

    
#Set up environment variables for galaxy docker...
ENV GALAXY_CONFIG_BRAND='MilkyWay Proteomics' \
GALAXY_VIRTUAL_ENV=/galaxy_venv \
GALAXY_HANDLER_NUMPROCS=4 \
UWSGI_PROCESSES=4 \
UWSGI_THREADS=2 \
GALAXY_ROOT=/galaxy-central \
GALAXY_CONFIG_DIR=/etc/galaxy \
GALAXY_DESTINATIONS_DEFAULT=local \
GALAXY_CONFIG_FILE=$GALAXY_CONFIG_DIR/galaxy.yml \
GALAXY_CONFIG_TOOL_CONFIG_FILE=/home/galaxy/milkyway_tool_conf.xml,$GALAXY_ROOT/config/shed_tool_conf.xml.sample  \
NONUSE=slurmd,slurmctld

    
#Let's install a few galaxy tools....
ADD proteomics_toolshed.yml $GALAXY_ROOT/proteomics_toolshed.yml
RUN install-tools $GALAXY_ROOT/proteomics_toolshed.yml


#Installing R packages and MSstats
RUN touch /etc/bash_completion.d/R;cp /etc/bash_completion.d/R /usr/share/bash-completion/completions/R;apt-get update; apt-get install -f;apt-get -o Dpkg::Options::=--force-confnew --yes --force-yes install r-base-core r-base && \
    R -e "install.packages(c('gplots','lme4','ggplot2','ggrepel','reshape','reshape2','data.table','rjson','Rcpp','survival','minpack.lm'),repos='https://cran.rstudio.com/',dependencies=TRUE)" && \
    R -e "source('https://bioconductor.org/biocLite.R');biocLite(c('limma','marray','preprocessCore','MSnbase'),ask=FALSE)" && \
    wget "http://msstats.org/wp-content/uploads/2017/09/MSstats_3.9.2.tar.gz";R -e "install.packages('MSstats_3.9.2.tar.gz',type='source', repos=NULL)"; rm MSstats_3.9.2.tar.gz

    
#Installing proteowizard binaries...
COPY pwiz-bin-linux-x86_64-gcc48-release-3_0_10738.tar.bz2 /bin/pwiz.tar.bz2
RUN cd /bin/ && tar xvfj pwiz.tar.bz2 && rm pwiz.tar.bz2


#Installing crux toolkit...
RUN git config --global user.email "docker@localhost" ; git config --global user.name "docker" && \
    git clone https://github.com/crux-toolkit/crux-toolkit.git crux-toolkit;cd crux-toolkit;cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=~/crux/;make;make install && \
    python /galaxy-central/add_to_galaxy_path.py /etc/supervisor/conf.d/galaxy.conf /home/galaxy/crux/bin/ && cp /home/galaxy/crux/bin/crux /galaxy_venv/bin/crux

#SET UP BLIBBUILD
RUN mkdir /galaxy-central/tools/wohl-proteomics/ && \
    mkdir /galaxy-central/tools/wohl-proteomics/ssl_converter/ && \
    svn checkout -r11856 https://svn.code.sf.net/p/proteowizard/code/trunk/pwiz proteowizard-code && \
    cd proteowizard-code/ && \
    sh quickbuild.sh -j8 optimization=space address-model=64 pwiz_tools/BiblioSpec && \
    mkdir /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild && \
    cp build-linux-x86_64/BiblioSpec/* /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild/ && \
    tar xvfj /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild/bibliospec*.tar.bz2 && \
    cd .. && \
    rm -rf proteowizard-code/


#Installing Milkyway tools/configurations...
RUN echo 'The milkyway toolset is cloned auotmatically after a triggered pull from commit_rev-CI_job_ID' && git clone https://github.com/wohllab/milkyway_proteomics.git --branch master && \
    mv milkyway_proteomics/galaxy_milkyway_files/tool-data/msgfplus_mods.loc $GALAXY_ROOT/tool-data/msgfplus_mods.loc;mv milkyway_proteomics/galaxy_milkyway_files/tool-data/silac_mods.loc $GALAXY_ROOT/tool-data/silac_mods.loc && \
    apt-get update && \
    apt-get install rsync -y && \
    rsync -avzh milkyway_proteomics/galaxy_milkyway_files/tools/wohl-proteomics/ $GALAXY_ROOT/tools/wohl-proteomics/ && \
    mv milkyway_proteomics/galaxy_milkyway_files/config/wohl_tool_conf.xml /home/galaxy/wohl_tool_conf.xml

#Now let's move all the tool data from our local machine into the docker image.
#After that's done, we'll have to take care of a few galaxy configuration XML files...
#The first is going to be the job_conf xml
#and COPY DOCKER_JOB_CONF.XML $GALAXY_CONFIG_DIR/job_conf.xml
#The second is the tool_conf xml
RUN rm $GALAXY_CONFIG_DIR/job_conf.xml && \
    mv milkyway_proteomics/galaxy_milkyway_files/config/job_conf.xml $GALAXY_CONFIG_DIR/job_conf.xml && \
    head -n -1 $GALAXY_ROOT/config/tool_conf.xml.sample > /home/galaxy/milkyway_tool_conf.xml; head -n -1 /home/galaxy/wohl_tool_conf.xml > /home/galaxy/wohl_tool_tmp.xml; sed -e "1d" /home/galaxy/wohl_tool_tmp.xml > /home/galaxy/wohl_tool_tmp_final.xml; cat /home/galaxy/wohl_tool_tmp_final.xml >> /home/galaxy/milkyway_tool_conf.xml; echo "</toolbox>" >> /home/galaxy/milkyway_tool_conf.xml; rm /home/galaxy/wohl_tool_tmp.xml; rm /home/galaxy/wohl_tool_tmp_final.xml

## INSTALL WORKFLOWS AND TOOLBOX TOOLS INTO GALAXY ##
#and installing python packages...
COPY replace_workflow_id.py /galaxy-central/replace_workflow_id.py
COPY patch_msconvert.py /galaxy-central/patch_msconvert.py
RUN startup_lite && \
    sleep 25 && \
    pip install ephemeris && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string msconvert_win --job_conf $GALAXY_CONFIG_DIR/job_conf.xml && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string DecoyDatabase && \
    python /galaxy-central/patch_msconvert.py --apikey admin --galaxy_address 127.0.0.1:8080 --tool_string msconvert_win && \
    workflow-install --workflow_path /galaxy-central/milkyway_proteomics/workflows/ -g http://localhost:8080 -u admin@galaxy.org -p admin

   
#INSTALL SOME PYTHON PACKAGES INTO VENV
RUN . "$GALAXY_VIRTUAL_ENV/bin/activate" && pip install cython && pip install https://pypi.python.org/packages/de/db/7df2929ee9fad94aa9e57071bbca246a42069c0307305e00ce3f2c5e0c1d/pyopenms-2.1.0-cp27-none-manylinux1_x86_64.whl#md5=3c886f9bb4a2569c0d3c8fe29fbff5e1 && pip install numpy==1.13.0 uniprot_tools h5py==2.7.0 ephemeris futures tqdm joblib multiprocessing pandas argparse pyteomics==3.2 natsort tqdm biopython lxml plotly Orange-Bioinformatics -U && \
    pip install pymzml==0.7.8 && curl -L http://ontologies.berkeleybop.org/ms.obo > /galaxy_venv/local/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo && cp /galaxy_venv/local/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo /galaxy_venv/local/lib/python2.7/site-packages/pymzml/obo/psi-ms-23:06:2017.0.0.obo

    
#Building Fido...
RUN wget https://noble.gs.washington.edu/proj/fido/fido.tgz && tar xzvf fido.tgz && rm fido.tgz && cd fido/src/cpp/ && mkdir ../../bin && make && \
    mv ../../bin/FidoChooseParameters /galaxy-central/tools/wohl-proteomics/fido/FidoChooseParameters && \
    mv ../../bin/Fido /galaxy-central/tools/wohl-proteomics/fido/Fido && \
    cd ../../../ && rm -rf fido && rm -rf bin


#Let's set up DIA-Umpire
RUN cd /galaxy-central/tools/wohl-proteomics/diaumpire/ ; wget https://github.com/Nesvilab/DIA-Umpire/releases/download/v2.1.2/v2.1.2.zip ; unzip v2.1.2.zip ; rm v2.1.2.zip


#We'll need the ptmRS dll file...
#RUN wget http://ms.imp.ac.at/data/ptmrs/ptmrs-2_x.zip; unzip ptmrs-2_x.zip;mv IMP.ptmRS.dll /galaxy-central/tools/wohl-proteomics/ptmRSmax/;rm IMP.ptmRSNode.dll;rm IMP.ptmRSConf.xml;rm ptmrs-2_x.zip


#Let's get MSPLIT-DIA
RUN cd /galaxy-central/tools/wohl-proteomics/msplit-dia/ ; wget http://proteomics.ucsd.edu/Software/MSPLIT-DIA/MSPLIT-DIAv1.0.zip; unzip MSPLIT-DIAv1.0.zip ; rm MSPLIT-DIAv1.0.zip ; mv MSPLIT-DIAv1.0/* . ; rm -rf MSPLIT-DIAv1.0
ADD MSPLIT-DIAv07192015.jar /galaxy-central/tools/wohl-proteomics/msplit-dia/


#Set up for galaxy XML files...
RUN cp /galaxy-central/config/dependency_resolvers_conf.xml.sample /galaxy-central/config/dependency_resolvers_conf.xml


#SET UP SAINTexpress
RUN wget https://downloads.sourceforge.net/project/saint-apms/SAINTexpress_v3.6.1__2015-05-03.zip;unzip SAINTexpress_v3.6.1__2015-05-03.zip -d /galaxy-central/tools/wohl-proteomics/SAINTexpress/;rm SAINTexpress_v3.6.1__2015-05-03.zip; cp /galaxy-central/tools/wohl-proteomics/SAINTexpress/SAINTexpress_v3.6.1__2015-05-03/Precompiled_binaries/Linux64/* /galaxy-central/tools/wohl-proteomics/SAINTexpress/; rm -rf /galaxy-central/tools/wohl-proteomics/SAINTexpress/SAINTexpress_v3.6.1__2015-05-03/


#SET UP SAINTq
RUN curl -L https://sourceforge.net/projects/saint-apms/files/saintq_v0.0.4.tar.gz/download >saintq.tar.gz && tar xzvf saintq.tar.gz && rm saintq.tar.gz && cd saintq/ && make && mv bin/saintq /bin/ && cd .. && rm -rf saintq/


#SET UP PERCOLATOR CONVERTERS
RUN wget https://github.com/percolator/percolator/releases/download/rel-3-01/ubuntu64_release.tar.gz && tar xzvf ubuntu64_release.tar.gz && rm ubuntu64_release.tar.gz && dpkg -i percolator-converters-v3-01-linux-amd64.deb && dpkg -i elude-v3-01-linux-amd64.deb && apt-get install -f && rm percolator-converters-v3-01-linux-amd64.deb percolator-noxml-v3-01-linux-amd64.deb percolator-v3-01-linux-amd64.deb elude-v3-01-linux-amd64.deb


#We need to grab the phosphoRS dll file and unpack it...
RUN mkdir phosphotemp && cd phosphotemp && curl -L http://ms.imp.ac.at/index.php?file=phosphors/phosphors-1_3.zip > phosphoRS.zip && unzip phosphoRS.zip && cp IMP.PhosphoRS.dll /galaxy-central/tools/wohl-proteomics/RSmax/IMP.PhosphoRS.dll && \
    cd ../ && rm -rf phosphotemp


# PATCHES AND FIXES BASED ON HARD REVISIONED PACKAGES
#
#
#Patch listed in https://github.com/galaxyproject/pulsar/issues/125 for directory issues...
RUN sed -i "s#        pattern = r\"(#        directory = directory.replace('\\\\\\\\','\\\\\\\\\\\\\\\\')\n        pattern = r\"(#g" /galaxy_venv/local/lib/python2.7/site-packages/pulsar/client/staging/up.py

#Modify galaxy.ini to always cleanup...
RUN sed -i 's/#cleanup_job = always/cleanup_job = always/' /etc/galaxy/galaxy.yml

#Gotta give this an absolute path nowadays...
RUN sed -i "s#ruby#/usr/local/rvm/rubies/ruby-2.5.1/bin/ruby#" /usr/local/rvm/gems/ruby-2.5.1/gems/protk-1.4.2/lib/protk/galaxy_stager.rb


VOLUME ["/export/","/data/","/var/lib/docker"]

EXPOSE :80
EXPOSE :21
EXPOSE :8800

CMD ["/usr/bin/startup"]

