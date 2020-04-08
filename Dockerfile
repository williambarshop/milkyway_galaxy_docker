FROM bgruening/galaxy-stable:latest
#FROM quay.io/bgruening/galaxy-htcondor-base:latest

MAINTAINER William Barshop, wbarshop@ucla.edu

#Updating packages and installing R...
RUN apt-get update --yes --force-yes && \
    apt-get --yes --force-yes install gnupg2 libpango-1.0-0 libbz2-dev && \
    apt-get -f install -y

#gpg --keyserver subkeys.pgp.net --recv-key 381BA480 && \
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \
    echo "deb http://download.mono-project.com/repo/debian wheezy main" | tee /etc/apt/sources.list.d/mono-xamarin.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 76F1A20FF987672F && \
    sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu bionic-cran35/" >> /etc/apt/sources.list'
    #gpg --keyserver subkeys.pgp.net --recv-key 381BA480 && \

RUN apt-get update --yes --force-yes && \
    apt-get install --yes --force-yes \
    pigz \
    git \
    ed \
    netcdf-bin \
    nco \
    libnetcdf-dev \
    libnetcdf13 \
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
    software-properties-common \
    curl \
    openjdk-8-jre-headless


#Installing R packages and MSstats
RUN touch /etc/bash_completion.d/R;cp /etc/bash_completion.d/R /usr/share/bash-completion/completions/R && apt-get update && apt-get install -f && \
    apt-get install r-cran-mass r-cran-class r-cran-nnet r-cran-boot r-base-core r-base r-recommended --yes
#    R -e "source('https://bioconductor.org/biocLite.R');biocLite(c('limma','marray','preprocessCore','MSnbase'),ask=FALSE)" && \
#    R -e "install.packages('MSstats_3.9.2.tar.gz',type='source', repos=NULL)" && \
#    rm MSstats_3.9.2.tar.gz
#RUN wget "http://msstats.org/wp-content/uploads/2017/09/MSstats_3.9.2.tar.gz" && \

RUN R -e "install.packages('BiocManager');BiocManager::install(c('limma','marray','preprocessCore','MSnbase','MSstats'),ask=FALSE)" && \
    R -e "install.packages(c('gplots','lme4','ggplot2','ggrepel','reshape','reshape2','data.table','rjson','Rcpp','survival','minpack.lm'),repos='https://cran.rstudio.com/',dependencies=TRUE)"

    
#Let's get cmake
ENV CMAKE_ROOT=/cmake/cmake-3.13.4-Linux-x86_64/
RUN cd / && mkdir cmake/ && cd cmake && \
    curl -sSL https://github.com/Kitware/CMake/releases/download/v3.13.4/cmake-3.13.4-Linux-x86_64.tar.gz > cmake.tar.gz && \
    tar xzvf cmake.tar.gz && \
    rm cmake.tar.gz && cd cmake-3.13.4-Linux-x86_64 && cp -r share/* /usr/share/ && cp bin/* /usr/bin/

#Installing wine.... and libfaudio
#RUN mv /etc/apt/sources.list.d/htcondor.list temporary_file && \
RUN dpkg --add-architecture i386 && \
    curl -sSL https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/Release.key > Release.key && \
    apt-key add Release.key && \
    rm Release.key && \
    sudo apt-add-repository 'deb https://download.opensuse.org/repositories/Emulators:/Wine:/Debian/xUbuntu_18.04/ ./' && \
    curl -sSL https://dl.winehq.org/wine-builds/Release.key > Release.key && \
    apt-key add Release.key && \
    apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ bionic main' && \
    apt update && \
    apt install --install-recommends winehq-stable -y

#Let's handle rvm and protk installation
RUN gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | grep -v __rvm_print_headline | bash -s stable --ruby=2.5.1 && \
    /bin/bash -c "source /usr/local/rvm/scripts/rvm && gem install protk -v 1.4.2" && \
    usermod -a -G rvm $(whoami)


#scripts to handle galaxy supervisor paths and env values
ADD add_to_galaxy_path.py /galaxy-central/add_to_galaxy_path.py
#ADD add_to_galaxy_env.py /galaxy-central/add_to_galaxy_env.py
RUN python /galaxy-central/add_to_galaxy_path.py /etc/supervisor/conf.d/galaxy.conf /usr/local/rvm/rubies/ruby-2.5.1/bin/ /OpenMS-build/bin/ /home/galaxy/crux/bin/
ENV PATH="/usr/local/rvm/rubies/ruby-2.5.1/bin/:/OpenMS-build/bin/:${PATH}"

#installation of OpenMS 2.4.0.
RUN apt-get install build-essential autoconf patch libtool automake qtbase5-dev libqt5svg5-dev libeigen3-dev libxerces-c-dev libboost-all-dev libsvn-dev libbz2-dev -y --force-yes
#RUN mkdir /galaxy-central/ && mkdir /galaxy-central/tools/
#RUN curl -L https://github.com/OpenMS/OpenMS/releases/download/Release2.2.0/OpenMS-2.2.0-src.zip > OpenMS-2.2.0-src.zip && unzip OpenMS-2.2.0-src.zip && rm OpenMS-2.2.0-src.zip && mv archive/* . && rm -rf archive/ && cd OpenMS-2.2.0/ && mkdir contrib-build && cd contrib-build && \
#RUN curl -L https://github.com/OpenMS/OpenMS/archive/Release2.4.0.zip > OpenMS-2.4.0-src.zip && unzip OpenMS-2.4.0-src.zip && rm OpenMS-2.4.0-src.zip

WORKDIR /galaxy-central/
RUN curl -L https://github.com/OpenMS/OpenMS/releases/download/Release2.4.0/OpenMS-2.4.0-src.tar.gz > OpenMS-2.4.0-src.tar.gz && tar xzvf OpenMS-2.4.0-src.tar.gz && rm OpenMS-2.4.0-src.tar.gz
#&& mv OpenMS-Release2.4.0/* . && rm -rf OpenMS-Release2.4.0/ && 
RUN ls && cd OpenMS-2.4.0/ && mkdir contrib-build && cd contrib-build && \
    cmake -DBUILD_TYPE=ALL -DNUMBER_OF_JOBS=8 ../contrib && \
    cd / && mkdir OpenMS-build && cd OpenMS-build && cmake -DCMAKE_PREFIX_PATH="/galaxy-central/OpenMS-2.4.0/contrib-build;/usr;/usr/local" -DBOOST_USE_STATIC=OFF -DOPENMS_CONTRIB_LIBS=/galaxy-central/OpenMS-2.4.0/contrib-build /galaxy-central/OpenMS-2.4.0/ ; \
    make && echo "export LD_LIBRARY_PATH='/OpenMS-build/lib:$LD_LIBRARY_PATH'" >> $HOME/.bashrc
#    cat /OpenMS-2.4.0/contrib-build/CMakeFiles/CMakeOutput.log && \

#&& mv /OpenMS-build/bin/* /galaxy_venv/bin/


#RUN curl -L https://github.com/OpenMS/OpenMS/releases/download/Release2.2.0/OpenMS-2.2.0-src.zip > OpenMS-2.2.0-src.zip && unzip OpenMS-2.2.0-src.zip && rm OpenMS-2.2.0-src.zip && mv archive/* . && rm -rf archive/ && cd OpenMS-2.2.0/ && mkdir contrib-build && cd contrib-build && \
#    cmake -DBUILD_TYPE=ALL -DNUMBER_OF_JOBS=8 ../contrib && \
#    cd / && mkdir OpenMS-build && cd OpenMS-build && cmake -DCMAKE_PREFIX_PATH="/galaxy-central/OpenMS-2.2.0/contrib-build;/usr;/usr/local" -DBOOST_USE_STATIC=OFF -DOPENMS_CONTRIB_LIBS=/galaxy-central/OpenMS-2.2.0/contrib-build /galaxy-central/OpenMS-2.2.0/ && \
#    make && echo "export LD_LIBRARY_PATH='/OpenMS-build/lib:$LD_LIBRARY_PATH'" >> $HOME/.bashrc && mv /OpenMS-build/bin/* /galaxy_venv/bin/

    
#Installing proteowizard binaries...
RUN apt-get install subversion --yes
COPY pwiz-bin-linux-x86_64-gcc48-release-3_0_10738.tar.bz2 /bin/pwiz.tar.bz2
RUN cd /bin/ && tar xvfj pwiz.tar.bz2 && rm pwiz.tar.bz2


#Installing crux toolkit...
RUN mkdir /crux/ && \
    cd /crux/ && \
    curl -s https://noble.gs.washington.edu/crux-downloads/daily/latest-build.txt >build.txt && BUILD=$(cat build.txt) && \
    curl https://noble.gs.washington.edu/crux-downloads/daily/crux-3.2.${BUILD}.Linux.x86_64.zip > crux-3.2.zip && \
    unzip crux-3.2.zip && rm crux-3.2.zip && mkdir bin/ && \
    mv crux-3.2.Linux.x86_64/bin/* bin/ && rm -rf crux-3.2.Linux.x86_64/ && \
    cp /crux/bin/crux /bin/crux && \
    python /galaxy-central/add_to_galaxy_path.py /etc/supervisor/conf.d/galaxy.conf /home/galaxy/crux/bin/
    #git config --global user.email "docker@localhost" && \
    #git config --global user.name "docker" && \
    #git clone https://github.com/crux-toolkit/crux-toolkit.git crux-toolkit && \
    #cd crux-toolkit && \
    #cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=/crux/ && \
    #make && \
    #make install && \

ENV PATH="/crux/bin/:${PATH}" \
    LC_CTYPE=en_US.UTF-8

#SET UP BLIBBUILD
#    svn checkout -r11856 https://svn.code.sf.net/p/proteowizard/code/trunk/pwiz proteowizard-code && \
RUN mkdir /galaxy-central/tools/wohl-proteomics/ && \
    mkdir /galaxy-central/tools/wohl-proteomics/ssl_converter/ && \
    svn checkout https://svn.code.sf.net/p/proteowizard/code/trunk/pwiz proteowizard-code && \
    cd proteowizard-code/ && \
    sh quickbuild.sh -j8 optimization=space address-model=64 pwiz_tools/BiblioSpec && \
    mkdir /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild && \
    cp build-linux-x86_64/BiblioSpec/* /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild/ && \
    tar xvfj /galaxy-central/tools/wohl-proteomics/ssl_converter/blibbuild/bibliospec*.tar.bz2 && \
    cd .. && \
    rm -rf proteowizard-code/


#Installing Milkyway tools/configurations...
#The wohl tool conf will be appended with some extras at the end of the docker image build.
#    mv milkyway_proteomics/galaxy_milkyway_files/tool-data/msgfplus_mods.loc $GALAXY_ROOT/tool-data/msgfplus_mods.loc;mv milkyway_proteomics/galaxy_milkyway_files/tool-data/silac_mods.loc $GALAXY_ROOT/tool-data/silac_mods.loc && \

#NOWIN BRANCH IS ENABLED!!!
RUN echo "The milkyway toolset was cloned auotmatically after a triggered pull from commit_rev-CI_job_ID on DATE-REPLACE"  && git clone https://github.com/wohllab/milkyway_proteomics.git --branch nowin && \
    apt-get update && \
    apt-get install rsync -y && \
    rsync -avzh milkyway_proteomics/galaxy_milkyway_files/tools/wohl-proteomics/ /galaxy-central/tools/wohl-proteomics/ && \
    mv milkyway_proteomics/galaxy_milkyway_files/config/wohl_tool_conf.xml /home/galaxy/wohl_tool_conf.xml


#Now let's move all the tool data from our local machine into the docker image.
#After that's done, we'll have to take care of a few galaxy configuration XML files...
#The first is going to be the job_conf xml
#and COPY DOCKER_JOB_CONF.XML $GALAXY_CONFIG_DIR/job_conf.xml


## INSTALL WORKFLOWS AND TOOLBOX TOOLS INTO GALAXY ##
#and installing python packages...

#INSTALL SOME PYTHON PACKAGES INTO VENV
RUN apt-get install gcc g++ python-pip --yes && \
    pip install cython && \
    pip install https://pypi.python.org/packages/de/db/7df2929ee9fad94aa9e57071bbca246a42069c0307305e00ce3f2c5e0c1d/pyopenms-2.1.0-cp27-none-manylinux1_x86_64.whl#md5=3c886f9bb4a2569c0d3c8fe29fbff5e1 && \
    pip install numpy==1.13.0 uniprot_tools h5py==2.7.0 ephemeris futures tqdm joblib multiprocessing pandas argparse pyteomics==3.2 natsort tqdm biopython lxml plotly -U && \
    pip install pymzml==0.7.8 

RUN curl -L http://ontologies.berkeleybop.org/ms.obo > /usr/local/lib/python2.7/dist-packages/pymzml/obo/psi-ms-4.0.14.obo && \
    cp /usr/local/lib/python2.7/dist-packages/pymzml/obo/psi-ms-4.0.14.obo /usr/local/lib/python2.7/dist-packages/pymzml/obo/psi-ms-23:06:2017.0.0.obo && \
    cp /usr/local/lib/python2.7/dist-packages/pymzml/obo/psi-ms-4.0.14.obo /usr/local/lib/python2.7/dist-packages/pymzml/obo/psi-ms-4.1.1.obo
#curl -L http://ontologies.berkeleybop.org/ms.obo > /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo && cp /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-23:06:2017.0.0.obo && cp /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.14.obo /galaxy_venv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.1.1.obo

    
#Building Fido...
#RUN wget https://noble.gs.washington.edu/proj/fido/fido.tgz && tar xzvf fido.tgz && rm fido.tgz && cd fido/src/cpp/ && mkdir ../../bin && make && \
#    mv ../../bin/FidoChooseParameters /galaxy-central/tools/wohl-proteomics/fido/FidoChooseParameters && \
#    mv ../../bin/Fido /galaxy-central/tools/wohl-proteomics/fido/Fido && \
#    cd ../../../ && rm -rf fido && rm -rf bin


#Let's set up DIA-Umpire
#RUN cd /galaxy-central/tools/wohl-proteomics/diaumpire/ ; wget https://cytranet.dl.sourceforge.net/project/diaumpire/JAR%20executables/DIA-Umpire_v2_0.zip ; unzip DIA-Umpire_v2_0.zip ; rm DIA-Umpire_v2_0.zip ; ls ; sleep 600
RUN cd /galaxy-central/tools/wohl-proteomics/diaumpire/ ; curl -sSL https://github.com/guoci/DIA-Umpire/releases/download/v2.1.3/v2.1.3.zip > v2.1.3.zip ; unzip v2.1.3.zip ; rm v2.1.3.zip
#RUN cd /galaxy-central/tools/wohl-proteomics/diaumpire/ ; wget https://github.com/Nesvilab/DIA-Umpire/releases/download/v2.1.2/v2.1.2.zip ; unzip v2.1.2.zip ; rm v2.1.2.zip


#We'll need the ptmRS dll file...
#RUN wget http://ms.imp.ac.at/data/ptmrs/ptmrs-2_x.zip; unzip ptmrs-2_x.zip;mv IMP.ptmRS.dll /galaxy-central/tools/wohl-proteomics/ptmRSmax/;rm IMP.ptmRSNode.dll;rm IMP.ptmRSConf.xml;rm ptmrs-2_x.zip


#Let's get MSPLIT-DIA
RUN cd /galaxy-central/tools/wohl-proteomics/msplit-dia/ ; curl -sSL http://proteomics.ucsd.edu/Software/MSPLIT-DIA/MSPLIT-DIAv1.0.zip > MSPLIT-DIAv1.0.zip; unzip MSPLIT-DIAv1.0.zip ; rm MSPLIT-DIAv1.0.zip ; mv MSPLIT-DIAv1.0/* . ; rm -rf MSPLIT-DIAv1.0
ADD MSPLIT-DIAv07192015.jar /galaxy-central/tools/wohl-proteomics/msplit-dia/

#And while we're at it, we'll get Specter
#And we'll handle the conda environment, and manually pull the obo file as per the Specter instructions.
#Also installing 3 packages for Specter into R at the end
#RUN cd /galaxy-central/tools/wohl-proteomics/specter/ && \
#    git clone https://github.com/rpeckner-broad/Specter.git && \
#    cd Specter && \
#    /tool_deps/_conda/condabin/conda env create -f SpecterEnv.yml && \
#    /tool_deps/_conda/condabin/conda activate SpecterEnv && \
#    pip install cvxopt && \
#    wget http://data.bioontology.org/ontologies/MS/submissions/116/download?apikey=8b5b7825-538d-40e0-9e9e-5ab9274a9aeb && \
#    mv download?apikey=8b5b7825-538d-40e0-9e9e-5ab9274a9aeb /tool_deps/_conda/envs/SpecterEnv/lib/python2.7/site-packages/pymzml/obo/psi-ms-4.0.1.obo && \
#    R -e "install.packages(c('moments','pracma','kza'),repos='https://cran.rstudio.com/',dependencies=TRUE)"


#SET UP SAINTexpress
RUN curl -sSL https://downloads.sourceforge.net/project/saint-apms/SAINTexpress_v3.6.1__2015-05-03.zip > SAINTexpress_v3.6.1__2015-05-03.zip && unzip SAINTexpress_v3.6.1__2015-05-03.zip -d /galaxy-central/tools/wohl-proteomics/SAINTexpress/;rm SAINTexpress_v3.6.1__2015-05-03.zip; cp /galaxy-central/tools/wohl-proteomics/SAINTexpress/SAINTexpress_v3.6.1__2015-05-03/Precompiled_binaries/Linux64/* /galaxy-central/tools/wohl-proteomics/SAINTexpress/; rm -rf /galaxy-central/tools/wohl-proteomics/SAINTexpress/SAINTexpress_v3.6.1__2015-05-03/


#SET UP SAINTq
RUN curl -L http://sourceforge.net/projects/saint-apms/files/saintq_v0.0.4.tar.gz/download >saintq.tar.gz && tar xzvf saintq.tar.gz && rm saintq.tar.gz && cd saintq/ && make && mv bin/saintq /bin/ && cd .. && rm -rf saintq/


#SET UP PERCOLATOR CONVERTERS
RUN curl -sSL https://github.com/percolator/percolator/releases/download/rel-3-01/ubuntu64_release.tar.gz > ubuntu64_release.tar.gz && tar xzvf ubuntu64_release.tar.gz && rm ubuntu64_release.tar.gz && dpkg -i percolator-converters-v3-01-linux-amd64.deb && dpkg -i elude-v3-01-linux-amd64.deb && apt-get install -f && rm percolator-converters-v3-01-linux-amd64.deb percolator-noxml-v3-01-linux-amd64.deb percolator-v3-01-linux-amd64.deb elude-v3-01-linux-amd64.deb


#We need to grab the phosphoRS dll file and unpack it...
RUN mkdir phosphotemp && cd phosphotemp && curl -L http://ms.imp.ac.at/index.php?file=phosphors/phosphors-1_3.zip > phosphoRS.zip && unzip phosphoRS.zip && cp IMP.PhosphoRS.dll /galaxy-central/tools/wohl-proteomics/RSmax/IMP.PhosphoRS.dll && \
    cd ../ && rm -rf phosphotemp


# PATCHES AND FIXES BASED ON HARD REVISIONED PACKAGES
#
#
#Patch listed in https://github.com/galaxyproject/pulsar/issues/125 for directory issues...
#RUN sed -i "s#        pattern = r\"(#        directory = directory.replace('\\\\\\\\','\\\\\\\\\\\\\\\\')\n        pattern = r\"(#g" /galaxy_venv/lib/python2.7/site-packages/pulsar/client/staging/up.py

#Modify galaxy.ini to always cleanup...
RUN sed -i 's/#cleanup_job = always/cleanup_job = always/' /etc/galaxy/galaxy.yml

#Gotta give this an absolute path nowadays...
RUN sed -i "s#ruby#/usr/local/rvm/rubies/ruby-2.5.1/bin/ruby#" /usr/local/rvm/gems/ruby-2.5.1/gems/protk-1.4.2/lib/protk/galaxy_stager.rb

#Let's install a few galaxy tools....
ADD proteomics_toolshed.yml $GALAXY_ROOT/proteomics_toolshed.yml
RUN cp /galaxy-central/config/dependency_resolvers_conf.xml.sample /galaxy-central/config/dependency_resolvers_conf.xml && \
    startup_lite && \
    sleep 25 && \
    install-tools $GALAXY_ROOT/proteomics_toolshed.yml

COPY replace_workflow_id.py /galaxy-central/replace_workflow_id.py
COPY patch_msconvert.py /galaxy-central/patch_msconvert.py
COPY patch_decoydatabase.py /galaxy-central/patch_decoydatabase.py
RUN startup_lite && \
    sleep 60 && \
    pip install ephemeris && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string msconvert_win --job_conf $GALAXY_CONFIG_DIR/job_conf.xml && \
    python /galaxy-central/replace_workflow_id.py --apikey admin --galaxy_address 127.0.0.1:8080 --workflow_folder /galaxy-central/milkyway_proteomics/workflows/ --old_tool_string DecoyDatabase && \
    python /galaxy-central/patch_msconvert.py --apikey admin --galaxy_address 127.0.0.1:8080 --tool_string msconvert_win && \
    python /galaxy-central/patch_decoydatabase.py --apikey admin --galaxy_address 127.0.0.1:8080 --tool_string openms_decoydatabase && \
    workflow-install --workflow_path /galaxy-central/milkyway_proteomics/workflows/ -g http://localhost:8080 -u admin@galaxy.org -p admin

#The second is the tool_conf xml
RUN cp milkyway_proteomics/galaxy_milkyway_files/config/job_conf.xml $GALAXY_CONFIG_DIR/job_conf.xml && \
    head -n -1 $GALAXY_ROOT/config/tool_conf.xml.sample > /home/galaxy/milkyway_tool_conf.xml; head -n -1 /home/galaxy/wohl_tool_conf.xml > /home/galaxy/wohl_tool_tmp.xml; sed -e "1d" /home/galaxy/wohl_tool_tmp.xml > /home/galaxy/wohl_tool_tmp_final.xml; cat /home/galaxy/wohl_tool_tmp_final.xml >> /home/galaxy/milkyway_tool_conf.xml; echo "</toolbox>" >> /home/galaxy/milkyway_tool_conf.xml; rm /home/galaxy/wohl_tool_tmp.xml; rm /home/galaxy/wohl_tool_tmp_final.xml

#Position the loc files for msgf+ and reading mods
RUN cp milkyway_proteomics/galaxy_milkyway_files/tool-data/msgfplus_mods.loc $GALAXY_ROOT/tool-data/msgfplus_mods.loc && \
    cp milkyway_proteomics/galaxy_milkyway_files/tool-data/silac_mods.loc $GALAXY_ROOT/tool-data/silac_mods.loc



ADD welcome.html /etc/galaxy/web/welcome.html
#Set up environment variables for galaxy docker...
ENV GALAXY_CONFIG_BRAND='MilkyWay' \
GALAXY_VIRTUAL_ENV=/galaxy_venv \
GALAXY_CONFIG_TOOL_CONFIG_FILE=/home/galaxy/milkyway_tool_conf.xml,$GALAXY_ROOT/config/shed_tool_conf.xml \
GALAXY_DESTINATIONS_DEFAULT=local_no_container \
GALAXY_HANDLER_NUMPROCS=4 \
UWSGI_PROCESSES=4 \
UWSGI_THREADS=2 \
GALAXY_ROOT=/galaxy-central \
GALAXY_CONFIG_DIR=/etc/galaxy

#NONUSE=slurmd,slurmctld \

#VOLUME ["/export/","/data/","/var/lib/docker"]

#EXPOSE :80
#EXPOSE :21
#EXPOSE :8800


#CMD ["/usr/bin/startup"]

ENV GALAXY_USER=galaxy \
GALAXY_UID=1450 \
GALAXY_GID=1450 \
GALAXY_HOME=/home/galaxy \
EXPORT_DIR=/export \
LC_ALL=en_US.UTF-8 \
LANG=en_US.UTF-8 \
GEM_HOME=/usr/local/rvm/gems/ruby-2.5.1 \
GEM_PATH=/usr/local/rvm/gems/ruby-2.5.1
# Setting a standard encoding. This can get important for things like the unix sort tool.

#ADD startup.sh /usr/bin/startup.sh

#RUN mkdir -p /tmp/download && \
#    wget --no-check-certificate -qO - https://download.docker.com/linux/static/stable/x86_64/docker-17.06.2-ce.tgz | tar -xz -C /tmp/download && \
#    mv /tmp/download/docker/docker /usr/bin/ && \
#    rm -rf /tmp/download && \
#    rm -rf ~/.cache/ && \
#    groupadd -r $GALAXY_USER -g $GALAXY_GID && \
#    useradd -u $GALAXY_UID -r -g $GALAXY_USER -d $GALAXY_HOME -c "Galaxy user" $GALAXY_USER && \
#    groupadd --gid 999 docker && \
#    gpasswd -a $GALAXY_USER docker && \
#    adduser condor docker

#ENV CONDOR_CPUS=1 \
#    CONDOR_MEMORY=1024

#ADD startup.sh /usr/bin/startup.sh
#RUN chmod +x /usr/bin/startup.sh

#CMD ["/usr/bin/startup.sh"]

CMD ["cp -n milkyway_proteomics/galaxy_milkyway_files/tool-data/msgfplus_mods.loc $GALAXY_ROOT/tool-data/msgfplus_mods.loc && \
    cp -n milkyway_proteomics/galaxy_milkyway_files/tool-data/silac_mods.loc $GALAXY_ROOT/tool-data/silac_mods.loc && \
    /usr/bin/startup"]
